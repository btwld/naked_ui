import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/src/utilities/naked_state_scope.dart';
import '../../lib/src/utilities/state.dart';

class TestNakedState extends NakedState {
  TestNakedState({required Set<WidgetState> states}) : super(states: states);
}

void main() {
  group('NakedState', () {
    test('constructor creates state with given states', () {
      final states = {WidgetState.hovered, WidgetState.focused};
      final nakedState = TestNakedState(states: states);

      expect(nakedState.states, equals(states));
      expect(nakedState.isHovered, isTrue);
      expect(nakedState.isFocused, isTrue);
      expect(nakedState.isPressed, isFalse);
    });

    group('state getters', () {
      test('return correct state for each WidgetState', () {
        final nakedState = TestNakedState(
          states: {
            WidgetState.hovered,
            WidgetState.focused,
            WidgetState.pressed,
            WidgetState.dragged,
            WidgetState.selected,
            WidgetState.disabled,
            WidgetState.error,
            WidgetState.scrolledUnder,
          },
        );

        expect(nakedState.isHovered, isTrue);
        expect(nakedState.isFocused, isTrue);
        expect(nakedState.isPressed, isTrue);
        expect(nakedState.isDragged, isTrue);
        expect(nakedState.isSelected, isTrue);
        expect(nakedState.isDisabled, isTrue);
        expect(nakedState.isError, isTrue);
        expect(nakedState.isScrolledUnder, isTrue);
        expect(nakedState.isEnabled, isFalse);
      });

      test('isEnabled is true when disabled is false', () {
        final nakedState = TestNakedState(states: {WidgetState.hovered});
        expect(nakedState.isEnabled, isTrue);
        expect(nakedState.isDisabled, isFalse);
      });
    });

    group('matches', () {
      test('returns true when all states match', () {
        final nakedState = TestNakedState(
          states: {
            WidgetState.hovered,
            WidgetState.focused,
            WidgetState.pressed,
          },
        );

        expect(nakedState.matches({WidgetState.hovered}), isTrue);
        expect(
          nakedState.matches({WidgetState.hovered, WidgetState.focused}),
          isTrue,
        );
        expect(
          nakedState.matches({
            WidgetState.hovered,
            WidgetState.focused,
            WidgetState.pressed,
          }),
          isTrue,
        );
      });

      test('returns false when not all states match', () {
        final nakedState = TestNakedState(states: {WidgetState.hovered});

        expect(nakedState.matches({WidgetState.focused}), isFalse);
        expect(
          nakedState.matches({WidgetState.hovered, WidgetState.focused}),
          isFalse,
        );
      });
    });

    group('when', () {
      test('returns first matching state in priority order', () {
        final nakedState = TestNakedState(
          states: {
            WidgetState.hovered,
            WidgetState.focused,
            WidgetState.selected,
          },
        );

        // Selected has highest priority
        final result = nakedState.when(
          selected: 'selected',
          hovered: 'hovered',
          focused: 'focused',
          orElse: 'default',
        );

        expect(result, equals('selected'));
      });

      test('returns hovered when selected is not provided', () {
        final nakedState = TestNakedState(
          states: {WidgetState.hovered, WidgetState.focused},
        );

        final result = nakedState.when(
          hovered: 'hovered',
          focused: 'focused',
          orElse: 'default',
        );

        expect(result, equals('hovered'));
      });

      test('returns orElse when no states match', () {
        final nakedState = TestNakedState(states: {});

        final result = nakedState.when(
          hovered: 'hovered',
          focused: 'focused',
          orElse: 'default',
        );

        expect(result, equals('default'));
      });

      test('covers all state priorities', () {
        // Test each state individually
        final states = [
          WidgetState.selected,
          WidgetState.hovered,
          WidgetState.focused,
          WidgetState.pressed,
          WidgetState.disabled,
          WidgetState.dragged,
          WidgetState.error,
          WidgetState.scrolledUnder,
        ];

        for (int i = 0; i < states.length; i++) {
          final nakedState = TestNakedState(states: {states[i]});
          final result = nakedState.when(
            selected: 'selected',
            hovered: 'hovered',
            focused: 'focused',
            pressed: 'pressed',
            disabled: 'disabled',
            dragged: 'dragged',
            error: 'error',
            scrolledUnder: 'scrolledUnder',
            orElse: 'default',
          );

          final expected = [
            'selected',
            'hovered',
            'focused',
            'pressed',
            'disabled',
            'dragged',
            'error',
            'scrolledUnder',
          ][i];

          expect(result, equals(expected));
        }
      });
    });

    group('whenOrNull', () {
      test('returns first matching state value', () {
        final nakedState = TestNakedState(states: {WidgetState.hovered});

        final result = nakedState.whenOrNull(
          hovered: 'hovered',
          focused: 'focused',
        );

        expect(result, equals('hovered'));
      });

      test('returns null when no states match', () {
        final nakedState = TestNakedState(states: {});

        final result = nakedState.whenOrNull(
          hovered: 'hovered',
          focused: 'focused',
        );

        expect(result, isNull);
      });
    });

    group('static methods', () {
      testWidgets('of() returns state from context', (tester) async {
        final testState = TestNakedState(states: {WidgetState.hovered});

        await tester.pumpWidget(
          MaterialApp(
            home: NakedStateScope<TestNakedState>(
              value: testState,
              child: Builder(
                builder: (context) {
                  final state = NakedState.of<TestNakedState>(context);
                  expect(state, equals(testState));
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });

      testWidgets('of() throws when no state found', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                expect(
                  () => NakedState.of<TestNakedState>(context),
                  throwsA(isA<FlutterError>()),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('maybeOf() returns state from context', (tester) async {
        final testState = TestNakedState(states: {WidgetState.hovered});

        await tester.pumpWidget(
          MaterialApp(
            home: NakedStateScope<TestNakedState>(
              value: testState,
              child: Builder(
                builder: (context) {
                  final state = NakedState.maybeOf<TestNakedState>(context);
                  expect(state, equals(testState));
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });

      testWidgets('maybeOf() returns null when no state found', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final state = NakedState.maybeOf<TestNakedState>(context);
                expect(state, isNull);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('controllerOf() returns controller from context', (
        tester,
      ) async {
        final testState = TestNakedState(states: {WidgetState.hovered});

        await tester.pumpWidget(
          MaterialApp(
            home: NakedStateScope<TestNakedState>(
              value: testState,
              child: Builder(
                builder: (context) {
                  final result = NakedState.controllerOf(context);
                  expect(result, isA<WidgetStatesController>());
                  expect(result.value, equals(testState.states));
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });

      testWidgets('maybeControllerOf() returns controller from context', (
        tester,
      ) async {
        final testState = TestNakedState(states: {WidgetState.hovered});

        await tester.pumpWidget(
          MaterialApp(
            home: NakedStateScope<TestNakedState>(
              value: testState,
              child: Builder(
                builder: (context) {
                  final result = NakedState.maybeControllerOf(context);
                  expect(result, isA<WidgetStatesController>());
                  expect(result!.value, equals(testState.states));
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      });

      testWidgets('maybeControllerOf() returns null when no controller found', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final result = NakedState.maybeControllerOf(context);
                expect(result, isNull);
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });
  });
}
