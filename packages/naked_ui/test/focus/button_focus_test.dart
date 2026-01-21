/// ARIA Focus Behavior Tests for NakedButton
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
/// - Tab: Button receives focus in natural tab order
/// - Shift+Tab: Button loses focus to previous focusable element
/// - Enter/Space: Activates the button
/// - Disabled buttons should NOT receive focus
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedButton ARIA Focus Behavior', () {
    group('Tab Navigation', () {
      testWidgets('Tab moves focus to button in natural tab order', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeButton = FocusNode(debugLabel: 'button');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedButton(
                focusNode: focusNodeButton,
                onPressed: () {},
                child: const Text('Button'),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the first element
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab to next element (button)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeButton.hasFocus, isTrue);

        // Tab to next element (after button)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeButton.dispose();
        focusNode3.dispose();
      });

      testWidgets('Shift+Tab moves focus to previous element', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeButton = FocusNode(debugLabel: 'button');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedButton(
                focusNode: focusNodeButton,
                onPressed: () {},
                child: const Text('Button'),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the last element
        focusNode3.requestFocus();
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        // Shift+Tab to previous element (button)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(focusNodeButton.hasFocus, isTrue);

        // Shift+Tab to previous element (before button)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeButton.dispose();
        focusNode3.dispose();
      });

      testWidgets('Button is a single tab stop', (WidgetTester tester) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeButton = FocusNode(debugLabel: 'button');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedButton(
                focusNode: focusNodeButton,
                onPressed: () {},
                // Complex child with multiple elements
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star),
                    Text('Star Button'),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the first element
        focusNode1.requestFocus();
        await tester.pump();

        // Tab once should focus the entire button (not individual child elements)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeButton.hasFocus, isTrue);

        // Tab again should skip to next element, not stay in button children
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNodeButton.dispose();
        focusNode3.dispose();
      });
    });

    group('Disabled Button Focus Behavior', () {
      testWidgets('Disabled button should NOT receive focus via Tab', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'before');
        final focusNodeDisabledButton = FocusNode(debugLabel: 'disabled');
        final focusNode3 = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNode1),
              NakedButton(
                focusNode: focusNodeDisabledButton,
                onPressed: () {},
                enabled: false,
                child: const Text('Disabled Button'),
              ),
              TextField(focusNode: focusNode3),
            ],
          ),
        );

        // Focus the first element
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab should skip disabled button and go directly to next element
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          focusNodeDisabledButton.hasFocus,
          isFalse,
          reason: 'Disabled button should not receive focus',
        );
        expect(
          focusNode3.hasFocus,
          isTrue,
          reason: 'Focus should skip to next enabled element',
        );

        focusNode1.dispose();
        focusNodeDisabledButton.dispose();
        focusNode3.dispose();
      });

      testWidgets(
        'Button with null onPressed should NOT receive focus via Tab',
        (WidgetTester tester) async {
          final focusNode1 = FocusNode(debugLabel: 'before');
          final focusNodeNullButton = FocusNode(debugLabel: 'null onPressed');
          final focusNode3 = FocusNode(debugLabel: 'after');

          await tester.pumpMaterialWidget(
            Column(
              children: [
                TextField(focusNode: focusNode1),
                NakedButton(
                  focusNode: focusNodeNullButton,
                  onPressed: null, // Non-interactive
                  child: const Text('Non-interactive Button'),
                ),
                TextField(focusNode: focusNode3),
              ],
            ),
          );

          // Focus the first element
          focusNode1.requestFocus();
          await tester.pump();

          // Tab should skip button with null onPressed
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(
            focusNodeNullButton.hasFocus,
            isFalse,
            reason: 'Button with null onPressed should not receive focus',
          );
          expect(focusNode3.hasFocus, isTrue);

          focusNode1.dispose();
          focusNodeNullButton.dispose();
          focusNode3.dispose();
        },
      );

      testWidgets(
        'Disabled button does not respond to programmatic focus request',
        (WidgetTester tester) async {
          final focusNodeDisabledButton = FocusNode(debugLabel: 'disabled');

          await tester.pumpMaterialWidget(
            NakedButton(
              focusNode: focusNodeDisabledButton,
              onPressed: () {},
              enabled: false,
              child: const Text('Disabled Button'),
            ),
          );

          // Attempt to focus programmatically
          focusNodeDisabledButton.requestFocus();
          await tester.pump();

          // Should not be able to focus a disabled button
          expect(
            focusNodeDisabledButton.hasFocus,
            isFalse,
            reason: 'Disabled button should not receive programmatic focus',
          );

          focusNodeDisabledButton.dispose();
        },
      );
    });

    group('Keyboard Activation', () {
      testWidgets('Enter key activates the button', (
        WidgetTester tester,
      ) async {
        bool wasPressed = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: () => wasPressed = true,
            child: const Text('Enter Test'),
          ),
        );

        await tester.pump(); // Allow autofocus to take effect

        expect(focusNode.hasFocus, isTrue);
        expect(wasPressed, isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(wasPressed, isTrue);

        focusNode.dispose();
      });

      testWidgets('Space key activates the button', (
        WidgetTester tester,
      ) async {
        bool wasPressed = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: () => wasPressed = true,
            child: const Text('Space Test'),
          ),
        );

        await tester.pump(); // Allow autofocus to take effect

        expect(focusNode.hasFocus, isTrue);
        expect(wasPressed, isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        expect(wasPressed, isTrue);

        focusNode.dispose();
      });

      testWidgets('Enter key does not activate disabled button', (
        WidgetTester tester,
      ) async {
        bool wasPressed = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: () => wasPressed = true,
            enabled: false,
            child: const Text('Disabled'),
          ),
        );

        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(wasPressed, isFalse);

        focusNode.dispose();
      });

      testWidgets('Space key does not activate disabled button', (
        WidgetTester tester,
      ) async {
        bool wasPressed = false;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: () => wasPressed = true,
            enabled: false,
            child: const Text('Disabled'),
          ),
        );

        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        expect(wasPressed, isFalse);

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
          NakedButton(
            focusNode: focusNode,
            onPressed: () {},
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
              NakedButton(
                focusNode: focusNode1,
                onPressed: () {},
                onFocusChange: (focused) => focusState = focused,
                child: const Text('Button 1'),
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

      testWidgets('NakedButtonState correctly reflects focused state', (
        WidgetTester tester,
      ) async {
        NakedButtonState? capturedState;
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedButton(
            focusNode: focusNode,
            onPressed: () {},
            builder: (context, state, child) {
              capturedState = state;
              return child ?? const SizedBox();
            },
            child: const Text('State Test'),
          ),
        );

        // Initially not focused
        expect(capturedState?.isFocused, isFalse);

        // Focus the button
        focusNode.requestFocus();
        await tester.pump();
        expect(capturedState?.isFocused, isTrue);

        focusNode.dispose();
      });
    });

    group('Multiple Buttons Navigation', () {
      testWidgets('Tab navigates through multiple buttons in order', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'button1');
        final focusNode2 = FocusNode(debugLabel: 'button2');
        final focusNode3 = FocusNode(debugLabel: 'button3');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              NakedButton(
                focusNode: focusNode1,
                onPressed: () {},
                child: const Text('Button 1'),
              ),
              NakedButton(
                focusNode: focusNode2,
                onPressed: () {},
                child: const Text('Button 2'),
              ),
              NakedButton(
                focusNode: focusNode3,
                onPressed: () {},
                child: const Text('Button 3'),
              ),
            ],
          ),
        );

        // Focus first button
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab to second
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode2.hasFocus, isTrue);

        // Tab to third
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNode2.dispose();
        focusNode3.dispose();
      });

      testWidgets('Tab skips disabled buttons in the middle', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'button1');
        final focusNodeDisabled = FocusNode(debugLabel: 'disabled');
        final focusNode3 = FocusNode(debugLabel: 'button3');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              NakedButton(
                focusNode: focusNode1,
                onPressed: () {},
                child: const Text('Button 1'),
              ),
              NakedButton(
                focusNode: focusNodeDisabled,
                onPressed: () {},
                enabled: false,
                child: const Text('Disabled Button'),
              ),
              NakedButton(
                focusNode: focusNode3,
                onPressed: () {},
                child: const Text('Button 3'),
              ),
            ],
          ),
        );

        // Focus first button
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

    group('Autofocus', () {
      testWidgets('Button with autofocus receives initial focus', (
        WidgetTester tester,
      ) async {
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: () {},
            child: const Text('Autofocus Button'),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);

        focusNode.dispose();
      });

      testWidgets('Only first autofocus button receives focus', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode();
        final focusNode2 = FocusNode();

        await tester.pumpMaterialWidget(
          Column(
            children: [
              NakedButton(
                focusNode: focusNode1,
                autofocus: true,
                onPressed: () {},
                child: const Text('First Autofocus'),
              ),
              NakedButton(
                focusNode: focusNode2,
                autofocus: true,
                onPressed: () {},
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
