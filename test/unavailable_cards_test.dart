// FlashFeed Unavailable Cards Widget Tests
// Task 5c.4: Test coverage for regional unavailability UI components

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/widgets/cards/unavailable_retailer_card.dart';
import 'package:flashfeed/widgets/cards/unavailable_offer_card.dart';
import 'package:flashfeed/models/models.dart';

void main() {
  group('UnavailableRetailerCard Tests', () {
    late Retailer testRetailer;
    late List<Retailer> alternativeRetailers;
    
    setUp(() {
      // Create test retailer that's not available
      testRetailer = Retailer(
        id: 'globus',
        name: 'Globus',
        displayName: 'Globus',
        iconUrl: 'https://example.com/globus.png',
        primaryColor: '#FF0000',
        availablePLZRanges: [
          PLZRange(
            startPLZ: '50000',
            endPLZ: '99999',
            regionName: 'Süd/West-Deutschland',
          ),
        ],
      );
      
      // Create alternative retailers
      alternativeRetailers = [
        Retailer(
          id: 'edeka',
          name: 'EDEKA',
          displayName: 'EDEKA',
          iconUrl: 'https://example.com/edeka.png',
          primaryColor: '#0000FF',
          availablePLZRanges: [], // Nationwide
        ),
        Retailer(
          id: 'rewe',
          name: 'REWE',
          displayName: 'REWE',
          iconUrl: 'https://example.com/rewe.png',
          primaryColor: '#FF0000',
          availablePLZRanges: [], // Nationwide
        ),
      ];
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
      final retailerNameFinder = find.text('Globus');
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
      
      expect(
        find.text('Globus ist in PLZ 10115 nicht verfügbar'),
        findsOneWidget,
      );
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
      
      // Check dialog content
      expect(find.text('Globus Verfügbarkeit'), findsOneWidget);
      expect(
        find.textContaining('Globus ist leider nicht in Ihrer Region'),
        findsOneWidget,
      );
      expect(find.text('Süd/West-Deutschland'), findsOneWidget);
    });
  });
  
  group('UnavailableOfferCard Tests', () {
    late Offer testOffer;
    late List<Offer> alternativeOffers;
    
    setUp(() {
      // Create test offer that's not available
      testOffer = Offer(
        id: 'offer1',
        productName: 'Bio Milch 1L',
        retailer: 'Globus',
        price: 1.49,
        originalPrice: 1.79,
        originalCategory: 'Molkereiprodukte',
        validUntil: DateTime.now().add(const Duration(days: 7)),
      );
      
      // Create alternative offers
      alternativeOffers = [
        Offer(
          id: 'offer2',
          productName: 'Frische Vollmilch 1L',
          retailer: 'EDEKA',
          price: 1.39,
          originalPrice: 1.59,
          originalCategory: 'Molkereiprodukte',
          validUntil: DateTime.now().add(const Duration(days: 7)),
        ),
        Offer(
          id: 'offer3',
          productName: 'H-Milch 1L',
          retailer: 'REWE',
          price: 1.29,
          originalPrice: 1.49,
          originalCategory: 'Molkereiprodukte',
          validUntil: DateTime.now().add(const Duration(days: 7)),
        ),
      ];
    });
    
    testWidgets('displays product name with strikethrough', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
            ),
          ),
        ),
      );
      
      final productNameFinder = find.text('Bio Milch 1L');
      expect(productNameFinder, findsOneWidget);
      
      final Text productNameWidget = tester.widget(productNameFinder);
      expect(productNameWidget.style?.decoration, TextDecoration.lineThrough);
    });
    
    testWidgets('shows unavailable overlay badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
            ),
          ),
        ),
      );
      
      expect(find.text('Nicht verfügbar'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });
    
    testWidgets('displays price with strikethrough', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
            ),
          ),
        ),
      );
      
      final priceFinder = find.text('€1.49');
      expect(priceFinder, findsOneWidget);
      
      final Text priceWidget = tester.widget(priceFinder);
      expect(priceWidget.style?.decoration, TextDecoration.lineThrough);
    });
    
    testWidgets('shows alternative offers when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
              alternativeOffers: alternativeOffers,
            ),
          ),
        ),
      );
      
      expect(find.text('Ähnliche Angebote:'), findsOneWidget);
      expect(find.textContaining('Frische Vollmilch 1L bei EDEKA'), findsOneWidget);
      expect(find.text('€1.39'), findsOneWidget);
    });
    
    testWidgets('find alternatives button works', (tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
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
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnavailableOfferCard(
              offer: testOffer,
              userPLZ: '10115',
            ),
          ),
        ),
      );
      
      expect(
        find.textContaining('Globus bietet dieses Angebot nicht in Ihrer Region an'),
        findsOneWidget,
      );
    });
  });
}
