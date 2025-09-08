// Test-Skript für RetailersProvider Verification
// Dieses Skript testet die grundlegende Funktionalität des RetailersProviders

import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/providers/retailers_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/repositories/mock_retailers_repository.dart';

void main() {
  group('RetailersProvider Basic Tests', () {
    late MockDataService testMockDataService;
    late RetailersProvider provider;
    
    setUp(() async {
      // Initialize MockDataService für Tests
      testMockDataService = MockDataService();
      await testMockDataService.initializeMockData(testMode: true);
      
      // Erstelle Provider mit Mock-Repository
      provider = RetailersProvider(
        repository: MockRetailersRepository(testService: testMockDataService),
        mockDataService: testMockDataService,
      );
      
      // FIX: Wait for initial load to complete
      await provider.loadRetailers();
    });
    
    tearDown(() {
      provider.dispose();
      testMockDataService.dispose();
    });
    
    test('should load retailers on initialization', () {
      // Provider has already loaded in setUp
      expect(provider.allRetailers.isNotEmpty, isTrue);
      expect(provider.totalRetailerCount, greaterThan(0));
      print('✅ Loaded ${provider.totalRetailerCount} retailers');
    });
    
    test('should filter retailers by PLZ (Berlin)', () {
      // Berlin PLZ
      provider.updateUserLocation('10115');
      
      final available = provider.availableRetailers;
      final unavailable = provider.unavailableRetailers;
      
      expect(available.isNotEmpty, isTrue);
      print('✅ Berlin (10115): ${available.length} available, ${unavailable.length} unavailable');
      
      // Prüfe ob EDEKA verfügbar ist (bundesweit)
      expect(available.any((r) => r.name == 'EDEKA'), isTrue);
    });
    
    test('should filter retailers by PLZ (München)', () {
      // München PLZ
      provider.updateUserLocation('80331');
      
      final available = provider.availableRetailers;
      final unavailable = provider.unavailableRetailers;
      
      expect(available.isNotEmpty, isTrue);
      print('✅ München (80331): ${available.length} available, ${unavailable.length} unavailable');
      
      // Prüfe ob REWE verfügbar ist (bundesweit)
      expect(available.any((r) => r.name == 'REWE'), isTrue);
    });
    
    test('should use cache for repeated PLZ queries', () {
      // Erste Anfrage
      provider.updateUserLocation('10115');
      expect(provider.testCache.containsKey('10115'), isTrue);
      
      // Cache sollte wiederverwendet werden
      final cachedResult = provider.getAvailableRetailers('10115');
      expect(cachedResult, equals(provider.testCache['10115']));
      
      print('✅ Cache working for repeated PLZ queries');
    });
    
    test('should generate availability messages correctly', () {
      provider.updateUserLocation('10115');
      
      // Test für bundesweiten Händler
      final edeka = provider.getAvailabilityMessage('EDEKA');
      expect(edeka.contains('bundesweit verfügbar'), isTrue);
      print('✅ EDEKA: $edeka');
      
      // Test für regionalen Händler (falls vorhanden)
      final bioCompany = provider.getAvailabilityMessage('BioCompany');
      print('✅ BioCompany: $bioCompany');
    });
    
    test('should handle invalid PLZ gracefully', () {
      // Ungültige PLZ
      provider.updateUserLocation('12345678'); // Zu lang
      // With invalid PLZ, only nationwide retailers should be available
      expect(provider.availableRetailers.every((r) => r.isNationwide), isTrue);
      
      provider.updateUserLocation('ABC'); // Keine Ziffern
      // With invalid PLZ, only nationwide retailers should be available
      expect(provider.availableRetailers.every((r) => r.isNationwide), isTrue);
      
      print('✅ Invalid PLZ handling works');
    });
    
    test('should calculate availability percentage', () {
      provider.updateUserLocation('10115');
      
      final percentage = provider.availabilityPercentage;
      expect(percentage, greaterThanOrEqualTo(0));
      expect(percentage, lessThanOrEqualTo(100));
      
      print('✅ Availability in Berlin: ${percentage.toStringAsFixed(1)}%');
    });
  });
}
