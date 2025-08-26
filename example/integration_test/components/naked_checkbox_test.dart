import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:example/api/naked_checkbox.0.dart' as checkbox_example;

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
      Set<WidgetState>? lastStates;
      
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
              onStatesChange: (states) => lastStates = states,
              child: const Text('Test Checkbox'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Test hover state
      await tester.simulateHover(checkboxKey, onHover: () {
        expect(isHovered, isTrue);
        if (lastStates != null) {
          tester.expectWidgetStates(lastStates!, expectHovered: true);
        }
      });
      
      // Test press state
      await tester.simulatePress(checkboxKey, onPressed: () {
        expect(isPressed, isTrue);
        if (lastStates != null) {
          tester.expectWidgetStates(lastStates!, expectPressed: true);
        }
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
    
    testWidgets('focusOnPress requests focus when enabled', (tester) async {
      final checkboxKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool checkboxValue = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedCheckbox(
              key: checkboxKey,
              focusNode: focusNode,
              focusOnPress: true,
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
      
      // Tap checkbox - should request focus
      await tester.tap(find.byKey(checkboxKey));
      await tester.pump();
      
      // Now should be focused
      expect(focusNode.hasFocus, isTrue);
      expect(checkboxValue, isTrue); // And value should be changed
    });
    
    testWidgets('focusOnPress disabled does not request focus', (tester) async {
      final checkboxKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool checkboxValue = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedCheckbox(
              key: checkboxKey,
              focusNode: focusNode,
              focusOnPress: false, // Default value, but explicit for test
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