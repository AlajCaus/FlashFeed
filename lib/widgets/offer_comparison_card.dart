import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/user_provider.dart';
import '../providers/offers_provider.dart';
import '../utils/responsive_helper.dart';

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
    'LIDL': Color(0xFF0050AA),
    'Netto': Color(0xFFFFD100),
    'Penny': Color(0xFFE30613),
    'Kaufland': Color(0xFFE10915),
    'Real': Color(0xFF004B93),
    'Globus': Color(0xFF009EE0),
    'Marktkauf': Color(0xFF1B5E20),
    'BioCompany': Color(0xFF7CB342),
  };
  
  Widget _buildRetailerBadge(String retailer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: retailerColors[retailer] ?? primaryGreen,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        retailer,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
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
  
  Widget _buildBestPriceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.white, size: 12),
          SizedBox(width: 2),
          Text(
            'Bester Preis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSavingsIndicator(double savings, String vsRetailer) {
    if (savings <= 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: savingsBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.savings, color: savingsText, size: 14),
          const SizedBox(width: 4),
          Text(
            'Sie sparen €${savings.toStringAsFixed(2)} vs. $vsRetailer',
            style: TextStyle(
              color: savingsText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceComparison() {
    if (comparableOffers.isEmpty) return const SizedBox.shrink();
    
    // Sort offers by price
    final sortedOffers = List<Offer>.from(comparableOffers)
      ..sort((a, b) => a.price.compareTo(b.price));
    
    // Check if primary offer is best price
    final isBestPrice = sortedOffers.first.id == primaryOffer.id;
    
    // Calculate savings if not best price
    double savings = 0;
    String vsRetailer = '';
    if (!isBestPrice && sortedOffers.isNotEmpty) {
      final bestOffer = sortedOffers.first;
      savings = primaryOffer.price - bestOffer.price;
      vsRetailer = bestOffer.retailer;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isBestPrice) _buildBestPriceBadge(),
        if (savings > 0) _buildSavingsIndicator(savings.abs(), vsRetailer),
        const SizedBox(height: 8),
        
        // Price comparison list
        if (comparableOffers.length > 1)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preisvergleich',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ...sortedOffers.take(3).map((offer) {
                  final isCurrentOffer = offer.id == primaryOffer.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: retailerColors[offer.retailer] ?? primaryGreen,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Center(
                            child: Text(
                              offer.retailer.substring(0, 1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            offer.retailer,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrentOffer ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          '€${offer.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrentOffer ? primaryGreen : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
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
              Padding(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 8),
                    
                    // Product image placeholder
                    Container(
                      height: isMobile ? 80 : 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(primaryOffer.flashFeedCategory),
                          size: 40,
                          color: primaryGreen.withAlpha(153),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Product name
                    Text(
                      primaryOffer.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Category
                    Text(
                      primaryOffer.flashFeedCategory,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${primaryOffer.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        if (primaryOffer.originalPrice != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '€${primaryOffer.originalPrice!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Price comparison
                    _buildPriceComparison(),
                    
                    const Spacer(),
                    
                    // Valid until
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Gültig bis ${_formatDate(primaryOffer.validUntil)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Obst & Gemüse':
        return Icons.eco;
      case 'Milchprodukte':
        return Icons.egg;
      case 'Fleisch & Wurst':
        return Icons.restaurant;
      case 'Brot & Backwaren':
        return Icons.bakery_dining;
      case 'Getränke':
        return Icons.local_drink;
      case 'Süßwaren':
        return Icons.cookie;
      case 'Tiefkühl':
        return Icons.ac_unit;
      case 'Konserven':
        return Icons.kitchen;
      case 'Drogerie':
        return Icons.favorite;
      case 'Haushalt':
        return Icons.cleaning_services;
      case 'Bio-Produkte':
        return Icons.spa;
      case 'Fertiggerichte':
        return Icons.microwave;
      default:
        return Icons.category;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
