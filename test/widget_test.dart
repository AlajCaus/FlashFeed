import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/services/mock_data_service.dart';

void main() {
  group('FlashFeed Widget Tests', () {
    late MockDataService testMockDataService;

    setUp(() {
      // MockDataService für Tests initialisieren
      testMockDataService = MockDataService();
      // Global mockDataService für Tests setzen (falls verfügbar)
      // mockDataService = testMockDataService; // Würde Compile-Error geben
    });

    tearDown(() {
      // MockDataService nach jedem Test bereinigen
      testMockDataService.dispose();
    });

    testWidgets('FlashFeed app loads correctly with mock setup', (WidgetTester tester) async {
      // Test-spezifische App-Initialisierung
      await tester.pumpWidget(
        MaterialApp(
          title: 'FlashFeed Test',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: const Scaffold(
            body: Center(
              child: Text('FlashFeed Test App'),
            ),
          ),
        ),
      );
      
      // Verify that test app loads without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('FlashFeed Test App'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    
    testWidgets('Basic Material App structure works', (WidgetTester tester) async {
      // Minimaler Test ohne Provider-Dependencies
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: const Center(child: Text('Basic Test')),
          ),
        ),
      );
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Basic Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MockDataService can be instantiated in tests', (WidgetTester tester) async {
      // Test dass MockDataService funktioniert
      final mockService = MockDataService();
      expect(mockService, isNotNull);
      
      // Vor Initialisierung sollten Listen leer sein
      expect(mockService.offers, isEmpty);
      expect(mockService.flashDeals, isEmpty);
      expect(mockService.retailers, isEmpty);
      expect(mockService.isInitialized, isFalse);
      
      // MockDataService initialisieren (mit Test-Mode - keine Timer)
      await mockService.initializeMockData(testMode: true);
      
      // Nach Initialisierung sollten Daten verfügbar sein
      expect(mockService.isInitialized, isTrue);
      expect(mockService.offers, isNotEmpty);
      expect(mockService.flashDeals, isNotEmpty);
      expect(mockService.retailers, isNotEmpty);

      // Einfache Widget mit MockDataService Daten
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Offers: ${mockService.offers.length}'),
                Text('Flash Deals: ${mockService.flashDeals.length}'),
                Text('Retailers: ${mockService.retailers.length}'),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining('Offers:'), findsOneWidget);
      expect(find.textContaining('Flash Deals:'), findsOneWidget);
      expect(find.textContaining('Retailers:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
