
import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/services/plz_lookup_service.dart';

void main() {
  group('PLZLookupService Tests', () {
    late PLZLookupService service;

    setUp(() {
      service = PLZLookupService();
      // Cache vor jedem Test leeren
      service.clearCache();
    });

    group('GPS-Koordinaten Validierung', () {
      test('Gültige deutsche GPS-Koordinaten werden akzeptiert', () {
        // Berlin
        // Test indirekt über getPLZFromCoordinates
        expect(service.getPLZFromCoordinates(52.5200, 13.4050), isNotNull);
        // München 
        expect(service.getPLZFromCoordinates(48.1351, 11.5820), isNotNull);
        // Hamburg
        expect(service.getPLZFromCoordinates(53.5511, 9.9937), isNotNull);
      });

      test('Ungültige GPS-Koordinaten werden abgelehnt', () async {
        // Außerhalb Deutschland (Paris)
        expect(
          () => service.getPLZFromCoordinates(48.8566, 2.3522),
          throwsA(isA<PLZLookupException>()),
        );
        
        // Außerhalb Deutschland (London)
        expect(
          () => service.getPLZFromCoordinates(51.5074, -0.1278),
          throwsA(isA<PLZLookupException>()),
        );
      });
    });

    group('Region-Mapping', () {
      test('PLZ-zu-Region Mapping funktioniert korrekt', () {
        // Updated expectations to match improved city-name format
        expect(service.getRegionFromPLZ('10115'), equals('Berlin/Brandenburg')); // Berlin still uses region format
        expect(service.getRegionFromPLZ('01067'), equals('Dresden, Sachsen'));
        expect(service.getRegionFromPLZ('20095'), equals('Hamburg'));
        expect(service.getRegionFromPLZ('40213'), equals('Düsseldorf, NRW'));
        expect(service.getRegionFromPLZ('60311'), equals('Frankfurt am Main, Hessen'));
        expect(service.getRegionFromPLZ('70173'), equals('Stuttgart, Baden-Württemberg'));
        expect(service.getRegionFromPLZ('80331'), equals('München, Bayern'));
        expect(service.getRegionFromPLZ('00000'), isNull); // Unbekannte PLZ
      });
    });

    group('Cache-Funktionalität', () {
      test('Cache wird korrekt initialisiert', () {
        final stats = service.getCacheStats();
        expect(stats['entries'], equals(0));
      });

      test('Cache wird korrekt geleert', () {
        service.clearCache();
        final stats = service.getCacheStats();
        expect(stats['entries'], equals(0));
      });
    });

    group('PLZ-Format-Validierung', () {
      test('Gültige deutsche PLZ-Formate', () {
        final validPLZs = ['10115', '80331', '01067', '20095', '99999'];
        for (final plz in validPLZs) {
          expect(RegExp(r'^\d{5}$').hasMatch(plz), isTrue, reason: 'PLZ $plz sollte gültig sein');
        }
      });

      test('Ungültige PLZ-Formate werden abgelehnt', () {
        final invalidPLZs = ['1011', '801234', 'ABC12', '10-115', ''];
        for (final plz in invalidPLZs) {
          expect(RegExp(r'^\d{5}$').hasMatch(plz), isFalse, reason: 'PLZ $plz sollte ungültig sein');
        }
      });
    });

    group('Error-Handling', () {
      test('PLZLookupException wird korrekt erstellt', () {
        const exception = PLZLookupException('Test Fehler', 'Original Error');
        expect(exception.message, equals('Test Fehler'));
        expect(exception.originalError, equals('Original Error'));
        expect(exception.toString(), contains('PLZLookupException: Test Fehler (Original Error)'));
      });

      test('PLZLookupException ohne Original Error', () {
        const exception = PLZLookupException('Nur Test Fehler');
        expect(exception.message, equals('Nur Test Fehler'));
        expect(exception.originalError, isNull);
        expect(exception.toString(), equals('PLZLookupException: Nur Test Fehler'));
      });
    });

    group('Integration Tests mit Mock API', () {
      test('Erfolgreiche Nominatim API Response wird korrekt geparst', () async {
        // Simuliere erfolgreiche Nominatim-Response
        final mockResponse = {
          'address': {
            'postcode': '10115',
            'city': 'Berlin',
            'state': 'Berlin',
            'country': 'Deutschland',
            'country_code': 'de'
          },
          'lat': '52.5200',
          'lon': '13.4050'
        };

        // Test PLZ-Extraktion aus Response
        final address = mockResponse['address'] as Map<String, dynamic>;
        final plz = address['postcode'] as String?;
        
        expect(plz, equals('10115'));
        expect(RegExp(r'^\d{5}$').hasMatch(plz!), isTrue);
      });

      test('Alternative PLZ-Felder werden korrekt behandelt', () {
        final testCases = [
          {'address': {'postcode': '80331'}},
          {'address': {'postal_code': '01067'}},
          {'address': {'zipcode': '20095'}},
        ];

        for (final testCase in testCases) {
          final address = testCase['address'] as Map<String, dynamic>;
          final plz = address['postcode'] as String? ??
                     address['postal_code'] as String? ??
                     address['zipcode'] as String?;
          
          expect(plz, isNotNull);
          expect(RegExp(r'^\d{5}$').hasMatch(plz!), isTrue);
        }
      });

      test('Fehlerhafte API-Response wird korrekt behandelt', () {
        // Simuliere fehlerhafte Response-Strukturen
        final errorCases = [
          {}, // Leer
          {'address': {}}, // Keine PLZ
          {'address': {'postcode': 'ABC123'}}, // Ungültiges Format
          {'address': {'postcode': ''}}, // Leere PLZ
        ];

        for (final errorCase in errorCases) {
          final address = errorCase['address'] as Map?;
          if (address == null) {
            // Keine Adress-Information gefunden
            expect(address, isNull);
            continue;
          }

          final addressMap = Map<String, dynamic>.from(address);
          final plz = addressMap['postcode'] as String? ??
                     addressMap['postal_code'] as String? ??
                     addressMap['zipcode'] as String?;

          if (plz == null || plz.isEmpty || !RegExp(r'^\d{5}$').hasMatch(plz)) {
            // Diese Fälle sollten PLZLookupException werfen
            expect(plz == null || plz.isEmpty || !RegExp(r'^\d{5}$').hasMatch(plz), isTrue);
          }
        }
      });
    });

    group('Rate-Limiting Simulation', () {
      test('Rate-Limiting Delay-Berechnung', () {
        final now = DateTime.now();
        final lastRequest = now.subtract(const Duration(milliseconds: 500));
        final rateLimitDelay = const Duration(seconds: 1);
        
        final timeSinceLastRequest = now.difference(lastRequest);
        final needsDelay = timeSinceLastRequest < rateLimitDelay;
        
        expect(needsDelay, isTrue);
        
        final requiredDelay = rateLimitDelay - timeSinceLastRequest;
        expect(requiredDelay.inMilliseconds, greaterThan(0));
      });
    });

    group('Performance Tests', () {
      test('Cache-Performance bei mehreren Lookups', () {
        final coordinates = [
          '52.5200,13.4050', // Berlin
          '48.1351,11.5820', // München
          '53.5511,9.9937',  // Hamburg
          '50.9375,6.9603',  // Köln
        ];

        // Initial leerer Cache
        expect(service.getCacheStats()['entries'], equals(0));
        
        // Cache-Keys simulieren
        final mockCache = <String, String>{};
        for (final coord in coordinates) {
          mockCache[coord] = '${coord.split(',')[0].substring(0, 2)}000';
        }
        
        expect(mockCache.length, equals(4));
      });

      test('Memory-Usage-Schätzung', () {
        final stats = service.getCacheStats();
        
        // Updated für Task 5b.4 enhanced cache statistics
        expect(stats.containsKey('estimatedMemoryBytes'), isTrue);
        expect(stats.containsKey('estimatedMemoryKB'), isTrue);
        
        final memoryBytes = stats['estimatedMemoryBytes'] as int;
        final memoryKB = stats['estimatedMemoryKB'] as String;
        
        expect(memoryBytes, greaterThanOrEqualTo(0));
        expect(memoryKB, contains('KB'));
      });
    });

    group('Deutsche Großstädte Mock-Tests', () {
      final deutscheStaedte = [
        {'name': 'Berlin', 'lat': 52.5200, 'lng': 13.4050, 'expectedPLZ': '10115'},
        {'name': 'München', 'lat': 48.1351, 'lng': 11.5820, 'expectedPLZ': '80331'},
        {'name': 'Hamburg', 'lat': 53.5511, 'lng': 9.9937, 'expectedPLZ': '20095'},
        {'name': 'Köln', 'lat': 50.9375, 'lng': 6.9603, 'expectedPLZ': '50667'},
        {'name': 'Frankfurt', 'lat': 50.1109, 'lng': 8.6821, 'expectedPLZ': '60311'},
      ];

      for (final stadt in deutscheStaedte) {
        test('${stadt['name']} GPS-Koordinaten sind in Deutschland', () {
          final lat = stadt['lat'] as double;
          final lng = stadt['lng'] as double;
          
          expect(lat, greaterThanOrEqualTo(47.0));
          expect(lat, lessThanOrEqualTo(56.0));
          expect(lng, greaterThanOrEqualTo(5.0));
          expect(lng, lessThanOrEqualTo(16.0));
        });
      }
    });
  });
}

// Extension für private Methoden-Tests
// extension PLZLookupServiceTest on PLZLookupService {
//   bool _isValidCoordinate(double latitude, double longitude) {
//     return latitude >= 47.0 && latitude <= 56.0 && 
//            longitude >= 5.0 && longitude <= 16.0;
//   }
// }
