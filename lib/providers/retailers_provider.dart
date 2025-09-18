// FlashFeed Retailers Provider
// Verwaltet Händler-Verfügbarkeit basierend auf User-PLZ
// 
// ARCHITEKTUR: Provider Pattern (nicht BLoC)
// INTEGRATION: LocationProvider Callbacks für PLZ-Updates
// DATENQUELLE: MockDataService (global von main.dart)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../repositories/retailers_repository.dart';
import '../repositories/mock_retailers_repository.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';
import 'location_provider.dart';

/// Enum für Store-Search Sortierung
enum StoreSearchSort {
  distance,  // Nach Entfernung (Standard)
  relevance, // Nach Such-Relevanz
  name,      // Alphabetisch
  openStatus,// Öffnungszeiten (offen zuerst)
}

/// Cache Entry für Store-Suche
class StoreSearchCacheEntry {
  final List<Store> results;
  final DateTime timestamp;
  
  StoreSearchCacheEntry(this.results, this.timestamp);
}

class RetailersProvider extends ChangeNotifier {
  // Repository & Service Dependencies
  final RetailersRepository _repository;
  
  // Disposal tracking
  bool _disposed = false;
  
  // State Management
  List<Retailer> _allRetailers = [];
  List<Retailer> _availableRetailers = [];
  List<Retailer> _unavailableRetailers = [];
  String _currentPLZ = '';
  bool _isLoading = false;
  String? _errorMessage;
  
  // Performance Cache
  final Map<String, List<Retailer>> _plzRetailerCache = {};
  final Map<String, Retailer> _retailerDetailsCache = {}; // Task 11.1: Cache für Details
  final Map<String, StoreSearchCacheEntry> _storeSearchCache = {}; // Task 11.4: Store-Search Cache
  
  // Task 11.4: Store-Search State
  List<Store> _allStores = [];
  List<Store> _searchResults = [];
  bool _isSearching = false;
  String _lastSearchQuery = '';
  
  // User Location for distance calculations
  double? _userLat;
  double? _userLng;
  LocationProvider? _locationProvider;
  
  // Cross-Provider Callbacks
  Function(List<Retailer>)? _onRetailersChanged;
  
  // Constructor
  RetailersProvider({
    required RetailersRepository repository,
    required MockDataService mockDataService,
  }) : _repository = repository {
    // Initial load on creation
    loadRetailers();
  }
  
  // Factory für Mock-Daten (nicht mehr verwendet, da main.dart direkt den Konstruktor nutzt)
  // Behalten für Backwards-Compatibility, falls benötigt
  factory RetailersProvider.mock({MockDataService? testService, RetailersRepository? repository}) {
    final service = testService ?? MockDataService();
    final repo = repository ?? MockRetailersRepository(testService: service);
    return RetailersProvider(
      repository: repo,
      mockDataService: service,  // Required by constructor, but not stored
    );
  }
  
  // Getters
  List<Retailer> get allRetailers => List.unmodifiable(_allRetailers);
  List<Store> get allStores => List.unmodifiable(_allStores);
  List<Store> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  String get lastSearchQuery => _lastSearchQuery;
  List<Retailer> get availableRetailers => List.unmodifiable(_availableRetailers);
  List<Retailer> get unavailableRetailers => List.unmodifiable(_unavailableRetailers);
  String? get currentPLZ => _currentPLZ;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  
  // Statistics
  int get totalRetailerCount => _allRetailers.length;
  int get availableRetailerCount => _availableRetailers.length;
  int get unavailableRetailerCount => _unavailableRetailers.length;
  double get availabilityPercentage {
    if (_allRetailers.isEmpty) return 0.0;
    return (_availableRetailers.length / _allRetailers.length) * 100;
  }
  
  /// Lädt alle Händler initial
  Future<void> loadRetailers() async {
    if (_disposed) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Lade Händler vom Repository
      _allRetailers = await _repository.getAllRetailers();
      
      // Wenn PLZ bereits gesetzt, filtere direkt
      if (_currentPLZ.isNotEmpty) {
        _updateAvailableRetailers(_currentPLZ);
      } else {
        // Ohne PLZ sind alle Händler "verfügbar" (bundesweite)
        _availableRetailers = _allRetailers
            .where((r) => r.isNationwide)
            .toList();
        _unavailableRetailers = _allRetailers
            .where((r) => !r.isNationwide)
            .toList();
      }
      
      debugPrint('✅ RetailersProvider: ${_allRetailers.length} Händler geladen');
      
    } catch (e) {
      _errorMessage = 'Fehler beim Laden der Händler: $e';
      debugPrint('❌ RetailersProvider Error: $e');
    } finally {
      _isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }
  
  /// Gibt verfügbare Händler für eine PLZ zurück
  List<Retailer> getAvailableRetailers(String plz) {
    // Validierung
    if (!PLZHelper.isValidPLZ(plz)) {
      debugPrint('⚠️ RetailersProvider: Ungültige PLZ: $plz');
      return [];
    }
    
    // Cache-Check für Performance
    if (_plzRetailerCache.containsKey(plz)) {
      return _plzRetailerCache[plz]!;
    }
    
    // Filterung nach PLZ-Verfügbarkeit
    final available = _allRetailers
        .where((retailer) => retailer.isAvailableInPLZ(plz))
        .toList();
    
    // Cache-Update
    _plzRetailerCache[plz] = available;
    
    return available;
  }
  
  /// Gibt nicht-verfügbare Händler für eine PLZ zurück
  List<Retailer> getUnavailableRetailers(String plz) {
    if (!PLZHelper.isValidPLZ(plz)) {
      return [];
    }
    
    return _allRetailers
        .where((retailer) => !retailer.isAvailableInPLZ(plz))
        .toList();
  }
  
  /// Aktualisiert User-Standort und filtert Händler
  void updateUserLocation(String plz) {
    if (_disposed) return;
    if (_currentPLZ == plz) return; // Keine Änderung
    
    debugPrint('📍 RetailersProvider: PLZ-Update von $_currentPLZ zu $plz');
    
    _currentPLZ = plz;
    _updateAvailableRetailers(plz);
    
    // Cache für alte PLZ kann behalten werden (Performance)
    
    // Benachrichtige andere Provider
    _notifyRetailerUpdate();
  }
  
  /// Interne Methode zur Aktualisierung der Verfügbarkeitslisten
  void _updateAvailableRetailers(String plz) {
    if (PLZHelper.isValidPLZ(plz)) {
      _availableRetailers = getAvailableRetailers(plz);
      _unavailableRetailers = getUnavailableRetailers(plz);
    } else {
      // Fallback: Nur bundesweite Händler
      _availableRetailers = _allRetailers
          .where((r) => r.isNationwide)
          .toList();
      _unavailableRetailers = _allRetailers
          .where((r) => !r.isNationwide)
          .toList();
    }
    
    debugPrint('✅ Verfügbare Händler in PLZ $plz: ${_availableRetailers.length}/${_allRetailers.length}');
  }
  
  /// Gibt Verfügbarkeitsnachricht für UI zurück
  String getAvailabilityMessage(String retailerName) {
    final retailer = _allRetailers.firstWhere(
      (r) => r.name == retailerName,
      orElse: () => Retailer(
        id: 'unknown',
        name: retailerName,
        displayName: retailerName,
        logoUrl: '',
        primaryColor: '#000000',
        description: '',
        categories: [],
        website: '',
        storeCount: 0,
      ),
    );
    
    if (retailer.id == 'unknown') {
      return '$retailerName ist nicht in unserem System';
    }
    
    if (retailer.isNationwide) {
      return '$retailerName ist bundesweit verfügbar ✅';
    }
    
    if (_currentPLZ.isEmpty) {
      return 'Bitte PLZ eingeben für Verfügbarkeitsprüfung';
    }
    
    if (retailer.isAvailableInPLZ(_currentPLZ)) {
      return '$retailerName ist in PLZ $_currentPLZ verfügbar ✅';
    }
    
    final regions = retailer.availableRegions.join(', ');
    return '$retailerName ist nicht in PLZ $_currentPLZ verfügbar ❌\n'
           'Verfügbar in: $regions';
  }
  
  /// Findet Händler in der Nähe (für Alternative-Vorschläge)
  List<Retailer> findNearbyRetailers(String plz, int radiusKm) {
    // Vereinfachte Implementation für MVP
    // TODO: Echte Umkreissuche mit PLZ-Datenbank
    
    if (!PLZHelper.isValidPLZ(plz)) {
      return [];
    }
    
    // Für MVP: Gib alle bundesweiten Händler zurück
    return _allRetailers
        .where((r) => r.isNationwide)
        .toList();
  }
  
  /// Task 5c.5: Cross-Provider Integration Methods
  void registerWithLocationProvider(LocationProvider locationProvider) {
    // Register for location and regional data updates
    locationProvider.registerLocationChangeCallback(_onLocationChanged);
    locationProvider.registerRegionalDataCallback(_onRegionalDataChanged);
    
    // Get initial regional data if available
    if (locationProvider.hasPostalCode) {
      updateUserLocation(locationProvider.postalCode!);
    }
    
    debugPrint('RetailersProvider: Registered with LocationProvider');
  }
  
  void unregisterFromLocationProvider(LocationProvider locationProvider) {
    locationProvider.unregisterLocationChangeCallback(_onLocationChanged);
    locationProvider.unregisterRegionalDataCallback(_onRegionalDataChanged);
    debugPrint('RetailersProvider: Unregistered from LocationProvider');
  }
  
  // Task 5c.5: Callback handlers
  void _onLocationChanged() {
    if (_disposed) return;
    debugPrint('RetailersProvider: Location changed, updating retailer availability');
  }
  
  void _onRegionalDataChanged(String? plz, List<String> retailerNames) {
    if (_disposed) return;
    debugPrint('📍 RetailersProvider: Regional data changed - PLZ: $plz');
    
    if (plz != null) {
      updateUserLocation(plz);
    } else {
      // PLZ is null/invalid - clear all retailers for edge case handling
      _currentPLZ = ''; // Reset to empty string (cannot be null due to type)
      _availableRetailers = []; // Empty for invalid PLZ edge case
      _unavailableRetailers = _allRetailers; // All retailers become unavailable
      
      debugPrint('✅ RetailersProvider: PLZ invalid/null, clearing all available retailers');
      _notifyRetailerUpdate();
    }
  }
  
  // Task 5c.5: Additional convenience methods for tests
  List<String> getAvailableRetailersForPLZ(String plz) {
    return getAvailableRetailers(plz).map((r) => r.name).toList();
  }
  
  bool isRetailerAvailable(String retailerName) {
    return _availableRetailers.any((r) => r.name == retailerName);
  }
  
  /// Registriert Callback für Cross-Provider Communication
  void setRetailerUpdateCallback(Function(List<Retailer>) callback) {
    _onRetailersChanged = callback;
  }
  
  /// Benachrichtigt andere Provider über Änderungen
  void _notifyRetailerUpdate() {
    if (!_disposed) {
      notifyListeners();
      _onRetailersChanged?.call(_availableRetailers);
    }
  }
  
  // ============ TASK 11.1: Neue Retailer Detail Methoden ============
  
  /// Gibt detaillierte Informationen zu einem Händler zurück
  Retailer? getRetailerDetails(String retailerName) {
    // Check Cache zuerst
    if (_retailerDetailsCache.containsKey(retailerName)) {
      return _retailerDetailsCache[retailerName];
    }
    
    // Suche in allen Händlern
    try {
      final retailer = _allRetailers.firstWhere(
        (r) => r.name == retailerName || r.displayName == retailerName,
      );
      
      // Cache für zukünftige Zugriffe
      _retailerDetailsCache[retailerName] = retailer;
      return retailer;
    } catch (e) {
      debugPrint('⚠️ RetailersProvider: Händler "$retailerName" nicht gefunden');
      return null;
    }
  }
  
  /// Gibt die Logo-URL eines Händlers zurück (mit Fallback)
  String getRetailerLogo(String retailerName) {
    final retailer = getRetailerDetails(retailerName);
    if (retailer != null && retailer.logoUrl != null && retailer.logoUrl!.isNotEmpty) {
      return retailer.logoUrl!;
    }
    
    // Fallback zu generischem Logo basierend auf Händlernamen
    return '/assets/logos/generic_retailer.png';
  }
  
  /// Gibt die Brand-Farben eines Händlers zurück
  Map<String, Color> getRetailerBrandColors(String retailerName) {
    final retailer = getRetailerDetails(retailerName);
    
    if (retailer != null) {
      // Parse hex colors to Flutter Colors
      try {
        final primaryColorHex = retailer.primaryColor.replaceAll('#', '');
        final primaryColor = Color(int.parse('0xFF$primaryColorHex'));
        
        // Secondary color could be derived or stored
        final secondaryColor = primaryColor.withValues(alpha: 0.7);
        
        return {
          'primary': primaryColor,
          'secondary': secondaryColor,
          'accent': primaryColor.withValues(alpha: 0.1), // Light background color
        };
      } catch (e) {
        debugPrint('⚠️ RetailersProvider: Fehler beim Parsen der Farben für $retailerName');
      }
    }
    
    // Fallback zu Standard-Farben
    return {
      'primary': const Color(0xFF2E8B57), // SeaGreen
      'secondary': const Color(0xFF228B22), // ForestGreen
      'accent': const Color(0xFFF0FFF0), // Honeydew
    };
  }
  
  /// Findet den Händler zu einer bestimmten Filiale
  Retailer? getRetailerByStore(Store store) {
    // Suche anhand des retailerId in der Store
    if (store.retailerId.isNotEmpty) {
      try {
        return _allRetailers.firstWhere(
          (r) => r.id == store.retailerId,
        );
      } catch (e) {
        debugPrint('⚠️ RetailersProvider: Händler für Store ${store.id} nicht gefunden');
      }
    }
    
    // Fallback: Suche anhand des Namens
    final storeName = store.name.toLowerCase();
    try {
      return _allRetailers.firstWhere(
        (r) => storeName.contains(r.name.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Gibt Icon-URL für kleinere Darstellungen zurück
  String getRetailerIcon(String retailerName) {
    final retailer = getRetailerDetails(retailerName);
    if (retailer != null && retailer.iconUrl != null && retailer.iconUrl!.isNotEmpty) {
      return retailer.iconUrl!;
    }
    
    // Fallback zu Logo oder generischem Icon
    return getRetailerLogo(retailerName);
  }
  
  /// Gibt den Display-Namen eines Händlers zurück (z.B. "ALDI SÜD" statt "ALDI")
  String getRetailerDisplayName(String retailerName) {
    final retailer = getRetailerDetails(retailerName);
    return retailer?.displayName ?? retailerName;
  }
  
  /// Gibt den Slogan eines Händlers zurück falls vorhanden
  String? getRetailerSlogan(String retailerName) {
    final retailer = getRetailerDetails(retailerName);
    return retailer?.slogan;
  }
  
  // ============ Ende TASK 11.1 ============
  
  /// Sucht Händler nach Namen
  Future<Retailer?> getRetailerByName(String name) async {
    try {
      return await _repository.getRetailerByName(name);
    } catch (e) {
      debugPrint('❌ RetailersProvider: Fehler bei Händlersuche: $e');
      return null;
    }
  }
  
  /// Lädt Filialen eines Händlers
  Future<List<Store>> getStoresByRetailer(String retailerName) async {
    try {
      return await _repository.getStoresByRetailer(retailerName);
    } catch (e) {
      debugPrint('❌ RetailersProvider: Fehler beim Laden der Filialen: $e');
      return [];
    }
  }
  
  /// Cache-Management
  void clearCache() {
    _plzRetailerCache.clear();
    _retailerDetailsCache.clear(); // Task 11.1: Details-Cache auch leeren
    _storeSearchCache.clear(); // Task 11.4: Store-Search Cache leeren
    debugPrint('🧹 RetailersProvider: Cache geleert');
  }
  
  /// Reload aller Daten
  Future<void> refresh() async {
    clearCache();
    await loadRetailers();
  }
  
  // Test-Helper (nur für Tests sichtbar)
  @visibleForTesting
  Map<String, List<Retailer>> get testCache => _plzRetailerCache;
  
  @visibleForTesting
  void mockRepository(RetailersRepository mockRepo) {
    // This method allows tests to inject a mock repository
    // Note: This would require making _repository non-final
    // For now, use the factory constructor with a test repository instead
    debugPrint('⚠️ Use RetailersProvider.mock() factory for testing');
  }
  
  @visibleForTesting
  void setTestPLZ(String plz) {
    if (_disposed) return;
    _currentPLZ = plz;
    _updateAvailableRetailers(plz);
    if (!_disposed) {
      notifyListeners();
    }
  }
  
  @visibleForTesting
  void setTestRetailers(List<Retailer> retailers) {
    if (_disposed) return;
    _allRetailers = retailers;
    if (_currentPLZ.isNotEmpty) {
      _updateAvailableRetailers(_currentPLZ);
    }
    if (!_disposed) {
      notifyListeners();
    }
  }
  
  // Task 5c.4: Regional unavailability fallback methods
  
  /// Get suggested alternative retailers for an unavailable one
  List<Retailer> getSuggestedRetailers(String unavailableRetailerName) {
    if (_availableRetailers.isEmpty) return [];
    
    // Find the unavailable retailer to understand its type
    // Note: In production, this would be used to match similar retailers
    // For MVP, we use simple logic
    
    // Suggest similar available retailers
    // For MVP: simple logic based on price range
    final suggestions = _availableRetailers.where((retailer) {
      // Don't suggest the same retailer
      if (retailer.name == unavailableRetailerName) return false;
      
      // Prefer retailers with similar characteristics
      // (In production, this would use more sophisticated matching)
      if (unavailableRetailerName.contains('Bio') && 
          retailer.name.contains('Bio')) {
        return true;
      }
      
      // Default: return any available retailer
      return true;
    }).take(3).toList();
    
    return suggestions;
  }
  
  /// Get expanded search results with additional radius
  Future<List<Retailer>> getExpandedSearchResults(int additionalRadiusKm) async {
    // Simulate expanded search
    await Future.delayed(const Duration(milliseconds: 300));
    
    // For MVP: Return retailers from nearby PLZ ranges
    final expandedPLZ = _getExpandedPLZRanges(_currentPLZ, additionalRadiusKm);
    final expandedRetailers = <Retailer>{};
    
    for (final plz in expandedPLZ) {
      final retailers = getAvailableRetailers(plz); // No await needed - returns List directly
      expandedRetailers.addAll(retailers);
    }
    
    return expandedRetailers.toList();
  }
  
  /// Helper: Get nearby PLZ ranges for expanded search
  List<String> _getExpandedPLZRanges(String basePLZ, int radiusKm) {
    if (basePLZ.isEmpty) return [];
    
    // For MVP: Simple PLZ range expansion
    try {
      final plzNum = int.parse(basePLZ);
      final ranges = <String>[];
      
      // Add nearby PLZ codes (simplified)
      for (int i = 1; i <= radiusKm ~/ 10; i++) {
        final nearbyPLZ = (plzNum + i * 100).toString().padLeft(5, '0');
        if (nearbyPLZ.length == 5) {
          ranges.add(nearbyPLZ);
        }
        
        final nearbyPLZ2 = (plzNum - i * 100).toString().padLeft(5, '0');
        if (nearbyPLZ2.length == 5 && int.parse(nearbyPLZ2) > 0) {
          ranges.add(nearbyPLZ2);
        }
      }
      
      return ranges;
    } catch (e) {
      debugPrint('⚠️ RetailersProvider: PLZ-Expansion fehlgeschlagen: $e');
      return [];
    }
  }
  
  /// Get availability statistics
  Map<String, dynamic> getAvailabilityStatistics() {
    return {
      'totalRetailers': _allRetailers.length,
      'availableInRegion': _availableRetailers.length,
      'unavailableInRegion': _unavailableRetailers.length,
      'percentageAvailable': _allRetailers.isNotEmpty
          ? (_availableRetailers.length / _allRetailers.length * 100).round()
          : 0,
      'currentPLZ': _currentPLZ,
      'regionName': _getRegionName(_currentPLZ),
    };
  }
  
  /// Helper: Get region name from PLZ
  String _getRegionName(String plz) {
    if (plz.isEmpty) return 'Unbekannt';
    
    // Use PLZHelper for region mapping
    try {
      if (plz.startsWith('10') || plz.startsWith('11') || 
          plz.startsWith('12') || plz.startsWith('13')) {
        return 'Berlin/Brandenburg';
      } else if (plz.startsWith('80') || plz.startsWith('81') || 
                 plz.startsWith('82') || plz.startsWith('83')) {
        return 'München/Oberbayern';
      } else if (plz.startsWith('50') || plz.startsWith('51')) {
        return 'Köln/Bonn';
      } else if (plz.startsWith('60')) {
        return 'Frankfurt/Rhein-Main';
      } else if (plz.startsWith('20') || plz.startsWith('21') || 
                 plz.startsWith('22')) {
        return 'Hamburg';
      } else if (plz.startsWith('01')) {
        return 'Dresden/Sachsen';
      } else if (plz.startsWith('04')) {
        return 'Leipzig';
      } else if (plz.startsWith('30')) {
        return 'Hannover/Niedersachsen';
      } else if (plz.startsWith('40')) {
        return 'Düsseldorf/NRW';
      } else if (plz.startsWith('70')) {
        return 'Stuttgart/Baden-Württemberg';
      } else if (plz.startsWith('90')) {
        return 'Nürnberg/Franken';
      } else {
        return 'Deutschland';
      }
    } catch (e) {
      return 'Unbekannt';
    }
  }
  
  // ============ TASK 11.4: Store Search Funktionalität ============
  
  /// Haupt-Suchmethode für Filialen
  Future<List<Store>> searchStores(
    String query, {
    String? plz,
    double? radiusKm,
    List<String>? requiredServices,
    bool openOnly = false,
    StoreSearchSort sortBy = StoreSearchSort.distance,
  }) async {
    if (_disposed) return [];
    
    // Update search state
    _isSearching = true;
    _lastSearchQuery = query;
    notifyListeners();
    
    try {
      // 1. Cache-Check
      final cacheKey = _generateSearchCacheKey(
        query, plz, radiusKm, requiredServices, openOnly
      );
      
      if (_storeSearchCache.containsKey(cacheKey)) {
        final cached = _storeSearchCache[cacheKey]!;
        if (DateTime.now().difference(cached.timestamp).inMinutes < 5) {
          _searchResults = cached.results;
          _isSearching = false;
          notifyListeners();
          return cached.results;
        }
      }
      
      // 2. Load all stores if not loaded
      if (_allStores.isEmpty) {
        await _loadAllStores();
      }
      
      // 3. Text-Search with fuzzy matching
      List<Store> filtered = query.isEmpty 
          ? List.from(_allStores)
          : _performTextSearch(_allStores, query);
      
      // 4. Apply Filters
      if (plz != null && plz.isNotEmpty) {
        filtered = _filterByPLZ(filtered, plz);
      }
      
      if (radiusKm != null && radiusKm > 0) {
        filtered = await _filterByRadius(filtered, radiusKm);
      }
      
      if (requiredServices?.isNotEmpty ?? false) {
        filtered = _filterByServices(filtered, requiredServices!);
      }
      
      if (openOnly) {
        filtered = _filterOpenStores(filtered);
      }
      
      // 5. Sort Results
      filtered = await _sortStores(filtered, sortBy);
      
      // 6. Cache & Update State
      _storeSearchCache[cacheKey] = StoreSearchCacheEntry(
        filtered, 
        DateTime.now()
      );
      
      _searchResults = filtered;
      _isSearching = false;
      notifyListeners();
      
      return filtered;
      
    } catch (e) {
      debugPrint('❌ Store search failed: $e');
      _isSearching = false;
      _errorMessage = 'Fehler bei der Filial-Suche: $e';
      notifyListeners();
      return [];
    }
  }
  
  /// Lädt alle Stores von allen Händlern
  Future<void> _loadAllStores() async {
    try {
      // Task 11.4: Verwende neue getAllStores() Repository-Methode
      // Dies lädt effizient alle 35+ Berlin-Stores aus MockDataService
      _allStores = await _repository.getAllStores();
      debugPrint('✅ Loaded ${_allStores.length} stores total');
    } catch (e) {
      debugPrint('❌ Failed to load all stores: $e');
      // Fallback: Lade Stores per Händler
      final stores = <Store>[];
      for (final retailer in _allRetailers) {
        try {
          final retailerStores = await _repository.getStoresByRetailer(retailer.name);
          stores.addAll(retailerStores);
        } catch (e) {
          debugPrint('⚠️ Failed to load stores for ${retailer.name}: $e');
        }
      }
      _allStores = stores;
    }
  }
  
  /// Text-Suche mit Fuzzy-Matching (Levenshtein Distance)
  List<Store> _performTextSearch(List<Store> stores, String query) {
    final queryLower = query.toLowerCase();
    final searchResults = <SearchResult>[];
    
    for (final store in stores) {
      int score = 0;
      
      // Exact match in name
      if (store.name.toLowerCase() == queryLower) {
        score += 100;
      } else if (store.name.toLowerCase().contains(queryLower)) {
        score += 50;
      }
      
      // Match in address
      if (store.address.toLowerCase().contains(queryLower)) {
        score += 30;
      }
      
      // Match in city
      if (store.city.toLowerCase().contains(queryLower)) {
        score += 20;
      }
      
      // Match in PLZ
      if (store.zipCode.contains(query)) {
        score += 40;
      }
      
      // Match in retailer name
      if (store.retailerName.toLowerCase().contains(queryLower)) {
        score += 25;
      }
      
      // Fuzzy match for typos (Levenshtein distance)
      if (score == 0) {
        // Check fuzzy match against store name
        final storeNameDistance = _levenshteinDistance(
          store.name.toLowerCase(), 
          queryLower
        );
        
        // Check fuzzy match against retailer name too
        final retailerDistance = _levenshteinDistance(
          store.retailerName.toLowerCase(),
          queryLower
        );
        
        // Use the better match (lower distance)
        final distance = math.min(storeNameDistance, retailerDistance);
        
        // Allow up to 2 character differences for short queries
        // or up to 30% difference for longer queries
        final maxDistance = query.length <= 5 ? 2 : (query.length * 0.3).round();
        
        if (distance <= maxDistance) {
          score = 10 + (maxDistance - distance) * 5;
        }
      }
      
      // Match in services
      for (final service in store.services) {
        if (service.toLowerCase().contains(queryLower)) {
          score += 15;
          break;
        }
      }
      
      if (score > 0) {
        searchResults.add(SearchResult(store, score));
      }
    }
    
    // Sort by relevance score and return stores
    searchResults.sort((a, b) => b.score.compareTo(a.score));
    return searchResults.map((r) => r.store).toList();
  }
  
  /// Berechnet Levenshtein-Distance für Fuzzy-Search
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,       // deletion
          matrix[i][j - 1] + 1,       // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce(math.min);
      }
    }
    
    return matrix[s1.length][s2.length];
  }
  
  /// Filter nach PLZ
  List<Store> _filterByPLZ(List<Store> stores, String plz) {
    return stores.where((store) => store.zipCode == plz).toList();
  }
  
  /// Filter nach Radius (benötigt User-Location)
  Future<List<Store>> _filterByRadius(List<Store> stores, double radiusKm) async {
    // Get user location from LocationProvider if set
    if (_locationProvider != null && _locationProvider!.hasLocation) {
      _userLat = _locationProvider!.latitude;
      _userLng = _locationProvider!.longitude;
    }
    
    // Fallback to Berlin center if no user location
    final lat = _userLat ?? 52.520008;
    final lng = _userLng ?? 13.404954;
    
    return stores.where((store) {
      final distance = _calculateDistance(
        lat, lng,
        store.latitude, store.longitude
      );
      return distance <= radiusKm;
    }).toList();
  }
  
  /// Filter nach Services
  List<Store> _filterByServices(List<Store> stores, List<String> requiredServices) {
    return stores.where((store) {
      // Store must have ALL required services
      for (final service in requiredServices) {
        final serviceLower = service.toLowerCase();
        bool hasService = store.services.any(
          (s) => s.toLowerCase().contains(serviceLower)
        );
        
        // Check special boolean fields too
        if (!hasService) {
          if (serviceLower.contains('wifi') && store.hasWifi) {
            hasService = true;
          } else if (serviceLower.contains('apotheke') && store.hasPharmacy) {
            hasService = true;
          } else if (serviceLower.contains('beacon') && store.hasBeacon) {
            hasService = true;
          }
        }
        
        if (!hasService) return false;
      }
      return true;
    }).toList();
  }
  
  /// Filter nur offene Filialen
  List<Store> _filterOpenStores(List<Store> stores) {
    final now = DateTime.now();
    return stores.where((store) => store.isOpenAt(now)).toList();
  }
  
  /// Sortierung der Suchergebnisse
  Future<List<Store>> _sortStores(List<Store> stores, StoreSearchSort sortBy) async {
    final sorted = List<Store>.from(stores);
    
    switch (sortBy) {
      case StoreSearchSort.distance:
        // Get user location
        if (_locationProvider != null && _locationProvider!.hasLocation) {
          _userLat = _locationProvider!.latitude;
          _userLng = _locationProvider!.longitude;
        }
        
        final lat = _userLat ?? 52.520008;
        final lng = _userLng ?? 13.404954;
        
        sorted.sort((a, b) {
          final distA = _calculateDistance(lat, lng, a.latitude, a.longitude);
          final distB = _calculateDistance(lat, lng, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });
        break;
        
      case StoreSearchSort.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
        
      case StoreSearchSort.openStatus:
        final now = DateTime.now();
        sorted.sort((a, b) {
          final aOpen = a.isOpenAt(now);
          final bOpen = b.isOpenAt(now);
          if (aOpen && !bOpen) return -1;
          if (!aOpen && bOpen) return 1;
          return 0;
        });
        break;
        
      case StoreSearchSort.relevance:
        // Already sorted by relevance in _performTextSearch
        break;
    }
    
    return sorted;
  }
  
  /// Berechnet Entfernung zwischen zwei Koordinaten (Haversine)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    
    double dLat = _toRadians(lat2 - lat1);
    double dLng = _toRadians(lng2 - lng1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
               math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
               math.sin(dLng / 2) * math.sin(dLng / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }
  
  /// Generiert Cache-Key für Suche
  String _generateSearchCacheKey(
    String query,
    String? plz,
    double? radius,
    List<String>? services,
    bool openOnly,
  ) {
    final parts = [
      query,
      plz ?? '',
      radius?.toString() ?? '',
      services?.join(',') ?? '',
      openOnly.toString(),
    ];
    return parts.join('|');
  }
  
  /// Integration mit LocationProvider
  void setLocationProvider(LocationProvider provider) {
    _locationProvider = provider;
    
    // Update user coordinates when location changes
    provider.registerLocationChangeCallback(() {
      if (provider.hasLocation) {
        _userLat = provider.latitude;
        _userLng = provider.longitude;
        
        // Clear search cache as distances have changed
        _storeSearchCache.clear();
        
        debugPrint('📍 Store search: User location updated');
      }
    });
  }
  
  /// Quick-Filter Presets
  Future<List<Store>> getOpenStoresNearby({double radiusKm = 5}) async {
    return searchStores(
      '',
      radiusKm: radiusKm,
      openOnly: true,
      sortBy: StoreSearchSort.distance,
    );
  }
  
  Future<List<Store>> getStoresWithService(String service, {double? radiusKm}) async {
    return searchStores(
      '',
      radiusKm: radiusKm,
      requiredServices: [service],
      sortBy: StoreSearchSort.distance,
    );
  }
  
  Future<List<Store>> getNearestStores({int limit = 5}) async {
    final stores = await searchStores(
      '',
      sortBy: StoreSearchSort.distance,
    );
    return stores.take(limit).toList();
  }
  
  // ============ Ende TASK 11.4 ============
  
  @override
  void dispose() {
    _disposed = true;
    clearCache();
    _onRetailersChanged = null;
    _locationProvider = null;
    super.dispose();
  }
}

/// Helper class for search results with score
class SearchResult {
  final Store store;
  final int score;
  
  SearchResult(this.store, this.score);
}
