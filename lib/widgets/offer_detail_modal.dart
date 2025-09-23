import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/models.dart';
import '../providers/location_provider.dart';
import '../providers/retailers_provider.dart';

/// OfferDetailModal - Detaillierte Produktansicht
/// 
/// Features:
/// - Alle verfügbaren Händler mit Preisen
/// - Nächste Filiale mit Entfernung
/// - Gültigkeitszeitraum
/// - Einkaufsliste-Integration
/// - Share-Funktion
class OfferDetailModal extends StatefulWidget {
  final Offer offer;
  final List<Offer> comparableOffers;
  
  const OfferDetailModal({
    super.key,
    required this.offer,
    this.comparableOffers = const [],
  });
  
  static void show(BuildContext context, Offer offer, {List<Offer>? comparableOffers}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferDetailModal(
        offer: offer,
        comparableOffers: comparableOffers ?? [],
      ),
    );
  }

  @override
  State<OfferDetailModal> createState() => _OfferDetailModalState();
}

class _OfferDetailModalState extends State<OfferDetailModal> {
  bool _addedToList = false;
  
  // Design System Colors
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color secondaryOrange = Color(0xFFFF6347);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color savingsBg = Color(0xFFE8F5E9);
  
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
  
  void _addToShoppingList() {
    // Mock implementation
    setState(() {
      _addedToList = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.offer.productName} zur Einkaufsliste hinzugefügt'),
        backgroundColor: primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _shareOffer() {
    // Create share text
    final shareText = '''
🛒 ${widget.offer.productName}
💰 Nur ${widget.offer.price.toStringAsFixed(2)}€ bei ${widget.offer.retailer}
📍 ${widget.offer.discountPercent != null ? '-${widget.offer.discountPercent}% Rabatt!' : ''}
⏰ Gültig bis ${_formatDate(widget.offer.validUntil)}

Gefunden mit FlashFeed!
    ''';
    
    // Copy to clipboard as mock share
    Clipboard.setData(ClipboardData(text: shareText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Angebot in Zwischenablage kopiert'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Widget _buildStoreInfo() {
    final locationProvider = context.watch<LocationProvider>();
    final retailersProvider = context.watch<RetailersProvider>();
    
    // Get nearest store for this retailer
    final availableRetailers = retailersProvider.availableRetailers
        .where((r) => r.name == widget.offer.retailer)
        .toList();
    
    if (availableRetailers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFEB2B2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off, color: Color(0xFFC53030), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.offer.retailer} ist in Ihrer Region nicht verfügbar',
                style: const TextStyle(color: Color(0xFFC53030), fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
    
    // Note: store property not directly on Offer model
    // Using mock Store data for MVP
    final store = Store(
      id: 'store-${widget.offer.retailer}-1',
      chainId: 'chain-${widget.offer.retailer}',
      retailerName: widget.offer.retailer,
      name: '${widget.offer.retailer} Filiale',
      street: 'Beispielstraße 1',
      zipCode: locationProvider.postalCode ?? '10115',
      city: 'Berlin',
      latitude: 52.5200,
      longitude: 13.4050,
      phoneNumber: '030-12345678',
      openingHours: {
        'Montag': OpeningHours.custom(8, 0, 20, 0),
        'Dienstag': OpeningHours.custom(8, 0, 20, 0),
        'Mittwoch': OpeningHours.custom(8, 0, 20, 0),
        'Donnerstag': OpeningHours.custom(8, 0, 20, 0),
        'Freitag': OpeningHours.custom(8, 0, 20, 0),
        'Samstag': OpeningHours.custom(8, 0, 20, 0),
        'Sonntag': OpeningHours.closed(),
      },
      services: ['Bäckerei', 'Metzgerei'],
    );
    final distance = locationProvider.latitude != null && locationProvider.longitude != null
        ? _calculateDistance(
            locationProvider.latitude!,
            locationProvider.longitude!,
            store.latitude,
            store.longitude,
          )
        : null;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.store, size: 20, color: primaryGreen),
              SizedBox(width: 8),
              Text(
                'Nächste Filiale',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            Text(
              store.street,
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '${store.zipCode} ${store.city}',
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            if (distance != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.navigation, size: 16, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${distance.toStringAsFixed(1)} km entfernt',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildPriceComparison() {
    if (widget.comparableOffers.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Sort offers by price
    final allOffers = [widget.offer, ...widget.comparableOffers]
      ..sort((a, b) => a.price.compareTo(b.price));
    
    // Remove duplicates
    final uniqueOffers = <String, Offer>{};
    for (final offer in allOffers) {
      uniqueOffers[offer.retailer] = offer;
    }
    
    final sortedOffers = uniqueOffers.values.toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.compare_arrows, size: 20, color: primaryGreen),
            SizedBox(width: 8),
            Text(
              'Preisvergleich',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sortedOffers.map((offer) {
          final isCurrentOffer = offer.retailer == widget.offer.retailer;
          final isBestPrice = offer == sortedOffers.first;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentOffer ? savingsBg : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrentOffer ? primaryGreen : borderColor,
                width: isCurrentOffer ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Retailer logo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: retailerColors[offer.retailer] ?? primaryGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      offer.retailer.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Retailer name and price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.retailer,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrentOffer ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      if (offer.discountPercent != null)
                        Text(
                          '-${offer.discountPercent}% Rabatt',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '€${offer.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isBestPrice ? primaryGreen : Colors.black,
                      ),
                    ),
                    if (offer.originalPrice != null)
                      Text(
                        '€${offer.originalPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                
                // Best price badge
                if (isBestPrice) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header with handle and close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // Balance for close button
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Product image (using thumbnailUrl like offer cards)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        image: widget.offer.thumbnailUrl != null && widget.offer.thumbnailUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(widget.offer.thumbnailUrl!),
                                fit: BoxFit.contain,
                              )
                            : null,
                      ),
                      child: widget.offer.thumbnailUrl == null || widget.offer.thumbnailUrl!.isEmpty
                          ? Center(
                              child: Icon(
                                _getCategoryIcon(widget.offer.flashFeedCategory),
                                size: 80,
                                color: primaryGreen.withAlpha(153),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Retailer badge and discount
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: retailerColors[widget.offer.retailer] ?? primaryGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.offer.retailer,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.offer.discountPercent != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: secondaryOrange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${widget.offer.discountPercent}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Product name
                    Text(
                      widget.offer.productName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Category
                    Text(
                      widget.offer.flashFeedCategory,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${widget.offer.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        if (widget.offer.originalPrice != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '€${widget.offer.originalPrice!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              color: textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Valid until
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFD700)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Color(0xFFF39C12)),
                          const SizedBox(width: 6),
                          Text(
                            'Gültig bis ${_formatDate(widget.offer.validUntil)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFF39C12),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Store info
                    _buildStoreInfo(),
                    const SizedBox(height: 20),
                    
                    // Price comparison
                    if (widget.comparableOffers.isNotEmpty) ...[
                      _buildPriceComparison(),
                      const SizedBox(height: 20),
                    ],
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addedToList ? null : _addToShoppingList,
                            icon: Icon(_addedToList ? Icons.check : Icons.add_shopping_cart),
                            label: Text(_addedToList ? 'Hinzugefügt' : 'Zur Liste'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _addedToList ? Colors.grey : primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shareOffer,
                            icon: const Icon(Icons.share),
                            label: const Text('Teilen'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryGreen,
                              side: const BorderSide(color: primaryGreen),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
