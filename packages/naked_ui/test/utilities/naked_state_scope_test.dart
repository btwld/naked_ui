import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/src/utilities/naked_state_scope.dart';
import 'package:naked_ui/src/utilities/state.dart';

// Test state class
class TestNakedState extends NakedState {
  final String label;

  TestNakedState({required Set<WidgetState> states, required this.label})
    : super(states: states);
}

class OtherNakedState extends NakedState {
  OtherNakedState({required super.states});
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
              capturedController = NakedState.controllerOf<TestNakedState>(
                context,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedController, isNotNull);
      expect(capturedController!.value, contains(WidgetState.focused));
      expect(capturedController!.value, contains(WidgetState.hovered));
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
                      capturedController =
                          NakedState.controllerOf<TestNakedState>(context);
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
                          capturedController =
                              NakedState.controllerOf<TestNakedState>(context);
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
            capturedController = NakedState.maybeControllerOf<TestNakedState>(
              context,
            );
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
        () => NakedState.controllerOf<TestNakedState>(
          tester.element(find.byType(SizedBox)),
        ),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets('typed lookup skips unrelated nested scopes', (tester) async {
      WidgetStatesController? outerController;
      WidgetStatesController? resolvedController;

      await tester.pumpWidget(
        NakedStateScope<TestNakedState>(
          value: TestNakedState(states: {WidgetState.focused}, label: 'outer'),
          child: Builder(
            builder: (outerContext) {
              outerController = NakedState.controllerOf<TestNakedState>(
                outerContext,
              );
              return NakedStateScope<OtherNakedState>(
                value: OtherNakedState(states: {WidgetState.hovered}),
                child: Builder(
                  builder: (innerContext) {
                    resolvedController =
                        NakedState.controllerOf<TestNakedState>(innerContext);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(resolvedController, same(outerController));
      expect(resolvedController!.value, {WidgetState.focused});
    });
  });
}
