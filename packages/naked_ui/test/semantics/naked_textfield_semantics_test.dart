import 'dart:ui' show SemanticsRole, SemanticsValidationResult, Tristate;

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

    testWidgets('initial error is discoverable without a live or alert node', (
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
      expect(data.flagsCollection.isLiveRegion, isFalse);
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.flagsCollection.isFocused, isNot(Tristate.none));
      expect(
        collectSemanticsNodes(
          root,
          (node) => node.getSemanticsData().role == SemanticsRole.alert,
        ),
        isEmpty,
      );

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

    testWidgets('standalone required and validation metadata are exposed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedTextField(
            semanticLabel: 'Email',
            isRequired: true,
            validationResult: SemanticsValidationResult.valid,
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
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.validationResult, SemanticsValidationResult.valid);
      handle.dispose();
    });

    testWidgets('a changed standalone error creates one transient alert', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      late StateSetter rebuild;
      var error = false;

      await tester.pumpWidget(
        _buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NakedTextField(
                error: error,
                semanticLabel: 'Email',
                semanticErrorText: 'Invalid email',
                builder: (context, state, editable) => editable,
              );
            },
          ),
        ),
      );

      rebuild(() => error = true);
      await tester.pump();

      var root = tester.getSemantics(find.byType(Scaffold));
      var alerts = collectSemanticsNodes(
        root,
        (node) => node.getSemanticsData().role == SemanticsRole.alert,
      );
      expect(alerts, hasLength(1));
      expect(alerts.single.getSemanticsData().label, 'Invalid email');
      expect(
        alerts.single.getSemanticsData().flagsCollection.isLiveRegion,
        isFalse,
      );

      final textField = findSemanticsNode(
        root,
        (node) => node.getSemanticsData().flagsCollection.isTextField,
      );
      expect(textField, isNotNull);
      expect(textField!.getSemanticsData().hint, 'Invalid email');
      expect(
        textField.getSemanticsData().flagsCollection.isLiveRegion,
        isFalse,
      );

      await tester.pump();
      root = tester.getSemantics(find.byType(Scaffold));
      alerts = collectSemanticsNodes(
        root,
        (node) => node.getSemanticsData().role == SemanticsRole.alert,
      );
      expect(alerts, isEmpty);
      handle.dispose();
    });

    testWidgets('excluded semantics suppresses a changed-error alert', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      late StateSetter rebuild;
      var error = false;

      await tester.pumpWidget(
        _buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NakedTextField(
                excludeSemantics: true,
                error: error,
                semanticLabel: 'Email',
                semanticErrorText: 'Invalid email',
                builder: (context, state, editable) => editable,
              );
            },
          ),
        ),
      );

      rebuild(() => error = true);
      await tester.pump();

      final root = tester.getSemantics(find.byType(Scaffold));
      expect(
        collectSemanticsNodes(
          root,
          (node) => node.getSemanticsData().role == SemanticsRole.alert,
        ),
        isEmpty,
      );
      expect(
        collectSemanticsNodes(
          root,
          (node) => node.getSemanticsData().flagsCollection.isTextField,
        ),
        isEmpty,
      );
      handle.dispose();
    });
  });
}
