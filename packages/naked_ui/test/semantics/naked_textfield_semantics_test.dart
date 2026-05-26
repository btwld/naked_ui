import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('NakedTextField Semantics', () {
    testWidgets('enabled empty field exposes text-field contract', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedTextField(
            enabled: true,
            builder: (context, state, editable) => editable,
          ),
        ),
      );

      final summary = summarizeMergedFromRoot(
        tester,
        control: ControlType.textField,
      );
      expect(summary.flags, containsAll(['isTextField', 'hasEnabledState']));
      expect(summary.flags, contains('isEnabled'));
      expect(summary.flags, contains('isFocusable'));
      expect(summary.actions, contains('tap'));

      handle.dispose();
    });

    testWidgets('disabled field exposes read-only disabled contract', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedTextField(
            enabled: false,
            builder: (context, state, editable) => editable,
          ),
        ),
      );

      final summary = summarizeMergedFromRoot(
        tester,
        control: ControlType.textField,
      );
      expect(summary.flags, contains('isTextField'));
      expect(summary.flags, contains('hasEnabledState'));
      expect(summary.flags, isNot(contains('isEnabled')));
      expect(summary.flags, contains('isReadOnly'));
      expect(summary.actions, isNot(contains('tap')));

      handle.dispose();
    });

    testWidgets('focused field exposes focus semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final fn = FocusNode();

      await tester.pumpWidget(
        _buildTestApp(
          NakedTextField(
            focusNode: fn,
            builder: (context, state, editable) => editable,
          ),
        ),
      );
      fn.requestFocus();
      await tester.pump();
      final summary = summarizeMergedFromRoot(
        tester,
        control: ControlType.textField,
      );
      expect(summary.flags, contains('isTextField'));
      expect(summary.flags, contains('isFocused'));
      expect(summary.flags, contains('isFocusable'));
      expect(summary.actions, contains('focus'));

      fn.dispose();
      handle.dispose();
    });

    testWidgets('read-only multiline field exposes text-field flags', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedTextField(
            maxLines: 3,
            readOnly: true,
            builder: (context, state, editable) => editable,
          ),
        ),
      );
      final summary = summarizeMergedFromRoot(
        tester,
        control: ControlType.textField,
      );
      expect(summary.flags, contains('isTextField'));
      expect(summary.flags, contains('isReadOnly'));
      expect(summary.flags, contains('isMultiline'));

      handle.dispose();
    });

    testWidgets('error text is associated with a live text field node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'bad');

      await tester.pumpWidget(
        _buildTestApp(
          NakedTextField(
            controller: controller,
            error: true,
            semanticLabel: 'Email',
            semanticHint: 'Enter your email',
            semanticErrorText: 'Enter a valid email address',
            builder: (context, state, editable) => editable,
          ),
        ),
      );

      final root = tester.getSemantics(find.byType(Scaffold));
      final textFieldNodes = collectSemanticsNodes(
        root,
        (node) => node.getSemanticsData().flagsCollection.isTextField,
      );
      expect(textFieldNodes, hasLength(1));
      expectNoNestedSemanticsNodes(
        root,
        predicate: (node) =>
            node.getSemanticsData().flagsCollection.isTextField,
        debugName: 'text field',
      );

      final data = textFieldNodes.single.getSemanticsData();
      expect(data.label, 'Email');
      expect(data.hint, contains('Enter your email'));
      expect(data.hint, contains('Enter a valid email address'));
      expect(data.flagsCollection.isLiveRegion, isTrue);
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.flagsCollection.isFocused, isNot(Tristate.none));

      controller.dispose();
      handle.dispose();
    });

    testWidgets('semanticErrorText is silent when error is false', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedTextField(
            error: false,
            semanticLabel: 'Email',
            semanticHint: 'Enter your email',
            semanticErrorText: 'Enter a valid email address',
            builder: (context, state, editable) => editable,
          ),
        ),
      );

      final root = tester.getSemantics(find.byType(Scaffold));
      final node = findSemanticsNode(
        root,
        (node) => node.getSemanticsData().flagsCollection.isTextField,
      );

      expect(node, isNotNull);
      final data = node!.getSemanticsData();
      expect(data.label, 'Email');
      expect(data.hint, 'Enter your email');
      expect(data.hint, isNot(contains('Enter a valid email address')));
      expect(data.flagsCollection.isLiveRegion, isFalse);

      handle.dispose();
    });
  });
}
