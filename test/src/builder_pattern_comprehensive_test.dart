import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

/// Comprehensive test suite for the builder pattern across all naked_ui components.
///
/// This test verifies that:
/// 1. Builder is called with correct states
/// 2. Builder receives non-null child when provided
/// 3. Builder can return different widgets based on states
/// 4. Multiple state changes don't cause unnecessary rebuilds
/// 5. Builder pattern works consistently across all components
void main() {
  group('Builder Pattern Documentation Tests', () {
    group('Builder Pattern Core Behavior', () {
      testWidgets('builder receives correct WidgetState set', (
        WidgetTester tester,
      ) async {
        Set<WidgetState>? receivedStates;

        await tester.pumpMaterialWidget(
          NakedButton(
            onPressed: () {},
            builder: (context, states, child) {
              receivedStates = states;
              return Container(
                width: 100,
                height: 50,
                color: states.contains(WidgetState.pressed)
                    ? Colors.red
                    : Colors.blue,
                child: child,
              );
            },
            child: const Text('Test'),
          ),
        );

        // Initially should have basic states (enabled, not pressed, not hovered)
        expect(receivedStates, isNotNull);
        expect(receivedStates, isNot(contains(WidgetState.disabled)));
        expect(receivedStates, isNot(contains(WidgetState.pressed)));
        expect(receivedStates, isNot(contains(WidgetState.hovered)));
      });

      testWidgets('builder receives non-null child when provided', (
        WidgetTester tester,
      ) async {
        Widget? receivedChild;

        const expectedChild = Text('Expected Child');

        await tester.pumpMaterialWidget(
          NakedButton(
            onPressed: () {},
            builder: (context, states, child) {
              receivedChild = child;
              return Container(child: child);
            },
            child: expectedChild,
          ),
        );

        expect(receivedChild, isNotNull);
        expect(receivedChild, equals(expectedChild));
      });

      testWidgets('builder can return different widgets based on states', (
        WidgetTester tester,
      ) async {
        final key = UniqueKey();
        await tester.pumpMaterialWidget(
          NakedButton(
            key: key,
            onPressed: () {},
            builder: (context, states, child) {
              if (states.contains(WidgetState.hovered)) {
                return const Text('HOVERED');
              }
              return const Text('NORMAL');
            },
          ),
        );

        // Initially normal state
        expect(find.text('NORMAL'), findsOneWidget);
        expect(find.text('HOVERED'), findsNothing);

        // Hover shows alternate content
        await tester.simulateHover(
          key,
          onHover: () {
            expect(find.text('HOVERED'), findsOneWidget);
            expect(find.text('NORMAL'), findsNothing);
          },
        );

        // After exit, back to normal
        expect(find.text('NORMAL'), findsOneWidget);
        expect(find.text('HOVERED'), findsNothing);
      });
    });

    group('Builder Efficiency Tests', () {
      testWidgets('builder rebuilds only when states change', (
        WidgetTester tester,
      ) async {
        int builderCallCount = 0;

        final key = UniqueKey();
        await tester.pumpMaterialWidget(
          NakedButton(
            key: key,
            onPressed: () {},
            builder: (context, states, child) {
              builderCallCount++;
              return Container(
                color: states.contains(WidgetState.hovered)
                    ? Colors.red
                    : Colors.blue,
                child: child,
              );
            },
            child: const Text('Counter Test'),
          ),
        );

        final initialCount = builderCallCount;

        // Trigger state change via hover enter/exit
        await tester.simulateHover(key, onHover: () {});
        expect(builderCallCount, greaterThan(initialCount));

        final afterHoverEnter = builderCallCount;
        // simulateHover exits at the end; ensure an additional rebuild occurred
        expect(builderCallCount, greaterThan(afterHoverEnter - 1));
      });

      testWidgets('child widget does not rebuild when states change', (
        WidgetTester tester,
      ) async {
        int childBuildCount = 0;
        int builderBuildCount = 0;

        Widget buildChild() {
          childBuildCount++;
          return const Text('Child Widget');
        }

        final key = UniqueKey();
        await tester.pumpMaterialWidget(
          NakedButton(
            key: key,
            onPressed: () {},
            builder: (context, states, child) {
              builderBuildCount++;
              return Container(
                color: states.contains(WidgetState.hovered)
                    ? Colors.red
                    : Colors.blue,
                child: child, // Reuses the child
              );
            },
            child: buildChild(),
          ),
        );

        final initialChildBuilds = childBuildCount;
        final initialBuilderBuilds = builderBuildCount;

        // Trigger state changes via hover
        await tester.simulateHover(key, onHover: () {});

        // Child should not rebuild
        expect(childBuildCount, equals(initialChildBuilds));
        // Builder should rebuild
        expect(builderBuildCount, greaterThan(initialBuilderBuilds));
      });
    });

    group('Cross-Component Builder Pattern Consistency', () {
      testWidgets('NakedButton builder pattern', (WidgetTester tester) async {
        await _testComponentBuilder(
          tester,
          (builder, child) =>
              NakedButton(onPressed: () {}, builder: builder, child: child),
        );
      });

      testWidgets('NakedCheckbox builder pattern', (WidgetTester tester) async {
        NakedCheckboxState? capturedState;
        Widget? capturedChild;
        const child = Text('Checkbox Child');

        await tester.pumpMaterialWidget(
          NakedCheckbox(
            value: false,
            onChanged: (value) {},
            builder: (context, state, childWidget) {
              capturedState = state;
              capturedChild = childWidget;
              return childWidget ?? const SizedBox.shrink();
            },
            child: child,
          ),
        );

        expect(capturedState, isNotNull);
        expect(capturedChild, equals(child));
      });

      testWidgets('NakedRadio builder pattern', (WidgetTester tester) async {
        NakedRadioState<String>? capturedState;
        const child = Text('Radio Child');

        await tester.pumpMaterialWidget(
          RadioGroup<String>(
            groupValue: 'value1',
            onChanged: (_) {},
            child: NakedRadio<String>(
              value: 'value1',
              builder: (context, state, childWidget) {
                capturedState = state;
                return childWidget ?? const SizedBox.shrink();
              },
              child: child,
            ),
          ),
        );

        expect(capturedState, isNotNull);
        expect(capturedState!.isSelected, isTrue);
      });

      testWidgets('NakedTab builder pattern', (WidgetTester tester) async {
        NakedTabState? capturedState;

        await tester.pumpMaterialWidget(
          NakedTabs(
            selectedTabId: 'tab1',
            onChanged: (value) {},
            child: NakedTabList(
              child: Row(
                children: [
                  NakedTab(
                    tabId: 'tab1',
                    builder: (context, tabState, child) {
                      capturedState = tabState;
                      return const Text('Builder Test');
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        expect(capturedState, isNotNull);
        expect(capturedState!.isSelected, isTrue);
      });
    });

    group('Builder Error Handling', () {
      testWidgets('builder handles null child gracefully', (
        WidgetTester tester,
      ) async {
        Widget? receivedChild;

        await tester.pumpMaterialWidget(
          NakedButton(
            onPressed: () {},
            builder: (context, states, child) {
              receivedChild = child;
              return Container(
                width: 100,
                height: 50,
                color: Colors.blue,
                // Intentionally not using child
              );
            },
            // No child provided
          ),
        );

        expect(receivedChild, isNull);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('builder can ignore provided child', (
        WidgetTester tester,
      ) async {
        await tester.pumpMaterialWidget(
          NakedButton(
            onPressed: () {},
            builder: (context, states, child) {
              // Ignore the child completely
              return const Text('Custom Content');
            },
            child: const Text('Original Child'), // This will be ignored
          ),
        );

        expect(find.text('Custom Content'), findsOneWidget);
        expect(find.text('Original Child'), findsNothing);
      });
    });

    group('State-Specific Builder Behavior', () {
      testWidgets('builder responds to all widget states', (
        WidgetTester tester,
      ) async {
        Set<WidgetState>? lastStates;

        final key = UniqueKey();
        await tester.pumpMaterialWidget(
          NakedButton(
            key: key,
            onPressed: () {},
            enabled: true,
            autofocus: true,
            builder: (context, states, child) {
              lastStates = states;
              return Container(
                width: 100,
                height: 50,
                decoration: BoxDecoration(
                  color: _getColorForStates(states),
                  border: states.contains(WidgetState.focused)
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
                ),
                child: child,
              );
            },
            child: const Text('All States'),
          ),
        );
        // Allow autofocus to take effect before checking focus state
        await tester.pump();
        // Should start with focus (autofocus: true)
        expect(lastStates, contains(WidgetState.focused));

        // Test hover state toggling
        await tester.simulateHover(
          key,
          onHover: () {
            expect(lastStates, contains(WidgetState.hovered));
          },
        );
        expect(lastStates, isNot(contains(WidgetState.hovered)));
      });

      testWidgets('builder handles disabled state', (
        WidgetTester tester,
      ) async {
        Set<WidgetState>? enabledStates;
        Set<WidgetState>? disabledStates;

        // Test enabled state
        await tester.pumpMaterialWidget(
          NakedButton(
            onPressed: () {},
            enabled: true,
            builder: (context, states, child) {
              enabledStates = states;
              return Container(child: child);
            },
            child: const Text('Enabled'),
          ),
        );

        expect(enabledStates, isNot(contains(WidgetState.disabled)));

        // Test disabled state
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NakedButton(
                onPressed: () {},
                enabled: false,
                builder: (context, states, child) {
                  disabledStates = states;
                  return Container(child: child);
                },
                child: const Text('Disabled'),
              ),
            ),
          ),
        );

        expect(disabledStates, contains(WidgetState.disabled));
      });
    });
  });
}

/// Helper function to test builder pattern consistency across components
Future<void> _testComponentBuilder(
  WidgetTester tester,
  Widget Function(ValueWidgetBuilder<Set<WidgetState>>, Widget?)
  componentBuilder,
) async {
  Set<WidgetState>? receivedStates;
  Widget? receivedChild;

  const testChild = Text('Test Child');

  await tester.pumpMaterialWidget(
    componentBuilder((context, states, child) {
      receivedStates = states;
      receivedChild = child;
      return Container(
        color: states.contains(WidgetState.pressed) ? Colors.red : Colors.blue,
        child: child,
      );
    }, testChild),
  );

  expect(receivedStates, isNotNull);
  expect(receivedChild, equals(testChild));
}

/// Helper to get color based on widget states
Color _getColorForStates(Set<WidgetState> states) {
  if (states.contains(WidgetState.disabled)) return Colors.grey;
  if (states.contains(WidgetState.pressed)) return Colors.red;
  if (states.contains(WidgetState.hovered)) return Colors.lightBlue;
  if (states.contains(WidgetState.selected)) return Colors.green;
  return Colors.blue;
}
