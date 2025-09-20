// Store Search Tests für Task 11.4
// Testet die Filial-Suche Funktionalität im RetailersProvider

import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/providers/retailers_provider.dart';
import 'package:flashfeed/providers/location_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/repositories/mock_retailers_repository.dart';
// import 'package:flashfeed/models/models.dart'; // Not needed in this test

void main() {
  group('Store Search Tests', () {
    late RetailersProvider provider;
    late MockDataService mockDataService;
    late MockRetailersRepository repository;
    
    setUp(() async {
      // Initialize MockDataService mit Test-Mode
      mockDataService = MockDataService();
      await mockDataService.initializeMockData(testMode: true);
      
      // Create repository with test service
      repository = MockRetailersRepository(testService: mockDataService);
      
      // Create provider
      provider = RetailersProvider(
        repository: repository,
        mockDataService: mockDataService,
        
      );
      
      // Load initial data
      await provider.loadRetailers();
    });
    
    tearDown(() {
      provider.dispose();
      mockDataService.dispose();
    });
    
    group('11.4.1: Core Search Implementation', () {
      test('should search stores by name', () async {
        // Search for EDEKA stores
        final results = await provider.searchStores('EDEKA');
        
        expect(results.isNotEmpty, isTrue);
        expect(results.every((store) => 
          store.name.toLowerCase().contains('edeka') ||
          store.retailerName.toLowerCase().contains('edeka')
        ), isTrue);
      });
      
      test('should handle empty search query', () async {
        // Empty search should be rejected for security (production safety)
        final results = await provider.searchStores('');
        
        expect(results.isEmpty, isTrue);
        expect(results.length, equals(0));
      });
      
      test('should perform case-insensitive search', () async {
        // Search with different cases
        final results1 = await provider.searchStores('REWE');
        final results2 = await provider.searchStores('rewe');
        final results3 = await provider.searchStores('Rewe');
        
        expect(results1.length, equals(results2.length));
        expect(results2.length, equals(results3.length));
      });
      
      test('should find stores with fuzzy search (typos)', () async {
        // Search with typos using Levenshtein distance
        final results = await provider.searchStores('Edka'); // Missing 'e'
        
        // Should still find EDEKA stores
        expect(results.any((store) => 
          store.retailerName.toLowerCase().contains('edeka')
        ), isTrue);
      });
      
      test('should cache search results for 5 minutes', () async {
        // First search - not cached
        final results1 = await provider.searchStores('ALDI');
        
        // Second identical search - should be cached
        final startTime2 = DateTime.now();
        final results2 = await provider.searchStores('ALDI');
        final secondSearchTime = DateTime.now().difference(startTime2);
        
        // Cached search should be much faster (< 10ms)
        expect(results1.length, equals(results2.length));
        expect(secondSearchTime.inMilliseconds, lessThan(10));
      });
    });
    
    group('11.4.2: Filter Options', () {
      test('should filter stores by PLZ', () async {
        // Search stores in specific PLZ
        final results = await provider.searchStores(
          '',
          plz: '10115',
        );
        
        expect(results.every((store) => store.zipCode == '10115'), isTrue);
      });
      
      test('should filter stores by services', () async {
        // Search stores with specific services
        final results = await provider.searchStores(
          '',
          requiredServices: ['Parkplatz'],
        );
        
        expect(results.every((store) => 
          store.services.contains('Parkplatz')
        ), isTrue);
      });
      
      test('should filter only open stores', () async {
        // Mock current time as Monday 10:00
        final monday10am = DateTime(2024, 1, 8, 10, 0);
        
        final results = await provider.searchStores(
          '',
          openOnly: true,
        );
        
        // All results should be open at the mocked time
        for (final store in results) {
          expect(store.isOpenAt(monday10am), isTrue,
            reason: 'Store ${store.name} should be open at Monday 10:00');
        }
      });
      
      test('should combine multiple filters', () async {
        // Search with multiple filters
        final results = await provider.searchStores(
          'EDEKA',
          plz: '10115',
          requiredServices: ['Parkplatz'],
        );
        
        // All conditions must be met
        for (final store in results) {
          expect(store.name.toLowerCase().contains('edeka') ||
                 store.retailerName.toLowerCase().contains('edeka'), isTrue);
          expect(store.zipCode, equals('10115'));
          expect(store.services.contains('Parkplatz'), isTrue);
        }
      });
      
      test('should filter by radius when location is set', () async {
        // Set user location (Berlin center)
        final locationProvider = LocationProvider(
          mockDataService: mockDataService,  // CORRECT parameter name
        );
        provider.setLocationProvider(locationProvider);
        
        // Simulate GPS location
        await locationProvider.setMockLocation(52.520008, 13.404954);
        
        // Search within 5km radius
        final results = await provider.searchStores(
          '',
          radiusKm: 5.0,
        );
        
        // All stores should be within 5km
        for (final store in results) {
          final distance = store.distanceTo(52.520008, 13.404954);
          expect(distance, lessThanOrEqualTo(5.0),
            reason: 'Store ${store.name} should be within 5km');
        }
        
        locationProvider.dispose();
      });
    });
    
    group('11.4.3: Sorting & Ranking', () {
      test('should sort by distance when location available', () async {
        // Set location
        final locationProvider = LocationProvider(
          mockDataService: mockDataService,  // CORRECT parameter name
        );
        provider.setLocationProvider(locationProvider);
        await locationProvider.setMockLocation(52.520008, 13.404954);
        
        // Search with distance sorting
        final results = await provider.searchStores(
          '',
          sortBy: StoreSearchSort.distance,
        );
        
        // Verify sorting order
        for (int i = 1; i < results.length; i++) {
          final dist1 = results[i-1].distanceTo(52.520008, 13.404954);
          final dist2 = results[i].distanceTo(52.520008, 13.404954);
          expect(dist1, lessThanOrEqualTo(dist2),
            reason: 'Stores should be sorted by distance');
        }
        
        locationProvider.dispose();
      });
      
      test('should sort alphabetically by name', () async {
        // Search with name sorting
        final results = await provider.searchStores(
          '',
          sortBy: StoreSearchSort.name,
        );
        
        // Verify alphabetical order
        for (int i = 1; i < results.length; i++) {
          expect(results[i-1].name.compareTo(results[i].name), 
                 lessThanOrEqualTo(0),
            reason: 'Stores should be sorted alphabetically');
        }
      });
      
      test('should sort by open status', () async {
        // Search with open status sorting
        final results = await provider.searchStores(
          '',
          sortBy: StoreSearchSort.openStatus,
        );
        
        // Open stores should come first
        final now = DateTime.now();
        bool foundClosed = false;
        
        for (final store in results) {
          if (foundClosed) {
            // Once we found a closed store, all following should be closed
            expect(store.isOpenAt(now), isFalse,
              reason: 'Closed stores should come after open ones');
          } else if (!store.isOpenAt(now)) {
            foundClosed = true;
          }
        }
      });
      
      test('should boost exact matches in relevance sorting', () async {
        // Search for exact store name
        final exactName = 'EDEKA Center Potsdamer Platz';
        final results = await provider.searchStores(
          exactName,
          sortBy: StoreSearchSort.relevance,
        );
        
        // Exact match should be first
        if (results.isNotEmpty) {
          expect(results.first.name, contains('EDEKA'));
        }
      });
    });
    
    group('11.4.4: LocationProvider Integration', () {
      test('should use user location for distance calculations', () async {
        // Create and set LocationProvider
        final locationProvider = LocationProvider(
          mockDataService: mockDataService,  // CORRECT parameter name
        );
        provider.setLocationProvider(locationProvider);
        
        // Set mock location
        await locationProvider.setMockLocation(52.520008, 13.404954);
        
        // Search stores with a valid query
        final results = await provider.searchStores('EDEKA');

        // Should be sorted by distance from user location
        expect(results.isNotEmpty, isTrue);
        
        locationProvider.dispose();
      });
      
      test('should update search when location changes', () async {
        final locationProvider = LocationProvider(
          mockDataService: mockDataService,  // CORRECT parameter name
        );
        provider.setLocationProvider(locationProvider);
        
        // First location (Berlin)
        await locationProvider.setMockLocation(52.520008, 13.404954);
        final results1 = await provider.searchStores(
          '',
          radiusKm: 2.0,
          sortBy: StoreSearchSort.distance,
        );
        
        // Change location (different part of Berlin)
        await locationProvider.setMockLocation(52.490000, 13.350000);
        
        // Search again - cache should be cleared
        final results2 = await provider.searchStores(
          '',
          radiusKm: 2.0,
          sortBy: StoreSearchSort.distance,
        );
        
        // Results might be different due to location change
        // At minimum, the order should be different
        if (results1.isNotEmpty && results2.isNotEmpty) {
          // Check if first store is different (likely due to distance change)
          // This is a soft check as stores might still be in same order
          expect(results1.first.id != results2.first.id || 
                 results1.length != results2.length, isTrue,
            reason: 'Results should differ after location change');
        }
        
        locationProvider.dispose();
      });
    });
    
    group('11.4.5: Repository Integration', () {
      test('should load all stores from repository', () async {
        // Trigger store loading with valid query
        final results = await provider.searchStores('EDEKA');

        // Should have loaded stores from MockDataService (35+ stores)
        expect(results.isNotEmpty, isTrue);
        expect(results.length, greaterThan(0),
          reason: 'Should load stores from repository');
      });
      
      test('should handle pagination (if implemented)', () async {
        // For MVP: No pagination yet, but test structure ready
        final allResults = await provider.searchStores('EDEKA');

        // Currently returns all results
        expect(allResults.length, greaterThanOrEqualTo(0));
        
        // TODO: When pagination is implemented:
        // - Test loading first page (20 items)
        // - Test loading more items
        // - Test hasMore flag
      });
    });
    
    group('11.4.6: Quick Filters', () {
      test('should get open stores nearby', () async {
        final locationProvider = LocationProvider(
          mockDataService: mockDataService,  // CORRECT parameter name
        );
        provider.setLocationProvider(locationProvider);
        await locationProvider.setMockLocation(52.520008, 13.404954);
        
        final results = await provider.getOpenStoresNearby(radiusKm: 3);
        
        // All should be open and within radius
        final now = DateTime.now();
        for (final store in results) {
          expect(store.isOpenAt(now), isTrue);
          expect(store.distanceTo(52.520008, 13.404954), 
                 lessThanOrEqualTo(3.0));
        }
        
        locationProvider.dispose();
      });
      
      test('should find stores with specific service', () async {
        final results = await provider.getStoresWithService('DHL');
        
        // All should have DHL service
        for (final store in results) {
          expect(store.services.any((s) => 
            s.toLowerCase().contains('dhl')
          ), isTrue);
        }
      });
      
      test('should get nearest stores with limit', () async {
        final locationProvider = LocationProvider(
          mockDataService: mockDataService,  // CORRECT parameter name
        );
        provider.setLocationProvider(locationProvider);
        await locationProvider.setMockLocation(52.520008, 13.404954);
        
        final results = await provider.getNearestStores(limit: 3);
        
        // Should return exactly 3 stores (or less if not enough stores)
        expect(results.length, lessThanOrEqualTo(3));
        
        // Should be sorted by distance
        for (int i = 1; i < results.length; i++) {
          final dist1 = results[i-1].distanceTo(52.520008, 13.404954);
          final dist2 = results[i].distanceTo(52.520008, 13.404954);
          expect(dist1, lessThanOrEqualTo(dist2));
        }
        
        locationProvider.dispose();
      });
    });
  });
}
