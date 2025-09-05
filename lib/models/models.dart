// FlashFeed Data Models
// Zentrale Model-Klassen für Provider und Repository Pattern

import '../data/product_category_mapping.dart';

/// Angebot Model-Klasse
class Offer {
  final String id;
  final String retailer;
  final String productName;
  final String originalCategory;
  final double price;
  final double? originalPrice; // null wenn kein Rabatt
  final String storeAddress;
  final String storeId;
  final double? discountPercent; // null wenn kein Rabatt
  final DateTime validUntil;
  final double storeLat;
  final double storeLng;

  Offer({
    required this.id,
    required this.retailer,
    required this.productName,
    required this.originalCategory,
    required this.price,
    this.originalPrice,
    required this.storeAddress,
    required this.storeId,
    this.discountPercent,
    required this.validUntil,
    required this.storeLat,
    required this.storeLng,
  });

  /// Zugeordnete FlashFeed Kategorie (aus product_category_mapping.dart)
  String get flashFeedCategory {
    return ProductCategoryMapping.mapToFlashFeedCategory(
      retailer, 
      originalCategory
    );
  }
  
  /// Hat das Angebot einen Rabatt?
  bool get hasDiscount => originalPrice != null && discountPercent != null;
  
  /// Ersparnis in Euro
  double get savings => hasDiscount ? (originalPrice! - price) : 0.0;
  
  /// Ist das Angebot noch gültig?
  bool get isValid => DateTime.now().isBefore(validUntil);
  
  /// Entfernung zu einem Punkt berechnen (grobe Näherung)
  double distanceTo(double lat, double lng) {
    // Vereinfachte Entfernungsberechnung für MVP
    const double earthRadius = 6371; // km
    double latDiff = (lat - storeLat) * (3.14159 / 180);
    double lngDiff = (lng - storeLng) * (3.14159 / 180);
    double a = (latDiff / 2) * (latDiff / 2) + 
               (lngDiff / 2) * (lngDiff / 2);
    return earthRadius * 2 * (a < 1 ? a : 1); // Vereinfacht
  }
}

/// Chain (Händlerkette) Model-Klasse
class Chain {
  final String id;
  final String name;
  final String displayName;
  final String logoUrl;
  final String primaryColor;
  final String website;
  final bool isActive;
  final int storeCount;

  Chain({
    required this.id,
    required this.name,
    required this.displayName,
    required this.logoUrl,
    required this.primaryColor,
    required this.website,
    required this.isActive,
    required this.storeCount,
  });
}

/// Store (Filiale) Model-Klasse
class Store {
  final String id;
  final String chainId;
  final String name;
  final String street;
  final String zipCode;
  final String city;
  final double latitude;
  final double longitude;
  final bool hasBeacon;
  final bool isActive;

  Store({
    required this.id,
    required this.chainId,
    required this.name,
    required this.street,
    required this.zipCode,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.hasBeacon,
    required this.isActive,
  });
}

/// Product (Produkt) Model-Klasse
class Product {
  final String id;
  final String categoryName;
  final String name;
  final String brand;
  final int basePriceCents;
  final bool isActive;

  Product({
    required this.id,
    required this.categoryName,
    required this.name,
    required this.brand,
    required this.basePriceCents,
    required this.isActive,
  });
}

/// Flash Deal Model-Klasse
class FlashDeal {
  final String id;
  final String productName;
  final String brand;
  final String retailer;
  final String storeName;
  final String storeAddress;
  final int originalPriceCents;
  final int flashPriceCents;
  final int discountPercentage;
  final DateTime expiresAt;
  final int remainingSeconds;
  final String urgencyLevel; // 'low', 'medium', 'high'
  final int estimatedStock;
  final ShelfLocation shelfLocation;
  final double storeLat;
  final double storeLng;

  FlashDeal({
    required this.id,
    required this.productName,
    required this.brand,
    required this.retailer,
    required this.storeName,
    required this.storeAddress,
    required this.originalPriceCents,
    required this.flashPriceCents,
    required this.discountPercentage,
    required this.expiresAt,
    required this.remainingSeconds,
    required this.urgencyLevel,
    required this.estimatedStock,
    required this.shelfLocation,
    required this.storeLat,
    required this.storeLng,
  });

  double get originalPrice => originalPriceCents / 100.0;
  double get flashPrice => flashPriceCents / 100.0;
  double get savings => originalPrice - flashPrice;
  int get remainingMinutes => (remainingSeconds / 60).ceil();
  bool get isExpired => remainingSeconds <= 0;

  FlashDeal copyWith({
    String? id,
    String? productName,
    String? brand,
    String? retailer,
    String? storeName,
    String? storeAddress,
    int? originalPriceCents,
    int? flashPriceCents,
    int? discountPercentage,
    DateTime? expiresAt,
    int? remainingSeconds,
    String? urgencyLevel,
    int? estimatedStock,
    ShelfLocation? shelfLocation,
    double? storeLat,
    double? storeLng,
  }) {
    return FlashDeal(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      retailer: retailer ?? this.retailer,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      originalPriceCents: originalPriceCents ?? this.originalPriceCents,
      flashPriceCents: flashPriceCents ?? this.flashPriceCents,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      expiresAt: expiresAt ?? this.expiresAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      estimatedStock: estimatedStock ?? this.estimatedStock,
      shelfLocation: shelfLocation ?? this.shelfLocation,
      storeLat: storeLat ?? this.storeLat,
      storeLng: storeLng ?? this.storeLng,
    );
  }
}

/// Shelf Location für Indoor-Navigation
class ShelfLocation {
  final String aisle;
  final String shelf;
  final int x;
  final int y;

  ShelfLocation({
    required this.aisle,
    required this.shelf,
    required this.x,
    required this.y,
  });
}

/// Sortier-Optionen für Angebote
enum OfferSortType {
  priceAsc,        // Preis aufsteigend
  priceDesc,       // Preis absteigend  
  discountDesc,    // Rabatt absteigend
  distanceAsc,     // Entfernung aufsteigend
  validityDesc,    // Gültigkeitsdauer absteigend
  nameAsc,         // Produktname A-Z
}

/// Simulator für Echtzeit-Rabatte (für Professor-Demo)
class FlashDealSimulator {
  static List<FlashDeal> generateRandomDeals() {
    final random = DateTime.now().millisecondsSinceEpoch;
    
    return [
      FlashDeal(
        id: 'deal_$random',
        productName: 'Frische Milch 1L',
        brand: 'Landliebe',
        retailer: 'EDEKA',
        storeName: 'EDEKA Neukauf',
        storeAddress: 'Musterstr. 15, 10115 Berlin',
        originalPriceCents: 129,
        flashPriceCents: 97,
        discountPercentage: 25,
        expiresAt: DateTime.now().add(const Duration(minutes: 45)),
        remainingSeconds: const Duration(minutes: 45).inSeconds,
        urgencyLevel: 'medium',
        estimatedStock: 15,
        shelfLocation: ShelfLocation(aisle: 'A3', shelf: 'links', x: 120, y: 80),
        storeLat: 52.5200,
        storeLng: 13.4050,
      ),
      FlashDeal(
        id: 'deal_${random + 1}',
        productName: 'Bio Bananen 1kg',
        brand: 'Bio Regional',
        retailer: 'REWE',
        storeName: 'REWE City',
        storeAddress: 'Beispielweg 42, 10115 Berlin',
        originalPriceCents: 299,
        flashPriceCents: 209,
        discountPercentage: 30,
        expiresAt: DateTime.now().add(const Duration(minutes: 25)),
        remainingSeconds: const Duration(minutes: 25).inSeconds,
        urgencyLevel: 'high',
        estimatedStock: 8,
        shelfLocation: ShelfLocation(aisle: 'B1', shelf: 'rechts', x: 200, y: 150),
        storeLat: 52.5200,
        storeLng: 13.4050,
      ),
    ];
  }
  
  // Professor-Demo: Sofortige Rabatt-Generierung
  static FlashDeal generateInstantDemoDeal() {
    final now = DateTime.now();
    return FlashDeal(
      id: 'demo_${now.millisecondsSinceEpoch}',
      productName: 'Schweineschnitzel 500g',
      brand: 'Landfleisch',
      retailer: 'ALDI',
      storeName: 'ALDI SÜD',
      storeAddress: 'Professorweg 1, 10115 Berlin',
      originalPriceCents: 499,
      flashPriceCents: 299,
      discountPercentage: 40,
      expiresAt: now.add(const Duration(minutes: 15)), // Kurze Demo-Zeit
      remainingSeconds: const Duration(minutes: 15).inSeconds,
      urgencyLevel: 'high',
      estimatedStock: 5,
      shelfLocation: ShelfLocation(aisle: 'C2', shelf: 'mitte', x: 300, y: 200),
      storeLat: 52.5200,
      storeLng: 13.4050,
    );
  }
}
