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

/// Händler Model-Klasse (konsolidiert Chain + Retailer)
class Retailer {
  final String id;              // Backend-ID (eindeutig)
  final String name;            // Backend-Name (eindeutig)
  final String displayName;     // UI-Text (kann doppelt sein)
  final String logoUrl;
  final String primaryColor;    // Hex-Color für UI (war brandColor)
  final String? iconUrl;        // Zusätzliches Icon (z.B. Scottie)
  final String description;
  final List<String> categories; // Verfügbare Produktkategorien
  final bool isPremiumPartner;   // Für Freemium-Features (war isActive)
  final String website;         // Website URL (war websiteUrl)
  final int storeCount;         // Anzahl Filialen

  Retailer({
    required this.id,
    required this.name,
    required this.displayName,
    required this.logoUrl,
    required this.primaryColor,
    this.iconUrl,
    required this.description,
    required this.categories,
    this.isPremiumPartner = false,
    required this.website,
    required this.storeCount,
  });
  
  /// Anzahl Kategorien die dieser Händler hat
  int get categoryCount => categories.length;
  
  /// Ist Premium-Partner?
  bool get isPreferred => isPremiumPartner;
  
  /// Ist aktiv?
  bool get isActive => true; // Alle Mock-Händler sind aktiv
}

/// Filiale Model-Klasse (konsolidiert Store Versionen)
class Store {
  final String id;
  final String chainId;         // Retailer ID (von Chain-Version)
  final String retailerName;    // Retailer Name (von Store-Version)
  final String name;
  final String street;          // Straße (separiert von address)
  final String zipCode;         // PLZ (für regionale Filterung)
  final String city;            // Stadt

  final double latitude;
  final double longitude;
  final String phoneNumber;     // Telefonnummer
  final Map<String, OpeningHours> openingHours; // Wochentag -> Öffnungszeiten
  final List<String> services;  // ['Parkplatz', 'Lieferservice', etc.]
  final bool hasWifi;
  final bool hasPharmacy;
  final bool hasBeacon;         // Für Indoor-Navigation
  final bool isActive;

  Store({
    required this.id,
    required this.chainId,
    required this.retailerName,
    required this.name,
    required this.street,
    required this.zipCode,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.openingHours,
    this.services = const [],
    this.hasWifi = false,
    this.hasPharmacy = false,
    this.hasBeacon = false,
    this.isActive = true,
  });
  
  /// Vollständige Adresse generieren
  String get address => '$street, $zipCode $city';
  
  /// Entfernung zu einem Punkt berechnen
  double distanceTo(double lat, double lng) {
    const double earthRadius = 6371;
    double latDiff = (lat - latitude) * (3.14159 / 180);
    double lngDiff = (lng - longitude) * (3.14159 / 180);
    double a = (latDiff / 2) * (latDiff / 2) + 
               (lngDiff / 2) * (lngDiff / 2);
    return earthRadius * 2 * (a < 1 ? a : 1);
  }
  
  /// Ist die Filiale zu einem bestimmten Zeitpunkt geöffnet?
  bool isOpenAt(DateTime dateTime) {
    String weekday = _getWeekdayString(dateTime.weekday);
    OpeningHours? hours = openingHours[weekday];
    
    if (hours == null || hours.isClosed) return false;
    
    int timeMinutes = dateTime.hour * 60 + dateTime.minute;
    return timeMinutes >= hours.openMinutes && timeMinutes <= hours.closeMinutes;
  }
  
  /// Ist die Filiale jetzt geöffnet?
  bool get isOpenNow => isOpenAt(DateTime.now());
  
  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1: return 'Montag';
      case 2: return 'Dienstag';
      case 3: return 'Mittwoch';
      case 4: return 'Donnerstag';
      case 5: return 'Freitag';
      case 6: return 'Samstag';
      case 7: return 'Sonntag';
      default: return 'Montag';
    }
  }
}

/// Öffnungszeiten Model-Klasse
class OpeningHours {
  final int openMinutes;   // Minuten seit Mitternacht (z.B. 8:00 = 480)
  final int closeMinutes;  // Minuten seit Mitternacht (z.B. 20:00 = 1200)
  final bool isClosed;     // Geschlossen (z.B. Sonntag)

  OpeningHours({
    required this.openMinutes,
    required this.closeMinutes,
    this.isClosed = false,
  });
  
  /// Factory für geschlossene Tage
  factory OpeningHours.closed() {
    return OpeningHours(
      openMinutes: 0,
      closeMinutes: 0,
      isClosed: true,
    );
  }
  
  /// Factory für Standard-Öffnungszeiten
  factory OpeningHours.standard(int openHour, int openMin, int closeHour, int closeMin) {
    return OpeningHours(
      openMinutes: openHour * 60 + openMin,
      closeMinutes: closeHour * 60 + closeMin,
    );
  }
  
  /// Öffnungszeit als String (z.B. "08:00 - 20:00")
  String get displayTime {
    if (isClosed) return 'Geschlossen';
    
    int openHour = openMinutes ~/ 60;
    int openMin = openMinutes % 60;
    int closeHour = closeMinutes ~/ 60;
    int closeMin = closeMinutes % 60;
    
    return '${openHour.toString().padLeft(2, '0')}:${openMin.toString().padLeft(2, '0')} - '
           '${closeHour.toString().padLeft(2, '0')}:${closeMin.toString().padLeft(2, '0')}';
  }
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
