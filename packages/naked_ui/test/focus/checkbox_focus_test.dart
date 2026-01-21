/// ARIA Focus Behavior Tests for NakedCheckbox
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
/// - Tab: Checkbox receives focus in natural tab order
/// - Space: Toggles checked state
/// - Each checkbox is an independent tab stop
/// - Disabled checkboxes should NOT receive focus
///
/// States tested:
/// - aria-checked="true" — checked
/// - aria-checked="false" — unchecked
/// - aria-checked="mixed" — indeterminate (for tri-state checkboxes)
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedCheckbox ARIA Focus Behavior', () {
    group('Tab Navigation', () {
      testWidgets('Tab moves focus to checkbox in natural tab order', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeCheckbox = FocusNode(debugLabel: 'checkbox');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedCheckbox(
                focusNode: focusNodeCheckbox,
                value: false,
                onChanged: (_) {},
                child: const Text('Checkbox'),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the first element
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab to next element (checkbox)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeCheckbox.hasFocus, isTrue);

        // Tab to next element (after checkbox)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeCheckbox.dispose();
        focusNode3.dispose();
      });

      testWidgets('Shift+Tab moves focus to previous element', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeCheckbox = FocusNode(debugLabel: 'checkbox');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedCheckbox(
                focusNode: focusNodeCheckbox,
                value: false,
                onChanged: (_) {},
                child: const Text('Checkbox'),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the last element
        focusNode3.requestFocus();
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        // Shift+Tab to previous element (checkbox)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(focusNodeCheckbox.hasFocus, isTrue);

        // Shift+Tab to previous element (before checkbox)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeCheckbox.dispose();
        focusNode3.dispose();
      });

      testWidgets('Each checkbox is an independent tab stop', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'checkbox1');
        final focusNode2 = FocusNode(debugLabel: 'checkbox2');
        final focusNode3 = FocusNode(debugLabel: 'checkbox3');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              NakedCheckbox(
                focusNode: focusNode1,
                value: false,
                onChanged: (_) {},
                child: const Text('Checkbox 1'),
              ),
              NakedCheckbox(
                focusNode: focusNode2,
                value: true,
                onChanged: (_) {},
                child: const Text('Checkbox 2'),
              ),
              NakedCheckbox(
                focusNode: focusNode3,
                value: false,
                onChanged: (_) {},
                child: const Text('Checkbox 3'),
              ),
            ],
          ),
        );

        // Focus first checkbox
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab to second checkbox
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode2.hasFocus, isTrue);

        // Tab to third checkbox
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNode2.dispose();
        focusNode3.dispose();
      });
    });

    group('Disabled Checkbox Focus Behavior', () {
      testWidgets(
        'Disabled checkbox should NOT receive focus via Tab',
        (WidgetTester tester) async {
          final focusNode1 = FocusNode(debugLabel: 'before');
          final focusNodeDisabledCheckbox = FocusNode(debugLabel: 'disabled');
          final focusNode3 = FocusNode(debugLabel: 'after');

          await tester.pumpMaterialWidget(
            Column(
              children: [
                TextField(focusNode: focusNode1),
                NakedCheckbox(
                  focusNode: focusNodeDisabledCheckbox,
                  value: false,
                  onChanged: (_) {},
                  enabled: false,
                  child: const Text('Disabled Checkbox'),
                ),
                TextField(focusNode: focusNode3),
              ],
            ),
          );

          // Focus the first element
          focusNode1.requestFocus();
          await tester.pump();
          expect(focusNode1.hasFocus, isTrue);

          // Tab should skip disabled checkbox and go directly to next element
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(
            focusNodeDisabledCheckbox.hasFocus,
            isFalse,
            reason: 'Disabled checkbox should not receive focus',
          );
          expect(
            focusNode3.hasFocus,
            isTrue,
            reason: 'Focus should skip to next enabled element',
          );

          focusNode1.dispose();
          focusNodeDisabledCheckbox.dispose();
          focusNode3.dispose();
        },
      );

      testWidgets(
        'Checkbox with null onChanged should NOT receive focus via Tab',
        (WidgetTester tester) async {
          final focusNode1 = FocusNode(debugLabel: 'before');
          final focusNodeNullCheckbox = FocusNode(debugLabel: 'null onChanged');
          final focusNode3 = FocusNode(debugLabel: 'after');

          await tester.pumpMaterialWidget(
            Column(
              children: [
                TextField(focusNode: focusNode1),
                NakedCheckbox(
                  focusNode: focusNodeNullCheckbox,
                  value: false,
                  onChanged: null, // Non-interactive
                  child: const Text('Non-interactive Checkbox'),
                ),
                TextField(focusNode: focusNode3),
              ],
            ),
          );

          // Focus the first element
          focusNode1.requestFocus();
          await tester.pump();

          // Tab should skip checkbox with null onChanged
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(
            focusNodeNullCheckbox.hasFocus,
            isFalse,
            reason: 'Checkbox with null onChanged should not receive focus',
          );
          expect(focusNode3.hasFocus, isTrue);

          focusNode1.dispose();
          focusNodeNullCheckbox.dispose();
          focusNode3.dispose();
        },
      );

      testWidgets(
        'Disabled checkbox does not respond to programmatic focus request',
        (WidgetTester tester) async {
          final focusNodeDisabledCheckbox = FocusNode(debugLabel: 'disabled');

          await tester.pumpMaterialWidget(
            NakedCheckbox(
              focusNode: focusNodeDisabledCheckbox,
              value: false,
              onChanged: (_) {},
              enabled: false,
              child: const Text('Disabled Checkbox'),
            ),
          );

          // Attempt to focus programmatically
          focusNodeDisabledCheckbox.requestFocus();
          await tester.pump();

          // Should not be able to focus a disabled checkbox
          expect(
            focusNodeDisabledCheckbox.hasFocus,
            isFalse,
            reason: 'Disabled checkbox should not receive programmatic focus',
          );

          focusNodeDisabledCheckbox.dispose();
        },
      );

      testWidgets('Tab skips disabled checkboxes in a group', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'checkbox1');
        final focusNodeDisabled = FocusNode(debugLabel: 'disabled');
        final focusNode3 = FocusNode(debugLabel: 'checkbox3');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              NakedCheckbox(
                focusNode: focusNode1,
                value: false,
                onChanged: (_) {},
                child: const Text('Checkbox 1'),
              ),
              NakedCheckbox(
                focusNode: focusNodeDisabled,
                value: false,
                onChanged: (_) {},
                enabled: false,
                child: const Text('Disabled Checkbox'),
              ),
              NakedCheckbox(
                focusNode: focusNode3,
                value: false,
                onChanged: (_) {},
                child: const Text('Checkbox 3'),
              ),
            ],
          ),
        );

        // Focus first checkbox
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab should skip disabled and go to third
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeDisabled.hasFocus, isFalse);
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeDisabled.dispose();
        focusNode3.dispose();
      });
    });

    group('Keyboard Activation - Space Key', () {
      testWidgets('Space key toggles unchecked to checked', (
        WidgetTester tester,
      ) async {
        bool? currentValue = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedCheckbox(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            onChanged: (value) => currentValue = value,
            child: const Text('Space Test'),
          ),
        );

        await tester.pump(); // Allow autofocus to take effect

        expect(focusNode.hasFocus, isTrue);
        expect(currentValue, isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        expect(currentValue, isTrue);

        focusNode.dispose();
      });

      testWidgets('Space key toggles checked to unchecked', (
        WidgetTester tester,
      ) async {
        bool? currentValue = true;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedCheckbox(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            onChanged: (value) => currentValue = value,
            child: const Text('Space Test'),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);
        expect(currentValue, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        expect(currentValue, isFalse);

        focusNode.dispose();
      });

      testWidgets(
        'Space key does not toggle disabled checkbox',
        (WidgetTester tester) async {
          bool? currentValue = false;
          final focusNode = FocusNode();

          await tester.pumpMaterialWidget(
            NakedCheckbox(
              focusNode: focusNode,
              autofocus: true,
              value: currentValue,
              onChanged: (value) => currentValue = value,
              enabled: false,
              child: const Text('Disabled'),
            ),
          );

          await tester.pump();

          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pump();

          expect(currentValue, isFalse, reason: 'Value should not change');

          focusNode.dispose();
        },
      );

      testWidgets('Enter key also toggles checkbox', (
        WidgetTester tester,
      ) async {
        // Note: While ARIA spec says Space toggles checkbox,
        // Enter is also commonly supported for better usability
        bool? currentValue = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedCheckbox(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            onChanged: (value) => currentValue = value,
            child: const Text('Enter Test'),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);
        expect(currentValue, isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(currentValue, isTrue);

        focusNode.dispose();
      });
    });

    group('Tristate (Mixed) Behavior', () {
      testWidgets('Space key cycles through tristate values', (
        WidgetTester tester,
      ) async {
        bool? currentValue = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedCheckbox(
                focusNode: focusNode,
                autofocus: true,
                value: currentValue,
                tristate: true,
                onChanged: (value) => setState(() => currentValue = value),
                child: const Text('Tristate'),
              );
            },
          ),
        );

        await tester.pump();
        expect(focusNode.hasFocus, isTrue);

        // false -> true
        expect(currentValue, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(currentValue, isTrue);

        // true -> null (mixed)
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(currentValue, isNull);

        // null -> false
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(currentValue, isFalse);

        focusNode.dispose();
      });

      testWidgets('NakedCheckboxState correctly reports isIntermediate', (
        WidgetTester tester,
      ) async {
        NakedCheckboxState? capturedState;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedCheckbox(
            focusNode: focusNode,
            value: null,
            tristate: true,
            onChanged: (_) {},
            builder: (context, state, child) {
              capturedState = state;
              return child ?? const SizedBox();
            },
            child: const Text('Mixed State'),
          ),
        );

        expect(capturedState?.isIntermediate, isTrue);
        expect(capturedState?.isChecked, isNull);

        focusNode.dispose();
      });
    });

    group('Focus State Reporting', () {
      testWidgets('onFocusChange is called when focus is gained', (
        WidgetTester tester,
      ) async {
        bool? focusState;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedCheckbox(
            focusNode: focusNode,
            value: false,
            onChanged: (_) {},
            onFocusChange: (focused) => focusState = focused,
            child: const Text('Focus Test'),
          ),
        );

        focusNode.requestFocus();
        await tester.pump();

        expect(focusState, isTrue);

        focusNode.dispose();
      });

      testWidgets('onFocusChange is called when focus is lost', (
        WidgetTester tester,
      ) async {
        bool? focusState;
        final focusNode1 = FocusNode();
        final focusNode2 = FocusNode();

        await tester.pumpMaterialWidget(
          Column(
            children: [
              NakedCheckbox(
                focusNode: focusNode1,
                value: false,
                onChanged: (_) {},
                onFocusChange: (focused) => focusState = focused,
                child: const Text('Checkbox 1'),
              ),
              TextField(focusNode: focusNode2),
            ],
          ),
        );

        // Gain focus
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusState, isTrue);

        // Lose focus
        focusNode2.requestFocus();
        await tester.pump();
        expect(focusState, isFalse);

        focusNode1.dispose();
        focusNode2.dispose();
      });

      testWidgets('NakedCheckboxState correctly reflects focused state', (
        WidgetTester tester,
      ) async {
        NakedCheckboxState? capturedState;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedCheckbox(
            focusNode: focusNode,
            value: false,
            onChanged: (_) {},
            builder: (context, state, child) {
              capturedState = state;
              return child ?? const SizedBox();
            },
            child: const Text('State Test'),
          ),
        );

        // Initially not focused
        expect(capturedState?.isFocused, isFalse);

        // Focus the checkbox
        focusNode.requestFocus();
        await tester.pump();
        expect(capturedState?.isFocused, isTrue);

        focusNode.dispose();
      });
    });

    group('Checked State Reporting', () {
      testWidgets('NakedCheckboxState correctly reflects checked state', (
        WidgetTester tester,
      ) async {
        NakedCheckboxState? capturedState;

        // Test unchecked (false)
        await tester.pumpMaterialWidget(
          NakedCheckbox(
            value: false,
            onChanged: (_) {},
            builder: (context, state, child) {
              capturedState = state;
              return child ?? const SizedBox();
            },
            child: const Text('Unchecked'),
          ),
        );

        expect(capturedState?.isChecked, isFalse);

        // Test checked (true)
        await tester.pumpMaterialWidget(
          NakedCheckbox(
            value: true,
            onChanged: (_) {},
            builder: (context, state, child) {
              capturedState = state;
              return child ?? const SizedBox();
            },
            child: const Text('Checked'),
          ),
        );

        expect(capturedState?.isChecked, isTrue);
      });

      testWidgets('NakedCheckboxState correctly reflects tristate values', (
        WidgetTester tester,
      ) async {
        NakedCheckboxState? capturedState;

        // Test mixed/indeterminate (null)
        await tester.pumpMaterialWidget(
          NakedCheckbox(
            value: null,
            tristate: true,
            onChanged: (_) {},
            builder: (context, state, child) {
              capturedState = state;
              return child ?? const SizedBox();
            },
            child: const Text('Mixed'),
          ),
        );

        expect(capturedState?.isChecked, isNull);
        expect(capturedState?.isIntermediate, isTrue);
        expect(capturedState?.tristate, isTrue);
      });
    });

    group('Autofocus', () {
      testWidgets('Checkbox with autofocus receives initial focus', (
        WidgetTester tester,
      ) async {
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedCheckbox(
            focusNode: focusNode,
            autofocus: true,
            value: false,
            onChanged: (_) {},
            child: const Text('Autofocus Checkbox'),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);

        focusNode.dispose();
      });

      testWidgets('Only first autofocus checkbox receives focus', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode();
        final focusNode2 = FocusNode();

        await tester.pumpMaterialWidget(
          Column(
            children: [
              NakedCheckbox(
                focusNode: focusNode1,
                autofocus: true,
                value: false,
                onChanged: (_) {},
                child: const Text('First Autofocus'),
              ),
              NakedCheckbox(
                focusNode: focusNode2,
                autofocus: true,
                value: false,
                onChanged: (_) {},
                child: const Text('Second Autofocus'),
              ),
            ],
          ),
        );

        await tester.pump();

        expect(focusNode1.hasFocus, isTrue);
        expect(focusNode2.hasFocus, isFalse);

        focusNode1.dispose();
        focusNode2.dispose();
      });
    });
  });
}

