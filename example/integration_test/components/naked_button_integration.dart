import 'package:example/api/naked_button.0.dart' as button_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedButton Integration Tests', () {
    testWidgets('button responds to all interaction types', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const button_example.MyApp());
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(NakedButton);
      expect(buttonFinder, findsOneWidget);

      // Test tap interaction
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Test keyboard activation
      await tester.testKeyboardActivation(buttonFinder);
      await tester.pumpAndSettle();

      // Test hover simulation (on platforms that support it)
      final buttonKey = UniqueKey();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              key: buttonKey,
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.simulateHover(buttonKey);
      await tester.pumpAndSettle();
    });

    testWidgets('button handles focus management correctly', (tester) async {
      final buttonKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool focusChanged = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              key: buttonKey,
              focusNode: focusNode,
              onPressed: () {},
              onFocusChange: (focused) => focusChanged = focused,
              child: const Text('Test Button'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test focus acquisition
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(focusChanged, isTrue);

      // Test focus loss
      focusChanged = false;
      focusNode.unfocus();
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
      expect(focusChanged, isFalse);
    });

    testWidgets('button state callbacks work in real app context',
        (tester) async {
      final buttonKey = UniqueKey();
      bool isHovered = false;
      bool isPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              key: buttonKey,
              onPressed: () {},
              onHoverChange: (hovered) => isHovered = hovered,
              onPressChange: (pressed) => isPressed = pressed,
              onFocusChange: (focused) {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test hover state
      await tester.simulateHover(buttonKey, onHover: () {
        expect(isHovered, isTrue);
      });

      // Test press state
      await tester.simulatePress(buttonKey, onPressed: () {
        expect(isPressed, isTrue);
      });
    });

    testWidgets('button keyboard navigation works correctly', (tester) async {
      // Create multiple buttons to test tab navigation
      final button1Key = UniqueKey();
      final button2Key = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NakedButton(
                key: button1Key,
                onPressed: () {},
                child: const Text('Button 1'),
              ),
              const SizedBox(height: 20),
              NakedButton(
                key: button2Key,
                onPressed: () {},
                child: const Text('Button 2'),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test tab navigation order
      await tester.verifyTabOrder([
        find.byKey(button1Key),
        find.byKey(button2Key),
      ]);
    });

    testWidgets('disabled button blocks all interactions', (tester) async {
      final buttonKey = UniqueKey();
      bool wasPressed = false;
      bool hoverChanged = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              key: buttonKey,
              onPressed: () => wasPressed = true,
              enabled: false,
              onHoverChange: (hovered) => hoverChanged = true,
              onFocusChange: (focused) {},
              child: const Text('Disabled Button'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test that disabled button doesn't respond to tap
      await tester.tap(find.byKey(buttonKey));
      await tester.pump();
      expect(wasPressed, isFalse);

      // Test that disabled button doesn't respond to keyboard
      await tester.testKeyboardActivation(find.byKey(buttonKey));
      expect(wasPressed, isFalse);

      // Test that hover callbacks aren't triggered when disabled
      await tester.simulateHover(buttonKey);
      expect(hoverChanged, isFalse);
    });

    testWidgets('focusOnPress requests focus when enabled', (tester) async {
      final buttonKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool wasPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              key: buttonKey,
              focusNode: focusNode,
              focusOnPress: true,
              onPressed: () => wasPressed = true,
              child: const Text('Focus Test Button'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Initially not focused
      expect(focusNode.hasFocus, isFalse);

      // Tap button - should request focus
      await tester.tap(find.byKey(buttonKey));
      await tester.pump();

      // Now should be focused and pressed
      expect(focusNode.hasFocus, isTrue);
      expect(wasPressed, isTrue);
    });

    testWidgets('focusOnPress disabled does not request focus', (tester) async {
      final buttonKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool wasPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              key: buttonKey,
              focusNode: focusNode,
              onPressed: () => wasPressed = true,
              child: const Text('No Focus Test Button'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Initially not focused
      expect(focusNode.hasFocus, isFalse);

      // Tap button - should NOT request focus
      await tester.tap(find.byKey(buttonKey));
      await tester.pump();

      // Should still not be focused but should be pressed
      expect(focusNode.hasFocus, isFalse);
      expect(wasPressed, isTrue);
    });

    testWidgets('button builder method works with states', (tester) async {
      final buttonKey = UniqueKey();
      bool isHovered = false;
      bool isPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              key: buttonKey,
              onPressed: () {},
              builder: (context, states, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: states.contains(WidgetState.hovered)
                        ? Colors.blue.shade100
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: states.contains(WidgetState.pressed)
                          ? Colors.blue
                          : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: child,
                );
              },
              onHoverChange: (hovered) => isHovered = hovered,
              onPressChange: (pressed) => isPressed = pressed,
              child: const Text('Builder Button'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final buttonFinder = find.byKey(buttonKey);
      expect(buttonFinder, findsOneWidget);
      expect(find.text('Builder Button'), findsOneWidget);

      // Test that builder updates with state changes
      await tester.simulateHover(buttonKey, onHover: () {
        expect(isHovered, isTrue);
      });

      await tester.simulatePress(buttonKey, onPressed: () {
        expect(isPressed, isTrue);
      });
    });

    testWidgets('button onLongPress works correctly', (tester) async {
      final buttonKey = UniqueKey();
      bool wasLongPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              key: buttonKey,
              onPressed: () {},
              onLongPress: () => wasLongPressed = true,
              child: const Text('Long Press Button'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Long press the button
      await tester.longPress(find.byKey(buttonKey));
      await tester.pumpAndSettle();

      // Verify long press callback was called
      expect(wasLongPressed, isTrue);
    });

    testWidgets('button onLongPress works when only long-press is provided',
        (tester) async {
      final buttonKey = UniqueKey();
      bool wasLongPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              key: buttonKey,
              onPressed: null,
              onLongPress: () => wasLongPressed = true,
              child: const Text('Long Press Only Button'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Long press the button
      await tester.longPress(find.byKey(buttonKey));
      await tester.pumpAndSettle();

      // Verify long press callback was called
      expect(wasLongPressed, isTrue);
    });


    testWidgets('button basic example works correctly', (tester) async {
      // Use the actual basic example app
      await tester.pumpWidget(const button_example.MyApp());
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(NakedButton);
      expect(buttonFinder, findsOneWidget);

      // Test tap interaction
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verify button still exists after tap
      expect(buttonFinder, findsOneWidget);
    });

    testWidgets('button works with different child widgets', (tester) async {
      // Test with Icon child
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              onPressed: () {},
              child: const Icon(Icons.star),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final iconButton = find.byType(NakedButton);
      expect(iconButton, findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.tap(iconButton);
      await tester.pumpAndSettle();

      // Test with complex child widget
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedButton(
              onPressed: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Play'),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final complexButton = find.byType(NakedButton);
      expect(complexButton, findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(complexButton);
      await tester.pumpAndSettle();
    });
  });
}
