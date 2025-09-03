// FlashFeed Location Provider - GPS & Standort
// Basis-Implementierung (wird in Task 5b-5c für PLZ-Features erweitert)

import 'package:flutter/material.dart';
import '../repositories/retailers_repository.dart';

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
  
  // Constructor
  LocationProvider();
  
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
  
  // Location Methods
  Future<void> requestLocationPermission() async {
    _setLocationError(null);
    
    try {
      // TODO: In real app, use geolocator package
      // For now, simulate permission request
      await Future.delayed(Duration(milliseconds: 500));
      
      // Simulate permission granted (for MVP)
      _hasLocationPermission = true;
      _isLocationServiceEnabled = true;
      
      notifyListeners();
    } catch (e) {
      _setLocationError('Fehler bei Standort-Berechtigung: ${e.toString()}');
    }
  }
  
  Future<void> getCurrentLocation() async {
    if (!canUseLocation) {
      await requestLocationPermission();
      if (!canUseLocation) return;
    }
    
    _setLoadingLocation(true);
    _setLocationError(null);
    
    try {
      // TODO: In real app, use geolocator to get actual GPS coordinates
      // For MVP, simulate Berlin coordinates
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Simulate GPS coordinates (Berlin Mitte)
      _latitude = 52.5200;
      _longitude = 13.4050;
      
      // Reverse geocoding simulation
      await _performReverseGeocoding();
      
    } catch (e) {
      _setLocationError('Fehler bei Standortermittlung: ${e.toString()}');
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
  
  // Distance Calculations
  double calculateDistance(double lat, double lng) {
    if (!hasLocation) return double.infinity;
    
    // Simplified distance calculation (will use proper haversine in real app)
    const double earthRadius = 6371;
    double latDiff = (_latitude! - lat) * (3.14159 / 180);
    double lngDiff = (_longitude! - lng) * (3.14159 / 180);
    double a = (latDiff / 2) * (latDiff / 2) + (lngDiff / 2) * (lngDiff / 2);
    return earthRadius * 2 * (a < 1 ? a : 1);
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
  
  @override
  void dispose() {
    // Clean up any timers or listeners
    super.dispose();
  }
}
