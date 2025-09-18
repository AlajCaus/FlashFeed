// FlashFeed Data Models
// Zentrale Model-Klassen für Provider und Repository Pattern

import 'dart:math' as math;
import '../data/product_category_mapping.dart';

/// Angebot Model-Klasse
class Offer {
  final String id;
  final String retailer;
  final String productName;
  final String originalCategory;
  final double price;
  final double? originalPrice; // null wenn kein Rabatt
  final String? storeAddress;   // Optional store address
  final String? storeId;        // Optional store ID
  final double? discountPercent; // null wenn kein Rabatt
  final DateTime validUntil;
  final double? storeLat;       // Optional store latitude
  final double? storeLng;       // Optional store longitude

  Offer({
    required this.id,
    required this.retailer,
    required this.productName,
    required this.originalCategory,
    required this.price,
    this.originalPrice,
    this.storeAddress,
    this.storeId,
    this.discountPercent,
    required this.validUntil,
    this.storeLat,
    this.storeLng,
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
    if (storeLat == null || storeLng == null) return 999999; // Unknown distance
    // Vereinfachte Entfernungsberechnung für MVP
    const double earthRadius = 6371; // km
    double latDiff = (lat - storeLat!) * (3.14159 / 180);
    double lngDiff = (lng - storeLng!) * (3.14159 / 180);
    double a = (latDiff / 2) * (latDiff / 2) + 
               (lngDiff / 2) * (lngDiff / 2);
    return earthRadius * 2 * (a < 1 ? a : 1); // Vereinfacht
  }
}

/// PLZ-Bereich für regionale Händler-Verfügbarkeit
class PLZRange {
  final String startPLZ;        // Start-PLZ (z.B. "10000")
  final String endPLZ;          // End-PLZ (z.B. "14999")
  final String regionName;      // Region-Name (z.B. "Berlin/Brandenburg")

  PLZRange({
    required this.startPLZ,
    required this.endPLZ,
    required this.regionName,
  });
  
  /// Prüft ob eine PLZ in diesem Bereich liegt
  bool containsPLZ(String plz) {
    if (plz.length != 5) return false;
    
    try {
      int plzInt = int.parse(plz);
      int startInt = int.parse(startPLZ);
      int endInt = int.parse(endPLZ);
      
      return plzInt >= startInt && plzInt <= endInt;
    } catch (e) {
      return false;
    }
  }
  
  /// String-Darstellung für Debugging
  @override
  String toString() {
    return '$regionName ($startPLZ-$endPLZ)';
  }
}

/// Händler Model-Klasse (konsolidiert Chain + Retailer)
class Retailer {
  final String id;              // Backend-ID (eindeutig)
  final String name;            // Backend-Name (eindeutig)
  final String displayName;     // UI-Text (kann doppelt sein)
  final String? logoUrl;         // Optional logo URL
  final String primaryColor;    // Hex-Color für UI (war brandColor)
  final String? secondaryColor;  // Task 11.2: Sekundäre Farbe für Branding
  final String? iconUrl;        // Zusätzliches Icon (z.B. Scottie)
  final String? slogan;         // Task 11.2: Händler-Slogan (z.B. "ALDI. Einfach ist mehr.")
  final String? description;    // Optional description
  final List<String> categories; // Verfügbare Produktkategorien
  final bool isPremiumPartner;   // Für Freemium-Features (war isActive)
  final String? website;        // Optional website URL (war websiteUrl)
  final int? storeCount;        // Optional store count
  final List<PLZRange> availablePLZRanges; // Regionale Verfügbarkeit (Task 5a)

  Retailer({
    required this.id,
    required this.name,
    required this.displayName,
    this.logoUrl,
    required this.primaryColor,
    this.secondaryColor,      // Task 11.2
    this.iconUrl,
    this.slogan,              // Task 11.2
    this.description,
    this.categories = const [],
    this.isPremiumPartner = false,
    this.website,
    this.storeCount,
    this.availablePLZRanges = const [], // Default: keine regionalen Beschränkungen
  });
  
  /// Anzahl Kategorien die dieser Händler hat
  int get categoryCount => categories.length;
  
  /// Ist Premium-Partner?
  bool get isPreferred => isPremiumPartner;
  
  /// Ist aktiv?
  bool get isActive => true; // Alle Mock-Händler sind aktiv
  
  /// Prüft ob Händler in einer bestimmten PLZ verfügbar ist (Task 5a)
  bool isAvailableInPLZ(String plz) {
    // Wenn keine PLZ-Ranges definiert sind, ist Händler überall verfügbar (bundesweit)
    if (availablePLZRanges.isEmpty) return true;
    
    // Prüfe ob PLZ in einem der verfügbaren Bereiche liegt
    return availablePLZRanges.any((range) => range.containsPLZ(plz));
  }
  
  /// Gibt alle Regionen zurück, in denen der Händler verfügbar ist
  List<String> get availableRegions {
    if (availablePLZRanges.isEmpty) return ['Bundesweit'];
    return availablePLZRanges.map((range) => range.regionName).toList();
  }
  
  /// Ist bundesweit verfügbar?
  bool get isNationwide => availablePLZRanges.isEmpty;
}

/// PLZ-Helper-Service für regionale Verfügbarkeitsprüfung (Task 5a)
class PLZHelper {
  /// Prüft ob eine PLZ gültig ist (5 Ziffern)
  static bool isValidPLZ(String plz) {
    if (plz.length != 5) return false;
    return int.tryParse(plz) != null;
  }
  
  /// Gibt alle verfügbaren Händler für eine PLZ zurück
  static List<Retailer> getAvailableRetailers(String userPLZ, List<Retailer> allRetailers) {
    if (!isValidPLZ(userPLZ)) return [];
    
    return allRetailers.where((retailer) => retailer.isAvailableInPLZ(userPLZ)).toList();
  }
  
  /// Gibt Region-Name für eine PLZ zurück (grobe Zuordnung)
  static String getRegionForPLZ(String plz) {
    if (!isValidPLZ(plz)) return 'Unbekannt';
    
    int plzInt = int.parse(plz);
    
    // Grobe PLZ-Bereiche für Deutschland
    if (plzInt >= 10000 && plzInt <= 16999) return 'Berlin/Brandenburg';
    if (plzInt >= 17000 && plzInt <= 19999) return 'Mecklenburg-Vorpommern';
    if (plzInt >= 20000 && plzInt <= 25999) return 'Hamburg/Schleswig-Holstein';
    if (plzInt >= 26000 && plzInt <= 31999) return 'Niedersachsen/Bremen';
    if (plzInt >= 32000 && plzInt <= 37999) return 'Nordrhein-Westfalen (Ost)';
    if (plzInt >= 38000 && plzInt <= 39999) return 'Sachsen-Anhalt';
    if (plzInt >= 40000 && plzInt <= 48999) return 'Nordrhein-Westfalen (West)';
    if (plzInt >= 49000 && plzInt <= 49999) return 'Nordrhein-Westfalen (Süd)';
    if (plzInt >= 50000 && plzInt <= 53999) return 'Nordrhein-Westfalen/Rheinland-Pfalz';
    if (plzInt >= 54000 && plzInt <= 56999) return 'Rheinland-Pfalz/Saarland';
    if (plzInt >= 57000 && plzInt <= 59999) return 'Nordrhein-Westfalen (Süd)';
    if (plzInt >= 60000 && plzInt <= 63999) return 'Hessen';
    if (plzInt >= 64000 && plzInt <= 65999) return 'Hessen/Rheinland-Pfalz';
    if (plzInt >= 66000 && plzInt <= 66999) return 'Saarland';
    if (plzInt >= 67000 && plzInt <= 76999) return 'Rheinland-Pfalz/Baden-Württemberg';
    if (plzInt >= 77000 && plzInt <= 79999) return 'Baden-Württemberg';
    if (plzInt >= 80000 && plzInt <= 87999) return 'Bayern (Süd)';
    if (plzInt >= 88000 && plzInt <= 89999) return 'Baden-Württemberg/Bayern';
    if (plzInt >= 90000 && plzInt <= 96999) return 'Bayern (Nord)';
    if (plzInt >= 97000 && plzInt <= 97999) return 'Bayern/Baden-Württemberg';
    if (plzInt >= 98000 && plzInt <= 99999) return 'Thüringen/Bayern';
    if (plzInt >= 1000 && plzInt <= 9999) return 'Sachsen/Thüringen';
    
    return 'Deutschland';
  }
}

/// Filiale Model-Klasse (konsolidiert Store Versionen)
class Store {
  final String id;
  final String chainId;         // Retailer ID (von Chain-Version)
  final String retailerId;      // Task 11.2: Retailer ID für getRetailerByStore
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
    String? retailerId,        // Task 11.2: Optional, falls to chainId
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
  }) : retailerId = retailerId ?? chainId;  // Task 11.2: Fallback auf chainId
  
  /// Vollständige Adresse generieren
  String get address => '$street, $zipCode $city';
  
  /// Entfernung zu einem Punkt berechnen (Haversine-Formel)
  double distanceTo(double lat, double lng) {
    const double earthRadius = 6371; // km
    
    // Convert to radians
    double lat1Rad = latitude * (math.pi / 180);
    double lat2Rad = lat * (math.pi / 180);
    double deltaLatRad = (lat - latitude) * (math.pi / 180);
    double deltaLngRad = (lng - longitude) * (math.pi / 180);
    
    // Haversine formula
    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
               math.cos(lat1Rad) * math.cos(lat2Rad) *
               math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
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

  /// Gibt den nächsten Öffnungszeitpunkt zurück (null wenn immer geschlossen)
  DateTime? getNextOpeningTime() {
    final now = DateTime.now();

    // Überprüfe heute und die nächsten 7 Tage
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final checkDate = now.add(Duration(days: dayOffset));
      final weekdayStr = _getWeekdayString(checkDate.weekday);
      final hours = openingHours[weekdayStr];

      if (hours == null || hours.isClosed) continue;

      final openTime = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
        hours.openMinutes ~/ 60,
        hours.openMinutes % 60,
      );

      // Wenn heute und öffnet später, oder zukünftiger Tag
      if (openTime.isAfter(now)) {
        return openTime;
      }
    }

    return null; // Immer geschlossen oder keine Öffnungszeiten
  }

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

/// Task 11.3: Wochentag Enum
enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;
  
  String toGerman() {
    switch (this) {
      case Weekday.monday: return 'Montag';
      case Weekday.tuesday: return 'Dienstag';
      case Weekday.wednesday: return 'Mittwoch';
      case Weekday.thursday: return 'Donnerstag';
      case Weekday.friday: return 'Freitag';
      case Weekday.saturday: return 'Samstag';
      case Weekday.sunday: return 'Sonntag';
    }
  }
  
  static Weekday fromDateTime(DateTime date) {
    // DateTime.weekday: 1=Monday, 7=Sunday
    return Weekday.values[date.weekday - 1];
  }
}

/// Task 11.3: Sonderöffnungszeiten (Feiertage)
class SpecialHours {
  final DateTime date;
  final OpeningHours hours;
  final String description;  // z.B. "Heiligabend", "Neujahr"
  
  SpecialHours({
    required this.date,
    required this.hours,
    required this.description,
  });
  
  bool appliesTo(DateTime checkDate) {
    return date.year == checkDate.year &&
           date.month == checkDate.month &&
           date.day == checkDate.day;
  }
}

/// Öffnungszeiten Model-Klasse - Task 11.3: Erweitert
class OpeningHours {
  final int openMinutes;   // Minuten seit Mitternacht (z.B. 8:00 = 480)
  final int closeMinutes;  // Minuten seit Mitternacht (z.B. 20:00 = 1200)
  final bool isClosed;     // Geschlossen (z.B. Sonntag)
  final bool isSpecialHours;  // Task 11.3: Sonderöffnungszeiten
  final String? specialNote;  // Task 11.3: Hinweis (z.B. "Feiertag")

  OpeningHours({
    required this.openMinutes,
    required this.closeMinutes,
    this.isClosed = false,
    this.isSpecialHours = false,  // Task 11.3
    this.specialNote,              // Task 11.3
  });
  
  /// Task 11.3: Prüft ob jetzt geöffnet ist
  bool isOpenNow() {
    if (isClosed) return false;
    
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    
    // Handle overnight hours (z.B. 20:00 - 02:00)
    if (closeMinutes < openMinutes) {
      return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
    }
    
    return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  }
  
  /// Task 11.3: Zeit bis zur Öffnung/Schließung
  Duration? timeUntilOpen() {
    if (isClosed) return null;
    if (isOpenNow()) return Duration.zero;
    
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    
    // Calculate minutes until opening
    int minutesUntilOpen;
    if (nowMinutes < openMinutes) {
      minutesUntilOpen = openMinutes - nowMinutes;
    } else {
      // Next day opening
      minutesUntilOpen = (24 * 60 - nowMinutes) + openMinutes;
    }
    
    return Duration(minutes: minutesUntilOpen);
  }
  
  /// Task 11.3: Zeit bis zur Schließung
  Duration? timeUntilClose() {
    if (isClosed || !isOpenNow()) return null;
    
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    
    // Handle overnight hours
    if (closeMinutes < openMinutes && nowMinutes < closeMinutes) {
      return Duration(minutes: closeMinutes - nowMinutes);
    }
    
    if (closeMinutes >= nowMinutes) {
      return Duration(minutes: closeMinutes - nowMinutes);
    }
    
    // Closing tomorrow
    return Duration(minutes: (24 * 60 - nowMinutes) + closeMinutes);
  }
  
  /// Task 11.3: Status-Nachricht für UI
  String getStatusMessage() {
    if (isClosed) {
      return specialNote ?? 'Geschlossen';
    }
    
    if (isOpenNow()) {
      final timeLeft = timeUntilClose();
      if (timeLeft != null) {
        if (timeLeft.inMinutes < 60) {
          return 'Schließt in ${timeLeft.inMinutes} Min';
        } else {
          return 'Geöffnet bis ${_formatTime(closeMinutes)}';
        }
      }
      return 'Geöffnet';
    } else {
      final timeUntil = timeUntilOpen();
      if (timeUntil != null) {
        if (timeUntil.inHours < 1) {
          return 'Öffnet in ${timeUntil.inMinutes} Min';
        } else if (timeUntil.inHours < 24) {
          return 'Öffnet um ${_formatTime(openMinutes)}';
        } else {
          return 'Öffnet morgen um ${_formatTime(openMinutes)}';
        }
      }
      return 'Geschlossen';
    }
  }
  
  /// Task 11.3: Zeit formatieren (480 -> "8:00")
  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }
  
  /// Task 11.3: Öffnungszeiten als String ("8:00 - 20:00")
  String toTimeString() {
    if (isClosed) return 'Geschlossen';
    return '${_formatTime(openMinutes)} - ${_formatTime(closeMinutes)}';
  }
  
  /// Factory für geschlossene Tage
  factory OpeningHours.closed({String? note}) {
    return OpeningHours(
      openMinutes: 0,
      closeMinutes: 0,
      isClosed: true,
      specialNote: note,
    );
  }
  
  /// Task 11.3: Factory für Standard-Öffnungszeiten
  factory OpeningHours.standard() {
    return OpeningHours(
      openMinutes: 7 * 60,   // 7:00
      closeMinutes: 20 * 60,  // 20:00
    );
  }
  
  /// Task 11.3: Factory für erweiterte Öffnungszeiten
  factory OpeningHours.extended() {
    return OpeningHours(
      openMinutes: 7 * 60,   // 7:00
      closeMinutes: 22 * 60,  // 22:00
    );
  }
  
  /// Task 11.3: Factory für Sonntagsöffnung
  factory OpeningHours.sunday() {
    return OpeningHours(
      openMinutes: 10 * 60,   // 10:00
      closeMinutes: 18 * 60,  // 18:00
    );
  }
  
  /// Factory für Custom-Öffnungszeiten mit spezifischen Zeiten
  factory OpeningHours.custom(int openHour, int openMin, int closeHour, int closeMin) {
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
