// FlashFeed Mock Retailers Repository Implementation
// Simuliert Händler- und Filial-Daten für MVP

import 'retailers_repository.dart';
import '../data/product_category_mapping.dart';

class MockRetailersRepository implements RetailersRepository {
  static final List<Retailer> _mockRetailers = [
    Retailer(
      name: 'EDEKA',
      logoUrl: 'assets/logos/edeka.png',
      brandColor: '#005CA9',
      description: 'Deutschlands größte Supermarkt-Kooperation mit frischen Produkten',
      categories: ['Molkereiprodukte', 'Frischfleisch', 'Obst', 'Gemüse'],
      isPremiumPartner: true,
      websiteUrl: 'https://www.edeka.de',
    ),
    Retailer(
      name: 'REWE',
      logoUrl: 'assets/logos/rewe.png', 
      brandColor: '#CC071E',
      description: 'Ihr Nahversorger mit nachhaltigen Produkten und Service',
      categories: ['Milch & Käse', 'Fleisch & Geflügel', 'Frisches Obst', 'Frisches Gemüse'],
      isPremiumPartner: true,
      websiteUrl: 'https://www.rewe.de',
    ),
    Retailer(
      name: 'ALDI',
      logoUrl: 'assets/logos/aldi.png',
      brandColor: '#00A8E6',
      description: 'Einfach günstig - Qualität zum besten Preis',
      categories: ['Milcherzeugnisse', 'Frischfleisch'],
      isPremiumPartner: false,
      websiteUrl: 'https://www.aldi-sued.de',
    ),
    Retailer(
      name: 'Lidl',
      logoUrl: 'assets/logos/lidl.png',
      brandColor: '#0050AA',
      description: 'Mehr frische Ideen - Qualität, Frische und Swappiness',
      categories: ['Backwaren', 'Milchprodukte'],
      isPremiumPartner: false,
      websiteUrl: 'https://www.lidl.de',
    ),
    Retailer(
      name: 'Netto',
      logoUrl: 'assets/logos/netto.png',
      brandColor: '#FFCC00',
      description: 'Der Scottie hat\'s - günstig und gut',
      categories: ['Getränke', 'Konserven'],
      isPremiumPartner: false,
      websiteUrl: 'https://www.netto-online.de',
    ),
  ];
  
  static final List<Store> _mockStores = [
    // EDEKA Filialen
    Store(
      id: 'edeka_berlin_01',
      retailerName: 'EDEKA',
      name: 'EDEKA Neukauf Berlin Mitte',
      address: 'Musterstraße 15, 10115 Berlin',
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
    ),
    Store(
      id: 'edeka_berlin_02',
      retailerName: 'EDEKA',
      name: 'EDEKA Supermarkt Berlin Prenzlauer Berg',
      address: 'Danziger Straße 101, 10405 Berlin',
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
    ),
    
    // REWE Filialen  
    Store(
      id: 'rewe_berlin_05',
      retailerName: 'REWE',
      name: 'REWE City Berlin Mitte',
      address: 'Beispielweg 42, 10117 Berlin',
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
    ),
    
    // ALDI Filialen
    Store(
      id: 'aldi_berlin_demo',
      retailerName: 'ALDI',
      name: 'ALDI SÜD Berlin Mitte',
      address: 'Professorweg 1, 10119 Berlin',
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
    ),
    
    // Lidl Filialen
    Store(
      id: 'lidl_berlin_01',
      retailerName: 'Lidl',
      name: 'Lidl Berlin Kreuzberg',
      address: 'Demostraße 99, 10120 Berlin',
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
    ),
    
    // Netto Filialen
    Store(
      id: 'netto_berlin_01',
      retailerName: 'Netto',
      name: 'Netto Berlin Friedrichshain',
      address: 'Teststraße 50, 10121 Berlin',
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
    ),
  ];

  @override
  Future<List<Retailer>> getAllRetailers() async {
    await Future.delayed(Duration(milliseconds: 200));
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
    
    return _mockStores.where((store) =>
      store.retailerName.toLowerCase() == retailerName.toLowerCase()
    ).toList();
  }

  @override
  Future<List<Store>> getStoresByLocation(double latitude, double longitude, double radiusKm) async {
    await Future.delayed(Duration(milliseconds: 200));
    
    return _mockStores.where((store) =>
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
    
    return _mockStores.where((store) => store.isOpenAt(dateTime)).toList();
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
