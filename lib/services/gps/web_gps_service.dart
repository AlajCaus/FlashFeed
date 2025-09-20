// Web GPS Service - Real Browser Geolocation API Integration
// Task 12: LocationProvider Setup with Web Geolocation

import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'gps_service.dart';

class WebGPSService implements GPSService {
  bool _hasPermission = false;
  bool _permissionChecked = false;

  // Cache for last known position
  double? _lastLatitude;
  double? _lastLongitude;
  DateTime? _lastPositionTime;

  @override
  bool get hasPermission => _hasPermission;

  @override
  Future<bool> requestPermission() async {
    debugPrint('🌐 WebGPSService: Requesting GPS permission from browser...');

    try {
      // Check if geolocation is available
      // Note: isSupported is not available, check for null instead
      if (html.window.navigator.geolocation == null) {
        debugPrint('❌ Geolocation not supported in this browser');
        _hasPermission = false;
        _permissionChecked = true;
        return false;
      }

      // Try to get current position to trigger permission dialog
      final completer = Completer<bool>();

      html.window.navigator.geolocation.getCurrentPosition().then(
        (html.Geoposition position) {
          debugPrint('✅ GPS permission granted');
          _hasPermission = true;
          _permissionChecked = true;

          // Cache the position (convert num to double)
          _lastLatitude = position.coords!.latitude!.toDouble();
          _lastLongitude = position.coords!.longitude!.toDouble();
          _lastPositionTime = DateTime.now();

          completer.complete(true);
        },
        onError: (html.PositionError error) {
          debugPrint('❌ GPS permission denied or error: ${error.message}');
          _hasPermission = false;
          _permissionChecked = true;

          // Handle different error codes
          switch (error.code) {
            case 1: // PERMISSION_DENIED
              debugPrint('User denied GPS permission');
              break;
            case 2: // POSITION_UNAVAILABLE
              debugPrint('Position unavailable');
              break;
            case 3: // TIMEOUT
              debugPrint('GPS request timed out');
              break;
          }

          completer.complete(false);
        }
      );

      // Add timeout to prevent hanging
      return completer.future.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ GPS permission request timed out');
          _hasPermission = false;
          _permissionChecked = true;
          return false;
        },
      );

    } catch (e) {
      debugPrint('❌ Error requesting GPS permission: $e');
      _hasPermission = false;
      _permissionChecked = true;
      return false;
    }
  }

  @override
  Future<GPSResult> getCurrentLocation() async {
    debugPrint('📍 WebGPSService: Getting current location from browser...');

    // Check permission first
    if (!_permissionChecked) {
      final granted = await requestPermission();
      if (!granted) {
        return GPSResult(
          latitude: 0,
          longitude: 0,
          success: false,
          error: 'GPS permission denied',
        );
      }
    }

    if (!_hasPermission) {
      return GPSResult(
        latitude: 0,
        longitude: 0,
        success: false,
        error: 'No GPS permission',
      );
    }

    try {
      final completer = Completer<GPSResult>();

      // Configure options for high accuracy
      // Note: PositionOptions is deprecated, use parameters directly

      html.window.navigator.geolocation.getCurrentPosition(
        enableHighAccuracy: true,
        timeout: Duration(seconds: 15),
        maximumAge: Duration(minutes: 5),
      ).then(
        (html.Geoposition position) {
          final lat = position.coords!.latitude!.toDouble();
          final lng = position.coords!.longitude!.toDouble();
          final accuracy = position.coords!.accuracy?.toDouble();

          debugPrint('✅ GPS location obtained: $lat, $lng (accuracy: ${accuracy}m)');

          // Cache the position
          _lastLatitude = lat;
          _lastLongitude = lng;
          _lastPositionTime = DateTime.now();

          completer.complete(GPSResult(
            latitude: lat,
            longitude: lng,
            success: true,
            accuracy: accuracy,
          ));
        },
        onError: (html.PositionError error) {
          debugPrint('❌ Error getting GPS location: ${error.message}');

          // If we have cached position less than 5 minutes old, use it
          if (_lastLatitude != null &&
              _lastLongitude != null &&
              _lastPositionTime != null &&
              DateTime.now().difference(_lastPositionTime!).inMinutes < 5) {
            debugPrint('📦 Using cached GPS position');
            completer.complete(GPSResult(
              latitude: _lastLatitude!,
              longitude: _lastLongitude!,
              success: true,
              isCached: true,
            ));
          } else {
            // Fall back to IP-based geolocation or default
            completer.complete(_getFallbackLocation(error.message));
          }
        }
      );

      return completer.future.timeout(
        Duration(seconds: 20),
        onTimeout: () {
          debugPrint('⏱️ GPS location request timed out');

          // Use cached position if available
          if (_lastLatitude != null && _lastLongitude != null) {
            return GPSResult(
              latitude: _lastLatitude!,
              longitude: _lastLongitude!,
              success: true,
              isCached: true,
            );
          }

          return _getFallbackLocation('Timeout');
        },
      );

    } catch (e) {
      debugPrint('❌ Exception getting GPS location: $e');
      return _getFallbackLocation(e.toString());
    }
  }

  @override
  Future<AddressResult> reverseGeocode(double latitude, double longitude) async {
    debugPrint('🗺️ WebGPSService: Reverse geocoding $latitude, $longitude');

    // Enhanced reverse geocoding with more German cities
    // This would ideally use a real geocoding API, but for MVP we use mappings

    // Berlin area
    if (latitude > 52.3 && latitude < 52.7 && longitude > 13.1 && longitude < 13.7) {
      if (latitude > 52.5) {
        return AddressResult(
          address: 'Berlin-Mitte, Deutschland',
          city: 'Berlin',
          postalCode: '10115',
          success: true,
        );
      } else {
        return AddressResult(
          address: 'Berlin-Schöneberg, Deutschland',
          city: 'Berlin',
          postalCode: '10827',
          success: true,
        );
      }
    }

    // Munich area
    if (latitude > 48.0 && latitude < 48.3 && longitude > 11.4 && longitude < 11.7) {
      return AddressResult(
        address: 'München, Bayern, Deutschland',
        city: 'München',
        postalCode: '80331',
        success: true,
      );
    }

    // Hamburg area
    if (latitude > 53.4 && latitude < 53.7 && longitude > 9.8 && longitude < 10.2) {
      return AddressResult(
        address: 'Hamburg, Deutschland',
        city: 'Hamburg',
        postalCode: '20095',
        success: true,
      );
    }

    // Cologne area
    if (latitude > 50.8 && latitude < 51.1 && longitude > 6.8 && longitude < 7.2) {
      return AddressResult(
        address: 'Köln, Nordrhein-Westfalen, Deutschland',
        city: 'Köln',
        postalCode: '50667',
        success: true,
      );
    }

    // Frankfurt area
    if (latitude > 50.0 && latitude < 50.2 && longitude > 8.5 && longitude < 8.8) {
      return AddressResult(
        address: 'Frankfurt am Main, Hessen, Deutschland',
        city: 'Frankfurt',
        postalCode: '60311',
        success: true,
      );
    }

    // Stuttgart area
    if (latitude > 48.7 && latitude < 48.9 && longitude > 9.0 && longitude < 9.3) {
      return AddressResult(
        address: 'Stuttgart, Baden-Württemberg, Deutschland',
        city: 'Stuttgart',
        postalCode: '70173',
        success: true,
      );
    }

    // Düsseldorf area
    if (latitude > 51.1 && latitude < 51.3 && longitude > 6.7 && longitude < 6.9) {
      return AddressResult(
        address: 'Düsseldorf, Nordrhein-Westfalen, Deutschland',
        city: 'Düsseldorf',
        postalCode: '40213',
        success: true,
      );
    }

    // Leipzig area
    if (latitude > 51.2 && latitude < 51.4 && longitude > 12.2 && longitude < 12.5) {
      return AddressResult(
        address: 'Leipzig, Sachsen, Deutschland',
        city: 'Leipzig',
        postalCode: '04109',
        success: true,
      );
    }

    // Dortmund area
    if (latitude > 51.4 && latitude < 51.6 && longitude > 7.3 && longitude < 7.6) {
      return AddressResult(
        address: 'Dortmund, Nordrhein-Westfalen, Deutschland',
        city: 'Dortmund',
        postalCode: '44135',
        success: true,
      );
    }

    // Dresden area
    if (latitude > 50.9 && latitude < 51.2 && longitude > 13.6 && longitude < 13.9) {
      return AddressResult(
        address: 'Dresden, Sachsen, Deutschland',
        city: 'Dresden',
        postalCode: '01067',
        success: true,
      );
    }

    // Default: Try to determine region based on rough coordinates
    String region = _determineRegionFromCoordinates(latitude, longitude);

    return AddressResult(
      address: '$region, Deutschland',
      city: region,
      postalCode: _estimatePLZFromCoordinates(latitude, longitude),
      success: true,
    );
  }

  /// Fallback location when GPS fails
  GPSResult _getFallbackLocation(String? errorMessage) {
    debugPrint('🔄 Using fallback location due to: $errorMessage');

    // Try to determine location based on timezone or language
    final timeZone = DateTime.now().timeZoneName;

    // For German timezone, use a central German location
    if (timeZone.contains('CET') || timeZone.contains('CEST')) {
      // Frankfurt - center of Germany
      return GPSResult(
        latitude: 50.1109,
        longitude: 8.6821,
        success: true,
        isFallback: true,
      );
    }

    // Default to Berlin
    return GPSResult(
      latitude: 52.5200,
      longitude: 13.4050,
      success: true,
      isFallback: true,
    );
  }

  /// Helper: Determine region from coordinates
  String _determineRegionFromCoordinates(double lat, double lng) {
    // Rough regional detection based on coordinates
    if (lat > 53.0) return 'Norddeutschland';
    if (lat < 48.5) return 'Süddeutschland';
    if (lng < 7.5) return 'Westdeutschland';
    if (lng > 12.5) return 'Ostdeutschland';
    return 'Mitteldeutschland';
  }

  /// Helper: Estimate PLZ from coordinates
  String _estimatePLZFromCoordinates(double lat, double lng) {
    // Very rough PLZ estimation based on geographic regions
    if (lat > 53.5) return '20000'; // Hamburg region
    if (lat > 52.0 && lng > 13.0) return '10000'; // Berlin region
    if (lat < 48.5 && lng > 11.0) return '80000'; // Munich region
    if (lat < 49.0 && lng < 9.5) return '70000'; // Stuttgart region
    if (lng < 7.5) return '50000'; // Cologne region
    return '60000'; // Frankfurt region (center)
  }
}

