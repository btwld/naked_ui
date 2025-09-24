import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/src/mixins/naked_mixins.dart';

class TestWidgetWithStatesMixin extends StatefulWidget {
  const TestWidgetWithStatesMixin({
    super.key,
    this.initialStates = const {},
    this.onHoverChange,
    this.onFocusChange,
    this.onPressChange,
    this.onSelectedChange,
    this.isDisabled = false,
  });

  final Set<WidgetState> initialStates;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onPressChange;
  final ValueChanged<bool>? onSelectedChange;
  final bool isDisabled;

  @override
  State<TestWidgetWithStatesMixin> createState() =>
      _TestWidgetWithStatesMixinState();
}

class _TestWidgetWithStatesMixinState extends State<TestWidgetWithStatesMixin>
    with WidgetStatesMixin<TestWidgetWithStatesMixin> {
  @override
  void initializeWidgetStates() {
    // Set initial states from widget (except disabled which is handled separately)
    for (final state in widget.initialStates) {
      if (state != WidgetState.disabled) {
        updateState(state, true);
      }
    }
    updateDisabledState(widget.isDisabled);
  }

  @override
  void didUpdateWidget(TestWidgetWithStatesMixin oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncWidgetStates();
  }

  void simulateHover(bool hovered) {
    updateHoverState(hovered, widget.onHoverChange);
  }

  void simulateFocus(bool focused) {
    updateFocusState(focused, widget.onFocusChange);
  }

  void simulatePress(bool pressed) {
    updatePressState(pressed, widget.onPressChange);
  }

  void simulateSelected(bool selected) {
    updateSelectedState(selected, widget.onSelectedChange);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: isPressed
          ? Colors.red
          : isHovered
          ? Colors.blue
          : isFocused
          ? Colors.green
          : isSelected
          ? Colors.purple
          : isDisabled
          ? Colors.grey
          : Colors.white,
    );
  }
}

void main() {
  group('WidgetStatesMixin', () {
    group('State initialization', () {
      testWidgets('initializes with empty states by default', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: TestWidgetWithStatesMixin()),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );
        expect(state.widgetStates, isEmpty);
        expect(state.isFocused, isFalse);
        expect(state.isHovered, isFalse);
        expect(state.isPressed, isFalse);
        expect(state.isDisabled, isFalse);
        expect(state.isSelected, isFalse);
        expect(state.isEnabled, isTrue);
      });

      testWidgets('initializes with provided states', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TestWidgetWithStatesMixin(
              initialStates: {
                WidgetState.hovered,
                WidgetState.focused,
                WidgetState.selected,
              },
              isDisabled: true,
            ),
          ),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );
        expect(state.widgetStates, contains(WidgetState.hovered));
        expect(state.widgetStates, contains(WidgetState.focused));
        expect(state.widgetStates, contains(WidgetState.selected));
        expect(state.widgetStates, contains(WidgetState.disabled));
        expect(state.isFocused, isTrue);
        expect(state.isHovered, isTrue);
        expect(state.isPressed, isFalse);
        expect(state.isDisabled, isTrue);
        expect(state.isSelected, isTrue);
        expect(state.isEnabled, isFalse);
      });

      testWidgets('syncWidgetStates updates states when widget changes', (
        tester,
      ) async {
        Widget buildWidget(bool isDisabled) {
          return MaterialApp(
            home: TestWidgetWithStatesMixin(
              isDisabled: isDisabled,
              initialStates: const {WidgetState.hovered},
            ),
          );
        }

        // Start not disabled
        await tester.pumpWidget(buildWidget(false));
        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );
        expect(state.isDisabled, isFalse);
        expect(state.isHovered, isTrue);

        // Change to disabled
        await tester.pumpWidget(buildWidget(true));
        expect(state.isDisabled, isTrue);
        expect(state.isHovered, isTrue); // Should preserve other states
      });
    });

    group('State getters', () {
      testWidgets('all state getters return correct values', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TestWidgetWithStatesMixin(
              initialStates: {
                WidgetState.hovered,
                WidgetState.focused,
                WidgetState.pressed,
                WidgetState.selected,
              },
              isDisabled: true,
            ),
          ),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );
        expect(state.isFocused, isTrue);
        expect(state.isHovered, isTrue);
        expect(state.isPressed, isTrue);
        expect(state.isDisabled, isTrue);
        expect(state.isSelected, isTrue);
        expect(state.isEnabled, isFalse); // Opposite of disabled
      });

      testWidgets('isEnabled returns opposite of isDisabled', (tester) async {
        Widget buildWidget(bool disabled) {
          return MaterialApp(
            home: TestWidgetWithStatesMixin(isDisabled: disabled),
          );
        }

        // Not disabled
        await tester.pumpWidget(buildWidget(false));
        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );
        expect(state.isDisabled, isFalse);
        expect(state.isEnabled, isTrue);

        // Disabled
        await tester.pumpWidget(buildWidget(true));
        expect(state.isDisabled, isTrue);
        expect(state.isEnabled, isFalse);
      });
    });

    group('State updates', () {
      testWidgets('updateState changes state and triggers rebuild', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(home: TestWidgetWithStatesMixin()),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );
        expect(state.isFocused, isFalse);

        // Update state
        final changed = state.updateState(WidgetState.focused, true);
        expect(changed, isTrue);
        expect(state.isFocused, isTrue);

        await tester.pump();

        // Widget should rebuild and show focused state
        final container = tester.widget<Container>(find.byType(Container));
        expect(container.color, equals(Colors.green)); // focused color
      });

      testWidgets('updateState returns false when value does not change', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TestWidgetWithStatesMixin(
              initialStates: {WidgetState.hovered},
            ),
          ),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );
        expect(state.isHovered, isTrue);

        // Try to set the same value
        final changed = state.updateState(WidgetState.hovered, true);
        expect(changed, isFalse);
        expect(state.isHovered, isTrue);
      });

      testWidgets('updateState removes state when value is false', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TestWidgetWithStatesMixin(
              initialStates: {WidgetState.hovered},
            ),
          ),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );
        expect(state.isHovered, isTrue);

        // Remove state
        final changed = state.updateState(WidgetState.hovered, false);
        expect(changed, isTrue);
        expect(state.isHovered, isFalse);
      });
    });

    group('State update helpers', () {
      testWidgets('updateHoverState calls callback only when state changes', (
        tester,
      ) async {
        bool? lastHoverValue;
        int callbackCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidgetWithStatesMixin(
              onHoverChange: (hovered) {
                lastHoverValue = hovered;
                callbackCount++;
              },
            ),
          ),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );

        // Start hover
        state.simulateHover(true);
        await tester.pump();
        expect(lastHoverValue, isTrue);
        expect(callbackCount, equals(1));
        expect(state.isHovered, isTrue);

        // Try to set same value - should not call callback
        state.simulateHover(true);
        await tester.pump();
        expect(callbackCount, equals(1)); // No additional callback

        // End hover
        state.simulateHover(false);
        await tester.pump();
        expect(lastHoverValue, isFalse);
        expect(callbackCount, equals(2));
        expect(state.isHovered, isFalse);
      });

      testWidgets('updateFocusState calls callback only when state changes', (
        tester,
      ) async {
        bool? lastFocusValue;
        int callbackCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidgetWithStatesMixin(
              onFocusChange: (focused) {
                lastFocusValue = focused;
                callbackCount++;
              },
            ),
          ),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );

        // Start focus
        state.simulateFocus(true);
        await tester.pump();
        expect(lastFocusValue, isTrue);
        expect(callbackCount, equals(1));
        expect(state.isFocused, isTrue);

        // Try to set same value - should not call callback
        state.simulateFocus(true);
        await tester.pump();
        expect(callbackCount, equals(1)); // No additional callback

        // End focus
        state.simulateFocus(false);
        await tester.pump();
        expect(lastFocusValue, isFalse);
        expect(callbackCount, equals(2));
        expect(state.isFocused, isFalse);
      });

      testWidgets('updatePressState calls callback only when state changes', (
        tester,
      ) async {
        bool? lastPressValue;
        int callbackCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: TestWidgetWithStatesMixin(
              onPressChange: (pressed) {
                lastPressValue = pressed;
                callbackCount++;
              },
            ),
          ),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );

        // Start press
        state.simulatePress(true);
        await tester.pump();
        expect(lastPressValue, isTrue);
        expect(callbackCount, equals(1));
        expect(state.isPressed, isTrue);

        // Try to set same value - should not call callback
        state.simulatePress(true);
        await tester.pump();
        expect(callbackCount, equals(1)); // No additional callback

        // End press
        state.simulatePress(false);
        await tester.pump();
        expect(lastPressValue, isFalse);
        expect(callbackCount, equals(2));
        expect(state.isPressed, isFalse);
      });

      testWidgets(
        'updateSelectedState calls callback only when state changes',
        (tester) async {
          bool? lastSelectedValue;
          int callbackCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: TestWidgetWithStatesMixin(
                onSelectedChange: (selected) {
                  lastSelectedValue = selected;
                  callbackCount++;
                },
              ),
            ),
          );

          final state = tester.state<_TestWidgetWithStatesMixinState>(
            find.byType(TestWidgetWithStatesMixin),
          );

          // Start selected
          state.simulateSelected(true);
          await tester.pump();
          expect(lastSelectedValue, isTrue);
          expect(callbackCount, equals(1));
          expect(state.isSelected, isTrue);

          // Try to set same value - should not call callback
          state.simulateSelected(true);
          await tester.pump();
          expect(callbackCount, equals(1)); // No additional callback

          // End selected
          state.simulateSelected(false);
          await tester.pump();
          expect(lastSelectedValue, isFalse);
          expect(callbackCount, equals(2));
          expect(state.isSelected, isFalse);
        },
      );

      testWidgets('updateDisabledState works without callback', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: TestWidgetWithStatesMixin()),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );
        expect(state.isDisabled, isFalse);

        // Enable disabled state
        final changed = state.updateDisabledState(true);
        expect(changed, isTrue);
        expect(state.isDisabled, isTrue);
        expect(state.isEnabled, isFalse);

        await tester.pump();

        // Widget should rebuild and show disabled state
        final container = tester.widget<Container>(find.byType(Container));
        expect(container.color, equals(Colors.grey)); // disabled color
      });
    });

    group('Widget rebuilds', () {
      testWidgets('state changes trigger widget rebuilds', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: TestWidgetWithStatesMixin()),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );

        // Initial state - white background
        Container container = tester.widget<Container>(find.byType(Container));
        expect(container.color, equals(Colors.white));

        // Hover state - blue background
        state.simulateHover(true);
        await tester.pump();
        container = tester.widget<Container>(find.byType(Container));
        expect(container.color, equals(Colors.blue));

        // Press state (higher priority) - red background
        state.simulatePress(true);
        await tester.pump();
        container = tester.widget<Container>(find.byType(Container));
        expect(container.color, equals(Colors.red));

        // Remove press, hover still active - blue background
        state.simulatePress(false);
        await tester.pump();
        container = tester.widget<Container>(find.byType(Container));
        expect(container.color, equals(Colors.blue));
      });

      testWidgets('no rebuild when state does not change', (tester) async {
        int buildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                buildCount++;
                return const TestWidgetWithStatesMixin(
                  initialStates: {WidgetState.hovered},
                );
              },
            ),
          ),
        );

        expect(buildCount, equals(1));

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );

        // Try to set the same state again - should not trigger rebuild
        state.simulateHover(true);
        await tester.pump();

        // Build count should remain the same as no actual state change occurred
        // Note: The mixin widget itself might rebuild, but not the parent Builder
        expect(buildCount, equals(1));
      });
    });

    group('State combinations', () {
      testWidgets('handles multiple simultaneous states', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: TestWidgetWithStatesMixin()),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );

        // Set multiple states
        state.simulateHover(true);
        state.simulateFocus(true);
        state.simulateSelected(true);
        await tester.pump();

        expect(state.isHovered, isTrue);
        expect(state.isFocused, isTrue);
        expect(state.isSelected, isTrue);
        expect(state.widgetStates.length, equals(3));

        // Press has highest visual priority
        state.simulatePress(true);
        await tester.pump();

        final container = tester.widget<Container>(find.byType(Container));
        expect(container.color, equals(Colors.red)); // press color
      });

      testWidgets('widgetStates returns defensive copy', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TestWidgetWithStatesMixin(
              initialStates: {WidgetState.hovered},
            ),
          ),
        );

        final state = tester.state<_TestWidgetWithStatesMixinState>(
          find.byType(TestWidgetWithStatesMixin),
        );
        final stateCopy = state.widgetStates;

        // Modify the copy
        stateCopy.add(WidgetState.focused);

        // Original should not be affected
        expect(state.widgetStates.contains(WidgetState.focused), isFalse);
        expect(state.isFocused, isFalse);
      });
    });
  });

  group('Edge Cases', () {
    testWidgets('updateState when widget is unmounted', (tester) async {
      late _TestWidgetWithStatesMixinState state;

      await tester.pumpWidget(
        MaterialApp(
          home: TestWidgetWithStatesMixin(onHoverChange: (hovered) {}),
        ),
      );

      state = tester.state<_TestWidgetWithStatesMixinState>(
        find.byType(TestWidgetWithStatesMixin),
      );

      // Remove the widget to unmount it
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Call updateState on unmounted widget - should not call setState
      expect(
        () => state.updateState(WidgetState.hovered, true),
        returnsNormally,
      );
    });

    testWidgets('syncWidgetStates calls initializeWidgetStates', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TestWidgetWithStatesMixin()),
      );

      final state = tester.state<_TestWidgetWithStatesMixinState>(
        find.byType(TestWidgetWithStatesMixin),
      );

      // Call syncWidgetStates - should execute without error
      expect(() => state.syncWidgetStates(), returnsNormally);
    });
  });
}
