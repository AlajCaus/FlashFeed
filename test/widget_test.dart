// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flashfeed/main.dart';

void main() {
  testWidgets('FlashFeed app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FlashFeedApp());
    
    // Allow time for providers to initialize
    await tester.pumpAndSettle();

    // Verify that FlashFeed app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify that main layout screen is present
    // Note: Specific widget checks depend on MainLayoutScreen implementation
    expect(tester.takeException(), isNull);
  });
  
  testWidgets('FlashFeed providers are accessible', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FlashFeedApp());
    
    // Allow time for providers to initialize
    await tester.pumpAndSettle();
    
    // Verify that no exceptions occurred during provider setup
    expect(tester.takeException(), isNull);
    
    // Verify MaterialApp is present (indicates successful provider setup)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
