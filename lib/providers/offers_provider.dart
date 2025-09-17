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
  
  // Task 9.1: Dynamic coordinates for distance sorting
  double? _userLatitude;
  double? _userLongitude;
  
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
  
  // Task 5c.5: Cross-Provider Communication Methods
  void registerWithLocationProvider(LocationProvider locationProvider) {
    _locationProvider = locationProvider; // Store reference for Task 5c.2
    
    // Register for both location and regional data updates
    locationProvider.registerLocationChangeCallback(_onLocationChanged);
    locationProvider.registerRegionalDataCallback(_onRegionalDataChanged);
    
    // Get initial regional data if available
    if (locationProvider.hasPostalCode && locationProvider.availableRetailersInRegion.isNotEmpty) {
      _userPLZ = locationProvider.postalCode;
      _availableRetailers = locationProvider.availableRetailersInRegion;
      // Don't load offers here - let the initialization flow handle it
    }
    
    // Task 9.1: Get initial coordinates
    _updateUserCoordinates();
    
    debugPrint('OffersProvider: Registered with LocationProvider');
  }
  
  void unregisterFromLocationProvider(LocationProvider locationProvider) {
    locationProvider.unregisterLocationChangeCallback(_onLocationChanged);
    locationProvider.unregisterRegionalDataCallback(_onRegionalDataChanged);
    _locationProvider = null;
    debugPrint('OffersProvider: Unregistered from LocationProvider');
  }
  
  // Task 5c.5: Callback handlers
  void _onLocationChanged() {
    if (_disposed) return;
    
    // Check if location was cleared (no PLZ)
    if (_locationProvider != null && _locationProvider!.postalCode == null) {
      // Location was cleared - reset our state
      _userPLZ = null;
      _availableRetailers = [];
      // Task 9.1: Clear coordinates too
      _userLatitude = null;
      _userLongitude = null;
      debugPrint('OffersProvider: Location cleared, resetting state');
      notifyListeners();
      return;
    }
    
    // Task 9.1: Update coordinates when location changes
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
  
  // Task 9.1: Update user coordinates from LocationProvider
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
  
  // Task 9.1: Convert PLZ to approximate coordinates for major German cities
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
  
  // Task 9.1: Location Getters for distance sorting
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
  
  // Load Offers with regional filtering support (Task 5c.2)
  Future<void> loadOffers({bool applyRegionalFilter = true}) async {
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
      
      _applyFilters();
      
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
        // Task 9.1: Pass user coordinates for distance sorting
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
      // Task 9.1: Pass user coordinates for distance sorting
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
    // Import UserProvider if needed
    // For now, first 3 offers are free, rest locked
    return index >= 3;
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
