// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:goodlobang/services/theme_service.dart';

import 'package:goodlobang/main.dart';

void main() {
  setUpAll(() async {
    await Firebase.initializeApp();
    GetIt.instance.registerLazySingleton(() => FirebaseService());
    GetIt.instance.registerLazySingleton(() => ThemeService());
  });

  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for async operations
    await tester.pumpAndSettle();

    // Verify that the app loads without crashing (basic smoke test)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
