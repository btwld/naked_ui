import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/naked_ui.dart';

import 'semantics_test_utils.dart';

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('NakedCheckbox Semantics', () {
    testWidgets('parity with Material Checkbox - unchecked enabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(Checkbox(value: false, onChanged: (_) {})),
        naked: _buildTestApp(
          NakedCheckbox(
            value: false,
            onChanged: (_) {},
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
        control: ControlType.checkbox,
      );
      handle.dispose();
    });

    testWidgets('parity with Material Checkbox - checked enabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(Checkbox(value: true, onChanged: (_) {})),
        naked: _buildTestApp(
          NakedCheckbox(
            value: true,
            onChanged: (_) {},
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
        control: ControlType.checkbox,
      );
      handle.dispose();
    });

    testWidgets('parity with Material Checkbox - tristate null enabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(
          Checkbox(value: null, tristate: true, onChanged: (_) {}),
        ),
        naked: _buildTestApp(
          NakedCheckbox(
            value: null,
            tristate: true,
            onChanged: (_) {},
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
        control: ControlType.checkbox,
      );
      handle.dispose();
    });

    testWidgets('parity with Material Checkbox - disabled unchecked', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(const Checkbox(value: false, onChanged: null)),
        naked: _buildTestApp(
          const NakedCheckbox(
            value: false,
            onChanged: null,
            child: SizedBox(width: 20, height: 20),
          ),
        ),
        control: ControlType.checkbox,
      );
      handle.dispose();
    });

    testWidgets('focus parity', (tester) async {
      final handle = tester.ensureSemantics();
      final focusMat = FocusNode();
      final focusNaked = FocusNode();

      await tester.pumpWidget(
        _buildTestApp(
          Checkbox(value: false, onChanged: (_) {}, focusNode: focusMat),
        ),
      );
      focusMat.requestFocus();
      await tester.pump();
      final matFocused = summarizeMergedFromRoot(
        tester,
        control: ControlType.checkbox,
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedCheckbox(
            value: false,
            onChanged: (_) {},
            focusNode: focusNaked,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      focusNaked.requestFocus();
      await tester.pump();
      final nakedFocused = summarizeMergedFromRoot(
        tester,
        control: ControlType.checkbox,
      );

      expect(nakedFocused, equals(matFocused));
      focusMat.dispose();
      focusNaked.dispose();
      handle.dispose();
    });

    testWidgets('hover parity', (tester) async {
      final handle = tester.ensureSemantics();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await tester.pump();

      await tester.pumpWidget(
        _buildTestApp(Checkbox(value: false, onChanged: (_) {})),
      );
      await mouse.moveTo(tester.getCenter(find.byType(Checkbox)));
      await tester.pump();
      final matHovered = summarizeMergedFromRoot(
        tester,
        control: ControlType.checkbox,
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedCheckbox(
            value: false,
            onChanged: (_) {},
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      await mouse.moveTo(tester.getCenter(find.byType(NakedCheckbox)));
      await tester.pump();
      final nakedHovered = summarizeMergedFromRoot(
        tester,
        control: ControlType.checkbox,
      );

      expect(nakedHovered, equals(matHovered));
      await mouse.removePointer();
      handle.dispose();
    });
  });

  group('NakedCheckbox Strict Parity (no utils)', () {
    testWidgets('unchecked enabled strict parity', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(Checkbox(value: false, onChanged: (_) {})),
      );
      final mNode = tester.getSemantics(find.byType(Checkbox));
      final strict = buildStrictMatcherFromSemanticsData(
        mNode.getSemanticsData(),
      );
      expect(mNode, strict);

      await tester.pumpWidget(
        _buildTestApp(
          NakedCheckbox(
            value: false,
            onChanged: (_) {},
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      expect(tester.getSemantics(find.byType(NakedCheckbox)), strict);

      handle.dispose();
    });

    testWidgets('checked enabled strict parity', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(Checkbox(value: true, onChanged: (_) {})),
      );
      final mNode = tester.getSemantics(find.byType(Checkbox));
      final strict = buildStrictMatcherFromSemanticsData(
        mNode.getSemanticsData(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedCheckbox(
            value: true,
            onChanged: (_) {},
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      expect(tester.getSemantics(find.byType(NakedCheckbox)), strict);

      handle.dispose();
    });

    testWidgets('tristate null enabled strict parity', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(Checkbox(value: null, tristate: true, onChanged: (_) {})),
      );
      final mNode = tester.getSemantics(find.byType(Checkbox));
      final strict = buildStrictMatcherFromSemanticsData(
        mNode.getSemanticsData(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedCheckbox(
            value: null,
            tristate: true,
            onChanged: (_) {},
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      expect(tester.getSemantics(find.byType(NakedCheckbox)), strict);

      handle.dispose();
    });

    testWidgets('disabled unchecked strict parity', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(const Checkbox(value: false, onChanged: null)),
      );
      final mNode = tester.getSemantics(find.byType(Checkbox));
      final strict = buildStrictMatcherFromSemanticsData(
        mNode.getSemanticsData(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          const NakedCheckbox(
            value: false,
            onChanged: null,
            child: SizedBox(width: 20, height: 20),
          ),
        ),
      );
      expect(tester.getSemantics(find.byType(NakedCheckbox)), strict);

      handle.dispose();
    });

    testWidgets('focused strict parity', (tester) async {
      final handle = tester.ensureSemantics();
      final fm = FocusNode();
      final fn = FocusNode();

      await tester.pumpWidget(
        _buildTestApp(Checkbox(value: false, onChanged: (_) {}, focusNode: fm)),
      );
      fm.requestFocus();
      await tester.pump();
      final mNode = tester.getSemantics(find.byType(Checkbox));
      final strict = buildStrictMatcherFromSemanticsData(
        mNode.getSemanticsData(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedCheckbox(
            value: false,
            onChanged: (_) {},
            focusNode: fn,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      fn.requestFocus();
      await tester.pump();
      expect(tester.getSemantics(find.byType(NakedCheckbox)), strict);

      fm.dispose();
      fn.dispose();
      handle.dispose();
    });

    testWidgets('hovered strict parity', (tester) async {
      final handle = tester.ensureSemantics();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await tester.pump();

      await tester.pumpWidget(
        _buildTestApp(Checkbox(value: false, onChanged: (_) {})),
      );
      await mouse.moveTo(tester.getCenter(find.byType(Checkbox)));
      await tester.pump();
      final mNode = tester.getSemantics(find.byType(Checkbox));
      final strict = buildStrictMatcherFromSemanticsData(
        mNode.getSemanticsData(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedCheckbox(
            value: false,
            onChanged: (_) {},
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      await mouse.moveTo(tester.getCenter(find.byType(NakedCheckbox)));
      await tester.pump();
      expect(tester.getSemantics(find.byType(NakedCheckbox)), strict);

      await mouse.removePointer();
      handle.dispose();
    });
  });
}
