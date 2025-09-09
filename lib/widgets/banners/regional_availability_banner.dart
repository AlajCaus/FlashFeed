// FlashFeed Regional Availability Banner Widget
// Task 5c.4: Regional unavailability UI fallback logic

import 'package:flutter/material.dart';

class RegionalAvailabilityBanner extends StatelessWidget {
  final String userPLZ;
  final String regionName;
  final int availableRetailers;
  final int totalRetailers;
  final VoidCallback? onChangePLZ;
  final VoidCallback? onShowDetails;
  final bool isExpanded;
  
  const RegionalAvailabilityBanner({
    super.key,
    required this.userPLZ,
    required this.regionName,
    required this.availableRetailers,
    required this.totalRetailers,
    this.onChangePLZ,
    this.onShowDetails,
    this.isExpanded = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final availability = (availableRetailers / totalRetailers * 100).round();
    final isGoodAvailability = availability >= 70;
    final isMediumAvailability = availability >= 40 && availability < 70;
    
    // Determine banner color based on availability
    final MaterialColor bannerColor = isGoodAvailability
        ? Colors.green
        : isMediumAvailability
            ? Colors.orange
            : Colors.red;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bannerColor[50]!,
            bannerColor[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bannerColor[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main banner content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Location icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: bannerColor[700]!,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Region info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Region: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: bannerColor[800]!,
                            ),
                          ),
                          Text(
                            regionName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: bannerColor[900]!,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PLZ $userPLZ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: bannerColor[700]!,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Availability indicator
                          Container(
                            width: 120,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  width: 120 * (availableRetailers / totalRetailers),
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: bannerColor[600]!,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$availableRetailers von $totalRetailers Händlern',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: bannerColor[800]!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onChangePLZ != null) ...[
                      IconButton(
                        onPressed: onChangePLZ,
                        icon: const Icon(Icons.edit_location),
                        iconSize: 20,
                        color: bannerColor[700]!,
                        tooltip: 'PLZ ändern',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                    if (onShowDetails != null) ...[
                      IconButton(
                        onPressed: onShowDetails,
                        icon: AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: isExpanded ? 0.5 : 0,
                          child: const Icon(Icons.expand_more),
                        ),
                        iconSize: 20,
                        color: bannerColor[700]!,
                        tooltip: isExpanded ? 'Weniger anzeigen' : 'Details anzeigen',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Expanded details section
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verfügbarkeitsdetails:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: bannerColor[900]!,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildAvailabilityChip(
                        'Bundesweit',
                        availability >= 60,
                        bannerColor,
                      ),
                      _buildAvailabilityChip(
                        'Regional',
                        availableRetailers >= 3,
                        bannerColor,
                      ),
                      _buildAvailabilityChip(
                        'Lokal',
                        availableRetailers >= 1,
                        bannerColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getAvailabilityMessage(),
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: bannerColor[700]!,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvailabilityChip(String label, bool isAvailable, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable 
            ? (baseColor as MaterialColor)[100]! 
            : Colors.grey[200]!,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable 
              ? (baseColor as MaterialColor)[400]! 
              : Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isAvailable 
                ? (baseColor as MaterialColor)[700]! 
                : Colors.grey[600]!,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isAvailable 
                  ? (baseColor as MaterialColor)[800]! 
                  : Colors.grey[700]!,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getAvailabilityMessage() {
    final percentage = (availableRetailers / totalRetailers * 100).round();
    
    if (percentage >= 80) {
      return 'Hervorragende Verfügbarkeit! Fast alle Händler sind in Ihrer Region verfügbar.';
    } else if (percentage >= 60) {
      return 'Gute Verfügbarkeit. Die meisten Händler bieten Angebote in Ihrer Region.';
    } else if (percentage >= 40) {
      return 'Mittlere Verfügbarkeit. Einige Händler sind nicht in Ihrer Region verfügbar.';
    } else if (percentage >= 20) {
      return 'Eingeschränkte Verfügbarkeit. Viele Händler sind nicht verfügbar.';
    } else {
      return 'Sehr eingeschränkte Verfügbarkeit. Erwägen Sie eine andere PLZ.';
    }
  }
}
