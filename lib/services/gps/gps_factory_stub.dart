// Stub implementation for conditional imports
import 'gps_service.dart';
import 'production_gps_service.dart';

GPSService createGPSService() {
  // Default fallback to production service
  return ProductionGPSService();
}