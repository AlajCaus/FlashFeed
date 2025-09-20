// GPS Service Factory with Conditional Import
// Automatically selects the right implementation based on platform

import 'gps_service.dart';
import 'gps_factory_stub.dart'
    if (dart.library.html) 'gps_factory_web.dart'
    if (dart.library.io) 'gps_factory_mobile.dart';

/// Factory to create the appropriate GPS service based on platform
class GPSFactory {
  /// Creates platform-specific GPS service
  static GPSService create() {
    return createGPSService();
  }
}