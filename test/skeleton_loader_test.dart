import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/widgets/skeleton_loader.dart';

void main() {
  group('SkeletonLoader Tests', () {
    testWidgets('SkeletonLoader displays with correct dimensions', (WidgetTester tester) async {
      const testWidth = 200.0;
      const testHeight = 100.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              width: testWidth,
              height: testHeight,
            ),
          ),
        ),
      );

      // Find the skeleton loader
      final skeletonFinder = find.byType(SkeletonLoader);
      expect(skeletonFinder, findsOneWidget);

      // Check container dimensions
      final container = tester.widget<Container>(
        find.descendant(
          of: skeletonFinder,
          matching: find.byType(Container).first,
        ),
      );

      expect(container.constraints?.maxWidth, testWidth);
      expect(container.constraints?.maxHeight, testHeight);
    });

    testWidgets('SkeletonLoader applies custom border radius', (WidgetTester tester) async {
      final customBorderRadius = BorderRadius.circular(16.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              width: 100,
              height: 100,
              borderRadius: customBorderRadius,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SkeletonLoader),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.decoration, isNotNull);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, customBorderRadius);
    });

    testWidgets('SkeletonLoader applies margin when provided', (WidgetTester tester) async {
      const testMargin = EdgeInsets.all(16.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              width: 100,
              height: 100,
              margin: testMargin,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SkeletonLoader),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.margin, testMargin);
    });

    testWidgets('SkeletonLoader animation controller is initialized', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Pump to trigger animation
      await tester.pump();

      // Find AnimatedBuilder (there may be multiple from Material widgets)
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Pump animation frames
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Skeleton should still be present
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('SkeletonLoader disposes animation controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Replace with empty container to trigger disposal
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });
  });

  group('OfferCardSkeleton Tests', () {
    testWidgets('OfferCardSkeleton displays all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfferCardSkeleton(),
          ),
        ),
      );

      // Should have multiple skeleton loaders for different parts
      expect(find.byType(SkeletonLoader), findsWidgets);

      // At minimum should have:
      // - Image skeleton
      // - Title skeleton
      // - Subtitle skeleton
      // - Price skeletons
      // - Retailer skeleton
      expect(find.byType(SkeletonLoader), findsAtLeast(5));
    });

    testWidgets('OfferCardSkeleton has proper container styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfferCardSkeleton(),
          ),
        ),
      );

      // Find the main container
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(container.decoration, isNotNull);
      final decoration = container.decoration as BoxDecoration;

      // Check for white background
      expect(decoration.color, Colors.white);

      // Check for rounded corners
      expect(decoration.borderRadius, isNotNull);

      // Check for border
      expect(decoration.border, isNotNull);
    });
  });

  group('FlashDealCardSkeleton Tests', () {
    testWidgets('FlashDealCardSkeleton displays in horizontal layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlashDealCardSkeleton(),
          ),
        ),
      );

      // Should have a Row for horizontal layout
      expect(find.byType(Row), findsWidgets);

      // Should have skeleton loaders
      expect(find.byType(SkeletonLoader), findsWidgets);

      // At minimum should have:
      // - Image skeleton
      // - Title skeleton
      // - Price skeleton
      // - Timer skeleton
      // - Badge skeleton
      expect(find.byType(SkeletonLoader), findsAtLeast(4));
    });

    testWidgets('FlashDealCardSkeleton has shadow styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlashDealCardSkeleton(),
          ),
        ),
      );

      // Find the main container
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(container.decoration, isNotNull);
      final decoration = container.decoration as BoxDecoration;

      // Check for shadow
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.isNotEmpty, isTrue);
    });
  });

  group('StoreCardSkeleton Tests', () {
    testWidgets('StoreCardSkeleton displays store layout elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoreCardSkeleton(),
          ),
        ),
      );

      // Should have skeleton loaders
      expect(find.byType(SkeletonLoader), findsWidgets);

      // Should have Row for logo and info
      expect(find.byType(Row), findsWidgets);

      // At minimum should have:
      // - Logo skeleton
      // - Store name skeleton
      // - Store info skeleton
      // - Address skeleton
      // - Distance skeleton
      expect(find.byType(SkeletonLoader), findsAtLeast(4));
    });
  });

  group('OffersGridSkeleton Tests', () {
    testWidgets('OffersGridSkeleton displays correct number of items', (WidgetTester tester) async {
      const testItemCount = 4;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OffersGridSkeleton(
              itemCount: testItemCount,
            ),
          ),
        ),
      );

      // Should display the specified number of skeleton cards
      expect(find.byType(OfferCardSkeleton), findsNWidgets(testItemCount));
    });

    testWidgets('OffersGridSkeleton uses GridView layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 1200, // Increase height to fit all items
              child: OffersGridSkeleton(),
            ),
          ),
        ),
      );

      // Should use GridView
      expect(find.byType(GridView), findsOneWidget);

      // Check that skeleton cards are rendered (at least 4 visible)
      expect(find.byType(OfferCardSkeleton), findsAtLeast(4));
    });

    testWidgets('OffersGridSkeleton has proper grid configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: OffersGridSkeleton(),
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));

      // Check grid delegate
      expect(gridView.gridDelegate, isNotNull);
      expect(gridView.gridDelegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());

      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      expect(delegate.childAspectRatio, 0.75);
    });
  });

  group('FlashDealsListSkeleton Tests', () {
    testWidgets('FlashDealsListSkeleton displays correct number of items', (WidgetTester tester) async {
      const testItemCount = 3;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlashDealsListSkeleton(
              itemCount: testItemCount,
            ),
          ),
        ),
      );

      // Should display the specified number of skeleton cards
      expect(find.byType(FlashDealCardSkeleton), findsNWidgets(testItemCount));
    });

    testWidgets('FlashDealsListSkeleton uses ListView layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlashDealsListSkeleton(),
          ),
        ),
      );

      // Should use ListView
      expect(find.byType(ListView), findsOneWidget);

      // Default item count should be 4
      expect(find.byType(FlashDealCardSkeleton), findsNWidgets(4));
    });

    testWidgets('FlashDealsListSkeleton has correct padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: FlashDealsListSkeleton(),
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));

      // Check padding
      expect(listView.padding, isNotNull);
      expect(listView.padding, const EdgeInsets.symmetric(vertical: 8));
    });
  });

  group('Shimmer Animation Tests', () {
    testWidgets('Shimmer animation runs continuously', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Initial pump
      await tester.pump();

      // Pump multiple animation frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      // Animation should still be running
      expect(find.byType(AnimatedBuilder), findsWidgets);
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('Multiple SkeletonLoaders animate independently', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SkeletonLoader(width: 100, height: 50),
                SkeletonLoader(width: 100, height: 50),
                SkeletonLoader(width: 100, height: 50),
              ],
            ),
          ),
        ),
      );

      // All skeleton loaders should be present
      expect(find.byType(SkeletonLoader), findsNWidgets(3));

      // There should be AnimatedBuilders (may be more than 3 due to Material widgets)
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Pump animation
      await tester.pump(const Duration(milliseconds: 750));

      // All should still be animating
      expect(find.byType(SkeletonLoader), findsNWidgets(3));
    });
  });
}