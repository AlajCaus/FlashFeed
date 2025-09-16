// FlashFeed Retailers Provider
// Verwaltet Händler-Verfügbarkeit basierend auf User-PLZ
// 
// ARCHITEKTUR: Provider Pattern (nicht BLoC)
// INTEGRATION: LocationProvider Callbacks für PLZ-Updates
// DATENQUELLE: MockDataService (global von main.dart)

import 'package:flutter/material.dart';
import '../repositories/retailers_repository.dart';
import '../repositories/mock_retailers_repository.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';
import 'location_provider.dart';

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
  
  @override
  void dispose() {
    _disposed = true;
    clearCache();
    _onRetailersChanged = null;
    super.dispose();
  }
}
