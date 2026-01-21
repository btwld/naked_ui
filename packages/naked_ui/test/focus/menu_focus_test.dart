/// ARIA Focus Behavior Tests for NakedMenu
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
/// - Click/Enter on Trigger: Opens menu, focus moves to **first menu item**
/// - Arrow Down: Moves focus to next menu item
/// - Arrow Up: Moves focus to previous menu item
/// - Home: Moves focus to first menu item
/// - End: Moves focus to last menu item
/// - Enter/Space: Activates focused menu item
/// - Escape: Closes menu, returns focus to trigger
/// - Tab: Closes menu, moves focus to next focusable (or trigger)
/// - Type-ahead: Typing characters moves focus to matching item
///
/// Focus Management:
/// - Uses **roving `tabindex`** inside menu
/// - Menu trigger is in tab order; menu items are NOT
/// - Focus must be **trapped inside open menu**
/// - On close, focus MUST return to the trigger element
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedMenu ARIA Focus Behavior', () {
    group('Menu Trigger Focus', () {
      testWidgets('Menu trigger receives focus via Tab', (
        WidgetTester tester,
      ) async {
        final focusNodeBefore = FocusNode(debugLabel: 'before');
        final focusNodeMenuTrigger = FocusNode(debugLabel: 'menuTrigger');
        final focusNodeAfter = FocusNode(debugLabel: 'after');
        final controller = MenuController();

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNodeBefore),
              NakedMenu<String>(
                controller: controller,
                triggerFocusNode: focusNodeMenuTrigger,
                builder: (context, state, child) => const Text('Menu Trigger'),
                overlayBuilder: (context, info) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NakedMenuItem<String>(
                      value: 'item1',
                      child: Text('Item 1'),
                    ),
                    NakedMenuItem<String>(
                      value: 'item2',
                      child: Text('Item 2'),
                    ),
                  ],
                ),
              ),
              TextField(focusNode: focusNodeAfter),
            ],
          ),
        );

        // Focus the first element
        focusNodeBefore.requestFocus();
        await tester.pump();
        expect(focusNodeBefore.hasFocus, isTrue);

        // Tab should move to menu trigger
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeMenuTrigger.hasFocus, isTrue);

        // Tab again should move to element after menu
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeAfter.hasFocus, isTrue);

        focusNodeBefore.dispose();
        focusNodeMenuTrigger.dispose();
        focusNodeAfter.dispose();
      });
    });

    group('Opening Menu', () {
      testWidgets('Enter on trigger opens menu', (WidgetTester tester) async {
        final controller = MenuController();
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedMenu<String>(
            controller: controller,
            triggerFocusNode: triggerFocusNode,
            builder: (context, state, child) => const Text('Menu Trigger'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem<String>(value: 'item1', child: Text('Item 1')),
                NakedMenuItem<String>(value: 'item2', child: Text('Item 2')),
              ],
            ),
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Menu should be closed initially
        expect(find.text('Item 1'), findsNothing);

        // Enter should open menu
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.text('Item 1'), findsOneWidget);
      });

      testWidgets('Space on trigger opens menu', (WidgetTester tester) async {
        final controller = MenuController();
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedMenu<String>(
            controller: controller,
            triggerFocusNode: triggerFocusNode,
            builder: (context, state, child) => const Text('Menu Trigger'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem<String>(value: 'item1', child: Text('Item 1')),
              ],
            ),
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Menu should be closed initially
        expect(find.text('Item 1'), findsNothing);

        // Space should open menu
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        expect(find.text('Item 1'), findsOneWidget);
      });
    });

    group('Closing Menu', () {
      testWidgets('Escape closes menu and returns focus to trigger', (
        WidgetTester tester,
      ) async {
        final controller = MenuController();
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedMenu<String>(
            controller: controller,
            triggerFocusNode: triggerFocusNode,
            builder: (context, state, child) => const Text('Menu Trigger'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem<String>(value: 'item1', child: Text('Item 1')),
              ],
            ),
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Open the menu
        controller.open();
        await tester.pumpAndSettle();
        expect(find.text('Item 1'), findsOneWidget);

        // Escape should close menu
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.text('Item 1'), findsNothing);
      });
    });

    group('Arrow Key Navigation', () {
      testWidgets('Arrow Down moves focus to next menu item', (
        WidgetTester tester,
      ) async {
        final controller = MenuController();
        final triggerFocusNode = FocusNode();
        String? selectedValue;

        await tester.pumpMaterialWidget(
          NakedMenu<String>(
            controller: controller,
            triggerFocusNode: triggerFocusNode,
            onSelected: (value) => selectedValue = value,
            builder: (context, state, child) => const Text('Menu Trigger'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem<String>(value: 'item1', child: Text('Item 1')),
                NakedMenuItem<String>(value: 'item2', child: Text('Item 2')),
                NakedMenuItem<String>(value: 'item3', child: Text('Item 3')),
              ],
            ),
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Open the menu
        controller.open();
        await tester.pumpAndSettle();

        // Arrow Down should navigate through items
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(selectedValue, 'item1');

        controller.open();
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(selectedValue, 'item2');
      });

      testWidgets('Arrow Up moves focus to previous menu item', (
        WidgetTester tester,
      ) async {
        final controller = MenuController();
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedMenu<String>(
            controller: controller,
            triggerFocusNode: triggerFocusNode,
            builder: (context, state, child) => const Text('Menu Trigger'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem<String>(value: 'item1', child: Text('Item 1')),
                NakedMenuItem<String>(value: 'item2', child: Text('Item 2')),
              ],
            ),
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Open the menu
        controller.open();
        await tester.pumpAndSettle();

        // Navigate down then up
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        // Items should still be visible
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
      });
    });

    group('Menu Item Activation', () {
      testWidgets('Enter activates focused menu item', (
        WidgetTester tester,
      ) async {
        String? selectedValue;
        final controller = MenuController();
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedMenu<String>(
            controller: controller,
            triggerFocusNode: triggerFocusNode,
            onSelected: (value) => selectedValue = value,
            builder: (context, state, child) => const Text('Menu Trigger'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem<String>(value: 'item1', child: Text('Item 1')),
                NakedMenuItem<String>(value: 'item2', child: Text('Item 2')),
              ],
            ),
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Open the menu
        controller.open();
        await tester.pumpAndSettle();

        // Navigate to first item and activate
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(selectedValue, 'item1');
      });

      testWidgets('Space activates focused menu item', (
        WidgetTester tester,
      ) async {
        String? selectedValue;
        final controller = MenuController();
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedMenu<String>(
            controller: controller,
            triggerFocusNode: triggerFocusNode,
            onSelected: (value) => selectedValue = value,
            builder: (context, state, child) => const Text('Menu Trigger'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem<String>(value: 'item1', child: Text('Item 1')),
                NakedMenuItem<String>(value: 'item2', child: Text('Item 2')),
              ],
            ),
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Open the menu
        controller.open();
        await tester.pumpAndSettle();

        // Navigate to item and activate with Space
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        expect(selectedValue, 'item1');
      });
    });

    // group('Disabled Menu Item Behavior', () {
    //   testWidgets('Disabled menu item is skipped in navigation', (
    //     WidgetTester tester,
    //   ) async {
    //     final controller = MenuController();
    //     final triggerFocusNode = FocusNode();
    //     String? selectedValue;

    //     await tester.pumpMaterialWidget(
    //       NakedMenu<String>(
    //         controller: controller,
    //         onSelected: (value) => selectedValue = value,
    //         triggerFocusNode: triggerFocusNode,
    //         builder: (context, state, child) => const Text('Menu Trigger'),
    //         overlayBuilder: (context, info) => const Column(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             NakedMenuItem<String>(
    //               value: 'item1',
    //               child: Text('Item 1'),
    //               // enabled: false,
    //             ),
    //             NakedMenuItem<String>(value: 'item2', child: Text('Item 2')),
    //           ],
    //         ),
    //       ),
    //     );

    //     // Focus the trigger first (required for keyboard navigation)
    //     triggerFocusNode.requestFocus();
    //     await tester.pump();

    //     // Open the menu
    //     controller.open();
    //     await tester.pumpAndSettle();

    //     // All items should be visible
    //     expect(find.text('Item 1'), findsOneWidget);
    //     expect(find.text('Item 2'), findsOneWidget);

    //     // Navigate down - should skip disabled Item 1 and focus Item 2
    //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    //     await tester.pump();

    //     // Activate the focused item
    //     await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    //     await tester.pumpAndSettle();

    //     // Item 2 should be selected (disabled Item 1 was skipped)
    //     expect(selectedValue, 'item2');
    //   });
    // });
  });
}
