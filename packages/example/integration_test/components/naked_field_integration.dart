import 'dart:ui'
    show SemanticsAction, SemanticsRole, SemanticsValidationResult, Tristate;

import 'package:example/api/naked_field.0.dart' as field_example;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Widget _testApp(
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

Finder get _control => find.byKey(field_example.fieldEmailControlKey);

Finder get _editable =>
    find.descendant(of: _control, matching: find.byType(EditableText));

List<SemanticsNode> _semanticsNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];

  void collect(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      collect(child);
      return true;
    });
  }

  collect(tester.getSemantics(find.byType(Scaffold)));
  return nodes;
}

SemanticsNode _textFieldNode(WidgetTester tester) {
  return _semanticsNodes(tester).singleWhere((node) {
    final data = node.getSemanticsData();
    return data.flagsCollection.isTextField && data.label.isNotEmpty;
  });
}

List<SemanticsNode> _alertNodes(WidgetTester tester) {
  return _semanticsNodes(tester)
      .where((node) => node.getSemanticsData().role == SemanticsRole.alert)
      .toList();
}

String _stateText(WidgetTester tester) {
  return tester
          .widget<Text>(find.byKey(field_example.fieldEmailStateKey))
          .data ??
      '';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedField Integration Tests', () {
    testWidgets('label focuses the control and typing updates Field state', (
      tester,
    ) async {
      await tester.pumpWidget(_testApp(const field_example.FieldExample()));
      await tester.pump();

      final editable = tester.widget<EditableText>(_editable);
      expect(editable.focusNode.hasFocus, isFalse);
      expect(_stateText(tester), contains('empty'));

      await tester.tap(find.byKey(field_example.fieldEmailLabelKey));
      await tester.pump();

      expect(editable.focusNode.hasFocus, isTrue);
      expect(_stateText(tester), contains('focused'));

      await tester.enterText(_editable, 'not-an-email');
      await tester.pump();

      expect(editable.controller.text, 'not-an-email');
      expect(_stateText(tester), contains('filled'));
      expect(_stateText(tester), contains('none'));
    });

    testWidgets(
      'consumer validation announces changes once and clears on correction',
      (tester) async {
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(_testApp(const field_example.FieldExample()));
        await tester.pump();

        await tester.enterText(_editable, 'not-an-email');
        await tester.tap(find.byKey(field_example.fieldEmailSubmitKey));
        await tester.pump();

        expect(
          find.descendant(
            of: find.byKey(field_example.fieldEmailErrorKey),
            matching: find.text('Enter a valid email address.'),
          ),
          findsOneWidget,
        );
        var data = _textFieldNode(tester).getSemanticsData();
        expect(data.label, 'Email address');
        expect(
          data.hint,
          'Use the address where we can reach you.\n'
          'Enter a valid email address.',
        );
        expect(data.flagsCollection.isRequired, Tristate.isTrue);
        expect(data.validationResult, SemanticsValidationResult.invalid);
        expect(_alertNodes(tester), hasLength(1));
        expect(
          _alertNodes(tester).single.getSemanticsData().label,
          'Enter a valid email address.',
        );

        await tester.pump();
        expect(_alertNodes(tester), isEmpty);

        await tester.tap(find.byKey(field_example.fieldEmailSubmitKey));
        await tester.pump();
        expect(
          _alertNodes(tester),
          isEmpty,
          reason: 'An unchanged rebuild must not repeat the error.',
        );

        await tester.enterText(_editable, '');
        await tester.pump();
        expect(_alertNodes(tester), hasLength(1));
        expect(
          _alertNodes(tester).single.getSemanticsData().label,
          'Enter an email address.',
        );

        await tester.pump();
        await tester.enterText(_editable, 'person@example.com');
        await tester.pump();

        data = _textFieldNode(tester).getSemanticsData();
        expect(data.hint, 'Use the address where we can reach you.');
        expect(data.validationResult, SemanticsValidationResult.valid);
        expect(_alertNodes(tester), isEmpty);
        expect(_stateText(tester), contains('valid'));

        await tester.tap(find.byKey(field_example.fieldEmailResetKey));
        await tester.pump();

        expect(tester.widget<EditableText>(_editable).controller.text, isEmpty);
        data = _textFieldNode(tester).getSemanticsData();
        expect(data.validationResult, SemanticsValidationResult.none);
        expect(_stateText(tester), contains('empty'));
        semantics.dispose();
      },
    );

    testWidgets('disabled and read-only remain distinct', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _testApp(
          const field_example.FieldExample(
            key: ValueKey('disabled-field'),
            enabled: false,
            initialValue: 'person@example.com',
          ),
        ),
      );
      await tester.pump();

      var editable = tester.widget<EditableText>(_editable);
      var data = _textFieldNode(tester).getSemanticsData();
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.flagsCollection.isReadOnly, isTrue);
      expect(data.hasAction(SemanticsAction.focus), isFalse);
      expect(data.hasAction(SemanticsAction.setText), isFalse);
      expect(_stateText(tester), contains('disabled'));

      await tester.tap(find.byKey(field_example.fieldEmailLabelKey));
      await tester.pump();
      expect(editable.focusNode.hasFocus, isFalse);

      await tester.pumpWidget(
        _testApp(
          const field_example.FieldExample(
            key: ValueKey('read-only-field'),
            readOnly: true,
            initialValue: 'person@example.com',
          ),
        ),
      );
      await tester.pump();

      editable = tester.widget<EditableText>(_editable);
      data = _textFieldNode(tester).getSemanticsData();
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.flagsCollection.isReadOnly, isTrue);
      expect(data.hasAction(SemanticsAction.focus), isTrue);
      expect(data.hasAction(SemanticsAction.setText), isFalse);
      expect(_stateText(tester), contains('read-only'));

      await tester.tap(find.byKey(field_example.fieldEmailLabelKey));
      await tester.pump();
      expect(editable.focusNode.hasFocus, isTrue);

      await tester.enterText(_editable, 'changed@example.com');
      await tester.pump();
      expect(editable.controller.text, 'person@example.com');
      semantics.dispose();
    });

    testWidgets('RTL fixture keeps localized metadata canonical', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      const label = 'البريد الإلكتروني';
      const description = 'أدخل عنوان بريد يمكننا الوصول إليه.';
      const invalidError = 'أدخل عنوان بريد إلكتروني صالحًا.';

      await tester.pumpWidget(
        _testApp(
          const field_example.FieldExample(
            label: label,
            description: description,
            requiredError: 'أدخل عنوان بريد إلكتروني.',
            invalidError: invalidError,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pump();

      expect(Directionality.of(tester.element(_control)), TextDirection.rtl);
      await tester.enterText(_editable, 'غير صالح');
      await tester.tap(find.byKey(field_example.fieldEmailSubmitKey));
      await tester.pump();

      final data = _textFieldNode(tester).getSemanticsData();
      expect(data.label, label);
      expect(data.hint, '$description\n$invalidError');
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(_alertNodes(tester).single.getSemanticsData().label, invalidError);
      semantics.dispose();
    });

    testWidgets('fixture remains usable with 200 percent text', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const field_example.FieldExample(),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(MediaQuery.textScalerOf(tester.element(_control)).scale(16), 32);
      expect(find.byKey(field_example.fieldEmailKey), findsOneWidget);
      expect(find.byKey(field_example.fieldEmailLabelKey), findsOneWidget);
      expect(find.byKey(field_example.fieldEmailControlKey), findsOneWidget);
      expect(
        find.byKey(field_example.fieldEmailDescriptionKey),
        findsOneWidget,
      );
      expect(find.byKey(field_example.fieldEmailErrorKey), findsOneWidget);
      expect(find.byKey(field_example.fieldEmailSubmitKey), findsOneWidget);
      expect(find.byKey(field_example.fieldEmailStateKey), findsOneWidget);
      expect(find.byKey(field_example.fieldEmailResetKey), findsOneWidget);

      await tester.ensureVisible(find.byKey(field_example.fieldEmailResetKey));
      await tester.tap(find.byKey(field_example.fieldEmailLabelKey));
      await tester.pump();
      expect(tester.widget<EditableText>(_editable).focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
