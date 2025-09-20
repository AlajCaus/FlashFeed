import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/services/offline_service.dart';

void main() {
  group('OfflineService Tests', () {
    late OfflineService offlineService;

    setUp(() {
      // Get singleton instance and clear caches
      offlineService = OfflineService();
      offlineService.clearAllCaches();
    });

    tearDown(() {
      // Clean up after each test
      offlineService.clearAllCaches();
    });

    group('Basic Caching Operations', () {
      test('can cache and retrieve data', () async {
        const testKey = 'test_key';
        final testData = {'id': 1, 'name': 'Test Item'};

        // Cache data
        await offlineService.cacheData(testKey, testData);

        // Retrieve data
        final cachedData = await offlineService.getCachedData(testKey);

        expect(cachedData, isNotNull);
        expect(cachedData, equals(testData));
      });

      test('returns null for non-existent key', () async {
        final result = await offlineService.getCachedData('non_existent_key');
        expect(result, isNull);
      });

      test('can cache different types of data', () async {
        // Cache string
        await offlineService.cacheData('string_key', 'Test String');
        expect(await offlineService.getCachedData('string_key'), 'Test String');

        // Cache list
        final testList = [1, 2, 3, 4, 5];
        await offlineService.cacheData('list_key', testList);
        expect(await offlineService.getCachedData('list_key'), equals(testList));

        // Cache map
        final testMap = {'key': 'value', 'number': 42};
        await offlineService.cacheData('map_key', testMap);
        expect(await offlineService.getCachedData('map_key'), equals(testMap));
      });

      test('overwrites existing cache with same key', () async {
        const key = 'overwrite_test';
        const originalValue = 'original';
        const newValue = 'updated';

        await offlineService.cacheData(key, originalValue);
        expect(await offlineService.getCachedData(key), originalValue);

        await offlineService.cacheData(key, newValue);
        expect(await offlineService.getCachedData(key), newValue);
      });
    });

    group('Cache Expiration', () {
      test('cache expires after specified duration', () async {
        const key = 'expiring_cache';
        const data = 'test data';

        await offlineService.cacheData(key, data);

        // Cache should be valid immediately
        expect(
          offlineService.isCacheValid(key, maxAge: const Duration(seconds: 1)),
          isTrue,
        );

        // Simulate time passing (this is tricky in tests, so we use a very short duration)
        await Future.delayed(const Duration(milliseconds: 100));

        // Cache should be invalid with very short max age
        expect(
          offlineService.isCacheValid(key, maxAge: const Duration(milliseconds: 50)),
          isFalse,
        );
      });

      test('expired cache returns null', () async {
        const key = 'expired_cache';
        const data = 'test data';

        await offlineService.cacheData(key, data);

        // Wait a bit
        await Future.delayed(const Duration(milliseconds: 100));

        // Request with very short max age should return null
        final result = await offlineService.getCachedData(
          key,
          maxAge: const Duration(milliseconds: 50),
        );

        expect(result, isNull);
      });

      test('uses default cache duration when not specified', () async {
        const key = 'default_duration';
        const data = 'test data';

        await offlineService.cacheData(key, data);

        // Should use default duration (24 hours)
        final result = await offlineService.getCachedData(key);
        expect(result, equals(data));

        // Should still be valid
        expect(offlineService.isCacheValid(key), isTrue);
      });
    });

    group('Cache Management', () {
      test('can clear specific cache', () async {
        const key1 = 'cache1';
        const key2 = 'cache2';
        const data1 = 'data1';
        const data2 = 'data2';

        await offlineService.cacheData(key1, data1);
        await offlineService.cacheData(key2, data2);

        // Both should exist
        expect(await offlineService.getCachedData(key1), data1);
        expect(await offlineService.getCachedData(key2), data2);

        // Clear only cache1
        await offlineService.clearCache(key1);

        // cache1 should be gone, cache2 should remain
        expect(await offlineService.getCachedData(key1), isNull);
        expect(await offlineService.getCachedData(key2), data2);
      });

      test('can clear all caches', () async {
        await offlineService.cacheData('key1', 'data1');
        await offlineService.cacheData('key2', 'data2');
        await offlineService.cacheData('key3', 'data3');

        // All should exist
        expect(await offlineService.getCachedData('key1'), isNotNull);
        expect(await offlineService.getCachedData('key2'), isNotNull);
        expect(await offlineService.getCachedData('key3'), isNotNull);

        // Clear all
        await offlineService.clearAllCaches();

        // All should be gone
        expect(await offlineService.getCachedData('key1'), isNull);
        expect(await offlineService.getCachedData('key2'), isNull);
        expect(await offlineService.getCachedData('key3'), isNull);
      });

      test('isCacheValid returns false for non-existent cache', () {
        expect(offlineService.isCacheValid('non_existent'), isFalse);
      });
    });

    group('Cache Statistics', () {
      test('getCacheAgeMinutes returns correct age', () async {
        const key = 'age_test';
        await offlineService.cacheData(key, 'data');

        // Immediately after caching, age should be 0
        final age = offlineService.getCacheAgeMinutes(key);
        expect(age, isNotNull);
        expect(age, equals(0));
      });

      test('getCacheAgeMinutes returns null for non-existent cache', () {
        expect(offlineService.getCacheAgeMinutes('non_existent'), isNull);
      });

      test('getCacheStats returns correct statistics', () async {
        await offlineService.cacheData('key1', 'short data');
        await offlineService.cacheData('key2', {'complex': 'object', 'with': 'data'});
        await offlineService.cacheData('key3', List.generate(100, (i) => i));

        final stats = offlineService.getCacheStats();

        expect(stats, isNotNull);
        expect(stats.length, 3);

        // Check that each key has statistics
        expect(stats.containsKey('key1'), isTrue);
        expect(stats.containsKey('key2'), isTrue);
        expect(stats.containsKey('key3'), isTrue);

        // Check structure of statistics
        for (final entry in stats.entries) {
          final stat = entry.value as Map<String, dynamic>;
          expect(stat.containsKey('size'), isTrue);
          expect(stat.containsKey('ageMinutes'), isTrue);
          expect(stat.containsKey('timestamp'), isTrue);
        }
      });
    });

    group('Predefined Cache Keys', () {
      test('predefined cache keys are unique', () {
        final keys = [
          OfflineService.cachedOffers,
          OfflineService.cachedRetailers,
          OfflineService.cachedFlashDeals,
          OfflineService.cachedLocation,
        ];

        // Check all keys are unique
        expect(keys.toSet().length, keys.length);
      });

      test('can cache offers using predefined key', () async {
        final offers = [
          {'id': 1, 'name': 'Offer 1'},
          {'id': 2, 'name': 'Offer 2'},
        ];

        await offlineService.cacheData(OfflineService.cachedOffers, offers);

        final cached = await offlineService.getCachedData(OfflineService.cachedOffers);
        expect(cached, equals(offers));
      });
    });

    group('Offline Mode', () {
      test('isOfflineMode returns false when cache is empty', () {
        expect(offlineService.isOfflineMode(), isFalse);
      });

      test('isOfflineMode returns true when cache has data', () async {
        await offlineService.cacheData('any_key', 'any_data');
        expect(offlineService.isOfflineMode(), isTrue);
      });

      test('hasNetworkConnection always returns true for web', () async {
        // Note: This is a simplified implementation for web
        // In production, this would check actual network status
        expect(await offlineService.hasNetworkConnection(), isTrue);
      });
    });

    group('Fallback Data', () {
      test('createFallbackData returns valid structure', () {
        final fallback = offlineService.createFallbackData();

        expect(fallback, isNotNull);
        expect(fallback.containsKey('offers'), isTrue);
        expect(fallback.containsKey('retailers'), isTrue);
        expect(fallback.containsKey('flashDeals'), isTrue);
        expect(fallback.containsKey('message'), isTrue);

        // Check offers structure
        expect(fallback['offers'], isList);
        expect(fallback['offers'].length, greaterThan(0));

        final firstOffer = fallback['offers'][0];
        expect(firstOffer.containsKey('id'), isTrue);
        expect(firstOffer.containsKey('productName'), isTrue);
        expect(firstOffer.containsKey('price'), isTrue);

        // Check retailers structure
        expect(fallback['retailers'], isList);
        expect(fallback['retailers'].length, greaterThan(0));

        // Check message
        expect(fallback['message'], contains('offline'));
      });
    });

    group('Error Handling', () {
      test('handles caching errors gracefully', () async {
        // Try to cache null (should handle without throwing)
        await offlineService.cacheData('null_test', null);
        expect(await offlineService.getCachedData('null_test'), isNull);
      });

      test('handles invalid cache keys gracefully', () async {
        // Empty key
        await offlineService.cacheData('', 'data');
        expect(await offlineService.getCachedData(''), 'data');
      });
    });

    group('Singleton Pattern', () {
      test('always returns the same instance', () {
        final instance1 = OfflineService();
        final instance2 = OfflineService();

        expect(identical(instance1, instance2), isTrue);
      });

      test('maintains state across instances', () async {
        final instance1 = OfflineService();
        await instance1.cacheData('shared_key', 'shared_data');

        final instance2 = OfflineService();
        expect(await instance2.getCachedData('shared_key'), 'shared_data');
      });
    });

    group('Size Estimation', () {
      test('estimates size correctly for different data types', () async {
        // Small string
        await offlineService.cacheData('small', 'test');
        final stats1 = offlineService.getCacheStats();
        final size1 = stats1['small']['size'];
        expect(size1, contains('B'));

        // Large object
        final largeData = List.generate(1000, (i) => {'index': i, 'data': 'value$i'});
        await offlineService.cacheData('large', largeData);
        final stats2 = offlineService.getCacheStats();
        final size2 = stats2['large']['size'];
        expect(size2, contains('KB'));
      });
    });
  });
}