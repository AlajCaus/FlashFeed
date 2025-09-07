import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flashfeed/providers/location_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';

void main() {
  group('LocationProvider Core Tests', () {
    late LocationProvider locationProvider;
    late MockDataService testMockDataService;
    
    setUp(() async {
    // Task A.2: TestWidgetsFlutterBinding für LocalStorage-Support
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Task A.3: SharedPreferences Mock (eingebaut in shared_preferences package)
    SharedPreferences.setMockInitialValues({});
    
    // PATTERN aus todo.md verwenden - MockDataService Test-Mode
    testMockDataService = MockDataService();
    await testMockDataService.initializeMockData(testMode: true);
    locationProvider = LocationProvider();
  });
    
    tearDown(() {
      testMockDataService.dispose();
      locationProvider.dispose();
    });
    
    group('ensureLocationData() Fallback Chain', () {
      test('GPS success stops fallback chain', () async {
        // Arrange: GPS sollte erfolgreich sein (simuliert)
        expect(locationProvider.currentLocationSource, LocationSource.none);
        
        // Act: ensureLocationData ohne Context (nur GPS + Cache)
        final result = await locationProvider.ensureLocationData();
        
        // Assert: GPS erfolgreich, Fallback-Kette gestoppt
        expect(result, isTrue);
        expect(locationProvider.currentLocationSource, LocationSource.gps);
        expect(locationProvider.hasLocation, isTrue);
        expect(locationProvider.latitude, isNotNull);
        expect(locationProvider.longitude, isNotNull);
      });
      
      test('GPS failed uses cache if available', () async {
        // Arrange: Simuliere Cache-PLZ
        await locationProvider.setUserPLZ('10115', saveToCache: true);
        
        // Simuliere GPS-Fehler durch useGPS = false
        locationProvider.setUseGPS(false);
        locationProvider.clearLocation();
        
        // Act: ensureLocationData sollte Cache verwenden
        final result = await locationProvider.ensureLocationData();
        
        // Assert: Cache hit oder GPS fallback
        expect(result, isTrue);
        expect(locationProvider.hasValidLocationData, isTrue);
      });
      
      test('All fallbacks failed returns false', () async {
        // Arrange: GPS deaktiviert, kein Cache, kein Context
        locationProvider.setUseGPS(false);
        await locationProvider.clearPLZCache();
        
        // Act: ensureLocationData ohne Context (kein Dialog möglich)
        final result = await locationProvider.ensureLocationData();
        
        // Assert: Alle Fallbacks fehlgeschlagen
        expect(result, isFalse);
        expect(locationProvider.currentLocationSource, LocationSource.none);
        expect(locationProvider.locationError, isNotNull);
      });
      
      test('forceRefresh bypasses cache', () async {
        // Arrange: Cache mit PLZ vorhanden
        await locationProvider.setUserPLZ('80331', saveToCache: true);
        expect(locationProvider.currentLocationSource, LocationSource.userPLZ);
        
        // Act: forceRefresh sollte Cache ignorieren und GPS versuchen
        final result = await locationProvider.ensureLocationData(forceRefresh: true);
        
        // Assert: GPS wurde versucht (nicht Cache)
        expect(result, isTrue);
        expect(locationProvider.currentLocationSource, LocationSource.gps);
        expect(locationProvider.hasLocation, isTrue);
      });
    });
    
    group('LocationSource State Tracking', () {
      test('Initial state is LocationSource.none', () {
        expect(locationProvider.currentLocationSource, LocationSource.none);
        expect(locationProvider.hasValidLocationData, isFalse);
      });
      
      test('GPS success sets LocationSource.gps', () async {
        // Act: GPS-Lokalisierung simulieren
        await locationProvider.getCurrentLocation();
        
        // Assert: LocationSource korrekt gesetzt
        expect(locationProvider.currentLocationSource, LocationSource.gps);
        expect(locationProvider.hasLocation, isTrue);
      });
      
      test('Cache hit sets appropriate LocationSource', () async {
        // Arrange: PLZ in Cache speichern
        await locationProvider.setUserPLZ('10115', saveToCache: true);
        locationProvider.clearLocation();
        
        // Act: ensureLocationData mit Cache
        locationProvider.setUseGPS(false);
        await locationProvider.ensureLocationData();
        
        // Assert: LocationSource should indicate cached data was used
        expect(locationProvider.currentLocationSource, 
            anyOf([LocationSource.cachedPLZ, LocationSource.userPLZ]));
        expect(locationProvider.postalCode, equals('10115'));
      });
      
      test('User dialog sets LocationSource.userPLZ', () async {
        // Act: Manuelle PLZ-Eingabe simulieren
        final result = await locationProvider.setUserPLZ('20095');
        
        // Assert: LocationSource.userPLZ
        expect(result, isTrue);
        expect(locationProvider.currentLocationSource, LocationSource.userPLZ);
        expect(locationProvider.postalCode, equals('20095'));
      });
      
      test('State transitions work correctly', () async {
        // Test: none → userPLZ → gps
        
        // Initial: none
        expect(locationProvider.currentLocationSource, LocationSource.none);
        
        // Manual PLZ: none → userPLZ  
        await locationProvider.setUserPLZ('10115');
        expect(locationProvider.currentLocationSource, LocationSource.userPLZ);
        
        // GPS: userPLZ → gps
        await locationProvider.getCurrentLocation();
        expect(locationProvider.currentLocationSource, LocationSource.gps);
        
        // Location should be available after GPS call
        expect(locationProvider.hasLocation, isTrue);
      });
    });
    
    group('Error Chain Tests', () {
      test('GPS permission handling works', () async {
        // Arrange: GPS permission simuliert verweigert
        locationProvider.setUseGPS(true);
        
        // Cache mit gültiger PLZ vorhanden
        await locationProvider.setUserPLZ('10115', saveToCache: true);
        locationProvider.clearLocation();
        
        // Act: ensureLocationData mit GPS-"Fehler"
        final result = await locationProvider.ensureLocationData();
        
        // Assert: Fallback zu Cache oder GPS success
        expect(result, isTrue);
        expect(locationProvider.hasValidLocationData, isTrue);
      });
      
      test('Invalid PLZ handled gracefully', () async {
        // Act: Ungültige PLZ setzen
        final result = await locationProvider.setUserPLZ('INVALID');
        
        // Assert: Ungültige PLZ abgelehnt
        expect(result, isFalse);
        expect(locationProvider.locationError, contains('Ungültige PLZ'));
      });
      
      test('All error scenarios handled gracefully', () async {
        // GPS deaktiviert, kein Cache, kein Context
        locationProvider.setUseGPS(false);
        await locationProvider.clearPLZCache();
        
        final result = await locationProvider.ensureLocationData();
        
        // Assert: Fehler-Nachricht gesetzt, aber kein Crash
        expect(result, isFalse);
        expect(locationProvider.locationError, isNotNull);
        expect(locationProvider.isLoadingLocation, isFalse);
      });
    });
    
    group('PLZ-to-Coordinates Simulation', () {
      test('Berlin PLZ 10115 maps to correct coordinates', () async {
        await locationProvider.setUserPLZ('10115');
        
        // Assert: Berlin-Koordinaten (52.5200, 13.4050 ± Toleranz)
        expect(locationProvider.latitude, closeTo(52.5200, 0.1));
        expect(locationProvider.longitude, closeTo(13.4050, 0.1));
        expect(locationProvider.city, contains('Berlin'));
      });
      
      test('München PLZ 80331 maps to correct coordinates', () async {
        await locationProvider.setUserPLZ('80331');
        
        // Assert: München-Koordinaten (48.1351, 11.5820 ± Toleranz)
        expect(locationProvider.latitude, closeTo(48.1351, 0.1));
        expect(locationProvider.longitude, closeTo(11.5820, 0.1));
        expect(locationProvider.address, contains('München'));
      });
      
      test('Hamburg PLZ 20095 maps to correct coordinates', () async {
        await locationProvider.setUserPLZ('20095');
        
        // Assert: Hamburg-Koordinaten (53.5511, 9.9937 ± Toleranz)
        expect(locationProvider.latitude, closeTo(53.5511, 0.1));
        expect(locationProvider.longitude, closeTo(9.9937, 0.1));
      });
      
      test('Unknown PLZ uses default coordinates', () async {
        await locationProvider.setUserPLZ('99999'); // Unbekannte PLZ
        
        // Assert: Deutschland-Mitte als Fallback (51.1657, 10.4515)
        expect(locationProvider.latitude, closeTo(51.1657, 0.5));
        expect(locationProvider.longitude, closeTo(10.4515, 0.5));
      });
      
      test('PLZ region mapping works correctly', () async {
        await locationProvider.setUserPLZ('10115'); // Berlin
        expect(locationProvider.address, contains('Berlin'));
        
        await locationProvider.setUserPLZ('80331'); // München  
        expect(locationProvider.address, contains('München'));
        
        await locationProvider.setUserPLZ('20095'); // Hamburg
        expect(locationProvider.address, contains('Hamburg'));
      });
    });
    
    group('GPS Permission Tests', () {
      test('requestLocationPermission simulates permission grant', () async {
        // Create a test-specific provider with testMode to start with false permissions
        final testProvider = LocationProvider(testMode: true);
        
        // Initial state: no permission
        expect(testProvider.hasLocationPermission, isFalse);
        expect(testProvider.isLocationServiceEnabled, isFalse);
        
        // Act: Request permission
        await testProvider.requestLocationPermission();
        
        // Assert: Permission granted (simulated)
        expect(testProvider.hasLocationPermission, isTrue);
        expect(testProvider.isLocationServiceEnabled, isTrue);
        expect(testProvider.canUseLocation, isTrue);
        
        // Clean up
        testProvider.dispose();
      });
      
      test('getCurrentLocation works with permission', () async {
        // Arrange: Permission granted
        await locationProvider.requestLocationPermission();
        expect(locationProvider.canUseLocation, isTrue);
        
        // Act: Get current location
        await locationProvider.getCurrentLocation();
        
        // Assert: Location acquired
        expect(locationProvider.hasLocation, isTrue);
        expect(locationProvider.latitude, isNotNull);
        expect(locationProvider.longitude, isNotNull);
        expect(locationProvider.currentLocationSource, LocationSource.gps);
      });
      
      test('Location loading state managed correctly', () async {
        expect(locationProvider.isLoadingLocation, isFalse);
        
        // Start location request
        final future = locationProvider.getCurrentLocation();
        
        await future;
        
        // After completion
        expect(locationProvider.isLoadingLocation, isFalse);
      });
    });
    
    group('LocalStorage Integration', () {
      test('setUserPLZ saves to cache when saveToCache=true', () async {
        // Act: PLZ mit Cache speichern
        final result = await locationProvider.setUserPLZ('10115', saveToCache: true);
        
        // Assert: Erfolgreich gesetzt und gecacht
        expect(result, isTrue);
        expect(locationProvider.userPLZ, equals('10115'));
        expect(locationProvider.currentLocationSource, LocationSource.userPLZ);
      });
      
      test('setUserPLZ without cache flag still sets PLZ', () async {
        // Act: PLZ setzen (Standard-Parameter)
        final result = await locationProvider.setUserPLZ('80331');
        
        // Assert: PLZ erfolgreich gesetzt
        expect(result, isTrue);
        expect(locationProvider.userPLZ, equals('80331'));
        expect(locationProvider.postalCode, equals('80331'));
      });
      
      test('clearPLZCache removes cached PLZ', () async {
        // Arrange: PLZ cachen
        await locationProvider.setUserPLZ('10115', saveToCache: true);
        
        // Act: Cache löschen
        await locationProvider.clearPLZCache();
        
        // Assert: Cache-Inhalt gelöscht (indirekt über neuen ensureLocationData Test)
        locationProvider.setUseGPS(false);
        locationProvider.clearLocation();
        
        final result = await locationProvider.ensureLocationData();
        // Sollte false sein, da kein Cache vorhanden
        expect(result, isFalse);
      });
      
      test('PLZ validation rejects invalid formats', () async {
        final invalidPLZs = ['1234', '123456', 'ABCDE', '', '10-115'];
        
        for (final invalidPLZ in invalidPLZs) {
          final result = await locationProvider.setUserPLZ(invalidPLZ);
          expect(result, isFalse, reason: 'PLZ $invalidPLZ should be invalid');
        }
      });
      
      test('PLZ validation accepts valid formats', () async {
        final validPLZs = ['10115', '80331', '20095', '01067', '99999'];
        
        for (final validPLZ in validPLZs) {
          final result = await locationProvider.setUserPLZ(validPLZ);
          expect(result, isTrue, reason: 'PLZ $validPLZ should be valid');
          expect(locationProvider.postalCode, equals(validPLZ));
        }
      });
    });
    
    group('Location Summary and Utilities', () {
      test('locationSummary returns appropriate format', () async {
        // No location
        expect(locationProvider.locationSummary, equals('Kein Standort'));
        
        // With PLZ
        await locationProvider.setUserPLZ('10115');
        expect(locationProvider.locationSummary, anyOf([
          contains('PLZ: 10115'),
          contains('Berlin'),
          contains('10115')
        ]));
      });
      
      test('calculateDistance works correctly', () async {
        // Arrange: Set location to Berlin (52.5200, 13.4050)
        await locationProvider.getCurrentLocation(); // Sets Berlin coordinates
        
        // Act: Calculate distance to München (48.1351, 11.5820)
        final distance = locationProvider.calculateDistance(48.1351, 11.5820);
        
        // Assert: ~500km distance Berlin-München
        expect(distance, greaterThan(400));
        expect(distance, lessThan(700));
      });
      
      test('isWithinRadius works correctly', () async {
        await locationProvider.getCurrentLocation(); // Berlin coordinates
        
        // Close location (Berlin Alexanderplatz: 52.5219, 13.4132)
        expect(locationProvider.isWithinRadius(52.5219, 13.4132), isTrue);
        
        // Far location (München)
        expect(locationProvider.isWithinRadius(48.1351, 11.5820), isFalse);
      });
      
      test('setSearchRadius updates radius correctly', () {
        expect(locationProvider.searchRadiusKm, equals(10.0)); // Default
        
        locationProvider.setSearchRadius(25.0);
        expect(locationProvider.searchRadiusKm, equals(25.0));
        
        // Test clamping
        locationProvider.setSearchRadius(100.0); // > 50km max
        expect(locationProvider.searchRadiusKm, equals(50.0));
        
        locationProvider.setSearchRadius(0.5); // < 1km min  
        expect(locationProvider.searchRadiusKm, equals(1.0));
      });
    });
  });
}
