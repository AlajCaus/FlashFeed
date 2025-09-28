import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/location_provider.dart';
import '../providers/retailers_provider.dart';
import '../providers/offers_provider.dart';

/// RegionalAvailabilityBanner - Regionale Verfügbarkeits-UI
///
/// Features:
/// - "Nicht in Ihrer Region" Banner
/// - Alternative Händler-Vorschläge
/// - PLZ-Änderungs-Prompt
/// - Verfügbarkeits-Statistiken
/// - Integrierter animierter PLZ-Hinweis
class RegionalAvailabilityBanner extends StatefulWidget {
  final String? currentRetailer;
  final bool showAlternatives;

  const RegionalAvailabilityBanner({
    super.key,
    this.currentRetailer,
    this.showAlternatives = true,
  });

  @override
  State<RegionalAvailabilityBanner> createState() => _RegionalAvailabilityBannerState();
}

class _RegionalAvailabilityBannerState extends State<RegionalAvailabilityBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _showHint = true;
  Timer? _hideTimer;

  // Design System Colors
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color warningBg = Color(0xFFFFF9E6);
  static const Color warningBorder = Color(0xFFFFD700);
  static const Color warningText = Color(0xFFF39C12);
  static const Color errorBg = Color(0xFFFFF5F5);
  static const Color errorBorder = Color(0xFFFEB2B2);
  static const Color errorText = Color(0xFFC53030);
  static const Color infoBg = Color(0xFFE3F2FD);
  static const Color infoBorder = Color(0xFF90CAF9);
  static const Color infoText = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();

    // Animation für pulsierenden Hinweis
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Animation in Schleife abspielen
    _animationController.repeat(reverse: true);

    // Timer zum automatischen Ausblenden nach 10 Sekunden
    _hideTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showHint = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onUserInteraction() {
    // Hinweis sofort ausblenden bei Benutzerinteraktion
    if (_showHint && mounted) {
      setState(() {
        _showHint = false;
      });
      _hideTimer?.cancel();
    }
  }
  
  Future<void> _showPLZDialog(BuildContext context, LocationProvider locationProvider) async {
    // Bei Dialog-Öffnung Hinweis ausblenden
    _onUserInteraction();

    final TextEditingController plzController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('PLZ eingeben'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bitte geben Sie Ihre Postleitzahl ein:'),
              const SizedBox(height: 16),
              TextField(
                controller: plzController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                decoration: const InputDecoration(
                  hintText: 'z.B. 10115',
                  labelText: 'Postleitzahl',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final plz = plzController.text.trim();
                if (plz.length == 5 && RegExp(r'^\d{5}$').hasMatch(plz)) {
                  await locationProvider.setUserPLZ(plz);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PLZ $plz gespeichert'),
                        backgroundColor: const Color(0xFF2E8B57),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bitte geben Sie eine gültige 5-stellige PLZ ein'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
              ),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWarningBanner({
    required IconData icon,
    required String title,
    required String message,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    Widget? action,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: textColor.withAlpha(204),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 8),
            action,
          ],
        ],
      ),
    );
  }
  
  Widget _buildLocationPrompt(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();

    if (locationProvider.postalCode != null) {
      return const SizedBox.shrink();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildWarningBanner(
          icon: Icons.location_off,
          title: 'Standort fehlt',
          message: 'Bitte geben Sie Ihre PLZ ein, um regionale Angebote zu sehen',
          bgColor: warningBg,
          borderColor: warningBorder,
          textColor: warningText,
          action: Row(
            children: [
              // PLZ eingeben Button mit Animation
              if (_showHint)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _showPLZDialog(context, locationProvider);
                      },
                      icon: const Icon(Icons.location_on, size: 16),
                      label: const Text('PLZ eingeben', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: warningText,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _showPLZDialog(context, locationProvider);
                    },
                    icon: const Icon(Icons.location_on, size: 16),
                    label: const Text('PLZ eingeben', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: warningText,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              // Animierter Hinweispfeil
              if (_showHint) ...[
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Hier klicken!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRetailerUnavailable(BuildContext context) {
    if (widget.currentRetailer == null) return const SizedBox.shrink();
    
    final retailersProvider = context.watch<RetailersProvider>();
    final locationProvider = context.watch<LocationProvider>();
    
    final isAvailable = retailersProvider.availableRetailers
        .any((r) => r.name == widget.currentRetailer);
    
    if (isAvailable) return const SizedBox.shrink();
    
    // Find alternative retailers
    final alternatives = retailersProvider.availableRetailers
        .take(3)
        .map((r) => r.name)
        .toList();
    
    return _buildWarningBanner(
      icon: Icons.store_mall_directory,
      title: '${widget.currentRetailer} nicht verfügbar',
      message: locationProvider.postalCode != null
          ? '${widget.currentRetailer} ist in PLZ ${locationProvider.postalCode} nicht verfügbar'
          : '${widget.currentRetailer} ist in Ihrer Region nicht verfügbar',
      bgColor: errorBg,
      borderColor: errorBorder,
      textColor: errorText,
      action: alternatives.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alternative Händler:',
                  style: TextStyle(
                    color: errorText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: alternatives.map((retailer) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: errorBorder),
                      ),
                      child: Text(
                        retailer,
                        style: TextStyle(
                          color: errorText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            )
          : null,
    );
  }
  
  Widget _buildRegionalStatistics(BuildContext context) {
    final retailersProvider = context.watch<RetailersProvider>();
    final offersProvider = context.watch<OffersProvider>();
    final locationProvider = context.watch<LocationProvider>();

    if (locationProvider.postalCode == null) {
      return const SizedBox.shrink();
    }

    final availableCount = retailersProvider.availableRetailers.length;
    final totalCount = 11; // Total number of retailers in system

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: infoBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: infoBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: infoText, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'PLZ ${locationProvider.postalCode} - $availableCount von $totalCount Händlern verfügbar',
                            style: TextStyle(
                              color: infoText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // PLZ löschen Kreuz
                        IconButton(
                          onPressed: () {
                            locationProvider.clearLocation();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('PLZ-Filter entfernt'),
                                backgroundColor: Color(0xFF2E8B57),
                              ),
                            );
                          },
                          icon: Icon(Icons.close, color: infoText),
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          tooltip: 'PLZ löschen',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offersProvider.filteredOffers.length} regionale Angebote verfügbar',
                      style: TextStyle(
                        color: infoText.withAlpha(204),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // PLZ ändern Button mit optionalem Hinweis
              if (_showHint)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: TextButton.icon(
                    onPressed: () async {
                      await _showPLZDialog(context, locationProvider);
                    },
                    icon: const Icon(Icons.edit_location, size: 14),
                    label: const Text('PLZ ändern'),
                    style: TextButton.styleFrom(
                      foregroundColor: infoText,
                      backgroundColor: infoBg,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () async {
                    await _showPLZDialog(context, locationProvider);
                  },
                  icon: const Icon(Icons.edit_location, size: 14),
                  label: const Text('PLZ ändern'),
                  style: TextButton.styleFrom(
                    foregroundColor: infoText,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              // Animierter Hinweis
              if (_showHint) ...[
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.8 + (_pulseAnimation.value - 1.0) * 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '← Hier PLZ ändern',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoOffersAvailable(BuildContext context) {
    final offersProvider = context.watch<OffersProvider>();
    final locationProvider = context.watch<LocationProvider>();
    
    if (offersProvider.offers.isNotEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: errorText.withAlpha(102),
          ),
          const SizedBox(height: 16),
          Text(
            locationProvider.postalCode != null
                ? 'Keine Angebote in PLZ ${locationProvider.postalCode}'
                : 'Keine Angebote verfügbar',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Versuchen Sie es mit einer anderen PLZ oder schauen Sie später wieder vorbei',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF757575),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  // requestUserPLZ method not available - using ensureLocationData
                  await locationProvider.ensureLocationData();
                },
                icon: const Icon(Icons.location_on, size: 16),
                label: const Text('PLZ ändern'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: const BorderSide(color: primaryGreen),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  offersProvider.loadOffers();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Aktualisieren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final offersProvider = context.watch<OffersProvider>();

    // Wrap everything in a GestureDetector to detect user interactions
    return GestureDetector(
      onTap: _onUserInteraction,
      onPanStart: (_) => _onUserInteraction(),
      child: _buildContent(context, locationProvider, offersProvider),
    );
  }

  Widget _buildContent(BuildContext context, LocationProvider locationProvider, OffersProvider offersProvider) {
    // Determine which banner to show
    if (locationProvider.postalCode == null) {
      return _buildLocationPrompt(context);
    }

    if (widget.currentRetailer != null) {
      return _buildRetailerUnavailable(context);
    }

    if (offersProvider.offers.isEmpty) {
      return _buildNoOffersAvailable(context);
    }

    if (widget.showAlternatives) {
      return _buildRegionalStatistics(context);
    }

    return const SizedBox.shrink();
  }
}

/// RegionalOverlay - Graues Overlay für nicht-verfügbare Angebote
class RegionalOverlay extends StatelessWidget {
  final bool isAvailable;
  final Widget child;
  
  const RegionalOverlay({
    super.key,
    required this.isAvailable,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    if (isAvailable) {
      return child;
    }
    
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 0.5, 0,
          ]),
          child: child,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(153),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off,
                  color: Colors.white,
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  'Nicht verfügbar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
