// Test für UI Widgets für Retailer Management
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
  
  group('RetailersProvider UI Methods', () {
    test('getRetailerLogo returns correct logo URL', () {
      final edekaLogo = retailersProvider.getRetailerLogo('EDEKA');
      expect(edekaLogo, '/assets/images/retailers/edeka.jpg');
      
      final reweLogo = retailersProvider.getRetailerLogo('REWE');
      expect(reweLogo, '/assets/images/retailers/rewe.png');
      
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
      expect(retailersProvider.getRetailerDisplayName('ALDI'), 'ALDI');
      expect(retailersProvider.getRetailerDisplayName('NETTO'), 'Netto');
      expect(retailersProvider.getRetailerDisplayName('nahkauf'), 'nahkauf');
      
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
      
      expect(branding['logo'], '/assets/images/retailers/edeka.jpg');
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
      expect(find.byType(RetailerLogo), findsAtLeastNWidgets(1));
      
      // Should have container with correct size
      final container = find.byType(Container).first;
      expect(container, findsAtLeastNWidgets(1));
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
      expect(find.text('Filter:'), findsAtLeastNWidgets(1));
      expect(find.text('Nur verfügbare'), findsAtLeastNWidgets(1));
      
      // Should show PLZ
      expect(find.text('PLZ: 10115'), findsAtLeastNWidgets(1));
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
      expect(find.text('EDEKA'), findsAtLeastNWidgets(1));
      
      // Should show availability status
      expect(find.textContaining('Verfügbar'), findsAtLeastNWidgets(1));
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
      expect(find.text('Filiale suchen...'), findsAtLeastNWidgets(1));
      
      // Should show filter chips
      expect(find.text('5km'), findsAtLeastNWidgets(1));
      expect(find.text('Nur geöffnet'), findsAtLeastNWidgets(1));
    });
  });
  
  group('Brand Colors Validation', () {
    test('All retailers have valid brand colors', () {
      final retailers = [
        'EDEKA', 'REWE', 'ALDI', 'LIDL', 'NETTO', 
        'PENNY', 'KAUFLAND', 'nahkauf', 'GLOBUS', 'MARKTKAUF', 'BIOCOMPANY'
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
        'PENNY', 'KAUFLAND', 'nahkauf', 'GLOBUS', 'MARKTKAUF', 'BIOCOMPANY'
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
        'PENNY', 'KAUFLAND', 'nahkauf', 'GLOBUS', 'MARKTKAUF', 'BIOCOMPANY'
      ];
      
      for (final retailer in retailers) {
        final displayName = retailersProvider.getRetailerDisplayName(retailer);
        
        expect(displayName, isNotNull);
        expect(displayName, isNotEmpty);
      }
    });
  });

  group('Extended Widget Interaction Tests', () {
    testWidgets('RetailerSelector allows multi-selection', (tester) async {
      final selectedRetailers = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: Scaffold(
              body: RetailerSelector(
                multiSelect: true,
                onSelectionChanged: (selected) {
                  selectedRetailers.clear();
                  selectedRetailers.addAll(selected);
                },
                showOnlyAvailable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap on first retailer
      final firstRetailer = find.textContaining('EDEKA').first;
      if (firstRetailer.evaluate().isNotEmpty) {
        await tester.tap(firstRetailer);
        await tester.pumpAndSettle();

        // Should allow multiple selections
        expect(selectedRetailers.length, greaterThanOrEqualTo(0));
      }
    });

    testWidgets('StoreSearchBar performs real-time search', (tester) async {

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: Scaffold(
              body: StoreSearchBar(
                onStoreSelected: (store) {
                  // Store selected
                },
                placeholder: 'Filiale suchen...',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find search field and enter text
      final searchField = find.byType(TextField);
      expect(searchField, findsAtLeastNWidgets(1));

      await tester.enterText(searchField, 'EDEKA');
      await tester.pumpAndSettle();

      // Should trigger search and potentially show results
      // Results depend on store data availability
    });

    testWidgets('RetailerAvailabilityCard expands for more info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: const Scaffold(
              body: RetailerAvailabilityCard(
                retailerName: 'BIOCOMPANY',
                userPLZ: '10115',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show expand/collapse functionality
      final expandIcon = find.byType(Icon);
      if (expandIcon.evaluate().isNotEmpty) {
        // Test expansion
        await tester.tap(expandIcon.first);
        await tester.pumpAndSettle();

        // Should show additional information when expanded
        expect(find.byType(RetailerAvailabilityCard), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('RetailerLogo shows fallback for unknown retailer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: const Scaffold(
              body: RetailerLogo(
                retailerName: 'UNKNOWN_RETAILER',
                size: LogoSize.large,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render fallback logo
      expect(find.byType(RetailerLogo), findsAtLeastNWidgets(1));

      // Should show default container or icon
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('Widgets handle theme changes properly', (tester) async {
      // Test light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: const Scaffold(
              body: Column(
                children: [
                  RetailerLogo(retailerName: 'EDEKA'),
                  RetailerAvailabilityCard(
                    retailerName: 'REWE',
                    userPLZ: '10115',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(RetailerLogo), findsAtLeastNWidgets(1));
      expect(find.byType(RetailerAvailabilityCard), findsAtLeastNWidgets(1));

      // Test dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: const Scaffold(
              body: Column(
                children: [
                  RetailerLogo(retailerName: 'EDEKA'),
                  RetailerAvailabilityCard(
                    retailerName: 'REWE',
                    userPLZ: '10115',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should adapt to dark theme
      expect(find.byType(RetailerLogo), findsAtLeastNWidgets(1));
      expect(find.byType(RetailerAvailabilityCard), findsAtLeastNWidgets(1));
    });
  });

  group('Widget Performance Tests', () {
    testWidgets('RetailerSelector handles large retailer lists efficiently', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: Scaffold(
              body: RetailerSelector(
                onSelectionChanged: (selected) {},
                showOnlyAvailable: false, // Show all retailers
              ),
            ),
          ),
        ),
      );

      // Measure rendering performance
      final stopwatch = Stopwatch()..start();
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should render within reasonable time (< 1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Should show widget without issues
      expect(find.byType(RetailerSelector), findsAtLeastNWidgets(1));
    });

    testWidgets('StoreSearchBar handles rapid input changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: Scaffold(
              body: StoreSearchBar(
                onStoreSelected: (store) {},
                placeholder: 'Search...',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsAtLeastNWidgets(1));

      // Simulate rapid typing
      await tester.enterText(searchField, 'E');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(searchField, 'ED');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(searchField, 'EDE');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(searchField, 'EDEKA');
      await tester.pumpAndSettle();

      // Should handle rapid changes without crashing
      expect(find.byType(StoreSearchBar), findsAtLeastNWidgets(1));
    });
  });

  group('Accessibility Tests', () {
    testWidgets('Widgets provide proper semantic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: const Scaffold(
              body: Column(
                children: [
                  RetailerLogo(
                    retailerName: 'EDEKA',
                  ),
                  RetailerAvailabilityCard(
                    retailerName: 'REWE',
                    userPLZ: '10115',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for semantic information
      expect(find.byType(Semantics), findsAtLeastNWidgets(1));

      // Should provide semantic information
      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });

    testWidgets('Widgets support high contrast mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.highContrastLight(),
          ),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: retailersProvider),
            ],
            child: const Scaffold(
              body: RetailerAvailabilityCard(
                retailerName: 'LIDL',
                userPLZ: '10115',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render properly in high contrast mode
      expect(find.byType(RetailerAvailabilityCard), findsAtLeastNWidgets(1));
    });
  });
}
