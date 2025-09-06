// FlashFeed Flash Deals Provider - Echtzeit Rabatte
// Nutzt MockDataService für Live-Updates

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../main.dart'; // Access to global mockDataService

class FlashDealsProvider extends ChangeNotifier {
  // State
  List<FlashDeal> _flashDeals = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filter State
  String? _selectedUrgencyLevel;
  String? _selectedRetailer;
  int? _maxRemainingMinutes;
  
  FlashDealsProvider() {
    _initializeCallbacks();
  }
  
  // Getters
  List<FlashDeal> get flashDeals => _flashDeals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Filter Getters
  String? get selectedUrgencyLevel => _selectedUrgencyLevel;
  String? get selectedRetailer => _selectedRetailer;
  int? get maxRemainingMinutes => _maxRemainingMinutes;
  
  // Statistics
  int get totalDealsCount => _flashDeals.length;
  int get urgentDealsCount => _flashDeals.where((d) => d.urgencyLevel == 'high').length;
  double get totalPotentialSavings => _flashDeals
      .map((deal) => deal.savings)
      .fold(0.0, (sum, savings) => sum + savings);
  
  // Initialize Provider-Callbacks
  void _initializeCallbacks() {
    if (mockDataService.isInitialized) {
      // Register callback for flash deals updates
      mockDataService.setFlashDealsCallback(() {
        _loadFlashDealsFromService();
      });
      
      // Initial load
      _loadFlashDealsFromService();
    }
  }
  
  // Load Flash Deals from MockDataService
  void _loadFlashDealsFromService() {
    if (mockDataService.isInitialized) {
      _flashDeals = List.from(mockDataService.flashDeals);
      _applyFilters();
      notifyListeners();
    }
  }
  
  // Load Flash Deals
  Future<void> loadFlashDeals() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      _loadFlashDealsFromService();
    } catch (e) {
      _setError('Fehler beim Laden der Flash Deals: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Professor Demo: Generate Instant Flash Deal
  FlashDeal generateInstantFlashDeal() {
    try {
      final deal = mockDataService.generateInstantFlashDeal();
      
      // Update local state immediately
      _loadFlashDealsFromService();
      
      return deal;
    } catch (e) {
      _setError('Fehler beim Generieren des Flash Deals: ${e.toString()}');
      rethrow;
    }
  }
  
  // Filter by Urgency Level
  void filterByUrgencyLevel(String? urgencyLevel) {
    if (_selectedUrgencyLevel != urgencyLevel) {
      _selectedUrgencyLevel = urgencyLevel;
      _applyFilters();
    }
  }
  
  void clearUrgencyFilter() {
    filterByUrgencyLevel(null);
  }
  
  // Filter by Retailer
  void filterByRetailer(String? retailer) {
    if (_selectedRetailer != retailer) {
      _selectedRetailer = retailer;
      _applyFilters();
    }
  }
  
  void clearRetailerFilter() {
    filterByRetailer(null);
  }
  
  // Filter by Remaining Time
  void setMaxRemainingMinutes(int? minutes) {
    if (_maxRemainingMinutes != minutes) {
      _maxRemainingMinutes = minutes;
      _applyFilters();
    }
  }
  
  void clearTimeFilter() {
    setMaxRemainingMinutes(null);
  }
  
  // Apply All Filters
  void _applyFilters() {
    List<FlashDeal> filtered = List.from(mockDataService.flashDeals);
    
    // Urgency filter
    if (_selectedUrgencyLevel != null) {
      filtered = filtered.where((deal) => 
          deal.urgencyLevel == _selectedUrgencyLevel).toList();
    }
    
    // Retailer filter
    if (_selectedRetailer != null) {
      filtered = filtered.where((deal) => 
          deal.retailer == _selectedRetailer).toList();
    }
    
    // Time filter
    if (_maxRemainingMinutes != null) {
      filtered = filtered.where((deal) => 
          deal.remainingMinutes <= _maxRemainingMinutes!).toList();
    }
    
    // Remove expired deals
    filtered = filtered.where((deal) => !deal.isExpired).toList();
    
    // Sort by urgency and remaining time
    filtered.sort((a, b) {
      // First by urgency level
      int urgencyA = a.urgencyLevel == 'high' ? 3 : a.urgencyLevel == 'medium' ? 2 : 1;
      int urgencyB = b.urgencyLevel == 'high' ? 3 : b.urgencyLevel == 'medium' ? 2 : 1;
      
      if (urgencyA != urgencyB) {
        return urgencyB.compareTo(urgencyA); // High urgency first
      }
      
      // Then by remaining time (shortest first)
      return a.remainingSeconds.compareTo(b.remainingSeconds);
    });
    
    _flashDeals = filtered;
    notifyListeners();
  }
  
  // Clear All Filters
  void clearAllFilters() {
    _selectedUrgencyLevel = null;
    _selectedRetailer = null;
    _maxRemainingMinutes = null;
    _applyFilters();
  }
  
  // Refresh
  Future<void> refresh() async {
    await loadFlashDeals();
  }
  
  // Get deals by criteria
  List<FlashDeal> getUrgentDeals() {
    return _flashDeals.where((deal) => deal.urgencyLevel == 'high').toList();
  }
  
  List<FlashDeal> getDealsByRetailer(String retailer) {
    return _flashDeals.where((deal) => deal.retailer == retailer).toList();
  }
  
  List<FlashDeal> getDealsExpiringIn(int minutes) {
    return _flashDeals.where((deal) => 
        deal.remainingMinutes <= minutes && !deal.isExpired).toList();
  }
  
  // Available filters from current deals
  List<String> get availableRetailers {
    return _flashDeals
        .map((deal) => deal.retailer)
        .toSet()
        .toList()
      ..sort();
  }
  
  List<String> get availableUrgencyLevels {
    return _flashDeals
        .map((deal) => deal.urgencyLevel)
        .toSet()
        .toList();
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
    // Clean up callbacks if needed
    super.dispose();
  }
}
