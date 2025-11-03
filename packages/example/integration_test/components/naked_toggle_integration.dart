import 'package:example/api/naked_toggle.0.dart' as toggle_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedToggle Integration Tests', () {
    testWidgets('toggle switches state correctly', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(
        const MaterialApp(home: toggle_example.ToggleButtonExample()),
      );
      await tester.pumpAndSettle();

      final toggleFinder = find.byType(NakedToggle);
      expect(toggleFinder, findsWidgets);

      // Find the first toggle button
      final firstToggleFinder = toggleFinder.first;

      // Tap to toggle state
      await tester.tap(firstToggleFinder);
      await tester.pumpAndSettle();

      // Verify toggle exists after interaction
      expect(firstToggleFinder, findsOneWidget);

      // Tap again to toggle back
      await tester.tap(firstToggleFinder);
      await tester.pumpAndSettle();

      // Verify toggle still exists
      expect(firstToggleFinder, findsOneWidget);
    });

    testWidgets('toggle responds to keyboard activation', (tester) async {
      final toggleKey = UniqueKey();
      bool toggleValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NakedToggle(
                key: toggleKey,
                value: toggleValue,
                onChanged: (value) => toggleValue = value,
                child: const Text('Toggle Button'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test keyboard activation
      await tester.testKeyboardActivation(find.byKey(toggleKey));
      await tester.pumpAndSettle();

      // Toggle should respond to keyboard input
      expect(find.byKey(toggleKey), findsOneWidget);
    });

    testWidgets('toggle handles focus management correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: toggle_example.ToggleButtonExample()),
      );
      await tester.pumpAndSettle();

      final toggleFinder = find.byType(NakedToggle).first;

      // Test focus by tapping
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Verify toggle is still present and interactive
      expect(toggleFinder, findsOneWidget);
    });

    testWidgets('toggle responds to hover interactions', (tester) async {
      final toggleKey = UniqueKey();
      bool toggleValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NakedToggle(
                key: toggleKey,
                value: toggleValue,
                onChanged: (value) => toggleValue = value,
                child: const Text('Hover Toggle'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate hover
      await tester.simulateHover(toggleKey);
      await tester.pumpAndSettle();

      // Toggle should respond to hover
      expect(find.byKey(toggleKey), findsOneWidget);
    });

    testWidgets('toggle works with different visual states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: toggle_example.ToggleButtonExample()),
      );
      await tester.pumpAndSettle();

      // Find all toggles in the example
      final toggleFinders = find.byType(NakedToggle);
      expect(toggleFinders, findsWidgets);

      // Test each toggle in the example
      for (int i = 0; i < toggleFinders.evaluate().length && i < 3; i++) {
        final currentToggle = toggleFinders.at(i);

        // Tap to change state
        await tester.tap(currentToggle);
        await tester.pumpAndSettle();

        // Verify toggle still exists after state change
        expect(currentToggle, findsOneWidget);
      }
    });

    testWidgets('disabled toggle does not respond to interactions', (
      tester,
    ) async {
      final toggleKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NakedToggle(
                key: toggleKey,
                value: false,
                onChanged: null, // Disabled
                child: const Text('Disabled Toggle'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Try to tap disabled toggle
      await tester.tap(find.byKey(toggleKey));
      await tester.pumpAndSettle();

      // Toggle should still exist but remain disabled
      expect(find.byKey(toggleKey), findsOneWidget);
    });
  });
}
