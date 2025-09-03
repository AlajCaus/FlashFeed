// FlashFeed Offers Repository Interface
// Repository Pattern für BLoC-Migration Ready

abstract class OffersRepository {
  /// Alle Angebote laden
  Future<List<Offer>> getAllOffers();
  
  /// Angebote nach Kategorie filtern
  Future<List<Offer>> getOffersByCategory(String flashFeedCategory);
  
  /// Angebote nach Händler filtern
  Future<List<Offer>> getOffersByRetailer(String retailer);
  
  /// Angebote nach Standort filtern (Radius in km)
  Future<List<Offer>> getOffersByLocation(double latitude, double longitude, double radiusKm);
  
  /// Angebote suchen (Produktname)
  Future<List<Offer>> searchOffers(String searchTerm);
  
  /// Angebote sortieren
  Future<List<Offer>> getSortedOffers(List<Offer> offers, OfferSortType sortType);
}

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
    // Import wird in Mock-Implementation hinzugefügt
    return 'Sonstiges'; // Fallback
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

/// Sortier-Optionen für Angebote
enum OfferSortType {
  priceAsc,        // Preis aufsteigend
  priceDesc,       // Preis absteigend  
  discountDesc,    // Rabatt absteigend
  distanceAsc,     // Entfernung aufsteigend
  validityDesc,    // Gültigkeitsdauer absteigend
  nameAsc,         // Produktname A-Z
}
