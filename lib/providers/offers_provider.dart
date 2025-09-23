// FlashFeed Offers Provider - Angebote & Preisvergleich
// Mit regionaler Filterung

import 'dart:async'; // Timer for debouncing

import 'package:flutter/material.dart';
import '../repositories/offers_repository.dart';
import '../repositories/mock_offers_repository.dart';
import '../data/product_category_mapping.dart';
import '../models/models.dart';
import '../main.dart'; // Access to global mockDataService
import '../services/mock_data_service.dart'; // For test service parameter
import '../providers/location_provider.dart';
import '../providers/user_provider.dart'; // For demo retailer filtering
import '../services/search_service.dart'; // Advanced Search

// Cache Entry for filter results
class FilterCacheEntry {
  final List<Offer> offers;
  final DateTime timestamp;
  final String cacheKey;
  
  FilterCacheEntry({
    required this.offers,
    required this.timestamp,
    required this.cacheKey,
  });
  
  bool get isExpired => 
    DateTime.now().difference(timestamp) > Duration(minutes: 5);
}

class OffersProvider extends ChangeNotifier {
  final OffersRepository _offersRepository;
  final SearchService _searchService = SearchService();
  
  // NEW: Reference to LocationProvider for regional data
  LocationProvider? _locationProvider;

  // Reference to UserProvider for demo retailer filtering
  UserProvider? _userProvider;

  // State
  List<Offer> _allOffers = [];
  List<Offer> _unfilteredOffers = []; // Keep ALL offers before regional filtering
  List<Offer> _filteredOffers = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false; // Track disposal state
  
  // Service reference for proper callback cleanup (FIX)
  MockDataService? _registeredService;
  
  // Cache Management
  final Map<String, FilterCacheEntry> _filterCache = {};
  // static const Duration _cacheTimeToLive = Duration(minutes: 5); // Currently unused
  static const int _maxCacheEntries = 50;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  
  // Pagination State
  // Default to 1000 for production (effectively no pagination for small datasets)
  // Can be overridden to 20 for testing via setPageSizeForTesting()
  static int _pageSize = 1000;
  int _currentPage = 0;
  bool _hasMoreOffers = true;
  bool _isLoadingMore = false;
  List<Offer> _displayedOffers = []; // Paginated subset
  
  // Debounced Search
  Timer? _searchDebounceTimer;
  final Duration _searchDebounceDelay = const Duration(milliseconds: 300); // Made final as suggested
  bool _isSearchPending = false;
  String _pendingSearchQuery = '';
  
  // Filter State
  String? _selectedCategory;
  String? _selectedRetailer;
  OfferSortType _sortType = OfferSortType.priceAsc;
  String _searchQuery = '';
  double? _maxPrice;
  bool _showOnlyWithDiscount = false;
  
  // Regional State
  String? _userPLZ;
  List<String> _availableRetailers = [];
  
  // Dynamic coordinates for distance sorting
  double? _userLatitude;
  double? _userLongitude;
  
  // Test helper to override page size
  @visibleForTesting
  static void setPageSizeForTesting(int size) {
    _pageSize = size;
  }
  
  // Reset page size to default after tests
  @visibleForTesting
  static void resetPageSize() {
    _pageSize = 1000;
  }
  
  // Constructor
  OffersProvider(this._offersRepository) {
    _initializeCallbacks();
  }
  
  // Factory constructor with mock repository (backwards-compatible)
  OffersProvider.mock({MockDataService? testService, int? seed}) 
      : _offersRepository = MockOffersRepository(
          testService: testService ?? MockDataService(seed: seed)
        ) {
    _initializeCallbacks(testService ?? (_offersRepository as MockOffersRepository).mockDataService);
  }
  
  // Initialize Provider-Callbacks with optional test service
  void _initializeCallbacks([MockDataService? testService]) {
    final service = testService ?? mockDataService; // Fall back to global instance
    _registeredService = service; // Track service for cleanup (FIX)
    
    if (service.isInitialized) {
      // Register callback for offers updates
      service.setOffersCallback(() {
        if (!_disposed) { // Safety check
          refresh();
        }
      });
    }
  }
  
  // Cross-Provider Communication Methods
  void registerWithLocationProvider(LocationProvider locationProvider) {
    _locationProvider = locationProvider; // Store reference
    
    // Register for both location and regional data updates
    locationProvider.registerLocationChangeCallback(_onLocationChanged);
    locationProvider.registerRegionalDataCallback(_onRegionalDataChanged);
    
    // Get initial regional data if available
    if (locationProvider.hasPostalCode && locationProvider.availableRetailersInRegion.isNotEmpty) {
      _userPLZ = locationProvider.postalCode;
      _availableRetailers = locationProvider.availableRetailersInRegion;
      // Don't load offers here - let the initialization flow handle it
    }
    
    // Get initial coordinates
    _updateUserCoordinates();
    
    debugPrint('OffersProvider: Registered with LocationProvider');
  }
  
  void unregisterFromLocationProvider(LocationProvider locationProvider) {
    locationProvider.unregisterLocationChangeCallback(_onLocationChanged);
    locationProvider.unregisterRegionalDataCallback(_onRegionalDataChanged);
    _locationProvider = null; // Clear reference
    debugPrint('OffersProvider: Unregistered from LocationProvider');
  }

  // Register UserProvider for demo retailer filtering
  void registerWithUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;

    // Listen to UserProvider changes (for premium status changes)
    userProvider.addListener(_onUserProviderChanged);

    debugPrint('OffersProvider: Registered with UserProvider');
  }

  void unregisterFromUserProvider() {
    if (_userProvider != null) {
      _userProvider!.removeListener(_onUserProviderChanged);
    }
    _userProvider = null;
    debugPrint('OffersProvider: Unregistered from UserProvider');
  }

  // Callback when UserProvider changes (e.g., premium status)
  void _onUserProviderChanged() {
    if (_disposed) return;

    debugPrint('OffersProvider: UserProvider changed, reloading offers with new retailer selection');

    // Clear cache when user status changes (important for premium upgrade)
    _filterCache.clear();
    debugPrint('OffersProvider: Cache cleared due to user status change');

    // Reload offers with new retailer selection
    loadOffers(applyRegionalFilter: false);
  }
  
  // Callback handlers
  void _onLocationChanged() {
    if (_disposed) return;
    
    // Check if location was cleared (no PLZ)
    if (_locationProvider != null && _locationProvider!.postalCode == null) {
      // Location was cleared - reset our state
      _userPLZ = null;
      _availableRetailers = [];
      // Clear coordinates too
      _userLatitude = null;
      _userLongitude = null;
      debugPrint('OffersProvider: Location cleared, resetting state');
      notifyListeners();
      return;
    }
    
    // Update coordinates when location changes
    _updateUserCoordinates();
    
    debugPrint('OffersProvider: Location changed, reloading offers');
    loadOffers(applyRegionalFilter: true);
  }
  
  void _onRegionalDataChanged(String? plz, List<String> availableRetailers) {
    if (_disposed) return;
    if (plz != null && availableRetailers.isNotEmpty) {
      // Set PLZ and retailers immediately for use by loadOffers
      _userPLZ = plz;
      _availableRetailers = availableRetailers;
      debugPrint('OffersProvider: Regional data changed - PLZ: $plz, Retailers: $availableRetailers');
      // Load offers with the new regional data
      loadOffers(applyRegionalFilter: true);
    }
  }
  
  // Update user coordinates from LocationProvider
  void _updateUserCoordinates() {
    if (_locationProvider != null) {
      // GPS coordinates if available
      if (_locationProvider!.latitude != null && _locationProvider!.longitude != null) {
        _userLatitude = _locationProvider!.latitude;
        _userLongitude = _locationProvider!.longitude;
        debugPrint('OffersProvider: Updated coordinates from GPS: $_userLatitude, $_userLongitude');
      } 
      // Fallback: PLZ to coordinates
      else if (_locationProvider!.postalCode != null && _locationProvider!.postalCode!.isNotEmpty) {
        final coords = _convertPLZToCoordinates(_locationProvider!.postalCode!);
        _userLatitude = coords['lat'];
        _userLongitude = coords['lng'];
        debugPrint('OffersProvider: Updated coordinates from PLZ ${_locationProvider!.postalCode}: $_userLatitude, $_userLongitude');
      }
      // Default: Berlin Mitte (will use fallback in getter)
      else {
        _userLatitude = null;
        _userLongitude = null;
        debugPrint('OffersProvider: No location data available, using default coordinates');
      }
      
      // Re-sort if distance sorting is active
      if (_sortType == OfferSortType.distanceAsc && !_disposed) {
        _applySorting();
      }
    }
  }
  
  // Convert PLZ to approximate coordinates for major German cities
  Map<String, double> _convertPLZToCoordinates(String plz) {
    // Major German cities mapping
    if (plz.startsWith('10') || plz.startsWith('12') || plz.startsWith('13') || plz.startsWith('14')) {
      return {'lat': 52.5200, 'lng': 13.4050}; // Berlin
    } else if (plz.startsWith('80') || plz.startsWith('81') || plz.startsWith('82') || plz.startsWith('85')) {
      return {'lat': 48.1351, 'lng': 11.5820}; // München
    } else if (plz.startsWith('40') || plz.startsWith('41') || plz.startsWith('42') || plz.startsWith('47')) {
      return {'lat': 51.2277, 'lng': 6.7735}; // Düsseldorf
    } else if (plz.startsWith('50') || plz.startsWith('51') || plz.startsWith('52') || plz.startsWith('53')) {
      return {'lat': 50.9375, 'lng': 6.9603}; // Köln
    } else if (plz.startsWith('60') || plz.startsWith('61') || plz.startsWith('63') || plz.startsWith('65')) {
      return {'lat': 50.1109, 'lng': 8.6821}; // Frankfurt
    } else if (plz.startsWith('70') || plz.startsWith('71') || plz.startsWith('72') || plz.startsWith('73')) {
      return {'lat': 48.7758, 'lng': 9.1829}; // Stuttgart
    } else if (plz.startsWith('01') || plz.startsWith('02') || plz.startsWith('03')) {
      return {'lat': 51.0504, 'lng': 13.7373}; // Dresden
    } else if (plz.startsWith('20') || plz.startsWith('21') || plz.startsWith('22') || plz.startsWith('25')) {
      return {'lat': 53.5511, 'lng': 9.9937}; // Hamburg
    } else if (plz.startsWith('30') || plz.startsWith('31') || plz.startsWith('37') || plz.startsWith('38')) {
      return {'lat': 52.3759, 'lng': 9.7320}; // Hannover
    } else if (plz.startsWith('90') || plz.startsWith('91') || plz.startsWith('95')) {
      return {'lat': 49.4521, 'lng': 11.0767}; // Nürnberg
    } else {
      return {'lat': 52.5200, 'lng': 13.4050}; // Default: Berlin
    }
  }
  
  // Getters
  List<Offer> get offers => _displayedOffers.isNotEmpty ? _displayedOffers : _filteredOffers;
  List<Offer> get displayedOffers => _displayedOffers.isNotEmpty ? _displayedOffers : _filteredOffers; // Task 10: For pagination
  List<Offer> get allOffers => _allOffers;
  List<Offer> get filteredOffers => _filteredOffers; // For UI components
  int get totalOffers => _allOffers.length; // Total count for statistics
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Filter Getters
  String? get selectedCategory => _selectedCategory;
  String? get selectedRetailer => _selectedRetailer;
  OfferSortType get sortType => _sortType;
  String get searchQuery => _searchQuery;
  double? get maxPrice => _maxPrice;
  bool get showOnlyWithDiscount => _showOnlyWithDiscount;
  List<String> get availableRetailers => _availableRetailers;
  
  // Regional Getters
  String? get userPLZ => _userPLZ;
  bool get hasRegionalFiltering => _userPLZ != null && _availableRetailers.isNotEmpty;
  
  //  Performance Getters
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearchPending => _isSearchPending;
  int get currentPage => _currentPage;
  int get totalPages => (_filteredOffers.length / _pageSize).ceil();
  bool get hasMorePages => _currentPage < totalPages - 1;
  double get cacheHitRate => _cacheHits + _cacheMisses == 0 ? 0 : 
    _cacheHits / (_cacheHits + _cacheMisses).toDouble();
  Map<String, dynamic> get cacheStatistics => {
    'hits': _cacheHits,
    'misses': _cacheMisses,
    'hitRate': '${(cacheHitRate * 100).toStringAsFixed(1)}%',
    'entries': _filterCache.length,
    'maxEntries': _maxCacheEntries,
    'memoryUsage': _estimateCacheMemoryUsage(),
  };
  
  // Location Getters for distance sorting
  double get currentLatitude => _userLatitude ?? 52.5200; // Berlin Mitte fallback
  double get currentLongitude => _userLongitude ?? 13.4050;
  bool get hasUserLocation => _userLatitude != null && _userLongitude != null;
  String get locationSource {
    if (hasUserLocation) {
      return _userPLZ != null ? 'GPS + PLZ' : 'GPS';
    } else if (_userPLZ != null) {
      return 'PLZ';
    } else {
      return 'Default (Berlin)';
    }
  }
  
  // NEW: Task 5c.2 - Get regional availability message
  String getRegionalAvailabilityMessage(String retailerName) {
    if (_userPLZ == null) {
      return '$retailerName - Verfügbarkeit unbekannt';
    }
    
    if (_availableRetailers.contains(retailerName)) {
      return '$retailerName ist in Ihrer Region (PLZ: $_userPLZ) verfügbar';
    } else {
      return '$retailerName ist in Ihrer Region (PLZ: $_userPLZ) nicht verfügbar';
    }
  }
  
  // NEW: Task 5c.2 - Empty state message
  String get emptyStateMessage {
    if (_filteredOffers.isEmpty && _userPLZ != null) {
      if (_allOffers.isEmpty) {
        return 'Keine Angebote verfügbar';
      } else if (hasRegionalFiltering && _availableRetailers.isEmpty) {
        return 'Keine Händler in Ihrer Region (PLZ: $_userPLZ) verfügbar';
      } else if (hasRegionalFiltering) {
        return 'Keine Angebote für Ihre Filterkriterien in PLZ $_userPLZ gefunden';
      }
    }
    return 'Keine Angebote gefunden';
  }
  
  // Statistics
  int get totalOffersCount => _allOffers.length;
  int get filteredOffersCount => _filteredOffers.length;
  double get averagePrice => _filteredOffers.isEmpty ? 0.0 : 
      _filteredOffers.map((o) => o.price).reduce((a, b) => a + b) / _filteredOffers.length;
  double get totalSavings => _filteredOffers
      .where((o) => o.hasDiscount)
      .map((o) => o.savings)
      .fold(0.0, (sum, savings) => sum + savings);
  
  // Task 9.2: Enhanced UI State Management
  bool get hasActiveFilters => 
    _selectedCategory != null || 
    _selectedRetailer != null || 
    _maxPrice != null || 
    _showOnlyWithDiscount || 
    _searchQuery.isNotEmpty;
    
  String getFilterStatistics() {
    if (hasRegionalFiltering) {
      return '$filteredOffersCount von $totalOffersCount Angeboten in PLZ $_userPLZ';
    } else {
      return '$filteredOffersCount von $totalOffersCount Angeboten';
    }
  }
  
  Map<String, dynamic> getFilterSummary() {
    final activeFilters = <String>[];
    
    if (_selectedCategory != null) activeFilters.add('Kategorie: $_selectedCategory');
    if (_selectedRetailer != null) activeFilters.add('Händler: $_selectedRetailer');
    if (_maxPrice != null) activeFilters.add('Max. Preis: ${_maxPrice!.toStringAsFixed(2)}€');
    if (_showOnlyWithDiscount) activeFilters.add('Nur Rabatte');
    if (_searchQuery.isNotEmpty) activeFilters.add('Suche: "$_searchQuery"');
    if (hasRegionalFiltering) activeFilters.add('Region: PLZ $_userPLZ');
    
    return {
      'count': filteredOffersCount,
      'total': totalOffersCount,
      'percentage': totalOffersCount > 0 ? (filteredOffersCount / totalOffersCount * 100).round() : 0,
      'activeFilters': activeFilters,
      'hasFilters': hasActiveFilters,
      'hasRegionalFilter': hasRegionalFiltering,
    };
  }
  
  // Load Offers with regional filtering support (Task 5c.2)
  Future<void> loadOffers({bool applyRegionalFilter = true, bool forceRefresh = false}) async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Load ALL offers from repository
      _unfilteredOffers = await _offersRepository.getAllOffers();
      _allOffers = List.from(_unfilteredOffers); // Copy for filtering
      
      // Apply regional filtering if requested
      if (applyRegionalFilter) {
        // Try to get PLZ from LocationProvider if not set yet
        if (_userPLZ == null && _locationProvider != null) {
          _userPLZ = _locationProvider!.postalCode;
        }

        // Apply regional filtering if PLZ is available
        if (_userPLZ != null && _userPLZ!.isNotEmpty) {
          // Use already set _availableRetailers if available (from callback)
          // Otherwise get them from LocationProvider
          if (_availableRetailers.isEmpty && _locationProvider != null) {
            _availableRetailers = _locationProvider!.getAvailableRetailersForPLZ(_userPLZ!);
          }

          // Filter offers to only show regionally available
          if (_availableRetailers.isNotEmpty) {
            _allOffers = _allOffers.where((offer) =>
                _availableRetailers.contains(offer.retailer)
            ).toList();
            
            debugPrint('OffersProvider: Regional filtering applied - PLZ: $_userPLZ, Retailers: $_availableRetailers');
            debugPrint('OffersProvider: Filtered from ${_unfilteredOffers.length} to ${_allOffers.length} offers');
          } else {
            debugPrint('OffersProvider: No retailers available for PLZ $_userPLZ');
          }
        } else {
          // No PLZ available, can't filter regionally
          debugPrint('OffersProvider: Regional filtering requested but no PLZ available');
          // Extract all retailers if no regional filtering
          _availableRetailers = _allOffers
              .map((offer) => offer.retailer)
              .toSet()
              .toList();
        }
      } else {
        // No regional filtering requested
        // Extract all retailers
        _availableRetailers = _allOffers
            .map((offer) => offer.retailer)
            .toSet()
            .toList();
      }

      // Apply Demo User retailer filtering (overrides regional filtering)
      if (_userProvider != null && _userProvider!.selectedRetailers.isNotEmpty) {
        final selectedRetailers = _userProvider!.selectedRetailers;
        _allOffers = _allOffers.where((offer) =>
            selectedRetailers.contains(offer.retailer)
        ).toList();

        debugPrint('OffersProvider: Demo retailer filtering applied - Selected: $selectedRetailers');
        debugPrint('OffersProvider: Filtered to ${_allOffers.length} offers for demo retailers');
      }

      // CRITICAL: Must await _applyFilters to ensure sorting completes
      await _applyFilters();

    } catch (e) {
      _setError('Fehler beim Laden der Angebote: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // DEPRECATED: Use loadOffers(applyRegionalFilter: true) instead
  // This method is kept for backwards compatibility but should not be used
  @Deprecated('Use loadOffers(applyRegionalFilter: true) instead')
  Future<void> loadRegionalOffers(String plz, List<String> availableRegionalRetailers) async {
    _userPLZ = plz;
    _availableRetailers = availableRegionalRetailers;
    await loadOffers(applyRegionalFilter: true);
  }
  
  // NEW: Task 5c.2 - Public method for regional offers
  List<Offer> getRegionalOffers([String? plz]) {
    final targetPLZ = plz ?? _userPLZ;
    
    if (targetPLZ == null || targetPLZ.isEmpty) {
      // No PLZ available - return all offers
      return _allOffers;
    }
    
    // Use LocationProvider logic to get available retailers
    final availableRetailers = _locationProvider?.getAvailableRetailersForPLZ(targetPLZ) ?? [];
    
    // Filter ALL offers by available retailers (not the already filtered ones)
    return _allOffers.where((offer) => 
        availableRetailers.contains(offer.retailer)
    ).toList();
  }
  
  // Category Filter
  Future<void> filterByCategory(String? category) async {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      await _applyFilters();
    }
  }
  
  void clearCategoryFilter() {
    filterByCategory(null);
  }
  
  // Retailer Filter
  Future<void> filterByRetailer(String? retailer) async {
    if (_selectedRetailer != retailer) {
      _selectedRetailer = retailer;
      await _applyFilters();
    }
  }
  
  void clearRetailerFilter() {
    filterByRetailer(null);
  }
  
  // Price Filter
  Future<void> setMaxPrice(double? price) async {
    if (_maxPrice != price) {
      _maxPrice = price;
      await _applyFilters();
    }
  }
  
  void clearMaxPrice() {
    setMaxPrice(null);
  }
  
  // Discount Filter
  Future<void> setShowOnlyWithDiscount(bool showOnly) async {
    if (_showOnlyWithDiscount != showOnly) {
      _showOnlyWithDiscount = showOnly;
      await _applyFilters();
    }
  }
  
  // Task 9.3 & 9.4.3: Enhanced Search with debouncing
  void searchOffers(String query, {bool immediate = false}) {
    if (_searchQuery == query) return;
    
    _pendingSearchQuery = query;
    
    // Cancel previous timer
    _searchDebounceTimer?.cancel();
    
    if (immediate || query.isEmpty) {
      // Immediate search or clearing search
      _performSearch(query);
    } else {
      // Debounced search
      _isSearchPending = true;
      notifyListeners();
      
      _searchDebounceTimer = Timer(_searchDebounceDelay, () {
        if (!_disposed) {
          _performSearch(_pendingSearchQuery);
        }
      });
    }
  }
  
  Future<void> _performSearch(String query) async {
    _searchQuery = query;
    _isSearchPending = false;
    _pendingSearchQuery = '';
    await _applyFilters();
  }
  
  // Task 9.3.1: Multi-Term Search
  Future<void> searchWithMultipleTerms(String query) async {
    _searchQuery = query;
    await _applyFilters();
  }
  
  // Task 9.3.2: Fuzzy Search
  Future<void> searchWithFuzzyMatching(String query, {int tolerance = 2}) async {
    _searchQuery = query;
    _fuzzySearchTolerance = tolerance;
    _useFuzzySearch = true;
    await _applyFilters();
  }
  
  // Task 9.3.3: Category-Aware Search
  Future<void> searchWithCategoryAwareness(String query) async {
    _searchQuery = query;
    _useCategoryAwareSearch = true;
    _useFuzzySearch = false; // Reset other search modes
    await _applyFilters();
  }
  
  // Task 9.3: Search mode flags
  bool _useFuzzySearch = false;
  bool _useCategoryAwareSearch = false;
  int _fuzzySearchTolerance = 2;
  
  void clearSearch() {
    searchOffers('');
  }
  
  // Sorting
  Future<void> setSortType(OfferSortType sortType) async {
    if (_sortType != sortType) {
      _sortType = sortType;

      _setLoading(true);
      try {
        // Pass user coordinates for distance sorting
        if (sortType == OfferSortType.distanceAsc) {
          _filteredOffers = await _offersRepository.getSortedOffers(
            _filteredOffers,
            sortType,
            userLat: currentLatitude,  // Uses getter with fallback
            userLng: currentLongitude
          );
          debugPrint('OffersProvider: Distance sorting applied with coordinates: $currentLatitude, $currentLongitude ($locationSource)');
        } else {
          _filteredOffers = await _offersRepository.getSortedOffers(_filteredOffers, sortType);
        }

        // Update displayed offers with the sorted data
        _resetPagination();
        _updateDisplayedOffers();

        // Notify listeners after successful sorting
        if (!_disposed) {
          notifyListeners();
        }
      } catch (e) {
        _setError('Fehler beim Sortieren: ${e.toString()}');
      } finally {
        _setLoading(false);
      }
    }
  }
  
  // Apply All Filters with caching and regional awareness (Task 5c.2 & 9.4.1)
  Future<void> _applyFilters() async {
    // Generate cache key
    final cacheKey = _generateCacheKey(
      _selectedCategory,
      _selectedRetailer,
      _maxPrice,
      _sortType,
      _searchQuery,
      _showOnlyWithDiscount,
    );
    
    // Check cache first
    final cachedEntry = _checkCache(cacheKey);
    if (cachedEntry != null) {
      _filteredOffers = List.from(cachedEntry.offers);
      _cacheHits++;
      debugPrint('OffersProvider: Cache hit! Key: $cacheKey (Hit rate: ${(cacheHitRate * 100).toStringAsFixed(1)}%)');
      _resetPagination();
      _updateDisplayedOffers();
      notifyListeners();
      return;
    }
    
    _cacheMisses++;
    
    List<Offer> filtered = List.from(_allOffers);
    
    // Regional filtering is already applied in _allOffers
    // So we don't need to filter again here
    
    // Category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((offer) {
        String offerCategory = ProductCategoryMapping.mapToFlashFeedCategory(
          offer.retailer, 
          offer.originalCategory
        );
        return offerCategory == _selectedCategory;
      }).toList();
    }
    
    // Retailer filter
    if (_selectedRetailer != null) {
      filtered = filtered.where((offer) => offer.retailer == _selectedRetailer).toList();
    }
    
    // Price filter
    if (_maxPrice != null) {
      filtered = filtered.where((offer) => offer.price <= _maxPrice!).toList();
    }
    
    // Discount filter
    if (_showOnlyWithDiscount) {
      filtered = filtered.where((offer) => offer.hasDiscount).toList();
    }
    
    // Task 9.4.3: Check for pending search
    if (_isSearchPending) {
      // Skip applying filters while search is pending
      return;
    }
    
    // Task 9.3: Advanced Search Implementation
    if (_searchQuery.isNotEmpty) {
      if (_useCategoryAwareSearch) {
        // Category-aware search (e.g., "Obst Banane")
        filtered = _searchService.categoryAwareSearch(filtered, _searchQuery);
        _useCategoryAwareSearch = false; // Reset flag after use
      } else if (_useFuzzySearch) {
        // Fuzzy search (e.g., "Joghrt" finds "Joghurt")
        filtered = _searchService.fuzzySearch(
          filtered, 
          _searchQuery, 
          maxDistance: _fuzzySearchTolerance
        );
        _useFuzzySearch = false; // Reset flag after use
      } else if (_searchQuery.contains(' ')) {
        // Multi-term search if query contains spaces
        filtered = _searchService.multiTermSearch(filtered, _searchQuery);
      } else {
        // Fall back to simple search for single terms
        String query = _searchQuery.toLowerCase();
        filtered = filtered.where((offer) =>
            offer.productName.toLowerCase().contains(query) ||
            offer.retailer.toLowerCase().contains(query) ||
            (offer.storeAddress?.toLowerCase().contains(query) ?? false)
        ).toList();
      }
    }
    
    _filteredOffers = filtered;
    
    // Task 9.4.1: Add to cache
    _addToCache(cacheKey, filtered);
    
    // NEW: Track empty results for UI feedback (Task 5c.2)
    if (hasRegionalFiltering && filtered.isEmpty && _allOffers.isNotEmpty) {
      debugPrint('⚠️ Regional filtering active: No offers available in PLZ $_userPLZ');
      debugPrint('Available retailers: $_availableRetailers');
    }
    
    // Task 9.4.2: Apply sorting BEFORE updating display
    // This ensures sorted order is visible immediately
    await _applySorting();
  }
  
  Future<void> _applySorting() async {
    debugPrint('_applySorting called: sortType=$_sortType, offers=${_filteredOffers.length}');
    try {
      // Always apply sorting if we have a sort type set
      // Don't skip sorting even if list is empty - it needs to be ready when filled
      if (_filteredOffers.isNotEmpty) {
        debugPrint('Applying sort type: $_sortType to ${_filteredOffers.length} offers');
        // Pass user coordinates for distance sorting
        if (_sortType == OfferSortType.distanceAsc) {
          _filteredOffers = await _offersRepository.getSortedOffers(
            _filteredOffers,
            _sortType,
            userLat: currentLatitude,  // Uses getter with fallback
            userLng: currentLongitude
          );
        } else {
          _filteredOffers = await _offersRepository.getSortedOffers(_filteredOffers, _sortType);
        }

        // Debug output to verify sorting
        if (_filteredOffers.isNotEmpty) {
          debugPrint('Sorting applied: ${_sortType.toString()} - First offer price: ${_filteredOffers.first.price}€');
          // Print first 5 prices to see sorting order
          debugPrint('First 5 sorted prices:');
          for (int i = 0; i < _filteredOffers.length && i < 5; i++) {
            debugPrint('  ${i+1}. ${_filteredOffers[i].productName}: ${_filteredOffers[i].price}€');
          }
        }
      }

      // Always update displayed offers after sorting
      _resetPagination();
      _updateDisplayedOffers();

      if (_disposed) return; // Defensive check against disposed provider
      notifyListeners();
    } catch (e) {
      // Sorting errors are non-critical, just log
      debugPrint('Sorting error: $e');
      // Still update UI even if sorting fails
      _resetPagination();
      _updateDisplayedOffers();
      if (!_disposed) {
        notifyListeners();
      }
    }
  }
  
  // Clear All Filters
  Future<void> clearAllFilters() async {
    _selectedCategory = null;
    _selectedRetailer = null;
    _maxPrice = null;
    _showOnlyWithDiscount = false;
    _searchQuery = '';
    await _applyFilters();
  }
  
  // Task 9.4.1: Cache Management Methods
  String _generateCacheKey(
    String? category,
    String? retailer,
    double? maxPrice,
    OfferSortType sortType,
    String searchQuery,
    bool showOnlyWithDiscount,
  ) {
    final parts = [
      category ?? 'null',
      retailer ?? 'null',
      maxPrice?.toString() ?? 'null',
      sortType.toString(),
      searchQuery.isEmpty ? 'null' : searchQuery,
      showOnlyWithDiscount.toString(),
      _userPLZ ?? 'null', // Include regional context
    ];
    return parts.join('|');
  }
  
  FilterCacheEntry? _checkCache(String key) {
    final entry = _filterCache[key];
    if (entry == null) return null;
    
    // Check if expired
    if (entry.isExpired) {
      _filterCache.remove(key);
      return null;
    }
    
    return entry;
  }
  
  void _addToCache(String key, List<Offer> offers) {
    // Task 9.4.4: LRU eviction if cache is full
    if (_filterCache.length >= _maxCacheEntries) {
      _evictOldestCacheEntry();
    }
    
    _filterCache[key] = FilterCacheEntry(
      offers: List.from(offers), // Create a copy
      timestamp: DateTime.now(),
      cacheKey: key,
    );
  }
  
  void _evictOldestCacheEntry() {
    if (_filterCache.isEmpty) return;
    
    // Find oldest entry
    String? oldestKey;
    DateTime? oldestTime;
    
    for (final entry in _filterCache.entries) {
      if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
        oldestTime = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }
    
    if (oldestKey != null) {
      _filterCache.remove(oldestKey);
      debugPrint('OffersProvider: Evicted oldest cache entry (LRU)');
    }
  }
  
  void clearCache() {
    _filterCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    debugPrint('OffersProvider: Cache cleared');
    notifyListeners();
  }
  
  // Task 9.4.2: Pagination Methods
  void _resetPagination() {
    _currentPage = 0;
    _hasMoreOffers = _filteredOffers.length > _pageSize;
    _displayedOffers.clear();
  }
  
  void _updateDisplayedOffers() {
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, _filteredOffers.length);

    debugPrint('DEBUG _updateDisplayedOffers: page=$_currentPage, startIndex=$startIndex, endIndex=$endIndex');
    debugPrint('DEBUG _updateDisplayedOffers: _filteredOffers.length=${_filteredOffers.length}');

    if (_currentPage == 0) {
      // First page - replace all
      _displayedOffers = _filteredOffers.sublist(0, endIndex);

      // Debug: Show first 10 items being set
      debugPrint('DEBUG _updateDisplayedOffers: Setting displayedOffers (first 10):');
      for (int i = 0; i < _displayedOffers.length && i < 10; i++) {
        debugPrint('  Display ${i+1}. ${_displayedOffers[i].productName}: ${_displayedOffers[i].price}€');
      }
    } else {
      // Additional pages - append
      _displayedOffers.addAll(_filteredOffers.sublist(startIndex, endIndex));
    }

    _hasMoreOffers = endIndex < _filteredOffers.length;
  }
  
  Future<void> loadMoreOffers() async {
    if (_isLoadingMore || !_hasMoreOffers) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    // Simulate network delay for realistic feel
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!_disposed) {
      _currentPage++;
      _updateDisplayedOffers();
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  void resetToFirstPage() {
    _currentPage = 0;
    _updateDisplayedOffers();
    notifyListeners();
  }
  
  // Task 9.4.4: Memory Management
  String _estimateCacheMemoryUsage() {
    // Rough estimation: each offer ~500 bytes
    int totalOffers = 0;
    for (final entry in _filterCache.values) {
      totalOffers += entry.offers.length;
    }
    final bytesUsed = totalOffers * 500;
    
    if (bytesUsed < 1024) {
      return '${bytesUsed}B';
    } else if (bytesUsed < 1024 * 1024) {
      return '${(bytesUsed / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytesUsed / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
  
  void onMemoryPressure() {
    // Clear half of cache when memory pressure detected
    final entriesToRemove = _filterCache.length ~/ 2;
    final keysToRemove = <String>[];
    
    // Get oldest entries
    final sortedEntries = _filterCache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
    
    for (int i = 0; i < entriesToRemove && i < sortedEntries.length; i++) {
      keysToRemove.add(sortedEntries[i].key);
    }
    
    for (final key in keysToRemove) {
      _filterCache.remove(key);
    }
    
    debugPrint('OffersProvider: Memory pressure - cleared ${keysToRemove.length} cache entries');
  }
  
  // Task 9.2: Smart Filter Management
  
  /// Clear only active user filters, keep regional filtering
  Future<void> clearActiveFilters() async {
    final hadFilters = hasActiveFilters;

    _selectedCategory = null;
    _selectedRetailer = null;
    _maxPrice = null;
    _showOnlyWithDiscount = false;
    _searchQuery = '';

    if (hadFilters) {
      await _applyFilters();
      debugPrint('OffersProvider: Cleared active filters, keeping regional filtering');
    }
  }
  
  /// Reset specific filter type
  void clearFilter(String filterType) {
    switch (filterType) {
      case 'category':
        clearCategoryFilter();
        break;
      case 'retailer':
        clearRetailerFilter();
        break;
      case 'price':
        clearMaxPrice();
        break;
      case 'discount':
        setShowOnlyWithDiscount(false);
        break;
      case 'search':
        clearSearch();
        break;
      case 'all':
        clearActiveFilters();
        break;
      default:
        debugPrint('Unknown filter type: $filterType');
    }
  }
  
  /// Get recommended filters based on current data
  List<Map<String, dynamic>> getRecommendedFilters() {
    final recommendations = <Map<String, dynamic>>[];
    
    // Recommend discount filter if many offers have discounts
    final discountOffers = _allOffers.where((o) => o.hasDiscount).length;
    if (discountOffers > _allOffers.length * 0.3) {
      recommendations.add({
        'type': 'discount',
        'label': 'Nur Rabatte ($discountOffers Angebote)',
        'reason': 'Viele Angebote mit Rabatt verfügbar',
        'count': discountOffers,
      });
    }
    
    // Recommend price filter based on price distribution
    final priceRanges = getAvailablePriceRanges();
    final averagePrice = priceRanges['average']!;
    final cheapOffers = _allOffers.where((o) => o.price <= averagePrice).length;
    if (cheapOffers > 0) {
      recommendations.add({
        'type': 'price',
        'label': 'Bis ${averagePrice.toStringAsFixed(2)}€ ($cheapOffers Angebote)',
        'reason': 'Günstige Angebote verfügbar',
        'value': averagePrice,
        'count': cheapOffers,
      });
    }
    
    // Recommend category filter for largest category
    final categoryCounts = getCategoryOfferCounts();
    if (categoryCounts.isNotEmpty) {
      final largestCategory = categoryCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      if (largestCategory.value > 5) {
        recommendations.add({
          'type': 'category',
          'label': '${largestCategory.key} (${largestCategory.value} Angebote)',
          'reason': 'Größte Kategorie',
          'value': largestCategory.key,
          'count': largestCategory.value,
        });
      }
    }
    
    return recommendations;
  }
  
  /// Get filter quick actions for UI
  List<Map<String, dynamic>> getFilterQuickActions() {
    return [
      {
        'label': 'Günstigste',
        'icon': 'arrow-up',
        'action': () => setSortType(OfferSortType.priceAsc),
        'active': _sortType == OfferSortType.priceAsc,
      },
      {
        'label': 'Rabatte',
        'icon': 'percent',
        'action': () => setShowOnlyWithDiscount(true),
        'active': _showOnlyWithDiscount,
      },
      {
        'label': 'In der Nähe',
        'icon': 'map-pin',
        'action': () => setSortType(OfferSortType.distanceAsc),
        'active': _sortType == OfferSortType.distanceAsc,
        'enabled': hasUserLocation,
      },
      {
        'label': 'Läuft ab',
        'icon': 'clock',
        'action': () => setSortType(OfferSortType.validityDesc),
        'active': _sortType == OfferSortType.validityDesc,
      },
    ];
  }
  
  // Refresh
  Future<void> refresh() async {
    await loadOffers();
  }
  
  // Specific offer operations
  List<Offer> getOffersByRetailer(String retailer) {
    return _filteredOffers.where((offer) => offer.retailer == retailer).toList();
  }
  
  List<Offer> getValidOffers() {
    return _filteredOffers.where((offer) => offer.isValid).toList();
  }
  
  List<Offer> getDiscountedOffers() {
    return _filteredOffers.where((offer) => offer.hasDiscount).toList();
  }
  
  // Task 9.2: UI-Ready Data Methods for Offers Panel
  
  /// Group offers by retailer for UI sections
  Map<String, List<Offer>> getOffersGroupedByRetailer() {
    final grouped = <String, List<Offer>>{};
    
    for (final offer in _filteredOffers) {
      grouped.putIfAbsent(offer.retailer, () => []).add(offer);
    }
    
    // Sort retailers by number of offers (descending)
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    return Map.fromEntries(sortedEntries);
  }
  
  /// Get featured offers for "Top Deals" showcase
  /// ALL offers with 30%+ discount are considered featured (no limit!)
  List<Offer> getFeaturedOffers({int? limit}) {
    final featured = _filteredOffers.where((offer) =>
        // Feature criteria: 30%+ discount and still valid
        offer.hasDiscount &&
        offer.isValid &&
        (offer.discountPercent ?? 0) >= 30.0
    ).toList();

    // Sort by discount percentage descending
    featured.sort((a, b) =>
        (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0));

    // If limit is provided, use it (for backwards compatibility)
    // Otherwise return ALL featured offers
    if (limit != null) {
      return featured.take(limit).toList();
    }
    return featured;
  }
  
  /// Get nearby offers based on user location
  List<Offer> getNearbyOffers({double limitKm = 5.0, int maxOffers = 10}) {
    if (!hasUserLocation) {
      // Fallback: return offers from Berlin area
      return _filteredOffers
          .where((offer) => offer.storeAddress?.contains('Berlin') == true)
          .take(maxOffers)
          .toList();
    }
    
    final nearbyOffers = _filteredOffers.where((offer) {
      final distance = offer.distanceTo(currentLatitude, currentLongitude);
      return distance <= limitKm;
    }).toList();
    
    // Sort by distance
    nearbyOffers.sort((a, b) => 
        a.distanceTo(currentLatitude, currentLongitude)
            .compareTo(b.distanceTo(currentLatitude, currentLongitude)));
    
    return nearbyOffers.take(maxOffers).toList();
  }
  
  /// Get offers expiring soon for warning sections
  List<Offer> getExpiringOffers({Duration? within}) {
    final threshold = within ?? Duration(hours: 24);
    final cutoff = DateTime.now().add(threshold);
    
    final expiring = _filteredOffers
        .where((offer) => offer.validUntil.isBefore(cutoff) && offer.isValid)
        .toList();
    
    // Sort by validity (soonest first)
    expiring.sort((a, b) => a.validUntil.compareTo(b.validUntil));
    
    return expiring;
  }
  
  /// Get price comparison data for charts/stats
  Map<String, dynamic> getPriceAnalysis() {
    if (_filteredOffers.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'average': 0.0,
        'median': 0.0,
        'savings': 0.0,
        'distribution': <String, int>{},
      };
    }
    
    final prices = _filteredOffers.map((o) => o.price).toList()..sort();
    final savings = _filteredOffers.where((o) => o.hasDiscount).map((o) => o.savings).fold(0.0, (a, b) => a + b);
    
    // Price distribution in ranges
    final distribution = <String, int>{
      '0-2€': 0,
      '2-5€': 0,
      '5-10€': 0,
      '10-20€': 0,
      '20€+': 0,
    };
    
    for (final price in prices) {
      if (price < 2) {
        distribution['0-2€'] = distribution['0-2€']! + 1;
      } else if (price < 5) {
        distribution['2-5€'] = distribution['2-5€']! + 1;
      } else if (price < 10) {
        distribution['5-10€'] = distribution['5-10€']! + 1;
      } else if (price < 20) {
        distribution['10-20€'] = distribution['10-20€']! + 1;
      } else {
        distribution['20€+'] = distribution['20€+']! + 1;
      }
    }
    
    return {
      'min': prices.first,
      'max': prices.last,
      'average': prices.reduce((a, b) => a + b) / prices.length,
      'median': prices[prices.length ~/ 2],
      'savings': savings,
      'distribution': distribution,
      'sampleSize': prices.length,
    };
  }
  
  /// Task 9.3.4: Enhanced search suggestions with categories
  List<SearchSuggestion> getEnhancedSearchSuggestions(String query, {int limit = 8}) {
    return _searchService.getEnhancedSuggestions(_allOffers, query, maxSuggestions: limit);
  }
  
  /// Legacy method for backwards compatibility
  List<String> getSearchSuggestions(String query, {int limit = 5}) {
    final enhanced = getEnhancedSearchSuggestions(query, limit: limit);
    return enhanced.map((s) => s.text).toList();
  }
  
  // Task 9.3: Advanced search using all features
  List<Offer> performAdvancedSearch(String query) {
    return _searchService.advancedSearch(_allOffers, query);
  }
  
  // Task 9.3: Reset search mode flags
  void resetSearchMode() {
    _useFuzzySearch = false;
    _useCategoryAwareSearch = false;
    _fuzzySearchTolerance = 2;
  }
  
  /// Get offer recommendations based on user behavior
  List<Offer> getRecommendedOffers({int limit = 3}) {
    // Simple recommendation: best discounts + nearby + expiring soon
    final recommendations = <Offer>[];
    
    // Add best discounts
    final bestDeals = getFeaturedOffers(limit: 2);
    recommendations.addAll(bestDeals);
    
    // Add nearby offers if location available
    if (hasUserLocation && recommendations.length < limit) {
      final nearby = getNearbyOffers(limitKm: 10.0, maxOffers: 2)
          .where((offer) => !recommendations.contains(offer))
          .toList();
      recommendations.addAll(nearby);
    }
    
    // Fill remaining with recently added or expiring
    if (recommendations.length < limit) {
      final expiring = getExpiringOffers(within: Duration(hours: 48))
          .where((offer) => !recommendations.contains(offer))
          .take(limit - recommendations.length)
          .toList();
      recommendations.addAll(expiring);
    }
    
    return recommendations.take(limit).toList();
  }
  
  // Available categories from current offers
  List<String> get availableCategories {
    return _filteredOffers
        .map((offer) => ProductCategoryMapping.mapToFlashFeedCategory(
            offer.retailer, offer.originalCategory))
        .toSet()
        .toList()
      ..sort();
  }
  
  // Task 9.2: Enhanced UI Filter Methods
  
  /// Get available categories from all offers (before filtering) for dropdown
  List<String> getFilteredCategories({bool includeAll = false}) {
    final categories = _allOffers
        .map((offer) => ProductCategoryMapping.mapToFlashFeedCategory(
            offer.retailer, offer.originalCategory))
        .toSet()
        .toList()
      ..sort();
    
    if (includeAll) {
      categories.insert(0, 'Alle Kategorien');
    }
    
    return categories;
  }
  
  /// Get available retailers from current offers for filter dropdown
  List<String> getFilteredRetailers({bool includeAll = false}) {
    final retailers = List<String>.from(_availableRetailers)
      ..sort();
    
    if (includeAll) {
      retailers.insert(0, 'Alle Händler');
    }
    
    return retailers;
  }
  
  /// Get price range from current offers for slider
  Map<String, double> getAvailablePriceRanges() {
    if (_allOffers.isEmpty) {
      return {'min': 0.0, 'max': 100.0};
    }
    
    final prices = _allOffers.map((offer) => offer.price).toList()
      ..sort();
    
    return {
      'min': prices.first,
      'max': prices.last,
      'average': prices[prices.length ~/ 2], // Median
    };
  }
  
  /// Get offer count per category for UI badges
  Map<String, int> getCategoryOfferCounts() {
    final counts = <String, int>{};
    
    for (final offer in _allOffers) {
      final category = ProductCategoryMapping.mapToFlashFeedCategory(
          offer.retailer, offer.originalCategory);
      counts[category] = (counts[category] ?? 0) + 1;
    }
    
    return counts;
  }
  
  /// Get offer count per retailer for UI badges
  Map<String, int> getRetailerOfferCounts() {
    final counts = <String, int>{};
    
    for (final offer in _allOffers) {
      counts[offer.retailer] = (counts[offer.retailer] ?? 0) + 1;
    }
    
    return counts;
  }
  
  /// Get sort options as map with named keys
  Map<String, dynamic> getSortOptionsMap() {
    return {
      'priceAsc': {
        'label': 'Preis aufsteigend',
        'description': 'Günstigste zuerst',
        'icon': Icons.arrow_upward,
        'value': OfferSortType.priceAsc,
        'active': _sortType == OfferSortType.priceAsc,
      },
      'priceDesc': {
        'label': 'Preis absteigend',
        'description': 'Teuerste zuerst',
        'icon': Icons.arrow_downward,
        'value': OfferSortType.priceDesc,
        'active': _sortType == OfferSortType.priceDesc,
      },
      'discountDesc': {
        'label': 'Höchste Rabatte',
        'description': 'Beste Deals zuerst',
        'icon': Icons.local_offer,
        'value': OfferSortType.discountDesc,
        'active': _sortType == OfferSortType.discountDesc,
      },
      'distanceAsc': {
        'label': 'Entfernung',
        'description': hasUserLocation ? 'Nächste zuerst' : 'Nach Berlin sortiert',
        'icon': Icons.near_me,
        'value': OfferSortType.distanceAsc,
        'active': _sortType == OfferSortType.distanceAsc,
        'hasLocation': hasUserLocation,
        'locationSource': locationSource,
      },
      'validityDesc': {
        'label': 'Läuft bald ab',
        'description': 'Nach Gültigkeit sortiert',
        'icon': Icons.lock_clock_rounded,
        'value': OfferSortType.validityDesc,
        'active': _sortType == OfferSortType.validityDesc,
      },
      'nameAsc': {
        'label': 'Produktname A-Z',
        'description': 'Alphabetisch sortiert',
        'icon': Icons.sort_by_alpha,
        'value': OfferSortType.nameAsc,
        'active': _sortType == OfferSortType.nameAsc,
      },
    };
  }
  
  // Task 5c.4: Regional unavailability fallback methods
  
  // Get offers that are not available in user's region
  List<Offer> get unavailableOffers {
    if (_userPLZ == null || _userPLZ!.isEmpty) return [];
    return _unfilteredOffers.where((offer) => 
      !_availableRetailers.contains(offer.retailer)
    ).toList();
  }
  
  bool get hasUnavailableOffers => unavailableOffers.isNotEmpty;
  
  // Get alternative retailers for an unavailable retailer
  List<String> getAlternativeRetailers(String unavailableRetailer) {
    if (_availableRetailers.isEmpty) return [];
    
    // Return available retailers except the unavailable one
    return _availableRetailers
        .where((retailer) => retailer != unavailableRetailer)
        .take(3) // Limit to 3 alternatives
        .toList();
  }
  
  // Get alternative offers for a specific product
  List<Offer> getAlternativeOffers(Offer unavailableOffer) {
    // Find similar offers from available retailers
    final category = ProductCategoryMapping.mapToFlashFeedCategory(
        unavailableOffer.retailer, unavailableOffer.originalCategory);
    
    return _filteredOffers
        .where((offer) => 
            offer.id != unavailableOffer.id &&
            _availableRetailers.contains(offer.retailer) &&
            ProductCategoryMapping.mapToFlashFeedCategory(
                offer.retailer, offer.originalCategory) == category)
        .take(3) // Limit to 3 alternatives
        .toList();
  }
  
  // Get nearby regions with better availability
  List<String> getNearbyRegions(String plz, int radiusKm) {
    // This would typically call a service to find nearby PLZ ranges
    // For MVP, return hardcoded nearby regions
    if (plz.startsWith('10')) {
      return ['Berlin-Mitte', 'Berlin-Charlottenburg', 'Potsdam'];
    } else if (plz.startsWith('80')) {
      return ['München-Zentrum', 'München-Schwabing', 'Freising'];
    } else {
      return ['Nachbarregion Nord', 'Nachbarregion Süd'];
    }
  }
  
  // Get expanded search results
  Future<List<Offer>> getExpandedSearchResults(int additionalRadiusKm) async {
    // Simulate expanded search by including more offers
    // In production, this would query based on extended radius
    await Future.delayed(const Duration(milliseconds: 500));
    
    // For demo: return all unfiltered offers regardless of region
    return List.from(_unfilteredOffers);
  }
  
  // Enhanced empty state message
  String getEmptyStateMessage() {
    if (_selectedCategory != null && _selectedRetailer != null) {
      return 'Keine Angebote für "$_selectedCategory" bei $_selectedRetailer in Ihrer Region.';
    } else if (_selectedCategory != null) {
      return 'Keine Angebote für "$_selectedCategory" in PLZ $_userPLZ gefunden.';
    } else if (_selectedRetailer != null) {
      return '$_selectedRetailer hat keine Angebote in PLZ $_userPLZ.';
    } else if (_userPLZ != null && _availableRetailers.isEmpty) {
      return 'Keine Händler in PLZ $_userPLZ verfügbar. Bitte erweitern Sie den Suchradius.';
    } else if (_userPLZ != null) {
      return 'Keine Angebote in PLZ $_userPLZ gefunden.';
    } else {
      return 'Keine Angebote verfügbar. Bitte geben Sie Ihre PLZ ein.';
    }
  }
  
  // Filter Methods (for tests and UI)
  Future<void> clearFilters() async {
    _selectedCategory = null;
    _selectedRetailer = null;
    _sortType = OfferSortType.priceAsc;
    _searchQuery = '';
    _maxPrice = null;
    _showOnlyWithDiscount = false;
    await _applyFilters();
  }
  
  // Task 10: Enhanced Filter Methods for UI
  Future<void> filterByCategories(List<String> categories) async {
    // For MVP, we only support single category
    // Could be extended to support multiple categories
    _selectedCategory = categories.isNotEmpty ? categories.first : null;
    await _applyFilters();
  }
  
  Future<void> filterByRetailers(List<String> retailers) async {
    // For MVP, we only support single retailer
    // Could be extended to support multiple retailers
    _selectedRetailer = retailers.isNotEmpty ? retailers.first : null;
    await _applyFilters();
  }
  
  Future<void> filterByPriceRange(double min, double max) async {
    _maxPrice = max;
    // Could add _minPrice if needed
    await _applyFilters();
  }
  
  Future<void> filterByMinDiscount(double minDiscount) async {
    _showOnlyWithDiscount = minDiscount > 0;
    // Could add _minDiscountPercent field for more precision
    await _applyFilters();
  }
  
  Future<void> setRegionalFilter(bool onlyAvailable) async {
    // This is already handled by regional filtering
    // Could add a flag to show/hide unavailable offers
    await _applyFilters();
  }
  
  Future<void> applyFilters({
    String? category,
    String? retailer,
    OfferSortType? sortType,
    String? searchQuery,
    double? maxPrice,
    bool? showOnlyWithDiscount,
  }) async {
    if (category != null) { _selectedCategory = category; }
    if (retailer != null) { _selectedRetailer = retailer; }
    if (sortType != null) { _sortType = sortType; }
    if (searchQuery != null) { _searchQuery = searchQuery; }
    if (maxPrice != null) { _maxPrice = maxPrice; }
    if (showOnlyWithDiscount != null) { _showOnlyWithDiscount = showOnlyWithDiscount; }
    await _applyFilters();
  }
  
  Future<void> setSelectedCategory(String? category) async {
    _selectedCategory = category;
    await _applyFilters();
  }
  
  // Helper Methods
  void _setLoading(bool loading) {
    if (_disposed) return; // Defensive check against disposed provider
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    if (_disposed) return; // Defensive check against disposed provider
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  // Task 5c.4: UI-Logic for Regional Availability
  // (Moved to line 440 to avoid duplication)
  
  List<String> get regionalWarnings {
    final warnings = <String>[];
    
    if (_userPLZ == null || _userPLZ!.isEmpty) {
      warnings.add('Bitte geben Sie Ihre PLZ ein für regionale Angebote');
    } else if (_availableRetailers.isEmpty) {
      warnings.add('Keine Händler in Ihrer Region (PLZ: $_userPLZ) verfügbar');
    } else if (hasUnavailableOffers) {
      final unavailableCount = unavailableOffers.length;
      warnings.add('$unavailableCount Angebote sind in Ihrer Region nicht verfügbar');
    }
    
    return warnings;
  }
  
  List<String> findNearbyRetailers(String plz, {int radiusKm = 50}) {
    // This would normally query nearby PLZ ranges
    // For MVP, return some suggested alternatives
    final suggestions = <String>[];
    
    // If no retailers available, suggest nationwide ones
    if (_availableRetailers.isEmpty) {
      suggestions.addAll(['EDEKA', 'REWE', 'ALDI', 'Lidl']);
    } else if (_availableRetailers.length < 5) {
      // Suggest additional nationwide retailers
      final nationwide = ['EDEKA', 'REWE', 'ALDI', 'Lidl', 'Penny', 'Kaufland'];
      for (final retailer in nationwide) {
        if (!_availableRetailers.contains(retailer)) {
          suggestions.add(retailer);
        }
      }
    }
    
    return suggestions.take(3).toList(); // Max 3 suggestions
  }
  
  // Freemium Logic
  bool isOfferLocked(int index) {
    // No offers should be locked for selected retailers
    // User can see ALL offers from their selected retailers
    return false;
  }
  
  // Convert sort options map to list for UI
  List<Map<String, dynamic>> getSortOptions() {
    final optionsMap = getSortOptionsMap();
    final List<Map<String, dynamic>> optionsList = [];
    
    // Convert map entries to list, rename 'active' to 'status'
    optionsMap.forEach((key, value) {
      final mapEntry = value as Map<String, dynamic>;
      optionsList.add({
        'label': mapEntry['label'],
        'icon': mapEntry['icon'],  // Already IconData!
        'value': mapEntry['value'], // Already OfferSortType!
        'status': mapEntry['active'], // Just rename
      });
    });
    
    return optionsList;
  }
  

  
  @override
  void dispose() {
    // Prevent double disposal
    if (_disposed) return;

    // Task 9.4.3: Cancel debounce timer
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = null;

    // Unregister from UserProvider
    unregisterFromUserProvider();

    // Task 9.4.1: Clear cache
    _filterCache.clear();

    // CRITICAL FIX: Unregister callback BEFORE marking as disposed
    if (_registeredService != null) {
      _registeredService!.clearOffersCallback();
      _registeredService = null;
    }

    // CRITICAL: Auto-unregister location callbacks to prevent memory leaks
    if (_locationProvider != null) {
      try {
        _locationProvider!.unregisterLocationChangeCallback(_onLocationChanged);
        _locationProvider!.unregisterRegionalDataCallback(_onRegionalDataChanged);
        debugPrint('✅ OffersProvider: Auto-unregistered callbacks during disposal');
      } catch (e) {
        debugPrint('⚠️ OffersProvider: Error during callback cleanup: $e');
      }
      _locationProvider = null;
    }

    _disposed = true; // Mark provider as disposed
    // Clean up resources
    super.dispose();
  }
}
