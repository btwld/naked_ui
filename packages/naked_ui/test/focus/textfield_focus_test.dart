/// ARIA Focus Behavior Tests for NakedTextField
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
///
/// Focus Behavior:
/// - Tab: Moves focus into/out of text field
/// - Text field is a single tab stop
/// - When focused, cursor appears and text input is active
///
/// Keyboard Interaction:
/// - Standard text editing keys work (typing, backspace, delete, etc.)
/// - Arrow keys move cursor within text
/// - Home/End move cursor to start/end of text
/// - Ctrl+A selects all text
/// - Escape: May clear selection or blur (implementation-specific)
///
/// Disabled State:
/// - Disabled text field should NOT receive focus via Tab
/// - Read-only text field CAN receive focus but cannot edit
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedTextField ARIA Focus Behavior', () {
    group('Tab Navigation', () {
      testWidgets('Tab moves focus to text field', (WidgetTester tester) async {
        final focusNodeBefore = FocusNode(debugLabel: 'before');
        final textFieldFocusNode = FocusNode(debugLabel: 'textfield');
        final focusNodeAfter = FocusNode(debugLabel: 'after');
        final controller = TextEditingController();

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNodeBefore),
              NakedTextField(
                controller: controller,
                focusNode: textFieldFocusNode,
                builder: (context, state, editableText) => Container(
                  decoration: BoxDecoration(border: Border.all()),
                  child: editableText,
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

        // Tab should move to text field
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(textFieldFocusNode.hasFocus, isTrue);

        // Tab again should move to element after text field
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeAfter.hasFocus, isTrue);

        focusNodeBefore.dispose();
        textFieldFocusNode.dispose();
        focusNodeAfter.dispose();
        controller.dispose();
      });

      testWidgets('Shift+Tab moves focus to previous element', (
        WidgetTester tester,
      ) async {
        final focusNodeBefore = FocusNode(debugLabel: 'before');
        final textFieldFocusNode = FocusNode(debugLabel: 'textfield');
        final controller = TextEditingController();

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNodeBefore),
              NakedTextField(
                controller: controller,
                autofocus: true,
                focusNode: textFieldFocusNode,
                builder: (context, state, editableText) => Container(
                  decoration: BoxDecoration(border: Border.all()),
                  child: editableText,
                ),
              ),
            ],
          ),
        );

        // Shift+Tab should move to previous element
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(focusNodeBefore.hasFocus, isTrue);

        focusNodeBefore.dispose();
        textFieldFocusNode.dispose();
        controller.dispose();
      });
    });

    group('Text Input', () {
      testWidgets('Text can be entered when focused', (
        WidgetTester tester,
      ) async {
        final controller = TextEditingController();

        await tester.pumpMaterialWidget(
          NakedTextField(
            controller: controller,
            autofocus: true,
            builder: (context, state, editableText) => Container(
              decoration: BoxDecoration(border: Border.all()),
              child: editableText,
            ),
          ),
        );

        // Enter text
        await tester.enterText(find.byType(EditableText), 'Hello World');
        await tester.pump();

        expect(controller.text, 'Hello World');

        controller.dispose();
      });
    });

    group('Disabled State', () {
      testWidgets('Disabled text field should NOT receive focus via Tab', (
        WidgetTester tester,
      ) async {
        final focusNodeBefore = FocusNode(debugLabel: 'before');
        final textFieldFocusNode = FocusNode(debugLabel: 'textfield');
        final focusNodeAfter = FocusNode(debugLabel: 'after');
        final controller = TextEditingController();

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNodeBefore),
              NakedTextField(
                controller: controller,
                focusNode: textFieldFocusNode,
                enabled: false,
                builder: (context, state, editableText) => Container(
                  decoration: BoxDecoration(border: Border.all()),
                  child: editableText,
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

        // Tab should skip disabled text field
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(textFieldFocusNode.hasFocus, isFalse);
        expect(focusNodeAfter.hasFocus, isTrue);

        focusNodeBefore.dispose();
        textFieldFocusNode.dispose();
        focusNodeAfter.dispose();
        controller.dispose();
      });
    });

    group('Read-Only State', () {
      testWidgets('Read-only text field CAN receive focus', (
        WidgetTester tester,
      ) async {
        final focusNode = FocusNode();
        final controller = TextEditingController(text: 'Read only text');

        await tester.pumpMaterialWidget(
          NakedTextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: true,
            builder: (context, state, editableText) => Container(
              decoration: BoxDecoration(border: Border.all()),
              child: editableText,
            ),
          ),
        );

        // Focus the text field
        focusNode.requestFocus();
        await tester.pump();

        expect(focusNode.hasFocus, isTrue);

        focusNode.dispose();
        controller.dispose();
      });
    });

    group('Focus State Reporting', () {
      testWidgets('NakedTextFieldState correctly reflects focused state', (
        WidgetTester tester,
      ) async {
        NakedTextFieldState? capturedState;
        final focusNode = FocusNode();
        final controller = TextEditingController();

        await tester.pumpMaterialWidget(
          NakedTextField(
            controller: controller,
            focusNode: focusNode,
            builder: (context, state, editableText) {
              capturedState = state;
              return Container(
                decoration: BoxDecoration(border: Border.all()),
                child: editableText,
              );
            },
          ),
        );

        // Initially not focused
        expect(capturedState?.isFocused, isFalse);

        // Focus the text field
        focusNode.requestFocus();
        await tester.pump();

        expect(capturedState?.isFocused, isTrue);

        focusNode.dispose();
        controller.dispose();
      });
    });

    group('Autofocus', () {
      testWidgets('Text field with autofocus receives initial focus', (
        WidgetTester tester,
      ) async {
        final focusNode = FocusNode();
        final controller = TextEditingController();

        await tester.pumpMaterialWidget(
          NakedTextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            builder: (context, state, editableText) => Container(
              decoration: BoxDecoration(border: Border.all()),
              child: editableText,
            ),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);

        focusNode.dispose();
        controller.dispose();
      });
    });

    group('onFocusChange Callback', () {
      testWidgets('onFocusChange is called when focus changes', (
        WidgetTester tester,
      ) async {
        bool? focusState;
        final focusNode = FocusNode();
        final otherFocusNode = FocusNode();
        final controller = TextEditingController();

        await tester.pumpMaterialWidget(
          Column(
            children: [
              NakedTextField(
                controller: controller,
                focusNode: focusNode,
                onFocusChange: (focused) => focusState = focused,
                builder: (context, state, editableText) => Container(
                  decoration: BoxDecoration(border: Border.all()),
                  child: editableText,
                ),
              ),
              TextField(focusNode: otherFocusNode),
            ],
          ),
        );

        // Focus the text field
        focusNode.requestFocus();
        await tester.pump();
        expect(focusState, isTrue);

        // Move focus away
        otherFocusNode.requestFocus();
        await tester.pump();
        expect(focusState, isFalse);

        focusNode.dispose();
        otherFocusNode.dispose();
        controller.dispose();
      });
    });
  });
}
