// GPS Service Interface for dependency injection
import 'dart:async';

abstract class GPSService {
  /// Get current GPS coordinates
  Future<GPSResult> getCurrentLocation();
  
  /// Perform reverse geocoding lookup
  Future<AddressResult> reverseGeocode(double latitude, double longitude);
  
  /// Check if GPS permissions are available
  bool get hasPermission;
  
  /// Request GPS permissions
  Future<bool> requestPermission();
}

class GPSResult {
  final double latitude;
  final double longitude;
  final bool success;
  final String? error;

  GPSResult({
    required this.latitude,
    required this.longitude,
    required this.success,
    this.error,
  });
}

class AddressResult {
  final String? address;
  final String? city;
  final String? postalCode;
  final bool success;
  final String? error;

  AddressResult({
    this.address,
    this.city,
    this.postalCode,
    required this.success,
    this.error,
  });
}
