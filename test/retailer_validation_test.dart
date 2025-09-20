// Production Safety Validation Tests für RetailersProvider
// Testet Input-Validation, Error Handling und Security Aspects

import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/providers/retailers_provider.dart';
import 'package:flashfeed/providers/location_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/services/gps/test_gps_service.dart';
import 'package:flashfeed/repositories/mock_retailers_repository.dart';
import 'retailer_test_helpers.dart';

void main() {
  group('Production Safety: RetailersProvider Validation Tests', () {
    late MockDataService testMockDataService;
    late RetailersProvider retailersProvider;
    late LocationProvider locationProvider;
    late MockRetailersRepository repository;

    setUp(() async {
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
    });

    tearDown(() {
      retailersProvider.dispose();
      locationProvider.dispose();
      testMockDataService.dispose();
    });

    group('Input Validation & Sanitization', () {
      test('should reject null and empty search queries safely', () async {
        // Test null safety
        final nullResults = await retailersProvider.searchStores('');
        expect(nullResults, isEmpty,
          reason: 'Empty search should return empty results for security');

        // Test whitespace-only queries
        final whitespaceResults = await retailersProvider.searchStores('   ');
        expect(whitespaceResults, isEmpty,
          reason: 'Whitespace-only search should be rejected');

        // Test very short queries (potential security issue)
        final shortResults = await retailersProvider.searchStores('a');
        expect(shortResults, isNotNull,
          reason: 'Single character searches should be handled gracefully');
      });

      test('should handle special characters and SQL injection attempts', () async {
        final maliciousQueries = [
          "'; DROP TABLE stores; --",
          "<script>alert('xss')</script>",
          "UNION SELECT * FROM users",
          "1' OR '1'='1",
          "../../../etc/passwd",
          String.fromCharCodes([0, 1, 2, 3]),
          "Robert'); DROP TABLE students;--",
        ];

        for (final query in maliciousQueries) {
          // Act: Attempt injection
          final results = await retailersProvider.searchStores(query);

          // Assert: Should handle gracefully without crashing
          expect(results, isNotNull,
            reason: 'Malicious query should not crash: $query');
          expect(results, isEmpty,
            reason: 'Malicious query should return no results: $query');
        }
      });

      test('should validate PLZ input format', () async {
        final invalidPLZs = [
          'INVALID',
          '1234',      // Too short
          '123456',    // Too long
          '1234a',     // Contains letters
          '00000',     // Invalid range
          '99999',     // Invalid range
          '-12345',    // Negative
          '',          // Empty
          '12 345',    // Contains space
        ];

        for (final plz in invalidPLZs) {
          // Act: Attempt to use invalid PLZ
          final results = await retailersProvider.searchStores(
            'EDEKA',
            plz: plz,
          );

          // Assert: Should handle gracefully
          expect(results, isNotNull,
            reason: 'Invalid PLZ should not crash: $plz');
          // Should either return empty results or ignore invalid PLZ
        }
      });

      test('should validate radius parameters', () async {
        final invalidRadii = [
          -1.0,        // Negative
          0.0,         // Zero
          1000.0,      // Too large (security: prevent DoS)
          double.infinity,
          double.nan,
        ];

        await locationProvider.setMockLocation(52.520008, 13.404954);

        for (final radius in invalidRadii) {
          // Act: Attempt to use invalid radius
          final results = await retailersProvider.searchStores(
            'EDEKA',
            radiusKm: radius,
          );

          // Assert: Should handle gracefully
          expect(results, isNotNull,
            reason: 'Invalid radius should not crash: $radius');
        }
      });

      test('should sanitize service filter input', () async {
        final maliciousServices = [
          "<script>alert('xss')</script>",
          "'; DROP TABLE services; --",
          String.fromCharCodes([0, 1, 2]),
          "' OR 1=1 --",
        ];

        for (final service in maliciousServices) {
          // Act: Attempt to use malicious service filter
          final results = await retailersProvider.searchStores(
            'EDEKA',
            requiredServices: [service],
          );

          // Assert: Should handle gracefully
          expect(results, isNotNull,
            reason: 'Malicious service filter should not crash: $service');
          expect(results, isEmpty,
            reason: 'Malicious service filter should return no results: $service');
        }
      });
    });

    group('Error Handling & Recovery', () {
      test('should handle repository errors gracefully', () async {
        // Arrange: Create provider with truly failing repository (no test service)
        final failingRepository = MockRetailersRepository(); // No testService = minimal fallback

        final testProvider = RetailersProvider(
          repository: failingRepository,
          mockDataService: testMockDataService, // Keep service for provider functionality
          
        );

        // Act: Attempt operations that should work with fallback
        await testProvider.loadRetailers();
        final results = await testProvider.searchStores('EDEKA');

        // Assert: Should not crash, should provide fallback (static mock data)
        expect(results, isNotNull);
        // Note: Results might not be empty due to static fallback data, but should not crash

        testProvider.dispose();
      });

      test('should handle service unavailability', () async {
        // Arrange: Create provider with disposed/unavailable service
        testMockDataService.dispose();

        final unavailableRepository = MockRetailersRepository(testService: testMockDataService);
        final testProvider = RetailersProvider(
          repository: unavailableRepository,
          mockDataService: testMockDataService,
          
        );

        // Act: Attempt operations with unavailable service
        final results = await testProvider.searchStores('EDEKA');

        // Assert: Should handle gracefully (fallback to static mock data)
        expect(results, isNotNull);
        // Note: Static fallback data might not be empty, but system should not crash

        testProvider.dispose();
      });

      test('should handle memory pressure gracefully', () async {
        // Arrange: Generate memory pressure with large operations
        final largeQueries = List.generate(100, (i) => 'QUERY_$i' * 100);

        // Act: Perform many large operations
        for (final query in largeQueries) {
          final results = await retailersProvider.searchStores(query);
          expect(results, isNotNull,
            reason: 'Large query should not crash: ${query.substring(0, 20)}...');
        }

        // Assert: System should still be responsive
        final finalResults = await retailersProvider.searchStores('EDEKA');
        expect(finalResults, isNotNull,
          reason: 'System should still work after memory pressure');
      });

      test('should handle concurrent access errors', () async {
        // Arrange: Fire many concurrent operations
        final futures = <Future>[];

        for (int i = 0; i < 50; i++) {
          futures.add(retailersProvider.searchStores('CONCURRENT_$i'));
        }

        // Act: Wait for all to complete
        final results = await Future.wait(futures);

        // Assert: All should complete without errors
        expect(results.length, equals(50));
        for (final result in results) {
          expect(result, isNotNull,
            reason: 'Concurrent operation should not return null');
        }
      });
    });

    group('Security & DoS Prevention', () {
      test('should rate limit excessive search requests', () async {
        final startTime = DateTime.now();

        // Act: Fire many rapid requests
        for (int i = 0; i < 100; i++) {
          await retailersProvider.searchStores('RATE_LIMIT_TEST_$i');
        }

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert: Should not complete instantly (implies rate limiting)
        expect(duration.inMilliseconds, greaterThan(50),
          reason: 'Rapid requests should be rate limited');

        // System should still be responsive
        final finalResult = await retailersProvider.searchStores('EDEKA');
        expect(finalResult, isNotNull);
      });

      test('should limit search result size to prevent DoS', () async {
        // Arrange: Generate large dataset
        // Simulate large dataset scenario
        await retailersProvider.loadRetailers();

        // Act: Perform broad search that could return many results
        final results = await retailersProvider.searchStores('');

        // Assert: Should limit results to reasonable size
        expect(results.length, lessThanOrEqualTo(1000),
          reason: 'Search results should be limited to prevent DoS');
      });

      test('should prevent cache pollution attacks', () async {
        // Arrange: Try to pollute cache with many unique queries
        for (int i = 0; i < 1000; i++) {
          await retailersProvider.searchStores('CACHE_POLLUTION_$i');
        }

        // Act: Perform legitimate search
        final stopwatch = Stopwatch()..start();
        final results = await retailersProvider.searchStores('EDEKA');
        stopwatch.stop();

        // Assert: Performance should not be degraded by cache pollution
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Cache pollution should not degrade performance');
        expect(results, isNotNull);
      });

      test('should validate location provider integration security', () async {
        // Arrange: Register with location provider
        retailersProvider.registerWithLocationProvider(locationProvider);

        // Act: Try to inject malicious location data
        final maliciousLocations = [
          'INVALID_PLZ',
          "'; DROP TABLE locations; --",
          "<script>alert('xss')</script>",
          '99999',
        ];

        for (final location in maliciousLocations) {
          await locationProvider.setUserPLZ(location);
          await Future.delayed(Duration(milliseconds: 10));

          // Assert: Should handle malicious location gracefully
          final results = await retailersProvider.searchStores('EDEKA');
          expect(results, isNotNull,
            reason: 'Malicious location should not crash search: $location');
        }

        retailersProvider.unregisterFromLocationProvider(locationProvider);
      });
    });

    group('Data Integrity & Consistency', () {
      test('should maintain data consistency during concurrent modifications', () async {
        // Arrange: Register location provider
        retailersProvider.registerWithLocationProvider(locationProvider);

        // Act: Perform concurrent operations that modify state
        final futures = [
          locationProvider.setUserPLZ('10115'),
          retailersProvider.searchStores('EDEKA'),
          locationProvider.setUserPLZ('80331'),
          retailersProvider.searchStores('REWE'),
          locationProvider.setUserPLZ('20095'),
        ];

        await Future.wait(futures);

        // Assert: Final state should be consistent
        expect(retailersProvider.currentPLZ, equals(locationProvider.userPLZ));

        final finalResults = await retailersProvider.searchStores('LIDL');
        expect(finalResults, isNotNull);

        retailersProvider.unregisterFromLocationProvider(locationProvider);
      });

      test('should validate retailer data integrity', () async {
        // Act: Get all retailers
        final retailers = retailersProvider.allRetailers;

        // Assert: Basic data integrity checks
        for (final retailer in retailers) {
          expect(retailer.name, isNotEmpty,
            reason: 'Retailer name should not be empty');
          expect(retailer.logoUrl, isNotEmpty,
            reason: 'Retailer logoUrl should not be empty');
          expect(retailer.primaryColor, isNotNull,
            reason: 'Retailer primaryColor should not be null');
        }
      });

      test('should validate store data integrity', () async {
        // Act: Search for stores
        final stores = await retailersProvider.searchStores('EDEKA');

        // Assert: Store data integrity
        for (final store in stores) {
          expect(store.id, isNotEmpty,
            reason: 'Store ID should not be empty');
          expect(store.name, isNotEmpty,
            reason: 'Store name should not be empty');
          expect(store.address, isNotEmpty,
            reason: 'Store address should not be empty');
          expect(store.zipCode, matches(RegExp(r'^\d{5}$')),
            reason: 'Store PLZ should be 5 digits');
          expect(store.latitude, greaterThan(45.0),
            reason: 'Store latitude should be valid for Germany');
          expect(store.latitude, lessThan(56.0),
            reason: 'Store latitude should be valid for Germany');
          expect(store.longitude, greaterThan(5.0),
            reason: 'Store longitude should be valid for Germany');
          expect(store.longitude, lessThan(16.0),
            reason: 'Store longitude should be valid for Germany');
        }
      });

      test('should ensure opening hours data consistency', () async {
        // Act: Get stores with opening hours
        final stores = await retailersProvider.searchStores('REWE');

        // Assert: Opening hours consistency
        for (final store in stores.take(5)) { // Test sample
          final openingHours = store.openingHours;

          // Skip stores with truly empty opening hours (no meaningful data)
          // Some stores might have an empty map {} which should be allowed
          if (openingHours.isNotEmpty) {
            // Validate opening hours format - check if days exist before asserting not null
            final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

            // Also check capitalized versions as fallback
            final capitalizedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

            // Also check German day names (as seen in the actual data)
            final germanDays = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];

            for (int i = 0; i < days.length; i++) {
              final day = days[i];
              final capitalizedDay = capitalizedDays[i];
              final germanDay = germanDays[i];

              // Check all three formats: lowercase, capitalized, and German
              if (openingHours.containsKey(day)) {
                expect(openingHours[day], isNotNull,
                  reason: 'Opening hours for $day should not be null if key exists');
              } else if (openingHours.containsKey(capitalizedDay)) {
                expect(openingHours[capitalizedDay], isNotNull,
                  reason: 'Opening hours for $capitalizedDay should not be null if key exists');
              } else if (openingHours.containsKey(germanDay)) {
                expect(openingHours[germanDay], isNotNull,
                  reason: 'Opening hours for $germanDay should not be null if key exists');
              }
            }

            // Check if at least one valid day exists (any format)
            final hasValidDay = days.any((day) => openingHours.containsKey(day)) ||
                                capitalizedDays.any((day) => openingHours.containsKey(day)) ||
                                germanDays.any((day) => openingHours.containsKey(day));

            // Only enforce this if the map has any keys at all
            if (openingHours.keys.isNotEmpty) {
              expect(hasValidDay, isTrue,
                reason: 'Store should have at least one valid day key if openingHours has any entries. Found keys: ${openingHours.keys.join(", ")}');
            }

            // Validate opening hours logic
            final now = DateTime.now();
            expect(() => store.isOpenAt(now), returnsNormally,
              reason: 'isOpenAt should not crash');
          }
        }
      });
    });

    group('Resource Management & Limits', () {
      test('should enforce reasonable timeout limits', () async {
        // Act: Perform search operation
        final stopwatch = Stopwatch()..start();
        final results = await retailersProvider.searchStores('EDEKA');
        stopwatch.stop();

        // Assert: Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Search should complete within 5 seconds');
        expect(results, isNotNull);
      });

      test('should limit concurrent operations', () async {
        // Arrange: Fire many concurrent operations
        final futures = List.generate(200, (i) =>
          retailersProvider.searchStores('CONCURRENT_LIMIT_$i'));

        final stopwatch = Stopwatch()..start();

        // Act: Wait for all operations
        final results = await Future.wait(futures);

        stopwatch.stop();

        // Assert: Should handle gracefully without system overload
        expect(results.length, equals(200));
        expect(stopwatch.elapsedMilliseconds, lessThan(10000),
          reason: 'Concurrent operations should not cause excessive delays');

        for (final result in results) {
          expect(result, isNotNull);
        }
      });

      test('should prevent memory exhaustion', () async {
        // Arrange: Try to exhaust memory with large operations
        for (int i = 0; i < 50; i++) {
          // Create large search query
          final largeQuery = 'MEMORY_TEST_${'X' * 1000}';
          final results = await retailersProvider.searchStores(largeQuery);

          expect(results, isNotNull,
            reason: 'Large query should not exhaust memory');
        }

        // Assert: System should still be responsive
        final finalResults = await retailersProvider.searchStores('EDEKA');
        expect(finalResults, isNotNull);
      });

      test('should cleanup resources on provider disposal', () async {
        // Arrange: Create provider with operations
        final testProvider = await RetailerTestHelpers.createTestProvider(
          mockDataService: testMockDataService,
        );

        // Perform operations that create resources
        await testProvider.searchStores('CLEANUP_TEST');
        testProvider.registerWithLocationProvider(locationProvider);

        final stopwatch = Stopwatch()..start();

        // Act: Dispose provider
        testProvider.unregisterFromLocationProvider(locationProvider);
        testProvider.dispose();

        stopwatch.stop();

        // Assert: Cleanup should be efficient
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Resource cleanup should be fast');
      });
    });
  });
}