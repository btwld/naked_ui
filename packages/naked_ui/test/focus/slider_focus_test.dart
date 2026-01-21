/// ARIA Focus Behavior Tests for NakedSlider
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
/// - Tab: Slider thumb receives focus
/// - Arrow Right/Up: Increases value by one step
/// - Arrow Left/Down: Decreases value by one step
/// - Page Up: Increases value by larger step (e.g., 10%)
/// - Page Down: Decreases value by larger step
/// - Home: Sets value to minimum
/// - End: Sets value to maximum
///
/// Required Attributes:
/// - `aria-valuenow` — current value
/// - `aria-valuemin` — minimum value
/// - `aria-valuemax` — maximum value
/// - `aria-valuetext` — (optional) human-readable value
///
/// Notes:
/// - For range sliders with two thumbs, each thumb is a separate tab stop
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedSlider ARIA Focus Behavior', () {
    group('Tab Navigation', () {
      testWidgets('Tab moves focus to slider in natural tab order', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeSlider = FocusNode(debugLabel: 'slider');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedSlider(
                focusNode: focusNodeSlider,
                value: 0.5,
                onChanged: (_) {},
                child: const SizedBox(width: 200, height: 40),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the first element
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab to next element (slider)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeSlider.hasFocus, isTrue);

        // Tab to next element (after slider)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeSlider.dispose();
        focusNode3.dispose();
      });

      testWidgets('Shift+Tab moves focus to previous element', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeSlider = FocusNode(debugLabel: 'slider');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedSlider(
                focusNode: focusNodeSlider,
                value: 0.5,
                onChanged: (_) {},
                child: const SizedBox(width: 200, height: 40),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the last element
        focusNode3.requestFocus();
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        // Shift+Tab to previous element (slider)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(focusNodeSlider.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeSlider.dispose();
        focusNode3.dispose();
      });
    });

    group('Disabled Slider Focus Behavior', () {
      testWidgets('Disabled slider should NOT receive focus via Tab', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeDisabledSlider = FocusNode(debugLabel: 'disabled');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedSlider(
                focusNode: focusNodeDisabledSlider,
                value: 0.5,
                onChanged: (_) {},
                enabled: false,
                child: const SizedBox(width: 200, height: 40),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the first element
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab should skip disabled slider
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          focusNodeDisabledSlider.hasFocus,
          isFalse,
          reason: 'Disabled slider should not receive focus',
        );
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeDisabledSlider.dispose();
        focusNode3.dispose();
      });

      testWidgets(
        'Slider with null onChanged should NOT receive focus via Tab',
        (WidgetTester tester) async {
          final focusNode1 = FocusNode(debugLabel: 'before');
          final focusNodeNullSlider = FocusNode(debugLabel: 'null onChanged');
          final focusNode3 = FocusNode(debugLabel: 'after');

          await tester.pumpMaterialWidget(
            Column(
              children: [
                TextField(focusNode: focusNode1),
                NakedSlider(
                  focusNode: focusNodeNullSlider,
                  value: 0.5,
                  onChanged: null, // Non-interactive
                  child: const SizedBox(width: 200, height: 40),
                ),
                TextField(focusNode: focusNode3),
              ],
            ),
          );

          // Focus the first element
          focusNode1.requestFocus();
          await tester.pump();

          // Tab should skip slider with null onChanged
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(focusNodeNullSlider.hasFocus, isFalse);
          expect(focusNode3.hasFocus, isTrue);

          focusNode1.dispose();
          focusNodeNullSlider.dispose();
          focusNode3.dispose();
        },
      );
    });

    group('Arrow Key Navigation', () {
      testWidgets('Arrow Right increases value', (WidgetTester tester) async {
        double currentValue = 0.5;
        const keyboardStep = 0.1;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedSlider(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            keyboardStep: keyboardStep,
            onChanged: (value) => currentValue = value,
            child: const SizedBox(width: 200, height: 40),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);
        final initialValue = currentValue;

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(currentValue, initialValue + keyboardStep);

        focusNode.dispose();
      });

      testWidgets('Arrow Left decreases value', (WidgetTester tester) async {
        double currentValue = 0.5;
        const keyboardStep = 0.1;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedSlider(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            keyboardStep: keyboardStep,
            onChanged: (value) => currentValue = value,
            child: const SizedBox(width: 200, height: 40),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);
        final initialValue = currentValue;

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();

        expect(currentValue, initialValue - keyboardStep);

        focusNode.dispose();
      });

      testWidgets('Arrow Up increases value', (WidgetTester tester) async {
        double currentValue = 0.5;
        const keyboardStep = 0.1;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedSlider(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            keyboardStep: keyboardStep,
            onChanged: (value) => currentValue = value,
            child: const SizedBox(width: 200, height: 40),
          ),
        );

        await tester.pump();
        final initialValue = currentValue;

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(currentValue, initialValue + keyboardStep);

        focusNode.dispose();
      });

      testWidgets('Arrow Down decreases value', (WidgetTester tester) async {
        double currentValue = 0.5;
        const keyboardStep = 0.1;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedSlider(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            keyboardStep: keyboardStep,
            onChanged: (value) => currentValue = value,
            child: const SizedBox(width: 200, height: 40),
          ),
        );

        await tester.pump();
        final initialValue = currentValue;

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(currentValue, initialValue - keyboardStep);

        focusNode.dispose();
      });
    });

    group('Home/End Keys', () {
      testWidgets('Home sets value to minimum', (WidgetTester tester) async {
        double currentValue = 0.5;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedSlider(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            min: 0.0,
            max: 1.0,
            onChanged: (value) => currentValue = value,
            child: const SizedBox(width: 200, height: 40),
          ),
        );

        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();

        expect(currentValue, 0.0);

        focusNode.dispose();
      });

      testWidgets('End sets value to maximum', (WidgetTester tester) async {
        double currentValue = 0.5;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedSlider(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            min: 0.0,
            max: 1.0,
            onChanged: (value) => currentValue = value,
            child: const SizedBox(width: 200, height: 40),
          ),
        );

        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();

        expect(currentValue, 1.0);

        focusNode.dispose();
      });
    });

    group('Page Up/Down Keys', () {
      testWidgets('Page Up increases value by larger step', (
        WidgetTester tester,
      ) async {
        double currentValue = 0.5;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedSlider(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            largeKeyboardStep: 0.2,
            onChanged: (value) => currentValue = value,
            child: const SizedBox(width: 200, height: 40),
          ),
        );

        await tester.pump();
        final initialValue = currentValue;

        await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
        await tester.pump();

        expect(currentValue, initialValue + 0.2);

        focusNode.dispose();
      });

      testWidgets('Page Down decreases value by larger step', (
        WidgetTester tester,
      ) async {
        double currentValue = 0.5;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedSlider(
            focusNode: focusNode,
            autofocus: true,
            value: currentValue,
            largeKeyboardStep: 0.2,
            onChanged: (value) => currentValue = value,
            child: const SizedBox(width: 200, height: 40),
          ),
        );

        await tester.pump();
        final initialValue = currentValue;

        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.pump();

        expect(currentValue, initialValue - 0.2);

        focusNode.dispose();
      });
    });

    group('Focus State Reporting', () {
      testWidgets('onFocusChange is called when focus is gained', (
        WidgetTester tester,
      ) async {
        bool focusState = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedSlider(
            focusNode: focusNode,
            value: 0.5,
            onChanged: (_) {},
            onFocusChange: (focused) => focusState = focused,
            child: const SizedBox(width: 200, height: 40),
          ),
        );

        focusNode.requestFocus();
        await tester.pump();

        expect(focusState, isTrue);

        focusNode.dispose();
      });
    });

    group('Autofocus', () {
      testWidgets('Slider with autofocus receives initial focus', (
        WidgetTester tester,
      ) async {
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedSlider(
            focusNode: focusNode,
            autofocus: true,
            value: 0.5,
            onChanged: (_) {},
            child: const SizedBox(width: 200, height: 40),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);

        focusNode.dispose();
      });
    });
  });
}
