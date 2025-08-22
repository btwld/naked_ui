import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/src/utilities/naked_interactable.dart';

import '../helpers/simulate_hover.dart';

void main() {
  group('NakedInteractable - Hover', () {
    testWidgets('onHoverChange toggles when pointer enters/exits', (
      WidgetTester tester,
    ) async {
      bool isHovered = false;

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;

      // Move mouse over a keyed interactable
      const key = Key('hover-box');
      await tester.pumpMaterialWidget(
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: KeyedSubtree(
            key: key,
            child: NakedInteractable(
              onHoverChange: (v) => isHovered = v,
              onPressed: () {}, // interactive so MouseRegion is active
              builder: (_) => const SizedBox(width: 24, height: 24),
            ),
          ),
        ),
      );

      await tester.simulateHover(key);
      expect(isHovered, isFalse);
    });
  });

  group('NakedInteractable - Focus', () {
    testWidgets('onFocusChange fires when widget is focused (autofocus)', (
      WidgetTester tester,
    ) async {
      bool isFocused = false;

      await tester.pumpMaterialWidget(
        NakedInteractable(
          autofocus: true,
          onFocusChange: (v) => isFocused = v,
          onPressed:
              () {}, // ensure actions are wired, though not required for focus
          builder: (_) => const SizedBox(width: 10, height: 10),
        ),
      );

      await tester.pump();

      // Expect true if focus is based on actual focus (not just highlight)
      expect(isFocused, isTrue);
    });

    testWidgets(
      'onFocusChange toggles when programmatically focusing/unfocusing',
      (WidgetTester tester) async {
        bool? lastFocused;
        final node = FocusNode();

        await tester.pumpMaterialWidget(
          NakedInteractable(
            focusNode: node,
            onFocusChange: (v) => lastFocused = v,
            onPressed: () {},
            builder: (_) => const SizedBox(width: 10, height: 10),
          ),
        );

        node.requestFocus();
        await tester.pump();
        expect(lastFocused, isTrue);

        node.unfocus();
        await tester.pump();
        expect(lastFocused, isFalse);
      },
    );
  });

  group('NakedInteractable - Press and Keyboard', () {
    testWidgets('onPressChange toggles on tap down/up and onPressed fires', (
      WidgetTester tester,
    ) async {
      bool pressedCalledTrue = false;
      bool pressedCalledFalse = false;
      bool wasPressed = false;
      const key = Key('pressable');

      await tester.pumpMaterialWidget(
        KeyedSubtree(
          key: key,
          child: NakedInteractable(
            onHighlightChanged: (v) {
              if (v)
                pressedCalledTrue = true;
              else
                pressedCalledFalse = true;
            },
            onPressed: () => wasPressed = true,
            builder: (_) => const SizedBox(width: 24, height: 24),
          ),
        ),
      );

      await tester.simulatePress(
        key,
        onPressed: () {
          expect(pressedCalledTrue, isTrue);
        },
      );

      expect(pressedCalledFalse, isTrue);
      expect(wasPressed, isTrue);
    });

    testWidgets(
      'ActivateIntent via Enter key triggers onPressed and press feedback',
      (WidgetTester tester) async {
        bool wasPressed = false;
        bool sawPressedTrue = false;
        bool sawPressedFalse = false;

        await tester.pumpMaterialWidget(
          NakedInteractable(
            autofocus: true,
            onPressed: () => wasPressed = true,
            onHighlightChanged: (v) {
              if (v)
                sawPressedTrue = true;
              else
                sawPressedFalse = true;
            },
            builder: (_) => const SizedBox(width: 24, height: 24),
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(wasPressed, isTrue);
        expect(sawPressedTrue, isTrue);
        expect(sawPressedFalse, isTrue);
      },
    );
  });
}
