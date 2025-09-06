// FlashFeed Location Provider - GPS & Standort
// Erweitert: PLZ-Fallback-Kette mit LocalStorage & Dialog Integration (Task 5b.3)

import 'dart:math';
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/plz_lookup_service.dart';
import '../helpers/plz_helper.dart';

/// Enum für Location-Datenquellen (Task 5b.3)
enum LocationSource {
  none,
  gps,
  userPLZ,
  cachedPLZ,
  manualAddress,
}

class LocationProvider extends ChangeNotifier {
  // Location State
  double? _latitude;
  double? _longitude;
  String? _address;
  String? _city;
  String? _postalCode;
  bool _hasLocationPermission = false;
  bool _isLocationServiceEnabled = false;
  bool _isLoadingLocation = false;
  String? _locationError;
  
  // Settings
  double _searchRadiusKm = 10.0;
  bool _useGPS = true;
  bool _autoUpdateLocation = false;
  
  // Regional Support (ready for Task 5b-5c)
  List<String> _availableRetailersInRegion = [];
  
  // Provider Callbacks (Task 5b.5: Cross-Provider Communication)
  final List<VoidCallback> _locationChangeCallbacks = [];
  final List<Function(String?, List<String>)> _regionalDataCallbacks = [];
  
  // PLZ Fallback State (Task 5b.3)
  String? _userPLZ; // Cached user PLZ from LocalStorage
  bool _hasAskedForLocation = false;
  LocationSource _currentLocationSource = LocationSource.none;
  
  // Services (Lazy Loading)
  LocalStorageService? _storageService;
  PLZLookupService? _plzLookupService;
  
  // Constructor
  LocationProvider({bool testMode = false}) {
    if (!testMode) {
      // For MVP/Testing: Set default permissions to avoid test issues
      _hasLocationPermission = true;
      _isLocationServiceEnabled = true;
      debugPrint('🔧 LocationProvider: Default permissions granted for MVP/Testing');
    }
    // In testMode, permissions start as false for proper testing
  }
  
  // Getters - Location Data
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get address => _address;
  String? get city => _city;
  String? get postalCode => _postalCode;
  bool get hasLocation => _latitude != null && _longitude != null;
  bool get hasAddress => _address != null && _address!.isNotEmpty;
  bool get hasPostalCode => _postalCode != null && _postalCode!.isNotEmpty;
  
  // Getters - Permissions & Status
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get locationError => _locationError;
  bool get canUseLocation => _hasLocationPermission && _isLocationServiceEnabled;
  
  // Getters - Settings
  double get searchRadiusKm => _searchRadiusKm;
  bool get useGPS => _useGPS;
  bool get autoUpdateLocation => _autoUpdateLocation;
  
  // Getters - Regional (ready for Task 5c)
  List<String> get availableRetailersInRegion => List.unmodifiable(_availableRetailersInRegion);
  bool get hasRegionalData => _availableRetailersInRegion.isNotEmpty;
  
  // Getters - PLZ Fallback (Task 5b.3)
  String? get userPLZ => _userPLZ;
  bool get hasAskedForLocation => _hasAskedForLocation;
  LocationSource get currentLocationSource => _currentLocationSource;
  bool get hasValidLocationData => hasLocation || hasPostalCode;
  
  // Provider Callbacks API (Task 5b.5)
  void registerLocationChangeCallback(VoidCallback callback) {
    _locationChangeCallbacks.add(callback);
  }
  
  void registerRegionalDataCallback(Function(String?, List<String>) callback) {
    _regionalDataCallbacks.add(callback);
  }
  
  void unregisterLocationChangeCallback(VoidCallback callback) {
    _locationChangeCallbacks.remove(callback);
  }
  
  void unregisterRegionalDataCallback(Function(String?, List<String>) callback) {
    _regionalDataCallbacks.remove(callback);
  }
  
  // CORE METHODE: ensureLocationData() für Tests
  /// Task 5b.6: Hauptmethode für intelligente Location-Bestimmung
  /// Implementiert Fallback-Kette: GPS → Cache → Dialog
  Future<bool> ensureLocationData({bool forceRefresh = false}) async {
    debugPrint('🗺️ LocationProvider: Starte intelligente Location-Bestimmung...');
    
    _setLocationError(null);
    
    // Fallback 1: GPS-Lokalisierung (wenn aktiviert und nicht force-refresh bei Cache)
    if (_useGPS && (forceRefresh || _currentLocationSource == LocationSource.none)) {
      debugPrint('📍 Fallback 1: GPS-Lokalisierung versuchen...');
      
      try {
        await getCurrentLocation();
        if (hasLocation) {
          // LocationSource.gps is already set in getCurrentLocation()
          debugPrint('✅ GPS-Lokalisierung erfolgreich');
          return true;
        }
      } catch (e) {
        debugPrint('❌ GPS-Lokalisierung fehlgeschlagen: $e');
      }
    }
    
    // Fallback 2: LocalStorage PLZ-Cache (nur wenn nicht force-refresh)
    if (!forceRefresh) {
      debugPrint('💾 Fallback 2: LocalStorage PLZ-Cache laden...');
      
      try {
        final cachedPLZ = await _loadPLZFromCache();
        if (cachedPLZ != null) {
          await _setPLZAsLocation(cachedPLZ);
          _currentLocationSource = LocationSource.cachedPLZ;
          debugPrint('✅ PLZ-Cache erfolgreich geladen: $cachedPLZ');
          return true;
        }
      } catch (e) {
        debugPrint('❌ PLZ-Cache-Laden fehlgeschlagen: $e');
      }
    }
    
    // Fallback 3: User-Dialog würde hier kommen (benötigt BuildContext)
    // Für Tests ohne Context: Fehler setzen und false zurückgeben
    debugPrint('❌ Alle Location-Fallbacks fehlgeschlagen');
    _setLocationError('Standort-Bestimmung fehlgeschlagen. GPS nicht verfügbar und kein Cache vorhanden.');
    return false;
  }
  
  /// Helper: PLZ aus LocalStorage laden
  Future<String?> _loadPLZFromCache() async {
    try {
      _storageService ??= await LocalStorageService.getInstance();
      final cachedPLZ = await _storageService!.getUserPLZ();
      
      if (cachedPLZ != null) {
        debugPrint('✅ LocalStorage: User-PLZ "$cachedPLZ" geladen');
        return cachedPLZ;
      } else {
        debugPrint('💭 LocalStorage: Keine User-PLZ gespeichert');
        return null;
      }
    } catch (e) {
      debugPrint('❌ PLZ-Cache nicht verfügbar oder abgelaufen');
      return null;
    }
  }
  
  /// Helper: PLZ in LocalStorage speichern
  Future<void> _savePLZToCache(String plz) async {
    try {
      _storageService ??= await LocalStorageService.getInstance();
      await _storageService!.saveUserPLZ(plz);
      debugPrint('✅ LocalStorage: User-PLZ "$plz" gespeichert');
    } catch (e) {
      debugPrint('⚠️ PLZ-Cache speichern fehlgeschlagen');
    }
  }
  
  /// Helper: PLZ als Location-Daten setzen (Task 5b.5: Enhanced PLZ Integration)
  Future<void> _setPLZAsLocation(String plz) async {
    try {
      _setLoadingLocation(true);
      
      // PLZ-Lookup Service initialisieren
      _plzLookupService ??= PLZLookupService();
      
      // PLZ-Daten setzen
      _postalCode = plz;
      _userPLZ = plz;
      
      // Region aus PLZ bestimmen (Enhanced von Task 5b.4)
      final region = _plzLookupService!.getRegionFromPLZ(plz);
      if (region != null) {
        _address = '$plz, $region, Deutschland';
        _city = region;
        debugPrint('🎯 PLZ $plz → Region: $region');
      } else {
        _address = '$plz, Deutschland';
        _city = 'Deutschland';
        debugPrint('⚠️ PLZ $plz → Unbekannte Region');
      }
      
      // TODO Task 5b.5: Echte PLZ-zu-Koordinaten-Konvertierung
      // Derzeit simuliert, wird später durch Reverse-PLZ-Lookup ersetzt
      await _simulateCoordinatesFromPLZ(plz);
      
      // Regionale Daten aktualisieren
      await _updateRegionalData();
      
      // Provider-Callbacks benachrichtigen (Task 5b.5)
      _notifyLocationCallbacks();
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ PLZ-Location-Setup-Fehler: $e');
    } finally {
      _setLoadingLocation(false);
    }
  }
  
  /// Simulation: Koordinaten aus PLZ ableiten - Enhanced mit Default-Koordinaten (Task C)
  Future<void> _simulateCoordinatesFromPLZ(String plz) async {
    // Basis-Koordinaten für deutsche Städte
    final plzToCoords = {
      '10': [52.5200, 13.4050], // Berlin
      '20': [53.5511, 9.9937],  // Hamburg  
      '30': [52.3759, 9.7320],  // Hannover
      '40': [51.2277, 6.7735],  // Düsseldorf
      '50': [50.9375, 6.9603],  // Köln
      '60': [50.1109, 8.6821],  // Frankfurt
      '70': [48.7758, 9.1829],  // Stuttgart
      '80': [48.1351, 11.5820], // München
      '90': [49.4521, 11.0767], // Nürnberg
    };
    
    final prefix = plz.substring(0, 2);
    final coords = plzToCoords[prefix] ?? [51.1657, 10.4515]; // Deutschland-Mitte
    
    // TASK C FIX: Koordinaten immer setzen, auch für unbekannte PLZ
    _latitude = coords[0];
    _longitude = coords[1];
    
    debugPrint('🗺️ PLZ $plz → Koordinaten: ${_latitude}, ${_longitude}');
  }
  
  /// Öffentliche API: Manuelle PLZ setzen (mit Caching)
  Future<bool> setUserPLZ(String plz, {bool saveToCache = true}) async {
    if (!PLZHelper.isValidPLZ(plz)) {
      _setLocationError('Ungültige PLZ: $plz');
      return false;
    }
    
    try {
      _userPLZ = plz;
      _currentLocationSource = LocationSource.userPLZ;
      
      if (saveToCache) {
        await _savePLZToCache(plz);
      }
      
      await _setPLZAsLocation(plz);
      
      debugPrint('User-PLZ gesetzt: $plz');
      return true;
      
    } catch (e) {
      _setLocationError('Fehler beim Setzen der PLZ: $e');
      return false;
    }
  }
  
  /// Öffentliche API: PLZ-Cache löschen
  Future<void> clearPLZCache() async {
    try {
      _storageService ??= await LocalStorageService.getInstance();
      await _storageService!.clearUserPLZ();
      
      _userPLZ = null;
      debugPrint('🧹 PLZ-Cache gelöscht');
      
    } catch (e) {
      debugPrint('❌ PLZ-Cache-Löschen fehlgeschlagen: $e');
    }
  }
  
  Future<void> requestLocationPermission() async {
    _setLocationError(null);
    
    try {
      // TODO: In real app, use geolocator package
      // For now, simulate permission request
      await Future.delayed(Duration(milliseconds: 500));
      
      // TASK PERMISSION FIX: Don't overwrite existing permissions for tests
      // Only set permissions if they were false initially
      if (!_hasLocationPermission || !_isLocationServiceEnabled) {
        _hasLocationPermission = true;
        _isLocationServiceEnabled = true;
        debugPrint('🔧 Permissions granted after request');
      }
      
      notifyListeners();
    } catch (e) {
      _setLocationError('Fehler bei Standort-Berechtigung: ${e.toString()}');
    }
  }
  
  Future<void> getCurrentLocation() async {
    debugPrint('🔧 getCurrentLocation: canUseLocation = $canUseLocation');
    
    if (!canUseLocation) {
      debugPrint('🔧 Requesting location permission...');
      await requestLocationPermission();
      debugPrint('🔧 After permission request: canUseLocation = $canUseLocation');
      if (!canUseLocation) {
        debugPrint('❌ getCurrentLocation: Early return - no location permission');
        _setLocationError('Standort-Berechtigung verweigert');
        return;
      }
    }
    
    _setLoadingLocation(true);
    _setLocationError(null);
    
    try {
      debugPrint('🔧 Starting GPS simulation...');
      // TODO: In real app, use geolocator to get actual GPS coordinates
      // For MVP, simulate Berlin coordinates
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Simulate GPS coordinates (Berlin Mitte)
      _latitude = 52.5200;
      _longitude = 13.4050;
      
      // CRITICAL FIX: Set LocationSource to GPS when coordinates are obtained
      _currentLocationSource = LocationSource.gps;
      debugPrint('✅ getCurrentLocation: LocationSource set to GPS');
      
      // Reverse geocoding simulation
      await _performReverseGeocoding();
      
      // Ensure notifyListeners is called after successful GPS
      notifyListeners();
      debugPrint('✅ getCurrentLocation: notifyListeners called');
      
    } catch (e) {
      debugPrint('❌ getCurrentLocation error: $e');
      _setLocationError('Fehler bei Standortermittlung: ${e.toString()}');
      _currentLocationSource = LocationSource.none;
    } finally {
      _setLoadingLocation(false);
    }
  }
  
  Future<void> setManualLocation(String address) async {
    _setLoadingLocation(true);
    _setLocationError(null);
    
    try {
      // TODO: In real app, use geocoding to convert address to coordinates
      // For MVP, simulate address parsing
      await Future.delayed(Duration(milliseconds: 800));
      
      _address = address;
      
      // Simulate coordinates based on address (Berlin example)
      if (address.toLowerCase().contains('berlin')) {
        _latitude = 52.5200;
        _longitude = 13.4050;
        _city = 'Berlin';
        _postalCode = '10115';
      } else {
        // Default to Munich for other addresses
        _latitude = 48.1374;
        _longitude = 11.5755;
        _city = 'München';
        _postalCode = '80331';
      }
      
    } catch (e) {
      _setLocationError('Fehler bei Adress-Geocoding: ${e.toString()}');
    } finally {
      _setLoadingLocation(false);
    }
  }
  
  Future<void> setManualPostalCode(String plz) async {
    _setLoadingLocation(true);
    _setLocationError(null);
    
    try {
      // TODO: In real app, use PLZ-to-coordinates lookup
      // For MVP, simulate PLZ mapping
      await Future.delayed(Duration(milliseconds: 600));
      
      _postalCode = plz;
      
      // Simulate coordinates based on PLZ
      if (plz.startsWith('10') || plz.startsWith('11') || plz.startsWith('12') || plz.startsWith('13') || plz.startsWith('14')) {
        // Berlin PLZ
        _latitude = 52.5200;
        _longitude = 13.4050;
        _city = 'Berlin';
        _address = 'Berlin, Deutschland';
      } else if (plz.startsWith('80') || plz.startsWith('81') || plz.startsWith('85')) {
        // München PLZ  
        _latitude = 48.1374;
        _longitude = 11.5755;
        _city = 'München';
        _address = 'München, Deutschland';
      } else {
        // Default to Frankfurt
        _latitude = 50.1109;
        _longitude = 8.6821;
        _city = 'Frankfurt am Main';
        _address = 'Frankfurt am Main, Deutschland';
      }
      
      // This will be extended in Task 5b-5c to update regional retailers
      await _updateRegionalData();
      
    } catch (e) {
      _setLocationError('Fehler bei PLZ-Lookup: ${e.toString()}');
    } finally {
      _setLoadingLocation(false);
    }
  }
  
  // Distance Calculations - Task E: Korrekte Haversine-Formel
  double calculateDistance(double lat, double lng) {
    if (!hasLocation) return double.infinity;
    
    // TASK E FIX: Korrekte Haversine-Formel für präzise Entfernungsberechnung
    const double earthRadius = 6371.0; // Erdradius in Kilometern
    
    // Koordinaten in Radians konvertieren
    double lat1Rad = _latitude! * (pi / 180.0);
    double lon1Rad = _longitude! * (pi / 180.0);
    double lat2Rad = lat * (pi / 180.0);
    double lon2Rad = lng * (pi / 180.0);
    
    // Differenzen berechnen
    double deltaLat = lat2Rad - lat1Rad;
    double deltaLon = lon2Rad - lon1Rad;
    
    // Haversine-Formel: a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
               cos(lat1Rad) * cos(lat2Rad) *
               sin(deltaLon / 2) * sin(deltaLon / 2);
    
    // c = 2 * atan2(√a, √(1−a))
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    // Entfernung: d = R * c
    double distance = earthRadius * c;
    
    debugPrint('📰 Distance: (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}) → (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}) = ${distance.toStringAsFixed(2)}km');
    
    return distance;
  }
  
  bool isWithinRadius(double lat, double lng, {double? customRadiusKm}) {
    double radius = customRadiusKm ?? _searchRadiusKm;
    return calculateDistance(lat, lng) <= radius;
  }
  
  // Settings
  void setSearchRadius(double radiusKm) {
    _searchRadiusKm = radiusKm.clamp(1.0, 50.0);
    notifyListeners();
  }
  
  void setUseGPS(bool useGPS) {
    _useGPS = useGPS;
    notifyListeners();
  }
  
  void setAutoUpdateLocation(bool autoUpdate) {
    _autoUpdateLocation = autoUpdate;
    notifyListeners();
    
    if (autoUpdate && canUseLocation) {
      // Start periodic location updates
      _startLocationUpdates();
    }
  }
  
  // Regional Data (ready for Task 5c integration)
  Future<void> _updateRegionalData() async {
    if (!hasPostalCode) return;
    
    try {
      // TODO: In Task 5c, this will be extended to:
      // 1. Use PLZ to determine region
      // 2. Filter available retailers based on region
      // 3. Update _availableRetailersInRegion
      
      // For now, simulate regional data
      if (_postalCode!.startsWith('10')) {
        // Berlin - alle Retailer verfügbar
        _availableRetailersInRegion = ['EDEKA', 'REWE', 'ALDI', 'Lidl', 'Netto Marken-Discount'];
      } else if (_postalCode!.startsWith('80')) {
        // München - ohne schwarzen Netto, mit Globus
        _availableRetailersInRegion = ['EDEKA', 'REWE', 'ALDI', 'Lidl', 'Netto Marken-Discount'];
      } else {
        // Standard - ohne regionale Spezialitäten
        _availableRetailersInRegion = ['EDEKA', 'REWE', 'ALDI', 'Lidl'];
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating regional data: $e');
    }
  }
  
  void clearLocation() {
    _latitude = null;
    _longitude = null;
    _address = null;
    _city = null;
    _postalCode = null;
    _currentLocationSource = LocationSource.none;
    _availableRetailersInRegion.clear();
    _setLocationError(null);
    notifyListeners();
  }
  
  // Helper Methods
  Future<void> _performReverseGeocoding() async {
    if (!hasLocation) return;
    
    try {
      // TODO: In real app, use actual reverse geocoding service
      // For MVP, simulate reverse geocoding
      await Future.delayed(Duration(milliseconds: 300));
      
      // Simulate address lookup based on coordinates
      if (_latitude! > 52.4 && _latitude! < 52.6 && _longitude! > 13.3 && _longitude! < 13.5) {
        // Berlin area
        _address = 'Berlin, Deutschland';
        _city = 'Berlin';
        _postalCode = '10115';
      } else if (_latitude! > 48.0 && _latitude! < 48.3 && _longitude! > 11.4 && _longitude! < 11.7) {
        // München area
        _address = 'München, Deutschland';
        _city = 'München';
        _postalCode = '80331';
      } else {
        _address = 'Deutschland';
        _city = 'Unbekannt';
        _postalCode = null;
      }
      
      await _updateRegionalData();
      
      // Provider-Callbacks benachrichtigen (Task 5b.5)
      _notifyLocationCallbacks();
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
  }
  
  void _startLocationUpdates() {
    if (_autoUpdateLocation && canUseLocation) {
      // TODO: Implement periodic location updates
      // For MVP, just refresh once
      Future.delayed(Duration(minutes: 5), () {
        if (_autoUpdateLocation) {
          getCurrentLocation();
        }
      });
    }
  }
  
  void _setLoadingLocation(bool loading) {
    _isLoadingLocation = loading;
    notifyListeners();
  }
  
  void _setLocationError(String? error) {
    _locationError = error;
    notifyListeners();
  }
  
  // Utility Getters
  String get locationSummary {
    if (hasAddress) {
      return _address!;
    } else if (hasPostalCode) {
      return 'PLZ: $_postalCode';
    } else if (hasLocation) {
      return '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}';
    } else {
      return 'Kein Standort';
    }
  }
  
  // Provider Callback Helpers (Task 5b.5)
  void _notifyLocationCallbacks() {
    debugPrint('LocationProvider: Benachrichtige ${_locationChangeCallbacks.length} Location-Callbacks');
    
    try {
      // Allgemeine Location-Change-Callbacks
      for (final callback in _locationChangeCallbacks) {
        callback();
      }
      
      // Regionale Daten-Callbacks mit PLZ + verfügbare Retailer
      for (final callback in _regionalDataCallbacks) {
        callback(_postalCode, _availableRetailersInRegion);
      }
      
      debugPrint('LocationProvider: Alle Callbacks erfolgreich benachrichtigt');
      
    } catch (e) {
      debugPrint('LocationProvider: Fehler bei Callback-Benachrichtigung: $e');
    }
  }
  
  @override
  void dispose() {
    // Clean up callbacks and timers
    _locationChangeCallbacks.clear();
    _regionalDataCallbacks.clear();
    super.dispose();
  }
}
