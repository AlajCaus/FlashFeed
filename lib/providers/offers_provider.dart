// FlashFeed Offers Provider - Angebote & Preisvergleich
// Mit regionaler Filterung (Integration für Task 5c vorbereitet)

import 'package:flutter/material.dart';
import '../repositories/offers_repository.dart';
import '../repositories/mock_offers_repository.dart';
import '../data/product_category_mapping.dart';
import '../models/models.dart';

class OffersProvider extends ChangeNotifier {
  final OffersRepository _offersRepository;
  
  // State
  List<Offer> _allOffers = [];
  List<Offer> _filteredOffers = [];
  bool _isLoading = false;
  String? _errorMessage;
  
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
  
  OffersProvider(this._offersRepository);
  
  // Factory constructor with mock repository
  OffersProvider.mock() : _offersRepository = MockOffersRepository();
  
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
  
  // Statistics
  int get totalOffersCount => _allOffers.length;
  int get filteredOffersCount => _filteredOffers.length;
  double get averagePrice => _filteredOffers.isEmpty ? 0.0 : 
      _filteredOffers.map((o) => o.price).reduce((a, b) => a + b) / _filteredOffers.length;
  double get totalSavings => _filteredOffers
      .where((o) => o.hasDiscount)
      .map((o) => o.savings)
      .fold(0.0, (sum, savings) => sum + savings);
  
  // Load Offers
  Future<void> loadOffers() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      _allOffers = await _offersRepository.getAllOffers();
      
      // Extract available retailers from loaded offers
      _availableRetailers = _allOffers
          .map((offer) => offer.retailer)
          .toSet()
          .toList();
      
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
      _allOffers = await _offersRepository.getAllOffers();
      
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
  
  // Apply All Filters
  void _applyFilters() {
    List<Offer> filtered = List.from(_allOffers);
    
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
          offer.storeAddress.toLowerCase().contains(query)
      ).toList();
    }
    
    _filteredOffers = filtered;
    notifyListeners();
    
    // Apply sorting (async)
    if (filtered.isNotEmpty) {
      _applySorting();
    }
  }
  
  Future<void> _applySorting() async {
    try {
      _filteredOffers = await _offersRepository.getSortedOffers(_filteredOffers, _sortType);
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
  
  // Helper Methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
