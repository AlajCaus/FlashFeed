import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offers_provider.dart';
import '../providers/user_provider.dart';
import '../providers/retailers_provider.dart';
import '../providers/location_provider.dart';
import '../models/models.dart';
import '../utils/responsive_helper.dart';

/// OffersScreen - Panel 1: Angebotsvergleich
/// 
/// UI-Spezifikationen:
/// - Händler-Icons: 80px Höhe, 60x60px Icons
/// - Produktgruppen-Grid: auto-fit minmax(150px, 1fr)
/// - Freemium: Grayscale für gesperrte Angebote
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  // Design System Colors
  static const Color primaryGreen = Color(0xFF2E8B57);

  static const Color secondaryOrange = Color(0xFFFF6347);
  static const Color textSecondary = Color(0xFF666666);
  static const Color errorBg = Color(0xFFFFF5F5);
  static const Color errorText = Color(0xFFC53030);
  
  // Händler-Farben
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
  
  String? _selectedRetailer;

  
  @override
  void initState() {
    super.initState();
    // Load offers on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OffersProvider>().loadOffers();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final offersProvider = context.watch<OffersProvider>();
    final userProvider = context.watch<UserProvider>();
    final retailersProvider = context.watch<RetailersProvider>();
    final locationProvider = context.watch<LocationProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // Händler-Icon-Leiste
          _buildRetailerIconBar(retailersProvider),
          
          // Content Area
          Expanded(
            child: offersProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Regional Warning if needed
                      if (locationProvider.postalCode == null)
                        _buildLocationWarning(),
                      
                      // Produktgruppen-Grid
                      Expanded(
                        child: _buildProductGrid(offersProvider, userProvider),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRetailerIconBar(RetailersProvider retailersProvider) {
    final availableRetailers = retailersProvider.availableRetailers;
    
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: textSecondary.withAlpha(51),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: availableRetailers.length,
        itemBuilder: (context, index) {
          final retailer = availableRetailers[index];
          final isSelected = _selectedRetailer == retailer.name;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedRetailer = isSelected ? null : retailer.name;
              });
            },
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? primaryGreen : textSecondary.withAlpha(51),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryGreen.withAlpha(77),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: ColorFiltered(
                  colorFilter: isSelected
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 0.5, 0,
                        ]),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: retailerColors[retailer.name] ?? primaryGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          retailer.name.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLocationWarning() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorBg,
        border: Border.all(color: const Color(0xFFFEB2B2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, color: errorText, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bitte PLZ eingeben für regionale Angebote',
              style: TextStyle(color: errorText, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductGrid(OffersProvider offersProvider, UserProvider userProvider) {
    // Group offers by category
    final Map<String, List<Offer>> offersByCategory = {};
    final filteredOffers = _selectedRetailer != null
        ? offersProvider.offers.where((o) => o.retailer == _selectedRetailer).toList()
        : offersProvider.offers;
    
    for (final offer in filteredOffers) {
      final category = offer.flashFeedCategory;
      offersByCategory.putIfAbsent(category, () => []).add(offer);
    }
    
    if (offersByCategory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: textSecondary.withAlpha(102)),
            const SizedBox(height: 16),
            Text(
              _selectedRetailer != null
                  ? 'Keine Angebote für $_selectedRetailer'
                  : 'Keine Angebote verfügbar',
              style: TextStyle(fontSize: 16, color: textSecondary),
            ),
          ],
        ),
      );
    }
    
    // Use ResponsiveHelper for dynamic grid columns
    final gridColumns = ResponsiveHelper.getAdaptiveGridColumns(
      context,
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
    );
    
    return GridView.builder(
      padding: ResponsiveHelper.getScreenPadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.0 : 1.2,
        crossAxisSpacing: ResponsiveHelper.getResponsiveSpacing(context, ResponsiveHelper.space4),
        mainAxisSpacing: ResponsiveHelper.getResponsiveSpacing(context, ResponsiveHelper.space4),
      ),
      itemCount: offersByCategory.keys.length,
      itemBuilder: (context, index) {
        final category = offersByCategory.keys.elementAt(index);
        final categoryOffers = offersByCategory[category]!;
        final bestDiscount = categoryOffers
            .map((o) => o.discountPercent ?? 0)
            .reduce((a, b) => a > b ? a : b);
        
        // Freemium: Only first category is free
        final isLocked = userProvider.isFree && index > 0;
        
        return GestureDetector(
          onTap: isLocked
              ? () => _showPremiumDialog(context)
              : () => _showCategoryOffers(context, category, categoryOffers),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Icon & Name
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 32,
                          color: primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getCategoryName(category),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Offer Count
                    Text(
                      '${categoryOffers.length} Angebote',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Best Discount Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: secondaryOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'bis -$bestDiscount%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(height: 8),
                      const Icon(Icons.lock, size: 16, color: Colors.grey),
                    ],
                  ],
                ),
              ),
            ),
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
  
  String _getCategoryName(String category) {
    // Return category as is, already formatted
    return category;
  }
  
  void _showCategoryOffers(BuildContext context, String category, List<Offer> offers) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getCategoryName(category),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return ListTile(
                    leading: Container(
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
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    title: Text(offer.productName),
                    subtitle: Text(offer.retailer),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${offer.price.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: secondaryOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${offer.discountPercent?.toStringAsFixed(0) ?? "0"}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'Diese Kategorie ist nur für Premium-Nutzer verfügbar. '
          'Aktivieren Sie Premium, um alle Angebote zu sehen!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Später'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UserProvider>().enableDemoMode();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium aktiviert!'),
                  backgroundColor: Color(0xFF2E8B57),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: const Text('Premium aktivieren'),
          ),
        ],
      ),
    );
  }
}
