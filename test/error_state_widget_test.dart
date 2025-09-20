import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashfeed/widgets/error_state_widget.dart';

void main() {
  group('ErrorStateWidget Tests', () {
    testWidgets('displays default error message for general error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.general,
            ),
          ),
        ),
      );

      // Check for error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Check for default title
      expect(find.text('Ein Fehler ist aufgetreten'), findsOneWidget);

      // Check for default message
      expect(
        find.text('Es ist ein unerwarteter Fehler aufgetreten. Bitte versuchen Sie es erneut.'),
        findsOneWidget,
      );
    });

    testWidgets('displays network error correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.network,
            ),
          ),
        ),
      );

      // Check for wifi off icon
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Check for network error title
      expect(find.text('Keine Internetverbindung'), findsOneWidget);

      // Check for network error message
      expect(
        find.text('Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.'),
        findsOneWidget,
      );
    });

    testWidgets('displays no data error correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.noData,
            ),
          ),
        ),
      );

      // Check for inbox icon
      expect(find.byIcon(Icons.inbox), findsOneWidget);

      // Check for no data title
      expect(find.text('Keine Daten verfügbar'), findsOneWidget);
    });

    testWidgets('displays permission error with help text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.permission,
            ),
          ),
        ),
      );

      // Check for lock icon
      expect(find.byIcon(Icons.lock), findsOneWidget);

      // Check for permission error title
      expect(find.text('Berechtigung erforderlich'), findsOneWidget);

      // Check for help text with settings icon
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(
        find.textContaining('Gehen Sie zu Einstellungen'),
        findsOneWidget,
      );
    });

    testWidgets('displays region error with help text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.region,
            ),
          ),
        ),
      );

      // Check for location off icon
      expect(find.byIcon(Icons.location_off), findsOneWidget);

      // Check for region error title
      expect(find.text('Nicht in Ihrer Region verfügbar'), findsOneWidget);

      // Check for help text with search icon
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(
        find.textContaining('Versuchen Sie eine andere PLZ'),
        findsOneWidget,
      );
    });

    testWidgets('displays custom error message when provided', (WidgetTester tester) async {
      const customMessage = 'Dies ist eine benutzerdefinierte Fehlermeldung';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.general,
              errorMessage: customMessage,
            ),
          ),
        ),
      );

      // Check for custom message
      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry callback is provided', (WidgetTester tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.network,
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      // Check for retry button
      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Erneut versuchen'));
      await tester.pump();

      // Verify callback was called
      expect(retryPressed, isTrue);
    });

    testWidgets('does not show retry button when onRetry is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.general,
              onRetry: null,
            ),
          ),
        ),
      );

      // Check that retry button is not shown
      expect(find.text('Erneut versuchen'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('displays different icons for different error types', (WidgetTester tester) async {
      // Test that each error type has its specific icon
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.network,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.permission,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.region,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets('displays help text only for permission and region errors', (WidgetTester tester) async {
      // Test general error - should not have help text
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.general,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.search), findsNothing);

      // Test network error - should not have help text
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.network,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.search), findsNothing);
    });

    testWidgets('text overflow is handled correctly', (WidgetTester tester) async {
      final veryLongMessage = 'Dies ist eine sehr lange Fehlermeldung ' * 20;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.general,
              errorMessage: veryLongMessage,
            ),
          ),
        ),
      );

      // Check that the widget doesn't throw overflow errors
      expect(tester.takeException(), isNull);

      // Find Text widget with the error message
      final textWidget = tester.widget<Text>(
        find.textContaining('Dies ist eine sehr lange Fehlermeldung'),
      );

      // Check that overflow is handled
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 3);
    });

    testWidgets('retry button is properly styled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorType: ErrorType.network,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Check that it has the refresh icon
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Check that it has the correct text
      expect(find.text('Erneut versuchen'), findsOneWidget);

      // Verify button exists by checking for widget type
      expect(find.byWidgetPredicate(
        (widget) => widget is ElevatedButton,
      ), findsOneWidget);
    });
  });

  group('ErrorType enum tests', () {
    test('all error types are defined', () {
      expect(ErrorType.values.length, 5);
      expect(ErrorType.values.contains(ErrorType.network), isTrue);
      expect(ErrorType.values.contains(ErrorType.noData), isTrue);
      expect(ErrorType.values.contains(ErrorType.permission), isTrue);
      expect(ErrorType.values.contains(ErrorType.region), isTrue);
      expect(ErrorType.values.contains(ErrorType.general), isTrue);
    });
  });
}