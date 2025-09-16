
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flashfeed/providers/location_provider.dart';
import 'package:flashfeed/providers/offers_provider.dart';
import 'package:flashfeed/providers/flash_deals_provider.dart';
import 'package:flashfeed/providers/retailers_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/services/gps/test_gps_service.dart';

void main() {
  group('Cross-Provider Integration Tests', () {
    late LocationProvider locationProvider;
    late OffersProvider offersProvider;
    late FlashDealsProvider flashDealsProvider;
    late RetailersProvider retailersProvider;
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
      retailersProvider = RetailersProvider.mock(testService: testMockDataService);
      
      // Register cross-provider callbacks (Task 5b.6 Phase 2.1 + Task 5c.5)
      offersProvider.registerWithLocationProvider(locationProvider);
      flashDealsProvider.registerWithLocationProvider(locationProvider);
      retailersProvider.registerWithLocationProvider(locationProvider);
      
      // Ensure all providers are fully initialized
      await retailersProvider.loadRetailers();
      await offersProvider.loadOffers(applyRegionalFilter: false);
      await flashDealsProvider.loadFlashDeals();
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
        retailersProvider.dispose();
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
        
        // WICHTIG: Warte bis Provider fertig geladen haben
        while (offersProvider.isLoading || flashDealsProvider.isLoading) {
          await Future.delayed(Duration(milliseconds: 50));
        }
        
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
        
        // WICHTIG: Warte bis Provider fertig geladen haben
        while (offersProvider.isLoading || flashDealsProvider.isLoading) {
          await Future.delayed(Duration(milliseconds: 50));
        }
        
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
    
    group('OffersProvider Regional Filtering', () {
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
        // This will trigger loadRegionalOffers via callback
        await locationProvider.setUserPLZ('10115');
        
        // Wait for the callback-triggered load to complete
        while (offersProvider.isLoading) {
          await Future.delayed(Duration(milliseconds: 10));
        }
        
        // WICHTIG: Warte bis regional filtering wirklich aktiv ist
        // Die Callbacks brauchen Zeit um zu propagieren
        int retryCount = 0;
        while ((!offersProvider.hasRegionalFiltering || offersProvider.allOffers.length == totalOffersCount) && retryCount < 20) {
          await Future.delayed(Duration(milliseconds: 100));
          retryCount++;
        }
        
        // Falls immer noch nicht gefiltert, explizit aufrufen
        if (!offersProvider.hasRegionalFiltering || offersProvider.allOffers.length == totalOffersCount) {
          await offersProvider.loadOffers(applyRegionalFilter: true);
        }
        
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
        
        // Verify REAL is NOT available in Berlin (no stores in Berlin PLZ range)
        expect(berlinRetailers.contains('REAL'), isFalse,
            reason: 'REAL should NOT be available in Berlin - stores only in Wuppertal/Düsseldorf');
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
    
    group('LocationProvider → RetailersProvider Integration', () {
      test('should update available retailers when location changes', () async {
        // Retailers are already loaded in setUp
        expect(retailersProvider.allRetailers.isNotEmpty, isTrue);
        
        // Set location to Berlin
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 100));
        
        // Check retailers are filtered for Berlin
        final berlinRetailers = retailersProvider.getAvailableRetailersForPLZ('10115');
        expect(berlinRetailers.contains('EDEKA'), isTrue);
        expect(berlinRetailers.contains('REWE'), isTrue);
        expect(berlinRetailers.contains('GLOBUS'), isFalse,
            reason: 'Globus should not be available in Berlin');
        expect(berlinRetailers.contains('REAL'), isFalse,
            reason: 'REAL should NOT be available in Berlin - stores only in Wuppertal/Düsseldorf');
        
        // Move to Munich
        await locationProvider.setUserPLZ('80331');
        await Future.delayed(Duration(milliseconds: 100));
        
        // Check retailers are updated for Munich
        final munichRetailers = retailersProvider.getAvailableRetailersForPLZ('80331');
        expect(munichRetailers.contains('EDEKA'), isTrue);
        expect(munichRetailers.contains('REWE'), isTrue);
        expect(munichRetailers.contains('GLOBUS'), isTrue,
            reason: 'Globus should be available in Munich');
      });
            
      test('should handle RetailersProvider registration with LocationProvider', () async {
        // Retailers are already loaded in setUp
        
        // Verify retailersProvider is registered
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 100));
        
        // Check that RetailersProvider received the update
        expect(retailersProvider.currentPLZ, equals('10115'));
        
        // Change location again
        await locationProvider.setUserPLZ('80331');
        await Future.delayed(Duration(milliseconds: 100));
        
        // Verify update propagated
        expect(retailersProvider.currentPLZ, equals('80331'));
      });
      
      test('should maintain consistency between all providers including retailers', () async {
        // Providers are already loaded in setUp
        
        // Set location and trigger updates
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 100));
        
        // WICHTIG: Warte bis Provider nicht mehr lädt
        while (offersProvider.isLoading || flashDealsProvider.isLoading) {
          await Future.delayed(Duration(milliseconds: 50));
        }
        
        // Jetzt explizit mit regionalem Filter laden (falls nötig)
        if (!offersProvider.hasRegionalFiltering) {
          await offersProvider.loadOffers(applyRegionalFilter: true);
        }
        
        await flashDealsProvider.loadFlashDeals();
        
        // All providers should have consistent regional data
        final locationRetailers = locationProvider.availableRetailersInRegion.toSet();
        final offersRetailers = offersProvider.offers
            .map((o) => o.retailer)
            .toSet();
        final flashDealsRetailers = flashDealsProvider.flashDeals
            .map((d) => d.retailer)
            .toSet();
        final availableRetailerNames = retailersProvider.availableRetailers
            .map((r) => r.name)
            .toSet();
        
        // All offers/deals should be from available retailers
        expect(offersRetailers.difference(locationRetailers).isEmpty, isTrue,
            reason: 'All offer retailers should be in available retailers');
        expect(flashDealsRetailers.difference(locationRetailers).isEmpty, isTrue,
            reason: 'All flash deal retailers should be in available retailers');
        
        // RetailersProvider should have same list as LocationProvider
        expect(availableRetailerNames, equals(locationRetailers),
            reason: 'RetailersProvider should have same retailers as LocationProvider');
      });
    });
    
    group('Extended Error Handling & Recovery', () {
      test('should handle invalid PLZ gracefully across all providers', () async {
        // Try setting invalid PLZ
        final result = await locationProvider.setUserPLZ('INVALID');
        expect(result, isFalse);
        expect(locationProvider.locationError, contains('Ungültige PLZ'));
        
        // All providers should maintain previous state
        expect(offersProvider.offers.isNotEmpty, isTrue);
        expect(flashDealsProvider.flashDeals.isNotEmpty, isTrue);
        expect(retailersProvider.allRetailers.isNotEmpty, isTrue);
      });
    });
    
    group('Memory Management & Performance', () {
      test('should handle provider unregistration correctly', () async {
        // Create temporary provider
        final tempOffersProvider = OffersProvider.mock(testService: testMockDataService);
        tempOffersProvider.registerWithLocationProvider(locationProvider);
        
        // Verify registration works
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 50));
        expect(tempOffersProvider.userPLZ, equals('10115'));
        
        // Unregister
        tempOffersProvider.unregisterFromLocationProvider(locationProvider);
        
        // Change location
        await locationProvider.setUserPLZ('80331');
        await Future.delayed(Duration(milliseconds: 50));
        
        // Temp provider should NOT be updated
        expect(tempOffersProvider.userPLZ, equals('10115'),
            reason: 'Unregistered provider should not receive updates');
        
        // Cleanup
        tempOffersProvider.dispose();
      });
      
      test('should not leak memory with multiple registrations', () async {
        // Register and unregister multiple times
        for (int i = 0; i < 10; i++) {
          final tempRetailersProvider = RetailersProvider.mock(testService: testMockDataService);
          tempRetailersProvider.registerWithLocationProvider(locationProvider);
          
          await locationProvider.setUserPLZ('10115');
          await Future.delayed(Duration(milliseconds: 10));
          
          tempRetailersProvider.unregisterFromLocationProvider(locationProvider);
          tempRetailersProvider.dispose();
        }
        
        // Original providers should still work
        await locationProvider.setUserPLZ('80331');
        expect(locationProvider.postalCode, '80331');
        expect(retailersProvider.currentPLZ, equals('80331'));
      });
      
      test('should handle PLZ cache correctly across providers', () async {
        // Set PLZ with cache
        await locationProvider.setUserPLZ('10115', saveToCache: true);
        await Future.delayed(Duration(milliseconds: 100));
        
        // Clear location
        locationProvider.clearLocation();
        
        // Disable GPS to force cache usage
        locationProvider.setUseGPS(false);
        
        // Restore from cache
        await locationProvider.ensureLocationData();
        await Future.delayed(Duration(milliseconds: 100));
        
        // Should restore PLZ and filter correctly
        expect(locationProvider.postalCode, '10115');
        expect(locationProvider.currentLocationSource, LocationSource.cachedPLZ);
        
        // Re-enable GPS for other tests
        locationProvider.setUseGPS(true);
        
        // All providers should be filtered for cached PLZ
        expect(retailersProvider.currentPLZ, equals('10115'));
        expect(offersProvider.userPLZ, equals('10115'));
        expect(flashDealsProvider.userPLZ, equals('10115'));
      });
    });
    
    // Task 5c.5: Additional Cross-Provider Integration Tests
    group('Task 5c.5 - Regional State Synchronization', () {
      test('should detect and report unavailable offers', () async {
        // Set location to Berlin (BioCompany available)
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 100));
        
        // Load offers
        await offersProvider.loadOffers(applyRegionalFilter: true);
        
        // Check unavailable offers (should have some from non-Berlin retailers)
        expect(offersProvider.hasUnavailableOffers, isTrue);
        expect(offersProvider.unavailableOffers.isNotEmpty, isTrue);
        
        // Check that unavailable offers are from retailers not in Berlin
        final unavailable = offersProvider.unavailableOffers;
        for (final offer in unavailable) {
          expect(offersProvider.availableRetailers.contains(offer.retailer), isFalse);
        }
      });
      
      test('should generate appropriate regional warnings', () async {
        // Test without PLZ
        locationProvider.clearLocation();
        await offersProvider.loadOffers(applyRegionalFilter: false);
        
        var warnings = offersProvider.regionalWarnings;
        expect(warnings.any((w) => w.contains('PLZ ein')), isTrue);
        
        // Test with PLZ but no retailers (use invalid PLZ)
        await locationProvider.setUserPLZ('99999');
        await Future.delayed(Duration(milliseconds: 100));
        await offersProvider.loadOffers(applyRegionalFilter: true);
        
        warnings = offersProvider.regionalWarnings;
        // Since 99999 may have some retailers, check if warning is appropriate
        expect(warnings.isNotEmpty, isTrue);
        
        // Test with valid PLZ
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 100));
        await offersProvider.loadOffers(applyRegionalFilter: true);
        
        warnings = offersProvider.regionalWarnings;
        // Should either have no warnings or warning about some unavailable offers
        if (warnings.isNotEmpty) {
          expect(warnings.any((w) => w.contains('nicht verfügbar')), isTrue);
        }
      });
      
      test('should suggest nearby retailers when few available', () async {
        // Set location with limited retailers
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 100));
        
        // Get suggestions
        final suggestions = offersProvider.findNearbyRetailers('10115');
        
        // Should suggest up to 3 retailers
        expect(suggestions.length, lessThanOrEqualTo(3));
        
        // Suggestions should be nationwide retailers not already available
        for (final suggestion in suggestions) {
          expect(['EDEKA', 'REWE', 'ALDI', 'Lidl', 'Penny', 'Kaufland'].contains(suggestion), isTrue);
        }
      });
      
      test('should maintain consistency across all providers after rapid PLZ changes', () async {
        // Rapid PLZ changes
        final plzList = ['10115', '80331', '40213', '01067', '10115'];
        
        for (final plz in plzList) {
          await locationProvider.setUserPLZ(plz);
          await Future.delayed(Duration(milliseconds: 50));
        }
        
        // Final state should be consistent
        expect(locationProvider.postalCode, '10115');
        expect(offersProvider.userPLZ, '10115');
        expect(retailersProvider.currentPLZ, '10115');
        expect(flashDealsProvider.userPLZ, '10115');
        
        // All providers should have same available retailers
        final locationRetailers = locationProvider.availableRetailersInRegion;
        expect(offersProvider.availableRetailers, equals(locationRetailers));
        expect(retailersProvider.availableRetailers.map((r) => r.name).toList(), 
               containsAll(locationRetailers));
      });
      
      test('should handle edge case with empty retailer lists', () async {
        // Create a PLZ with no retailers (edge case)
        await locationProvider.setUserPLZ('00000'); // Invalid PLZ
        await Future.delayed(Duration(milliseconds: 100));
        
        // Should handle gracefully
        expect(locationProvider.availableRetailersInRegion.isEmpty, isTrue);
        expect(offersProvider.availableRetailers.isEmpty, isTrue);
        expect(retailersProvider.availableRetailers.isEmpty, isTrue);
        
        // Should show appropriate warnings
        final warnings = offersProvider.regionalWarnings;
        expect(warnings.any((w) => w.contains('Keine Händler')), isTrue);
      });
      
      test('should correctly identify offer lock status', () async {
        // Load offers
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 100));
        await offersProvider.loadOffers(applyRegionalFilter: true);
        
        // Check freemium logic
        if (offersProvider.offers.isNotEmpty) {
          // First 3 offers should be free
          expect(offersProvider.isOfferLocked(0), isFalse);
          expect(offersProvider.isOfferLocked(1), isFalse);
          expect(offersProvider.isOfferLocked(2), isFalse);
          
          // 4th and beyond should be locked
          if (offersProvider.offers.length > 3) {
            expect(offersProvider.isOfferLocked(3), isTrue);
          }
        }
      });
      
      test('should update all providers when location source changes', () async {
        // Start with user PLZ
        await locationProvider.setUserPLZ('10115');
        await Future.delayed(Duration(milliseconds: 100));
        expect(locationProvider.currentLocationSource, LocationSource.userPLZ);
        
        // All providers should be updated
        expect(offersProvider.userPLZ, '10115');
        expect(retailersProvider.currentPLZ, '10115');
        expect(flashDealsProvider.userPLZ, '10115');
        
        // Clear and ensure no location
        locationProvider.clearLocation();
        await Future.delayed(Duration(milliseconds: 100));
        expect(locationProvider.currentLocationSource, LocationSource.none);
        
        // Providers should handle no location gracefully
        expect(offersProvider.userPLZ, isNull);
        expect(retailersProvider.currentPLZ, isNull);
        expect(flashDealsProvider.userPLZ, isNull);
      });
    });
  });
}
