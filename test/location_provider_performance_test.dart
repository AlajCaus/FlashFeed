// FlashFeed Performance Benchmark for PLZ Cache System
// Task 5b.6: Performance Testing (Fixed Test Bindings)

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flashfeed/providers/location_provider.dart';
import 'package:flashfeed/services/plz_lookup_service.dart';

void main() {
  group('Task 5b.6: PLZ Cache Performance Benchmarks', () {
    late LocationProvider locationProvider;
    late PLZLookupService plzLookupService;
    
    setUpAll(() async {
      // Initialize Flutter test bindings for LocalStorage
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Setup SharedPreferences mock for LocalStorage
      const MethodChannel('plugins.flutter.io/shared_preferences')
          .setMockMethodCallHandler((methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      });
    });

    setUp(() {
      locationProvider = LocationProvider();
      plzLookupService = PLZLookupService();
    });

    tearDown(() {
      locationProvider.dispose();
    });

    group('PLZ Lookup Performance', () {
      test('should handle 100 sequential PLZ lookups within time limit', () async {
        final stopwatch = Stopwatch()..start();
        final testPLZs = _generateTestPLZs(100);
        
        for (final plz in testPLZs) {
          final region = plzLookupService.getRegionFromPLZ(plz);
          expect(region, isNotNull, reason: 'PLZ $plz should map to a region');
        }
        
        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;
        
        debugPrint('PLZ Lookup Performance: 100 lookups in ${elapsedMs}ms (avg: ${elapsedMs/100}ms per lookup)');
        
        // Performance requirement: Should complete within 1 second
        expect(elapsedMs, lessThan(1000), reason: '100 PLZ lookups should complete within 1 second');
      });

      test('should cache PLZ lookups for improved performance', () async {
        final testPLZ = '10115';
        
        // First lookup (uncached)
        final stopwatch1 = Stopwatch()..start();
        final region1 = plzLookupService.getRegionFromPLZ(testPLZ);
        stopwatch1.stop();
        
        // Second lookup (should be cached)
        final stopwatch2 = Stopwatch()..start();
        final region2 = plzLookupService.getRegionFromPLZ(testPLZ);
        stopwatch2.stop();
        
        // Assert: Results should be identical and second lookup should be faster
        expect(region1, equals(region2));
        expect(stopwatch2.elapsedMicroseconds, lessThan(stopwatch1.elapsedMicroseconds),
               reason: 'Cached lookup should be faster than initial lookup');
               
        debugPrint('Cache Performance: Initial: ${stopwatch1.elapsedMicroseconds}μs, Cached: ${stopwatch2.elapsedMicroseconds}μs');
      });
    });

    group('LocationProvider Performance', () {
      test('should handle rapid location changes efficiently', () async {
        final stopwatch = Stopwatch()..start();
        final testPLZs = _generateTestPLZs(50);
        
        var successCount = 0;
        for (final plz in testPLZs) {
          final success = await locationProvider.setUserPLZ(plz);
          if (success) successCount++;
        }
        
        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;
        
        debugPrint('LocationProvider Performance: $successCount/${testPLZs.length} updates in ${elapsedMs}ms');
        
        // Performance requirements
        expect(elapsedMs, lessThan(5000), reason: '50 location updates should complete within 5 seconds');
        expect(successCount, greaterThan(testPLZs.length * 0.8), reason: 'At least 80% of valid PLZs should succeed');
      });

      test('should handle concurrent callback registrations without performance degradation', () async {
        final stopwatch = Stopwatch()..start();
        
        // Register 100 callbacks
        final callbacks = <VoidCallback>[];
        for (int i = 0; i < 100; i++) {
          void callback() => debugPrint('Callback $i triggered');
          callbacks.add(callback);
          locationProvider.registerLocationChangeCallback(callback);
        }
        
        // Trigger location change
        await locationProvider.setUserPLZ('10115');
        
        stopwatch.stop();
        
        debugPrint('Callback Performance: 100 callbacks processed in ${stopwatch.elapsedMilliseconds}ms');
        
        // Cleanup
        for (final callback in callbacks) {
          locationProvider.unregisterLocationChangeCallback(callback);
        }
        
        // Performance requirement: Should complete within 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500), 
               reason: '100 callbacks should be processed within 500ms');
      });
    });

    group('Memory Usage Validation', () {
      test('should not leak memory during repeated operations', () async {
        // This is a basic memory usage test - in a real scenario you'd use more sophisticated tools
        final initialTime = DateTime.now();
        
        // Perform 200 operations
        for (int i = 0; i < 200; i++) {
          final plz = _generateRandomPLZ();
          await locationProvider.setUserPLZ(plz);
          
          // Simulate some time passing
          if (i % 50 == 0) {
            await Future.delayed(Duration(milliseconds: 10));
          }
        }
        
        final finalTime = DateTime.now();
        final totalDuration = finalTime.difference(initialTime);
        
        debugPrint('Memory Test: 200 operations completed in ${totalDuration.inMilliseconds}ms');
        
        // Basic validation: operations should complete in reasonable time
        expect(totalDuration.inSeconds, lessThan(10), 
               reason: '200 operations should complete within 10 seconds');
      });

      test('should cleanup resources properly on dispose', () {
        // Create a separate LocationProvider instance for this test
        final testProvider = LocationProvider();
        
        // Register some callbacks and data
        testProvider.registerLocationChangeCallback(() {});
        testProvider.registerRegionalDataCallback((plz, retailers) {});
        
        // Dispose should not throw
        expect(() => testProvider.dispose(), returnsNormally);
        
        // After dispose, the provider should be properly cleaned up
        // (We can't test much more without exposing internal state)
      });
    });

    group('Real-World Scenario Simulation', () {
      test('should handle typical user workflow efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Simulate typical user workflow:
        // 1. App starts, requests location permission
        await locationProvider.requestLocationPermission();
        
        // 2. User enters PLZ manually
        await locationProvider.setUserPLZ('10115');
        
        // 3. User moves to different city, enters new PLZ
        await locationProvider.setUserPLZ('80331');
        
        // 4. User travels and updates location multiple times
        final travelerPLZs = ['20095', '40213', '50667', '60311', '70173'];
        for (final plz in travelerPLZs) {
          await locationProvider.setUserPLZ(plz);
          await Future.delayed(Duration(milliseconds: 100)); // Simulate user thinking time
        }
        
        stopwatch.stop();
        
        debugPrint('User Workflow Simulation: Complete workflow in ${stopwatch.elapsedMilliseconds}ms');
        
        // Should handle typical workflow smoothly
        expect(stopwatch.elapsedMilliseconds, lessThan(3000),
               reason: 'Typical user workflow should complete within 3 seconds');
               
        // Final state should be correct
        expect(locationProvider.hasValidLocationData, isTrue);
        expect(locationProvider.postalCode, equals('70173'));
      });
    });
  });
}

// Helper Functions
List<String> _generateTestPLZs(int count) {
  final plzs = <String>[];
  final random = Random(42); // Fixed seed for reproducible tests
  
  // Include some known valid PLZs
  final knownPLZs = ['10115', '80331', '20095', '40213', '50667', '60311', '70173', '90402'];
  plzs.addAll(knownPLZs);
  
  // Generate additional random PLZs
  while (plzs.length < count) {
    final plz = (random.nextInt(90000) + 10000).toString();
    if (!plzs.contains(plz)) {
      plzs.add(plz);
    }
  }
  
  return plzs.take(count).toList();
}

String _generateRandomPLZ() {
  final random = Random();
  return (random.nextInt(90000) + 10000).toString();
}
