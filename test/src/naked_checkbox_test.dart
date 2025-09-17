import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('Basic Functionality', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(
        NakedCheckbox(
          value: false,
          onChanged: (_) {},
          child: const Text('Checkbox Label'),
        ),
      );

      expect(find.text('Checkbox Label'), findsOneWidget);
    });

    testWidgets('handles tap to toggle state', (WidgetTester tester) async {
      bool isChecked = false;
      await tester.pumpMaterialWidget(
        NakedCheckbox(
          value: isChecked,
          onChanged: (value) => isChecked = value!,
          child: const Text('Checkbox Label'),
        ),
      );

      await tester.tap(find.byType(NakedCheckbox));
      expect(isChecked, isTrue);
    });

    testWidgets('does not respond when disabled', (WidgetTester tester) async {
      bool isChecked = false;
      await tester.pumpMaterialWidget(
        NakedCheckbox(
          value: isChecked,
          onChanged: (value) => isChecked = value!,
          enabled: false,
          child: const Text('Checkbox Label'),
        ),
      );

      await tester.tap(find.byType(NakedCheckbox));
      expect(isChecked, isFalse);
    });

    testWidgets('does not respond when onChanged is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        const NakedCheckbox(
          value: false,
          onChanged: null,
          child: Text('Checkbox Label'),
        ),
      );

      await tester.tap(find.byType(NakedCheckbox));
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
        NakedCheckbox(
          key: key,
          value: false,
          onChanged: (_) {},
          enabled: false,
          onFocusChange: (focused) => isFocused = focused,
          onHoverChange: (hovered) => isHovered = hovered,
          onPressChange: (pressed) => isPressed = pressed,
          child: const Text('Checkbox Label'),
        ),
      );

      await tester.simulateHover(
        key,
        onHover: () {
          expect(isHovered, false);
        },
      );

      expect(isHovered, false);

      final pressGesture = await tester.press(find.byType(NakedCheckbox));
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
      final textKey = GlobalKey();

      bool isHovered = false;
      await tester.pumpMaterialWidget(
        Padding(
          padding: const EdgeInsets.all(1),
          child: NakedCheckbox(
            value: false,
            onChanged: (_) {},
            onHoverChange: (hovered) => isHovered = hovered,
            child: Text('Checkbox Label', key: textKey),
          ),
        ),
      );

      // Use helper to simulate hover enter/exit robustly
      await tester.simulateHover(
        textKey,
        onHover: () {
          expect(isHovered, isTrue);
        },
      );
      expect(isHovered, isFalse);
    });

    testWidgets('calls onPressChange on tap down/up', (
      WidgetTester tester,
    ) async {
      bool isPressed = false;
      await tester.pumpMaterialWidget(
        NakedCheckbox(
          value: false,
          onChanged: (_) {},
          onPressChange: (pressed) => isPressed = pressed,
          child: const Text('Checkbox Label'),
        ),
      );

      final gesture = await tester.press(find.byType(NakedCheckbox));
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
          NakedCheckbox(
            key: key,
            value: false,
            onChanged: (_) {},
            onPressChange: (pressed) => lastPressedState = pressed,
            child: const Text('Checkbox Label'),
          ),
        );

        final center = tester.getCenter(find.byKey(key));
        final gesture = await tester.startGesture(center);
        await tester.pump();
        expect(lastPressedState, true);

        // Drag off the checkbox to trigger cancel
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
        NakedCheckbox(
          value: false,
          onChanged: (_) {},
          focusNode: focusNode,
          onFocusChange: (focused) => isFocused = focused,
          child: const Text('Checkbox Label'),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(isFocused, true);

      // Focus elsewhere
      final focusNodeCheckbox = FocusNode();
      final focusNodeOther = FocusNode();

      await tester.pumpMaterialWidget(
        Column(
          children: [
            NakedCheckbox(
              value: false,
              onChanged: (_) {},
              focusNode: focusNodeCheckbox,
              onFocusChange: (focused) => isFocused = focused,
              child: const Text('Checkbox Label'),
            ),
            m.TextButton(
              onPressed: () {},
              focusNode: focusNodeOther,
              child: const Text('Other Element'),
            ),
          ],
        ),
      );

      focusNodeCheckbox.requestFocus();
      await tester.pump();
      expect(isFocused, true);

      focusNodeOther.requestFocus();
      await tester.pump();
      expect(isFocused, false);
    });
  });

  group('Keyboard Interaction', () {
    testWidgets('toggles with Space key', (WidgetTester tester) async {
      bool isChecked = false;

      final focusNode = FocusNode();
      await tester.pumpMaterialWidget(
        NakedCheckbox(
          value: isChecked,
          autofocus: true,
          onChanged: (value) => isChecked = value!,
          focusNode: focusNode,
          child: const Text('Checkbox Label'),
        ),
      );

      // Give time for autofocus to take effect
      await tester.pump();

      expect(isChecked, false);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(isChecked, true);
    });

    testWidgets('toggles with Enter key', (WidgetTester tester) async {
      bool isChecked = false;
      final focusNode = FocusNode();
      await tester.pumpMaterialWidget(
        NakedCheckbox(
          value: isChecked,
          onChanged: (value) => isChecked = value!,
          focusNode: focusNode,
          autofocus: true,
          child: const Text('Checkbox Label'),
        ),
      );

      // Give time for autofocus to take effect
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(isChecked, true);
    });
  });

  group('Tristate', () {
    testWidgets(
      'cycles false → true → null → false when tristate is enabled (Material parity)',
      (WidgetTester tester) async {
        bool? value = false;

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedCheckbox(
                value: value,
                tristate: true,
                onChanged: (newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
                child: const Text('Checkbox Label'),
              );
            },
          ),
        );

        await tester.tap(find.byType(NakedCheckbox));
        expect(value, true);

        await tester.pump();
        await tester.tap(find.byType(NakedCheckbox));
        expect(value, isNull);

        await tester.pump();
        await tester.tap(find.byType(NakedCheckbox));
        expect(value, false);
      },
    );

    testWidgets(
      'throws assertion error when value is null but tristate is false, since null values are only allowed in tristate mode',
      (WidgetTester tester) async {
        expect(
          () => NakedCheckbox(
            value: null,
            tristate: false,
            onChanged: (_) {},
            child: const Text('Checkbox Label'),
          ),
          throwsAssertionError,
        );
      },
    );
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
            NakedCheckbox(
              key: keyEnabled,
              value: false,
              onChanged: (_) {},
              child: const Text('Enabled Checkbox'),
            ),
            NakedCheckbox(
              key: keyDisabled,
              value: false,
              onChanged: (_) {},
              enabled: false,
              child: const Text('Disabled Checkbox'),
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
        NakedCheckbox(
          key: key,
          value: false,
          onChanged: (_) {},
          mouseCursor: SystemMouseCursors.help,
          child: const Text('Custom Cursor Checkbox'),
        ),
      );

      tester.expectCursor(SystemMouseCursors.help, on: key);
    });
  });
}
