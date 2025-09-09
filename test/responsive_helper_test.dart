import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flashfeed/utils/responsive_helper.dart';

void main() {
  group('ResponsiveHelper Tests', () {
    group('Device Type Detection', () {
      testWidgets('detects mobile device correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Simulate mobile screen (320px)
                return MediaQuery(
                  data: const MediaQueryData(size: Size(320, 640)),
                  child: Builder(
                    builder: (context) {
                      expect(ResponsiveHelper.isMobile(context), true);
                      expect(ResponsiveHelper.isTablet(context), false);
                      expect(ResponsiveHelper.isDesktop(context), false);
                      expect(ResponsiveHelper.getDeviceType(context), DeviceType.mobile);
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        );
      });

      testWidgets('detects tablet device correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Simulate tablet screen (800px)
                return MediaQuery(
                  data: const MediaQueryData(size: Size(800, 1200)),
                  child: Builder(
                    builder: (context) {
                      expect(ResponsiveHelper.isMobile(context), false);
                      expect(ResponsiveHelper.isTablet(context), true);
                      expect(ResponsiveHelper.isDesktop(context), false);
                      expect(ResponsiveHelper.getDeviceType(context), DeviceType.tablet);
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        );
      });

      testWidgets('detects desktop device correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Simulate desktop screen (1440px)
                return MediaQuery(
                  data: const MediaQueryData(size: Size(1440, 900)),
                  child: Builder(
                    builder: (context) {
                      expect(ResponsiveHelper.isMobile(context), false);
                      expect(ResponsiveHelper.isTablet(context), false);
                      expect(ResponsiveHelper.isDesktop(context), true);
                      expect(ResponsiveHelper.getDeviceType(context), DeviceType.desktop);
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        );
      });
    });

    group('Grid Columns', () {
      testWidgets('returns correct columns for mobile', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(375, 667)),
              child: Builder(
                builder: (context) {
                  expect(ResponsiveHelper.getGridColumns(context), 2);
                  expect(
                    ResponsiveHelper.getAdaptiveGridColumns(
                      context,
                      mobileColumns: 1,
                      tabletColumns: 3,
                      desktopColumns: 4,
                    ),
                    1,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });

      testWidgets('returns correct columns for tablet', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(768, 1024)),
              child: Builder(
                builder: (context) {
                  expect(ResponsiveHelper.getGridColumns(context), 3);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });

      testWidgets('returns correct columns for desktop', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1920, 1080)),
              child: Builder(
                builder: (context) {
                  expect(ResponsiveHelper.getGridColumns(context), 4);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });
    });

    group('Font Scaling', () {
      testWidgets('scales font for small mobile', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(320, 568)),
              child: Builder(
                builder: (context) {
                  final scaledFont = ResponsiveHelper.getScaledFontSize(16, context);
                  expect(scaledFont, 14.4); // 16 * 0.9
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });

      testWidgets('scales font for desktop', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1440, 900)),
              child: Builder(
                builder: (context) {
                  final scaledFont = ResponsiveHelper.getScaledFontSize(16, context);
                  expect(scaledFont, 19.2); // 16 * 1.2
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });
    });

    group('Spacing System', () {
      test('spacing constants are correct', () {
        expect(ResponsiveHelper.space1, 4.0);
        expect(ResponsiveHelper.space2, 8.0);
        expect(ResponsiveHelper.space3, 12.0);
        expect(ResponsiveHelper.space4, 16.0);
        expect(ResponsiveHelper.space5, 20.0);
        expect(ResponsiveHelper.space6, 24.0);
        expect(ResponsiveHelper.space8, 32.0);
        expect(ResponsiveHelper.space10, 40.0);
        expect(ResponsiveHelper.space12, 48.0);
        expect(ResponsiveHelper.space16, 64.0);
      });

      testWidgets('responsive spacing adjusts correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(375, 667)),
              child: Builder(
                builder: (context) {
                  final spacing = ResponsiveHelper.getResponsiveSpacing(context, 20);
                  expect(spacing, 16.0); // 20 * 0.8 for mobile
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });
    });

    group('Animation Durations', () {
      test('animation durations are correct', () {
        expect(ResponsiveHelper.animationFast, const Duration(milliseconds: 150));
        expect(ResponsiveHelper.animationNormal, const Duration(milliseconds: 300));
        expect(ResponsiveHelper.animationSlow, const Duration(milliseconds: 500));
      });

      testWidgets('animation duration getter works', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                expect(
                  ResponsiveHelper.getAnimationDuration(context, AnimationSpeed.fast),
                  const Duration(milliseconds: 150),
                );
                expect(
                  ResponsiveHelper.getAnimationDuration(context, AnimationSpeed.normal),
                  const Duration(milliseconds: 300),
                );
                expect(
                  ResponsiveHelper.getAnimationDuration(context, AnimationSpeed.slow),
                  const Duration(milliseconds: 500),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    group('Container Constraints', () {
      testWidgets('max content width for mobile is infinity', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(375, 667)),
              child: Builder(
                builder: (context) {
                  expect(ResponsiveHelper.getMaxContentWidth(context), double.infinity);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });

      testWidgets('max content width for tablet is 720', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(800, 1024)),
              child: Builder(
                builder: (context) {
                  expect(ResponsiveHelper.getMaxContentWidth(context), 720.0);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });

      testWidgets('max content width for desktop is 1140', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1920, 1080)),
              child: Builder(
                builder: (context) {
                  expect(ResponsiveHelper.getMaxContentWidth(context), 1140.0);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });
    });

    group('Extension Methods', () {
      testWidgets('context extensions work correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(375, 667)),
              child: Builder(
                builder: (context) {
                  expect(context.isMobile, true);
                  expect(context.isTablet, false);
                  expect(context.isDesktop, false);
                  expect(context.deviceType, DeviceType.mobile);
                  expect(context.gridColumns, 2);
                  expect(context.maxContentWidth, double.infinity);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });
    });
  });
}
