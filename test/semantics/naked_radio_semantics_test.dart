import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('NakedRadio Semantics', () {
    testWidgets('parity with Material Radio - selected vs unselected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      // Use two radios under the group to avoid registration edge cases.
      // Selected state (groupValue 'a')
      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(
          RadioGroup<String>(
            groupValue: 'a',
            onChanged: (_) {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Radio<String>(value: 'a'),
                Radio<String>(value: 'b'),
              ],
            ),
          ),
        ),
        naked: _buildTestApp(
          RadioGroup<String>(
            groupValue: 'a',
            onChanged: (_) {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                NakedRadio<String>(
                  value: 'a',
                  child: SizedBox(width: 20, height: 20),
                ),
                NakedRadio<String>(
                  value: 'b',
                  child: SizedBox(width: 20, height: 20),
                ),
              ],
            ),
          ),
        ),
        control: ControlType.radio,
      );

      // Unselected state (groupValue 'b')
      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(
          RadioGroup<String>(
            groupValue: 'b',
            onChanged: (_) {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Radio<String>(value: 'a'),
                Radio<String>(value: 'b'),
              ],
            ),
          ),
        ),
        naked: _buildTestApp(
          RadioGroup<String>(
            groupValue: 'b',
            onChanged: (_) {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                NakedRadio<String>(
                  value: 'a',
                  child: SizedBox(width: 20, height: 20),
                ),
                NakedRadio<String>(
                  value: 'b',
                  child: SizedBox(width: 20, height: 20),
                ),
              ],
            ),
          ),
        ),
        control: ControlType.radio,
      );
      handle.dispose();
    });

    testWidgets('focus parity', (tester) async {
      final handle = tester.ensureSemantics();
      final fm = FocusNode();
      final fn = FocusNode();

      await tester.pumpWidget(
        _buildTestApp(
          RadioGroup<String>(
            groupValue: 'a',
            onChanged: (_) {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(value: 'a', focusNode: fm),
                const Radio<String>(value: 'b'),
              ],
            ),
          ),
        ),
      );
      fm.requestFocus();
      await tester.pump();
      final materialFocused = summarizeMergedFromRoot(
        tester,
        control: ControlType.radio,
      );

      await tester.pumpWidget(
        _buildTestApp(
          RadioGroup<String>(
            groupValue: 'a',
            onChanged: (_) {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedRadio<String>(
                  value: 'a',
                  focusNode: fn,
                  child: const SizedBox(width: 20, height: 20),
                ),
                const NakedRadio<String>(
                  value: 'b',
                  child: SizedBox(width: 20, height: 20),
                ),
              ],
            ),
          ),
        ),
      );
      fn.requestFocus();
      await tester.pump();
      final nakedFocused = summarizeMergedFromRoot(
        tester,
        control: ControlType.radio,
      );

      expect(nakedFocused, equals(materialFocused));

      fm.dispose();
      fn.dispose();
      handle.dispose();
    });

    testWidgets('hover parity', (tester) async {
      final handle = tester.ensureSemantics();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await tester.pump();

      await tester.pumpWidget(
        _buildTestApp(
          RadioGroup<String>(
            groupValue: 'a',
            onChanged: (_) {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Radio<String>(value: 'a'),
                Radio<String>(value: 'b'),
              ],
            ),
          ),
        ),
      );
      await mouse.moveTo(tester.getCenter(find.byType(Radio<String>)));
      await tester.pump();
      final materialHovered = summarizeMergedFromRoot(
        tester,
        control: ControlType.radio,
      );

      await tester.pumpWidget(
        _buildTestApp(
          RadioGroup<String>(
            groupValue: 'a',
            onChanged: (_) {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                NakedRadio<String>(
                  value: 'a',
                  child: SizedBox(width: 20, height: 20),
                ),
                NakedRadio<String>(
                  value: 'b',
                  child: SizedBox(width: 20, height: 20),
                ),
              ],
            ),
          ),
        ),
      );
      await mouse.moveTo(tester.getCenter(find.byType(NakedRadio<String>)));
      await tester.pump();
      final nakedHovered = summarizeMergedFromRoot(
        tester,
        control: ControlType.radio,
      );

      expect(nakedHovered, equals(materialHovered));
      await mouse.removePointer();
      handle.dispose();
    });

    testWidgets('disabled strict parity', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          RadioGroup<String>(
            groupValue: 'a',
            onChanged: (_) {},
            child: const Radio<String>(value: 'a', enabled: false),
          ),
        ),
      );
      final mNode = tester.getSemantics(find.byType(Radio<String>));
      final strict = buildStrictMatcherFromSemanticsData(mNode.getSemanticsData());

      await tester.pumpWidget(
        _buildTestApp(
          RadioGroup<String>(
            groupValue: 'a',
            onChanged: (_) {},
            child: const NakedRadio<String>(
              value: 'a',
              enabled: false,
              child: SizedBox(width: 20, height: 20),
            ),
          ),
        ),
      );
      expect(tester.getSemantics(find.byType(NakedRadio<String>)), strict);

      handle.dispose();
    });
  }, skip: true);
}
