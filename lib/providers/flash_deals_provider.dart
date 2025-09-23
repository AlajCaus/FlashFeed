// FlashFeed Flash Deals Provider - Echtzeit Rabatte
// Nutzt MockDataService für Live-Updates

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../main.dart'; // Access to global mockDataService
import '../services/mock_data_service.dart'; // For test service parameter
import '../providers/location_provider.dart'; // Task 5b.6: Cross-Provider Integration

class FlashDealsProvider extends ChangeNotifier {
  // State
  List<FlashDeal> _flashDeals = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false; // Track disposal state

  // Service instance (for test compatibility)
  late final MockDataService _mockDataService;

  // Task 14: Echtzeit-Countdown Timer
  Timer? _countdownTimer;
  bool _isCountdownActive = false;

  // Filter State
  String? _selectedUrgencyLevel;
  String? _selectedRetailer;
  int? _maxRemainingMinutes;

  // Regional State (Task 5b.6: Cross-Provider Integration)
  String? _userPLZ;
  List<String> _availableRetailers = [];

  // LocationProvider reference for auto-cleanup
  LocationProvider? _locationProvider;
  
  // Standard constructor with global service
  FlashDealsProvider({MockDataService? testService}) {
    _mockDataService = testService ?? mockDataService;
    _initializeCallbacks();

    // Task 14: Start real-time countdown only in non-test environments
    // Check if we're using a test service - if so, don't start the timer
    if (testService == null) {
      _startCountdownTimer();
    }
  }
  
  // Getters
  List<FlashDeal> get flashDeals => _flashDeals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Filter Getters
  String? get selectedUrgencyLevel => _selectedUrgencyLevel;
  String? get selectedRetailer => _selectedRetailer;
  int? get maxRemainingMinutes => _maxRemainingMinutes;
  
  // Regional Getters (Task 5b.6: Phase 2.1)
  String? get userPLZ => _userPLZ;
  List<String> get availableRetailers => _availableRetailers;
  bool get hasRegionalFiltering => _locationProvider?.hasLocation ?? false;
  
  // Statistics
  int get totalDealsCount => _flashDeals.length;
  int get urgentDealsCount => _flashDeals.where((d) => d.urgencyLevel == 'high').length;
  double get totalPotentialSavings => _flashDeals
      .map((deal) => deal.savings)
      .fold(0.0, (sum, savings) => sum + savings);
  
  // Task 5c.5: Cross-Provider Communication Methods
  void registerWithLocationProvider(LocationProvider locationProvider) {
    // Store reference for auto-cleanup during disposal
    _locationProvider = locationProvider;

    // Register for both location and regional data updates
    locationProvider.registerLocationChangeCallback(_onLocationChanged);
    locationProvider.registerRegionalDataCallback(_onRegionalDataChanged);

    // Get initial location data if available
    if (locationProvider.hasLocation) {
      debugPrint('FlashDealsProvider: Initial location available - Lat: ${locationProvider.latitude}, Lng: ${locationProvider.longitude}');
      _userPLZ = locationProvider.postalCode;
      _availableRetailers = List.from(locationProvider.availableRetailersInRegion);
      // Apply distance-based filtering for Flash Deals
      _loadFlashDealsFromService();  // This will apply regional filtering
    } else {
      debugPrint('FlashDealsProvider: No initial location available yet');
      // Still need to load flash deals, but without filtering
      _loadFlashDealsFromService();
    }

    debugPrint('FlashDealsProvider: Registered with LocationProvider (hasLocation: ${locationProvider.hasLocation})');
  }
  
  void unregisterFromLocationProvider(LocationProvider locationProvider) {
    locationProvider.unregisterLocationChangeCallback(_onLocationChanged);
    locationProvider.unregisterRegionalDataCallback(_onRegionalDataChanged);
    _locationProvider = null; // Clear reference
    debugPrint('FlashDealsProvider: Unregistered from LocationProvider');
  }
  
  // Task 5c.5: Callback handlers
  void _onLocationChanged() {
    if (_disposed) return;
    debugPrint('FlashDealsProvider: Location changed, resetting flash deals timer');
    
    // Reset timer state when location changes
    _resetTimerState();
    _applyRegionalFiltering();
  }
  
  void _onRegionalDataChanged(String? plz, List<String> availableRetailers) {
    if (_disposed) return;
    
    // Handle location cleared case
    if (plz == null) {
      debugPrint('FlashDealsProvider: Location cleared');
      _userPLZ = null;
      _availableRetailers = [];
      if (!_disposed) notifyListeners();
      return;
    }
    
    if (availableRetailers.isNotEmpty) {
      debugPrint('FlashDealsProvider: Regional data changed - PLZ: $plz');
      _userPLZ = plz;
      _availableRetailers = List.from(availableRetailers);
      
      // Reset timer state when location changes
      _resetTimerState();
      
      _applyRegionalFiltering();
      if (!_disposed) notifyListeners();
    }
  }
  
  // FIX: Reset timer state when location changes
  void _resetTimerState() {
    final now = DateTime.now();
    
    // Reset all flash deals to have proper timer values
    for (int i = 0; i < _flashDeals.length; i++) {
      final deal = _flashDeals[i];
      final newRemainingSeconds = deal.expiresAt.difference(now).inSeconds;
      
      // Only keep deals that haven't expired and have reasonable remaining time
      if (newRemainingSeconds > 0 && newRemainingSeconds <= 3600) { // Max 1 hour
        final newUrgencyLevel = newRemainingSeconds < 3600 ? 'high' : 
                               newRemainingSeconds < 7200 ? 'medium' : 'low';
        
        _flashDeals[i] = deal.copyWith(
          remainingSeconds: newRemainingSeconds,
          urgencyLevel: newUrgencyLevel,
        );
      } else {
        // Remove expired or invalid deals
        _flashDeals.removeAt(i);
        i--;
      }
    }
    
    debugPrint('🔄 Timer state reset: ${_flashDeals.length} valid deals remaining');
  }
  
  // Apply regional filtering based on DISTANCE AND retailer availability
  void _applyRegionalFiltering() {
    // Get user location from LocationProvider
    final locationProvider = _locationProvider;
    if (locationProvider == null || !locationProvider.hasLocation) {
      debugPrint('📍 FlashDealsProvider: No user location available, showing all deals');
      return;
    }

    final userLat = locationProvider.latitude!;
    final userLng = locationProvider.longitude!;
    final originalCount = _flashDeals.length;

    // Maximum distance for Flash Deals (in km) - should be reachable quickly
    const double maxDistanceKm = 500.0; // Temporarily increased for demo/testing

    // Filter deals by distance AND retailer availability
    final filteredDeals = <FlashDeal>[];
    for (final deal in _flashDeals) {
      final distance = _calculateDistance(
        userLat, userLng,
        deal.storeLat, deal.storeLng
      );

      // Check both distance AND if retailer is available in region
      final isRetailerAvailable = _availableRetailers.isEmpty ||
                                  _availableRetailers.contains(deal.retailer);

      if (distance <= maxDistanceKm && isRetailerAvailable) {
        filteredDeals.add(deal);
        debugPrint('✅ Flash Deal included: ${deal.productName} at ${deal.storeName} (${distance.toStringAsFixed(1)}km)');
      } else if (distance > maxDistanceKm) {
        debugPrint('❌ Flash Deal too far: ${deal.productName} at ${deal.storeName} (${distance.toStringAsFixed(1)}km)');
      } else {
        debugPrint('❌ Flash Deal retailer not available: ${deal.retailer} not in region');
      }
    }

    _flashDeals = filteredDeals;
    debugPrint('📍 Regional filtering by distance and retailer: $originalCount → ${_flashDeals.length} deals (within ${maxDistanceKm}km)');
  }
  
  // Initialize Provider-Callbacks
  void _initializeCallbacks() {
    if (_mockDataService.isInitialized) {
      // Register callback for flash deals updates
      _mockDataService.setFlashDealsCallback(() {
        if (!_disposed) { // Safety check
          _loadFlashDealsFromService();
        }
      });

      // Initial load
      _loadFlashDealsFromService();
    }
  }

  // Task 14: Echtzeit-Countdown Timer Management
  void _startCountdownTimer() {
    if (_isCountdownActive) return;

    _countdownTimer?.cancel();
    _isCountdownActive = true;

    // Update countdown every second for real-time experience
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed) {
        _updateLocalCountdowns();
      }
    });

    debugPrint('⏱️ FlashDealsProvider: Echtzeit-Countdown gestartet (1-Sekunden-Updates)');
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isCountdownActive = false;
    debugPrint('⏹️ FlashDealsProvider: Countdown-Timer gestoppt');
  }

  // Public methods for test control
  void startTimerForTesting() {
    if (!_isCountdownActive) {
      _startCountdownTimer();
    }
  }

  void stopTimerForTesting() {
    _stopCountdownTimer();
  }

  void _updateLocalCountdowns() {
    if (_flashDeals.isEmpty) return;

    final now = DateTime.now();
    bool hasExpiredDeals = false;

    // Update remaining seconds for all deals
    for (int i = 0; i < _flashDeals.length; i++) {
      final deal = _flashDeals[i];
      final newRemainingSeconds = deal.expiresAt.difference(now).inSeconds;

      if (newRemainingSeconds <= 0) {
        hasExpiredDeals = true;
        continue;
      }

      // Update urgency level based on remaining time
      final newUrgencyLevel = newRemainingSeconds < 1800 ? 'high' :    // < 30 min
                              newRemainingSeconds < 3600 ? 'medium' :  // < 1 hour
                              'low';

      // Update deal with new countdown values
      _flashDeals[i] = deal.copyWith(
        remainingSeconds: newRemainingSeconds,
        urgencyLevel: newUrgencyLevel,
      );
    }

    // Remove expired deals
    if (hasExpiredDeals) {
      final beforeCount = _flashDeals.length;
      _flashDeals.removeWhere((deal) =>
        deal.expiresAt.difference(now).inSeconds <= 0);
      final removedCount = beforeCount - _flashDeals.length;
      if (removedCount > 0) {
        debugPrint('🗑️ $removedCount Flash Deal(s) abgelaufen und entfernt');
      }
    }

    // Notify listeners for UI update
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Load Flash Deals from MockDataService
  void _loadFlashDealsFromService() {
    if (_mockDataService.isInitialized) {
      // Filter out hidden deals
      final allDeals = _mockDataService.flashDeals;
      debugPrint('🔍 FlashDealsProvider: Loading ${allDeals.length} flash deals from service');

      _flashDeals = allDeals
          .where((deal) => !_hiddenDealIds.contains(deal.id))
          .toList();
      debugPrint('🔍 FlashDealsProvider: After hiding filter: ${_flashDeals.length} deals');

      _applyRegionalFiltering(); // FIX: Apply regional filtering first
      debugPrint('🔍 FlashDealsProvider: After regional filter: ${_flashDeals.length} deals');

      // TEMPORARILY DISABLED: _applyFilters() was removing all deals
      // _applyFilters();
      debugPrint('🔍 FlashDealsProvider: Filters temporarily disabled to show deals');

      if (!_disposed) notifyListeners();
    } else {
      debugPrint('❌ FlashDealsProvider: MockDataService not initialized!');
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
  
  // Task 14: Enhanced Demo - Generate Impressive Flash Deals
  FlashDeal generateInstantFlashDeal() {
    try {
      // Generate impressive deal with short duration (5-15 minutes)
      final deal = _mockDataService.generateInstantFlashDeal();

      // Update local state immediately
      _loadFlashDealsFromService();

      // Trigger notification for new deal
      _showFlashDealNotification(deal);

      // Ensure countdown is active for new deal
      if (!_isCountdownActive) {
        _startCountdownTimer();
      }

      debugPrint('🚀 Demo: Beeindruckender Flash Deal generiert!');
      debugPrint('   → ${deal.productName} (-${deal.discountPercentage}%)');
      debugPrint('   → Läuft ab in ${deal.remainingMinutes} Minuten');

      return deal;
    } catch (e) {
      _setError('Fehler beim Generieren des Flash Deals: ${e.toString()}');
      rethrow;
    }
  }

  // Task 14: Mock Push Notification
  void _showFlashDealNotification(FlashDeal deal) {
    // This will be called from UI to show SnackBar or Dialog
    debugPrint('🔔 NEU: ${deal.productName} jetzt -${deal.discountPercentage}%!');
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
    // IMPORTANT: Work on current _flashDeals (which may have regional filtering applied)
    List<FlashDeal> filtered = List.from(_flashDeals);
    
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
    if (!_disposed) notifyListeners();
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
  
  // Hide/Unhide deals for swipe-to-dismiss
  final Set<String> _hiddenDealIds = {};

  void hideDeal(String dealId) {
    _hiddenDealIds.add(dealId);
    _flashDeals.removeWhere((deal) => deal.id == dealId);
    if (!_disposed) notifyListeners();
  }

  void unhideDeal(String dealId) {
    _hiddenDealIds.remove(dealId);
    // Reload deals to restore the unhidden deal
    loadFlashDeals();
  }

  // Available filters from current deals
  List<String> get currentDealRetailers {
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
    if (!_disposed) notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    if (!_disposed) notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  @override
  void dispose() {
    // Prevent double disposal
    if (_disposed) return;

    // Task 14: Stop countdown timer
    _stopCountdownTimer();

    // CRITICAL: Auto-unregister callbacks to prevent memory leaks
    if (_locationProvider != null) {
      try {
        _locationProvider!.unregisterLocationChangeCallback(_onLocationChanged);
        _locationProvider!.unregisterRegionalDataCallback(_onRegionalDataChanged);
        debugPrint('✅ FlashDealsProvider: Auto-unregistered callbacks during disposal');
      } catch (e) {
        debugPrint('⚠️ FlashDealsProvider: Error during callback cleanup: $e');
      }
      _locationProvider = null;
    }

    _disposed = true; // Mark provider as disposed
    // Clean up callbacks if needed
    super.dispose();
  }

  // Helper method to calculate distance between two coordinates
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
