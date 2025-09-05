// FlashFeed Offers Repository Interface
// Repository Pattern für BLoC-Migration Ready

import '../models/models.dart';

/*
 * MIGRATION-KOMPATIBILITÄT:
 * - Interface bleibt unverändert für BLoC-Migration
 * - Nur Provider/BLoC-Layer ändert sich später
 * - Model-Klassen jetzt zentral in lib/models/models.dart
 */

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
