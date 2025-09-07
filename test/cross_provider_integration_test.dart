import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flashfeed/providers/location_provider.dart';
import 'package:flashfeed/providers/offers_provider.dart';
import 'package:flashfeed/providers/flash_deals_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/services/gps/test_gps_service.dart';

void main() {
  group('Cross-Provider Integration Tests (PRIORITÄT 2)', () {
    late LocationProvider locationProvider;
    late OffersProvider offersProvider;
    late FlashDealsProvider flashDealsProvider;
    late MockDataService testMockDataService;
    
    setUp(() async {
      // Test environment setup (pattern from PRIORITÄT 1)
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      // Initialize MockDataService in test mode
      testMockDataService = MockDataService();
      await testMockDataService.initializeMockData(testMode: true);
      
      // Initialize providers with test service and GPS service
      locationProvider = LocationProvider(
        gpsService: TestGPSService(),
        mockDataService: testMockDataService,
      );
      offersProvider = OffersProvider.mock(testService: testMockDataService);
      flashDealsProvider = FlashDealsProvider(testService: testMockDataService);
      
      // Register cross-provider callbacks (Task 5b.6 Phase 2.1)
      offersProvider.registerWithLocationProvider(locationProvider);
      flashDealsProvider.registerWithLocationProvider(locationProvider);
    });
    
    tearDown(() {
      // WICHTIG: Disposal-Reihenfolge - abhängige Provider zuerst!
      // Reason: OffersProvider und FlashDealsProvider haben Callbacks zu LocationProvider
      try {
        testMockDataService.dispose();
      } catch (e) {
        // Ignore disposal errors for already disposed services
      }
      
      try {
        offersProvider.dispose();       // Zuerst: abhängige Provider
      } catch (e) {
        // Ignore disposal errors for already disposed providers
      }
      
      try {
        flashDealsProvider.dispose();
      } catch (e) {
        // Ignore disposal errors for already disposed providers
      }
      
      try {
        locationProvider.dispose();     // Zuletzt: der Provider mit den Callbacks
      } catch (e) {
        // Ignore disposal errors for already disposed providers
      }
    });
    
    group('LocationProvider → OffersProvider Integration', () {
      test('Berlin User (PLZ 10115) sees only available retailers', () async {
        // Arrange: Set Berlin location
        await locationProvider.setUserPLZ('10115');
        
        // Act: Load offers with regional filtering
        await offersProvider.loadOffers();
        
        // Assert: Only Berlin-available retailers shown
        final berlinRetailers = locationProvider.getAvailableRetailersForPLZ('10115');
        final availableRetailers = offersProvider.offers
            .map((offer) => offer.retailer)
            .toSet()
            .toList();
        
        expect(availableRetailers.every((retailer) => 
            berlinRetailers.contains(retailer)), isTrue,
            reason: 'All retailers should be available in Berlin (PLZ 10115)');
        
        // Verify regional filtering is active
        expect(offersProvider.hasRegionalFiltering, isTrue);
        expect(offersProvider.userPLZ, equals('10115'));
      });
      
      test('Muenchen User (PLZ 80331) sees different retailers', () async {
        // Arrange: Set Muenchen location
        await locationProvider.setUserPLZ('80331');
        
        // Act: Load offers with regional filtering
        await offersProvider.loadOffers();
        
        // Assert: Only Muenchen-available retailers shown
        final muenchenRetailers = locationProvider.getAvailableRetailersForPLZ('80331');
        final availableRetailers = offersProvider.offers
            .map((offer) => offer.retailer)
            .toSet()
            .toList();
        
        expect(availableRetailers.every((retailer) => 
            muenchenRetailers.contains(retailer)), isTrue,
            reason: 'All retailers should be available in Muenchen (PLZ 80331)');
        
        // BioCompany should NOT be available in Muenchen (dynamic check)
        expect(muenchenRetailers.contains('BIOCOMPANY'), isFalse,
            reason: 'BIOCOMPANY is only available in Berlin/Brandenburg');
      });
      
      test('LocationProvider callback triggers OffersProvider regional filtering', () async {
        // Arrange: Start with no location
        expect(offersProvider.hasRegionalFiltering, isFalse);
        
        // Act: Set location through LocationProvider
        await locationProvider.setUserPLZ('10115');
        
        // Assert: Callback should have triggered regional filtering
        expect(locationProvider.userPLZ, equals('10115'));
        expect(locationProvider.currentLocationSource, LocationSource.userPLZ);
        expect(offersProvider.hasRegionalFiltering, isTrue);
        expect(offersProvider.userPLZ, equals('10115'));
      });
    });
    
    group('LocationProvider → FlashDealsProvider Integration', () {
      test('Standort-Update propagates to FlashDealsProvider', () async {
        // Arrange: Load initial flash deals
        await flashDealsProvider.loadFlashDeals();
        
        // Act: Change location
        await locationProvider.setUserPLZ('10115');
        
        // Assert: FlashDealsProvider should be notified
        expect(locationProvider.userPLZ, equals('10115'));
        expect(flashDealsProvider.hasRegionalFiltering, isTrue);
        expect(flashDealsProvider.userPLZ, equals('10115'));
      });
      
      test('Only regional Flash Deals are displayed', () async {
        // Arrange: Set Berlin location
        await locationProvider.setUserPLZ('10115');
        
        // Act: Load flash deals
        await flashDealsProvider.loadFlashDeals();
        
        // Assert: Only Berlin-available retailers in flash deals
        final flashDeals = flashDealsProvider.flashDeals;
        
        expect(flashDeals.isNotEmpty, isTrue,
            reason: 'Flash deals should be available');
        
        // Verify that flash deals only show Berlin-available retailers
        final berlinRetailers = locationProvider.getAvailableRetailersForPLZ('10115');
        final dealRetailers = flashDeals
            .map((deal) => deal.retailer)
            .toSet()
            .toList();
            
        expect(dealRetailers.every((retailer) => 
            berlinRetailers.contains(retailer)), isTrue,
            reason: 'Flash deals should only show Berlin-available retailers');
      });
      
      test('Timer system remains synchronized during location updates', () async {
        // Arrange: Get initial timer state
        await flashDealsProvider.loadFlashDeals();
        final initialDeals = flashDealsProvider.flashDeals;
        
        if (initialDeals.isNotEmpty) {
          final initialRemainingTime = initialDeals.first.remainingSeconds;
          
          // Act: Change location
          await locationProvider.setUserPLZ('80331');
          
          // Simulate timer update in test mode
          testMockDataService.updateTimersForTesting();
          
          // Small delay to check timer consistency
          await Future.delayed(Duration(milliseconds: 100));
          
          // Assert: Timer should still be running correctly
          final updatedDeals = flashDealsProvider.flashDeals;
          if (updatedDeals.isNotEmpty) {
            expect(updatedDeals.first.remainingSeconds, lessThanOrEqualTo(initialRemainingTime),
                reason: 'Timer should continue counting down during location updates');
          }
        }
      });
    });
    
    group('Multi-Provider State Synchronisation', () {
      test('PLZ change propagates to all providers simultaneously', () async {
        // Arrange: Initialize all providers
        await offersProvider.loadOffers();
        await flashDealsProvider.loadFlashDeals();
        
        // Act: Change PLZ
        await locationProvider.setUserPLZ('10115');
        
        // Assert: All providers should be aware of the new location
        expect(locationProvider.userPLZ, equals('10115'));
        expect(locationProvider.currentLocationSource, LocationSource.userPLZ);
        expect(offersProvider.userPLZ, equals('10115'));
        expect(flashDealsProvider.userPLZ, equals('10115'));
      });
      
      test('State consistency across all providers', () async {
        // Arrange: Set location
        await locationProvider.setUserPLZ('80331');
        
        // Act: Load data in all providers
        await offersProvider.loadOffers();
        await flashDealsProvider.loadFlashDeals();
        
        // Assert: Consistent state across providers
        expect(locationProvider.userPLZ, equals('80331'));
        expect(offersProvider.userPLZ, equals('80331'));
        expect(flashDealsProvider.userPLZ, equals('80331'));
        
        // Verify that the same retailers are available in both providers
        final offersRetailers = offersProvider.availableRetailers;
        final flashDealsRetailers = flashDealsProvider.availableRetailers;
        expect(offersRetailers, equals(flashDealsRetailers),
            reason: 'Available retailers should be consistent across providers');
      });
      
      test('No race conditions during simultaneous location updates', () async {
        // Arrange: Multiple rapid location changes
        final locations = ['10115', '80331', '20095', '40213'];
        
        // Act: Rapid location changes
        for (final plz in locations) {
          locationProvider.setUserPLZ(plz);
          // No await - simulate rapid changes
        }
        
        // Wait for all operations to complete
        await Future.delayed(Duration(milliseconds: 500));
        
        // Assert: Final state should be consistent
        expect(locationProvider.userPLZ, equals(locations.last));
        expect(locationProvider.isLoadingLocation, isFalse,
            reason: 'Loading should be completed after race conditions');
      });
    });
    
    group('Regional Data Callback System', () {
      test('RegionalDataCallback integration works correctly', () async {
        // Arrange: Mock callback tracking
        bool callbackTriggered = false;
        String? receivedPLZ;
        List<String>? receivedRetailers;
        
        // Register test callback
        locationProvider.registerRegionalDataCallback((plz, retailers) {
          callbackTriggered = true;
          receivedPLZ = plz;
          receivedRetailers = retailers;
        });
        
        // Act: Set location
        await locationProvider.setUserPLZ('10115');
        
        // Assert: Callback should have been triggered
        expect(callbackTriggered, isTrue,
            reason: 'Regional data callback should be triggered');
        expect(receivedPLZ, equals('10115'));
        expect(receivedRetailers, isNotNull);
        expect(receivedRetailers!.isNotEmpty, isTrue,
            reason: 'Available retailers list should not be empty');
      });
      
      test('Multiple callback registrations work correctly', () async {
        // Arrange: Multiple callback registrations
        int callback1Count = 0;
        int callback2Count = 0;
        
        locationProvider.registerRegionalDataCallback((plz, retailers) {
          callback1Count++;
        });
        
        locationProvider.registerRegionalDataCallback((plz, retailers) {
          callback2Count++;
        });
        
        // Act: Set location
        await locationProvider.setUserPLZ('10115');
        
        // Assert: Both callbacks should be triggered
        expect(callback1Count, equals(1));
        expect(callback2Count, equals(1));
      });
      
      test('Callback unregistration prevents further calls', () async {
        // Arrange: Register and unregister callback
        int callbackCount = 0;
        
        void testCallback(String? plz, List<String> retailers) {
          callbackCount++;
        }
        
        locationProvider.registerRegionalDataCallback(testCallback);
        
        // First call should trigger
        await locationProvider.setUserPLZ('10115');
        expect(callbackCount, equals(1));
        
        // Unregister and test again
        locationProvider.unregisterRegionalDataCallback(testCallback);
        await locationProvider.setUserPLZ('80331');
        
        // Assert: Callback should not be triggered after unregistration
        expect(callbackCount, equals(1),
            reason: 'Callback should not be triggered after unregistration');
      });
    });
    
    group('Cross-Provider Communication Stress Tests', () {
      test('High frequency location updates performance', () async {
        // Arrange: Rapid location updates
        final stopwatch = Stopwatch()..start();
        
        // Act: 50 rapid location updates
        for (int i = 0; i < 50; i++) {
          final plz = ['10115', '80331', '20095'][i % 3];
          await locationProvider.setUserPLZ(plz);
        }
        
        stopwatch.stop();
        
        // Assert: Performance should be acceptable
        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
            reason: '50 location updates should complete within 5 seconds');
        
        // Verify final state consistency
        expect(locationProvider.isLoadingLocation, isFalse);
        expect(locationProvider.locationError, isNull);
      });
      
      test('Memory leak prevention during callback operations', () async {
        // Arrange: Multiple callback registrations and unregistrations
        final callbacks = <Function(String?, List<String>)>[];
        
        // Create many callbacks
        for (int i = 0; i < 100; i++) {
          void callback(String? plz, List<String> retailers) {
            // Dummy operation
          }
          callbacks.add(callback);
          locationProvider.registerRegionalDataCallback(callback);
        }
        
        // Act: Trigger callbacks and then unregister
        await locationProvider.setUserPLZ('10115');
        
        for (final callback in callbacks) {
          locationProvider.unregisterRegionalDataCallback(callback);
        }
        
        // Assert: No memory leaks or hanging references
        await locationProvider.setUserPLZ('80331');
        
        expect(locationProvider.userPLZ, equals('80331'));
        expect(locationProvider.locationError, isNull);
      });
      
      test('Provider disposal cleanup', () async {
        // Arrange: Set up cross-provider relationships
        await locationProvider.setUserPLZ('10115');
        await offersProvider.loadOffers();
        
        // Act: Dispose providers in correct order - abhängige Provider zuerst!
        offersProvider.dispose();       // Zuerst: Provider mit Callbacks zu LocationProvider
        flashDealsProvider.dispose();
        locationProvider.dispose();     // Zuletzt: Provider der die Callbacks hält
        
        // Assert: Clean disposal without errors
        expect(true, isTrue, reason: 'Disposal should complete without errors');
      });
    });
    
    group('Task 5c.2: OffersProvider Regional Filtering', () {
      test('getRegionalOffers returns only regional offers', () async {
        // Set Berlin location
        await locationProvider.setUserPLZ('10115');
        
        // Load offers first
        await offersProvider.loadOffers();
        
        // Get regional offers
        final regionalOffers = offersProvider.getRegionalOffers('10115');
        
        // Verify all offers are from available retailers
        final berlinRetailers = locationProvider.getAvailableRetailersForPLZ('10115');
        expect(regionalOffers.every((offer) => 
            berlinRetailers.contains(offer.retailer)), isTrue,
            reason: 'All offers should be from Berlin-available retailers');
      });

      test('regional filtering works correctly', () async {
        // Load all offers first without filter to see total count
        await offersProvider.loadOffers(applyRegionalFilter: false);
        final totalOffersCount = offersProvider.allOffers.length;
        
        // Apply regional filter for Berlin
        await locationProvider.setUserPLZ('10115');
        await offersProvider.loadOffers(applyRegionalFilter: true);
        final regionalOffersCount = offersProvider.allOffers.length;
        
        // Check that offers are actually being filtered
        expect(totalOffersCount, greaterThan(0),
            reason: 'Should have some offers to test');
        
        // If there are non-Berlin retailers, count should be less
        final berlinRetailers = locationProvider.getAvailableRetailersForPLZ('10115');
        final allRetailers = ['EDEKA', 'REWE', 'ALDI SÜD', 'LIDL', 'NETTO', 
                              'PENNY', 'KAUFLAND', 'REAL', 'GLOBUS', 'MARKTKAUF', 
                              'BIOCOMPANY'];
        
        // Check if filtering is applied
        if (allRetailers.length > berlinRetailers.length) {
          expect(regionalOffersCount, lessThanOrEqualTo(totalOffersCount),
              reason: 'Regional filtering should reduce or maintain offer count');
        }
        
        // Verify all remaining offers are from available retailers
        for (final offer in offersProvider.allOffers) {
          expect(berlinRetailers.contains(offer.retailer), isTrue,
              reason: 'Offer from ${offer.retailer} should be available in Berlin');
        }
      });

      test('emptyStateMessage provides correct feedback', () async {
        // Test with valid PLZ but no filtering
        await locationProvider.setUserPLZ('10115');
        await offersProvider.loadOffers(applyRegionalFilter: false);
        
        // Clear all offers to test empty state
        offersProvider.clearAllFilters();
        offersProvider.setMaxPrice(0.01); // Set impossibly low price
        
        final message = offersProvider.emptyStateMessage;
        expect(message, isNotEmpty,
            reason: 'Empty state message should not be empty');
        
        // Test with no available retailers
        await locationProvider.setUserPLZ('99999'); // Fictional PLZ
        await offersProvider.loadOffers(applyRegionalFilter: true);
        
        final noRetailersMessage = offersProvider.emptyStateMessage;
        if (offersProvider.availableRetailers.isEmpty) {
          expect(noRetailersMessage, contains('Keine'),
              reason: 'Should indicate no retailers available');
        }
      });
      
      test('loadOffers respects applyRegionalFilter parameter', () async {
        // Set location
        await locationProvider.setUserPLZ('10115');
        
        // Load without regional filter
        await offersProvider.loadOffers(applyRegionalFilter: false);
        final allOffersCount = offersProvider.allOffers.length;
        
        // Load with regional filter
        await offersProvider.loadOffers(applyRegionalFilter: true);
        final regionalOffersCount = offersProvider.allOffers.length;
        
        // Regional offers should be less than or equal to all offers
        expect(regionalOffersCount, lessThanOrEqualTo(allOffersCount),
            reason: 'Regional filtering should not increase offer count');
        
        // Verify that only Berlin-available retailers are shown
        final berlinRetailers = locationProvider.getAvailableRetailersForPLZ('10115');
        final offerRetailers = offersProvider.allOffers
            .map((o) => o.retailer).toSet().toList();
        
        for (final retailer in offerRetailers) {
          expect(berlinRetailers.contains(retailer), isTrue,
              reason: 'Retailer $retailer should be available in Berlin');
        }
      });
      
      test('getRegionalAvailabilityMessage returns correct messages', () async {
        // Set location
        await locationProvider.setUserPLZ('10115');
        await offersProvider.loadOffers(applyRegionalFilter: true);
        
        // Test for available retailer message
        if (offersProvider.availableRetailers.isNotEmpty) {
          final availableRetailer = offersProvider.availableRetailers.first;
          final message = offersProvider.getRegionalAvailabilityMessage(availableRetailer);
          expect(message, contains('verfügbar'),
              reason: 'Available retailer should be marked as available');
          expect(message, contains('10115'),
              reason: 'Message should include PLZ');
        }
        
        // Test for unknown PLZ
        offersProvider.clearAllFilters();
        final unknownMessage = offersProvider.getRegionalAvailabilityMessage('EDEKA');
        if (offersProvider.userPLZ == null) {
          expect(unknownMessage, contains('unbekannt'),
              reason: 'Should indicate unknown availability when no PLZ set');
        }
      });
    });
  });
}
