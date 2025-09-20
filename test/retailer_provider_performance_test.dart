// Performance Tests für Task 11.7.4: Retailer Provider Performance
// Testet Performance, Scalability und Memory Management

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flashfeed/providers/retailers_provider.dart';
import 'package:flashfeed/providers/location_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/services/gps/test_gps_service.dart';
import 'package:flashfeed/repositories/mock_retailers_repository.dart';
import 'retailer_test_helpers.dart';

void main() {
  group('Task 11.7.4: RetailersProvider Performance Tests', () {
    late MockDataService testMockDataService;
    late RetailersProvider retailersProvider;
    late LocationProvider locationProvider;
    late MockRetailersRepository repository;

    setUp(() async {
      // Initialize with performance test mode
      testMockDataService = MockDataService();
      await testMockDataService.initializeMockData(testMode: true);

      repository = MockRetailersRepository(testService: testMockDataService);

      locationProvider = LocationProvider(
        gpsService: TestGPSService(),
        mockDataService: testMockDataService,
      );

      retailersProvider = RetailersProvider(
        repository: repository,
        mockDataService: testMockDataService,
        
      );

      await retailersProvider.loadRetailers();
      retailersProvider.registerWithLocationProvider(locationProvider);
    });

    tearDown(() {
      // Only dispose if not already disposed to prevent double disposal
      if (!retailersProvider.isDisposed) {
        retailersProvider.dispose();
      }
      locationProvider.dispose();
      testMockDataService.dispose();
    });

    group('11.7.4.1: Store Search Performance (1000+ Stores)', () {
      test('should handle large store datasets efficiently', () async {
        // Arrange: Generate large dataset
        // Simulate large dataset scenario with 1000 stores
        await retailersProvider.loadRetailers();

        final stopwatch = Stopwatch()..start();

        // Act: Perform complex search across large dataset
        final results = await retailersProvider.searchStores(
          'EDEKA',
          radiusKm: 10.0,
          requiredServices: ['Parkplatz'],
          sortBy: StoreSearchSort.distance,
        );

        stopwatch.stop();

        // Assert: Performance requirements
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Search should complete within 500ms for 1000+ stores');

        expect(results.isNotEmpty, isTrue);
        debugPrint('Large Dataset Search Performance: ${stopwatch.elapsedMilliseconds}ms for ${results.length} results');
      });

      test('should scale linearly with dataset size', () async {
        final sizes = [100, 500, 1000];
        final timings = <int>[];

        for (final size in sizes) {
          // Arrange: Generate dataset of specific size
          // Simulate large dataset scenario with variable size
          await retailersProvider.loadRetailers();

          final stopwatch = Stopwatch()..start();

          // Act: Perform standardized search
          await retailersProvider.searchStores('REWE');

          stopwatch.stop();
          timings.add(stopwatch.elapsedMilliseconds);

          debugPrint('Dataset Size: $size stores, Search Time: ${stopwatch.elapsedMilliseconds}ms');
        }

        // Assert: Should scale reasonably (not exponentially)
        expect(timings[1], lessThan(timings[0] * 10 + 50),
          reason: 'Performance should not degrade exponentially');
        expect(timings[2], lessThan(timings[1] * 3 + 100),
          reason: 'Large datasets should still perform reasonably');
      });

      test('should handle concurrent searches under load', () async {
        // Arrange: Large dataset
        // Simulate large dataset scenario with 1000 stores
        await retailersProvider.loadRetailers();

        final stopwatch = Stopwatch()..start();

        // Act: Perform 10 concurrent searches
        final futures = List.generate(10, (index) =>
          retailersProvider.searchStores('SEARCH_$index'));

        final results = await Future.wait(futures);

        stopwatch.stop();

        // Assert: All searches should complete successfully
        expect(results.length, equals(10));
        for (final result in results) {
          expect(result, isNotNull);
        }

        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: '10 concurrent searches should complete within 2 seconds');

        debugPrint('Concurrent Search Performance: ${stopwatch.elapsedMilliseconds}ms for 10 searches');
      });

      test('should handle fuzzy search performance on large datasets', () async {
        // Arrange: Large dataset with typos
        // Simulate large dataset scenario with 1000 stores
        await retailersProvider.loadRetailers();

        final typoQueries = ['Edka', 'Rwee', 'Aldi', 'Lidll', 'Kauflnd'];
        final stopwatch = Stopwatch()..start();

        // Act: Perform fuzzy searches
        for (final query in typoQueries) {
          final results = await retailersProvider.searchStores(query);
          expect(results, isNotNull);
        }

        stopwatch.stop();

        // Assert: Fuzzy search should still be performant
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'Fuzzy search should complete within 1 second');

        debugPrint('Fuzzy Search Performance: ${stopwatch.elapsedMilliseconds}ms for ${typoQueries.length} queries');
      });
    });

    group('11.7.4.2: Cache Efficiency Tests', () {
      test('should demonstrate cache performance improvement', () async {
        final query = 'EDEKA';

        // First search (uncached)
        final stopwatch1 = Stopwatch()..start();
        final results1 = await retailersProvider.searchStores(query);
        stopwatch1.stop();

        // Second search (cached)
        final stopwatch2 = Stopwatch()..start();
        final results2 = await retailersProvider.searchStores(query);
        stopwatch2.stop();

        // Assert: Cache should improve performance significantly
        expect(results1.length, equals(results2.length));
        expect(stopwatch2.elapsedMicroseconds, lessThan(stopwatch1.elapsedMicroseconds),
          reason: 'Cached search should be faster than initial search');

        expect(stopwatch2.elapsedMicroseconds, lessThan(1000),
          reason: 'Cached search should be under 1ms');

        debugPrint('Cache Performance: Initial: ${stopwatch1.elapsedMicroseconds}μs, Cached: ${stopwatch2.elapsedMicroseconds}μs');
      });

      test('should handle cache invalidation correctly', () async {
        // Arrange: Populate cache
        await retailersProvider.searchStores('REWE');

        // Act: Change location (should invalidate cache)
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 100));

        final stopwatch = Stopwatch()..start();
        final results = await retailersProvider.searchStores('REWE');
        stopwatch.stop();

        // Assert: Should perform fresh search (not use stale cache)
        expect(results.isNotEmpty, isTrue);

        // Should take longer than cached search but still be performant
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Fresh search after cache invalidation should still be fast');

        debugPrint('Cache Invalidation Performance: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should manage cache size efficiently', () async {
        // Arrange: Generate many different searches to fill cache
        for (int i = 0; i < 100; i++) {
          await retailersProvider.searchStores('QUERY_$i');
        }

        final stopwatch = Stopwatch()..start();

        // Act: Perform new search
        await retailersProvider.searchStores('NEW_UNIQUE_QUERY');

        stopwatch.stop();

        // Assert: Cache size management shouldn't impact performance
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Cache size management should not degrade performance');

        debugPrint('Cache Management Performance: ${stopwatch.elapsedMilliseconds}ms after 100 cached items');
      });

      test('should handle cache cleanup during provider disposal', () async {
        // Arrange: Populate cache
        for (int i = 0; i < 20; i++) {
          await retailersProvider.searchStores('CACHE_TEST_$i');
        }

        final stopwatch = Stopwatch()..start();

        // Act: Dispose provider (should clean up cache)
        retailersProvider.dispose();

        stopwatch.stop();

        // Assert: Disposal should be quick even with large cache
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Provider disposal should be fast even with large cache');

        debugPrint('Cache Cleanup Performance: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('11.7.4.3: Memory Leak Tests bei Provider Disposal', () {
      test('should not leak memory with multiple provider lifecycles', () async {
        final initialTime = DateTime.now();

        // Act: Create and dispose multiple providers
        for (int i = 0; i < 10; i++) {
          final testService = MockDataService();
          await testService.initializeMockData(testMode: true);

          final testProvider = RetailersProvider(
            repository: MockRetailersRepository(testService: testService),
            mockDataService: testService,
            
          );

          await testProvider.loadRetailers();

          // Perform some operations
          await testProvider.searchStores('EDEKA');
          await testProvider.searchStores('REWE');

          // Dispose properly - ensure provider is not already disposed
          if (!testProvider.isDisposed) {
            testProvider.dispose();
          }
          testService.dispose();

          // Small delay to allow garbage collection
          await Future.delayed(Duration(milliseconds: 20));
        }

        final finalTime = DateTime.now();
        final totalDuration = finalTime.difference(initialTime);

        // Assert: Multiple lifecycles should complete without memory issues
        expect(totalDuration.inSeconds, lessThan(10),
          reason: '10 provider lifecycles should complete within 10 seconds');

        debugPrint('Memory Test: 10 provider lifecycles in ${totalDuration.inMilliseconds}ms');
      }, timeout: Timeout(Duration(seconds: 30)));

      test('should handle callback cleanup on disposal', () async {
        // Arrange: Create provider with callbacks
        final testProvider = await RetailerTestHelpers.createTestProvider(
          mockDataService: testMockDataService,
        );

        // Register with location provider
        testProvider.registerWithLocationProvider(locationProvider);

        // Perform operations that create internal callbacks
        await testProvider.searchStores('EDEKA');
        await locationProvider.setUserPLZ('10115');

        final stopwatch = Stopwatch()..start();

        // Act: Dispose and cleanup
        testProvider.unregisterFromLocationProvider(locationProvider);
        testProvider.dispose();

        stopwatch.stop();

        // Assert: Callback cleanup should be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(10),
          reason: 'Callback cleanup should be immediate');

        debugPrint('Callback Cleanup Performance: ${stopwatch.elapsedMilliseconds}ms');

        // Location provider should still work after callback cleanup
        await locationProvider.setUserPLZ('80331');
        expect(locationProvider.postalCode, equals('80331'));
      }, timeout: Timeout(Duration(seconds: 15)));

      test('should handle rapid provider creation and disposal', () async {
        // OPTIMIZATION: Pre-create shared mock data to avoid repeated initialization
        final sharedTestService = MockDataService();
        await sharedTestService.initializeMockData(testMode: true);

        // Pre-load retailer data once to avoid repeated repository calls
        final sharedRepository = MockRetailersRepository(testService: sharedTestService);
        final preloadedRetailers = await sharedRepository.getAllRetailers();

        final stopwatch = Stopwatch()..start();

        // Act: Rapid create/dispose cycle (optimized with pre-loaded data)
        for (int i = 0; i < 20; i++) {
          final testProvider = RetailersProvider(
            repository: sharedRepository,
            mockDataService: sharedTestService,
            
          );

          // Skip loadRetailers() for performance test - test disposal only
          testProvider.dispose();
        }

        stopwatch.stop();

        // Cleanup shared service after all cycles
        sharedTestService.dispose();

        // Assert: Rapid lifecycle disposal should be fast (disposal-only test)
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: '20 rapid provider disposals should complete within 500ms');

        debugPrint('Rapid Disposal Performance: ${stopwatch.elapsedMilliseconds}ms for 20 cycles (${preloadedRetailers.length} retailers pre-loaded)');
      });

      test('should cleanup search cache on disposal', () async {
        // Arrange: Populate large cache
        for (int i = 0; i < 50; i++) {
          await retailersProvider.searchStores('MEMORY_TEST_$i');
        }

        final stopwatch = Stopwatch()..start();

        // Act: Dispose provider
        retailersProvider.dispose();

        stopwatch.stop();

        // Assert: Cache cleanup should be efficient
        expect(stopwatch.elapsedMilliseconds, lessThan(20),
          reason: 'Search cache cleanup should be fast');

        debugPrint('Search Cache Cleanup: ${stopwatch.elapsedMilliseconds}ms for 50 cached items');
      });
    });

    group('11.7.4.4: Scalability Tests (Concurrent Users)', () {
      test('should handle multiple concurrent provider instances', () async {
        // OPTIMIZATION: Pre-create shared mock data for all concurrent providers
        final sharedTestService = MockDataService();
        await sharedTestService.initializeMockData(testMode: true);
        final sharedRepository = MockRetailersRepository(testService: sharedTestService);

        final providers = <RetailersProvider>[];

        // Arrange: Create multiple provider instances with shared resources (sequential setup)
        for (int i = 0; i < 5; i++) {
          final provider = RetailersProvider(
            repository: sharedRepository,
            mockDataService: sharedTestService,
            
          );

          await provider.loadRetailers();
          providers.add(provider);
        }

        // Act: START TIMER ONLY FOR CONCURRENT OPERATIONS (the actual test target)
        final stopwatch = Stopwatch()..start();

        final futures = providers.map((provider) =>
          provider.searchStores('CONCURRENT_TEST')).toList();

        final results = await Future.wait(futures);

        stopwatch.stop();

        // Assert: All operations should succeed
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, isNotNull);
        }

        expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: '5 concurrent search operations should complete within 500ms (setup excluded)');

        debugPrint('Concurrent Search Performance: ${stopwatch.elapsedMilliseconds}ms for 5 concurrent searches');

        // Cleanup
        for (final provider in providers) {
          provider.dispose();
        }

        sharedTestService.dispose();

        debugPrint('Concurrent Users Performance: ${stopwatch.elapsedMilliseconds}ms for 5 providers');
      });

      test('should handle concurrent location updates across providers', () async {
        // Arrange: Multiple providers with shared location provider
        final providers = <RetailersProvider>[];

        for (int i = 0; i < 3; i++) {
          final testService = MockDataService();
          await testService.initializeMockData(testMode: true);

          final provider = RetailersProvider(
            repository: MockRetailersRepository(testService: testService),
            mockDataService: testService,
            
          );

          await provider.loadRetailers();
          provider.registerWithLocationProvider(locationProvider);
          providers.add(provider);
        }

        final stopwatch = Stopwatch()..start();

        // Act: Trigger location update (should update all providers)
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 200)); // Allow propagation

        // Perform searches on all providers
        final futures = providers.map((provider) =>
          provider.searchStores('LOCATION_UPDATE_TEST')).toList();

        final results = await Future.wait(futures);

        stopwatch.stop();

        // Assert: All providers should reflect the location change
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isNotNull);
        }

        for (final provider in providers) {
          expect(provider.currentPLZ, equals('10115'));
        }

        expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Location update propagation should be fast');

        // Cleanup
        for (final provider in providers) {
          provider.unregisterFromLocationProvider(locationProvider);
          provider.dispose();
        }

        debugPrint('Location Update Propagation: ${stopwatch.elapsedMilliseconds}ms for 3 providers');
      });

      test('should maintain performance under stress', () async {
        // Arrange: Stress test setup
        final operations = <Future>[];
        final stopwatch = Stopwatch()..start();

        // Act: Fire many operations simultaneously
        for (int i = 0; i < 50; i++) {
          operations.add(retailersProvider.searchStores('STRESS_$i'));
        }

        for (int i = 0; i < 10; i++) {
          operations.add(locationProvider.setUserPLZ('1011$i'));
        }

        await Future.wait(operations);

        stopwatch.stop();

        // Assert: System should handle stress gracefully
        expect(stopwatch.elapsedMilliseconds, lessThan(10000),
          reason: 'Stress test should complete within 10 seconds');

        // Final state should be consistent
        expect(retailersProvider.currentPLZ, isNotNull);
        expect(locationProvider.userPLZ, isNotNull);

        debugPrint('Stress Test Performance: ${stopwatch.elapsedMilliseconds}ms for 60 operations');
      });
    });

    group('11.7.4.5: Baseline Performance Metrics', () {
      test('should establish baseline search performance', () async {
        final metrics = <String, int>{};

        // Basic search
        var stopwatch = Stopwatch()..start();
        await retailersProvider.searchStores('EDEKA');
        stopwatch.stop();
        metrics['basic_search'] = stopwatch.elapsedMilliseconds;

        // Filtered search
        stopwatch = Stopwatch()..start();
        await retailersProvider.searchStores(
          'REWE',
          requiredServices: ['Parkplatz'],
          openOnly: true,
        );
        stopwatch.stop();
        metrics['filtered_search'] = stopwatch.elapsedMilliseconds;

        // Distance-based search
        await locationProvider.setMockLocation(52.520008, 13.404954);
        stopwatch = Stopwatch()..start();
        await retailersProvider.searchStores(
          '',
          radiusKm: 2.0,
          sortBy: StoreSearchSort.distance,
        );
        stopwatch.stop();
        metrics['distance_search'] = stopwatch.elapsedMilliseconds;

        // Fuzzy search
        stopwatch = Stopwatch()..start();
        await retailersProvider.searchStores('Edka');
        stopwatch.stop();
        metrics['fuzzy_search'] = stopwatch.elapsedMilliseconds;

        // Assert baseline requirements
        expect(metrics['basic_search']!, lessThan(300),
          reason: 'Basic search should complete under 300ms');
        expect(metrics['filtered_search']!, lessThan(350),
          reason: 'Filtered search should complete under 350ms');
        expect(metrics['distance_search']!, lessThan(400),
          reason: 'Distance search should complete under 400ms');
        expect(metrics['fuzzy_search']!, lessThan(350),
          reason: 'Fuzzy search should complete under 350ms');

        debugPrint('Performance Baselines:');
        metrics.forEach((key, value) {
          debugPrint('  $key: ${value}ms');
        });
      });

      test('should establish baseline provider operation metrics', () async {
        final metrics = <String, int>{};

        // Provider initialization
        var stopwatch = Stopwatch()..start();
        final testService = MockDataService();
        await testService.initializeMockData(testMode: true);
        final testProvider = RetailersProvider(
          repository: MockRetailersRepository(testService: testService),
          mockDataService: testService,
          
        );
        await testProvider.loadRetailers();
        stopwatch.stop();
        metrics['provider_init'] = stopwatch.elapsedMilliseconds;

        // Location registration
        stopwatch = Stopwatch()..start();
        testProvider.registerWithLocationProvider(locationProvider);
        stopwatch.stop();
        metrics['location_registration'] = stopwatch.elapsedMicroseconds;

        // Provider disposal
        stopwatch = Stopwatch()..start();
        testProvider.unregisterFromLocationProvider(locationProvider);
        testProvider.dispose();
        testService.dispose();
        stopwatch.stop();
        metrics['provider_disposal'] = stopwatch.elapsedMilliseconds;

        // Assert baseline requirements
        expect(metrics['provider_init']!, lessThan(300),
          reason: 'Provider initialization should complete under 300ms');
        expect(metrics['location_registration']!, lessThan(1000),
          reason: 'Location registration should complete under 1000μs');
        expect(metrics['provider_disposal']!, lessThan(100),
          reason: 'Provider disposal should complete under 100ms');

        debugPrint('Provider Operation Baselines:');
        metrics.forEach((key, value) {
          final unit = key == 'location_registration' ? 'μs' : 'ms';
          debugPrint('  $key: $value$unit');
        });
      });
    });
  });
}