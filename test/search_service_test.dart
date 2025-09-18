// Task 9.3: Advanced Search Features Test Suite
// Tests for multi-term search, fuzzy search, category-aware search,
// and enhanced search suggestions

import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/services/search_service.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/providers/offers_provider.dart';
import 'package:flashfeed/models/models.dart';
import 'package:flashfeed/data/product_category_mapping.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper function to count actual Bio-Obst offers
int _countActualBioObstOffers(OffersProvider provider) {
  return provider.offers
    .where((o) => 
      o.productName.toLowerCase().contains('bio') &&
      ProductCategoryMapping.mapToFlashFeedCategory(
        o.retailer, 
        o.originalCategory
      ) == 'Obst & Gemüse'
    ).length;
}

void main() {
  group('Task 9.3: Advanced Search Features', () {
    // Shared test setup
    group('with random data (original tests)', () {
      late SearchService searchService;
      late MockDataService mockDataService;
      late OffersProvider offersProvider;
      late List<Offer> testOffers;

      setUp(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});
        
        searchService = SearchService();
        mockDataService = MockDataService(); // Random data
        await mockDataService.initializeMockData(testMode: true);
        
        offersProvider = OffersProvider.mock(testService: mockDataService);
        await offersProvider.loadOffers(applyRegionalFilter: false);
      
      // Create test offers with specific products for search testing
      testOffers = [
        Offer(
          id: '1',
          retailer: 'EDEKA',
          productName: 'Bio Vollmilch 3.5%',
          originalCategory: 'Milchprodukte',
          price: 1.49,
          originalPrice: 1.49,
          validUntil: DateTime.now().add(Duration(days: 3)),

          storeAddress: 'Berlin Mitte',
        ),
        Offer(
          id: '2',
          retailer: 'REWE',
          productName: 'Joghurt Natur',
          originalCategory: 'Milchprodukte',
          price: 0.89,
          originalPrice: 0.89,
          validUntil: DateTime.now().add(Duration(days: 3)),
          storeAddress: 'Berlin Prenzlauer Berg',
        ),
        Offer(
          id: '3',
          retailer: 'ALDI SÜD',
          productName: 'Banane Bio',
          originalCategory: 'Obst',
          price: 1.99,
          originalPrice: 1.99,
          validUntil: DateTime.now().add(Duration(days: 3)),
          storeAddress: 'Berlin Charlottenburg',
        ),
        Offer(
          id: '4',
          retailer: 'LIDL',
          productName: 'Milchbrötchen',
          originalCategory: 'Backwaren',
          price: 0.79,
          originalPrice: 0.79,
          validUntil: DateTime.now().add(Duration(days: 3)),
          storeAddress: 'Berlin Kreuzberg',
        ),
        Offer(
          id: '5',
          retailer: 'NETTO',
          productName: 'Apfel Braeburn',
          originalCategory: 'Obst',
          price: 2.49,
          originalPrice: 2.49,
          validUntil: DateTime.now().add(Duration(days: 3)),
          storeAddress: 'Berlin Neukölln',
        ),
      ];
    });
    
    tearDown(() {
      mockDataService.dispose();
      offersProvider.dispose();
    });
    
    group('Task 9.3.1: Multi-Term Search', () {
      test('should find products containing ALL search terms', () {
        // Search for "Bio Milch"
        final results = searchService.multiTermSearch(testOffers, 'Bio Milch');
        
        expect(results.length, equals(1));
        expect(results.first.productName, equals('Bio Vollmilch 3.5%'));
      });
      
      test('should find products with terms in any order', () {
        // Search for "Milch Bio" (reversed order)
        final results = searchService.multiTermSearch(testOffers, 'Milch Bio');
        
        expect(results.length, equals(1));
        expect(results.first.productName, equals('Bio Vollmilch 3.5%'));
      });
      
      test('should return empty when not all terms match', () {
        // Search for "Bio Joghurt" - no product has both
        final results = searchService.multiTermSearch(testOffers, 'Bio Joghurt');
        
        expect(results.isEmpty, isTrue);
      });
      
      test('should handle single term searches', () {
        // Search for just "Milch" - should find products from MockDataService
        // Using the actual offers from MockDataService, not testOffers
        final actualOffers = offersProvider.offers;
        final results = searchService.multiTermSearch(actualOffers, 'Milch');
        
        // MockDataService has: Vollmilch, Bio-Vollmilch, Joghurt (via category), Milchbrötchen
        expect(results.length, greaterThanOrEqualTo(4)); // At least 4 matches
        expect(results.any((o) => o.productName.contains('Milch')), isTrue);
        expect(results.any((o) => o.productName.contains('Vollmilch')), isTrue);
        expect(results.any((o) => o.productName.contains('Bio-Vollmilch')), isTrue);
      });
      
      test('should work with OffersProvider integration', () {
        offersProvider.searchWithMultipleTerms('Bio Milch');
        
        // The filtered results should only contain products with both terms
        final filtered = offersProvider.offers;
        expect(filtered.any((o) => 
          o.productName.toLowerCase().contains('bio') && 
          o.productName.toLowerCase().contains('milch')
        ), isTrue);
      });
    });
    
    group('Task 9.3.2: Fuzzy Search', () {
      test('should find "Joghurt" when searching for "Joghrt" (typo)', () {
        final results = searchService.fuzzySearch(testOffers, 'Joghrt', maxDistance: 2);
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.productName, equals('Joghurt Natur'));
      });
      
      test('should find "Milch" when searching for "Mlch" (missing letter)', () {
        final results = searchService.fuzzySearch(testOffers, 'Mlch', maxDistance: 2);
        
        expect(results.isNotEmpty, isTrue);
        expect(results.any((o) => o.productName.contains('Milch')), isTrue);
      });
      
      test('should find "Banane" when searching for "Banana" (different spelling)', () {
        final results = searchService.fuzzySearch(testOffers, 'Banana', maxDistance: 2);
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.productName, equals('Banane Bio'));
      });
      
      test('should respect maxDistance threshold', () {
        // Search with very different term and strict distance
        final results = searchService.fuzzySearch(testOffers, 'xyz', maxDistance: 1);
        
        expect(results.isEmpty, isTrue);
      });
      
      test('should sort results by relevance (lower distance first)', () {
        // Create offers with varying similarities to search term
        final specialOffers = [
          Offer(
            id: 'a',
            retailer: 'TEST',
            productName: 'Apfel', // Exact match
            originalCategory: 'Test',
            price: 1.0,
            originalPrice: 1.0,
            validUntil: DateTime.now().add(Duration(days: 1)),
            storeAddress: 'Test',
          ),
          Offer(
            id: 'b',
            retailer: 'TEST',
            productName: 'Apfle', // 1 typo
            originalCategory: 'Test',
            price: 1.0,
            originalPrice: 1.0,
            validUntil: DateTime.now().add(Duration(days: 1)),
            storeAddress: 'Test',
          ),
        ];
        
        final results = searchService.fuzzySearch(specialOffers, 'Apfel', maxDistance: 2);
        
        expect(results.length, equals(2));
        expect(results.first.productName, equals('Apfel')); // Exact match first
      });
      
      test('should work with OffersProvider fuzzy search', () {
        offersProvider.searchWithFuzzyMatching('Joghrt', tolerance: 2);
        
        // Should find Joghurt despite typo
        final filtered = offersProvider.offers;
        expect(filtered.any((o) => o.productName.contains('Joghurt')), isTrue);
      });
    });
    
    group('Task 9.3.3: Category-Aware Search', () {
      test('should filter by category when category is in search query', () {
        final results = searchService.categoryAwareSearch(testOffers, 'Obst Banane');
        
        expect(results.length, equals(1));
        expect(results.first.productName, equals('Banane Bio'));
        expect(results.first.originalCategory, equals('Obst'));
      });
      
      test('should detect category even with partial match', () {
        // "Milch" should match "Milchprodukte" category
        final results = searchService.categoryAwareSearch(testOffers, 'Milch Natur');
        
        expect(results.length, equals(1));
        expect(results.first.productName, equals('Joghurt Natur'));
      });
      
      test('should return all products in category if no other terms', () {
        final results = searchService.categoryAwareSearch(testOffers, 'Obst');
        
        expect(results.length, equals(2)); // Banane and Apfel
        expect(results.every((o) => o.originalCategory == 'Obst'), isTrue);
      });
      
      test('should handle non-category searches normally', () {
        final results = searchService.categoryAwareSearch(testOffers, 'EDEKA');
        
        expect(results.length, equals(1));
        expect(results.first.retailer, equals('EDEKA'));
      });
      
      test('should work with OffersProvider category-aware search', () {
        // Search for products in "Obst" category containing "Bio"
        offersProvider.searchWithCategoryAwareness('Obst Bio');
        
        final filtered = offersProvider.offers;
        
        // Should find products where:
        // 1. The mapped FlashFeed category is "Obst & Gemüse" AND
        // 2. The product name contains "Bio"
        expect(filtered.any((o) {
          final mappedCategory = ProductCategoryMapping.mapToFlashFeedCategory(
            o.retailer,
            o.originalCategory
          );
          return o.productName.toLowerCase().contains('bio') && 
                 mappedCategory == 'Obst & Gemüse';
        }), isTrue);
      });
    });
    
    group('Task 9.3.4: Enhanced Search Suggestions', () {
      test('should provide category suggestions', () {
        final suggestions = searchService.getEnhancedSuggestions(
          testOffers, 
          'Obst',
          maxSuggestions: 5,
        );
        
        expect(suggestions.any((s) => 
          s.type == SuggestionType.category && 
          s.text == 'Obst & Gemüse'
        ), isTrue);
      });
      
      test('should provide product suggestions', () {
        final suggestions = searchService.getEnhancedSuggestions(
          testOffers,
          'Milch',
          maxSuggestions: 5,
        );
        
        expect(suggestions.any((s) => 
          s.type == SuggestionType.product &&
          s.text.contains('Milch')
        ), isTrue);
      });
      
      test('should provide retailer suggestions', () {
        final suggestions = searchService.getEnhancedSuggestions(
          testOffers,
          'EDEK',
          maxSuggestions: 5,
        );
        
        expect(suggestions.any((s) => 
          s.type == SuggestionType.retailer &&
          s.text == 'EDEKA'
        ), isTrue);
      });
      
      test('should provide popular search combinations for "bio"', () {
        final suggestions = searchService.getEnhancedSuggestions(
          testOffers,
          'bio',
          maxSuggestions: 8,
        );
        
        expect(suggestions.any((s) => 
          s.type == SuggestionType.popular &&
          s.text == 'Bio Milch'
        ), isTrue);
      });
      
      test('should prioritize categories over products in suggestions', () {
        final suggestions = searchService.getEnhancedSuggestions(
          testOffers,
          'Milch',
          maxSuggestions: 10,
        );
        
        // Find indices of category and product suggestions
        final categoryIndex = suggestions.indexWhere((s) => 
          s.type == SuggestionType.category
        );
        final productIndex = suggestions.indexWhere((s) => 
          s.type == SuggestionType.product
        );
        
        if (categoryIndex != -1 && productIndex != -1) {
          expect(categoryIndex, lessThan(productIndex));
        }
      });
      
      test('should include appropriate icons for suggestions', () {
        final suggestions = searchService.getEnhancedSuggestions(
          testOffers,
          'Obst',
          maxSuggestions: 5,
        );
        
        final categorySuggestion = suggestions.firstWhere(
          (s) => s.type == SuggestionType.category && s.text.contains('Obst'),
          orElse: () => SearchSuggestion(
            text: '', 
            type: SuggestionType.category, 
            icon: '',
          ),
        );
        
        if (categorySuggestion.text.isNotEmpty) {
          expect(categorySuggestion.icon, equals('apple'));
        }
      });
      
      test('should work with OffersProvider enhanced suggestions', () {
        final suggestions = offersProvider.getEnhancedSearchSuggestions('Milch');
        
        expect(suggestions.isNotEmpty, isTrue);
        expect(suggestions.any((s) => s.text.contains('Milch')), isTrue);
      });
    });
    
    group('Advanced Search Integration', () {
      test('should fallback to fuzzy search when category search has no results', () {
        final results = searchService.advancedSearch(testOffers, 'Joghrt'); // Typo
        
        // Should find Joghurt through fuzzy search fallback
        expect(results.isNotEmpty, isTrue);
        expect(results.first.productName, equals('Joghurt Natur'));
      });
      
      test('should handle complex multi-feature searches with dynamic validation', () {
        // Count actual Bio-Obst offers in the random data
        final actualBioObstCount = _countActualBioObstOffers(offersProvider);
        
        // Category-aware search should find all Bio products in Obst category
        var results = offersProvider.performAdvancedSearch('Obst Bio');
        expect(results.length, equals(actualBioObstCount));
        
        // Validate all results are correct
        for (final result in results) {
          expect(result.productName.toLowerCase(), contains('bio'));
          final category = ProductCategoryMapping.mapToFlashFeedCategory(
            result.retailer, 
            result.originalCategory
          );
          expect(category, equals('Obst & Gemüse'));
        }
        
        // Multi-term search for Bio Milch products
        results = offersProvider.performAdvancedSearch('Bio Milch');
        // At least one result expected (Bio-Vollmilch exists)
        expect(results.isNotEmpty, isTrue);
        for (final result in results) {
          expect(result.productName.toLowerCase(), contains('bio'));
          expect(result.productName.toLowerCase(), contains('milch'));
        }
        
        // Fuzzy search should find Apfel even with typo
        results = offersProvider.performAdvancedSearch('Aplfe'); // Typo for Apfel
        expect(results.isNotEmpty, isTrue);
        expect(results.any((o) => o.productName.contains('Äpfel') || 
                                   o.productName.contains('Apfel')), isTrue);
      });
      
      test('OffersProvider performAdvancedSearch should work correctly', () {
        // Test with typo
        var results = offersProvider.performAdvancedSearch('Joghrt');
        expect(results.any((o) => o.productName.contains('Joghurt')), isTrue);
        
        // Test with category search
        results = offersProvider.performAdvancedSearch('Obst Apfel');
        expect(results.every((o) => o.originalCategory == 'Obst'), isTrue);
      });
      
      test('should reset search mode flags correctly', () {
        // Set various search modes
        offersProvider.searchWithFuzzyMatching('test');
        offersProvider.searchWithCategoryAwareness('test');
        
        // Reset
        offersProvider.resetSearchMode();
        
        // Now search should use default mode
        offersProvider.searchOffers('Milch');
        expect(offersProvider.offers.any((o) => 
          o.productName.contains('Milch')
        ), isTrue);
      });
    });
  }); // Ende von 'with random data'
    
    // Deterministic tests with fixed seed
    group('with deterministic data (seed = 42)', () {
      late MockDataService mockDataService;
      late OffersProvider offersProvider;
      late SearchService searchService;
      
      setUp(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});
        
        // Use fixed seed for reproducible results
        mockDataService = MockDataService(seed: 42);
        await mockDataService.initializeMockData(testMode: true);
        
        offersProvider = OffersProvider.mock(testService: mockDataService);
        await offersProvider.loadOffers(applyRegionalFilter: false);
        
        searchService = SearchService();
      });
      
      tearDown(() {
        mockDataService.dispose();
        offersProvider.dispose();
      });
      
      test('should find exact number of Bio-Obst offers with seed 42', () {
        // With seed 42, count the exact number of Bio-Obst offers
        final bioObstOffers = offersProvider.offers
          .where((o) => 
            o.productName.toLowerCase().contains('bio') &&
            ProductCategoryMapping.mapToFlashFeedCategory(
              o.retailer, 
              o.originalCategory
            ) == 'Obst & Gemüse'
          ).toList();
        
        // Log the count for reference (can be used to update expected value)
        print('Seed 42 generates ${bioObstOffers.length} Bio-Obst offers');
        
        // Search should find exactly the same number
        final results = offersProvider.performAdvancedSearch('Obst Bio');
        expect(results.length, equals(bioObstOffers.length));
        
        // Verify all results are correct
        for (final result in results) {
          expect(result.productName.toLowerCase(), contains('bio'));
          final category = ProductCategoryMapping.mapToFlashFeedCategory(
            result.retailer,
            result.originalCategory
          );
          expect(category, equals('Obst & Gemüse'));
        }
      });
      
      test('should consistently find same results with seed 42', () {
        // Run the same search multiple times
        final results1 = offersProvider.performAdvancedSearch('Bio');
        final results2 = offersProvider.performAdvancedSearch('Bio');
        
        // Results should be identical
        expect(results1.length, equals(results2.length));
        for (int i = 0; i < results1.length; i++) {
          expect(results1[i].id, equals(results2[i].id));
          expect(results1[i].productName, equals(results2[i].productName));
        }
      });
      
      test('should find predictable number of Milch products with seed 42', () {
        // Count products with 'milch' in searchable text (same logic as multiTermSearch)
        final milchInSearchableText = offersProvider.offers
          .where((o) {
            // Replicate the _getSearchableText logic from SearchService
            final category = ProductCategoryMapping.mapToFlashFeedCategory(
              o.retailer,
              o.originalCategory,
            );
            final searchableText = [
              o.productName,
              o.retailer,
              category,
              o.storeAddress ?? '',
            ].where((p) => p.isNotEmpty).join(' ').toLowerCase();
            
            return searchableText.contains('milch');
          })
          .toList();
        
        print('Seed 42 generates ${milchInSearchableText.length} offers with "milch" in searchable text');
        
        // Search should find exactly the same
        final results = searchService.multiTermSearch(
          offersProvider.offers, 
          'Milch'
        );
        
        // Should find all products with 'milch' anywhere in searchable text
        expect(results.length, equals(milchInSearchableText.length));
        
        // Additional verification: all results should contain 'milch' somewhere
        for (final result in results) {
          final category = ProductCategoryMapping.mapToFlashFeedCategory(
            result.retailer,
            result.originalCategory,
          );
          final searchableText = [
            result.productName,
            result.retailer,
            category,
            result.storeAddress ?? '',
          ].where((p) => p.isNotEmpty).join(' ').toLowerCase();
          
          expect(searchableText.contains('milch'), isTrue,
            reason: 'Result should contain "milch" in searchable text');
        }
      });
      
      test('edge case: no results for impossible search', () {
        // Search for something that doesn't exist
        final results = offersProvider.performAdvancedSearch('XYZ123ABC');
        expect(results.isEmpty, isTrue);
      });
      
      test('edge case: fuzzy search with extreme typo', () {
        // Even with seed, fuzzy search should handle extreme typos
        final results = searchService.fuzzySearch(
          offersProvider.offers,
          'Mlk', // Extreme typo for Milch
          maxDistance: 3
        );
        
        // Should find at least one Milch product
        expect(results.any((o) => o.productName.contains('Milch')), isTrue);
      });
    });
  }); // Ende von 'Task 9.3: Advanced Search Features'
}
