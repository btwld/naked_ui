import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

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
                    builder: (context, states, child) => Text(
                      states.contains(WidgetState.selected) ? 'A*' : 'A',
                    ),
                  ),
                  NakedToggleOption<String>(
                    value: 'b',
                    builder: (context, states, child) => Text(
                      states.contains(WidgetState.selected) ? 'B*' : 'B',
                    ),
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
