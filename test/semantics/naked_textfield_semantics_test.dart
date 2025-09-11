import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

SemanticsNode _findTextFieldNode(WidgetTester tester) {
  final SemanticsNode root = tester.getSemantics(find.byType(Scaffold));
  SemanticsNode? found;
  bool dfs(SemanticsNode n) {
    final d = n.getSemanticsData();
    if (d.hasFlag(SemanticsFlag.isTextField)) {
      found = n;
      return true;
    }
    n.visitChildren(dfs);
    return true;
  }

  root.visitChildren(dfs);
  if (found == null) throw StateError('No textField node found');
  return found!;
}

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('NakedTextField Semantics', () {
    testWidgets('parity with Material TextField - enabled empty', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(const TextField()),
        naked: _buildTestApp(
          NakedTextField(
            enabled: true,
            builder: (context, editable) => editable,
          ),
        ),
        control: ControlType.textField,
      );
      handle.dispose();
    });

    testWidgets('parity with Material TextField - disabled', (tester) async {
      final handle = tester.ensureSemantics();

      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(const TextField(enabled: false)),
        naked: _buildTestApp(
          NakedTextField(
            enabled: false,
            builder: (context, editable) => editable,
          ),
        ),
        control: ControlType.textField,
      );
      handle.dispose();
    });

    testWidgets('focus and hover parity', (tester) async {
      final handle = tester.ensureSemantics();
      final fm = FocusNode();
      final fn = FocusNode();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await tester.pump();

      await tester.pumpWidget(
        _buildTestApp(TextField(focusNode: fm)),
      );
      fm.requestFocus();
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byType(TextField)));
      await tester.pump();
      var materialFocused = summarizeMergedFromRoot(
        tester,
        control: ControlType.textField,
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedTextField(
            focusNode: fn,
            builder: (context, editable) => editable,
          ),
        ),
      );
      fn.requestFocus();
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byType(NakedTextField)));
      await tester.pump();
      var nakedFocused = summarizeMergedFromRoot(
        tester,
        control: ControlType.textField,
      );
      // Normalize focusable flag differences from ancestor placement.
      SemanticsSummary stripFocusable(SemanticsSummary s) => SemanticsSummary(
            label: s.label,
            value: s.value,
            flags: s.flags.where((f) => f != 'isFocusable').toSet(),
            actions: s.actions,
          );
      materialFocused = stripFocusable(materialFocused);
      nakedFocused = stripFocusable(nakedFocused);
      expect(nakedFocused, equals(materialFocused));

      await mouse.removePointer();
      fm.dispose();
      fn.dispose();
      handle.dispose();
    });

    testWidgets('multiline and readOnly parity', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(const TextField(maxLines: 3, readOnly: true)),
      );
      var mat = summarizeMergedFromRoot(tester, control: ControlType.textField);

      await tester.pumpWidget(
        _buildTestApp(
          NakedTextField(
            maxLines: 3,
            readOnly: true,
            builder: (context, editable) => editable,
          ),
        ),
      );
      var nak = summarizeMergedFromRoot(tester, control: ControlType.textField);
      // Normalize focusable differences
      SemanticsSummary stripFocusable(SemanticsSummary s) => SemanticsSummary(
            label: s.label,
            value: s.value,
            flags: s.flags.where((f) => f != 'isFocusable').toSet(),
            actions: s.actions,
          );
      expect(stripFocusable(nak), equals(stripFocusable(mat)));

      handle.dispose();
    });
  });
}
