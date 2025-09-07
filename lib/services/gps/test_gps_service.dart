// Test GPS Service without delays
import 'dart:async';
import 'gps_service.dart';

class TestGPSService implements GPSService {
  bool _hasPermission = true; // Start with permissions for test convenience
  
  // Test helper to override permissions
  void setPermissionForTesting(bool hasPermission) {
    _hasPermission = hasPermission;
  }
  
  @override
  bool get hasPermission => _hasPermission;

  @override
  Future<bool> requestPermission() async {
    _hasPermission = true;
    return true;
  }

  @override
  Future<GPSResult> getCurrentLocation() async {
    if (!_hasPermission) {
      return GPSResult(
        latitude: 0, 
        longitude: 0, 
        success: false, 
        error: 'No GPS permission'
      );
    }

    // NO delay for tests - immediate response
    return GPSResult(
      latitude: 52.5200,
      longitude: 13.4050,
      success: true,
    );
  }

  @override
  Future<AddressResult> reverseGeocode(double latitude, double longitude) async {
    // NO delay for tests - immediate response
    
    if (latitude > 52.4 && latitude < 52.6 && longitude > 13.3 && longitude < 13.5) {
      return AddressResult(
        address: 'Berlin, Deutschland',
        city: 'Berlin',
        postalCode: '10115',
        success: true,
      );
    } else if (latitude > 48.0 && latitude < 48.3 && longitude > 11.4 && longitude < 11.7) {
      return AddressResult(
        address: 'München, Deutschland',
        city: 'München',
        postalCode: '80331',
        success: true,
      );
    } else {
      return AddressResult(
        address: 'Deutschland',
        city: 'Unbekannt',
        success: true,
      );
    }
  }
}
