import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'helpers/simulate_hover.dart';

const _key = Key('radioButton');

void main() {
  group('Structural Tests', () {
    testWidgets('renders child widget correctly', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: null,
          onChanged: (_) {},
          child: const NakedRadio<String>(
            value: 'test',
            child: Text('Test Radio'),
          ),
        ),
      );

      expect(find.text('Test Radio'), findsOneWidget);
    });

    testWidgets('throws FlutterError when used outside NakedRadioGroup', (
      WidgetTester tester,
    ) async {
      FlutterErrorDetails? errorDetails;
      FlutterError.onError = (FlutterErrorDetails details) {
        errorDetails = details;
      };

      await tester.pumpMaterialWidget(
        const NakedRadio<String>(
          value: 'test',
          child: SizedBox(width: 24, height: 24),
        ),
      );

      await tester.pump();

      expect(errorDetails?.exception, isA<FlutterError>());
    });
  });

  group('Selection Behavior Tests', () {
    testWidgets('handles tap to select', (WidgetTester tester) async {
      String? selectedValue;

      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: null,
          onChanged: (value) => selectedValue = value,
          child: const NakedRadio<String>(
            value: 'test',
            child: SizedBox(width: 24, height: 24),
          ),
        ),
      );

      await tester.tap(find.byType(NakedRadio<String>));
      await tester.pumpAndSettle();
      expect(selectedValue, 'test');
    });

    testWidgets('maintains selected state when matching group value', (
      WidgetTester tester,
    ) async {
      String? selectedValue = 'test';
      bool wasChanged = false;

      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: selectedValue,
          onChanged: (_) => wasChanged = true,
          child: const NakedRadio<String>(
            value: 'test',
            child: SizedBox(width: 24, height: 24),
          ),
        ),
      );

      await tester.tap(find.byType(NakedRadio<String>));
      expect(
        wasChanged,
        isFalse,
      ); // Should not call onChanged when already selected
    });
  });

  group('State Callback Tests', () {
    testWidgets('reports hovered state changes', (WidgetTester tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      bool isHovered = false;

      await tester.pumpMaterialWidget(
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: NakedRadioGroup<String>(
            groupValue: 'test',
            onChanged: (_) {},
            child: NakedRadio<String>(
              key: _key,
              value: 'test',
              onHoverChange: (hovered) => isHovered = hovered,
              child: Container(width: 24, height: 24, color: Colors.red),
            ),
          ),
        ),
      );

      await tester.simulateHover(_key);
      // After hover simulation, hover state should have changed back to false
      expect(isHovered, false);
    });

    testWidgets('reports pressed state changes', (WidgetTester tester) async {
      bool isPressed = false;

      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: null,
          onChanged: (_) {},
          child: NakedRadio<String>(
            value: 'test',
            onPressChange: (pressed) => isPressed = pressed,
            child: const SizedBox(width: 24, height: 24),
          ),
        ),
      );

      final gesture = await tester.press(find.byType(NakedRadio<String>));
      await tester.pump();
      expect(isPressed, true);

      await gesture.up();
      await tester.pump();
      expect(isPressed, false);
    });

    testWidgets('reports focused state changes', (WidgetTester tester) async {
      bool isFocused = false;
      final focusNode = FocusNode();

      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: null,
          onChanged: (_) {},
          child: NakedRadio<String>(
            value: 'test',
            onFocusChange: (focused) => isFocused = focused,
            focusNode: focusNode,
            child: const SizedBox(width: 24, height: 24),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(isFocused, true);

      focusNode.unfocus();
      await tester.pump();
      expect(isFocused, false);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('provides correct semantic properties', (
      WidgetTester tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: 'test', // Selected
          onChanged: (_) {},
          child: NakedRadio<String>(
            key: key,
            value: 'test',
            child: const SizedBox(width: 24, height: 24),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
    });

    // TODO: Fix keyboard activation - currently broken due to NakedInteractable changes
    // testWidgets('handles keyboard selection with Space and Enter keys', (
    //   WidgetTester tester,
    // ) async {
    //   String? selectedValue;
    //   final focusNode = FocusNode();

    //   await tester.pumpMaterialWidget(
    //     NakedRadioGroup<String>(
    //       groupValue: null,
    //       onChanged: (value) => selectedValue = value,
    //       child: NakedRadio<String>(
    //         value: 'test',
    //         focusNode: focusNode,
    //         child: const SizedBox(width: 24, height: 24),
    //       ),
    //     ),
    //   );

    //   focusNode.requestFocus();
    //   await tester.pump();

    //   for (final key in [LogicalKeyboardKey.space, LogicalKeyboardKey.enter]) {
    //     await tester.sendKeyEvent(key);
    //     await tester.pump();
    //     expect(selectedValue, 'test');
    //     selectedValue = null;
    //   }
    // });

    testWidgets('properly manages focus', (WidgetTester tester) async {
      bool isFocused = false;
      final focusNode = FocusNode();

      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: null,
          onChanged: (_) {},
          child: NakedRadio<String>(
            value: 'test',
            focusNode: focusNode,
            onFocusChange: (focused) => isFocused = focused,
            child: const SizedBox(width: 24, height: 24),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(isFocused, true);
      expect(focusNode.hasFocus, true);
    });

    testWidgets('uses custom focus node when provided', (
      WidgetTester tester,
    ) async {
      final customFocusNode = FocusNode();

      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: null,
          onChanged: (_) {},
          child: NakedRadio<String>(
            value: 'test',
            focusNode: customFocusNode,
            child: const SizedBox(width: 24, height: 24),
          ),
        ),
      );

      customFocusNode.requestFocus();
      await tester.pump();
      expect(customFocusNode.hasFocus, true);
    });
  });

  group('Interactivity Tests', () {
    testWidgets('disables interaction when RadioButton is disabled', (
      WidgetTester tester,
    ) async {
      bool wasChanged = false;

      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: null,
          onChanged: (_) => wasChanged = true,
          child: const NakedRadio<String>(
            value: 'test',
            enabled: false,
            child: SizedBox(width: 24, height: 24),
          ),
        ),
      );

      await tester.tap(find.byType(NakedRadio<String>));
      expect(wasChanged, false);
    });

    testWidgets('enables selection when group value is null', (
      WidgetTester tester,
    ) async {
      bool wasChanged = false;

      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: null,
          onChanged: (_) => wasChanged = true,

          child: const NakedRadio<String>(
            value: 'test',
            child: SizedBox(width: 24, height: 24),
          ),
        ),
      );

      await tester.tap(find.byType(NakedRadio<String>));
      expect(wasChanged, true);
    });

    testWidgets('shows forbidden cursor when disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: null,
          onChanged: (_) {},
          child: const NakedRadio<String>(
            key: _key,
            value: 'test',
            enabled: false,
            child: SizedBox(width: 24, height: 24),
          ),
        ),
      );

      tester.expectCursor(SystemMouseCursors.forbidden, on: _key);
    });

    testWidgets(
      'keyboard focus management works correctly',
      (tester) async {
        String? selected;

        final focusNodes = [FocusNode(), FocusNode(), FocusNode()];

        await tester.pumpMaterialWidget(
          NakedRadioGroup<String>(
            groupValue: null,
            onChanged: (v) => selected = v,
            child: Row(
              children: [
                NakedRadio<String>(
                  value: 'a',
                  focusNode: focusNodes[0],
                  child: const SizedBox(width: 20, height: 20),
                ),
                NakedRadio<String>(
                  value: 'b',
                  focusNode: focusNodes[1],
                  child: const SizedBox(width: 20, height: 20),
                ),
                NakedRadio<String>(
                  value: 'c',
                  focusNode: focusNodes[2],
                  child: const SizedBox(width: 20, height: 20),
                ),
              ],
            ),
          ),
        );

        // Focus first radio
        focusNodes[0].requestFocus();
        await tester.pump();
        // Initially no selection (focusing doesn't auto-select)
        expect(selected, null);
        expect(focusNodes[0].hasFocus, true);

        // Focus second radio
        focusNodes[1].requestFocus();
        await tester.pump();
        expect(selected, null); // Still no selection from focus alone
        expect(focusNodes[1].hasFocus, true);

        // Space key should select the focused radio
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(selected, 'b');
      },
      timeout: Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'keyboard selection with space and enter keys',
      (tester) async {
        String? selected;

        final focusNodes = [FocusNode(), FocusNode(), FocusNode()];

        await tester.pumpMaterialWidget(
          NakedRadioGroup<String>(
            groupValue: null,
            onChanged: (v) => selected = v,
            child: Column(
              children: [
                NakedRadio<String>(
                  value: 'a',
                  focusNode: focusNodes[0],
                  child: const SizedBox(width: 20, height: 20),
                ),
                NakedRadio<String>(
                  value: 'b',
                  focusNode: focusNodes[1],
                  child: const SizedBox(width: 20, height: 20),
                ),
                NakedRadio<String>(
                  value: 'c',
                  focusNode: focusNodes[2],
                  child: const SizedBox(width: 20, height: 20),
                ),
              ],
            ),
          ),
        );

        // Focus first radio
        focusNodes[0].requestFocus();
        await tester.pump();
        expect(selected, null);

        // Space key selects
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(selected, 'a');

        // Focus different radio
        focusNodes[2].requestFocus();
        await tester.pumpAndSettle();

        // Enter key also selects
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(selected, 'c');
      },
      timeout: Timeout(Duration(seconds: 20)),
    );

    testWidgets('uses custom cursor when specified', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          key: _key,
          groupValue: null,
          onChanged: (_) {},
          child: const NakedRadio<String>(
            value: 'test',
            mouseCursor: SystemMouseCursors.help,
            child: SizedBox(width: 24, height: 24),
          ),
        ),
      );

      tester.expectCursor(SystemMouseCursors.help, on: _key);
    });
  });

  group('Builder Tests', () {
    testWidgets('builder receives Set<WidgetState>', (
      WidgetTester tester,
    ) async {
      Set<WidgetState>? capturedStates;

      await tester.pumpMaterialWidget(
        NakedRadioGroup<String>(
          groupValue: 'value1',
          onChanged: (_) {},
          child: Column(
            children: [
              NakedRadio<String>(
                value: 'value1',
                builder: (context, states, child) {
                  capturedStates = states;
                  return Container(
                    color: states.isSelected ? Colors.blue : Colors.grey,
                    child: const Text('Radio 1'),
                  );
                },
                child: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );

      // Verify builder was called with states
      expect(capturedStates, isNotNull);
      expect(capturedStates, isA<Set<WidgetState>>());

      // Should be selected since groupValue matches value
      expect(capturedStates!.isSelected, isTrue);
    });

    testWidgets('builder updates when selection changes', (
      WidgetTester tester,
    ) async {
      String? groupValue = 'value1';
      Set<WidgetState>? radio1States;
      Set<WidgetState>? radio2States;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return NakedRadioGroup<String>(
                  groupValue: groupValue,
                  onChanged: (value) {
                    setState(() {
                      groupValue = value;
                    });
                  },
                  child: Column(
                    children: [
                      NakedRadio<String>(
                        value: 'value1',
                        builder: (context, states, child) {
                          radio1States = states;
                          return GestureDetector(
                            key: const Key('radio1'),
                            child: Container(
                              color: states.isSelected
                                  ? Colors.blue
                                  : Colors.grey,
                              child: const Text('Radio 1'),
                            ),
                          );
                        },
                        child: const SizedBox.shrink(),
                      ),
                      NakedRadio<String>(
                        value: 'value2',
                        builder: (context, states, child) {
                          radio2States = states;
                          return GestureDetector(
                            key: const Key('radio2'),
                            child: Container(
                              color: states.isSelected
                                  ? Colors.blue
                                  : Colors.grey,
                              child: const Text('Radio 2'),
                            ),
                          );
                        },
                        child: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initially radio1 is selected
      expect(radio1States!.isSelected, isTrue);
      expect(radio2States!.isSelected, isFalse);

      // Tap radio2
      await tester.tap(find.byKey(const Key('radio2')));
      await tester.pump();

      // Now radio2 should be selected
      expect(radio1States!.isSelected, isFalse);
      expect(radio2States!.isSelected, isTrue);
    });

    // TODO: Fix disabled state propagation in RawRadio
    // testWidgets('disabled state is reflected in states', (WidgetTester tester) async {
    //   Set<WidgetState>? capturedStates;

    //   await tester.pumpMaterialWidget(
    //     NakedRadioGroup<String>(
    //       groupValue: null,
    //       onChanged: null, // Disabled group
    //       enabled: false,
    //       child: NakedRadio<String>(
    //         value: 'value1',
    //         builder: (states) {
    //           capturedStates = states;
    //           return Container(
    //             color: states.isDisabled
    //                 ? Colors.grey.shade300
    //                 : Colors.white,
    //             child: const Text('Disabled Radio'),
    //           );
    //         },
    //         child: const SizedBox.shrink(),
    //       ),
    //     ),
    //   );

    //   // Should contain disabled state
    //   expect(capturedStates!.isDisabled, isTrue);
    // });
  });
}
