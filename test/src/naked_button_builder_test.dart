import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedButton Builder Pattern Tests', () {
    testWidgets('builder rebuilds on state change', (
      WidgetTester tester,
    ) async {
      int builderCallCount = 0;
      bool isPressed = false;

      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          builder: (context, state, child) {
            builderCallCount++;
            isPressed = state.states.contains(WidgetState.pressed);
            return Container(
              width: 100,
              height: 50,
              color: isPressed ? Colors.blue : Colors.grey,
              child: child,
            );
          },
          child: const Text('Builder Button'),
        ),
      );

      final initialBuilds = builderCallCount;
      expect(isPressed, isFalse);

      // Trigger press state
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NakedButton)),
      );
      await tester.pumpAndSettle();

      // Builder should have been called again
      expect(builderCallCount, greaterThan(initialBuilds));
      expect(isPressed, isTrue);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('parent widget does NOT rebuild on state change (efficiency)', (
      WidgetTester tester,
    ) async {
      int parentBuildCount = 0;
      int builderBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              parentBuildCount++;
              return Scaffold(
                body: Center(
                  child: NakedButton(
                    onPressed: () {},
                    builder: (context, state, child) {
                      builderBuildCount++;
                      return Container(
                        width: 100,
                        height: 50,
                        color: state.states.contains(WidgetState.pressed)
                            ? Colors.blue
                            : Colors.grey,
                        child: child,
                      );
                    },
                    child: const Text('Efficiency Test'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      final initialParentBuilds = parentBuildCount;
      final initialBuilderBuilds = builderBuildCount;

      // Trigger state change
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NakedButton)),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Parent should NOT rebuild
      expect(parentBuildCount, equals(initialParentBuilds));
      // Builder SHOULD rebuild
      expect(builderBuildCount, greaterThan(initialBuilderBuilds));
    });

    testWidgets('child parameter does not rebuild unnecessarily', (
      WidgetTester tester,
    ) async {
      int childBuildCount = 0;
      int builderBuildCount = 0;

      Widget buildExpensiveChild() {
        childBuildCount++;
        return const Text('Expensive Child');
      }

      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          builder: (context, state, child) {
            builderBuildCount++;
            return Container(
              width: 100,
              height: 50,
              color: state.states.contains(WidgetState.pressed)
                  ? Colors.blue
                  : Colors.grey,
              child: child, // Uses cached child
            );
          },
          child: buildExpensiveChild(),
        ),
      );

      final initialChildBuilds = childBuildCount;
      final initialBuilderBuilds = builderBuildCount;

      // Trigger multiple state changes
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NakedButton)),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Child should NOT rebuild
      expect(childBuildCount, equals(initialChildBuilds));
      // Builder SHOULD rebuild
      expect(builderBuildCount, greaterThan(initialBuilderBuilds));
    });

    testWidgets('builder receives correct states for all interactions', (
      WidgetTester tester,
    ) async {
      Set<WidgetState>? lastStates;

      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          builder: (context, state, child) {
            lastStates = state.states;
            return Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                color: state.states.contains(WidgetState.pressed)
                    ? Colors.blue
                    : state.states.contains(WidgetState.hovered)
                    ? Colors.lightBlue
                    : Colors.grey,
                border: state.states.contains(WidgetState.focused)
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
              ),
              child: child,
            );
          },
          child: const Text('State Test'),
        ),
      );

      // Test press state
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NakedButton)),
      );
      await tester.pumpAndSettle();
      expect(lastStates, contains(WidgetState.pressed));

      await gesture.up();
      await tester.pump();
      expect(lastStates, isNot(contains(WidgetState.pressed)));
    });

    testWidgets('builder can return different widgets based on states', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          builder: (context, state, child) {
            if (state.states.contains(WidgetState.pressed)) {
              return Container(
                width: 100,
                height: 50,
                color: Colors.red,
                child: const Text('Pressed!'),
              );
            }
            return Container(
              width: 100,
              height: 50,
              color: Colors.green,
              child: child,
            );
          },
          child: const Text('Normal'),
        ),
      );

      // Initially should show normal state
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Pressed!'), findsNothing);

      // Press and check state change
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NakedButton)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Normal'), findsNothing);
      expect(find.text('Pressed!'), findsOneWidget);

      await gesture.up();
      await tester.pump();

      // Should return to normal
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Pressed!'), findsNothing);
    });

    testWidgets('builder works correctly when disabled', (
      WidgetTester tester,
    ) async {
      Set<WidgetState>? lastStates;

      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          enabled: false,
          builder: (context, state, child) {
            lastStates = state.states;
            return Container(
              width: 100,
              height: 50,
              color: state.states.contains(WidgetState.disabled)
                  ? Colors.grey.shade300
                  : Colors.blue,
              child: child,
            );
          },
          child: const Text('Disabled Button'),
        ),
      );

      // Should show disabled state
      expect(lastStates, contains(WidgetState.disabled));

      // Try to interact - should not change state
      await tester.tap(find.byType(NakedButton));
      await tester.pump();

      // Should still be disabled
      expect(lastStates, contains(WidgetState.disabled));
      expect(lastStates, isNot(contains(WidgetState.pressed)));
    });

    testWidgets('builder demonstrates modern state.when() API', (
      WidgetTester tester,
    ) async {
      String currentColor = 'default';

      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          builder: (context, state, child) {
            // Modern way: Use state.when() for conditional styling
            final color = state.when(
              disabled: Colors.grey.shade300,
              pressed: Colors.red,
              hovered: Colors.lightBlue,
              focused: Colors.orange,
              orElse: Colors.blue,
            );
            currentColor = color.toString();

            return Container(
              width: 100,
              height: 50,
              color: color,
              child: child,
            );
          },
          child: const Text('Modern State API'),
        ),
      );

      // Check default state
      expect(currentColor, contains('blue'));

      // Test press state with modern API
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NakedButton)),
      );
      await tester.pumpAndSettle();

      // Should show pressed color
      expect(currentColor, contains('red'));

      await gesture.up();
      await tester.pump();

      // Should return to default
      expect(currentColor, contains('blue'));
    });

    testWidgets('builder demonstrates direct state accessors', (
      WidgetTester tester,
    ) async {
      bool? isHovered;
      bool? isPressed;
      bool? isFocused;
      bool? isDisabled;

      await tester.pumpMaterialWidget(
        NakedButton(
          onPressed: () {},
          autofocus: true,
          builder: (context, state, child) {
            // Modern way: Direct boolean accessors
            isHovered = state.isHovered;
            isPressed = state.isPressed;
            isFocused = state.isFocused;
            isDisabled = state.isDisabled;

            return Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue,
                border: state.isFocused
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
              ),
              child: child,
            );
          },
          child: const Text('Direct Accessors'),
        ),
      );

      await tester.pump(); // Allow autofocus to take effect

      // Check state accessors
      expect(isFocused, isTrue);
      expect(isHovered, isFalse);
      expect(isPressed, isFalse);
      expect(isDisabled, isFalse);

      // Test press state
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NakedButton)),
      );
      // Allow time for gesture recognition to complete
      await tester.pump(const Duration(milliseconds: 100));

      expect(isPressed, isTrue);
      expect(isFocused, isTrue); // Still focused

      await gesture.up();
      await tester.pump();

      expect(isPressed, isFalse);
    });
  });
}
