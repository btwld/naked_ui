import 'dart:ui'
    show SemanticsInputType, SemanticsRole, SemanticsValidationResult, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_test_utils.dart';

void main() {
  testWidgets('summarizeNode includes extended semantics fields', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            label: 'Details',
            value: 'Current',
            increasedValue: 'Next',
            decreasedValue: 'Previous',
            expanded: true,
            scopesRoute: true,
            namesRoute: true,
            role: SemanticsRole.dialog,
            validationResult: SemanticsValidationResult.invalid,
            inputType: SemanticsInputType.email,
            minValue: 'Minimum',
            maxValue: 'Maximum',
            explicitChildNodes: true,
            identifier: 'details-trigger',
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(SizedBox));
    final summary = summarizeNode(node);

    expect(summary.label, 'Details');
    expect(summary.value, 'Current');
    expect(summary.increasedValue, 'Next');
    expect(summary.decreasedValue, 'Previous');
    expect(summary.identifier, 'details-trigger');
    expect(summary.role, SemanticsRole.dialog);
    expect(summary.validationResult, SemanticsValidationResult.invalid);
    expect(summary.inputType, SemanticsInputType.email);
    expect(summary.minValue, 'Minimum');
    expect(summary.maxValue, 'Maximum');
    expect(summary.flags, contains('isExpanded'));
    expect(summary.flags, contains('scopesRoute'));
    expect(summary.flags, contains('namesRoute'));
    expect(node.getSemanticsData().flagsCollection.isExpanded, Tristate.isTrue);

    handle.dispose();
  });

  testWidgets('summarizeNode preserves duplicate merged labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(label: 'Name', child: const Text('Name')),
      ),
    );

    final summary = summarizeNode(tester.getSemantics(find.text('Name')));
    expect(summary.label, 'Name\nName');

    handle.dispose();
  });

  testWidgets('summarizeNode distinguishes collapsed expanded state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            label: 'Details',
            expanded: false,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final summary = summarizeNode(tester.getSemantics(find.byType(SizedBox)));

    expect(summary.flags, contains('hasExpandedState'));
    expect(summary.flags, isNot(contains('isExpanded')));

    handle.dispose();
  });

  testWidgets('tree helpers count matching nodes and detect nesting', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            container: true,
            textField: true,
            child: Semantics(
              container: true,
              textField: true,
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      ),
    );

    final root = tester.getSemantics(find.byType(Scaffold));
    bool isTextField(SemanticsNode node) {
      return node.getSemanticsData().flagsCollection.isTextField;
    }

    expect(countSemanticsNodes(root, isTextField), 2);
    expect(
      () => expectNoNestedSemanticsNodes(
        root,
        predicate: isTextField,
        debugName: 'text field',
      ),
      throwsA(isA<TestFailure>()),
    );

    handle.dispose();
  });
}
