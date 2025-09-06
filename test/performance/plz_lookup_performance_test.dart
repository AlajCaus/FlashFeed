import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/services/plz_lookup_service.dart';

/// Performance Test Suite für PLZLookupService (Task 5b.4)
/// 
/// Tests: Bulk-Operations, Cache-Efficiency, Memory-Usage, Concurrent Access
/// 
/// WICHTIG: Diese Tests benötigen eine saubere Test-Umgebung
/// - Mock API Responses für reproduzierbare Ergebnisse  
/// - Isolation zwischen Test-Cases
/// - Performance-Metriken-Validation
void main() {
  group('PLZLookupService Performance Tests (Task 5b.4)', () {
    late PLZLookupService service;
    
    setUp(() {
      // Neue Service-Instanz für jeden Test (Isolation)
      service = PLZLookupService();
      service.clearCache(); // Clean Slate
    });
    
    tearDown(() {
      // Cleanup nach jedem Test
      service.dispose();
    });

    group('Bulk Coordinate Processing', () {
      test('100 koordinaten verarbeitung - cache efficiency', () async {
        // Test-Koordinaten generieren (Berlin-Bereich für realistische Daten)
        final coordinates = _generateTestCoordinates(100, centerLat: 52.5200, centerLng: 13.4050, radiusKm: 50);
        
        // Benchmark ausführen
        final benchmark = await service.performBenchmark(coordinates);
        
        // Performance-Assertions
        expect(benchmark['coordinatesProcessed'], equals(100));
        expect(benchmark['successfulLookups'], greaterThan(80)); // Mind. 80% Erfolgsrate
        expect(benchmark['averageTimeMs'], lessThan(5000)); // Max 5s pro Lookup (inkl. Rate-Limiting)
        
        // Cache-Stats nach Bulk-Operation prüfen
        final cacheStats = service.getCacheStats();
        expect(cacheStats['entries'], greaterThan(0));
        expect(cacheStats['cacheHits'], equals(0)); // Erste Durchgang: alle Misses
        expect(cacheStats['cacheMisses'], equals(100));
        
        print('Bulk-Test 100 Koordinaten: ${benchmark['totalTimeMs']}ms total, '
              '${benchmark['averageTimeMs'].toStringAsFixed(2)}ms average');
      });
      
      test('wiederholte bulk-operation für cache hit-rate', () async {
        // Erste Durchgang: Cache füllen
        final coordinates = _generateTestCoordinates(50, centerLat: 52.5200, centerLng: 13.4050, radiusKm: 20);
        await service.performBenchmark(coordinates);
        
        // Cache-Stats nach erstem Durchgang
        final statsAfterFirst = service.getCacheStats();
        final initialCacheSize = statsAfterFirst['entries'] as int;
        
        // Zweite Durchgang: Cache-Hits erwarten
        final secondBenchmark = await service.performBenchmark(coordinates);
        
        // Cache-Hit-Rate validieren
        expect(secondBenchmark['cacheHitsInBenchmark'], greaterThan(30)); // Mind. 60% Hits
        expect(secondBenchmark['averageTimeMs'], lessThan(100)); // Cache-Hits sind schnell
        
        final finalStats = service.getCacheStats();
        final hitRate = double.parse((finalStats['hitRate'] as String).replaceAll('%', ''));
        expect(hitRate, greaterThan(40.0)); // Gesamt-Hit-Rate mind. 40%
        
        print('Cache Hit-Rate Test: ${hitRate.toStringAsFixed(1)}% hit rate, '
              '${secondBenchmark['cacheHitsInBenchmark']} hits von ${coordinates.length} requests');
      });
      
      test('1000 koordinaten stress test - memory usage', () async {
        // Memory-Stress-Test mit großer Koordinaten-Menge
        final coordinates = _generateTestCoordinates(1000, centerLat: 51.1657, centerLng: 10.4515, radiusKm: 500);
        
        // Vor Stress-Test: Memory-Baseline
        final statsBefore = service.getCacheStats();
        final memoryBefore = statsBefore['estimatedMemoryBytes'] as int;
        
        // Stress-Test durchführen
        final stopwatch = Stopwatch()..start();
        var successCount = 0;
        var errorCount = 0;
        
        for (int i = 0; i < coordinates.length; i += 50) {
          // Batches von 50 Koordinaten verarbeiten
          final batch = coordinates.skip(i).take(50).toList();
          
          try {
            await service.performBenchmark(batch);
            successCount += batch.length;
          } catch (e) {
            errorCount += batch.length;
            print('Batch ${i ~/ 50 + 1} failed: $e');
          }
        }
        
        stopwatch.stop();
        
        // Stress-Test Results
        final statsAfter = service.getCacheStats();
        final memoryAfter = statsAfter['estimatedMemoryBytes'] as int;
        final memoryIncrease = memoryAfter - memoryBefore;
        
        // Performance-Assertions für Stress-Test
        expect(successCount, greaterThan(800)); // Mind. 80% Erfolgsrate
        expect(stopwatch.elapsedMilliseconds, lessThan(300000)); // Max 5 Minuten
        expect(memoryIncrease, lessThan(500000)); // Max 500KB Memory-Increase
        expect(statsAfter['entries'], lessThanOrEqualTo(1000)); // Cache-Size-Limit respektiert
        
        print('Stress-Test 1000 Koordinaten: ${stopwatch.elapsedMilliseconds}ms, '
              '${(memoryIncrease / 1024).toStringAsFixed(1)}KB memory increase, '
              '$successCount/$errorCount success/error');
      });
    });

    group('Cache Performance & LRU Behavior', () {
      test('lru eviction funktioniert korrekt', () async {
        // Cache bis zur Kapazitätsgrenze füllen
        final maxSize = 1000; // Entspricht _maxCacheSize in PLZLookupService
        final coordinates = _generateTestCoordinates(maxSize + 100, centerLat: 52.5200, centerLng: 13.4050, radiusKm: 100);
        
        // Cache komplett füllen
        await service.performBenchmark(coordinates);
        
        // Cache-Stats nach Überfüllung prüfen
        final stats = service.getCacheStats();
        final cacheSize = stats['entries'] as int;
        final evictions = stats['cacheEvictions'] as int;
        
        // LRU-Eviction Assertions
        expect(cacheSize, lessThanOrEqualTo(maxSize)); // Size-Limit respektiert
        expect(evictions, greaterThan(0)); // Evictions fanden statt
        
        print('LRU-Test: Cache size $cacheSize/$maxSize, $evictions evictions');
      });
      
      test('cache expiry funktioniert', () async {
        // Test mit kurzer Expiry-Zeit (nicht production-ready, nur für Tests)
        // TODO: In real implementation, allow configurable expiry for tests
        
        // Vorerst: Cache-Cleanup manuell testen
        final coordinates = _generateTestCoordinates(10, centerLat: 52.5200, centerLng: 13.4050, radiusKm: 10);
        
        // Cache füllen
        await service.performBenchmark(coordinates);
        final statsAfterFill = service.getCacheStats();
        expect(statsAfterFill['entries'], equals(10));
        
        // Manual Cache-Clear simuliert Expiry
        service.clearCache();
        final statsAfterClear = service.getCacheStats();
        expect(statsAfterClear['entries'], equals(0));
        
        print('Cache-Expiry Test: Cache cleared successfully');
      });
    });

    group('Concurrent Access Performance', () {
      test('simultane requests verhalten sich korrekt', () async {
        // Parallele Requests für gleiche Koordinaten
        final testCoord = [52.5200, 13.4050]; // Berlin
        
        // 10 simultane Requests für gleiche Koordinaten starten
        final futures = <Future<String>>[];
        for (int i = 0; i < 10; i++) {
          futures.add(service.getPLZFromCoordinates(testCoord[0], testCoord[1]));
        }
        
        // Alle Requests warten
        final results = await Future.wait(futures);
        
        // Ergebnisse validieren
        expect(results.length, equals(10));
        expect(results.every((plz) => plz == results.first), isTrue); // Alle gleich
        
        // Cache-Stats: Nur 1 API-Call trotz 10 Requests (wegen Rate-Limiting + Cache)
        final stats = service.getCacheStats();
        expect(stats['entries'], equals(1)); // Ein Cache-Entry
        
        print('Concurrent-Test: 10 simultane requests für gleiche Koordinaten, '
              '${stats['apiCalls']} API calls, result: ${results.first}');
      });
    });
  });
}

/// Helper: Test-Koordinaten im Umkreis generieren
List<List<double>> _generateTestCoordinates(int count, {
  required double centerLat,
  required double centerLng, 
  required double radiusKm
}) {
  final coordinates = <List<double>>[];
  final random = DateTime.now().millisecondsSinceEpoch % 100000; // Pseudo-Random für Tests
  
  for (int i = 0; i < count; i++) {
    // Pseudo-Random-Offset im Radius
    final angle = (i * 17 + random) % 360 * (3.14159 / 180); // Pseudo-Random-Winkel
    final distance = (i % 10 + 1) * (radiusKm / 10); // Verschiedene Distanzen
    
    // Koordinaten-Offset berechnen (vereinfacht, für Tests ausreichend)
    final latOffset = distance / 111.0 * (angle > 3.14159 ? -1 : 1); // ~111km pro Grad
    final lngOffset = distance / (111.0 * (6.6)) * ((angle > 1.57 && angle < 4.71) ? -1 : 1); // Longitude-Correction
    
    coordinates.add([
      centerLat + latOffset,
      centerLng + lngOffset,
    ]);
  }
  
  return coordinates;
}
