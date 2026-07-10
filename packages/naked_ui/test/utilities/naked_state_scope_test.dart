import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/src/naked_button.dart';
import 'package:naked_ui/src/utilities/naked_state_scope.dart';
import 'package:naked_ui/src/utilities/state.dart';

// Test state class
class TestNakedState extends NakedState {
  final String label;

  TestNakedState({required super.states, required this.label});
}

class OtherNakedState extends NakedState {
  OtherNakedState({required super.states});
}

class GenericNakedState<T> extends NakedState {
  GenericNakedState({required super.states, required this.value});

  final T value;
}

void main() {
  group('NakedStateScope', () {
    testWidgets('provides controller to descendants', (tester) async {
      WidgetStatesController? capturedController;
      final testState = TestNakedState(
        states: {WidgetState.focused, WidgetState.hovered},
        label: 'test',
      );

      await tester.pumpWidget(
        NakedStateScope<TestNakedState>(
          value: testState,
          child: Builder(
            builder: (context) {
              capturedController = NakedState.controllerOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedController, isNotNull);
      expect(capturedController!.value, contains(WidgetState.focused));
      expect(capturedController!.value, contains(WidgetState.hovered));
    });

    testWidgets('typed lookup skips unrelated nested scopes', (tester) async {
      WidgetStatesController? outerController;
      WidgetStatesController? innerController;
      WidgetStatesController? genericController;

      await tester.pumpWidget(
        NakedStateScope<TestNakedState>(
          value: TestNakedState(states: {WidgetState.focused}, label: 'outer'),
          child: NakedStateScope<GenericNakedState<String>>(
            value: GenericNakedState<String>(
              states: {WidgetState.selected},
              value: 'generic',
            ),
            child: NakedStateScope<OtherNakedState>(
              value: OtherNakedState(states: {WidgetState.pressed}),
              child: Builder(
                builder: (context) {
                  outerController = NakedState.controllerOfType<TestNakedState>(
                    context,
                  );
                  innerController =
                      NakedState.controllerOfType<OtherNakedState>(context);
                  genericController =
                      NakedState.controllerOfType<GenericNakedState<dynamic>>(
                        context,
                      );
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(outerController!.value, {WidgetState.focused});
      expect(innerController!.value, {WidgetState.pressed});
      expect(genericController!.value, {WidgetState.selected});
      expect(outerController, isNot(same(innerController)));
    });

    testWidgets('component lookup skips unrelated nested scopes', (
      tester,
    ) async {
      WidgetStatesController? buttonController;

      await tester.pumpWidget(
        NakedStateScope<NakedButtonState>(
          value: NakedButtonState(states: {WidgetState.focused}),
          child: NakedStateScope<OtherNakedState>(
            value: OtherNakedState(states: {WidgetState.pressed}),
            child: Builder(
              builder: (context) {
                buttonController = NakedButtonState.controllerOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(buttonController!.value, {WidgetState.focused});
    });

    testWidgets('updates controller when states change', (tester) async {
      WidgetStatesController? capturedController;
      var testState = TestNakedState(
        states: {WidgetState.focused},
        label: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: NakedStateScope<TestNakedState>(
                  value: testState,
                  child: Builder(
                    builder: (context) {
                      // Get fresh controller reference each build
                      capturedController = NakedState.controllerOf(context);
                      return Center(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              testState = TestNakedState(
                                states: {
                                  WidgetState.focused,
                                  WidgetState.pressed,
                                },
                                label: 'test',
                              );
                            });
                          },
                          child: const Text('Update'),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Initial state
      expect(capturedController!.value, equals({WidgetState.focused}));

      // Tap to update states
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Controller should be updated (the same controller instance is updated)
      expect(
        capturedController!.value,
        equals({WidgetState.focused, WidgetState.pressed}),
      );
    });

    testWidgets('controllerOf does not create dependency', (tester) async {
      var buildCount = 0;
      WidgetStatesController? capturedController;
      final testState = TestNakedState(
        states: {WidgetState.focused},
        label: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: NakedStateScope<TestNakedState>(
            value: testState,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      Builder(
                        builder: (context) {
                          buildCount++;
                          capturedController = NakedState.controllerOf(context);
                          return Text('Build count: $buildCount');
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          // Manually update the controller value
                          capturedController!.value = {WidgetState.pressed};
                        },
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(buildCount, equals(1));

      // Update controller value directly
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      // Build count should not increase since controllerOf doesn't create dependency
      expect(buildCount, equals(1));
      expect(capturedController!.value, equals({WidgetState.pressed}));
    });

    testWidgets('maybeControllerOf returns null when no scope', (tester) async {
      WidgetStatesController? capturedController;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedController = NakedState.maybeControllerOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(capturedController, isNull);
    });

    testWidgets('controllerOf throws when no scope', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            return const SizedBox();
          },
        ),
      );

      expect(
        () => NakedState.controllerOf(tester.element(find.byType(SizedBox))),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}
