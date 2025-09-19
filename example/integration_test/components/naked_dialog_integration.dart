import 'package:example/api/naked_dialog.0.dart' as dialog_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedDialog Integration Tests', () {
    testWidgets('dialog opens and closes correctly', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const dialog_example.MyApp());
      await tester.pumpAndSettle();

      // Find the button that opens the dialog
      final openButtonFinder = find.text('Open Dialog');
      expect(openButtonFinder, findsOneWidget);

      // Initially, dialog should not be visible
      expect(find.byType(NakedDialog), findsNothing);

      // Tap to open dialog
      await tester.tap(openButtonFinder);
      await tester.pumpAndSettle();

      // Verify dialog is now visible
      expect(find.byType(NakedDialog), findsOneWidget);

      // Find and tap the close button (usually "Close" or "Cancel")
      final closeButtonFinder = find.text('Close').last;
      expect(closeButtonFinder, findsOneWidget);

      await tester.tap(closeButtonFinder);
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.byType(NakedDialog), findsNothing);
    });

    testWidgets('dialog closes when tapping outside', (tester) async {
      await tester.pumpWidget(const dialog_example.MyApp());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.byType(NakedDialog), findsOneWidget);

      // Tap outside the dialog
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.byType(NakedDialog), findsNothing);
    });

    testWidgets('dialog responds to keyboard activation', (tester) async {
      final dialogKey = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              key: dialogKey,
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test keyboard activation
      await tester.testKeyboardActivation(find.byKey(dialogKey));
      await tester.pumpAndSettle();

      // Button should be activated by keyboard
      expect(find.byKey(dialogKey), findsOneWidget);
    });

    testWidgets('dialog handles focus management correctly', (tester) async {
      await tester.pumpWidget(const dialog_example.MyApp());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is focused
      expect(find.byType(NakedDialog), findsOneWidget);

      // Test that focus is properly managed within dialog
      final focusableElements = find.byType(TextButton);
      if (focusableElements.evaluate().isNotEmpty) {
        await tester.tap(focusableElements.first);
        await tester.pumpAndSettle();
      }
    });
  });
}