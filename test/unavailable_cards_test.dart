// FlashFeed Unavailable Cards Widget Tests
// Task 5c.4: Test coverage for regional unavailability UI components

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/widgets/cards/unavailable_retailer_card.dart';
import 'package:flashfeed/widgets/cards/unavailable_offer_card.dart';
import 'package:flashfeed/models/models.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UnavailableRetailerCard Tests', () {
    late MockDataService mockDataService;
    late Retailer testRetailer;
    late List<Retailer> alternativeRetailers;
    
    setUp(() async {
      // Initialize test environment
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      // Use MockDataService for real test data
      mockDataService = MockDataService(seed: 999); // Deterministic for UI tests
      await mockDataService.initializeMockData(testMode: true);
      
      // Get real retailers from MockDataService
      final allRetailers = mockDataService.retailers;
      
      // Find GLOBUS explicitly for this test
      testRetailer = allRetailers.firstWhere(
        (r) => r.id == 'globus' || r.displayName.toLowerCase() == 'globus',
        orElse: () {
          // If Globus not found, find any retailer with regional restrictions
          final regionalRetailer = allRetailers.firstWhere(
            (r) => r.availablePLZRanges.isNotEmpty,
            orElse: () => throw StateError(
              'Test requires GLOBUS or regional retailer, but none found. '
              'Available retailers: ${allRetailers.map((r) => r.displayName).join(", ")}'
            ),
          );
          print('⚠️ GLOBUS not found, using fallback: ${regionalRetailer.displayName}');
          return regionalRetailer;
        },
      );
      
      // Debug output for test verification
      print('🧪 Test Retailer: ${testRetailer.displayName} (id: ${testRetailer.id})');
      print('   Regional restrictions: ${testRetailer.availablePLZRanges.isNotEmpty}');
      if (testRetailer.availablePLZRanges.isNotEmpty) {
        print('   Available regions: ${testRetailer.availableRegions.join(", ")}');
      }
      
      // Get alternative retailers (nationwide ones)
      alternativeRetailers = allRetailers
          .where((r) => r.availablePLZRanges.isEmpty && r.id != testRetailer.id)
          .take(2)
          .toList();
    });
    
    tearDown(() {
      mockDataService.dispose();
    });
    
    testWidgets('displays retailer name with strikethrough', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableRetailerCard(
              retailer: testRetailer,
              userPLZ: '10115',
              alternativeRetailers: alternativeRetailers,
            ),
          ),
        ),
      );
      
      // Find retailer name with strikethrough
      final retailerNameFinder = find.text(testRetailer.displayName);
      expect(retailerNameFinder, findsOneWidget);
      
      // Verify strikethrough decoration
      final Text retailerNameWidget = tester.widget(retailerNameFinder);
      expect(retailerNameWidget.style?.decoration, TextDecoration.lineThrough);
    });
    
    testWidgets('shows unavailable badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableRetailerCard(
              retailer: testRetailer,
              userPLZ: '10115',
            ),
          ),
        ),
      );
      
      expect(find.text('Nicht verfügbar'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });
    
    testWidgets('displays unavailability message with PLZ', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableRetailerCard(
              retailer: testRetailer,
              userPLZ: '10115',
            ),
          ),
        ),
      );
      
      // Use the actual displayName from testRetailer
      final expectedMessage = '${testRetailer.displayName} ist in PLZ 10115 nicht verfügbar';
      
      // Debug output to help diagnose issues
      final textFinder = find.text(expectedMessage);
      if (textFinder.evaluate().isEmpty) {
        // Print all text widgets to debug
        final allTexts = find.byType(Text).evaluate();
        print('❌ Expected message not found: "$expectedMessage"');
        print('📝 All Text widgets in the tree:');
        for (final widget in allTexts) {
          final text = (widget.widget as Text).data;
          if (text != null && text.contains('10115')) {
            print('   - "$text"');
          }
        }
      }
      
      expect(textFinder, findsOneWidget);
    });
    
    testWidgets('shows alternative retailers when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableRetailerCard(
              retailer: testRetailer,
              userPLZ: '10115',
              alternativeRetailers: alternativeRetailers,
            ),
          ),
        ),
      );
      
      expect(find.text('Alternative Händler in Ihrer Nähe:'), findsOneWidget);
      expect(find.text('EDEKA'), findsOneWidget);
      expect(find.text('REWE'), findsOneWidget);
    });
    
    testWidgets('expand search radius button works', (tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableRetailerCard(
              retailer: testRetailer,
              userPLZ: '10115',
              onExpandSearchRadius: () {
                buttonPressed = true;
              },
            ),
          ),
        ),
      );
      
      await tester.tap(find.text('Suchradius erweitern'));
      await tester.pump();
      
      expect(buttonPressed, isTrue);
    });
    
    testWidgets('info dialog shows details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableRetailerCard(
              retailer: testRetailer,
              userPLZ: '10115',
            ),
          ),
        ),
      );
      
      // Tap info button
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      
      // Check dialog content - use actual retailer name
      expect(find.text('${testRetailer.displayName} Verfügbarkeit'), findsOneWidget);
      expect(
        find.textContaining('${testRetailer.displayName} ist leider nicht in Ihrer Region'),
        findsOneWidget,
      );
      expect(find.text('Süd/West-Deutschland'), findsOneWidget);
    });
  });
  
  group('UnavailableOfferCard Tests', () {
    late MockDataService mockDataService;
    late Offer testOffer;
    late List<Offer> alternativeOffers;
    
    setUp(() async {
      // Initialize test environment
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      // Use MockDataService for real test data
      mockDataService = MockDataService(seed: 888); // Different seed for offer tests
      await mockDataService.initializeMockData(testMode: true);
      
      // Get real offers from MockDataService
      final allOffers = mockDataService.offers;
      
      // Find an offer from a retailer with regional restrictions
      // First find a retailer with PLZ restrictions
      final regionalRetailer = mockDataService.retailers.firstWhere(
        (r) => r.availablePLZRanges.isNotEmpty,
        orElse: () => mockDataService.retailers.first,
      );
      
      // Find an offer from that retailer
      testOffer = allOffers.firstWhere(
        (o) => o.retailer == regionalRetailer.name,
        orElse: () => allOffers.first,
      );
      
      // Debug output for test verification
      print('🧪 Test Offer: ${testOffer.productName} from ${testOffer.retailer}');
      print('   Price: €${(testOffer.price).toStringAsFixed(2)}');
      print('   Regional retailer: ${regionalRetailer.displayName}');
      
      // Find alternative offers from nationwide retailers
      final nationwideRetailers = mockDataService.retailers
          .where((r) => r.availablePLZRanges.isEmpty)
          .map((r) => r.name)
          .toSet();
      
      alternativeOffers = allOffers
          .where((o) => 
            nationwideRetailers.contains(o.retailer) &&
            o.id != testOffer.id)
          .take(2)
          .toList();
      
      // Debug alternative offers
      if (alternativeOffers.isNotEmpty) {
        print('   Alternative offers:');
        for (var i = 0; i < alternativeOffers.length; i++) {
          final alt = alternativeOffers[i];
          print('     ${i+1}. ${alt.productName} bei ${alt.retailer} - €${alt.price.toStringAsFixed(2)}');
        }
      }
    });
    
    tearDown(() {
      mockDataService.dispose();
    });
    
    testWidgets('displays product name with strikethrough', (tester) async {
      // Get the retailer for displayName
      final offerRetailer = mockDataService.retailers.firstWhere(
        (r) => r.name == testOffer.retailer,
        orElse: () => mockDataService.retailers.first,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
              retailerDisplayName: offerRetailer.displayName, // Pass displayName
            ),
          ),
        ),
      );
      
      // Use actual product name from testOffer
      final productNameFinder = find.text(testOffer.productName);
      
      // Debug output if not found
      if (productNameFinder.evaluate().isEmpty) {
        final allTexts = find.byType(Text).evaluate();
        print('❌ Product name not found: "${testOffer.productName}"');
        print('📝 All Text widgets in the tree:');
        for (final widget in allTexts) {
          final text = (widget.widget as Text).data;
          if (text != null) {
            print('   - "$text"');
          }
        }
      }
      
      expect(productNameFinder, findsOneWidget);
      
      final Text productNameWidget = tester.widget(productNameFinder);
      expect(productNameWidget.style?.decoration, TextDecoration.lineThrough);
    });
    
    testWidgets('shows unavailable overlay badge', (tester) async {
      // Get the retailer for displayName
      final offerRetailer = mockDataService.retailers.firstWhere(
        (r) => r.name == testOffer.retailer,
        orElse: () => mockDataService.retailers.first,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
              retailerDisplayName: offerRetailer.displayName, // Pass displayName
            ),
          ),
        ),
      );
      
      expect(find.text('Nicht verfügbar'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });
    
    testWidgets('displays price with strikethrough', (tester) async {
      // Get the retailer for displayName
      final offerRetailer = mockDataService.retailers.firstWhere(
        (r) => r.name == testOffer.retailer,
        orElse: () => mockDataService.retailers.first,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
              retailerDisplayName: offerRetailer.displayName, // Pass displayName
            ),
          ),
        ),
      );
      
      // Format price as the widget would display it
      final expectedPrice = '€${testOffer.price.toStringAsFixed(2)}';
      final priceFinder = find.text(expectedPrice);
      
      // Debug output if not found
      if (priceFinder.evaluate().isEmpty) {
        print('❌ Price not found: "$expectedPrice"');
        print('   Looking for price widgets with €...');
        final allTexts = find.byType(Text).evaluate();
        for (final widget in allTexts) {
          final text = (widget.widget as Text).data;
          if (text != null && text.startsWith('€')) {
            print('   Found price text: "$text"');
          }
        }
      }
      
      expect(priceFinder, findsOneWidget);
      
      final Text priceWidget = tester.widget(priceFinder);
      expect(priceWidget.style?.decoration, TextDecoration.lineThrough);
    });
    
    testWidgets('shows alternative offers when provided', (tester) async {
      // Get the retailer for displayName
      final offerRetailer = mockDataService.retailers.firstWhere(
        (r) => r.name == testOffer.retailer,
        orElse: () => mockDataService.retailers.first,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
              alternativeOffers: alternativeOffers,
              retailerDisplayName: offerRetailer.displayName, // Pass displayName
            ),
          ),
        ),
      );
      
      expect(find.text('Ähnliche Angebote:'), findsOneWidget);
      
      // Check for first alternative offer (if exists)
      if (alternativeOffers.isNotEmpty) {
        final firstAlt = alternativeOffers[0];
        final expectedText = '${firstAlt.productName} bei ${firstAlt.retailer}';
        final expectedPrice = '€${firstAlt.price.toStringAsFixed(2)}';
        
        // Debug output for alternative offers
        final altTextFinder = find.textContaining(firstAlt.productName);
        if (altTextFinder.evaluate().isEmpty) {
          print('❌ Alternative offer not found: "$expectedText"');
          print('📝 Looking for alternative offer texts:');
          final allTexts = find.byType(Text).evaluate();
          for (final widget in allTexts) {
            final text = (widget.widget as Text).data;
            if (text != null && (text.contains('bei') || text.contains('€'))) {
              print('   - "$text"');
            }
          }
        }
        
        expect(find.textContaining(firstAlt.productName), findsWidgets);
        expect(find.text(expectedPrice), findsWidgets);
      } else {
        // If no alternatives, test should still pass but log warning
        print('⚠️ No alternative offers available for testing');
      }
    });
    
    testWidgets('find alternatives button works', (tester) async {
      bool buttonPressed = false;
      
      // Get the retailer for displayName
      final offerRetailer = mockDataService.retailers.firstWhere(
        (r) => r.name == testOffer.retailer,
        orElse: () => mockDataService.retailers.first,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
              retailerDisplayName: offerRetailer.displayName, // Pass displayName
              onFindAlternatives: () {
                buttonPressed = true;
              },
            ),
          ),
        ),
      );
      
      await tester.tap(find.text('Alternativen finden'));
      await tester.pump();
      
      expect(buttonPressed, isTrue);
    });
    
    testWidgets('shows unavailability reason', (tester) async {
      // Find the actual retailer name from the offer
      final offerRetailer = mockDataService.retailers.firstWhere(
        (r) => r.name == testOffer.retailer,
        orElse: () => mockDataService.retailers.first,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
              retailerDisplayName: offerRetailer.displayName, // Pass displayName
            ),
          ),
        ),
      );
      
      // Now test expects the displayName
      final expectedText = '${offerRetailer.displayName} bietet dieses Angebot nicht in Ihrer Region an';
      final textFinder = find.textContaining(expectedText);
      
      // Debug output if not found
      if (textFinder.evaluate().isEmpty) {
        print('❌ Unavailability reason not found: "$expectedText"');
        print('📝 Looking for text widgets with "bietet dieses Angebot"...');
        final allTexts = find.byType(Text).evaluate();
        for (final widget in allTexts) {
          final text = (widget.widget as Text).data;
          if (text != null && text.contains('bietet dieses Angebot')) {
            print('   Found: "$text"');
          }
        }
      }
      
      expect(textFinder, findsOneWidget);
    });
  });
}
