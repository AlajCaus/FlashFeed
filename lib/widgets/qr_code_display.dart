import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/demo_service.dart';

/// Widget zur Anzeige eines QR-Codes für Demo-Zugriff
///
/// Features:
/// - Dynamische QR-Code-Generierung
/// - URL-Kopieren-Funktion
/// - Responsive Größenanpassung
/// - Anpassbare Demo-Parameter
class QrCodeDisplay extends StatefulWidget {
  final double size;
  final bool showUrl;
  final bool includePremium;
  final bool includeGuidedTour;
  final bool includeMetrics;

  const QrCodeDisplay({
    super.key,
    this.size = 200,
    this.showUrl = true,
    this.includePremium = true,
    this.includeGuidedTour = false,
    this.includeMetrics = false,
  });

  @override
  State<QrCodeDisplay> createState() => _QrCodeDisplayState();
}

class _QrCodeDisplayState extends State<QrCodeDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final DemoService _demoService = DemoService();
  String _demoUrl = '';
  bool _urlCopied = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();

    _generateDemoUrl();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateDemoUrl() {
    setState(() {
      _demoUrl = _demoService.generateDemoUrl(
        includePremium: widget.includePremium,
        includeGuidedTour: widget.includeGuidedTour,
        includeMetrics: widget.includeMetrics,
      );
    });
  }

  void _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: _demoUrl));
    setState(() {
      _urlCopied = true;
    });

    // Reset nach 2 Sekunden
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _urlCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titel
              Text(
                '🔗 Demo-Zugriff',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'QR-Code scannen für schnellen Zugriff',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // QR-Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _demoUrl,
                  version: QrVersions.auto,
                  size: widget.size,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (context, error) {
                    return Container(
                      width: widget.size,
                      height: widget.size,
                      alignment: Alignment.center,
                      child: Text(
                        'Fehler beim Generieren des QR-Codes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // URL-Anzeige und Kopier-Button
              if (widget.showUrl) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      SelectableText(
                        _demoUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _copyUrl,
                        icon: Icon(
                          _urlCopied ? Icons.check : Icons.copy,
                          size: 18,
                        ),
                        label: Text(_urlCopied ? 'Kopiert!' : 'URL kopieren'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _urlCopied
                              ? Colors.green
                              : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Demo-Features Info
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Aktivierte Demo-Features:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.includePremium)
                          _buildFeatureChip(
                            context,
                            '👑 Premium',
                            Colors.amber,
                          ),
                        if (widget.includeGuidedTour)
                          _buildFeatureChip(
                            context,
                            '🎯 Tour',
                            Colors.blue,
                          ),
                        if (widget.includeMetrics)
                          _buildFeatureChip(
                            context,
                            '📊 Metriken',
                            Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}