import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/models.dart';
import '../utils/responsive_helper.dart';
import '../providers/retailers_provider.dart';
import '../providers/offers_provider.dart';
import '../providers/location_provider.dart';
import 'retailer_logo.dart';

/// OfferComparisonCard - Preisvergleich-Karte für Angebote
/// 
/// Features:
/// - Cross-Händler Preisvergleich
/// - Beste-Preis-Hervorhebung
/// - Ersparnis-Anzeige
/// - Regional verfügbare Preise
/// - Freemium Lock-State
class OfferComparisonCard extends StatelessWidget {
  final Offer primaryOffer;
  final List<Offer> comparableOffers;
  final bool isLocked;
  final VoidCallback? onTap;
  
  const OfferComparisonCard({
    super.key,
    required this.primaryOffer,
    this.comparableOffers = const [],
    this.isLocked = false,
    this.onTap,
  });
  
  // Design System Colors
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color primaryRed = Color(0xFFDC143C);
  static const Color secondaryOrange = Color(0xFFFF6347);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color savingsBg = Color(0xFFE8F5E9);
  static const Color savingsText = Color(0xFF2E7D32);
  
  // Retailer Colors
  static const Map<String, Color> retailerColors = {
    'EDEKA': Color(0xFF005CA9),
    'REWE': Color(0xFFCC071E),
    'ALDI': Color(0xFF00549F),
    'ALDI SÜD': Color(0xFF00549F),
    'LIDL': Color(0xFF0050AA),
    'NETTO': Color(0xFFFFD100),
    'netto scottie': Color(0xFFFFD100),
    'Penny': Color(0xFFE30613),
    'Kaufland': Color(0xFFE10915),
    'nahkauf': Color(0xFF004B93),
    'Globus': Color(0xFF009EE0),
    'norma': Color(0xFF1B5E20),
    'BioCompany': Color(0xFF7CB342),
  };
  
  Widget _buildRetailerBadge(String retailer) {
    return Consumer<RetailersProvider>(
      builder: (context, retailersProvider, child) {
        final logoPath = retailersProvider.getRetailerLogo(retailer);

        // Check if logo path points to a real asset (not placeholder)
        final bool hasRealLogo = logoPath.contains('/retailers/') &&
                                 !logoPath.contains('placeholder');

        if (hasRealLogo) {
          // SQUARE badge for logo
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Image.asset(
                  logoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // If logo fails to load, show initials in square format
                    return Container(
                      decoration: BoxDecoration(
                        color: retailerColors[retailer] ?? primaryGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          retailer.length >= 2 ? retailer.substring(0, 2).toUpperCase() : retailer[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        } else {
          // RECTANGULAR badge for text
          return Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            constraints: const BoxConstraints(minWidth: 50),
            decoration: BoxDecoration(
              color: retailerColors[retailer] ?? primaryGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                retailer,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
      },
    );
  }
  
  Widget _buildDiscountBadge(double? discountPercent) {
    if (discountPercent == null || discountPercent == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: secondaryOrange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '-${discountPercent.toInt()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 4,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ColorFiltered(
          colorFilter: isLocked
              ? const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 0.5, 0,
                ])
              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with retailer and discount
                          Row(
                            children: [
                              _buildRetailerBadge(primaryOffer.retailer),
                              const Spacer(),
                              _buildDiscountBadge(primaryOffer.discountPercent),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Product image: Asset -> Network -> Retailer Logo
                          Container(
                            height: isMobile ? 95 : 115,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: primaryOffer.thumbnailUrl != null
                                  ? Builder(
                                      builder: (context) {
                                        // First try as asset
                                        return Image.asset(
                                          primaryOffer.thumbnailUrl!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, assetError, stackTrace) {
                                            // If asset fails, try network
                                            return Image.network(
                                              primaryOffer.thumbnailUrl!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, networkError, stackTrace) {
                                                // If network also fails, show retailer logo
                                                return Center(
                                                  child: RetailerLogo(
                                                    retailerName: primaryOffer.retailer,
                                                    size: isMobile ? LogoSize.medium : LogoSize.large,
                                                    shape: LogoShape.rounded,
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        );
                                    },
                                  )
                                  : Center(
                                      child: RetailerLogo(
                                        retailerName: primaryOffer.retailer,
                                        size: isMobile ? LogoSize.medium : LogoSize.large,
                                        shape: LogoShape.rounded,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Product name
                          Text(
                            primaryOffer.productName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),

                          // Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '€${primaryOffer.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                              if (primaryOffer.originalPrice != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '€${primaryOffer.originalPrice!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Valid until and Distance (when sorted by distance)
                          Row(
                            children: [
                              // Distance indicator (only when sorted by distance)
                              Consumer2<OffersProvider, LocationProvider>(
                                builder: (context, offersProvider, locationProvider, child) {
                                  if (offersProvider.sortType == OfferSortType.distanceAsc) {
                                    // Calculate distance to store
                                    final userLat = locationProvider.latitude ?? 52.5200;
                                    final userLon = locationProvider.longitude ?? 13.4050;

                                    // Generate store coordinates based on retailer (same logic as OfferDetailModal)
                                    final retailerHash = primaryOffer.retailer.hashCode;
                                    final latOffset = ((retailerHash % 100) - 50) * 0.002;
                                    final lonOffset = ((retailerHash % 200) - 100) * 0.002;
                                    final storeLat = userLat + latOffset;
                                    final storeLon = userLon + lonOffset;

                                    final distance = _calculateDistance(
                                      userLat, userLon, storeLat, storeLon
                                    );

                                    return Row(
                                      children: [
                                        Icon(Icons.location_on, size: 11, color: primaryGreen),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${distance.toStringAsFixed(1)} km',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 1,
                                          height: 10,
                                          color: borderColor,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              Icon(Icons.schedule, size: 11, color: textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Gültig bis ${_formatDate(primaryOffer.validUntil)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Lock overlay
              if (isLocked)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula for distance calculation
    const R = 6371; // Earth's radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return R * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
