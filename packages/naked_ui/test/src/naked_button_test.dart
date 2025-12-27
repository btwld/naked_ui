import 'package:flutter/material.dart' as m;
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/naked_ui.dart';

import '../test_helpers.dart';
import 'helpers/builder_state_scope.dart';

void main() {
  group('Basic Functionality', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(
        NakedButton(child: const Text('Test Button'), onPressed: () {}),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('handles tap when enabled', (WidgetTester tester) async {
      bool wasPressed = false;
      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () => wasPressed = true,
          child: const Text('Test Button'),
        ),
      );

      await tester.tap(find.byType(NakedButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('does not respond when disabled', (WidgetTester tester) async {
      bool wasPressed = false;
      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () => wasPressed = true,
          enabled: false,
          child: const Text('Test Button'),
        ),
      );

      await tester.tap(find.byType(NakedButton));
      expect(wasPressed, isFalse);
    });

    testWidgets('does not respond to keyboard when disabled', (
      WidgetTester tester,
    ) async {
      bool wasPressed = false;
      await tester.pumpMaterialWidget(
        NakedButton(
          autofocus: true,
          onPressed: () => wasPressed = true,
          enabled: false,
          child: const Text('Test Button'),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(wasPressed, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(wasPressed, isFalse);
    });

    testWidgets('does not respond when onPressed is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        const NakedButton(onPressed: null, child: Text('Test Button')),
      );

      await tester.tap(find.byType(NakedButton));
      // No error should occur
    });

    testStateScopeBuilder<NakedButtonState>(
      'builder\'s context contains NakedStateScope',
      (builder) => NakedButton(onPressed: () {}, builder: builder),
    );
  });

  group('State Callbacks', () {
    testWidgets('does not trigger callbacks when disabled', (
      WidgetTester tester,
    ) async {
      bool hoverCalled = false;
      bool pressCalled = false;
      final key = UniqueKey();

      await tester.pumpMaterialWidget(
        NakedButton(
          key: key,
          onPressed: () {},
          enabled: false,
          onHoverChange: (hovered) => hoverCalled = true,
          onPressChange: (pressed) => pressCalled = true,
          child: const Text('Test Button'),
        ),
      );

      await tester.simulateHover(key);
      expect(hoverCalled, isFalse);

      await tester.simulatePress(key);
      expect(pressCalled, isFalse);
    });

    testWidgets('reports hover state changes', (WidgetTester tester) async {
      bool isHovered = false;

      final key = UniqueKey();

      await tester.pumpMaterialWidget(
        Padding(
          padding: const EdgeInsets.all(1),
          child: NakedButton(
            key: key,
            onPressed: () {},
            onHoverChange: (hovered) => isHovered = hovered,
            child: const Text('Test Button'),
          ),
        ),
      );

      await tester.simulateHover(
        key,
        onHover: () {
          expect(isHovered, isTrue);
        },
      );

      expect(isHovered, isFalse);
    });

    testWidgets('reports press state changes on tap down/up', (
      WidgetTester tester,
    ) async {
      final pressStates = <bool>[];
      final key = UniqueKey();
      await tester.pumpMaterialWidget(
        NakedButton(
          key: key,
          onPressed: () {},
          onPressChange: (pressed) => pressStates.add(pressed),
          child: const Text('Test Button'),
        ),
      );

      await tester.simulatePress(key);

      // Expect pressed true on down, then false on up
      expect(pressStates, equals([true, false]));
    });

    // Skipping dedicated cancel behavior test as pressed state sequencing
    // is already covered in other tests and cancel semantics are verified
    // through framework gesture handling elsewhere.

    testWidgets('reports focus state changes when focused/unfocused', (
      WidgetTester tester,
    ) async {
      bool isFocused = false;
      final focusNode = FocusNode();

      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          focusNode: focusNode,
          onFocusChange: (focused) => isFocused = focused,
          child: const Text('Test Button'),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(isFocused, isTrue);

      // Focus elsewhere
      final focusNodeNakedButton = FocusNode();
      final focusNodeOtherButton = FocusNode();

      await tester.pumpMaterialWidget(
        Column(
          children: [
            NakedButton(
              onPressed: () {},
              focusNode: focusNodeNakedButton,
              onFocusChange: (focused) => isFocused = focused,
              child: const Text('Test Button'),
            ),
            m.TextButton(
              onPressed: () {},
              focusNode: focusNodeOtherButton,
              child: const Text('Other Button'),
            ),
          ],
        ),
      );

      focusNodeNakedButton.requestFocus();
      await tester.pump();
      expect(isFocused, isTrue);

      focusNodeOtherButton.requestFocus();
      await tester.pump();
      expect(isFocused, isFalse);
    });
  });

  group('Gesture Interaction', () {
    testWidgets('calls onLongPress when long pressed', (
      WidgetTester tester,
    ) async {
      bool wasLongPressed = false;
      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          onLongPress: () => wasLongPressed = true,
          child: const Text('Test Button'),
        ),
      );

      await tester.longPress(find.byType(NakedButton));
      expect(wasLongPressed, isTrue);
    });

    testWidgets('does not call onLongPress when disabled', (
      WidgetTester tester,
    ) async {
      bool wasLongPressed = false;
      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          onLongPress: () => wasLongPressed = true,
          enabled: false,
          child: const Text('Test Button'),
        ),
      );

      await tester.longPress(find.byType(NakedButton));
      expect(wasLongPressed, isFalse);
    });

    testWidgets('calls onLongPress when only long-press provided', (
      WidgetTester tester,
    ) async {
      bool wasLongPressed = false;
      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: null,
          onLongPress: () => wasLongPressed = true,
          child: const Text('Test Button'),
        ),
      );

      await tester.longPress(find.byType(NakedButton));
      expect(wasLongPressed, isTrue);
    });

    testWidgets(
      'press state toggles on long-press when only long-press provided',
      (WidgetTester tester) async {
        final key = UniqueKey();
        final pressStates = <bool>[];
        bool wasLongPressed = false;

        await tester.pumpMaterialWidget(
          NakedButton(
            key: key,
            onPressed: null,
            onLongPress: () => wasLongPressed = true,
            onPressChange: (v) => pressStates.add(v),
            child: const Text('Hold Me'),
          ),
        );

        // Manually perform a long-press gesture: down, hold past threshold, up.
        final center = tester.getCenter(find.byKey(key));
        final gesture = await tester.startGesture(center);
        // Allow the framework to process down and then exceed the long-press timeout
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
        // Release
        await gesture.up();
        await tester.pump();

        expect(wasLongPressed, isTrue, reason: 'onLongPress should fire');
        expect(
          pressStates.isNotEmpty,
          isTrue,
          reason: 'onPressChange should update during long-press',
        );
        // We expect it to have gone pressed (true) during hold and false on end.
        expect(pressStates.first, isTrue);
        expect(pressStates.last, isFalse);
      },
    );
  });

  group('Keyboard Interaction', () {
    testWidgets('activates with Space key', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpMaterialWidget(
        NakedButton(
          autofocus: true,
          onPressed: () => wasPressed = true,
          child: const Text('Test Button'),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('activates with Enter key', (WidgetTester tester) async {
      bool wasPressed = false;
      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () => wasPressed = true,
          child: const Text('Test Button'),
        ),
      );

      await tester.tap(find.byType(NakedButton));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(wasPressed, true);
    });
  });

  group('Focus Behavior', () {
    testWidgets('focusOnPress requests focus when button is pressed', (
      WidgetTester tester,
    ) async {
      final focusNode = FocusNode();
      final key = UniqueKey();

      await tester.pumpMaterialWidget(
        NakedButton(
          key: key,
          onPressed: () {},
          focusOnPress: true,
          focusNode: focusNode,
          child: const Text('Focus On Press'),
        ),
      );

      expect(focusNode.hasFocus, isFalse);

      // Tap the button
      await tester.tap(find.byKey(key));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('focusOnPress false does not request focus on press', (
      WidgetTester tester,
    ) async {
      final focusNode = FocusNode();
      final key = UniqueKey();

      await tester.pumpMaterialWidget(
        NakedButton(
          key: key,
          onPressed: () {},
          focusOnPress: false, // default
          focusNode: focusNode,
          child: const Text('No Focus On Press'),
        ),
      );

      expect(focusNode.hasFocus, isFalse);

      // Tap the button
      await tester.tap(find.byKey(key));
      await tester.pump();

      // Focus should not have been requested
      expect(focusNode.hasFocus, isFalse);
    });
  });

  group('Cursor', () {
    testWidgets('shows appropriate cursor based on interactive state', (
      WidgetTester tester,
    ) async {
      final keyEnabled = UniqueKey();
      final keyDisabled = UniqueKey();

      await tester.pumpMaterialWidget(
        Column(
          children: [
            NakedButton(
              key: keyEnabled,
              onPressed: () {},
              child: const Text('Enabled Button'),
            ),
            NakedButton(
              key: keyDisabled,
              onPressed: () {},
              enabled: false,
              child: const Text('Disabled Button'),
            ),
          ],
        ),
      );

      tester.expectCursor(SystemMouseCursors.click, on: keyEnabled);

      tester.expectCursor(SystemMouseCursors.basic, on: keyDisabled);
    });
  });
}
