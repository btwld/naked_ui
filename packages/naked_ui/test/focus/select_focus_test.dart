/// ARIA Focus Behavior Tests for NakedSelect (Combobox)
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
/// - Tab: Combobox trigger/input receives focus
/// - Enter/Space/Arrow Down: Opens dropdown, focus moves to selected option (or first)
/// - Arrow Down (open): Moves focus to next option
/// - Arrow Up (open): Moves focus to previous option
/// - Home (open): Moves focus to first option
/// - End (open): Moves focus to last option
/// - Enter/Space (open): Selects focused option, closes dropdown
/// - Escape: Closes dropdown without selecting, returns focus to trigger
/// - Tab (open): Selects focused option, closes dropdown, moves to next element
/// - Type-ahead: Filters or jumps to matching option
///
/// Focus Management Options:
/// - **DOM Focus**: Focus actually moves to options in the listbox
/// - **`aria-activedescendant`**: Focus stays on combobox; `aria-activedescendant` points to active option
///
/// Notes:
/// - When dropdown closes, focus MUST return to trigger
/// - Selected option should be announced to screen readers
/// - For multi-select: Space toggles selection, maintains dropdown open
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedSelect ARIA Focus Behavior', () {
    Widget buildSelect<T>({
      T? selectedValue,
      ValueChanged<T?>? onSelectedValueChanged,
      bool enabled = true,
      FocusNode? triggerFocusNode,
    }) {
      return Center(
        child: NakedSelect<T>(
          value: selectedValue,
          onChanged: onSelectedValueChanged,
          enabled: enabled,
          triggerFocusNode: triggerFocusNode,
          builder: (context, state, child) => const Text('Select option'),
          overlayBuilder: (context, info) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedSelectOption<T>(
                value: 'apple' as T,
                child: const Text('Apple'),
              ),
              NakedSelectOption<T>(
                value: 'banana' as T,
                child: const Text('Banana'),
              ),
              NakedSelectOption<T>(
                value: 'orange' as T,
                child: const Text('Orange'),
              ),
            ],
          ),
        ),
      );
    }

    group('Tab Navigation', () {
      testWidgets('Tab moves focus to select trigger', (
        WidgetTester tester,
      ) async {
        final focusNodeBefore = FocusNode(debugLabel: 'before');
        final focusNodeSelectTrigger = FocusNode(debugLabel: 'selectTrigger');
        final focusNodeAfter = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNodeBefore),
              buildSelect<String>(triggerFocusNode: focusNodeSelectTrigger),
              TextField(focusNode: focusNodeAfter),
            ],
          ),
        );

        // Focus the first element
        focusNodeBefore.requestFocus();
        await tester.pump();
        expect(focusNodeBefore.hasFocus, isTrue);

        // Tab should move to select trigger
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeBefore.hasFocus, isFalse);
        expect(focusNodeSelectTrigger.hasFocus, isTrue);

        // Tab again should move to element after select
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeAfter.hasFocus, isTrue);

        focusNodeBefore.dispose();
        focusNodeSelectTrigger.dispose();
        focusNodeAfter.dispose();
      });
    });

    group('Opening Dropdown', () {
      testWidgets('Enter opens dropdown', (WidgetTester tester) async {
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          buildSelect<String>(
            triggerFocusNode: triggerFocusNode,
            onSelectedValueChanged: (_) {},
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Dropdown should be closed initially
        expect(find.text('Apple'), findsNothing);

        // Enter should open dropdown
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.text('Apple'), findsOneWidget);

        triggerFocusNode.dispose();
      });

      testWidgets('Space opens dropdown', (WidgetTester tester) async {
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          buildSelect<String>(
            triggerFocusNode: triggerFocusNode,
            onSelectedValueChanged: (_) {},
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Dropdown should be closed initially
        expect(find.text('Apple'), findsNothing);

        // Space should open dropdown
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        expect(find.text('Apple'), findsOneWidget);

        triggerFocusNode.dispose();
      });
      // TODO (tilucasoli): Arrow Down opens dropdown is not implemented.
      // testWidgets('Arrow Down opens dropdown', (WidgetTester tester) async {
      //   final triggerFocusNode = FocusNode();
      //
      //   await tester.pumpMaterialWidget(
      //     buildSelect<String>(
      //       triggerFocusNode: triggerFocusNode,
      //       onSelectedValueChanged: (_) {},
      //     ),
      //   );
      //
      //   triggerFocusNode.requestFocus();
      //   await tester.pump();
      //
      //   // Arrow Down should open dropdown
      //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      //   await tester.pumpAndSettle();
      //
      //   expect(find.text('Apple'), findsOneWidget);
      //
      //   triggerFocusNode.dispose();
      // });
    });

    group('Closing Dropdown', () {
      testWidgets('Escape closes dropdown without selecting', (
        WidgetTester tester,
      ) async {
        String? selectedValue;
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          buildSelect<String>(
            selectedValue: selectedValue,
            triggerFocusNode: triggerFocusNode,
            onSelectedValueChanged: (value) => selectedValue = value,
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Open dropdown
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Apple'), findsOneWidget);

        // Escape should close without selecting
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.text('Apple'), findsNothing);
        expect(selectedValue, isNull);

        triggerFocusNode.dispose();
      });
    });

    group('Arrow Key Navigation', () {
      // TODO: The tests inside this group should be rewritten using the FocusNode on the options
      // testWidgets('Arrow Down navigates through options', (
      //   WidgetTester tester,
      // ) async {
      //   String? selectedValue;
      //   final triggerFocusNode = FocusNode();

      //   await tester.pumpMaterialWidget(
      //     buildSelect<String>(
      //       triggerFocusNode: triggerFocusNode,
      //       onSelectedValueChanged: (value) => selectedValue = value,
      //     ),
      //   );

      //   triggerFocusNode.requestFocus();
      //   await tester.pump();

      //   // Open dropdown
      //   await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      //   await tester.pumpAndSettle();

      //   // Arrow Down should navigate
      //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      //   await tester.pump();

      //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      //   await tester.pump();

      //   await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      //   await tester.pump();

      //   // Options should still be visible
      //   expect(find.text('Apple'), findsNothing);
      //   expect(find.text('Banana'), findsNothing);
      //   expect(find.text('Orange'), findsNothing);

      //   expect(selectedValue, 'orange');

      //   triggerFocusNode.dispose();
      // });

      // TODO (tilucasoli): Arrow Up navigates through options is not implemented.
      // testWidgets('Arrow Up navigates through options', (
      //   WidgetTester tester,
      // ) async {
      //   final triggerFocusNode = FocusNode();
      //   String? selectedValue;
      //
      //   await tester.pumpMaterialWidget(
      //     buildSelect<String>(
      //       triggerFocusNode: triggerFocusNode,
      //       onSelectedValueChanged: (value) => selectedValue = value,
      //     ),
      //   );
      //
      //   triggerFocusNode.requestFocus();
      //   await tester.pump();
      //
      //   // Open dropdown
      //   await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      //   await tester.pumpAndSettle();
      //
      //   // Navigate down then up
      //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      //   await tester.pump();
      //
      //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      //   await tester.pump();
      //
      //   await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      //   await tester.pump();
      //
      //   // Options should still be visible
      //   expect(find.text('Apple'), findsNothing);
      //   expect(find.text('Banana'), findsNothing);
      //   expect(find.text('Orange'), findsNothing);
      //
      //   expect(selectedValue, 'apple');
      //
      //   triggerFocusNode.dispose();
      // });
    });

    group('Option Selection', () {
      testWidgets('Enter selects focused option and closes dropdown', (
        WidgetTester tester,
      ) async {
        String? selectedValue;
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return buildSelect<String>(
                selectedValue: selectedValue,
                triggerFocusNode: triggerFocusNode,
                onSelectedValueChanged: (value) =>
                    setState(() => selectedValue = value),
              );
            },
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Open dropdown
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Navigate to an option
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        // Select with Enter
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Dropdown should be closed and value selected
        expect(selectedValue, isNotNull);

        triggerFocusNode.dispose();
      });
    });

    group('Disabled Select Behavior', () {
      testWidgets('Disabled select should NOT receive focus via Tab', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              buildSelect<String>(enabled: false),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the first element
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab should skip disabled select
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNode3.dispose();
      });

      testWidgets('Disabled select does not open on keyboard activation', (
        WidgetTester tester,
      ) async {
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          buildSelect<String>(
            enabled: false,
            triggerFocusNode: triggerFocusNode,
          ),
        );

        triggerFocusNode.requestFocus();
        await tester.pump();

        // Enter should NOT open disabled select
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.text('Apple'), findsNothing);

        triggerFocusNode.dispose();
      });
    });
  });
}
