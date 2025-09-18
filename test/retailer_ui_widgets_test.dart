// Test für Task 11.6: UI Widgets für Retailer Management
// Testet die Integration der neuen RetailersProvider Methoden mit den UI Widgets

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flashfeed/providers/retailers_provider.dart';
import 'package:flashfeed/repositories/mock_retailers_repository.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/widgets/retailer_logo.dart';
import 'package:flashfeed/widgets/retailer_selector.dart';
import 'package:flashfeed/widgets/retailer_availability_card.dart';
import 'package:flashfeed/widgets/store_search_bar.dart';

void main() {
  late MockDataService mockDataService;
  late RetailersProvider retailersProvider;
  
  setUp(() async {
    // Initialize services
    mockDataService = MockDataService();
    await mockDataService.initializeMockData(testMode: true);
    
    // Create provider
    retailersProvider = RetailersProvider(
      repository: MockRetailersRepository(testService: mockDataService),
      mockDataService: mockDataService,
    );
    
    // Load initial data
    await retailersProvider.loadRetailers();
    
    // Set user location for testing
    retailersProvider.updateUserLocation('10115'); // Berlin PLZ
  });
  
  tearDown(() {
    mockDataService.dispose();
    retailersProvider.dispose();
  });
  
  group('Task 11.1 & 11.6: RetailersProvider UI Methods', () {
    test('getRetailerLogo returns correct logo URL', () {
      final edekaLogo = retailersProvider.getRetailerLogo('EDEKA');
      expect(edekaLogo, contains('Logo_Edeka'));
      
      final reweLogo = retailersProvider.getRetailerLogo('REWE');
      expect(reweLogo, contains('Logo_REWE'));
      
      // Test fallback for unknown retailer
      final unknownLogo = retailersProvider.getRetailerLogo('UNKNOWN');
      expect(unknownLogo, '/assets/images/default_retailer.png');
    });
    
    test('getRetailerBrandColors returns correct colors', () {
      final edekaColors = retailersProvider.getRetailerBrandColors('EDEKA');
      expect(edekaColors['primary'], const Color(0xFF005CA9)); // EDEKA Blau
      expect(edekaColors['accent'], const Color(0xFFFDB813));  // EDEKA Gelb
      
      final reweColors = retailersProvider.getRetailerBrandColors('REWE');
      expect(reweColors['primary'], const Color(0xFFCC071E)); // REWE Rot
      
      // Test fallback colors
      final unknownColors = retailersProvider.getRetailerBrandColors('UNKNOWN');
      expect(unknownColors['primary'], const Color(0xFF2E8B57)); // FlashFeed Green
    });
    
    test('getRetailerDisplayName returns correct display names', () {
      expect(retailersProvider.getRetailerDisplayName('ALDI'), 'ALDI SÜD');
      expect(retailersProvider.getRetailerDisplayName('NETTO'), 'Netto Marken-Discount');
      expect(retailersProvider.getRetailerDisplayName('REAL'), 'real');
      
      // Test fallback
      expect(retailersProvider.getRetailerDisplayName('UNKNOWN'), 'UNKNOWN');
    });
    
    test('isRetailerAvailable checks PLZ availability correctly', () {
      // Set Berlin PLZ
      retailersProvider.updateUserLocation('10115');
      
      // EDEKA is nationwide, should be available
      expect(retailersProvider.isRetailerAvailable('EDEKA'), isTrue);
      
      // BioCompany is only in Berlin/Brandenburg
      expect(retailersProvider.isRetailerAvailable('BIOCOMPANY'), isTrue);
      
      // Set Munich PLZ
      retailersProvider.updateUserLocation('80331');
      
      // EDEKA still available (nationwide)
      expect(retailersProvider.isRetailerAvailable('EDEKA'), isTrue);
      
      // BioCompany not available in Munich
      expect(retailersProvider.isRetailerAvailable('BIOCOMPANY'), isFalse);
    });
    
    test('getRetailerDetails returns correct retailer object', () {
      final edeka = retailersProvider.getRetailerDetails('EDEKA');
      expect(edeka, isNotNull);
      expect(edeka?.name, 'EDEKA');
      expect(edeka?.displayName, 'EDEKA');
      expect(edeka?.isNationwide, isTrue);
      
      // Test caching
      final edeka2 = retailersProvider.getRetailerDetails('EDEKA');
      expect(identical(edeka, edeka2), isTrue); // Should be same cached object
      
      // Test null for unknown retailer
      final unknown = retailersProvider.getRetailerDetails('UNKNOWN');
      expect(unknown, isNull);
    });
    
    test('getRetailerBranding returns complete branding info', () {
      final branding = retailersProvider.getRetailerBranding('EDEKA');
      
      expect(branding['logo'], contains('Logo_Edeka'));
      expect(branding['colors'], isA<Map<String, Color>>());
      expect(branding['displayName'], 'EDEKA');
      expect(branding['isAvailable'], isA<bool>());
      
      // Check that all keys are present
      expect(branding.keys.toSet(), {'logo', 'colors', 'displayName', 'isAvailable'});
    });
  });
  
  group('Widget Integration Tests', () {
    testWidgets('RetailerLogo widget uses provider data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: const Scaffold(
              body: RetailerLogo(
                retailerName: 'EDEKA',
                size: LogoSize.medium,
              ),
            ),
          ),
        ),
      );
      
      // Widget should render
      expect(find.byType(RetailerLogo), findsOneWidget);
      
      // Should have container with correct size
      final container = find.byType(Container).first;
      expect(container, findsOneWidget);
    });
    
    testWidgets('RetailerSelector widget shows available retailers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: Scaffold(
              body: RetailerSelector(
                onSelectionChanged: (selected) {},
                showOnlyAvailable: true,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show filter bar
      expect(find.text('Filter:'), findsOneWidget);
      expect(find.text('Nur verfügbare'), findsOneWidget);
      
      // Should show PLZ
      expect(find.text('PLZ: 10115'), findsOneWidget);
    });
    
    testWidgets('RetailerAvailabilityCard shows availability info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: const Scaffold(
              body: RetailerAvailabilityCard(
                retailerName: 'EDEKA',
                userPLZ: '10115',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show retailer name
      expect(find.text('EDEKA'), findsOneWidget);
      
      // Should show availability status
      expect(find.textContaining('Verfügbar'), findsOneWidget);
    });
    
    testWidgets('StoreSearchBar widget allows store search', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: Scaffold(
              body: StoreSearchBar(
                onStoreSelected: (store) {},
                placeholder: 'Filiale suchen...',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show search field
      expect(find.text('Filiale suchen...'), findsOneWidget);
      
      // Should show filter chips
      expect(find.text('5km'), findsOneWidget);
      expect(find.text('Nur geöffnet'), findsOneWidget);
    });
  });
  
  group('Brand Colors Validation', () {
    test('All retailers have valid brand colors', () {
      final retailers = [
        'EDEKA', 'REWE', 'ALDI', 'LIDL', 'NETTO', 
        'PENNY', 'KAUFLAND', 'REAL', 'GLOBUS', 'MARKTKAUF', 'BIOCOMPANY'
      ];
      
      for (final retailer in retailers) {
        final colors = retailersProvider.getRetailerBrandColors(retailer);
        
        expect(colors, isNotNull);
        expect(colors.containsKey('primary'), isTrue);
        expect(colors.containsKey('accent'), isTrue);
        expect(colors['primary'], isA<Color>());
        expect(colors['accent'], isA<Color>());
      }
    });
    
    test('All retailers have logo URLs', () {
      final retailers = [
        'EDEKA', 'REWE', 'ALDI', 'LIDL', 'NETTO', 
        'PENNY', 'KAUFLAND', 'REAL', 'GLOBUS', 'MARKTKAUF', 'BIOCOMPANY'
      ];
      
      for (final retailer in retailers) {
        final logo = retailersProvider.getRetailerLogo(retailer);
        
        expect(logo, isNotNull);
        expect(logo, isNotEmpty);
        expect(
          logo.startsWith('http') || logo.startsWith('/assets'),
          isTrue,
          reason: 'Logo should be either a URL or local asset path',
        );
      }
    });
    
    test('All retailers have display names', () {
      final retailers = [
        'EDEKA', 'REWE', 'ALDI', 'LIDL', 'NETTO', 
        'PENNY', 'KAUFLAND', 'REAL', 'GLOBUS', 'MARKTKAUF', 'BIOCOMPANY'
      ];
      
      for (final retailer in retailers) {
        final displayName = retailersProvider.getRetailerDisplayName(retailer);
        
        expect(displayName, isNotNull);
        expect(displayName, isNotEmpty);
      }
    });
  });
}
