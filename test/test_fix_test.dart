// Isolierter Test für die Fehleranalyse
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/providers/location_provider.dart';
import 'package:flashfeed/providers/flash_deals_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/services/gps/test_gps_service.dart';

void main() {
  group('Isolated Fix Tests', () {
    test('Flash Deals regional filter should check retailer availability', () async {
      // Setup
      final mockDataService = MockDataService();
      await mockDataService.initializeMockData(testMode: true);

      final locationProvider = LocationProvider(
        gpsService: TestGPSService(),
        mockDataService: mockDataService,
      );

      final flashDealsProvider = FlashDealsProvider(
        testService: mockDataService,
      );

      // Register with location provider
      flashDealsProvider.registerWithLocationProvider(locationProvider);

      // Set location to Berlin
      await locationProvider.setUserPLZ('10115');
      await Future.delayed(Duration(milliseconds: 100));

      // Load flash deals
      await flashDealsProvider.loadFlashDeals();

      // Get available retailers in region
      final availableRetailers = locationProvider.availableRetailersInRegion.toSet();

      // Check that all flash deal retailers are in available retailers
      final flashDealRetailers = flashDealsProvider.flashDeals
          .map((d) => d.retailer)
          .toSet();

      debugPrint('Available retailers in Berlin: $availableRetailers');
      debugPrint('Flash deal retailers: $flashDealRetailers');
      debugPrint('Flash deals count: ${flashDealsProvider.flashDeals.length}');

      // Test assertion
      final difference = flashDealRetailers.difference(availableRetailers);
      if (difference.isNotEmpty) {
        debugPrint('ERROR: Flash deal retailers not in region: $difference');
      }

      expect(flashDealRetailers.difference(availableRetailers).isEmpty, isTrue,
          reason: 'All flash deal retailers should be in available retailers');

      // Cleanup
      mockDataService.dispose();
      locationProvider.dispose();
      flashDealsProvider.dispose();
    });
  });
}