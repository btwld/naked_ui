import 'package:example/api/naked_checkbox.0.dart' as checkbox_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedCheckbox Integration Tests', () {
    testWidgets('checkbox toggles value correctly', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const checkbox_example.MyApp());
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(NakedCheckbox);
      expect(checkboxFinder, findsOneWidget);

      // Verify initial state (unchecked)
      final checkIcon = find.byIcon(Icons.check);
      expect(checkIcon, findsNothing);

      // Tap to check
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Verify checked state
      expect(checkIcon, findsOneWidget);

      // Tap to uncheck
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Verify unchecked state
      expect(checkIcon, findsNothing);
    });

    testWidgets('checkbox responds to keyboard activation', (tester) async {
      final checkboxKey = UniqueKey();
      bool checkboxValue = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedCheckbox(
              key: checkboxKey,
              value: checkboxValue,
              onChanged: (value) => checkboxValue = value!,
              child: const Text('Test Checkbox'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test keyboard activation
      await tester.testKeyboardActivation(find.byKey(checkboxKey));
      await tester.pumpAndSettle();
    });

    testWidgets('checkbox state callbacks work correctly', (tester) async {
      final checkboxKey = UniqueKey();
      bool isHovered = false;
      bool isPressed = false;
      bool checkboxValue = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedCheckbox(
              key: checkboxKey,
              value: checkboxValue,
              onChanged: (value) => checkboxValue = value!,
              onHoverChange: (hovered) => isHovered = hovered,
              onPressChange: (pressed) => isPressed = pressed,
              onFocusChange: (focused) {},
              child: const Text('Test Checkbox'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test hover state
      await tester.simulateHover(checkboxKey, onHover: () {
        expect(isHovered, isTrue);
      });

      // Test press state
      await tester.simulatePress(checkboxKey, onPressed: () {
        expect(isPressed, isTrue);
      });
    });

    testWidgets('checkbox handles focus management correctly', (tester) async {
      final checkboxKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool focusChanged = false;
      bool checkboxValue = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedCheckbox(
              key: checkboxKey,
              value: checkboxValue,
              onChanged: (value) => checkboxValue = value!,
              focusNode: focusNode,
              onFocusChange: (focused) => focusChanged = focused,
              child: const Text('Test Checkbox'),
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

    testWidgets('disabled checkbox blocks all interactions', (tester) async {
      final checkboxKey = UniqueKey();
      bool wasChanged = false;
      bool hoverChanged = false;
      bool checkboxValue = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedCheckbox(
              key: checkboxKey,
              value: checkboxValue,
              onChanged: (value) => wasChanged = true,
              enabled: false,
              onHoverChange: (hovered) => hoverChanged = true,
              onFocusChange: (focused) {},
              child: const Text('Disabled Checkbox'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test that disabled checkbox doesn't respond to tap
      await tester.tap(find.byKey(checkboxKey));
      await tester.pump();
      expect(wasChanged, isFalse);

      // Test that disabled checkbox doesn't respond to keyboard
      await tester.testKeyboardActivation(find.byKey(checkboxKey));
      expect(wasChanged, isFalse);

      // Test that hover callbacks aren't triggered when disabled
      await tester.simulateHover(checkboxKey);
      expect(hoverChanged, isFalse);
    });

    testWidgets('tap toggles value and does not request focus by default',
        (tester) async {
      final checkboxKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool checkboxValue = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedCheckbox(
              key: checkboxKey,
              focusNode: focusNode,
              value: checkboxValue,
              onChanged: (value) => checkboxValue = value!,
              child: const Text('Focus Test Checkbox'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Initially not focused
      expect(focusNode.hasFocus, isFalse);

      // Tap checkbox - should NOT request focus by default
      await tester.tap(find.byKey(checkboxKey));
      await tester.pump();

      // Should still not be focused, but value should be toggled
      expect(focusNode.hasFocus, isFalse);
      expect(checkboxValue, isTrue);
    });

    testWidgets('tap does not request focus (explicit focusNode present)',
        (tester) async {
      final checkboxKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool checkboxValue = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedCheckbox(
              key: checkboxKey,
              focusNode: focusNode,
              value: checkboxValue,
              onChanged: (value) => checkboxValue = value!,
              child: const Text('No Focus Test Checkbox'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Initially not focused
      expect(focusNode.hasFocus, isFalse);

      // Tap checkbox - should NOT request focus
      await tester.tap(find.byKey(checkboxKey));
      await tester.pump();

      // Should still not be focused
      expect(focusNode.hasFocus, isFalse);
      expect(checkboxValue, isTrue); // But value should still change
    });

    testWidgets('checkbox builder method works with states', (tester) async {
      final checkboxKey = UniqueKey();
      bool checkboxValue = false;
      bool isHovered = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return NakedCheckbox(
                  key: checkboxKey,
                  value: checkboxValue,
                  onChanged: (value) => setState(() => checkboxValue = value!),
                  builder: (context, states, child) {
                    final isChecked = states.contains(WidgetState.selected);
                    final box = Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isChecked ? Colors.blue : Colors.white,
                        border: Border.all(
                          color: states.contains(WidgetState.hovered)
                              ? Colors.blue.shade400
                              : Colors.grey,
                          width: states.contains(WidgetState.pressed) ? 3 : 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    );
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        box,
                        const SizedBox(height: 8),
                        if (child != null) child,
                      ],
                    );
                  },
                  onHoverChange: (hovered) => isHovered = hovered,
                  child: const Text('Builder Checkbox'),
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final checkboxFinder = find.byKey(checkboxKey);
      expect(checkboxFinder, findsOneWidget);
      expect(find.text('Builder Checkbox'), findsOneWidget);

      // Initially unchecked
      expect(find.byIcon(Icons.check), findsNothing);

      // Test hover state updates builder
      await tester.simulateHover(checkboxKey, onHover: () {
        expect(isHovered, isTrue);
      });

      // Tap to check - builder should update
      await tester.tap(checkboxFinder);
      await tester.pump();
      expect(checkboxValue, isTrue);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('checkbox supports tristate mode', (tester) async {
      final checkboxKey = UniqueKey();
      bool? checkboxValue; // null for indeterminate state

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return NakedCheckbox(
                  key: checkboxKey,
                  value: checkboxValue,
                  tristate: true,
                  onChanged: (value) => setState(() => checkboxValue = value),
                  child: const Text('Tristate Checkbox'),
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final checkboxFinder = find.byKey(checkboxKey);
      expect(checkboxFinder, findsOneWidget);

      // Initially null (indeterminate)
      expect(checkboxValue, isNull);

      // Our tristate cycles: false → true → null → false
      // Starting from null, next is false
      await tester.tap(checkboxFinder);
      await tester.pump();
      expect(checkboxValue, isFalse);

      // Next: false -> true
      await tester.tap(checkboxFinder);
      await tester.pump();
      expect(checkboxValue, isTrue);

      // Next: true -> null
      await tester.tap(checkboxFinder);
      await tester.pump();
      expect(checkboxValue, isNull);
    });

    testWidgets('checkbox works with different visual states', (tester) async {
      // Test checked and unchecked visual representations
      await tester.pumpWidget(const checkbox_example.MyApp());
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(NakedCheckbox);

      // Find the visual container that changes based on state
      final containerFinder = find.descendant(
        of: checkboxFinder,
        matching: find.byType(AnimatedContainer),
      );
      expect(containerFinder, findsOneWidget);

      // Test interaction with the visual checkbox
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Verify the visual indicator appears
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Test another toggle
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Verify the visual indicator disappears
      expect(find.byIcon(Icons.check), findsNothing);
    });
  });
}
