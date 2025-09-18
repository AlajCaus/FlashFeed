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
  // FIX: Handle hyphens intelligently - "Bio Milch" finds "Bio-Milch" and vice versa
  List<Offer> multiTermSearch(List<Offer> offers, String searchQuery) {
    if (searchQuery.isEmpty) return offers;
    
    // Normalize query: treat hyphens as spaces for splitting
    final normalizedQuery = searchQuery.toLowerCase().trim()
        .replaceAll('-', ' ')  // Bio-Milch → Bio Milch
        .replaceAll(RegExp(r'\s+'), ' ');  // Multiple spaces → single space
    
    // Split query into individual terms
    final terms = normalizedQuery.split(' ')
        .where((term) => term.isNotEmpty)
        .toList();
    
    if (terms.isEmpty) return offers;
    
    // Filter offers that contain ALL terms
    return offers.where((offer) {
      // Normalize searchable text the same way
      final searchableText = _getSearchableText(offer).toLowerCase()
          .replaceAll('-', ' ')  // Bio-Äpfel → Bio Äpfel
          .replaceAll(RegExp(r'\s+'), ' ');  // Normalize spaces
      
      // Check if ALL terms are found in the searchable text
      return terms.every((term) => searchableText.contains(term));
    }).toList();
  }

  // Task 9.3.2: Fuzzy Search with Levenshtein Distance
  // "Joghrt" findet "Joghurt"
  // FIX: Handle hyphens - normalize for better fuzzy matching
  List<Offer> fuzzySearch(List<Offer> offers, String searchQuery, {int maxDistance = 2}) {
    if (searchQuery.isEmpty) return offers;
    
    // Normalize query: treat hyphens as spaces
    final queryLower = searchQuery.toLowerCase().trim()
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    final results = <_SearchResult>[];
    
    for (final offer in offers) {
      // Normalize searchable text the same way
      final searchableText = _getSearchableText(offer).toLowerCase()
          .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\s+'), ' ');
      final words = searchableText.split(' ');
      
      // Find minimum distance to any word in the offer
      int minDistance = 999;
      for (final word in words) {
        // Check exact substring match first
        if (word.contains(queryLower)) {
          minDistance = 0;
          break;
        }
        
        // Check whole word distance
        final distance = _levenshteinDistance(queryLower, word);
        if (distance < minDistance) {
          minDistance = distance;
        }
        
        // NEW: Check for fuzzy substring matches within the word
        // This handles cases like "mlch" matching "milch" in "vollmilch"
        if (word.length > queryLower.length) {
          // Try sliding windows of similar length to query
          for (int i = 0; i <= word.length - queryLower.length; i++) {
            // Check substring of exact query length
            if (i + queryLower.length <= word.length) {
              final substring = word.substring(i, i + queryLower.length);
              final substringDist = _levenshteinDistance(queryLower, substring);
              if (substringDist < minDistance) {
                minDistance = substringDist;
              }
            }
            
            // Check substring with 1 extra character (for missing letters)
            if (i + queryLower.length + 1 <= word.length) {
              final substring = word.substring(i, i + queryLower.length + 1);
              final substringDist = _levenshteinDistance(queryLower, substring);
              if (substringDist < minDistance) {
                minDistance = substringDist;
              }
            }
          }
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
    
    final queryLower = searchQuery.toLowerCase().trim();
    final terms = queryLower.split(' ').where((t) => t.isNotEmpty).toList();
    
    if (terms.isEmpty) return offers;
    
    // Find matching category - ONLY THE FIRST ONE
    String? detectedCategory;
    final remainingTerms = <String>[];
    
    for (int i = 0; i < terms.length; i++) {
      final term = terms[i];
      
      // If we already found a category, treat all remaining terms as search terms
      if (detectedCategory != null) {
        remainingTerms.add(term);
        continue;
      }
      
      bool isCategory = false;
      
      // Check each FlashFeed category
      for (final category in ProductCategoryMapping.flashFeedCategories) {
        final catLower = category.toLowerCase();
        
        // Exact match
        if (catLower == term) {
          detectedCategory = category;
          isCategory = true;
          break;
        }
        
        // Check words in category name (including hyphenated words)
        // FIX: Also split on hyphens for better matching
        final catWords = catLower
        .replaceAll('&', ' ')
        .replaceAll('-', ' ')  // Also split hyphenated words
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
          .map((w) => w.trim())
          .toList();
            
        for (final catWord in catWords) {
          // Exact word match
          if (catWord == term) {
            detectedCategory = category;
            isCategory = true;
            break;
          }
          // Check if category word starts with term (for partial matches like "milch" in "milchprodukte")
          // But NOT for hyphenated words like "bio-produkte"
          if (!catWord.contains('-') && catWord.length > 3 && catWord.startsWith(term) && term.length >= 3) {
            detectedCategory = category;
            isCategory = true;
            break;
          }
        }
        
        if (isCategory) break;
      }
      
      if (!isCategory) {
        remainingTerms.add(term);
      } else {
        // All remaining terms after the category are search terms
        for (int j = i + 1; j < terms.length; j++) {
          remainingTerms.add(terms[j]);
        }
        break; // Stop processing terms once we found a category
      }
    }
    
    // If a category was detected, filter by it first
    List<Offer> result = offers;
    if (detectedCategory != null) {
      // Filter by category
      result = offers.where((offer) {
        final mapped = ProductCategoryMapping.mapToFlashFeedCategory(
          offer.retailer,
          offer.originalCategory,
        );
        return mapped == detectedCategory;
      }).toList();
      
      // Then filter by remaining terms in product name only
      if (remainingTerms.isNotEmpty) {
        result = result.where((offer) {
          final productName = offer.productName.toLowerCase();
          return remainingTerms.every((term) => productName.contains(term));
        }).toList();
      }
    } else {
      // No category detected - search all terms in full searchable text
      // This handles cases like "EDEKA" or other non-category searches
      result = offers.where((offer) {
      // Normalize for hyphen handling
      final searchText = _getSearchableText(offer).toLowerCase()
            .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\s+'), ' ');
      return terms.every((term) => searchText.contains(term));
    }).toList();
    }
    
    return result;
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
    
    // Try category-aware search first (handles "Obst Bio" correctly)
    var results = categoryAwareSearch(offers, searchQuery);
    
    // If category search returned results, use them
    if (results.isNotEmpty) {
      return results;
    }
    
    // If no results, try multi-term search (handles "Bio Milch")
    results = multiTermSearch(offers, searchQuery);
    if (results.isNotEmpty) {
      return results;
    }
    
    // If still no results, try fuzzy search
    results = fuzzySearch(offers, searchQuery, maxDistance: 2);
    if (results.isNotEmpty) {
      return results;
    }
    
    // Last resort: more lenient fuzzy search
    return fuzzySearch(offers, searchQuery, maxDistance: 3);
  }

  // Helper: Get all searchable text from an offer
  String _getSearchableText(Offer offer) {
    final category = ProductCategoryMapping.mapToFlashFeedCategory(
      offer.retailer,
      offer.originalCategory,
    );
    
    // Include all searchable fields: product name, retailer, category, and address
    // Make sure everything is properly spaced
    final parts = [
      offer.productName,
      offer.retailer,
      category,
      offer.storeAddress ?? '',
    ];
    
    // Join parts and normalize for better search matching
    // NOTE: We don't replace hyphens here to preserve original text for display
    // Hyphen normalization happens in the search methods themselves
    return parts.where((p) => p.isNotEmpty).join(' ');
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
