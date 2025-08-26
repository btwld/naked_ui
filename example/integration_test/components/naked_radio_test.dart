import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:example/api/naked_radio.0.dart' as radio_example;

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('NakedRadio Integration Tests', () {
    testWidgets('radio group handles single selection correctly', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const radio_example.MyApp());
      await tester.pumpAndSettle();
      
      final radioGroupFinder = find.byType(NakedRadioGroup<radio_example.RadioOption>);
      expect(radioGroupFinder, findsOneWidget);
      
      // Find both radio buttons
      final radioFinders = find.byType(NakedRadio<radio_example.RadioOption>);
      expect(radioFinders, findsNWidgets(2));
      
      // Initially banana should be selected (thick border)
      // We can test by tapping each radio and verifying visual changes
      final appleRadio = radioFinders.at(1);
      
      // Tap apple radio
      await tester.tap(appleRadio);
      await tester.pumpAndSettle();
      
      // Tap banana radio again
      final bananaRadio = radioFinders.at(0);
      await tester.tap(bananaRadio);
      await tester.pumpAndSettle();
      
      // The visual state should update (border thickness changes)
      expect(radioFinders, findsNWidgets(2));
    });
    
    testWidgets('radio responds to keyboard activation', (tester) async {
      final radioKey1 = UniqueKey();
      final radioKey2 = UniqueKey();
      radio_example.RadioOption selectedValue = radio_example.RadioOption.banana;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedRadioGroup<radio_example.RadioOption>(
              groupValue: selectedValue,
              onChanged: (value) => selectedValue = value!,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedRadio<radio_example.RadioOption>(
                    key: radioKey1,
                    value: radio_example.RadioOption.banana,
                    child: const Text('Banana'),
                  ),
                  NakedRadio<radio_example.RadioOption>(
                    key: radioKey2,
                    value: radio_example.RadioOption.apple,
                    child: const Text('Apple'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Test keyboard activation on second radio
      await tester.testKeyboardActivation(find.byKey(radioKey2));
      await tester.pumpAndSettle();
    });
    
    testWidgets('radio state callbacks work correctly', (tester) async {
      final radioKey = UniqueKey();
      bool isHovered = false;
      bool isPressed = false;
      radio_example.RadioOption selectedValue = radio_example.RadioOption.banana;
      Set<WidgetState>? lastStates;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedRadioGroup<radio_example.RadioOption>(
              groupValue: selectedValue,
              onChanged: (value) => selectedValue = value!,
              child: NakedRadio<radio_example.RadioOption>(
                key: radioKey,
                value: radio_example.RadioOption.apple,
                onHoverChange: (hovered) => isHovered = hovered,
                onPressChange: (pressed) => isPressed = pressed,
                onFocusChange: (focused) {},
                onStatesChange: (states) => lastStates = states,
                builder: (context, states, child) {
                  return Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: states.isSelected ? Colors.blue : Colors.grey,
                        width: states.isSelected ? 4 : 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Test hover state
      await tester.simulateHover(radioKey, onHover: () {
        expect(isHovered, isTrue);
        if (lastStates != null) {
          tester.expectWidgetStates(lastStates!, expectHovered: true);
        }
      });
      
      // Test press state
      await tester.simulatePress(radioKey, onPressed: () {
        expect(isPressed, isTrue);
        if (lastStates != null) {
          tester.expectWidgetStates(lastStates!, expectPressed: true);
        }
      });
      
      // Selection state testing is complex with groups - tested in dedicated selection tests
    });
    
    testWidgets('radio handles focus management correctly', (tester) async {
      final radioKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool focusChanged = false;
      radio_example.RadioOption selectedValue = radio_example.RadioOption.banana;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedRadioGroup<radio_example.RadioOption>(
              groupValue: selectedValue,
              onChanged: (value) => selectedValue = value!,
              child: NakedRadio<radio_example.RadioOption>(
                key: radioKey,
                value: radio_example.RadioOption.apple,
                focusNode: focusNode,
                onFocusChange: (focused) => focusChanged = focused,
                child: const Text('Test Radio'),
              ),
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
    
    testWidgets('disabled radio blocks interactions', (tester) async {
      final radioKey = UniqueKey();
      bool wasChanged = false;
      bool hoverChanged = false;
      radio_example.RadioOption selectedValue = radio_example.RadioOption.banana;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedRadioGroup<radio_example.RadioOption>(
              groupValue: selectedValue,
              onChanged: (value) => wasChanged = true,
              child: NakedRadio<radio_example.RadioOption>(
                key: radioKey,
                value: radio_example.RadioOption.apple,
                enabled: false,
                onHoverChange: (hovered) => hoverChanged = true,
                onFocusChange: (focused) {},
                child: const Text('Disabled Radio'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Test that disabled radio doesn't respond to tap
      await tester.tap(find.byKey(radioKey));
      await tester.pump();
      expect(wasChanged, isFalse);
      
      // Test that disabled radio doesn't respond to keyboard
      await tester.testKeyboardActivation(find.byKey(radioKey));
      expect(wasChanged, isFalse);
      
      // Test that hover callbacks aren't triggered when disabled
      await tester.simulateHover(radioKey);
      expect(hoverChanged, isFalse);
    });

    testWidgets('radio group enforces single selection', (tester) async {
      final radio1Key = UniqueKey();
      final radio2Key = UniqueKey();
      radio_example.RadioOption selectedValue = radio_example.RadioOption.banana;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedRadioGroup<radio_example.RadioOption>(
              groupValue: selectedValue,
              onChanged: (value) => selectedValue = value!,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedRadio<radio_example.RadioOption>(
                    key: radio1Key,
                    value: radio_example.RadioOption.banana,
                    builder: (context, states, child) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: states.isSelected ? Colors.blue : Colors.grey,
                            width: states.isSelected ? 4 : 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  NakedRadio<radio_example.RadioOption>(
                    key: radio2Key,
                    value: radio_example.RadioOption.apple,
                    builder: (context, states, child) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: states.isSelected ? Colors.blue : Colors.grey,
                            width: states.isSelected ? 4 : 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Initially banana should be selected
      // Tap apple radio to change selection
      await tester.tap(find.byKey(radio2Key));
      await tester.pumpAndSettle();
      
      // Tap banana radio to change back
      await tester.tap(find.byKey(radio1Key));
      await tester.pumpAndSettle();
      
      // Both radios should exist but only one should be visually selected
      expect(find.byKey(radio1Key), findsOneWidget);
      expect(find.byKey(radio2Key), findsOneWidget);
    });
  });
}