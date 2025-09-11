import 'dart:ui';

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
        NakedSwitch(
          value: false,
          onChanged: (_) {},
          child: const Text('Switch Label'),
        ),
      );

      expect(find.text('Switch Label'), findsOneWidget);
    });

    testWidgets('handles tap to toggle state', (WidgetTester tester) async {
      bool isOn = false;
      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedSwitch(
              value: isOn,
              onChanged: (value) => setState(() => isOn = value ?? false),
              child: const Text('Switch Label'),
            );
          },
        ),
      );

      await tester.tap(find.byType(NakedSwitch));
      await tester.pump();
      expect(isOn, isTrue);
    });

    testWidgets('does not respond when disabled', (WidgetTester tester) async {
      bool isOn = false;
      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedSwitch(
              value: isOn,
              onChanged: (value) => setState(() => isOn = value ?? false),
              enabled: false,
              child: const Text('Switch Label'),
            );
          },
        ),
      );

      await tester.tap(find.byType(NakedSwitch));
      await tester.pump();
      expect(isOn, isFalse);
    });

    testWidgets('does not respond when onChanged is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        const NakedSwitch(
          value: false,
          onChanged: null,
          child: Text('Switch Label'),
        ),
      );

      await tester.tap(find.byType(NakedSwitch));
      // No error should occur
    });
  });

  group('State Callbacks', () {
    testWidgets('does not call state callbacks when disabled', (
      WidgetTester tester,
    ) async {
      final key = UniqueKey();

      bool isHovered = false;
      bool isPressed = false;
      bool isFocused = false;

      await tester.pumpMaterialWidget(
        NakedSwitch(
          key: key,
          value: false,
          onChanged: (_) {},
          enabled: false,
          onFocusChange: (focused) => isFocused = focused,
          onHoverChange: (hovered) => isHovered = hovered,
          onPressChange: (pressed) => isPressed = pressed,
          child: const Text('Switch Label'),
        ),
      );

      await tester.simulateHover(
        key,
        onHover: () {
          expect(isHovered, false);
        },
      );

      expect(isHovered, false);

      final pressGesture = await tester.press(find.byType(NakedSwitch));
      await tester.pump();
      expect(isPressed, false);
      await pressGesture.up();
      await tester.pump();
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

      final textKey = GlobalKey();

      bool isHovered = false;
      await tester.pumpMaterialWidget(
        Padding(
          padding: const EdgeInsets.all(1),
          child: NakedSwitch(
            value: false,
            onChanged: (_) {},
            onHoverChange: (hovered) => isHovered = hovered,
            child: Text('Switch Label', key: textKey),
          ),
        ),
      );

      final finder = find.byKey(textKey);

      // Create a test pointer and simulate hover over the widget
      final TestPointer testPointer = TestPointer(1, PointerDeviceKind.mouse);
      final Offset hoverPosition = tester.getCenter(finder);
      await tester.sendEventToBinding(testPointer.hover(hoverPosition));
      await tester.pump();

      expect(isHovered, isTrue); // Should be hovering now

      // Move pointer out of widget
      await tester.sendEventToBinding(testPointer.hover(Offset.zero));
      await tester.pump();

      expect(isHovered, isFalse);
    });

    testWidgets('calls onPressChange on tap down/up', (
      WidgetTester tester,
    ) async {
      bool isPressed = false;
      await tester.pumpMaterialWidget(
        NakedSwitch(
          value: false,
          onChanged: (_) {},
          onPressChange: (pressed) => isPressed = pressed,
          child: const Text('Switch Label'),
        ),
      );

      final gesture = await tester.press(find.byType(NakedSwitch));
      await tester.pump();
      expect(isPressed, true);

      await gesture.up();
      await tester.pump();
      expect(isPressed, false);
    });

    testWidgets(
      'calls onPressChange on tap cancel when gesture leaves and releases',
      (tester) async {
        bool? lastPressedState;
        final key = UniqueKey();

        await tester.pumpMaterialWidget(
          NakedSwitch(
            key: key,
            value: false,
            onChanged: (_) {},
            onPressChange: (pressed) => lastPressedState = pressed,
            child: const Text('Switch Label'),
          ),
        );

        final center = tester.getCenter(find.byKey(key));
        final gesture = await tester.startGesture(center);
        await tester.pump();
        expect(lastPressedState, true);

        // Drag off the switch to trigger cancel
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
      bool isFocused = false;
      final focusNode = FocusNode();

      await tester.pumpMaterialWidget(
        NakedSwitch(
          value: false,
          onChanged: (_) {},
          focusNode: focusNode,
          onFocusChange: (focused) => isFocused = focused,
          child: const Text('Switch Label'),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(isFocused, true);

      // Focus elsewhere
      final focusNodeSwitch = FocusNode();
      final focusNodeOther = FocusNode();

      await tester.pumpMaterialWidget(
        Column(
          children: [
            NakedSwitch(
              value: false,
              onChanged: (_) {},
              focusNode: focusNodeSwitch,
              onFocusChange: (focused) => isFocused = focused,
              child: const Text('Switch Label'),
            ),
            m.TextButton(
              onPressed: () {},
              focusNode: focusNodeOther,
              child: const Text('Other Element'),
            ),
          ],
        ),
      );

      focusNodeSwitch.requestFocus();
      await tester.pump();
      expect(isFocused, true);

      focusNodeOther.requestFocus();
      await tester.pump();
      expect(isFocused, false);
    });
  });

  group('Keyboard Interaction', () {
    testWidgets('toggles with Space key', (WidgetTester tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;

      bool isOn = false;

      final focusNode = FocusNode();
      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedSwitch(
              value: isOn,
              autofocus: true,
              onChanged: (value) => setState(() => isOn = value ?? false),
              focusNode: focusNode,
              child: const Text('Switch Label'),
            );
          },
        ),
      );

      // Give time for autofocus to take effect
      await tester.pump();

      expect(isOn, false);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(isOn, true);
    });

    testWidgets('toggles with Enter key', (WidgetTester tester) async {
      bool isOn = false;
      final focusNode = FocusNode();
      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedSwitch(
              value: isOn,
              onChanged: (value) => setState(() => isOn = value ?? false),
              focusNode: focusNode,
              autofocus: true,
              child: const Text('Switch Label'),
            );
          },
        ),
      );

      // Give time for autofocus to take effect
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(isOn, true);
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
            NakedSwitch(
              key: keyEnabled,
              value: false,
              onChanged: (_) {},
              child: const Text('Enabled Switch'),
            ),
            NakedSwitch(
              key: keyDisabled,
              value: false,
              onChanged: (_) {},
              enabled: false,
              child: const Text('Disabled Switch'),
            ),
          ],
        ),
      );

      tester.expectCursor(SystemMouseCursors.click, on: keyEnabled);

      tester.expectCursor(SystemMouseCursors.basic, on: keyDisabled);
    });

    testWidgets('supports custom cursor', (WidgetTester tester) async {
      final key = UniqueKey();

      await tester.pumpMaterialWidget(
        NakedSwitch(
          key: key,
          value: false,
          onChanged: (_) {},
          mouseCursor: SystemMouseCursors.help,
          child: const Text('Custom Cursor Switch'),
        ),
      );

      tester.expectCursor(SystemMouseCursors.help, on: key);
    });
  });

  group('Semantics', () {
    testWidgets('has correct semantic properties when enabled', (
      WidgetTester tester,
    ) async {
      final key = UniqueKey();

      await tester.pumpMaterialWidget(
        NakedSwitch(
          key: key,
          value: false,
          onChanged: (_) {},
          child: const Text('Switch Label'),
        ),
      );

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('has correct semantic properties when disabled', (
      WidgetTester tester,
    ) async {
      final key = UniqueKey();

      await tester.pumpMaterialWidget(
        NakedSwitch(
          key: key,
          value: false,
          onChanged: (_) {},
          enabled: false,
          child: const Text('Switch Label'),
        ),
      );

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('has correct semantic properties when toggled', (
      WidgetTester tester,
    ) async {
      final key = UniqueKey();

      await tester.pumpMaterialWidget(
        NakedSwitch(
          key: key,
          value: true,
          onChanged: (_) {},
          child: const Text('Switch Label'),
        ),
      );

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('has correct semantic properties when focused', (
      WidgetTester tester,
    ) async {
      final key = UniqueKey();
      final focusNode = FocusNode();
      addTearDown(() => focusNode.dispose());

      await tester.pumpMaterialWidget(
        NakedSwitch(
          key: key,
          value: false,
          onChanged: (_) {},
          focusNode: focusNode,
          child: const Text('Switch Label'),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          isFocused: true,
        ),
      );
    });

    testWidgets('semantic state transitions correctly (enabled/disabled)', (
      WidgetTester tester,
    ) async {
      bool enabled = true;
      final key = UniqueKey();

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                NakedSwitch(
                  key: key,
                  value: false,
                  enabled: enabled,
                  onChanged: (_) {},
                  child: const Text('Switch Label'),
                ),
                m.TextButton(
                  onPressed: () => setState(() => enabled = !enabled),
                  child: const Text('Toggle'),
                ),
              ],
            );
          },
        ),
      );

      // Initially enabled
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );

      // Toggle to disabled
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });
  });
}