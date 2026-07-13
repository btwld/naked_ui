import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';
import 'helpers/builder_state_scope.dart';

void main() {
  group('NakedToggle', () {
    testWidgets('renders child and reflects initial value', (tester) async {
      await tester.pumpMaterialWidget(
        NakedToggle(
          value: false,
          onChanged: (_) {},
          child: const Text('Toggle'),
        ),
      );
      expect(find.text('Toggle'), findsOneWidget);
    });

    testWidgets('toggles on tap', (tester) async {
      bool value = false;
      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) => NakedToggle(
            value: value,
            onChanged: (v) => setState(() => value = v),
            child: const Text('Toggle'),
          ),
        ),
      );

      await tester.tap(find.text('Toggle'));
      await tester.pump();
      expect(value, isTrue);
    });

    testWidgets('closes via keyboard activation (Space)', (tester) async {
      bool value = false;
      final focusNode = FocusNode();
      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) => NakedToggle(
            value: value,
            onChanged: (v) => setState(() => value = v),
            focusNode: focusNode,
            child: const Text('Toggle'),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(value, isTrue);
    });

    testWidgets('disabled does not toggle', (tester) async {
      bool value = false;
      await tester.pumpMaterialWidget(
        NakedToggle(value: value, onChanged: null, child: const Text('Toggle')),
      );

      await tester.tap(find.text('Toggle'));
      await tester.pump();
      expect(value, isFalse);
    });
  });

  group('NakedToggleGroup', () {
    testWidgets('selects one option at a time', (tester) async {
      String? selected = 'a';

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedToggleGroup<String>(
              selectedValue: selected,
              onChanged: (v) => setState(() => selected = v),
              child: Row(
                children: [
                  NakedToggleOption<String>(
                    value: 'a',
                    builder: (context, optionState, child) =>
                        Text(optionState.isSelected ? 'A*' : 'A'),
                  ),
                  NakedToggleOption<String>(
                    value: 'b',
                    builder: (context, optionState, child) =>
                        Text(optionState.isSelected ? 'B*' : 'B'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('A*'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      await tester.tap(find.text('B'));
      await tester.pump();

      expect(selected, 'b');
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B*'), findsOneWidget);
    });

    testWidgets('options invoke the latest group callback', (tester) async {
      var useSecondCallback = false;
      var firstCalls = 0;
      var secondCalls = 0;
      late StateSetter rebuild;

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return NakedToggleGroup<String>(
              selectedValue: 'a',
              onChanged: useSecondCallback
                  ? (_) => secondCalls++
                  : (_) => firstCalls++,
              child: const Row(
                children: [
                  NakedToggleOption<String>(value: 'a', child: Text('A')),
                  NakedToggleOption<String>(value: 'b', child: Text('B')),
                ],
              ),
            );
          },
        ),
      );

      rebuild(() => useSecondCallback = true);
      await tester.pump();
      await tester.tap(find.text('B'));
      await tester.pump();

      expect(firstCalls, 0);
      expect(secondCalls, 1);
    });

    testWidgets('disabled group prevents interaction', (tester) async {
      String? selected = 'a';

      await tester.pumpMaterialWidget(
        NakedToggleGroup<String>(
          selectedValue: selected,
          onChanged: null,
          child: Row(
            children: const [
              NakedToggleOption<String>(value: 'a', child: Text('A')),
              NakedToggleOption<String>(value: 'b', child: Text('B')),
            ],
          ),
        ),
      );

      await tester.tap(find.text('B'));
      await tester.pump();
      expect(selected, 'a');
    });

    testWidgets('null callback removes the group from traversal', (
      tester,
    ) async {
      final before = FocusNode(debugLabel: 'before');
      final optionA = FocusNode(debugLabel: 'option A');
      final optionB = FocusNode(debugLabel: 'option B');
      final after = FocusNode(debugLabel: 'after');
      for (final node in [before, optionA, optionB, after]) {
        addTearDown(node.dispose);
      }

      await tester.pumpMaterialWidget(
        Column(
          children: [
            Focus(focusNode: before, child: const Text('Before')),
            NakedToggleGroup<String>(
              selectedValue: 'a',
              onChanged: null,
              child: Row(
                children: [
                  NakedToggleOption<String>(
                    value: 'a',
                    focusNode: optionA,
                    child: const Text('A'),
                  ),
                  NakedToggleOption<String>(
                    value: 'b',
                    focusNode: optionB,
                    child: const Text('B'),
                  ),
                ],
              ),
            ),
            Focus(focusNode: after, child: const Text('After')),
          ],
        ),
      );

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(after.hasPrimaryFocus, isTrue);
      expect(optionA.canRequestFocus, isFalse);
      expect(optionB.canRequestFocus, isFalse);
    });

    for (final disableWithEnabled in [true, false]) {
      final mechanism = disableWithEnabled ? 'enabled' : 'onChanged';
      testWidgets(
        'runtime $mechanism disable removes the stop without stealing focus',
        (tester) async {
          final before = FocusNode(debugLabel: 'before');
          final optionA = FocusNode(debugLabel: 'option A');
          final optionB = FocusNode(debugLabel: 'option B');
          final after = FocusNode(debugLabel: 'after');
          for (final node in [before, optionA, optionB, after]) {
            addTearDown(node.dispose);
          }
          var active = true;
          final proposedValues = <String?>[];
          late StateSetter rebuild;

          await tester.pumpMaterialWidget(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Column(
                  children: [
                    Focus(focusNode: before, child: const Text('Before')),
                    NakedToggleGroup<String>(
                      selectedValue: 'a',
                      enabled: disableWithEnabled ? active : true,
                      onChanged: disableWithEnabled || active
                          ? proposedValues.add
                          : null,
                      child: Row(
                        children: [
                          NakedToggleOption<String>(
                            value: 'a',
                            focusNode: optionA,
                            child: const Text('A'),
                          ),
                          NakedToggleOption<String>(
                            value: 'b',
                            focusNode: optionB,
                            child: const Text('B'),
                          ),
                        ],
                      ),
                    ),
                    Focus(focusNode: after, child: const Text('After')),
                  ],
                );
              },
            ),
          );

          optionB.requestFocus();
          await tester.pump();
          expect(optionB.hasPrimaryFocus, isTrue);

          rebuild(() => active = false);
          await tester.pump();
          expect(optionA.canRequestFocus, isFalse);
          expect(optionB.canRequestFocus, isFalse);
          expect(optionA.skipTraversal, isTrue);
          expect(optionB.skipTraversal, isTrue);
          expect(before.hasFocus, isFalse);
          expect(after.hasFocus, isFalse);

          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pump();
          expect(proposedValues, isEmpty);
          expect(before.hasFocus, isFalse);
          expect(after.hasFocus, isFalse);

          rebuild(() => active = true);
          await tester.pump();
          expect(optionA.skipTraversal, isFalse);
          expect(optionB.skipTraversal, isTrue);

          after.requestFocus();
          await tester.pump();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.pump();
          expect(optionA.hasPrimaryFocus, isTrue);
        },
      );
    }

    testWidgets('tapping already selected option is a no-op', (tester) async {
      String? selected = 'a';
      var calls = 0;

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedToggleGroup<String>(
              selectedValue: selected,
              onChanged: (v) {
                calls++;
                setState(() => selected = v);
              },
              child: Row(
                children: const [
                  NakedToggleOption<String>(value: 'a', child: Text('A')),
                  NakedToggleOption<String>(value: 'b', child: Text('B')),
                ],
              ),
            );
          },
        ),
      );

      expect(selected, 'a');
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(
        calls,
        0,
        reason: 'onChanged should not fire when selecting the same value',
      );
      expect(selected, 'a');
    });

    testWidgets('disabled option cannot be selected (group enabled)', (
      tester,
    ) async {
      String? selected = 'a';

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedToggleGroup<String>(
              selectedValue: selected,
              onChanged: (v) => setState(() => selected = v),
              child: Row(
                children: const [
                  NakedToggleOption<String>(value: 'a', child: Text('A')),
                  NakedToggleOption<String>(
                    value: 'b',
                    child: Text('B'),
                    enabled: false,
                  ),
                ],
              ),
            );
          },
        ),
      );

      await tester.tap(find.text('B'));
      await tester.pump();
      expect(selected, 'a');
    });

    testWidgets('keyboard activation selects focused option', (tester) async {
      String? selected = 'a';
      final bFocus = FocusNode();

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedToggleGroup<String>(
              selectedValue: selected,
              onChanged: (v) => setState(() => selected = v),
              child: Row(
                children: [
                  const NakedToggleOption<String>(value: 'a', child: Text('A')),
                  NakedToggleOption<String>(
                    value: 'b',
                    focusNode: bFocus,
                    child: const Text('B'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      bFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selected, 'b');
    });

    testWidgets('Enter, Space, and pointer each emit exactly one proposal', (
      tester,
    ) async {
      final bFocus = FocusNode(debugLabel: 'option B');
      addTearDown(bFocus.dispose);
      final proposedValues = <String?>[];

      await tester.pumpMaterialWidget(
        NakedToggleGroup<String>(
          selectedValue: 'a',
          onChanged: proposedValues.add,
          child: Row(
            children: [
              const NakedToggleOption<String>(
                value: 'a',
                enableFeedback: false,
                child: Text('A'),
              ),
              NakedToggleOption<String>(
                value: 'b',
                enableFeedback: false,
                focusNode: bFocus,
                child: const Text('B'),
              ),
            ],
          ),
        ),
      );

      bFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(proposedValues, ['b']);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(proposedValues, ['b', 'b']);

      await tester.tap(find.text('B'));
      await tester.pump();
      expect(proposedValues, ['b', 'b', 'b']);
    });

    testWidgets('contributes one Tab stop and Tab exits the group', (
      tester,
    ) async {
      final before = FocusNode(debugLabel: 'before');
      final optionA = FocusNode(debugLabel: 'option A');
      final optionB = FocusNode(debugLabel: 'option B');
      final after = FocusNode(debugLabel: 'after');
      addTearDown(before.dispose);
      addTearDown(optionA.dispose);
      addTearDown(optionB.dispose);
      addTearDown(after.dispose);

      await tester.pumpMaterialWidget(
        Column(
          children: [
            Focus(focusNode: before, child: const Text('Before')),
            NakedToggleGroup<String>(
              selectedValue: 'a',
              onChanged: (_) {},
              child: Row(
                children: [
                  NakedToggleOption<String>(
                    value: 'a',
                    focusNode: optionA,
                    child: const Text('A'),
                  ),
                  NakedToggleOption<String>(
                    value: 'b',
                    focusNode: optionB,
                    child: const Text('B'),
                  ),
                ],
              ),
            ),
            Focus(focusNode: after, child: const Text('After')),
          ],
        ),
      );

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(optionA.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);
      expect(optionB.hasFocus, isFalse);
    });

    testWidgets('enters on the selected enabled option', (tester) async {
      final before = FocusNode(debugLabel: 'before');
      final optionA = FocusNode(debugLabel: 'option A');
      final optionB = FocusNode(debugLabel: 'option B');
      addTearDown(before.dispose);
      addTearDown(optionA.dispose);
      addTearDown(optionB.dispose);

      await tester.pumpMaterialWidget(
        Column(
          children: [
            Focus(focusNode: before, child: const Text('Before')),
            NakedToggleGroup<String>(
              selectedValue: 'b',
              onChanged: (_) {},
              child: Row(
                children: [
                  NakedToggleOption<String>(
                    value: 'a',
                    focusNode: optionA,
                    child: const Text('A'),
                  ),
                  NakedToggleOption<String>(
                    value: 'b',
                    focusNode: optionB,
                    child: const Text('B'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(optionB.hasPrimaryFocus, isTrue);
      expect(optionA.hasFocus, isFalse);
    });

    testWidgets('arrows move focus only and last focus wins on re-entry', (
      tester,
    ) async {
      final before = FocusNode(debugLabel: 'before');
      final optionA = FocusNode(debugLabel: 'option A');
      final optionB = FocusNode(debugLabel: 'option B');
      final optionC = FocusNode(debugLabel: 'option C');
      final after = FocusNode(debugLabel: 'after');
      for (final node in [before, optionA, optionB, optionC, after]) {
        addTearDown(node.dispose);
      }
      String? selected = 'a';
      final proposedValues = <String?>[];
      late StateSetter rebuild;

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Column(
              children: [
                Focus(focusNode: before, child: const Text('Before')),
                NakedToggleGroup<String>(
                  selectedValue: selected,
                  onChanged: proposedValues.add,
                  child: Row(
                    children: [
                      NakedToggleOption<String>(
                        value: 'a',
                        focusNode: optionA,
                        child: const Text('A'),
                      ),
                      NakedToggleOption<String>(
                        value: 'b',
                        focusNode: optionB,
                        child: const Text('B'),
                      ),
                      NakedToggleOption<String>(
                        value: 'c',
                        focusNode: optionC,
                        child: const Text('C'),
                      ),
                    ],
                  ),
                ),
                Focus(focusNode: after, child: const Text('After')),
              ],
            );
          },
        ),
      );

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(optionA.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(optionB.hasPrimaryFocus, isTrue);
      expect(selected, 'a');
      expect(proposedValues, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(proposedValues, ['b']);
      expect(selected, 'a', reason: 'selection remains controlled by the host');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);

      rebuild(() => selected = 'c');
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(optionB.hasPrimaryFocus, isTrue);
    });

    testWidgets('skips disabled options and honors Home, End, and loop', (
      tester,
    ) async {
      final optionA = FocusNode(debugLabel: 'option A');
      final optionB = FocusNode(debugLabel: 'option B');
      final optionC = FocusNode(debugLabel: 'option C');
      for (final node in [optionA, optionB, optionC]) {
        addTearDown(node.dispose);
      }
      var loop = true;
      final proposedValues = <String?>[];
      late StateSetter rebuild;

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return NakedToggleGroup<String>(
              selectedValue: 'a',
              onChanged: proposedValues.add,
              loop: loop,
              child: Row(
                children: [
                  NakedToggleOption<String>(
                    value: 'a',
                    focusNode: optionA,
                    child: const Text('A'),
                  ),
                  NakedToggleOption<String>(
                    value: 'b',
                    enabled: false,
                    focusNode: optionB,
                    child: const Text('B'),
                  ),
                  NakedToggleOption<String>(
                    value: 'c',
                    focusNode: optionC,
                    child: const Text('C'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      optionA.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(optionC.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(optionA.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(optionC.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(optionA.hasPrimaryFocus, isTrue);

      rebuild(() => loop = false);
      await tester.pump();
      optionC.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(optionC.hasPrimaryFocus, isTrue);
      expect(optionB.hasFocus, isFalse);
      expect(proposedValues, isEmpty);
    });

    testWidgets('vertical groups claim only Up and Down', (tester) async {
      final optionA = FocusNode(debugLabel: 'option A');
      final optionB = FocusNode(debugLabel: 'option B');
      final optionC = FocusNode(debugLabel: 'option C');
      for (final node in [optionA, optionB, optionC]) {
        addTearDown(node.dispose);
      }
      var orthogonalCalls = 0;

      await tester.pumpMaterialWidget(
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowRight): () {
              orthogonalCalls++;
            },
          },
          child: NakedToggleGroup<String>(
            selectedValue: 'a',
            onChanged: (_) {},
            orientation: Axis.vertical,
            child: Column(
              children: [
                NakedToggleOption<String>(
                  value: 'a',
                  focusNode: optionA,
                  child: const Text('A'),
                ),
                NakedToggleOption<String>(
                  value: 'b',
                  enabled: false,
                  focusNode: optionB,
                  child: const Text('B'),
                ),
                NakedToggleOption<String>(
                  value: 'c',
                  focusNode: optionC,
                  child: const Text('C'),
                ),
              ],
            ),
          ),
        ),
      );

      optionA.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(orthogonalCalls, 1);
      expect(optionA.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(optionC.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(optionA.hasPrimaryFocus, isTrue);
    });

    testWidgets('horizontal arrows follow visual direction in RTL', (
      tester,
    ) async {
      final optionA = FocusNode(debugLabel: 'option A');
      final optionB = FocusNode(debugLabel: 'option B');
      final optionC = FocusNode(debugLabel: 'option C');
      for (final node in [optionA, optionB, optionC]) {
        addTearDown(node.dispose);
      }

      await tester.pumpMaterialWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: NakedToggleGroup<String>(
            selectedValue: 'b',
            onChanged: (_) {},
            child: Row(
              children: [
                NakedToggleOption<String>(
                  value: 'a',
                  focusNode: optionA,
                  child: const Text('A'),
                ),
                NakedToggleOption<String>(
                  value: 'b',
                  focusNode: optionB,
                  child: const Text('B'),
                ),
                NakedToggleOption<String>(
                  value: 'c',
                  focusNode: optionC,
                  child: const Text('C'),
                ),
              ],
            ),
          ),
        ),
      );

      optionB.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(optionA.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(optionB.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(optionC.hasPrimaryFocus, isTrue);
    });

    testWidgets(
      'falls back to first enabled and disappears when all disabled',
      (tester) async {
        final before = FocusNode(debugLabel: 'before');
        final optionA = FocusNode(debugLabel: 'option A');
        final optionB = FocusNode(debugLabel: 'option B');
        final optionC = FocusNode(debugLabel: 'option C');
        final after = FocusNode(debugLabel: 'after');
        for (final node in [before, optionA, optionB, optionC, after]) {
          addTearDown(node.dispose);
        }
        var allDisabled = false;
        late StateSetter rebuild;

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Column(
                children: [
                  Focus(focusNode: before, child: const Text('Before')),
                  NakedToggleGroup<String>(
                    selectedValue: 'b',
                    onChanged: (_) {},
                    child: Row(
                      children: [
                        NakedToggleOption<String>(
                          value: 'a',
                          enabled: !allDisabled,
                          focusNode: optionA,
                          child: const Text('A'),
                        ),
                        NakedToggleOption<String>(
                          value: 'b',
                          enabled: false,
                          focusNode: optionB,
                          child: const Text('B'),
                        ),
                        NakedToggleOption<String>(
                          value: 'c',
                          enabled: false,
                          focusNode: optionC,
                          child: const Text('C'),
                        ),
                      ],
                    ),
                  ),
                  Focus(focusNode: after, child: const Text('After')),
                ],
              );
            },
          ),
        );

        before.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(optionA.hasPrimaryFocus, isTrue);

        after.requestFocus();
        await tester.pump();
        rebuild(() => allDisabled = true);
        await tester.pump();
        before.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(after.hasPrimaryFocus, isTrue);
        expect(optionA.canRequestFocus, isFalse);
        expect(optionB.canRequestFocus, isFalse);
        expect(optionC.canRequestFocus, isFalse);
      },
    );

    testWidgets('recomputes keyed visual order after reorder', (tester) async {
      final nodes = {
        for (final value in ['a', 'b', 'c', 'd'])
          value: FocusNode(debugLabel: 'option $value'),
      };
      for (final node in nodes.values) {
        addTearDown(node.dispose);
      }
      var values = ['a', 'b', 'c'];
      late StateSetter rebuild;

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return NakedToggleGroup<String>(
              selectedValue: 'a',
              onChanged: (_) {},
              child: Row(
                children: [
                  for (final value in values)
                    NakedToggleOption<String>(
                      key: ValueKey(value),
                      value: value,
                      focusNode: nodes[value],
                      child: Text(value.toUpperCase()),
                    ),
                ],
              ),
            );
          },
        ),
      );

      nodes['b']!.requestFocus();
      await tester.pump();
      rebuild(() => values = ['b', 'c', 'a']);
      await tester.pump();
      expect(nodes['b']!.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(nodes['c']));

      rebuild(() => values = ['b', 'd', 'c', 'a']);
      await tester.pump();
      nodes['b']!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(nodes['d']));
    });

    testWidgets('repairs focused removal to successor then predecessor', (
      tester,
    ) async {
      final nodes = {
        for (final value in ['a', 'b', 'c'])
          value: FocusNode(debugLabel: 'option $value'),
      };
      for (final node in nodes.values) {
        addTearDown(node.dispose);
      }
      var values = ['a', 'b', 'c'];
      final enabledValues = {'a', 'b', 'c'};
      late StateSetter rebuild;

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return NakedToggleGroup<String>(
              selectedValue: 'a',
              onChanged: (_) {},
              child: Row(
                children: [
                  for (final value in values)
                    NakedToggleOption<String>(
                      key: ValueKey(value),
                      value: value,
                      enabled: enabledValues.contains(value),
                      focusNode: nodes[value],
                      child: Text(value.toUpperCase()),
                    ),
                ],
              ),
            );
          },
        ),
      );

      nodes['b']!.requestFocus();
      await tester.pump();
      rebuild(() => values = ['a', 'c']);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(nodes['c']));

      rebuild(() => enabledValues.remove('c'));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(nodes['a']));

      final listener = () {};
      expect(() => nodes['b']!.addListener(listener), returnsNormally);
      nodes['b']!.removeListener(listener);
    });

    testWidgets('retargets while outside without stealing page focus', (
      tester,
    ) async {
      final optionA = FocusNode(debugLabel: 'option A');
      final optionB = FocusNode(debugLabel: 'option B');
      final optionC = FocusNode(debugLabel: 'option C');
      final after = FocusNode(debugLabel: 'after');
      for (final node in [optionA, optionB, optionC, after]) {
        addTearDown(node.dispose);
      }
      String? selected = 'a';
      late StateSetter rebuild;

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Column(
              children: [
                NakedToggleGroup<String>(
                  selectedValue: selected,
                  onChanged: (_) {},
                  child: Row(
                    children: [
                      NakedToggleOption<String>(
                        value: 'a',
                        focusNode: optionA,
                        child: const Text('A'),
                      ),
                      NakedToggleOption<String>(
                        value: 'b',
                        focusNode: optionB,
                        child: const Text('B'),
                      ),
                      NakedToggleOption<String>(
                        value: 'c',
                        focusNode: optionC,
                        child: const Text('C'),
                      ),
                    ],
                  ),
                ),
                Focus(focusNode: after, child: const Text('After')),
              ],
            );
          },
        ),
      );

      after.requestFocus();
      await tester.pump();
      rebuild(() => selected = 'c');
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(optionC.hasPrimaryFocus, isTrue);

      after.requestFocus();
      await tester.pump();
      rebuild(() => selected = 'b');
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(
        optionC.hasPrimaryFocus,
        isTrue,
        reason: 'last still-valid focus has priority over selection',
      );
    });

    testWidgets('hands focus across caller-owned node swaps', (tester) async {
      final oldNode = FocusNode(debugLabel: 'old option node');
      final newNode = FocusNode(debugLabel: 'new option node');
      addTearDown(oldNode.dispose);
      addTearDown(newNode.dispose);
      var focusNode = oldNode;
      var showGroup = true;
      late StateSetter rebuild;

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return showGroup
                ? NakedToggleGroup<String>(
                    selectedValue: 'a',
                    onChanged: (_) {},
                    child: NakedToggleOption<String>(
                      value: 'a',
                      focusNode: focusNode,
                      child: const Text('A'),
                    ),
                  )
                : const SizedBox();
          },
        ),
      );

      oldNode.requestFocus();
      await tester.pump();
      rebuild(() => focusNode = newNode);
      await tester.pump();
      expect(newNode.hasPrimaryFocus, isTrue);

      rebuild(() => showGroup = false);
      await tester.pump();
      final listener = () {};
      expect(() => oldNode.addListener(listener), returnsNormally);
      oldNode.removeListener(listener);
      expect(() => newNode.addListener(listener), returnsNormally);
      newNode.removeListener(listener);
    });

    testWidgets('autofocus resolves to the enabled roving target', (
      tester,
    ) async {
      final optionA = FocusNode(debugLabel: 'option A');
      final optionB = FocusNode(debugLabel: 'option B');
      addTearDown(optionA.dispose);
      addTearDown(optionB.dispose);

      await tester.pumpMaterialWidget(
        NakedToggleGroup<String>(
          selectedValue: 'b',
          onChanged: (_) {},
          child: Row(
            children: [
              NakedToggleOption<String>(
                value: 'a',
                autofocus: true,
                focusNode: optionA,
                child: const Text('A'),
              ),
              NakedToggleOption<String>(
                value: 'b',
                focusNode: optionB,
                child: const Text('B'),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(optionB.hasPrimaryFocus, isTrue);
      expect(optionA.hasFocus, isFalse);
    });

    testWidgets('preserves option builder and interaction callbacks', (
      tester,
    ) async {
      const optionKey = ValueKey('option-b');
      final optionFocus = FocusNode(debugLabel: 'option B');
      addTearDown(optionFocus.dispose);
      final focusChanges = <bool>[];
      final hoverChanges = <bool>[];
      final pressChanges = <bool>[];
      late NakedToggleOptionState<String> latestState;

      await tester.pumpMaterialWidget(
        NakedToggleGroup<String>(
          selectedValue: 'a',
          onChanged: (_) {},
          child: NakedToggleOption<String>(
            key: optionKey,
            value: 'b',
            focusNode: optionFocus,
            onFocusChange: focusChanges.add,
            onHoverChange: hoverChanges.add,
            onPressChange: pressChanges.add,
            builder: (context, state, child) {
              latestState = state;
              return const SizedBox(width: 80, height: 40);
            },
          ),
        ),
      );

      expect(latestState.value, 'b');
      expect(latestState.isSelected, isFalse);

      optionFocus.requestFocus();
      await tester.pump();
      expect(focusChanges, [true]);
      expect(latestState.isFocused, isTrue);

      await tester.simulateHover(optionKey);
      expect(hoverChanges, [true, false]);

      await tester.simulatePress(optionKey);
      expect(pressChanges, [true, false]);
    });

    testWidgets('clears hover state on every effective-disable path', (
      tester,
    ) async {
      const optionKey = ValueKey('hover-option');
      var optionEnabled = true;
      var groupEnabled = true;
      var callbackEnabled = true;
      late StateSetter rebuild;
      late NakedToggleOptionState<String> latestState;
      final hoverChanges = <bool>[];
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      addTearDown(mouse.removePointer);

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return NakedToggleGroup<String>(
              selectedValue: 'a',
              enabled: groupEnabled,
              onChanged: callbackEnabled ? (_) {} : null,
              child: NakedToggleOption<String>(
                key: optionKey,
                value: 'a',
                enabled: optionEnabled,
                onHoverChange: (value) {
                  hoverChanges.add(value);
                  if (!value) rebuild(() {});
                },
                builder: (context, state, child) {
                  latestState = state;
                  return const SizedBox(width: 80, height: 40);
                },
              ),
            );
          },
        ),
      );

      await mouse.moveTo(tester.getCenter(find.byKey(optionKey)));
      await tester.pump();
      expect(latestState.isHovered, isTrue);
      expect(hoverChanges, [true]);

      rebuild(() => optionEnabled = false);
      await tester.pump();
      expect(latestState.isDisabled, isTrue);
      expect(latestState.isHovered, isFalse);
      expect(hoverChanges, [true, false]);

      await mouse.moveTo(const Offset(-100, -100));
      rebuild(() => optionEnabled = true);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(optionKey)));
      await tester.pump();
      expect(latestState.isHovered, isTrue);

      rebuild(() => groupEnabled = false);
      await tester.pump();
      expect(latestState.isDisabled, isTrue);
      expect(latestState.isHovered, isFalse);
      expect(hoverChanges, [true, false, true, false]);

      await mouse.moveTo(const Offset(-100, -100));
      rebuild(() => groupEnabled = true);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(optionKey)));
      await tester.pump();
      expect(latestState.isHovered, isTrue);

      rebuild(() => callbackEnabled = false);
      await tester.pump();
      expect(latestState.isDisabled, isTrue);
      expect(latestState.isHovered, isFalse);
      expect(hoverChanges, [true, false, true, false, true, false]);
    });

    testWidgets('clears pressed state on every effective-disable path', (
      tester,
    ) async {
      const optionKey = ValueKey('pressed-option');
      var optionEnabled = true;
      var groupEnabled = true;
      var callbackEnabled = true;
      late StateSetter rebuild;
      late NakedToggleOptionState<String> latestState;
      final pressChanges = <bool>[];

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return NakedToggleGroup<String>(
              selectedValue: 'a',
              enabled: groupEnabled,
              onChanged: callbackEnabled ? (_) {} : null,
              child: NakedToggleOption<String>(
                key: optionKey,
                value: 'a',
                enabled: optionEnabled,
                onPressChange: (value) {
                  pressChanges.add(value);
                  if (!value) rebuild(() {});
                },
                builder: (context, state, child) {
                  latestState = state;
                  return const SizedBox(width: 80, height: 40);
                },
              ),
            );
          },
        ),
      );

      Future<void> pressThenDisable(
        VoidCallback disable, {
        required int expectedPresses,
      }) async {
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(optionKey)),
        );
        await tester.pump();
        expect(latestState.isPressed, isTrue);

        rebuild(disable);
        await tester.pump();
        expect(latestState.isDisabled, isTrue);
        expect(latestState.isPressed, isFalse);
        final expectedChanges = <bool>[
          for (var i = 0; i < expectedPresses; i++) ...[true, false],
        ];
        expect(pressChanges, expectedChanges);

        await gesture.up();
        await tester.pump();
        expect(pressChanges, expectedChanges);
      }

      await pressThenDisable(() => optionEnabled = false, expectedPresses: 1);
      rebuild(() => optionEnabled = true);
      await tester.pump();

      await pressThenDisable(() => groupEnabled = false, expectedPresses: 2);
      rebuild(() => groupEnabled = true);
      await tester.pump();

      await pressThenDisable(() => callbackEnabled = false, expectedPresses: 3);
    });

    testWidgets('reports one focus loss on every effective-disable path', (
      tester,
    ) async {
      final optionFocus = FocusNode(debugLabel: 'option B');
      addTearDown(optionFocus.dispose);
      var optionEnabled = true;
      var groupEnabled = true;
      var callbackEnabled = true;
      late StateSetter rebuild;
      final focusChanges = <bool>[];

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return NakedToggleGroup<String>(
              selectedValue: 'a',
              enabled: groupEnabled,
              onChanged: callbackEnabled ? (_) {} : null,
              child: Row(
                children: [
                  const NakedToggleOption<String>(value: 'a', child: Text('A')),
                  NakedToggleOption<String>(
                    value: 'b',
                    enabled: optionEnabled,
                    focusNode: optionFocus,
                    onFocusChange: (value) {
                      focusChanges.add(value);
                      if (!value) rebuild(() {});
                    },
                    child: const Text('B'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      Future<void> focusThenDisable(
        VoidCallback disable, {
        required int expectedPairs,
      }) async {
        optionFocus.requestFocus();
        await tester.pump();
        expect(optionFocus.hasPrimaryFocus, isTrue);

        rebuild(disable);
        await tester.pump();
        final expectedChanges = <bool>[
          for (var i = 0; i < expectedPairs; i++) ...[true, false],
        ];
        expect(focusChanges, expectedChanges);
        await tester.pump();
        expect(
          focusChanges,
          expectedChanges,
          reason: 'false is not duplicated',
        );
      }

      await focusThenDisable(() => optionEnabled = false, expectedPairs: 1);
      rebuild(() => optionEnabled = true);
      await tester.pump();

      await focusThenDisable(() => groupEnabled = false, expectedPairs: 2);
      rebuild(() => groupEnabled = true);
      await tester.pump();

      await focusThenDisable(() => callbackEnabled = false, expectedPairs: 3);
    });

    testStateScopeBuilder<NakedToggleState>(
      'builder\'s context contains NakedStateScope',
      (builder) =>
          NakedToggle(builder: builder, value: false, child: const SizedBox()),
    );

    group('asSwitch parameter', () {
      testWidgets('behaves as toggle button by default', (tester) async {
        bool value = false;
        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) => NakedToggle(
              value: value,
              onChanged: (v) => setState(() => value = v),
              child: const Text('Toggle'),
            ),
          ),
        );

        await tester.tap(find.text('Toggle'));
        await tester.pump();
        expect(value, isTrue);
      });

      testWidgets('behaves as switch when asSwitch=true', (tester) async {
        bool value = false;
        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) => NakedToggle(
              value: value,
              asSwitch: true,
              onChanged: (v) => setState(() => value = v),
              child: const Text('Switch'),
            ),
          ),
        );

        await tester.tap(find.text('Switch'));
        await tester.pump();
        expect(value, isTrue);
      });
    });
  });
}
