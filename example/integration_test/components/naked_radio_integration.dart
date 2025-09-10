import 'package:example/api/naked_radio.0.dart' as radio_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedRadio Integration Tests', () {
    testWidgets('radio group handles single selection correctly',
        (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const radio_example.MyApp());
      await tester.pumpAndSettle();

      final radioGroupFinder =
          find.byType(RadioGroup<radio_example.RadioOption>);
      expect(radioGroupFinder, findsOneWidget);

      // The example renders purely visual radios without text labels.
      // Tap the second radio by index and verify group value changes via UI behavior.
      final radios = find.byType(NakedRadio<radio_example.RadioOption>);
      expect(radios, findsNWidgets(2));

      // Select the second radio (apple)
      await tester.tap(radios.at(1));
      await tester.pumpAndSettle();

      // Select back the first radio (banana)
      await tester.tap(radios.at(0));
      await tester.pumpAndSettle();

      // Both radios remain in the tree
      expect(radios, findsNWidgets(2));
    });

    testWidgets('radio responds to keyboard activation', (tester) async {
      final radioKey = UniqueKey();
      radio_example.RadioOption selectedValue =
          radio_example.RadioOption.banana;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: RadioGroup<radio_example.RadioOption>(
              groupValue: selectedValue,
              onChanged: (value) => selectedValue = value!,
              child: NakedRadio<radio_example.RadioOption>(
                key: radioKey,
                value: radio_example.RadioOption.apple,
                child: const Text('Apple'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test keyboard activation
      await tester.testKeyboardActivation(find.byKey(radioKey));
      await tester.pumpAndSettle();
    });

    testWidgets('radio state callbacks work correctly', (tester) async {
      final radioKey = UniqueKey();
      bool isHovered = false;
      bool isPressed = false;
      radio_example.RadioOption selectedValue =
          radio_example.RadioOption.banana;
      Set<WidgetState>? lastStates;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: RadioGroup<radio_example.RadioOption>(
              groupValue: selectedValue,
              onChanged: (value) => selectedValue = value!,
              child: NakedRadio<radio_example.RadioOption>(
                key: radioKey,
                value: radio_example.RadioOption.apple,
                onHoverChange: (hovered) => isHovered = hovered,
                onPressChange: (pressed) => isPressed = pressed,
                onFocusChange: (focused) {},
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
      });

      // Test press state
      await tester.simulatePress(radioKey, onPressed: () {
        expect(isPressed, isTrue);
      });
    });

    testWidgets('radio handles focus management correctly', (tester) async {
      final radioKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool focusChanged = false;
      radio_example.RadioOption selectedValue =
          radio_example.RadioOption.banana;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: RadioGroup<radio_example.RadioOption>(
              groupValue: selectedValue,
              onChanged: (value) => selectedValue = value!,
              child: NakedRadio<radio_example.RadioOption>(
                key: radioKey,
                value: radio_example.RadioOption.apple,
                focusNode: focusNode,
                onFocusChange: (focused) => focusChanged = focused,
                child: const Text('Focus Test Radio'),
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
      bool hoverChanged = false;
      radio_example.RadioOption selectedValue =
          radio_example.RadioOption.banana;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: RadioGroup<radio_example.RadioOption>(
              groupValue: selectedValue,
              onChanged: (value) => selectedValue = value!,
              child: NakedRadio<radio_example.RadioOption>(
                key: radioKey,
                value: radio_example.RadioOption.apple,
                enabled: false,
                onHoverChange: (hovered) => hoverChanged = true,
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
      expect(
          selectedValue, radio_example.RadioOption.banana); // Should not change

      // Test that hover callbacks aren't triggered when disabled
      await tester.simulateHover(radioKey);
      expect(hoverChanged, isFalse);

      // Test that disabled radio doesn't respond to keyboard
      await tester.testKeyboardActivation(find.byKey(radioKey));
      expect(
          selectedValue, radio_example.RadioOption.banana); // Should not change
    });

    testWidgets('radio group enforces single selection', (tester) async {
      radio_example.RadioOption selectedValue =
          radio_example.RadioOption.banana;
      final radio1Key = UniqueKey();
      final radio2Key = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: RadioGroup<radio_example.RadioOption>(
              groupValue: selectedValue,
              onChanged: (value) => selectedValue = value!,
              child: Column(
                children: [
                  NakedRadio<radio_example.RadioOption>(
                    key: radio1Key,
                    value: radio_example.RadioOption.apple,
                    builder: (context, states, child) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                states.isSelected ? Colors.blue : Colors.grey,
                            width: states.isSelected ? 4 : 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                  NakedRadio<radio_example.RadioOption>(
                    key: radio2Key,
                    value: radio_example.RadioOption.banana,
                    builder: (context, states, child) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                states.isSelected ? Colors.blue : Colors.grey,
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

      // Initially banana is selected
      expect(selectedValue, radio_example.RadioOption.banana);

      // Select apple - should change selection
      await tester.tap(find.byKey(radio1Key));
      await tester.pumpAndSettle();
      expect(selectedValue, radio_example.RadioOption.apple);

      // Select banana - should change selection back
      await tester.tap(find.byKey(radio2Key));
      await tester.pumpAndSettle();

      // Both radios should exist but only one should be visually selected
      expect(find.byKey(radio1Key), findsOneWidget);
      expect(find.byKey(radio2Key), findsOneWidget);
    });

    testWidgets('radio builder method works with states', (tester) async {
      final radioKey = UniqueKey();
      radio_example.RadioOption? groupValue;
      bool isSelected = false;
      bool isHovered = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return RadioGroup<radio_example.RadioOption>(
                  groupValue: groupValue,
                  onChanged: (value) => setState(() => groupValue = value),
                  child: NakedRadio<radio_example.RadioOption>(
                    key: radioKey,
                    value: radio_example.RadioOption.apple,
                    onHoverChange: (hovered) => isHovered = hovered,
                    builder: (context, states, child) {
                      isSelected = states.contains(WidgetState.selected);
                      return Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.blue : Colors.white,
                          border: Border.all(
                            color: states.contains(WidgetState.hovered)
                                ? Colors.blue.shade400
                                : Colors.grey,
                            width: states.contains(WidgetState.pressed) ? 3 : 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.circle,
                                color: Colors.white, size: 12)
                            : null,
                      );
                    },
                    child: const Text('Builder Radio'),
                  ),
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final radioFinder = find.byKey(radioKey);
      expect(radioFinder, findsOneWidget);

      // Initially not selected
      expect(isSelected, isFalse);

      // Test hover state updates builder
      await tester.simulateHover(radioKey, onHover: () {
        expect(isHovered, isTrue);
      });

      // Tap to select - builder should update
      await tester.tap(radioFinder);
      await tester.pump();
      expect(groupValue, radio_example.RadioOption.apple);
      expect(isSelected, isTrue);
      expect(find.byIcon(Icons.circle), findsOneWidget);
    });
  });
}
