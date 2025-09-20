// Test Helper Utilities für Task 11.7
// Bietet gemeinsame Test-Daten und Utilities für Retailer-Tests

import 'package:flashfeed/models/models.dart';
import 'package:flashfeed/providers/retailers_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/repositories/mock_retailers_repository.dart';

class RetailerTestHelpers {
  
  /// Erstellt einen vorkonfigurierten RetailersProvider für Tests
  static Future<RetailersProvider> createTestProvider({
    MockDataService? mockDataService,
    String? initialPLZ,
  }) async {
    final service = mockDataService ?? MockDataService();
    
    // Initialize test mode to avoid timers
    if (mockDataService == null) {
      await service.initializeMockData(testMode: true);
    }
    
    final repository = MockRetailersRepository(testService: service);
    final provider = RetailersProvider(
      repository: repository,
      mockDataService: service,
      
    );
    
    // Load initial data
    await provider.loadRetailers();
    
    // Set initial PLZ if provided
    if (initialPLZ != null) {
      provider.updateUserLocation(initialPLZ);
    }
    
    return provider;
  }
  
  /// Test-PLZ-Sets für verschiedene Regionen
  static const Map<String, List<String>> testPLZByRegion = {
    'Berlin': ['10115', '10178', '10557', '10999', '12043'],
    'München': ['80331', '80333', '80539', '80799', '81543'],
    'Hamburg': ['20095', '20099', '20357', '20459', '22767'],
    'Köln': ['50667', '50668', '50670', '50674', '50823'],
    'Frankfurt': ['60311', '60313', '60316', '60318', '60329'],
    'Invalid': ['00000', '99999', 'ABCDE', '123', ''],
  };
  
  /// Test-Händler-Namen
  static const List<String> allRetailerNames = [
    'EDEKA', 'REWE', 'ALDI', 'LIDL', 'NETTO', 
    'PENNY', 'KAUFLAND', 'REAL', 'GLOBUS', 'MARKTKAUF', 'BIOCOMPANY'
  ];
  
  /// Erstellt Test-Stores mit verschiedenen Eigenschaften
  static List<Store> createTestStores({
    int count = 5,
    String? retailerName,
    String? plz,
    bool allOpen = false,
    bool allClosed = false,
    List<String>? services,
  }) {
    final stores = <Store>[];
    
    for (int i = 0; i < count; i++) {
      final now = DateTime.now();
      final isOpen = allOpen ? true : (allClosed ? false : i % 2 == 0);
      
      stores.add(Store(
        id: 'test-store-$i',
        chainId: 'chain-${retailerName ?? allRetailerNames[i % allRetailerNames.length]}',
        retailerId: 'retailer-$i',
        retailerName: retailerName ?? allRetailerNames[i % allRetailerNames.length],
        name: 'Test Store $i',
        street: 'Teststraße ${i + 1}',
        zipCode: plz ?? '10115',
        city: 'Berlin',
        latitude: 52.520008 + (i * 0.01),
        longitude: 13.404954 + (i * 0.01),
        phoneNumber: '030-123456$i',
        services: services ?? ['Parkplatz', 'Bäckerei'],
        openingHours: _createTestOpeningHours(isOpen, now),
        hasWifi: i % 3 == 0,
        hasPharmacy: i % 4 == 0,
        hasBeacon: i % 5 == 0,
      ));
    }
    
    return stores;
  }
  
  /// Erstellt Test-OpeningHours
  static Map<String, OpeningHours> _createTestOpeningHours(bool isOpen, DateTime now) {
    if (isOpen) {
      // Store is open from 8:00 to 20:00
      return {
        'Montag': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Dienstag': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Mittwoch': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Donnerstag': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Freitag': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Samstag': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Sonntag': OpeningHours(openMinutes: 10 * 60, closeMinutes: 18 * 60),
      };
    } else {
      // Store is closed (current time outside hours)
      return {
        'Montag': OpeningHours(openMinutes: 9 * 60, closeMinutes: 10 * 60),
        'Dienstag': OpeningHours(openMinutes: 9 * 60, closeMinutes: 10 * 60),
        'Mittwoch': OpeningHours(openMinutes: 9 * 60, closeMinutes: 10 * 60),
        'Donnerstag': OpeningHours(openMinutes: 9 * 60, closeMinutes: 10 * 60),
        'Freitag': OpeningHours(openMinutes: 9 * 60, closeMinutes: 10 * 60),
        'Samstag': OpeningHours(openMinutes: 9 * 60, closeMinutes: 10 * 60),
        'Sonntag': OpeningHours.closed(),
      };
    }
  }
  
  /// Performance-Test Utilities
  static Future<Duration> measurePerformance(Future<void> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }
  
  /// Generiert viele Test-Stores für Performance-Tests
  static List<Store> generateLargeStoreSet(int count) {
    return List.generate(count, (i) => Store(
      id: 'perf-store-$i',
      chainId: 'perf-chain-${i % 10}',
      retailerId: 'perf-retailer-${i % 10}',
      retailerName: allRetailerNames[i % allRetailerNames.length],
      name: 'Performance Test Store $i',
      street: 'Perf Street ${i + 1}',
      zipCode: (10000 + (i % 90000)).toString().padLeft(5, '0'),
      city: i % 3 == 0 ? 'Berlin' : (i % 3 == 1 ? 'München' : 'Hamburg'),
      latitude: 48.0 + (i % 10) * 0.5,
      longitude: 9.0 + (i % 10) * 0.5,
      phoneNumber: '01234-${i.toString().padLeft(6, '0')}',
      services: i % 2 == 0 
        ? ['Parkplatz', 'Bäckerei', 'Payback'] 
        : ['Metzgerei', 'DHL Paketstation'],
      openingHours: {
        'Montag': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Dienstag': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Mittwoch': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Donnerstag': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Freitag': OpeningHours(openMinutes: 8 * 60, closeMinutes: 22 * 60),
        'Samstag': OpeningHours(openMinutes: 8 * 60, closeMinutes: 20 * 60),
        'Sonntag': i % 5 == 0 
          ? OpeningHours(openMinutes: 10 * 60, closeMinutes: 18 * 60)
          : OpeningHours.closed(),
      },
      hasWifi: i % 3 == 0,
      hasPharmacy: i % 7 == 0,
      hasBeacon: i % 11 == 0,
    ));
  }
  
  /// Validiert Retailer-Brand-Farben
  static bool validateBrandColors(Map<String, dynamic> colors) {
    if (!colors.containsKey('primary') && !colors.containsKey('accent')) {
      return false;
    }
    
    // Check if values are Colors
    return colors['primary'] != null || colors['accent'] != null;
  }
  
  /// Mock-Retailer Generator
  static Retailer createMockRetailer({
    required String name,
    bool isNationwide = false,
    List<PLZRange>? plzRanges,
  }) {
    return Retailer(
      id: 'test-${name.toLowerCase()}',
      name: name,
      displayName: name,
      logoUrl: 'https://example.com/logo-$name.png',
      iconUrl: 'https://example.com/icon-$name.png',
      primaryColor: '#FF0000',
      secondaryColor: '#00FF00',
      description: 'Test retailer $name',
      categories: ['Lebensmittel', 'Getränke'],
      website: 'https://www.$name.de',
      storeCount: 100,
      slogan: 'Test slogan for $name',
      availablePLZRanges: plzRanges ?? [],
    );
  }
}
