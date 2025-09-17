// Task 9.3: Advanced Search Service for FlashFeed
// Implements multi-term search, fuzzy matching, category-aware search
// und enhanced search suggestions


import '../models/models.dart';
import '../data/product_category_mapping.dart';

class SearchService {
  // Singleton pattern
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  // Task 9.3.1: Multi-Term Search
  // "Bio Milch" findet Produkte mit BEIDEN Keywords
  List<Offer> multiTermSearch(List<Offer> offers, String searchQuery) {
    if (searchQuery.isEmpty) return offers;
    
    // Split query into individual terms
    final terms = searchQuery.toLowerCase().trim().split(' ')
        .where((term) => term.isNotEmpty)
        .toList();
    
    if (terms.isEmpty) return offers;
    
    // Filter offers that contain ALL terms
    return offers.where((offer) {
      final searchableText = _getSearchableText(offer).toLowerCase();
      
      // Check if ALL terms are found in the searchable text
      return terms.every((term) => searchableText.contains(term));
    }).toList();
  }

  // Task 9.3.2: Fuzzy Search with Levenshtein Distance
  // "Joghrt" findet "Joghurt"
  List<Offer> fuzzySearch(List<Offer> offers, String searchQuery, {int maxDistance = 2}) {
    if (searchQuery.isEmpty) return offers;
    
    final queryLower = searchQuery.toLowerCase().trim();
    final results = <_SearchResult>[];
    
    for (final offer in offers) {
      final searchableText = _getSearchableText(offer).toLowerCase();
      final words = searchableText.split(' ');
      
      // Find minimum distance to any word in the offer
      int minDistance = 999;
      for (final word in words) {
        final distance = _levenshteinDistance(queryLower, word);
        if (distance < minDistance) {
          minDistance = distance;
        }
        
        // Also check if query is substring (distance 0)
        if (word.contains(queryLower)) {
          minDistance = 0;
          break;
        }
      }
      
      // Include if within threshold
      if (minDistance <= maxDistance) {
        results.add(_SearchResult(offer, minDistance));
      }
    }
    
    // Sort by relevance (lower distance = more relevant)
    results.sort((a, b) => a.distance.compareTo(b.distance));
    
    return results.map((r) => r.offer).toList();
  }

  // Task 9.3.3: Category-Aware Search
  // "Obst Banane" sucht nur in Obst-Kategorie
  List<Offer> categoryAwareSearch(List<Offer> offers, String searchQuery) {
    if (searchQuery.isEmpty) return offers;
    
    final terms = searchQuery.toLowerCase().trim().split(' ');
    if (terms.isEmpty) return offers;
    
    // Check if first term matches a category
    String? detectedCategory;
    List<String> searchTerms = List.from(terms);
    
    // Get all FlashFeed categories
    final categories = ProductCategoryMapping.flashFeedCategories
        .map((c) => c.toLowerCase())
        .toList();
    
    // Check if any term matches a category
    for (int i = 0; i < terms.length; i++) {
      final term = terms[i];
      
      // Check exact match
      if (categories.contains(term)) {
        detectedCategory = ProductCategoryMapping.flashFeedCategories
            .firstWhere((c) => c.toLowerCase() == term);
        searchTerms.remove(term);
        break;
      }
      
      // Check partial match (e.g., "Milch" matches "Milchprodukte")
      final matchingCategory = categories.firstWhere(
        (cat) => cat.contains(term) || term.contains(cat),
        orElse: () => '',
      );
      
      if (matchingCategory.isNotEmpty) {
        detectedCategory = ProductCategoryMapping.flashFeedCategories
            .firstWhere((c) => c.toLowerCase() == matchingCategory);
        searchTerms.remove(term);
        break;
      }
    }
    
    // Filter by category first if detected
    List<Offer> filteredOffers = offers;
    if (detectedCategory != null) {
      filteredOffers = offers.where((offer) {
        final offerCategory = ProductCategoryMapping.mapToFlashFeedCategory(
          offer.retailer,
          offer.originalCategory,
        );
        return offerCategory == detectedCategory;
      }).toList();
    }
    
    // Then search within the filtered results
    if (searchTerms.isNotEmpty) {
      final remainingQuery = searchTerms.join(' ');
      return multiTermSearch(filteredOffers, remainingQuery);
    }
    
    return filteredOffers;
  }

  // Task 9.3.4: Enhanced Search Suggestions with Categories
  List<SearchSuggestion> getEnhancedSuggestions(
    List<Offer> offers,
    String query, {
    int maxSuggestions = 8,
  }) {
    if (query.isEmpty || query.length < 2) return [];
    
    final suggestions = <SearchSuggestion>{};
    final queryLower = query.toLowerCase();
    
    // Category suggestions
    for (final category in ProductCategoryMapping.flashFeedCategories) {
      if (category.toLowerCase().contains(queryLower)) {
        suggestions.add(SearchSuggestion(
          text: category,
          type: SuggestionType.category,
          icon: _getCategoryIcon(category),
        ));
      }
    }
    
    // Product suggestions
    final productNames = <String>{};
    for (final offer in offers) {
      if (offer.productName.toLowerCase().contains(queryLower)) {
        productNames.add(offer.productName);
      }
    }
    
    for (final productName in productNames.take(5)) {
      suggestions.add(SearchSuggestion(
        text: productName,
        type: SuggestionType.product,
        icon: 'package',
      ));
    }
    
    // Retailer suggestions
    final retailers = offers.map((o) => o.retailer).toSet();
    for (final retailer in retailers) {
      if (retailer.toLowerCase().contains(queryLower)) {
        suggestions.add(SearchSuggestion(
          text: retailer,
          type: SuggestionType.retailer,
          icon: 'store',
        ));
      }
    }
    
    // Popular search combinations
    if (queryLower.contains('bio')) {
      suggestions.add(SearchSuggestion(
        text: 'Bio Milch',
        type: SuggestionType.popular,
        icon: 'trending-up',
      ));
      suggestions.add(SearchSuggestion(
        text: 'Bio Obst',
        type: SuggestionType.popular,
        icon: 'trending-up',
      ));
    }
    
    // Sort by relevance and type
    final sortedSuggestions = suggestions.toList()
      ..sort((a, b) {
        // Categories first, then products, then retailers
        if (a.type != b.type) {
          return a.type.index.compareTo(b.type.index);
        }
        // Within same type, sort by text match position
        final aIndex = a.text.toLowerCase().indexOf(queryLower);
        final bIndex = b.text.toLowerCase().indexOf(queryLower);
        if (aIndex != bIndex) {
          // Prefer matches at the beginning
          if (aIndex == 0) return -1;
          if (bIndex == 0) return 1;
          return aIndex.compareTo(bIndex);
        }
        // Finally sort alphabetically
        return a.text.compareTo(b.text);
      });
    
    return sortedSuggestions.take(maxSuggestions).toList();
  }

  // Combined search that uses all features
  List<Offer> advancedSearch(List<Offer> offers, String searchQuery) {
    if (searchQuery.isEmpty) return offers;
    
    // Try category-aware search first
    var results = categoryAwareSearch(offers, searchQuery);
    
    // If no results, try fuzzy search
    if (results.isEmpty) {
      results = fuzzySearch(offers, searchQuery, maxDistance: 2);
    }
    
    // If still no results, try more lenient fuzzy search
    if (results.isEmpty) {
      results = fuzzySearch(offers, searchQuery, maxDistance: 3);
    }
    
    return results;
  }

  // Helper: Get all searchable text from an offer
  String _getSearchableText(Offer offer) {
    final category = ProductCategoryMapping.mapToFlashFeedCategory(
      offer.retailer,
      offer.originalCategory,
    );
    
    return '${offer.productName} ${offer.retailer} $category ${offer.storeAddress ?? ''}';
  }

  // Helper: Calculate Levenshtein distance for fuzzy matching
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    // Create distance matrix
    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );
    
    // Initialize first row and column
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    // Fill the matrix
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[s1.length][s2.length];
  }

  // Helper: Get icon for category
  String _getCategoryIcon(String category) {
    final iconMap = {
      'Obst & Gemüse': 'apple',
      'Milchprodukte': 'milk',
      'Fleisch & Wurst': 'beef',
      'Brot & Backwaren': 'croissant',
      'Getränke': 'cup-soda',
      'Süßwaren & Snacks': 'candy',
      'Tiefkühl': 'snowflake',
      'Konserven': 'package-2',
      'Haushaltsartikel': 'home',
      'Drogerie': 'heart',
      'Bio-Produkte': 'leaf',
      'Fertiggerichte': 'utensils',
    };
    
    return iconMap[category] ?? 'package';
  }
}

// Helper class for search results with relevance score
class _SearchResult {
  final Offer offer;
  final int distance;
  
  _SearchResult(this.offer, this.distance);
}

// Search suggestion model
class SearchSuggestion {
  final String text;
  final SuggestionType type;
  final String icon;
  
  SearchSuggestion({
    required this.text,
    required this.type,
    required this.icon,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSuggestion &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          type == other.type;
  
  @override
  int get hashCode => text.hashCode ^ type.hashCode;
}

enum SuggestionType {
  category,
  product,
  retailer,
  popular,
}
