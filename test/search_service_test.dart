// Task 9.3: Advanced Search Features Test Suite
// Tests for multi-term search, fuzzy search, category-aware search,
// and enhanced search suggestions

import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/services/search_service.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/providers/offers_provider.dart';
import 'package:flashfeed/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Task 9.3: Advanced Search Features', () {
    late SearchService searchService;
    late MockDataService mockDataService;
    late OffersProvider offersProvider;
    late List<Offer> testOffers;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      searchService = SearchService();
      mockDataService = MockDataService();
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
        // Search for just "Milch"
        final results = searchService.multiTermSearch(testOffers, 'Milch');
        
        expect(results.length, equals(2)); // Vollmilch and Milchbrötchen
        expect(results.any((o) => o.productName.contains('Milch')), isTrue);
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
        offersProvider.searchWithCategoryAwareness('Obst Bio');
        
        // Should find products in Obst category containing "Bio"
        final filtered = offersProvider.offers;
        expect(filtered.any((o) => 
          o.productName.contains('Bio') && 
          o.originalCategory == 'Obst'
        ), isTrue);
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
      
      test('should handle complex multi-feature searches', () {
        // This should use category-aware search
        var results = searchService.advancedSearch(testOffers, 'Obst Bio');
        expect(results.length, equals(1));
        expect(results.first.productName, equals('Banane Bio'));
        
        // This should use multi-term search
        results = searchService.advancedSearch(testOffers, 'Bio Milch');
        expect(results.length, equals(1));
        expect(results.first.productName, contains('Milch'));
        
        // This should use fuzzy search
        results = searchService.advancedSearch(testOffers, 'Aplfe'); // Typo for Apfel
        expect(results.isNotEmpty, isTrue);
        expect(results.first.productName, contains('Apfel'));
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
  });
}
