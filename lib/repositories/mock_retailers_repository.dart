// FlashFeed Mock Retailers Repository Implementation
// Simuliert Händler- und Filial-Daten für MVP

import 'retailers_repository.dart';
import '../models/models.dart';
import '../data/product_category_mapping.dart';
import '../services/mock_data_service.dart';

class MockRetailersRepository implements RetailersRepository {
  final MockDataService? _testService; // Optional test service
  
  MockRetailersRepository({MockDataService? testService}) : _testService = testService;
  
  // Helper to check if we have a service
  bool get _hasDataService => _testService != null && _testService.isInitialized;
  static final List<Retailer> _mockRetailers = [
    Retailer(
      id: 'edeka',
      name: 'EDEKA',
      displayName: 'EDEKA',
      logoUrl: 'assets/logos/edeka.png',
      primaryColor: '#005CA9',
      iconUrl: null,
      description: 'Deutschlands größte Supermarkt-Kooperation mit frischen Produkten',
      categories: ['Molkereiprodukte', 'Frischfleisch', 'Obst', 'Gemüse'],
      isPremiumPartner: true,
      website: 'https://www.edeka.de',
      storeCount: 5,
    ),
    Retailer(
      id: 'rewe',
      name: 'REWE',
      displayName: 'REWE',
      logoUrl: 'assets/logos/rewe.png', 
      primaryColor: '#CC071E',
      iconUrl: null,
      description: 'Ihr Nahversorger mit nachhaltigen Produkten und Service',
      categories: ['Milch & Käse', 'Fleisch & Geflügel', 'Frisches Obst', 'Frisches Gemüse'],
      isPremiumPartner: true,
      website: 'https://www.rewe.de',
      storeCount: 4,
    ),
    Retailer(
      id: 'aldi',
      name: 'ALDI',
      displayName: 'ALDI',
      logoUrl: 'assets/logos/aldi.png',
      primaryColor: '#00A8E6',
      iconUrl: null,
      description: 'Einfach günstig - Qualität zum besten Preis',
      categories: ['Milcherzeugnisse', 'Frischfleisch'],
      isPremiumPartner: false,
      website: 'https://www.aldi-sued.de',
      storeCount: 3,
    ),
    Retailer(
      id: 'lidl',
      name: 'Lidl',
      displayName: 'Lidl',
      logoUrl: 'assets/logos/lidl.png',
      primaryColor: '#0050AA',
      iconUrl: null,
      description: 'Mehr frische Ideen - Qualität, Frische und Swappiness',
      categories: ['Backwaren', 'Milchprodukte'],
      isPremiumPartner: false,
      website: 'https://www.lidl.de',
      storeCount: 3,
    ),
    Retailer(
      id: 'netto_schwarz',
      name: 'Netto Marken-Discount',
      displayName: 'Netto',
      logoUrl: 'assets/logos/netto_red.png',
      primaryColor: '#FF0000',
      iconUrl: null,
      description: 'Jeden Tag ein bisschen besser - günstige Preise, große Auswahl',
      categories: ['Getränke', 'Konserven'],
      isPremiumPartner: false,
      website: 'https://www.netto-online.de',
      storeCount: 3,
    ),
  ];
  
  static final List<Store> _mockStores = [
    // EDEKA Filialen
    Store(
      id: 'edeka_berlin_01',
      chainId: 'edeka',
      retailerName: 'EDEKA',
      name: 'EDEKA Neukauf Berlin Mitte',
      street: 'Musterstraße 15',
      zipCode: '10115',
      city: 'Berlin',
      latitude: 52.5200,
      longitude: 13.4050,
      phoneNumber: '+49 30 12345678',
      openingHours: {
        'Montag': OpeningHours.standard(7, 0, 22, 0),
        'Dienstag': OpeningHours.standard(7, 0, 22, 0),
        'Mittwoch': OpeningHours.standard(7, 0, 22, 0),
        'Donnerstag': OpeningHours.standard(7, 0, 22, 0),
        'Freitag': OpeningHours.standard(7, 0, 22, 0),
        'Samstag': OpeningHours.standard(7, 0, 22, 0),
        'Sonntag': OpeningHours.closed(),
      },
      services: ['Parkplatz', 'Lieferservice', 'Click & Collect'],
      hasWifi: true,
      hasPharmacy: false,
      hasBeacon: true,
    ),
    Store(
      id: 'edeka_berlin_02',
      chainId: 'edeka',
      retailerName: 'EDEKA',
      name: 'EDEKA Supermarkt Berlin Prenzlauer Berg',
      street: 'Danziger Straße 101',
      zipCode: '10405',
      city: 'Berlin',
      latitude: 52.5350,
      longitude: 13.4200,
      phoneNumber: '+49 30 87654321',
      openingHours: {
        'Montag': OpeningHours.standard(6, 0, 24, 0),
        'Dienstag': OpeningHours.standard(6, 0, 24, 0),
        'Mittwoch': OpeningHours.standard(6, 0, 24, 0),
        'Donnerstag': OpeningHours.standard(6, 0, 24, 0),
        'Freitag': OpeningHours.standard(6, 0, 24, 0),
        'Samstag': OpeningHours.standard(6, 0, 24, 0),
        'Sonntag': OpeningHours.standard(8, 0, 22, 0),
      },
      services: ['24h geöffnet', 'Parkplatz'],
      hasWifi: false,
      hasPharmacy: false,
      hasBeacon: true,
    ),
    
    // REWE Filialen  
    Store(
      id: 'rewe_berlin_05',
      chainId: 'rewe',
      retailerName: 'REWE',
      name: 'REWE City Berlin Mitte',
      street: 'Beispielweg 42',
      zipCode: '10117',
      city: 'Berlin',
      latitude: 52.5170,
      longitude: 13.3880,
      phoneNumber: '+49 30 11223344',
      openingHours: {
        'Montag': OpeningHours.standard(7, 0, 23, 0),
        'Dienstag': OpeningHours.standard(7, 0, 23, 0),
        'Mittwoch': OpeningHours.standard(7, 0, 23, 0),
        'Donnerstag': OpeningHours.standard(7, 0, 23, 0),
        'Freitag': OpeningHours.standard(7, 0, 23, 0),
        'Samstag': OpeningHours.standard(7, 0, 23, 0),
        'Sonntag': OpeningHours.closed(),
      },
      services: ['REWE Lieferservice', 'Abholservice', 'PayBack'],
      hasWifi: true,
      hasPharmacy: false,
      hasBeacon: true,
    ),
    
    // ALDI Filialen
    Store(
      id: 'aldi_berlin_demo',
      chainId: 'aldi',
      retailerName: 'ALDI',
      name: 'ALDI SÜD Berlin Mitte',
      street: 'Professorweg 1',
      zipCode: '10119',
      city: 'Berlin',
      latitude: 52.5230,
      longitude: 13.4100,
      phoneNumber: '+49 30 55667788',
      openingHours: {
        'Montag': OpeningHours.standard(7, 0, 21, 0),
        'Dienstag': OpeningHours.standard(7, 0, 21, 0),
        'Mittwoch': OpeningHours.standard(7, 0, 21, 0),
        'Donnerstag': OpeningHours.standard(7, 0, 21, 0),
        'Freitag': OpeningHours.standard(7, 0, 21, 0),
        'Samstag': OpeningHours.standard(7, 0, 21, 0),
        'Sonntag': OpeningHours.closed(),
      },
      services: ['Parkplatz', 'Pfandautomat'],
      hasWifi: false,
      hasPharmacy: false,
      hasBeacon: true,
    ),
    
    // Lidl Filialen
    Store(
      id: 'lidl_berlin_01',
      chainId: 'lidl',
      retailerName: 'Lidl',
      name: 'Lidl Berlin Kreuzberg',
      street: 'Demostraße 99',
      zipCode: '10120',
      city: 'Berlin',
      latitude: 52.5150,
      longitude: 13.3950,
      phoneNumber: '+49 30 99887766',
      openingHours: {
        'Montag': OpeningHours.standard(7, 0, 22, 0),
        'Dienstag': OpeningHours.standard(7, 0, 22, 0),
        'Mittwoch': OpeningHours.standard(7, 0, 22, 0),
        'Donnerstag': OpeningHours.standard(7, 0, 22, 0),
        'Freitag': OpeningHours.standard(7, 0, 22, 0),
        'Samstag': OpeningHours.standard(7, 0, 22, 0),
        'Sonntag': OpeningHours.closed(),
      },
      services: ['Parkplatz', 'Lidl Plus App', 'Bäckerei'],
      hasWifi: false,
      hasPharmacy: false,
      hasBeacon: false,
    ),
    
    // Netto Marken-Discount Filialen
    Store(
      id: 'netto_berlin_01',
      chainId: 'netto_schwarz',
      retailerName: 'Netto Marken-Discount',
      name: 'Netto Marken-Discount Berlin Friedrichshain',
      street: 'Teststraße 50',
      zipCode: '10121',
      city: 'Berlin',
      latitude: 52.5100,
      longitude: 13.3800,
      phoneNumber: '+49 30 44556677',
      openingHours: {
        'Montag': OpeningHours.standard(7, 0, 20, 0),
        'Dienstag': OpeningHours.standard(7, 0, 20, 0),
        'Mittwoch': OpeningHours.standard(7, 0, 20, 0),
        'Donnerstag': OpeningHours.standard(7, 0, 20, 0),
        'Freitag': OpeningHours.standard(7, 0, 20, 0),
        'Samstag': OpeningHours.standard(7, 0, 20, 0),
        'Sonntag': OpeningHours.closed(),
      },
      services: ['Parkplatz', 'DeutschlandCard'],
      hasWifi: false,
      hasPharmacy: false,
      hasBeacon: false,
    ),
  ];

  @override
  Future<List<Retailer>> getAllRetailers() async {
    await Future.delayed(Duration(milliseconds: 200));
    // Use data from MockDataService if available, fallback to static list
    if (_hasDataService) {
      return List.from(_testService!.retailers);
    }
    return List.from(_mockRetailers);
  }

  @override
  Future<Retailer?> getRetailerByName(String name) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    try {
      return _mockRetailers.firstWhere(
        (retailer) => retailer.name.toLowerCase() == name.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Store>> getStoresByRetailer(String retailerName) async {
    await Future.delayed(Duration(milliseconds: 150));
    
    // Use data from MockDataService if available, fallback to static list
    final stores = _hasDataService ? _testService!.stores : _mockStores;
    
    return stores.where((store) =>
      store.retailerName.toLowerCase() == retailerName.toLowerCase()
    ).toList();
  }

  @override
  Future<List<Store>> getStoresByLocation(double latitude, double longitude, double radiusKm) async {
    await Future.delayed(Duration(milliseconds: 200));
    
    // Use data from MockDataService if available, fallback to static list
    final stores = _hasDataService ? _testService!.stores : _mockStores;
    
    return stores.where((store) =>
      store.distanceTo(latitude, longitude) <= radiusKm
    ).toList();
  }

  @override
  Future<Store?> getNearestStore(String retailerName, double latitude, double longitude) async {
    await Future.delayed(Duration(milliseconds: 150));
    
    List<Store> retailerStores = await getStoresByRetailer(retailerName);
    if (retailerStores.isEmpty) return null;
    
    Store? nearestStore;
    double minDistance = double.infinity;
    
    for (Store store in retailerStores) {
      double distance = store.distanceTo(latitude, longitude);
      if (distance < minDistance) {
        minDistance = distance;
        nearestStore = store;
      }
    }
    
    return nearestStore;
  }

  @override
  Future<List<Store>> getOpenStores(DateTime dateTime) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    // Use data from MockDataService if available, fallback to static list
    final stores = _hasDataService ? _testService!.stores : _mockStores;
    
    return stores.where((store) => store.isOpenAt(dateTime)).toList();
  }
  
  /// Zusätzliche Mock-Methoden für Demo
  static void addMockRetailer(Retailer retailer) {
    _mockRetailers.add(retailer);
  }
  
  static void addMockStore(Store store) {
    _mockStores.add(store);
  }
  
  /// Für Professor-Demo: Alle verfügbaren Kategorien
  static List<String> getAllAvailableCategories() {
    return ProductCategoryMapping.flashFeedCategories;
  }
  
  /// Händler-spezifische Kategorien
  static List<String> getRetailerCategories(String retailerName) {
    return ProductCategoryMapping.getRetailerCategories(retailerName);
  }
}
