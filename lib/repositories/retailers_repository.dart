// FlashFeed Retailers Repository Interface
// Repository Pattern für Händler-Management

import '../models/models.dart';

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
  
  /// Task 11.4: Alle Stores laden für Store-Search
  Future<List<Store>> getAllStores();
}
