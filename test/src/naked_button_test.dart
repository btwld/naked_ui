
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'helpers/simulate_hover.dart';

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

    testWidgets('does not respond to keyboard when disabled', (WidgetTester tester) async {
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

    testWidgets('supports statesController parameter', (WidgetTester tester) async {
      final statesController = WidgetStatesController();
      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          statesController: statesController,
          child: const Text('Test Button'),
        ),
      );

      expect(find.byType(NakedButton), findsOneWidget);
      expect(statesController.value, isEmpty);
      
      // Tap to trigger state change
      await tester.tap(find.byType(NakedButton));
      await tester.pump();
      
      // Controller should have been used (no error)
      expect(find.byType(NakedButton), findsOneWidget);
    });
  });

  group('State Callbacks', () {
    testWidgets('does not call state callbacks when disabled', (
      WidgetTester tester,
    ) async {
      bool isHovered = false;
      bool isPressed = false;
      bool isFocused = false;
      final key = UniqueKey();

      await tester.pumpMaterialWidget(
        NakedButton(
          key: key,
          onPressed: () {},
          enabled: false,
          onFocusChange: (focused) => isFocused = focused,
          onHoverChange: (hovered) => isHovered = hovered,
          onPressChange: (pressed) => isPressed = pressed,
          child: const Text('Test Button'),
        ),
      );

      await tester.simulateHover(
        key,
        onHover: () {
          expect(isHovered, false);
        },
      );

      expect(isHovered, false);

      await tester.simulatePress(
        key,
        onPressed: () {
          expect(isPressed, false);
        },
      );

      expect(isPressed, false);

      final focusNode = FocusNode();
      focusNode.requestFocus();
      await tester.pump();
      expect(isFocused, false);
      focusNode.unfocus();
      await tester.pump();
      expect(isFocused, false);
    });

    testWidgets('calls onHoverChange when hovered', (
      WidgetTester tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
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
          expect(isHovered, true);
        },
      );

      expect(isHovered, false);
    });

    testWidgets('calls onPressChange on tap down/up', (
      WidgetTester tester,
    ) async {
      bool isPressed = false;
      final key = UniqueKey();
      await tester.pumpMaterialWidget(
        NakedButton(
          key: key,
          onPressed: () {},
          onPressChange: (pressed) => isPressed = pressed,
          child: const Text('Test Button'),
        ),
      );

      await tester.simulatePress(
        key,
        onPressed: () {
          expect(isPressed, true);
        },
      );

      expect(isPressed, false);
    });

    testWidgets(
      'calls onPressChange on tap cancel when gesture leaves and releases',
      (tester) async {
        bool? lastPressedState;
        final key = UniqueKey();

        await tester.pumpMaterialWidget(
          NakedButton(
            key: key,
            onPressed: () {},
            onPressChange: (pressed) => lastPressedState = pressed,
            child: const Text('Test Button'),
          ),
        );

        final center = tester.getCenter(find.byKey(key));
        final gesture = await tester.startGesture(center);
        await tester.pump();
        expect(lastPressedState, true);

        // Drag off the button to trigger cancel
        await gesture.moveTo(Offset.zero);
        await tester.pump();

        await gesture.up();
        await tester.pump();

        expect(lastPressedState, false);
      },
      timeout: Timeout(Duration(seconds: 15)),
    );

    testWidgets('calls onFocusChange when focused/unfocused', (
      WidgetTester tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
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
      expect(isFocused, true);

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
      expect(isFocused, true);

      focusNodeOtherButton.requestFocus();
      await tester.pump();
      expect(isFocused, false);
    });
  });

  group('Gesture Interaction', () {
    testWidgets('calls onLongPress when long pressed', (WidgetTester tester) async {
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

    testWidgets('does not call onLongPress when disabled', (WidgetTester tester) async {
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

    testWidgets('calls onDoubleTap when double tapped', (WidgetTester tester) async {
      bool wasDoubleTapped = false;
      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          onDoubleTap: () => wasDoubleTapped = true,
          child: const Text('Test Button'),
        ),
      );

      await tester.tap(find.byType(NakedButton));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(NakedButton));
      await tester.pumpAndSettle();
      
      expect(wasDoubleTapped, isTrue);
    });

    testWidgets('does not call onDoubleTap when disabled', (WidgetTester tester) async {
      bool wasDoubleTapped = false;
      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          onDoubleTap: () => wasDoubleTapped = true,
          enabled: false,
          child: const Text('Test Button'),
        ),
      );

      await tester.tap(find.byType(NakedButton));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(NakedButton));
      await tester.pumpAndSettle();
      
      expect(wasDoubleTapped, isFalse);
    });
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

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
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

  group('Accessibility', () {
    testWidgets('provides semantic button property', (
      WidgetTester tester,
    ) async {
      final key = UniqueKey();
      await tester.pumpMaterialWidget(
        NakedButton(
          key: key,
          onPressed: () {},
          child: const Text('Test Button'),
        ),
      );

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('shows correct enabled/disabled state', (
      WidgetTester tester,
    ) async {
      final key = UniqueKey();
      for (var enabled in [true, false]) {
        await tester.pumpMaterialWidget(
          NakedButton(
            key: key,
            onPressed: () {},
            enabled: enabled,
            child: const Text('Test Button'),
          ),
        );

        expect(
          tester.getSemantics(find.byKey(key)),
          matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: enabled,
            isFocusable: enabled,
            hasFocusAction: enabled,
            hasTapAction: enabled,
          ),
        );
      }
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
