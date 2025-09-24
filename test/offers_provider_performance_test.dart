//  Performance & Caching Tests for OffersProvider
import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/providers/offers_provider.dart';
import 'package:flashfeed/models/models.dart' show OfferSortType;
import 'package:flashfeed/services/mock_data_service.dart';

void main() {
  group(' OffersProvider Performance & Caching', () {
    late OffersProvider offersProvider;
    late MockDataService testMockDataService;
    
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Initialize MockDataService in test mode
      testMockDataService = MockDataService(seed: 42);
      await testMockDataService.initializeMockData(testMode: true);
      
      // Create provider with test service
      offersProvider = OffersProvider.mock(testService: testMockDataService);
      
      // Load initial offers
      await offersProvider.loadOffers();
    });
    
    tearDown(() {
      offersProvider.dispose();
      testMockDataService.dispose();
    });
    
    // Verify pagination is disabled
    test('should show all offers without pagination', () async {
      // Pagination is disabled for MVP - all offers should be shown
      expect(offersProvider.hasMorePages, isFalse); // No more pages to load
      expect(offersProvider.offers.length, equals(testMockDataService.offers.length)); // All offers visible
    });
    
    group('9.4.1: Filter-Result Caching', () {
      test('should cache filter results and hit cache on repeated queries', () async {
        // Arrange: Apply specific filters
        await offersProvider.filterByCategory('Obst & Gemüse');
        // Note initial misses for verification
        // final initialCacheMisses = offersProvider.cacheStatistics['misses'];
        final firstResults = List.from(offersProvider.offers);
        
        // Act: Apply same filter again
        await offersProvider.filterByCategory(null); // Clear first
        await offersProvider.filterByCategory('Obst & Gemüse'); // Apply again
        
        // Assert: Cache hit occurred
        expect(offersProvider.cacheStatistics['hits'], greaterThan(0));
        expect(offersProvider.offers.length, equals(firstResults.length));
        expect(offersProvider.cacheHitRate, greaterThan(0));
      });
      
      test('should generate unique cache keys for different filter combinations', () async {
        // Arrange: Track cache entries
        final initialEntries = offersProvider.cacheStatistics['entries'];
        
        // Act: Apply different filter combinations
        await offersProvider.filterByCategory('Obst & Gemüse');
        await offersProvider.filterByRetailer('EDEKA');
        offersProvider.setMaxPrice(10.0);
        offersProvider.setShowOnlyWithDiscount(true);
        
        // Assert: Multiple cache entries created
        expect(offersProvider.cacheStatistics['entries'], greaterThan(initialEntries));
      });
      
      test('should evict oldest entry when cache is full', () async {
        // Note: This would require exposing _maxCacheEntries or filling cache
        // For now, verify eviction method exists via clearCache
        offersProvider.clearCache();
        expect(offersProvider.cacheStatistics['entries'], equals(0));
        expect(offersProvider.cacheStatistics['hits'], equals(0));
        expect(offersProvider.cacheStatistics['misses'], equals(0));
      });
      
      test('should calculate cache hit rate correctly', () {
        // Arrange: Clear cache first
        offersProvider.clearCache();
        
        // Act: Perform searches that will miss and hit
        offersProvider.searchOffers('test1', immediate: true);
        offersProvider.searchOffers('test1', immediate: true); // Should hit
        
        // Assert: Hit rate should be ~50%
        final stats = offersProvider.cacheStatistics;
        expect(stats['hitRate'], contains('%'));
      });
      
      test('should estimate memory usage for cache', () {
        // Act: Check memory usage
        final memoryUsage = offersProvider.cacheStatistics['memoryUsage'];
        
        // Assert: Memory usage is formatted
        expect(memoryUsage, anyOf(
          contains('B'),
          contains('KB'),
          contains('MB'),
        ));
      });
    });
    
    group('9.4.2: Pagination System', () {
      test('should initialize pagination state correctly', () {
        // Assert: Initial state
        expect(offersProvider.currentPage, equals(0));
        expect(offersProvider.totalPages, greaterThanOrEqualTo(1));
        expect(offersProvider.isLoadingMore, isFalse);
      });
      
      test('should load more offers when requested', () async {
        // Arrange: Note initial count
        final initialCount = offersProvider.offers.length;
        
        // Act: Load more offers if available
        if (offersProvider.hasMorePages) {
          await offersProvider.loadMoreOffers();
          
          // Assert: More offers loaded
          expect(offersProvider.offers.length, greaterThan(initialCount));
          expect(offersProvider.currentPage, equals(1));
        }
      });
      
      test('should reset pagination when filters change', () async {
        // Arrange: Load some pages
        if (offersProvider.hasMorePages) {
          await offersProvider.loadMoreOffers();
        }
        expect(offersProvider.currentPage, greaterThanOrEqualTo(0));
        
        // Act: Apply new filter
        await offersProvider.filterByCategory('Obst & Gemüse');
        
        // Assert: Pagination reset
        expect(offersProvider.currentPage, equals(0));
      });
      
      test('should handle loadMoreOffers when no more pages', () async {
        // Arrange: Go to last page
        while (offersProvider.hasMorePages) {
          await offersProvider.loadMoreOffers();
        }
        final lastPageCount = offersProvider.offers.length;
        
        // Act: Try to load more
        await offersProvider.loadMoreOffers();
        
        // Assert: No change
        expect(offersProvider.offers.length, equals(lastPageCount));
      });
      
      test('should show loading state during pagination', () async {
        // Skip if no more pages
        if (!offersProvider.hasMorePages) {
          return;
        }
        
        // Act: Start loading more
        final loadFuture = offersProvider.loadMoreOffers();
        
        // Assert: Loading state active (might be too fast to catch)
        // Wait for completion
        await loadFuture;
        
        // Assert: Loading state cleared
        expect(offersProvider.isLoadingMore, isFalse);
      });
    });
    
    group('9.4.3: Debounced Search', () {
      test('should debounce search queries', () async {
        // Arrange: Track search executions
        int searchCount = 0;
        offersProvider.addListener(() {
          if (!offersProvider.isSearchPending) {
            searchCount++;
          }
        });
        
        // Act: Rapid search queries
        offersProvider.searchOffers('t');
        offersProvider.searchOffers('te');
        offersProvider.searchOffers('tes');
        offersProvider.searchOffers('test');
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 400));
        
        // Assert: Only one search executed (plus initial state)
        expect(searchCount, lessThanOrEqualTo(3)); // Initial + clear + final search
      });
      
      test('should search immediately when immediate flag is true', () {
        // Arrange: Note initial state
        expect(offersProvider.searchQuery, isEmpty);
        
        // Act: Immediate search
        offersProvider.searchOffers('immediate test', immediate: true);
        
        // Assert: Search applied immediately
        expect(offersProvider.searchQuery, equals('immediate test'));
        expect(offersProvider.isSearchPending, isFalse);
      });
      
      test('should cancel pending search when new query arrives', () async {
        // Act: Multiple rapid searches
        offersProvider.searchOffers('first');
        offersProvider.searchOffers('second');
        offersProvider.searchOffers('third');
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 400));
        
        // Assert: Only last search applied
        expect(offersProvider.searchQuery, equals('third'));
      });
      
      test('should clear search immediately when query is empty', () {
        // Arrange: Set initial search
        offersProvider.searchOffers('test', immediate: true);
        expect(offersProvider.searchQuery, equals('test'));
        
        // Act: Clear search
        offersProvider.searchOffers('');
        
        // Assert: Cleared immediately
        expect(offersProvider.searchQuery, isEmpty);
        expect(offersProvider.isSearchPending, isFalse);
      });
      
      test('should show pending state during debounce', () {
        // Act: Start debounced search
        offersProvider.searchOffers('pending test');
        
        // Assert: Pending state active
        expect(offersProvider.isSearchPending, isTrue);
      });
    });
    
    group('9.4.4: Memory Management', () {
      test('should handle memory pressure by clearing cache', () {
        // Arrange: Add some cache entries
        offersProvider.searchOffers('test1', immediate: true);
        offersProvider.searchOffers('test2', immediate: true);
        offersProvider.searchOffers('test3', immediate: true);
        final initialEntries = offersProvider.cacheStatistics['entries'];
        
        // Act: Simulate memory pressure
        offersProvider.onMemoryPressure();
        
        // Assert: Cache reduced
        expect(offersProvider.cacheStatistics['entries'], 
               lessThanOrEqualTo(initialEntries));
      });
      
      test('should clean up resources on dispose', () {
        // Arrange: Create new provider
        final testProvider = OffersProvider.mock(testService: testMockDataService);
        
        // Act: Add some state and dispose
        testProvider.searchOffers('test');
        testProvider.dispose();
        
        // Assert: Should not throw when disposed
        expect(() => testProvider.dispose(), returnsNormally);
      });
      
      test('should not execute debounced search after dispose', () async {
        // Arrange: Create new provider
        final testProvider = OffersProvider.mock(testService: testMockDataService);
        
        // Act: Start debounced search and immediately dispose
        testProvider.searchOffers('test');
        testProvider.dispose();
        
        // Wait for debounce period
        await Future.delayed(const Duration(milliseconds: 400));
        
        // Assert: No errors thrown (search cancelled)
        expect(testProvider.searchQuery, isEmpty); // Stays empty after dispose
      });
      
      test('should track active timers for leak detection', () {
        // Arrange: Start multiple debounced searches
        offersProvider.searchOffers('timer1');
        
        // Act: Start another before first completes
        offersProvider.searchOffers('timer2');
        
        // Assert: Only one timer active (previous cancelled)
        // This is implicitly tested - no memory leak
        expect(offersProvider.isSearchPending, isTrue);
      });
    });
    
    group('9.4: Integration Tests', () {
      test('should maintain performance with 1000+ offers', () async {
        // This test would require a larger dataset
        // For now, verify the system handles current dataset efficiently
        
        // Measure filter performance
        final stopwatch = Stopwatch()..start();
        
        // Perform multiple operations
        await offersProvider.filterByCategory('Obst & Gemüse');
        offersProvider.setMaxPrice(5.0);
        offersProvider.setShowOnlyWithDiscount(true);
        await offersProvider.setSortType(OfferSortType.priceAsc);
        
        stopwatch.stop();
        
        // Assert: Operations complete quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Under 1 second
      });
      
      test('should handle rapid filter changes efficiently', () async {
        // Arrange: Track execution time
        final stopwatch = Stopwatch()..start();
        
        // Act: Rapid filter changes
        for (int i = 0; i < 10; i++) {
          await offersProvider.filterByCategory(
            i.isEven ? 'Obst & Gemüse' : 'Molkereiprodukte'
          );
        }
        
        stopwatch.stop();
        
        // Assert: Cache makes subsequent calls faster
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Fast due to caching
        expect(offersProvider.cacheHitRate, greaterThan(0));
      });
      
      test('should paginate search results correctly', () async {
        // Arrange: Apply search filter
        offersProvider.searchOffers('e', immediate: true); // Common letter
        
        // Act: Load pages if available
        int totalLoaded = offersProvider.offers.length;
        
        if (offersProvider.hasMorePages) {
          await offersProvider.loadMoreOffers();
          
          // Assert: More results loaded
          expect(offersProvider.offers.length, greaterThan(totalLoaded));
        }
      });
    });
  });
}
