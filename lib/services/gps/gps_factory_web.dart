// Web implementation for conditional imports
import 'gps_service.dart';
import 'web_gps_service.dart';

GPSService createGPSService() {
  // Use WebGPSService for web platform
  return WebGPSService();
}