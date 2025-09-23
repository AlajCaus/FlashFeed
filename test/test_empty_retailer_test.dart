// Isolierter Test für empty retailer edge case
import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/providers/location_provider.dart';
import 'package:flashfeed/providers/offers_provider.dart';
import 'package:flashfeed/providers/flash_deals_provider.dart';
import 'package:flashfeed/providers/retailers_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/services/gps/test_gps_service.dart';

void main() {
  test('Empty retailer list edge case', () async {
    // Setup with timeout
    final mockDataService = MockDataService();
    await mockDataService.initializeMockData(testMode: true)
      .timeout(Duration(seconds: 2), onTimeout: () {
        throw Exception('MockDataService initialization timeout');
      });

    final locationProvider = LocationProvider(
      gpsService: TestGPSService(),
      mockDataService: mockDataService,
    );

    try {
      // Quick test without loading all providers
      print('Setting invalid PLZ 00000...');
      final result = await locationProvider.setUserPLZ('00000')
        .timeout(Duration(seconds: 2), onTimeout: () {
          print('setUserPLZ timeout!');
          return false;
        });

      print('setUserPLZ result: $result');
      print('Available retailers: ${locationProvider.availableRetailersInRegion}');

      // Expectations
      expect(locationProvider.availableRetailersInRegion.isEmpty, isTrue);

      print('Test passed!');
    } finally {
      // Cleanup
      mockDataService.dispose();
      locationProvider.dispose();
    }
  }, timeout: Timeout(Duration(seconds: 10)));
}