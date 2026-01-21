/// ARIA Focus Behavior Tests for NakedToggle (Switch)
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
/// - Tab: Switch receives focus in natural tab order
/// - Space: Toggles the switch on/off
/// - Enter: (Optional) May also toggle
///
/// States:
/// - `aria-checked="true"` — on
/// - `aria-checked="false"` — off
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedToggle ARIA Focus Behavior', () {
    group('Tab Navigation', () {
      testWidgets('Tab moves focus to toggle in natural tab order', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeToggle = FocusNode(debugLabel: 'toggle');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedToggle(
                focusNode: focusNodeToggle,
                value: false,
                onChanged: (_) {},
                child: const Text('Toggle'),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the first element
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab to next element (toggle)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeToggle.hasFocus, isTrue);

        // Tab to next element (after toggle)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeToggle.dispose();
        focusNode3.dispose();
      });

      testWidgets('Shift+Tab moves focus to previous element', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeToggle = FocusNode(debugLabel: 'toggle');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedToggle(
                focusNode: focusNodeToggle,
                value: false,
                onChanged: (_) {},
                child: const Text('Toggle'),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the last element
        focusNode3.requestFocus();
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        // Shift+Tab to previous element (toggle)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(focusNodeToggle.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeToggle.dispose();
        focusNode3.dispose();
      });
    });

    group('Disabled Toggle Focus Behavior', () {
      testWidgets('Disabled toggle should NOT receive focus via Tab', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeDisabledToggle = FocusNode(debugLabel: 'disabled');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedToggle(
                focusNode: focusNodeDisabledToggle,
                value: false,
                onChanged: (_) {},
                enabled: false,
                child: const Text('Disabled Toggle'),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the first element
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab should skip disabled toggle
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          focusNodeDisabledToggle.hasFocus,
          isFalse,
          reason: 'Disabled toggle should not receive focus',
        );
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeDisabledToggle.dispose();
        focusNode3.dispose();
      });

      testWidgets(
        'Toggle with null onChanged should NOT receive focus via Tab',
        (WidgetTester tester) async {
          final focusNode1 = FocusNode(debugLabel: 'before');
          final focusNodeNullToggle = FocusNode(debugLabel: 'null onChanged');
          final focusNode3 = FocusNode(debugLabel: 'after');

          await tester.pumpMaterialWidget(
            Column(
              children: [
                TextField(focusNode: focusNode1),
                NakedToggle(
                  focusNode: focusNodeNullToggle,
                  value: false,
                  onChanged: null, // Non-interactive
                  child: const Text('Non-interactive Toggle'),
                ),
                TextField(focusNode: focusNode3),
              ],
            ),
          );

          // Focus the first element
          focusNode1.requestFocus();
          await tester.pump();

          // Tab should skip toggle with null onChanged
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(focusNodeNullToggle.hasFocus, isFalse);
          expect(focusNode3.hasFocus, isTrue);

          focusNode1.dispose();
          focusNodeNullToggle.dispose();
          focusNode3.dispose();
        },
      );
    });

    group('Keyboard Activation - Space Key', () {
      testWidgets('Space key toggles off to on', (WidgetTester tester) async {
        bool currentValue = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedToggle(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            onChanged: (value) => currentValue = value,
            child: const Text('Space Test'),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);
        expect(currentValue, isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        expect(currentValue, isTrue);

        focusNode.dispose();
      });

      testWidgets('Space key toggles on to off', (WidgetTester tester) async {
        bool currentValue = true;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedToggle(
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

      testWidgets('Space key does not toggle disabled switch', (
        WidgetTester tester,
      ) async {
        bool currentValue = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedToggle(
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
      });

      testWidgets('Enter key also toggles switch', (WidgetTester tester) async {
        bool currentValue = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedToggle(
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

    group('Focus State Reporting', () {
      testWidgets('onFocusChange is called when focus is gained', (
        WidgetTester tester,
      ) async {
        bool? focusState;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedToggle(
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
              NakedToggle(
                focusNode: focusNode1,
                value: false,
                onChanged: (_) {},
                onFocusChange: (focused) => focusState = focused,
                child: const Text('Toggle 1'),
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
    });

    group('Autofocus', () {
      testWidgets('Toggle with autofocus receives initial focus', (
        WidgetTester tester,
      ) async {
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedToggle(
            focusNode: focusNode,
            autofocus: true,
            value: false,
            onChanged: (_) {},
            child: const Text('Autofocus Toggle'),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);

        focusNode.dispose();
      });
    });
  });
}
