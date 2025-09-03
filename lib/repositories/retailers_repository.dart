// FlashFeed Retailers Repository Interface
// Repository Pattern für Händler-Management

abstract class RetailersRepository {
  /// Alle verfügbaren Händler laden
  Future<List<Retailer>> getAllRetailers();
  
  /// Händler nach Namen suchen
  Future<Retailer?> getRetailerByName(String name);
  
  /// Alle Filialen eines Händlers
  Future<List<Store>> getStoresByRetailer(String retailerName);
  
  /// Filialen nach Standort filtern (Radius in km)
  Future<List<Store>> getStoresByLocation(double latitude, double longitude, double radiusKm);
  
  /// Nächstgelegene Filiale finden
  Future<Store?> getNearestStore(String retailerName, double latitude, double longitude);
  
  /// Geöffnete Filialen zum aktuellen Zeitpunkt
  Future<List<Store>> getOpenStores(DateTime dateTime);
}

/// Händler Model-Klasse
class Retailer {
  final String name;            // Backend-ID (eindeutig)
  final String displayName;     // UI-Text (kann doppelt sein)
  final String logoUrl;
  final String brandColor;      // Hex-Color für UI
  final String? iconUrl;        // Zusätzliches Icon (z.B. Scottie)
  final String description;
  final List<String> categories; // Verfügbare Produktkategorien
  final bool isPremiumPartner;   // Für Freemium-Features
  final String websiteUrl;

  Retailer({
    required this.name,
    required this.displayName,
    required this.logoUrl,
    required this.brandColor,
    this.iconUrl,
    required this.description,
    required this.categories,
    this.isPremiumPartner = false,
    required this.websiteUrl,
  });
  
  /// Anzahl Kategorien die dieser Händler hat
  int get categoryCount => categories.length;
  
  /// Ist Premium-Partner?
  bool get isPreferred => isPremiumPartner;
}

/// Filiale Model-Klasse
class Store {
  final String id;
  final String retailerName;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final Map<String, OpeningHours> openingHours; // Wochentag -> Öffnungszeiten
  final List<String> services; // ['Parkplatz', 'Lieferservice', etc.]
  final bool hasWifi;
  final bool hasPharmacy;

  Store({
    required this.id,
    required this.retailerName,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.openingHours,
    this.services = const [],
    this.hasWifi = false,
    this.hasPharmacy = false,
  });
  
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
