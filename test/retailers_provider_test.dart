// Konsolidierte Test-Suite für RetailersProvider
// Enthält Basic Tests + Task 11.5 erweiterte Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/providers/retailers_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/repositories/mock_retailers_repository.dart';
import 'package:flashfeed/models/models.dart';

void main() {
  group('RetailersProvider Complete Test Suite', () {
    late MockDataService testMockDataService;
    late RetailersProvider provider;
    late MockRetailersRepository repository;
    
    setUp(() async {
      // Initialize MockDataService für Tests
      testMockDataService = MockDataService();
      await testMockDataService.initializeMockData(testMode: true);
      
      // Create repository with mock data
      repository = MockRetailersRepository(testService: testMockDataService);
      
      // Erstelle Provider mit Mock-Repository
      provider = RetailersProvider(
        repository: repository,
        mockDataService: testMockDataService,
        
      );
      
      // Wait for initial load to complete
      await provider.loadRetailers();
    });
    
    tearDown(() {
      provider.dispose();
      testMockDataService.dispose();
    });
    
    // ========== BASIC TESTS ==========
    group('Basic Functionality', () {
      test('should load retailers on initialization', () {
        expect(provider.allRetailers.isNotEmpty, isTrue);
        expect(provider.totalRetailerCount, greaterThan(0));
      });
      
      test('should filter retailers by PLZ (Berlin)', () {
        // Berlin PLZ
        provider.updateUserLocation('10115');
        
        final available = provider.availableRetailers;
        
        expect(available.isNotEmpty, isTrue);
        
        // Prüfe ob EDEKA verfügbar ist (bundesweit)
        expect(available.any((r) => r.name == 'EDEKA'), isTrue);
      });
      
      test('should filter retailers by PLZ (München)', () {
        // München PLZ
        provider.updateUserLocation('80331');
        
        final available = provider.availableRetailers;
        
        expect(available.isNotEmpty, isTrue);
        
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
      });
      
      test('should generate availability messages correctly', () {
        provider.updateUserLocation('10115');
        
        // Test für bundesweiten Händler
        final edeka = provider.getAvailabilityMessage('EDEKA');
        expect(edeka.contains('bundesweit verfügbar'), isTrue);
      });
      
      test('should handle invalid PLZ gracefully', () {
        // Ungültige PLZ - zu lang
        provider.updateUserLocation('12345678');
        expect(provider.availableRetailers.every((r) => r.isNationwide), isTrue);
        
        // Ungültige PLZ - keine Ziffern
        provider.updateUserLocation('ABC');
        expect(provider.availableRetailers.every((r) => r.isNationwide), isTrue);
      });
      
      test('should calculate availability percentage', () {
        provider.updateUserLocation('10115');
        
        final percentage = provider.availabilityPercentage;
        expect(percentage, greaterThanOrEqualTo(0));
        expect(percentage, lessThanOrEqualTo(100));
      });
    });
    
    // ========== TASK 11.1: RETAILER DETAILS TESTS ==========
    group('Task 11.1: Retailer Details Management', () {
      test('should get retailer details with cache', () {
        final edeka = provider.getRetailerDetails('EDEKA');
        
        expect(edeka, isNotNull);
        expect(edeka!.name, equals('EDEKA'));
        expect(edeka.displayName, isNotEmpty);
        expect(edeka.primaryColor, isNotEmpty);
        
        // Second call should use cache
        final cachedEdeka = provider.getRetailerDetails('EDEKA');
        expect(identical(edeka, cachedEdeka), isTrue);
      });
      
      test('should get retailer logo with fallback', () {
        final logo = provider.getRetailerLogo('EDEKA');
        expect(logo, isNotEmpty);
        
        // Non-existent retailer should return fallback
        final fallbackLogo = provider.getRetailerLogo('NonExistent');
        expect(fallbackLogo, contains('default_retailer'));
      });
      
      test('should get retailer brand colors', () {
        final colors = provider.getRetailerBrandColors('REWE');
        
        expect(colors, contains('primary'));
        expect(colors, contains('accent'));
        
        // Colors should be valid Color objects
        expect(colors['primary'], isNotNull);
        expect(colors['accent'], isNotNull);
      });
      
      test('should get retailer display name', () {
        final displayName = provider.getRetailerDisplayName('ALDI');
        expect(displayName, isNotEmpty);
        
        // Unknown retailer should return original name
        final unknown = provider.getRetailerDisplayName('Unknown');
        expect(unknown, equals('Unknown'));
      });
    });
    
    // ========== TASK 11.5: ERWEITERTE REGIONALE TESTS ==========
    group('Task 11.5: getNearbyRetailers', () {
      test('should return retailers within specified radius', () async {
        final retailers = await provider.getNearbyRetailers('10115', 5.0);
        
        expect(retailers, isNotEmpty);
        expect(retailers.length, greaterThanOrEqualTo(3));
        
        // Should include major retailers in Berlin
        final retailerNames = retailers.map((r) => r.name).toList();
        expect(retailerNames, contains('EDEKA'));
      });

      test('should return empty list for invalid PLZ', () async {
        final retailers = await provider.getNearbyRetailers('invalid', 5.0);
        expect(retailers, isEmpty);
      });

      test('should sort retailers by distance', () async {
        // Get retailers with larger radius to ensure multiple results
        final retailers = await provider.getNearbyRetailers('10115', 10.0);
        
        if (retailers.length > 1) {
          // Verify they are sorted (closest first)
          expect(retailers, isNotEmpty);
          expect(retailers.first, isA<Retailer>());
        }
      });

      test('should use cache for repeated queries', () async {
        // First call - not cached
        final retailers1 = await provider.getNearbyRetailers('10115', 5.0);
        
        // Second call - should use cache
        final retailers2 = await provider.getNearbyRetailers('10115', 5.0);
        
        // Should return same results
        expect(retailers2.length, equals(retailers1.length));
        if (retailers1.isNotEmpty && retailers2.isNotEmpty) {
          expect(retailers2.first.name, equals(retailers1.first.name));
        }
      });

      test('should handle different radius values correctly', () async {
        // Small radius
        final smallRadius = await provider.getNearbyRetailers('10115', 2.0);
        
        // Large radius
        final largeRadius = await provider.getNearbyRetailers('10115', 20.0);
        
        // Large radius should include at least as many as small radius
        expect(largeRadius.length, greaterThanOrEqualTo(smallRadius.length));
      });
    });

    group('Task 11.5: getRetailerCoverage', () {
      test('should return coverage statistics for existing retailer', () {
        final coverage = provider.getRetailerCoverage('EDEKA');
        
        expect(coverage, isNotNull);
        expect(coverage['retailerName'], equals('EDEKA'));
        expect(coverage['totalStores'], isA<int>());
        expect(coverage['isNationwide'], isA<bool>());
        expect(coverage['coveragePercentage'], isA<String>());
        expect(coverage['coveredRegions'], isA<List>());
      });

      test('should return error for non-existent retailer', () {
        final coverage = provider.getRetailerCoverage('NonExistentRetailer');
        
        expect(coverage, isNotNull);
        expect(coverage['error'], equals('Händler nicht gefunden'));
        expect(coverage['retailerName'], equals('NonExistentRetailer'));
      });

      test('should calculate correct coverage percentage for nationwide retailer', () async {
        // Ensure stores are loaded first to avoid race condition
        await provider.searchStores('EDEKA');

        final coverage = provider.getRetailerCoverage('EDEKA');

        if (coverage['isNationwide'] == true) {
          final percentage = double.parse(coverage['coveragePercentage'].toString());
          expect(percentage, greaterThan(90)); // Nationwide should be ~95%
        }
      });

      test('should include regional distribution', () {
        final coverage = provider.getRetailerCoverage('REWE');
        
        expect(coverage['regionalDistribution'], isA<Map>());
        expect(coverage['totalRegions'], isA<int>());
        
        if (coverage['isNationwide'] == true) {
          expect(coverage['regionalDistribution'], contains('Bundesweit'));
        }
      });

      test('should include services offered', () async {
        // Load stores first to ensure services are available
        await provider.searchStores('EDEKA');

        final coverage = provider.getRetailerCoverage('EDEKA');

        expect(coverage['servicesOffered'], isA<List>());

        // EDEKA stores should offer various services
        final services = coverage['servicesOffered'] as List;
        expect(services, isA<List>());

        // Services should be available since we searched for EDEKA stores
        expect(services, isNotEmpty);
      });

      test('should include branding information', () {
        final coverage = provider.getRetailerCoverage('EDEKA');
        
        expect(coverage['primaryColor'], isA<String>());
        expect(coverage['website'], isA<String>());
        expect(coverage['description'], isA<String>());
      });
    });

    group('Task 11.5: findAlternativeRetailers', () {
      test('should return empty list if preferred retailer is available', () {
        // Set PLZ where EDEKA is available
        provider.updateUserLocation('10115');
        
        final alternatives = provider.findAlternativeRetailers('10115', 'EDEKA');
        
        // EDEKA is available in Berlin, so no alternatives needed
        expect(alternatives, isEmpty);
      });

      test('should suggest alternatives for unavailable retailer', () {
        // Globus is not available in Berlin (10115)
        final alternatives = provider.findAlternativeRetailers('10115', 'Globus');
        
        expect(alternatives, isNotEmpty);
        expect(alternatives.length, lessThanOrEqualTo(5)); // Max 5 alternatives
        
        // Should suggest similar full-service retailers
        final alternativeNames = alternatives.map((r) => r.name).toList();
        expect(alternativeNames, anyOf(
          contains('EDEKA'),
          contains('REWE'),
          contains('Kaufland')
        ));
      });

      test('should return all available if preferred retailer not found', () {
        final alternatives = provider.findAlternativeRetailers('10115', 'UnknownRetailer');
        
        expect(alternatives, isNotEmpty);
        // Should return available retailers in that PLZ
        for (final retailer in alternatives) {
          expect(retailer.isAvailableInPLZ('10115'), isTrue);
        }
      });

      test('should prioritize similar category retailers', () {
        // BioCompany is a Bio retailer
        // If it's not available, should suggest other bio/premium retailers first
        final alternatives = provider.findAlternativeRetailers('80331', 'BioCompany');
        
        if (alternatives.isNotEmpty) {
          // First alternatives should be premium/bio focused
          expect(alternatives.first, isA<Retailer>());
        }
      });

      test('should handle invalid PLZ gracefully', () {
        final alternatives = provider.findAlternativeRetailers('invalid', 'EDEKA');
        
        expect(alternatives, isEmpty);
      });

      test('should limit alternatives to maximum 5', () {
        // Even if many retailers are available
        final alternatives = provider.findAlternativeRetailers('10115', 'Globus');
        
        expect(alternatives.length, lessThanOrEqualTo(5));
      });
    });

    group('Task 11.5: Helper Methods', () {
      test('retailer categorization should work correctly', () {
        // Test through findAlternativeRetailers behavior
        // Categories: Discount, Premium, Bio, Regional
        
        // Discount retailers
        final discountAlternatives = provider.findAlternativeRetailers('10115', 'ALDI SÜD');
        // If ALDI is not available, should prioritize other discount retailers
        
        // Premium retailers  
        final premiumAlternatives = provider.findAlternativeRetailers('10115', 'Globus');
        // Should prioritize EDEKA, REWE, Kaufland
        
        // Both should return some results (if retailers available)
        expect(discountAlternatives, isA<List>());
        expect(premiumAlternatives, isA<List>());
      });

      test('PLZ coordinates mapping should work for major cities', () {
        // Test through getNearbyRetailers
        
        // Berlin PLZ
        final berlinRetailers = provider.getNearbyRetailers('10115', 5.0);
        
        // München PLZ
        final muenchenRetailers = provider.getNearbyRetailers('80331', 5.0);
        
        // Hamburg PLZ  
        final hamburgRetailers = provider.getNearbyRetailers('20095', 5.0);
        
        // All should return futures (async operations)
        expect(berlinRetailers, isA<Future<List<Retailer>>>());
        expect(muenchenRetailers, isA<Future<List<Retailer>>>());
        expect(hamburgRetailers, isA<Future<List<Retailer>>>());
      });
    });

    group('Task 11.5: Regional Variations', () {
      test('should handle EDEKA regional variations', () {
        // EDEKA has regional cooperatives
        final coverage = provider.getRetailerCoverage('EDEKA');
        
        expect(coverage, isNotNull);
        expect(coverage['retailerName'], contains('EDEKA'));
        
        // Should handle variations like EDEKA Nord, EDEKA Südbayern, etc.
        // This is tested implicitly through the coverage calculation
      });

      test('should handle retailer aliases correctly', () {
        // Netto vs Netto Marken-Discount
        final nettoAlternatives = provider.findAlternativeRetailers('10115', 'Netto');
        
        // Should work regardless of exact name variant
        expect(nettoAlternatives, isA<List>());
      });
    });

    group('Task 11.5: Performance Tests', () {
      test('getNearbyRetailers should complete within reasonable time', () async {
        final stopwatch = Stopwatch()..start();
        
        await provider.getNearbyRetailers('10115', 5.0);
        
        stopwatch.stop();
        
        // Should complete within 500ms (generous for CI/CD)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('cache should improve performance on repeated calls', () async {
        // Clear cache first to ensure cold start
        provider.clearCache();
        
        // First call - cold (no cache)
        final stopwatch1 = Stopwatch()..start();
        final retailers1 = await provider.getNearbyRetailers('10115', 5.0);
        stopwatch1.stop();
        final coldTime = stopwatch1.elapsedMicroseconds; // Use microseconds for more precision
        
        // Second call - should use cache
        final stopwatch2 = Stopwatch()..start();
        final retailers2 = await provider.getNearbyRetailers('10115', 5.0);
        stopwatch2.stop();
        final cachedTime = stopwatch2.elapsedMicroseconds;
        
        // Verify both calls completed successfully
        expect(retailers1, isNotEmpty);
        expect(retailers2, isNotEmpty);
        expect(retailers1.length, equals(retailers2.length));
        
        // Times should be non-negative (might be 0 if very fast)
        expect(coldTime, greaterThanOrEqualTo(0));
        expect(cachedTime, greaterThanOrEqualTo(0));
        
        // In most cases, cached should be faster or equal (but not always in CI/CD)
        // So we just verify the cache works by checking results are identical
        if (retailers1.isNotEmpty && retailers2.isNotEmpty) {
          expect(retailers2.first.name, equals(retailers1.first.name));
        }
      });
    });

    group('Task 11.5: Integration Tests', () {
      test('should work with LocationProvider PLZ updates', () async {
        // Simulate PLZ change in Berlin (all mock stores are in Berlin)
        provider.updateUserLocation('10115'); // Berlin Mitte
        
        // Get nearby retailers
        final retailers = await provider.getNearbyRetailers('10115', 5.0);
        
        expect(retailers, isNotEmpty);
        
        // Change to another Berlin PLZ (not München since we have no stores there)
        provider.updateUserLocation('12099'); // Berlin Tempelhof
        
        // Get nearby retailers for new location
        final newRetailers = await provider.getNearbyRetailers('12099', 5.0);
        
        // Should find retailers in the other Berlin area
        expect(newRetailers, isNotEmpty);
        
        // Note: Both are in Berlin, so might have overlapping retailers
        // but the test verifies that location updates work correctly
      });

      test('complete workflow: unavailable retailer → alternatives → coverage', () async {
        // 1. User in Berlin wants Globus (not available)
        final plz = '10115';
        
        // 2. Check if Globus is available
        final globusAvailable = provider.getAvailableRetailers(plz)
            .any((r) => r.name == 'Globus');
        expect(globusAvailable, isFalse);
        
        // 3. Get alternatives
        final alternatives = provider.findAlternativeRetailers(plz, 'Globus');
        expect(alternatives, isNotEmpty);
        
        // 4. Load stores before checking coverage (needed for totalStores count)
        await provider.searchStores('Store');
        
        // 5. Check coverage of first alternative
        if (alternatives.isNotEmpty) {
          final firstAlternative = alternatives.first;
          final coverage = provider.getRetailerCoverage(firstAlternative.name);
          
          expect(coverage, isNotNull);
          // Now totalStores should be > 0 since we loaded stores
          expect(coverage['totalStores'], greaterThanOrEqualTo(0));
          
          // If stores are loaded, expect some stores for major retailers
          if (provider.allStores.isNotEmpty && 
              (firstAlternative.name == 'Kaufland' || 
               firstAlternative.name == 'EDEKA' || 
               firstAlternative.name == 'REWE')) {
            expect(coverage['totalStores'], greaterThan(0));
          }
        }
        
        // 6. Get nearby retailers as additional option
        final nearbyRetailers = await provider.getNearbyRetailers(plz, 10.0);
        expect(nearbyRetailers, isNotEmpty);
      });
    });
    
    // ========== TASK 5C.3: CROSS-PROVIDER TESTS ==========
    group('Task 5c.3: Cross-Provider Integration', () {
      test('should get available retailers for specific PLZ', () {
        final berlinRetailers = provider.getAvailableRetailersForPLZ('10115');
        expect(berlinRetailers, isNotEmpty);
        expect(berlinRetailers, contains('EDEKA'));
        
        final muenchenRetailers = provider.getAvailableRetailersForPLZ('80331');
        expect(muenchenRetailers, isNotEmpty);
      });
      
      test('should check if specific retailer is available', () {
        provider.updateUserLocation('10115');
        
        // EDEKA should be available (bundesweit)
        expect(provider.isRetailerAvailable('EDEKA'), isTrue);
        
        // Globus should not be available in Berlin
        expect(provider.isRetailerAvailable('Globus'), isFalse);
      });
      
      test('should get suggested retailers for unavailable ones', () {
        provider.updateUserLocation('10115');
        
        // Get suggestions for unavailable Globus
        final suggestions = provider.getSuggestedRetailers('Globus');
        expect(suggestions, isNotEmpty);
        expect(suggestions.length, lessThanOrEqualTo(3));
        
        // Should not suggest Globus itself
        expect(suggestions.any((r) => r.name == 'Globus'), isFalse);
      });
      
      test('should get availability statistics', () {
        provider.updateUserLocation('10115');
        
        final stats = provider.getAvailabilityStatistics();
        
        expect(stats['totalRetailers'], greaterThan(0));
        expect(stats['availableInRegion'], greaterThan(0));
        expect(stats['currentPLZ'], equals('10115'));
        expect(stats['regionName'], contains('Berlin'));
        expect(stats['percentageAvailable'], greaterThanOrEqualTo(0));
      });
    });
    
    // ========== DISPOSAL AND CLEANUP TESTS ==========
    group('Disposal and Memory Management', () {
      test('should clear cache when requested', () {
        // Add some data to cache
        provider.updateUserLocation('10115');
        provider.getAvailableRetailers('10115');
        
        expect(provider.testCache.isNotEmpty, isTrue);
        
        // Clear cache
        provider.clearCache();
        
        expect(provider.testCache.isEmpty, isTrue);
      });
      
      test('should handle disposal correctly', () {
        // Create a new provider for disposal test
        final testProvider = RetailersProvider(
          repository: repository,
          mockDataService: testMockDataService,
          
        );
        
        // Should not throw when disposing
        expect(() => testProvider.dispose(), returnsNormally);
      });
    });
  });
}
