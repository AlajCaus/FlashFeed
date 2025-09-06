import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/plz_helper.dart';

/// Material Design Dialog für User-PLZ-Eingabe
/// 
/// Verwendet als GPS-Fallback wenn Geolocation fehlschlägt
/// Features: Real-time Validierung, Error-States, Integration mit PLZHelper
class PLZInputDialog extends StatefulWidget {
  final String? initialPLZ;
  final String title;
  final String subtitle;
  final Function(String plz)? onPLZConfirmed;
  
  const PLZInputDialog({
    super.key,
    this.initialPLZ,
    this.title = 'Postleitzahl eingeben',
    this.subtitle = 'Um lokale Angebote zu finden, geben Sie bitte Ihre PLZ ein:',
    this.onPLZConfirmed,
  });
  
  @override
  State<PLZInputDialog> createState() => _PLZInputDialogState();
  
  /// Static Helper: Dialog anzeigen und PLZ zurückgeben
  /// 
  /// Returns: Gültige PLZ oder null bei Abbruch
  static Future<String?> show(
    BuildContext context, {
    String? initialPLZ,
    String? title,
    String? subtitle,
  }) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false, // Nur über Buttons schließbar
      builder: (BuildContext context) {
        return PLZInputDialog(
          initialPLZ: initialPLZ,
          title: title ?? 'Postleitzahl eingeben',
          subtitle: subtitle ?? 'Um lokale Angebote zu finden, geben Sie bitte Ihre PLZ ein:',
        );
      },
    );
  }
}

class _PLZInputDialogState extends State<PLZInputDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  
  String? _errorMessage;
  bool _isValidPLZ = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPLZ ?? '');
    _focusNode = FocusNode();
    
    // Initial-Validierung wenn PLZ vorgegeben
    if (widget.initialPLZ?.isNotEmpty == true) {
      _validatePLZ(widget.initialPLZ!);
    }
    
    // Fokus auf Textfeld setzen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  /// PLZ in Echtzeit validieren
  void _validatePLZ(String plz) {
    setState(() {
      if (plz.isEmpty) {
        _errorMessage = null;
        _isValidPLZ = false;
        return;
      }
      
      if (plz.length < 5) {
        _errorMessage = 'PLZ muss 5 Ziffern haben';
        _isValidPLZ = false;
        return;
      }
      
      if (plz.length > 5) {
        _errorMessage = 'PLZ darf nur 5 Ziffern haben';
        _isValidPLZ = false;
        return;
      }
      
      if (!RegExp(r'^\\d{5}\$').hasMatch(plz)) {
        _errorMessage = 'PLZ darf nur Ziffern enthalten';
        _isValidPLZ = false;
        return;
      }
      
      // Integration mit PLZHelper
      if (!PLZHelper.isValidPLZ(plz)) {
        _errorMessage = 'Ungültige deutsche PLZ';
        _isValidPLZ = false;
        return;
      }
      
      // PLZ ist gültig
      _errorMessage = null;
      _isValidPLZ = true;
    });
  }
  
  /// PLZ bestätigen und Dialog schließen
  void _confirmPLZ() async {
    if (!_isValidPLZ) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final plz = _controller.text.trim();
      
      // Callback für Parent-Widget
      if (widget.onPLZConfirmed != null) {
        widget.onPLZConfirmed!(plz);
      }
      
      // Dialog schließen mit PLZ-Ergebnis
      if (mounted) {
        Navigator.of(context).pop(plz);
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler bei der Verarbeitung';
      });
    }
  }
  
  /// Dialog ohne PLZ schließen
  void _cancel() {
    Navigator.of(context).pop(null);
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            maxLength: 5,
            decoration: InputDecoration(
              labelText: 'PLZ',
              hintText: 'z.B. 10115',
              errorText: _errorMessage,
              prefixIcon: const Icon(Icons.location_on),
              border: const OutlineInputBorder(),
              counterText: '', // Zeichen-Counter ausblenden
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Nur Ziffern
              LengthLimitingTextInputFormatter(5), // Max 5 Zeichen
            ],
            onChanged: _validatePLZ,
            onSubmitted: (_) => _isValidPLZ ? _confirmPLZ() : null,
            enabled: !_isLoading,
          ),
          
          if (_isValidPLZ && _errorMessage == null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gültige deutsche PLZ',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _cancel,
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: (_isValidPLZ && !_isLoading) ? _confirmPLZ : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Bestätigen'),
        ),
      ],
    );
  }
}

/// Einfacher PLZ-Eingabe-Widget für Integration in andere UIs
class PLZInputField extends StatefulWidget {
  final String? initialPLZ;
  final Function(String? plz, bool isValid)? onChanged;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  
  const PLZInputField({
    super.key,
    this.initialPLZ,
    this.onChanged,
    this.labelText = 'PLZ',
    this.hintText = 'z.B. 10115',
    this.enabled = true,
  });
  
  @override
  State<PLZInputField> createState() => _PLZInputFieldState();
}

class _PLZInputFieldState extends State<PLZInputField> {
  late final TextEditingController _controller;
  String? _errorMessage;
  bool _isValidPLZ = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPLZ ?? '');
    
    // Initial-Validierung
    if (widget.initialPLZ?.isNotEmpty == true) {
      _validatePLZ(widget.initialPLZ!);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _validatePLZ(String plz) {
    setState(() {
      if (plz.isEmpty) {
        _errorMessage = null;
        _isValidPLZ = false;
      } else if (plz.length != 5) {
        _errorMessage = 'PLZ muss 5 Ziffern haben';
        _isValidPLZ = false;
      } else if (!RegExp(r'^\\d{5}\$').hasMatch(plz)) {
        _errorMessage = 'PLZ darf nur Ziffern enthalten';
        _isValidPLZ = false;
      } else if (!PLZHelper.isValidPLZ(plz)) {
        _errorMessage = 'Ungültige deutsche PLZ';
        _isValidPLZ = false;
      } else {
        _errorMessage = null;
        _isValidPLZ = true;
      }
    });
    
    // Callback für Parent-Widget
    if (widget.onChanged != null) {
      widget.onChanged!(
        _isValidPLZ ? plz : null,
        _isValidPLZ,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      maxLength: 5,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: _errorMessage,
        prefixIcon: const Icon(Icons.location_on),
        border: const OutlineInputBorder(),
        counterText: '', // Zeichen-Counter ausblenden
        suffixIcon: _isValidPLZ
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      onChanged: _validatePLZ,
    );
  }
}
