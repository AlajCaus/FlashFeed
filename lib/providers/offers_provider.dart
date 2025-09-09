// FlashFeed Offers Provider - Angebote & Preisvergleich
// Mit regionaler Filterung (Integration für Task 5c vorbereitet)

import 'package:flutter/material.dart';
import '../repositories/offers_repository.dart';
import '../repositories/mock_offers_repository.dart';
import '../data/product_category_mapping.dart';
import '../models/models.dart';
import '../main.dart'; // Access to global mockDataService
import '../services/mock_data_service.dart'; // For test service parameter
import '../providers/location_provider.dart'; // Task 5b.5: Provider-Callbacks

class OffersProvider extends ChangeNotifier {
  final OffersRepository _offersRepository;
  
  // NEW: Reference to LocationProvider for regional data (Task 5c.2)
  LocationProvider? _locationProvider;
  
  // State
  List<Offer> _allOffers = [];
  List<Offer> _unfilteredOffers = []; // Keep ALL offers before regional filtering
  List<Offer> _filteredOffers = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false; // Track disposal state
  
  // Service reference for proper callback cleanup (FIX)
  MockDataService? _registeredService;
  
  // Filter State
  String? _selectedCategory;
  String? _selectedRetailer;
  OfferSortType _sortType = OfferSortType.priceAsc;
  String _searchQuery = '';
  double? _maxPrice;
  bool _showOnlyWithDiscount = false;
  
  // Regional State (ready for Task 5c)
  String? _userPLZ;
  List<String> _availableRetailers = [];
  
  OffersProvider(this._offersRepository) {
    _initializeCallbacks();
  }
  
  // Factory constructor with mock repository (backwards-compatible)
  OffersProvider.mock({MockDataService? testService}) 
      : _offersRepository = MockOffersRepository(testService: testService) {
    _initializeCallbacks(testService);
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
  
  // Register with LocationProvider for regional updates (Task 5b.5)
  void registerWithLocationProvider(LocationProvider locationProvider) {
    _locationProvider = locationProvider; // NEW: Store reference (Task 5c.2)
    
    locationProvider.registerRegionalDataCallback((plz, availableRetailers) {
      if (plz != null && availableRetailers.isNotEmpty) {
        loadRegionalOffers(plz, availableRetailers);
      }
    });
  }
  
  // Getters
  List<Offer> get offers => _filteredOffers;
  List<Offer> get allOffers => _allOffers;
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
  
  // Load Offers with regional filtering support (Task 5c.2)
  Future<void> loadOffers({bool applyRegionalFilter = true}) async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Load ALL offers from repository
      _unfilteredOffers = await _offersRepository.getAllOffers();
      _allOffers = List.from(_unfilteredOffers); // Copy for filtering
      
      // Apply regional filtering if requested and PLZ is available
      if (applyRegionalFilter && _userPLZ != null && _userPLZ!.isNotEmpty) {
        // Get regionally available retailers
        final regionalRetailers = _locationProvider?.getAvailableRetailersForPLZ(_userPLZ!) ?? [];
        
        // Update available retailers list
        _availableRetailers = regionalRetailers;
        
        // Filter offers to only show regionally available
        _allOffers = _allOffers.where((offer) => 
            regionalRetailers.contains(offer.retailer)
        ).toList();
      } else {
        // Extract all retailers if no regional filtering
        _availableRetailers = _allOffers
            .map((offer) => offer.retailer)
            .toSet()
            .toList();
      }
      
      _applyFilters();
      
    } catch (e) {
      _setError('Fehler beim Laden der Angebote: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Regional Loading (ready for Task 5c integration)
  Future<void> loadRegionalOffers(String plz, List<String> availableRegionalRetailers) async {
    _userPLZ = plz;
    _availableRetailers = availableRegionalRetailers;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Load all offers first
      _unfilteredOffers = await _offersRepository.getAllOffers();
      _allOffers = List.from(_unfilteredOffers); // Keep a copy
      
      // Filter by regionally available retailers
      _allOffers = _allOffers.where((offer) => 
          availableRegionalRetailers.contains(offer.retailer)).toList();
      
      _applyFilters();
      
    } catch (e) {
      _setError('Fehler beim Laden der regionalen Angebote: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
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
      _applyFilters();
    }
  }
  
  void clearCategoryFilter() {
    filterByCategory(null);
  }
  
  // Retailer Filter
  Future<void> filterByRetailer(String? retailer) async {
    if (_selectedRetailer != retailer) {
      _selectedRetailer = retailer;
      _applyFilters();
    }
  }
  
  void clearRetailerFilter() {
    filterByRetailer(null);
  }
  
  // Price Filter
  void setMaxPrice(double? price) {
    if (_maxPrice != price) {
      _maxPrice = price;
      _applyFilters();
    }
  }
  
  void clearMaxPrice() {
    setMaxPrice(null);
  }
  
  // Discount Filter
  void setShowOnlyWithDiscount(bool showOnly) {
    if (_showOnlyWithDiscount != showOnly) {
      _showOnlyWithDiscount = showOnly;
      _applyFilters();
    }
  }
  
  // Search
  void searchOffers(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
    }
  }
  
  void clearSearch() {
    searchOffers('');
  }
  
  // Sorting
  Future<void> setSortType(OfferSortType sortType) async {
    if (_sortType != sortType) {
      _sortType = sortType;
      
      _setLoading(true);
      try {
        _filteredOffers = await _offersRepository.getSortedOffers(_filteredOffers, sortType);
      } catch (e) {
        _setError('Fehler beim Sortieren: ${e.toString()}');
      } finally {
        _setLoading(false);
      }
    }
  }
  
  // Apply All Filters with regional awareness (Task 5c.2)
  void _applyFilters() {
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
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      String query = _searchQuery.toLowerCase();
      filtered = filtered.where((offer) =>
          offer.productName.toLowerCase().contains(query) ||
          offer.retailer.toLowerCase().contains(query) ||
          (offer.storeAddress?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    _filteredOffers = filtered;
    
    // NEW: Track empty results for UI feedback (Task 5c.2)
    if (hasRegionalFiltering && filtered.isEmpty && _allOffers.isNotEmpty) {
      debugPrint('⚠️ Regional filtering active: No offers available in PLZ $_userPLZ');
      debugPrint('Available retailers: $_availableRetailers');
    }
    
    if (_disposed) return; // Defensive check against disposed provider
    notifyListeners();
    
    // Apply sorting (async)
    if (filtered.isNotEmpty) {
      _applySorting();
    }
  }
  
  Future<void> _applySorting() async {
    try {
      _filteredOffers = await _offersRepository.getSortedOffers(_filteredOffers, _sortType);
      if (_disposed) return; // Defensive check against disposed provider
      notifyListeners();
    } catch (e) {
      // Sorting errors are non-critical, just log
      debugPrint('Sorting error: $e');
    }
  }
  
  // Clear All Filters
  void clearAllFilters() {
    _selectedCategory = null;
    _selectedRetailer = null;
    _maxPrice = null;
    _showOnlyWithDiscount = false;
    _searchQuery = '';
    _applyFilters();
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
  
  // Available categories from current offers
  List<String> get availableCategories {
    return _filteredOffers
        .map((offer) => ProductCategoryMapping.mapToFlashFeedCategory(
            offer.retailer, offer.originalCategory))
        .toSet()
        .toList()
      ..sort();
  }
  
  // Task 5c.4: Regional unavailability fallback methods
  
  // Get offers that are not available in user's region
  List<Offer> get unavailableOffers {
    if (_userPLZ == null) return [];
    // Use _unfilteredOffers to find offers from unavailable retailers
    return _unfilteredOffers
        .where((offer) => !_availableRetailers.contains(offer.retailer))
        .toList();
  }
  
  // Check if there are unavailable offers
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
  
  // Filter Methods (for tests)
  void clearFilters() {
    _selectedCategory = null;
    _selectedRetailer = null;
    _sortType = OfferSortType.priceAsc;
    _searchQuery = '';
    _maxPrice = null;
    _showOnlyWithDiscount = false;
    _applyFilters();
  }
  
  void applyFilters({
    String? category,
    String? retailer,
    OfferSortType? sortType,
    String? searchQuery,
    double? maxPrice,
    bool? showOnlyWithDiscount,
  }) {
    if (category != null) _selectedCategory = category;
    if (retailer != null) _selectedRetailer = retailer;
    if (sortType != null) _sortType = sortType;
    if (searchQuery != null) _searchQuery = searchQuery;
    if (maxPrice != null) _maxPrice = maxPrice;
    if (showOnlyWithDiscount != null) _showOnlyWithDiscount = showOnlyWithDiscount;
    _applyFilters();
  }
  
  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
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
  
  @override
  void dispose() {
    // Prevent double disposal
    if (_disposed) return;
    
    // CRITICAL FIX: Unregister callback BEFORE marking as disposed
    if (_registeredService != null) {
      _registeredService!.clearOffersCallback();
      _registeredService = null;
    }
    
    _disposed = true; // Mark provider as disposed
    // Clean up resources
    super.dispose();
  }
}
