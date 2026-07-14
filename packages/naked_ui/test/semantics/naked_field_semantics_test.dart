import 'dart:ui'
    show SemanticsAction, SemanticsRole, SemanticsValidationResult, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

Widget _testApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

Widget _textField({
  bool enabled = true,
  bool readOnly = false,
  String? semanticLabel,
  String? semanticHint,
  String? semanticErrorText,
  bool error = false,
  bool? isRequired,
  SemanticsValidationResult? validationResult,
}) {
  return NakedTextField(
    enabled: enabled,
    readOnly: readOnly,
    semanticLabel: semanticLabel,
    semanticHint: semanticHint,
    semanticErrorText: semanticErrorText,
    error: error,
    isRequired: isRequired,
    validationResult: validationResult,
    builder: (context, state, editable) => editable,
  );
}

List<SemanticsNode> _nodes(WidgetTester tester) {
  final root = tester.getSemantics(find.byType(Scaffold));
  return collectSemanticsNodes(root, (_) => true);
}

List<SemanticsNode> _textFieldNodes(WidgetTester tester) {
  return _nodes(tester)
      .where((node) => node.getSemanticsData().flagsCollection.isTextField)
      .toList();
}

List<SemanticsNode> _alertNodes(WidgetTester tester) {
  return _nodes(tester)
      .where((node) => node.getSemanticsData().role == SemanticsRole.alert)
      .toList();
}

void main() {
  group('NakedField semantics', () {
    testWidgetsWithSemantics(
      'metadata lands once on the native text-field node',
      (tester) async {
        await tester.pumpWidget(
          _testApp(
            NakedField(
              label: 'Email',
              description: 'Work address',
              errorText: 'Invalid email',
              isRequired: true,
              validationResult: SemanticsValidationResult.invalid,
              child: Column(
                children: [
                  const NakedFieldLabel(child: Text('Email')),
                  const NakedFieldDescription(child: Text('Work address')),
                  _textField(
                    semanticLabel: 'Email',
                    semanticHint: 'Work address',
                    semanticErrorText: 'Invalid email',
                    error: true,
                    isRequired: true,
                    validationResult: SemanticsValidationResult.invalid,
                  ),
                  const NakedFieldError(child: Text('Invalid email')),
                ],
              ),
            ),
          ),
        );
        await tester.tap(find.byType(EditableText));
        await tester.pump();

        final textFields = _textFieldNodes(tester);
        expect(textFields, hasLength(1));
        final data = textFields.single.getSemanticsData();
        expect(data.label, 'Email');
        expect(data.hint, 'Work address\nInvalid email');
        expect(data.flagsCollection.isRequired, Tristate.isTrue);
        expect(data.validationResult, SemanticsValidationResult.invalid);
        expect(data.flagsCollection.isLiveRegion, isFalse);
        expect(data.hasAction(SemanticsAction.setText), isTrue);
        expect(data.hasAction(SemanticsAction.setSelection), isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(_alertNodes(tester), isEmpty);

        expect(
          _nodes(tester).where((node) {
            final nodeData = node.getSemanticsData();
            return nodeData.label == 'Email' ||
                nodeData.hint.contains('Work address') ||
                nodeData.hint.contains('Invalid email');
          }),
          hasLength(1),
        );
      },
    );

    testWidgetsWithSemantics(
      'required false and valid are explicit on the control',
      (tester) async {
        await tester.pumpWidget(
          _testApp(
            NakedField(
              label: 'Email',
              isRequired: false,
              validationResult: SemanticsValidationResult.valid,
              child: _textField(),
            ),
          ),
        );

        final data = _textFieldNodes(tester).single.getSemanticsData();
        expect(data.flagsCollection.isRequired, Tristate.isFalse);
        expect(data.validationResult, SemanticsValidationResult.valid);
      },
    );

    testWidgetsWithSemantics('default validation result is explicitly none', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(NakedField(label: 'Email', child: _textField())),
      );

      final data = _textFieldNodes(tester).single.getSemanticsData();
      expect(data.validationResult, SemanticsValidationResult.none);
    });

    testWidgetsWithSemantics(
      'disabled and read-only semantics use the stricter state',
      (tester) async {
        await tester.pumpWidget(
          _testApp(
            NakedField(label: 'Email', enabled: false, child: _textField()),
          ),
        );

        var data = _textFieldNodes(tester).single.getSemanticsData();
        expect(data.flagsCollection.isEnabled, Tristate.isFalse);
        expect(data.flagsCollection.isReadOnly, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
        expect(data.hasAction(SemanticsAction.focus), isFalse);

        await tester.pumpWidget(
          _testApp(
            NakedField(label: 'Email', readOnly: true, child: _textField()),
          ),
        );

        data = _textFieldNodes(tester).single.getSemanticsData();
        expect(data.flagsCollection.isEnabled, Tristate.isTrue);
        expect(data.flagsCollection.isReadOnly, isTrue);
        expect(data.hasAction(SemanticsAction.focus), isTrue);
        expect(data.hasAction(SemanticsAction.setText), isFalse);

        await tester.pumpWidget(
          _testApp(
            NakedField(label: 'Email', child: _textField(enabled: false)),
          ),
        );

        data = _textFieldNodes(tester).single.getSemanticsData();
        expect(data.flagsCollection.isEnabled, Tristate.isFalse);
        expect(data.flagsCollection.isReadOnly, isTrue);
        expect(data.hasAction(SemanticsAction.focus), isFalse);

        await tester.pumpWidget(
          _testApp(
            NakedField(label: 'Email', child: _textField(readOnly: true)),
          ),
        );

        data = _textFieldNodes(tester).single.getSemanticsData();
        expect(data.flagsCollection.isEnabled, Tristate.isTrue);
        expect(data.flagsCollection.isReadOnly, isTrue);
        expect(data.hasAction(SemanticsAction.focus), isTrue);
      },
    );

    testWidgetsWithSemantics(
      'Field exclusion removes control and helper semantics',
      (tester) async {
        await tester.pumpWidget(
          _testApp(
            NakedField(
              label: 'Email',
              description: 'Work address',
              excludeSemantics: true,
              child: Column(
                children: [
                  const NakedFieldLabel(child: Text('Email')),
                  const NakedFieldDescription(child: Text('Work address')),
                  _textField(),
                ],
              ),
            ),
          ),
        );

        expect(_textFieldNodes(tester), isEmpty);
        expect(
          _nodes(
            tester,
          ).where((node) => node.getSemanticsData().label.contains('Email')),
          isEmpty,
        );
      },
    );
  });

  group('NakedField error transitions', () {
    testWidgetsWithSemantics(
      'completed semantics updates announce changed errors exactly once',
      (tester) async {
        final announcements = AlertSemanticsUpdateRecorder(tester);
        late StateSetter rebuild;
        var errorText = 'Initial error';
        var unrelated = 0;

        try {
          await tester.pumpWidget(
            _testApp(
              StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return NakedField(
                    label: 'Email $unrelated',
                    errorText: errorText,
                    child: _textField(),
                  );
                },
              ),
            ),
          );

          expect(_alertNodes(tester), isEmpty);
          expect(
            announcements.introducedLabels,
            isEmpty,
            reason: 'An error present on the initial build is not live.',
          );

          rebuild(() => errorText = 'Changed error');
          await tester.pump();
          expect(_alertNodes(tester), hasLength(1));
          expect(announcements.introducedLabels, <String>['Changed error']);

          rebuild(() => errorText = 'Replacement error');
          await tester.pump();
          expect(_alertNodes(tester), hasLength(1));
          expect(announcements.introducedLabels, <String>[
            'Changed error',
            'Replacement error',
          ]);

          await tester.pump();
          expect(_alertNodes(tester), isEmpty);

          rebuild(() => unrelated++);
          await tester.pump();
          expect(_alertNodes(tester), isEmpty);
          expect(
            announcements.introducedLabels,
            <String>['Changed error', 'Replacement error'],
            reason: 'An unchanged error must not be dispatched again.',
          );
        } finally {
          announcements.dispose();
        }
      },
    );

    testWidgetsWithSemantics(
      'changed error creates one alert for one completed update',
      (tester) async {
        late StateSetter rebuild;
        String? errorText;

        await tester.pumpWidget(
          _testApp(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return NakedField(
                  label: 'Email',
                  errorText: errorText,
                  isRequired: true,
                  validationResult: errorText == null
                      ? SemanticsValidationResult.none
                      : SemanticsValidationResult.invalid,
                  child: _textField(),
                );
              },
            ),
          ),
        );
        expect(_alertNodes(tester), isEmpty);
        await tester.tap(find.byType(EditableText));
        await tester.pump();

        rebuild(() => errorText = 'Invalid email');
        await tester.pump();

        final root = tester.getSemantics(find.byType(Scaffold));
        final alerts = _alertNodes(tester);
        expect(alerts, hasLength(1));
        final alertData = alerts.single.getSemanticsData();
        expect(alertData.label, 'Invalid email');
        expect(alertData.flagsCollection.isLiveRegion, isFalse);
        expect(
          collectSemanticsNodes(
            alerts.single,
            (node) => node.getSemanticsData().flagsCollection.isTextField,
          ),
          isEmpty,
        );

        final textFields = _textFieldNodes(tester);
        expect(textFields, hasLength(1));
        expect(
          collectSemanticsNodes(
            textFields.single,
            (node) => node.getSemanticsData().role == SemanticsRole.alert,
          ),
          isEmpty,
        );
        final textFieldData = textFields.single.getSemanticsData();
        expect(textFieldData.label, 'Email');
        expect(textFieldData.hint, 'Invalid email');
        expect(textFieldData.flagsCollection.isRequired, Tristate.isTrue);
        expect(
          textFieldData.validationResult,
          SemanticsValidationResult.invalid,
        );
        expect(textFieldData.flagsCollection.isLiveRegion, isFalse);
        expect(textFieldData.hasAction(SemanticsAction.setText), isTrue);
        expect(textFieldData.hasAction(SemanticsAction.setSelection), isTrue);
        expect(textFieldData.hasAction(SemanticsAction.tap), isTrue);
        expect(
          collectSemanticsNodes(
            root,
            (node) => node.getSemanticsData().role == SemanticsRole.alert,
          ),
          hasLength(1),
        );

        await tester.pump();
        expect(_alertNodes(tester), isEmpty);
      },
    );

    testWidgetsWithSemantics('unchanged rebuild does not recreate an alert', (
      tester,
    ) async {
      late StateSetter rebuild;
      String? errorText;
      var unrelated = 0;

      await tester.pumpWidget(
        _testApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NakedField(
                label: 'Email $unrelated',
                errorText: errorText,
                child: _textField(),
              );
            },
          ),
        ),
      );

      rebuild(() => errorText = 'Invalid email');
      await tester.pump();
      expect(_alertNodes(tester), hasLength(1));
      await tester.pump();
      expect(_alertNodes(tester), isEmpty);

      rebuild(() => unrelated++);
      await tester.pump();
      expect(_alertNodes(tester), isEmpty);
    });

    testWidgetsWithSemantics(
      'clear then re-add announces the same error again',
      (tester) async {
        late StateSetter rebuild;
        String? errorText;

        await tester.pumpWidget(
          _testApp(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return NakedField(
                  label: 'Email',
                  errorText: errorText,
                  child: _textField(),
                );
              },
            ),
          ),
        );

        rebuild(() => errorText = 'Invalid email');
        await tester.pump();
        expect(_alertNodes(tester), hasLength(1));
        await tester.pump();

        rebuild(() => errorText = null);
        await tester.pump();
        expect(_alertNodes(tester), isEmpty);

        rebuild(() => errorText = 'Invalid email');
        await tester.pump();
        expect(_alertNodes(tester), hasLength(1));
      },
    );

    testWidgetsWithSemantics(
      'announcement policy none suppresses transition alerts',
      (tester) async {
        late StateSetter rebuild;
        String? errorText;

        await tester.pumpWidget(
          _testApp(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return NakedField(
                  label: 'Email',
                  errorText: errorText,
                  errorAnnouncement: NakedFieldErrorAnnouncement.none,
                  child: _textField(),
                );
              },
            ),
          ),
        );

        rebuild(() => errorText = 'Invalid email');
        await tester.pump();

        expect(_alertNodes(tester), isEmpty);
        expect(
          _textFieldNodes(tester).single.getSemanticsData().hint,
          'Invalid email',
        );
      },
    );

    testWidgetsWithSemantics(
      'localized non-empty error change announces translated text',
      (tester) async {
        late StateSetter rebuild;
        var errorText = 'Invalid email';

        await tester.pumpWidget(
          _testApp(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return NakedField(
                  label: 'Email',
                  errorText: errorText,
                  child: _textField(),
                );
              },
            ),
          ),
        );
        expect(_alertNodes(tester), isEmpty);

        rebuild(() => errorText = 'E-Mail-Adresse ist ungültig');
        await tester.pump();

        final alerts = _alertNodes(tester);
        expect(alerts, hasLength(1));
        expect(
          alerts.single.getSemanticsData().label,
          'E-Mail-Adresse ist ungültig',
        );
      },
    );
  });
}
