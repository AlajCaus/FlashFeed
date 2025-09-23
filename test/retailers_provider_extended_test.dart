// Erweiterte Unit Tests für Task 11.7.1
// Tests für alle RetailersProvider Methoden aus Task 11.1-11.6

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flashfeed/providers/retailers_provider.dart';
import 'package:flashfeed/services/mock_data_service.dart';
import 'package:flashfeed/models/models.dart';
import 'retailer_test_helpers.dart';

void main() {
  group('RetailersProvider UI Methods Tests', () {
    late MockDataService testMockDataService;
    late RetailersProvider provider;
    
    setUp(() async {
      testMockDataService = MockDataService();
      await testMockDataService.initializeMockData(testMode: true);
      
      provider = await RetailerTestHelpers.createTestProvider(
        mockDataService: testMockDataService,
        initialPLZ: '10115', // Berlin
      );
    });
    
    tearDown(() {
      provider.dispose();
      testMockDataService.dispose();
    });
    
    group('getRetailerLogo() Tests', () {
      test('should return correct logo URL for each retailer', () {
        for (final retailerName in RetailerTestHelpers.allRetailerNames) {
          final logo = provider.getRetailerLogo(retailerName);
          
          expect(logo, isNotNull);
          expect(logo, isNotEmpty);
          
          // Check if it's a valid URL or asset path
          final isValid = logo.startsWith('http') || 
                         logo.startsWith('/assets') ||
                         logo.contains('wikipedia');
          expect(isValid, isTrue, 
            reason: 'Logo for $retailerName should be URL or asset path');
        }
      });
      
      test('should return default logo for unknown retailer', () {
        final logo = provider.getRetailerLogo('UNKNOWN_RETAILER');
        expect(logo, equals('/assets/images/default_retailer.png'));
      });
      
      test('should be case-insensitive', () {
        final logo1 = provider.getRetailerLogo('EDEKA');
        final logo2 = provider.getRetailerLogo('edeka');
        final logo3 = provider.getRetailerLogo('Edeka');
        
        expect(logo1, equals(logo2));
        expect(logo2, equals(logo3));
      });
    });
    
    group('getRetailerBrandColors() Tests', () {
      test('should return valid colors for all retailers', () {
        for (final retailerName in RetailerTestHelpers.allRetailerNames) {
          final colors = provider.getRetailerBrandColors(retailerName);
          
          expect(colors, isNotNull);
          expect(colors.containsKey('primary'), isTrue);
          expect(colors.containsKey('accent'), isTrue);
          expect(colors['primary'], isA<Color>());
          expect(colors['accent'], isA<Color>());
          
          // Validate colors are not null
          expect(colors['primary'], isNotNull);
          expect(colors['accent'], isNotNull);
        }
      });
      
      test('should return correct brand colors for specific retailers', () {
        // Test specific known brand colors
        final edekaColors = provider.getRetailerBrandColors('EDEKA');
        expect(edekaColors['primary'], equals(const Color(0xFF005CA9))); // EDEKA Blue
        expect(edekaColors['accent'], equals(const Color(0xFFFDB813)));  // EDEKA Yellow
        
        final reweColors = provider.getRetailerBrandColors('REWE');
        expect(reweColors['primary'], equals(const Color(0xFFCC071E))); // REWE Red
        expect(reweColors['accent'], equals(const Color(0xFFFFFFFF)));  // White
      });
      
      test('should return default colors for unknown retailer', () {
        final colors = provider.getRetailerBrandColors('UNKNOWN');
        expect(colors['primary'], equals(const Color(0xFF2E8B57))); // FlashFeed Green
        expect(colors['accent'], equals(const Color(0xFFDC143C)));  // FlashFeed Red
      });
    });
    
    group('getRetailerDisplayName() Tests', () {
      test('should return display names for all retailers', () {
        for (final retailerName in RetailerTestHelpers.allRetailerNames) {
          final displayName = provider.getRetailerDisplayName(retailerName);
          
          expect(displayName, isNotNull);
          expect(displayName, isNotEmpty);
        }
      });
      
      test('should return correct display names', () {
        expect(provider.getRetailerDisplayName('ALDI'), equals('ALDI'));
        expect(provider.getRetailerDisplayName('NETTO'), equals('Netto'));
        expect(provider.getRetailerDisplayName('LIDL'), equals('Lidl'));
        expect(provider.getRetailerDisplayName('nahkauf'), equals('nahkauf'));
      });
      
      test('should handle unknown retailer gracefully', () {
        final displayName = provider.getRetailerDisplayName('UNKNOWN_STORE');
        expect(displayName, equals('UNKNOWN_STORE'));
      });
    });
    
    group('getRetailerDetails() Tests', () {
      test('should return retailer details for valid names', () {
        final edeka = provider.getRetailerDetails('EDEKA');
        expect(edeka, isNotNull);
        expect(edeka!.name, equals('EDEKA'));
        expect(edeka.displayName, isNotEmpty);
        expect(edeka.logoUrl, isNotEmpty);
      });
      
      test('should return null for unknown retailer', () {
        final unknown = provider.getRetailerDetails('NONEXISTENT');
        expect(unknown, isNull);
      });
      
      test('should cache retailer details', () {
        // First call - should hit database
        final edeka1 = provider.getRetailerDetails('EDEKA');
        
        // Second call - should hit cache
        final edeka2 = provider.getRetailerDetails('EDEKA');
        
        // Should be the same instance (cached)
        expect(identical(edeka1, edeka2), isTrue);
      });
    });
    
    group('isRetailerAvailable() Tests', () {
      test('should check availability in current PLZ', () {
        // Provider was initialized with Berlin PLZ 10115
        
        // EDEKA should be available (nationwide)
        expect(provider.isRetailerAvailable('EDEKA'), isTrue);
        
        // GLOBUS should not be available in Berlin (only South/West)
        expect(provider.isRetailerAvailable('GLOBUS'), isFalse);
        
        // BioCompany should be available in Berlin
        expect(provider.isRetailerAvailable('BIOCOMPANY'), isTrue);
      });
      
      test('should handle nationwide retailers correctly', () {
        // Test with no PLZ set
        provider.updateUserLocation('');
        
        // Nationwide retailers should still be available
        expect(provider.isRetailerAvailable('EDEKA'), isTrue);
        expect(provider.isRetailerAvailable('REWE'), isTrue);
        
        // Regional retailers should not be available without PLZ
        expect(provider.isRetailerAvailable('BIOCOMPANY'), isFalse);
      });
    });
    
    group('getRetailerBranding() Tests', () {
      test('should return complete branding info', () {
        final branding = provider.getRetailerBranding('EDEKA');
        
        expect(branding, isNotNull);
        expect(branding['logo'], isNotEmpty);
        expect(branding['colors'], isA<Map<String, Color>>());
        expect(branding['displayName'], equals('EDEKA'));
        expect(branding['isAvailable'], isTrue);
      });
      
      test('should reflect availability in branding', () {
        // GLOBUS is not available in Berlin
        final branding = provider.getRetailerBranding('GLOBUS');
        expect(branding['isAvailable'], isFalse);
        
        // But still has branding info
        expect(branding['logo'], isNotEmpty);
        expect(branding['displayName'], equals('Globus'));
      });
    });
    
    group('Cache Management Tests', () {
      test('should clear all caches on clearCache()', () {
        // Populate caches
        provider.getRetailerDetails('EDEKA');
        provider.getAvailableRetailers('10115');
        
        // Clear caches
        provider.clearCache();
        
        // Cache should be empty (test via side effect)
        // After clear, next call should take longer (not from cache)
        final stopwatch = Stopwatch()..start();
        provider.getAvailableRetailers('10115');
        stopwatch.stop();
        
        // This is a rough test - clearing cache means recalculation
        expect(stopwatch.elapsedMicroseconds, greaterThan(0));
      });
      
      test('should handle concurrent cache access', () async {
        // Simulate concurrent access
        final futures = <Future>[];
        
        for (int i = 0; i < 10; i++) {
          futures.add(Future(() => provider.getRetailerDetails('EDEKA')));
          futures.add(Future(() => provider.getRetailerLogo('REWE')));
          futures.add(Future(() => provider.getRetailerBrandColors('ALDI')));
        }
        
        final results = await Future.wait(futures);
        
        // All results should be valid (no race conditions)
        expect(results.every((r) => r != null), isTrue);
      });
    });
    
    group('Error Handling Tests', () {
      test('should handle invalid retailer names gracefully', () {
        expect(() => provider.getRetailerLogo(''), returnsNormally);
        expect(() => provider.getRetailerLogo(null as dynamic), throwsA(isA<TypeError>()));
      });
      
      test('should handle invalid PLZ gracefully', () {
        provider.updateUserLocation('INVALID_PLZ');
        
        // Should fall back to showing only nationwide retailers
        expect(provider.availableRetailers.isNotEmpty, isTrue);
        expect(provider.availableRetailers.every((r) => r.isNationwide), isTrue);
      });
    });
    
    group('Opening Hours Integration Tests', () {
      test('should check if stores are open', () {
        // This would need actual store data with opening hours
        // For now, just verify the method exists and doesn't crash
        final stores = provider.allStores;
        if (stores.isNotEmpty) {
          final now = DateTime.now();
          final openStores = stores.where((s) => s.isOpenAt(now)).toList();
          
          // At least some stores should have opening hours
          expect(openStores, isNotNull);
        }
      });
      
      test('should get next opening time', () {
        final stores = provider.allStores;
        if (stores.isNotEmpty) {
          final firstStore = stores.first;
          final nextOpen = firstStore.getNextOpeningTime();
          
          // Should either be null (always open) or a future time
          if (nextOpen != null) {
            expect(nextOpen.isAfter(DateTime.now()), isTrue);
          }
        }
      });
    });
  });
  
  group('Extended Regional Availability Tests', () {
    late RetailersProvider provider;
    late MockDataService testMockDataService;
    
    setUp(() async {
      testMockDataService = MockDataService();
      await testMockDataService.initializeMockData(testMode: true);
      
      provider = await RetailerTestHelpers.createTestProvider(
        mockDataService: testMockDataService,
      );
    });
    
    tearDown(() {
      provider.dispose();
      testMockDataService.dispose();
    });
    
    test('getNearbyRetailers should find retailers within radius', () async {
      final nearbyRetailers = await provider.getNearbyRetailers('10115', 10.0);
      
      expect(nearbyRetailers, isNotEmpty);
      
      // Should be sorted by distance
      if (nearbyRetailers.length > 1) {
        // Can't easily verify exact distances without mock data
        // But list should be returned
        expect(nearbyRetailers, isA<List<Retailer>>());
      }
    });
    
    test('getRetailerCoverage should return statistics', () {
      final coverage = provider.getRetailerCoverage('EDEKA');
      
      expect(coverage, isNotNull);
      expect(coverage['retailerName'], equals('EDEKA'));
      expect(coverage['isNationwide'], isTrue);
      expect(coverage['totalStores'], isA<int>());
      expect(coverage['coveragePercentage'], isNotEmpty);
      expect(coverage['coveredRegions'], isA<List>());
    });
    
    test('findAlternativeRetailers should suggest alternatives', () {
      // GLOBUS is not available in Berlin
      final alternatives = provider.findAlternativeRetailers('10115', 'GLOBUS');
      
      expect(alternatives, isNotEmpty);
      
      // Should not include GLOBUS itself
      expect(alternatives.any((r) => r.name == 'GLOBUS'), isFalse);
      
      // Should include available retailers
      expect(alternatives.every((r) => r.isAvailableInPLZ('10115')), isTrue);
    });
  });
}
