// FlashFeed Mock Offers Repository Implementation
// Nutzt zentralen MockDataService als Datenquelle

import 'offers_repository.dart';
import '../data/product_category_mapping.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';
// Access to global mockDataService

class MockOffersRepository implements OffersRepository {
  final MockDataService? _testService; // Optional test service
  
  MockOffersRepository({MockDataService? testService}) : _testService = testService;
  
  // Helper to get the correct service
  MockDataService get _dataService => _testService ?? mockDataService;
  
  // Expose mockDataService for testing
  MockDataService get mockDataService => _dataService;
  static final List<Offer> _mockOffers = [
    // EDEKA Angebote
    Offer(
      id: 'edeka_001',
      retailer: 'EDEKA',
      productName: 'Frische Vollmilch 1L',
      originalCategory: 'Molkereiprodukte',
      price: 0.89,
      originalPrice: 1.29,
      discountPercent: 31.0,
      storeAddress: 'EDEKA Neukauf, Musterstraße 15, 10115 Berlin',
      storeId: 'edeka_berlin_01',
      validUntil: DateTime.now().add(Duration(days: 2)),
      storeLat: 52.5200,
      storeLng: 13.4050,
    ),
    Offer(
      id: 'edeka_002', 
      retailer: 'EDEKA',
      productName: 'Bio Bananen 1kg',
      originalCategory: 'Obst',
      price: 2.49,
      storeAddress: 'EDEKA Neukauf, Musterstraße 15, 10115 Berlin',
      storeId: 'edeka_berlin_01',
      validUntil: DateTime.now().add(Duration(days: 1)),
      storeLat: 52.5200,
      storeLng: 13.4050,
    ),
    
    // REWE Angebote
    Offer(
      id: 'rewe_001',
      retailer: 'REWE',
      productName: 'Gouda jung 200g',
      originalCategory: 'Milch & Käse',
      price: 1.99,
      originalPrice: 2.49,
      discountPercent: 20.0,
      storeAddress: 'REWE City, Beispielweg 42, 10117 Berlin',
      storeId: 'rewe_berlin_05',
      validUntil: DateTime.now().add(Duration(days: 3)),
      storeLat: 52.5170,
      storeLng: 13.3880,
    ),
    Offer(
      id: 'rewe_002',
      retailer: 'REWE', 
      productName: 'Hähnchenbrust 500g',
      originalCategory: 'Fleisch & Geflügel',
      price: 4.99,
      storeAddress: 'REWE City, Beispielweg 42, 10117 Berlin',
      storeId: 'rewe_berlin_05',
      validUntil: DateTime.now().add(Duration(hours: 18)),
      storeLat: 52.5170,
      storeLng: 13.3880,
    ),
    
    // ALDI Angebote  
    Offer(
      id: 'aldi_001',
      retailer: 'ALDI',
      productName: 'Schweineschnitzel 500g',
      originalCategory: 'Frischfleisch',
      price: 3.49,
      originalPrice: 4.99,
      discountPercent: 30.0,
      storeAddress: 'ALDI SÜD, Professorweg 1, 10119 Berlin',
      storeId: 'aldi_berlin_demo',
      validUntil: DateTime.now().add(Duration(hours: 8)),
      storeLat: 52.5230,
      storeLng: 13.4100,
    ),
    Offer(
      id: 'aldi_002',
      retailer: 'ALDI',
      productName: 'Joghurt 150g Becher',
      originalCategory: 'Milcherzeugnisse', 
      price: 0.35,
      storeAddress: 'ALDI SÜD, Professorweg 1, 10119 Berlin',
      storeId: 'aldi_berlin_demo',
      validUntil: DateTime.now().add(Duration(days: 5)),
      storeLat: 52.5230,
      storeLng: 13.4100,
    ),
    
    // Weitere Mock-Daten für Demo
    Offer(
      id: 'lidl_001',
      retailer: 'Lidl',
      productName: 'Brot 500g',
      originalCategory: 'Backwaren',
      price: 0.79,
      originalPrice: 1.19,
      discountPercent: 33.0,
      storeAddress: 'Lidl, Demostraße 99, 10120 Berlin',
      storeId: 'lidl_berlin_01',
      validUntil: DateTime.now().add(Duration(hours: 6)),
      storeLat: 52.5150,
      storeLng: 13.3950,
    ),
    Offer(
      id: 'netto_001', 
      retailer: 'Netto Marken-Discount',
      productName: 'Apfelsaft 1L',
      originalCategory: 'Getränke',
      price: 1.29,
      storeAddress: 'Netto Marken-Discount, Teststraße 50, 10121 Berlin',
      storeId: 'netto_berlin_01',
      validUntil: DateTime.now().add(Duration(days: 7)),
      storeLat: 52.5100,
      storeLng: 13.3800,
    ),
  ];

  @override
  Future<List<Offer>> getAllOffers() async {
    // Simuliere Netzwerk-Delay
    await Future.delayed(Duration(milliseconds: 300));
    
    // Use correct service (test or global)
    if (_dataService.isInitialized) {
      return List.from(_dataService.offers);
    }
    
    // Fallback to static data if service not initialized
    return List.from(_mockOffers);
  }

  @override
  Future<List<Offer>> getOffersByCategory(String flashFeedCategory) async {
    await Future.delayed(Duration(milliseconds: 200));
    
    // Get offers from correct service
    List<Offer> allOffers = _dataService.isInitialized 
        ? _dataService.offers 
        : _mockOffers;
    
    return allOffers.where((offer) {
      String mappedCategory = ProductCategoryMapping.mapToFlashFeedCategory(
        offer.retailer, 
        offer.originalCategory
      );
      return mappedCategory == flashFeedCategory;
    }).toList();
  }

  @override
  Future<List<Offer>> getOffersByRetailer(String retailer) async {
    await Future.delayed(Duration(milliseconds: 150));
    
    // Get offers from correct service
    List<Offer> allOffers = _dataService.isInitialized 
        ? _dataService.offers 
        : _mockOffers;
    
    return allOffers.where((offer) => 
      offer.retailer.toLowerCase() == retailer.toLowerCase()
    ).toList();
  }

  @override
  Future<List<Offer>> getOffersByLocation(double latitude, double longitude, double radiusKm) async {
    await Future.delayed(Duration(milliseconds: 250));
    
    return _mockOffers.where((offer) => 
      offer.distanceTo(latitude, longitude) <= radiusKm
    ).toList();
  }

  @override
  Future<List<Offer>> searchOffers(String searchTerm) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (searchTerm.isEmpty) return getAllOffers();
    
    String lowerSearchTerm = searchTerm.toLowerCase();
    return _mockOffers.where((offer) =>
      offer.productName.toLowerCase().contains(lowerSearchTerm) ||
      offer.retailer.toLowerCase().contains(lowerSearchTerm)
    ).toList();
  }

  @override
  Future<List<Offer>> getSortedOffers(List<Offer> offers, OfferSortType sortType, {double? userLat, double? userLng}) async {
    await Future.delayed(Duration(milliseconds: 50));
    
    List<Offer> sortedOffers = List.from(offers);
    
    switch (sortType) {
      case OfferSortType.priceAsc:
        sortedOffers.sort((a, b) => a.price.compareTo(b.price));
        break;
      case OfferSortType.priceDesc:
        sortedOffers.sort((a, b) => b.price.compareTo(a.price));
        break;
      case OfferSortType.discountDesc:
        sortedOffers.sort((a, b) => 
          (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0));
        break;
      case OfferSortType.distanceAsc:
        // Task 9.1: Use provided coordinates or Berlin Mitte as fallback
        final lat = userLat ?? 52.5200;
        final lng = userLng ?? 13.4050;
        sortedOffers.sort((a, b) => 
          a.distanceTo(lat, lng).compareTo(b.distanceTo(lat, lng)));
        break;
      case OfferSortType.validityDesc:
        sortedOffers.sort((a, b) => b.validUntil.compareTo(a.validUntil));
        break;
      case OfferSortType.nameAsc:
        sortedOffers.sort((a, b) => a.productName.compareTo(b.productName));
        break;
    }
    
    return sortedOffers;
  }
  
  /// Zusätzliche Mock-Methoden für Demo
  static void addMockOffer(Offer offer) {
    _mockOffers.add(offer);
  }
  
  static void clearMockOffers() {
    _mockOffers.clear();
  }
  
  /// Professor-Demo: Sofortigen Deal hinzufügen
  static void addInstantDemoOffer() {
    final demoOffer = Offer(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      retailer: 'DEMO',
      productName: 'Professor Demo Produkt',
      originalCategory: 'Demo-Kategorie',
      price: 1.99,
      originalPrice: 9.99,
      discountPercent: 80.0,
      storeAddress: 'Demo Store, Campus Straße 1, 10999 Berlin',
      storeId: 'demo_store_01',
      validUntil: DateTime.now().add(Duration(minutes: 5)),
      storeLat: 52.5200,
      storeLng: 13.4050,
    );
    _mockOffers.insert(0, demoOffer); // Am Anfang einfügen
  }
}

/// Helper-Extension für Offer mit FlashFeed Kategorie
extension OfferFlashFeedCategory on Offer {
  /// Korrekte FlashFeed Kategorie mit ProductCategoryMapping
  String get flashFeedCategory {
    return ProductCategoryMapping.mapToFlashFeedCategory(retailer, originalCategory);
  }
}
