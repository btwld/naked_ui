/// ARIA Focus Behavior Tests for NakedPopover
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
///
/// Trigger Behavior:
/// - Click/Enter/Space on trigger: Opens popover
/// - Escape: Closes popover
///
/// Focus Management (depends on popover type):
/// - **Non-modal (tooltip-like)**: Focus stays on trigger; popover content not in tab order
/// - **Interactive popover**: Focus may move into popover; Tab navigates within
///
/// On Close:
/// - Return focus to trigger element
///
/// Notes:
/// - Unlike dialogs, popovers typically don't trap focus
/// - Clicking outside usually closes the popover
/// - Content should be accessible but not interrupt user flow
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedPopover ARIA Focus Behavior', () {
    group('Closing Popover', () {
      testWidgets('Escape closes popover', (WidgetTester tester) async {
        final triggerFocusNode = FocusNode();
        final controller = MenuController();

        await tester.pumpMaterialWidget(
          NakedPopover(
            controller: controller,
            popoverBuilder: (context, info) => const Text('Popover Content'),
            child: const Text('Popover Trigger'),
          ),
        );

        controller.open();
        await tester.pump();
        expect(find.text('Popover Content'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Popover Content'), findsNothing);

        triggerFocusNode.dispose();
      });
    });

    group('Interactive Popover Content', () {
      testWidgets('Tab can navigate to focusable content in popover', (
        WidgetTester tester,
      ) async {
        final triggerFocusNode = FocusNode(debugLabel: 'trigger');
        final contentFocusNode = FocusNode(debugLabel: 'content');
        final controller = MenuController();

        await tester.pumpMaterialWidget(
          NakedPopover(
            controller: controller,
            popoverBuilder: (context, info) => TextField(
              focusNode: contentFocusNode,
              decoration: const InputDecoration(labelText: 'Input'),
            ),
            child: const Text('Popover Trigger'),
          ),
        );

        controller.open();
        await tester.pumpAndSettle();

        // Tab should move to content in popover
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(contentFocusNode.hasFocus, isTrue);

        triggerFocusNode.dispose();
        contentFocusNode.dispose();
      });

      testWidgets('Tab cycles focus within popover and does not escape', (
        WidgetTester tester,
      ) async {
        final outsideFocusNode = FocusNode(debugLabel: 'outside');
        final input1FocusNode = FocusNode(debugLabel: 'input1');
        final input2FocusNode = FocusNode(debugLabel: 'input2');
        final controller = MenuController();

        await tester.pumpMaterialWidget(
          Column(
            children: [
              NakedPopover(
                controller: controller,
                popoverBuilder: (context, info) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      focusNode: input1FocusNode,
                      decoration: const InputDecoration(labelText: 'Input 1'),
                    ),
                    TextField(
                      focusNode: input2FocusNode,
                      decoration: const InputDecoration(labelText: 'Input 2'),
                    ),
                  ],
                ),
                child: const Text('Popover Trigger'),
              ),
              TextField(
                focusNode: outsideFocusNode,
                decoration: const InputDecoration(labelText: 'Outside Input'),
              ),
            ],
          ),
        );

        // Open the popover
        controller.open();
        await tester.pumpAndSettle();

        // Tab to first input in popover
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(input1FocusNode.hasFocus, isTrue);

        // Tab to second input in popover
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(input2FocusNode.hasFocus, isTrue);

        // Tab again - focus should cycle back within popover, not escape outside
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Focus should NOT have escaped to the outside element
        expect(outsideFocusNode.hasFocus, isFalse);

        // Focus should still be within the popover (cycled back to first input)
        expect(input1FocusNode.hasFocus, isTrue);

        outsideFocusNode.dispose();
        input1FocusNode.dispose();
        input2FocusNode.dispose();
      });
    });
  });
}
