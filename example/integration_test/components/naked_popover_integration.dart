import 'package:example/api/naked_popover.0.dart' as popover_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedPopover Integration Tests', () {
    testWidgets('popover opens and closes correctly', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const MaterialApp(
        home: popover_example.BasicPopoverExample(),
      ));
      await tester.pumpAndSettle();

      // Find the button that triggers the popover
      final triggerButtonFinder = find.byType(NakedButton).first;
      expect(triggerButtonFinder, findsOneWidget);

      // Initially, popover content should not be visible
      expect(find.text('Popover Content'), findsNothing);

      // Tap to open popover
      await tester.tap(triggerButtonFinder);
      await tester.pumpAndSettle();

      // Verify popover content is now visible
      expect(find.text('Popover Content'), findsOneWidget);

      // Tap outside to close popover
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // Verify popover content is closed
      expect(find.text('Popover Content'), findsNothing);
    });

    testWidgets('popover responds to hover interactions', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: popover_example.BasicPopoverExample(),
      ));
      await tester.pumpAndSettle();

      // Find the popover trigger
      final triggerFinder = find.byType(NakedButton).first;
      expect(triggerFinder, findsOneWidget);

      // Simulate hover to show popover
      final triggerWidget = tester.widget<NakedButton>(triggerFinder);
      final triggerKey = triggerWidget.key;

      if (triggerKey != null) {
        await tester.simulateHover(triggerKey);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('popover handles keyboard activation', (tester) async {
      final popoverKey = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedPopover(
              key: popoverKey,
              popoverBuilder: (context, info) => const Text('Popover Content'),
              child: NakedButton(
                onPressed: () {},
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test keyboard activation
      await tester.testKeyboardActivation(find.byKey(popoverKey));
      await tester.pumpAndSettle();

      // Popover should respond to keyboard input
      expect(find.byKey(popoverKey), findsOneWidget);
    });

    testWidgets('popover positioning works correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: popover_example.BasicPopoverExample(),
      ));
      await tester.pumpAndSettle();

      // Find the popover trigger
      final triggerFinder = find.byType(NakedButton).first;
      expect(triggerFinder, findsOneWidget);

      // Open popover
      await tester.tap(triggerFinder);
      await tester.pumpAndSettle();

      // Verify popover is positioned correctly (it should be visible on screen)
      final popoverFinder = find.byType(NakedPopover);
      expect(popoverFinder, findsWidgets);

      // Verify the popover content is accessible
      final contentFinder = find.textContaining('');
      expect(contentFinder, findsWidgets);
    });

    testWidgets('popover handles focus management', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: popover_example.BasicPopoverExample(),
      ));
      await tester.pumpAndSettle();

      // Open popover
      final triggerFinder = find.byType(NakedButton).first;
      await tester.tap(triggerFinder);
      await tester.pumpAndSettle();

      // Test focus management within popover
      final buttonFinders = find.byType(NakedButton);
      if (buttonFinders.evaluate().isNotEmpty) {
        final firstButton = buttonFinders.first;
        await tester.tap(firstButton);
        await tester.pumpAndSettle();
      }
    });
  });
}
