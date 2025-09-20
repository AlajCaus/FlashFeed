// Mobile implementation for conditional imports
import 'gps_service.dart';
import 'production_gps_service.dart';

GPSService createGPSService() {
  // For mobile, use ProductionGPSService (would be replaced with real mobile GPS later)
  return ProductionGPSService();
}