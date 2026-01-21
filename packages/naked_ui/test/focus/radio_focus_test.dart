/// ARIA Focus Behavior Tests for NakedRadio
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
/// - Tab: Focus enters the radio group on the **checked** radio; if none checked, focus goes to **first** radio
/// - Tab (exit): Focus leaves the entire radio group to next focusable element
/// - Arrow Down/Right: Moves focus to next radio (and selects it)
/// - Arrow Up/Left: Moves focus to previous radio (and selects it)
/// - Space: Selects the focused radio (if not already selected)
/// - Home: (Optional) Moves focus to first radio
/// - End: (Optional) Moves focus to last radio
///
/// Focus Management:
/// - Uses **roving `tabindex`** — only one radio has `tabindex="0"`
/// - The entire group is ONE tab stop
/// - Arrow keys wrap (optional, but recommended)
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedRadio ARIA Focus Behavior', () {
    group('Tab Navigation - Single Tab Stop for Group', () {
      testWidgets('Tab enters radio group on first radio when none selected', (
        WidgetTester tester,
      ) async {
        final focusNodeBefore = FocusNode(debugLabel: 'before');
        final focusNodeRadio1 = FocusNode(debugLabel: 'radio1');
        final focusNodeRadio2 = FocusNode(debugLabel: 'radio2');
        final focusNodeRadio3 = FocusNode(debugLabel: 'radio3');
        final focusNodeAfter = FocusNode(debugLabel: 'after');

        String? selectedValue;

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNodeBefore),
              RadioGroup<String>(
                groupValue: selectedValue,
                onChanged: (value) => selectedValue = value,
                child: Column(
                  children: [
                    NakedRadio<String>(
                      value: 'option1',
                      focusNode: focusNodeRadio1,
                      child: Text('Option 1'),
                    ),
                    NakedRadio<String>(
                      value: 'option2',
                      focusNode: focusNodeRadio2,
                      child: Text('Option 2'),
                    ),
                    NakedRadio<String>(
                      value: 'option3',
                      focusNode: focusNodeRadio3,
                      child: Text('Option 3'),
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

        // Tab should enter the radio group
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Focus should be within the radio group (first radio)
        expect(focusNodeBefore.hasFocus, isFalse);
        expect(focusNodeAfter.hasFocus, isFalse);
        expect(focusNodeRadio1.hasFocus, isTrue);
        expect(focusNodeRadio2.hasFocus, isFalse);
        expect(focusNodeRadio3.hasFocus, isFalse);

        focusNodeBefore.dispose();
        focusNodeAfter.dispose();
        focusNodeRadio1.dispose();
        focusNodeRadio2.dispose();
        focusNodeRadio3.dispose();
      });

      testWidgets('Tab exits radio group to next focusable element', (
        WidgetTester tester,
      ) async {
        final focusNodeBefore = FocusNode(debugLabel: 'before');
        final focusNodeRadio1 = FocusNode(debugLabel: 'radio1');
        final focusNodeRadio2 = FocusNode(debugLabel: 'radio2');
        final focusNodeAfter = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNodeBefore),
              RadioGroup<String>(
                groupValue: 'option1',
                onChanged: (_) {},
                child: Column(
                  children: [
                    NakedRadio<String>(
                      value: 'option1',
                      autofocus: true,
                      focusNode: focusNodeRadio1,
                      child: Text('Option 1'),
                    ),
                    NakedRadio<String>(
                      value: 'option2',
                      focusNode: focusNodeRadio2,
                      child: Text('Option 2'),
                    ),
                  ],
                ),
              ),
              TextField(focusNode: focusNodeAfter),
            ],
          ),
        );

        await tester.pump();

        focusNodeRadio1.requestFocus();
        await tester.pump();

        expect(focusNodeBefore.hasFocus, isFalse);
        expect(focusNodeRadio1.hasFocus, isTrue);
        expect(focusNodeRadio2.hasFocus, isFalse);
        expect(focusNodeAfter.hasFocus, isFalse);

        // Tab should exit the radio group
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        expect(focusNodeBefore.hasFocus, isFalse);
        expect(focusNodeRadio1.hasFocus, isFalse);
        expect(focusNodeRadio2.hasFocus, isFalse);
        expect(focusNodeAfter.hasFocus, isTrue);

        focusNodeBefore.dispose();
        focusNodeRadio1.dispose();
        focusNodeRadio2.dispose();
        focusNodeAfter.dispose();
      });
    });

    group('Arrow Key Navigation', () {
      testWidgets('Arrow Down moves focus to next radio', (
        WidgetTester tester,
      ) async {
        String? selectedValue = 'option1';

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return RadioGroup<String>(
                groupValue: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                child: const Column(
                  children: [
                    NakedRadio<String>(
                      value: 'option1',
                      autofocus: true,
                      child: Text('Option 1'),
                    ),
                    NakedRadio<String>(
                      value: 'option2',
                      child: Text('Option 2'),
                    ),
                    NakedRadio<String>(
                      value: 'option3',
                      child: Text('Option 3'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Down should move to next and select
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(selectedValue, 'option2');
      });

      testWidgets('Arrow Up moves focus to previous radio', (
        WidgetTester tester,
      ) async {
        String? selectedValue = 'option2';

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return RadioGroup<String>(
                groupValue: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                child: const Column(
                  children: [
                    NakedRadio<String>(
                      value: 'option1',
                      child: Text('Option 1'),
                    ),
                    NakedRadio<String>(
                      value: 'option2',
                      autofocus: true,
                      child: Text('Option 2'),
                    ),
                    NakedRadio<String>(
                      value: 'option3',
                      child: Text('Option 3'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Up should move to previous and select
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(selectedValue, 'option1');
      });

      testWidgets('Arrow Right moves focus to next radio (horizontal)', (
        WidgetTester tester,
      ) async {
        String? selectedValue = 'option1';

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return RadioGroup<String>(
                groupValue: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                child: const Row(
                  children: [
                    NakedRadio<String>(
                      value: 'option1',
                      autofocus: true,
                      child: Text('Option 1'),
                    ),
                    NakedRadio<String>(
                      value: 'option2',
                      child: Text('Option 2'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Right should move to next and select
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(selectedValue, 'option2');
      });

      testWidgets('Arrow Left moves focus to previous radio (horizontal)', (
        WidgetTester tester,
      ) async {
        String? selectedValue = 'option2';

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return RadioGroup<String>(
                groupValue: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                child: const Row(
                  children: [
                    NakedRadio<String>(
                      value: 'option1',
                      child: Text('Option 1'),
                    ),
                    NakedRadio<String>(
                      value: 'option2',
                      autofocus: true,
                      child: Text('Option 2'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Left should move to previous and select
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();

        expect(selectedValue, 'option1');
      });
    });

    group('Disabled Radio Behavior', () {
      // TODO (tilucasoli): Disabled radio is skipped in navigation.
      // testWidgets('Disabled radio is skipped in navigation', (
      //   WidgetTester tester,
      // ) async {
      //   String? selectedValue = 'option1';
      //
      //   await tester.pumpMaterialWidget(
      //     StatefulBuilder(
      //       builder: (context, setState) {
      //         return RadioGroup<String>(
      //           groupValue: selectedValue,
      //           onChanged: (value) => setState(() => selectedValue = value),
      //           child: const Column(
      //             children: [
      //               NakedRadio<String>(
      //                 value: 'option1',
      //                 autofocus: true,
      //                 child: Text('Option 1'),
      //               ),
      //               NakedRadio<String>(
      //                 value: 'option2',
      //                 enabled: false,
      //                 child: Text('Option 2 (disabled)'),
      //               ),
      //               NakedRadio<String>(
      //                 value: 'option3',
      //                 child: Text('Option 3'),
      //               ),
      //             ],
      //           ),
      //         );
      //       },
      //     ),
      //   );
      //
      //   await tester.pump();
      //
      //   // Arrow Down should skip disabled and go to option3
      //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      //   await tester.pump();
      //
      //   // Note: Behavior depends on implementation - disabled may be skipped
      //   // or included but not selectable
      //   expect(selectedValue, isNot('option2'));
      // });
    });

    group('Focus State Reporting', () {
      testWidgets('onFocusChange is called when radio gains focus', (
        WidgetTester tester,
      ) async {
        bool? focusState;

        await tester.pumpMaterialWidget(
          RadioGroup<String>(
            groupValue: 'option1',
            onChanged: (_) {},
            child: Column(
              children: [
                NakedRadio<String>(
                  value: 'option1',
                  autofocus: true,
                  onFocusChange: (focused) => focusState = focused,
                  child: const Text('Option 1'),
                ),
              ],
            ),
          ),
        );

        await tester.pump();
        expect(focusState, isTrue);
      });

      testWidgets('onFocusChange is called when radio loses focus', (
        WidgetTester tester,
      ) async {
        bool? focusState;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          RadioGroup<String>(
            groupValue: 'option1',
            onChanged: (_) {},
            child: Column(
              children: [
                NakedRadio<String>(
                  value: 'option1',
                  autofocus: true,
                  onFocusChange: (focused) => focusState = focused,
                  child: const Text('Option 1'),
                ),
                Focus(
                  focusNode: focusNode,
                  child: const Text('Other focusable'),
                ),
              ],
            ),
          ),
        );

        await tester.pump();
        expect(focusState, isTrue);

        // Move focus away from the radio
        focusNode.requestFocus();
        await tester.pump();

        expect(focusState, isFalse);
      });

      testWidgets('NakedRadioState correctly reflects selected state', (
        WidgetTester tester,
      ) async {
        NakedRadioState<String>? capturedState;

        await tester.pumpMaterialWidget(
          RadioGroup<String>(
            groupValue: 'option1',
            onChanged: (_) {},
            child: Column(
              children: [
                NakedRadio<String>(
                  value: 'option1',
                  builder: (context, state, child) {
                    capturedState = state;
                    return child ?? const SizedBox();
                  },
                  child: const Text('Option 1'),
                ),
                const NakedRadio<String>(
                  value: 'option2',
                  child: Text('Option 2'),
                ),
              ],
            ),
          ),
        );

        expect(capturedState?.isSelected, isTrue);
        expect(capturedState?.value, 'option1');
      });
    });
  });
}
