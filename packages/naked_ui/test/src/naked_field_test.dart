import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/gestures.dart' show PointerDeviceKind, kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

Widget _testApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

Widget _textField({
  Key? key,
  FocusNode? focusNode,
  TextEditingController? controller,
  bool enabled = true,
  bool readOnly = false,
  String? semanticLabel,
  String? semanticHint,
  String? semanticErrorText,
  bool error = false,
  bool? isRequired,
  SemanticsValidationResult? validationResult,
  bool? ignorePointers,
  ValueChanged<NakedTextFieldState>? onBuild,
}) {
  return NakedTextField(
    key: key,
    focusNode: focusNode,
    controller: controller,
    enabled: enabled,
    readOnly: readOnly,
    semanticLabel: semanticLabel,
    semanticHint: semanticHint,
    semanticErrorText: semanticErrorText,
    error: error,
    isRequired: isRequired,
    validationResult: validationResult,
    ignorePointers: ignorePointers,
    builder: (context, state, editable) {
      onBuild?.call(state);
      return editable;
    },
  );
}

void main() {
  group('NakedField API', () {
    test('requires a child or builder', () {
      expect(() => NakedField(label: 'Email'), throwsAssertionError);
    });

    test('rejects a visible error with a valid result', () {
      expect(
        () => NakedField(
          label: 'Email',
          errorText: 'Invalid email',
          validationResult: SemanticsValidationResult.valid,
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    test('state equality includes all controlled and reported values', () {
      final first = NakedFieldState(
        states: const {WidgetState.focused, WidgetState.error},
        label: 'Email',
        description: 'Work address',
        errorText: 'Invalid email',
        isRequired: true,
        isReadOnly: false,
        isFilled: true,
        validationResult: SemanticsValidationResult.invalid,
      );
      final same = NakedFieldState(
        states: const {WidgetState.error, WidgetState.focused},
        label: 'Email',
        description: 'Work address',
        errorText: 'Invalid email',
        isRequired: true,
        isReadOnly: false,
        isFilled: true,
        validationResult: SemanticsValidationResult.invalid,
      );
      final different = NakedFieldState(
        states: const {WidgetState.focused, WidgetState.error},
        label: 'Email',
        description: 'Work address',
        errorText: 'Another error',
        isRequired: true,
        isReadOnly: false,
        isFilled: true,
        validationResult: SemanticsValidationResult.invalid,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });

    testWidgets('builder receives controlled state from its own scope', (
      tester,
    ) async {
      NakedFieldState? captured;
      NakedFieldState? fromScope;

      await tester.pumpWidget(
        _testApp(
          NakedField(
            label: 'Email',
            description: 'Work address',
            errorText: '   ',
            isRequired: true,
            enabled: false,
            readOnly: true,
            validationResult: SemanticsValidationResult.invalid,
            child: const SizedBox(),
            builder: (context, state, child) {
              captured = state;
              fromScope = NakedFieldState.of(context);
              return child!;
            },
          ),
        ),
      );

      expect(fromScope, same(captured));
      expect(captured!.label, 'Email');
      expect(captured!.description, 'Work address');
      expect(captured!.errorText, '   ');
      expect(captured!.isRequired, isTrue);
      expect(captured!.isEnabled, isFalse);
      expect(captured!.isReadOnly, isTrue);
      expect(captured!.validationResult, SemanticsValidationResult.invalid);
    });

    testWidgets('normalizes only an empty error as absent', (tester) async {
      NakedFieldState? captured;

      await tester.pumpWidget(
        _testApp(
          NakedField(
            label: 'Email',
            errorText: '',
            builder: (context, state, child) {
              captured = state;
              return child!;
            },
            child: const SizedBox(),
          ),
        ),
      );

      expect(captured!.errorText, isNull);
      expect(captured!.isError, isFalse);
    });
  });

  group('NakedField control registration', () {
    testWidgets('label focuses the mounted enabled text field', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _testApp(
          NakedField(
            label: 'Email',
            child: Column(
              children: [
                const NakedFieldLabel(
                  child: Text('Email', key: ValueKey('label')),
                ),
                _textField(focusNode: focusNode),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('label')));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('disabled Field governs interaction and builder state', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      NakedTextFieldState? textFieldState;

      await tester.pumpWidget(
        _testApp(
          MediaQuery(
            data: const MediaQueryData(
              navigationMode: NavigationMode.directional,
            ),
            child: NakedField(
              label: 'Email',
              enabled: false,
              child: Column(
                children: [
                  const NakedFieldLabel(
                    child: Text('Email', key: ValueKey('label')),
                  ),
                  _textField(
                    focusNode: focusNode,
                    onBuild: (state) => textFieldState = state,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('label')));
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
      expect(focusNode.canRequestFocus, isFalse);
      expect(textFieldState!.isEnabled, isFalse);
      expect(textFieldState!.isReadOnly, isFalse);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(NakedTextField),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is IgnorePointer && widget.child is RepaintBoundary,
          ),
        ),
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('Field disabled state cannot be bypassed by pointer override', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          NakedField(
            label: 'Email',
            enabled: false,
            child: _textField(ignorePointers: false),
          ),
        ),
      );

      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(NakedTextField),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is IgnorePointer && widget.child is RepaintBoundary,
          ),
        ),
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('disabling a Field clears an active pressed state', (
      tester,
    ) async {
      late StateSetter rebuild;
      var enabled = true;
      NakedTextFieldState? textFieldState;

      await tester.pumpWidget(
        _testApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NakedField(
                label: 'Email',
                enabled: enabled,
                child: _textField(onBuild: (state) => textFieldState = state),
              );
            },
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(EditableText)),
      );
      addTearDown(gesture.cancel);
      await tester.pump(kPressTimeout);
      expect(textFieldState!.isPressed, isTrue);

      rebuild(() => enabled = false);
      await tester.pump();

      expect(textFieldState!.isEnabled, isFalse);
      expect(textFieldState!.isPressed, isFalse);
    });

    testWidgets('disabling a Field clears an active hovered state', (
      tester,
    ) async {
      late StateSetter rebuild;
      var enabled = true;
      NakedTextFieldState? textFieldState;

      await tester.pumpWidget(
        _testApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NakedField(
                label: 'Email',
                enabled: enabled,
                child: _textField(onBuild: (state) => textFieldState = state),
              );
            },
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: const Offset(-1000, -1000));
      await gesture.moveTo(tester.getCenter(find.byType(EditableText)));
      await tester.pump();
      expect(textFieldState!.isHovered, isTrue);

      rebuild(() => enabled = false);
      await tester.pump();

      expect(textFieldState!.isEnabled, isFalse);
      expect(textFieldState!.isHovered, isFalse);
    });

    testWidgets('read-only Field remains focusable but is not editable', (
      tester,
    ) async {
      final focusNode = FocusNode();
      final controller = TextEditingController(text: 'seed');
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);
      NakedTextFieldState? textFieldState;

      await tester.pumpWidget(
        _testApp(
          NakedField(
            label: 'Email',
            readOnly: true,
            child: Column(
              children: [
                const NakedFieldLabel(
                  child: Text('Email', key: ValueKey('label')),
                ),
                _textField(
                  focusNode: focusNode,
                  controller: controller,
                  onBuild: (state) => textFieldState = state,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('label')));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(textFieldState!.isEnabled, isTrue);
      expect(textFieldState!.isReadOnly, isTrue);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
    });

    testWidgets('Field builder tracks primary control focus and filled state', (
      tester,
    ) async {
      final focusNode = FocusNode();
      final controller = TextEditingController();
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);
      NakedFieldState? fieldState;

      await tester.pumpWidget(
        _testApp(
          NakedField(
            label: 'Email',
            builder: (context, state, child) {
              fieldState = state;
              return child!;
            },
            child: _textField(focusNode: focusNode, controller: controller),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(fieldState!.isFocused, isFalse);
      expect(fieldState!.isFilled, isFalse);

      focusNode.requestFocus();
      controller.text = 'value';
      await tester.pump();
      await tester.pump();

      expect(fieldState!.isFocused, isTrue);
      expect(fieldState!.isFilled, isTrue);
    });

    testWidgets('Field builder reports enabled immediately when re-enabled', (
      tester,
    ) async {
      late StateSetter rebuild;
      var enabled = false;
      NakedFieldState? fieldState;

      await tester.pumpWidget(
        _testApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NakedField(
                label: 'Email',
                enabled: enabled,
                builder: (context, state, child) {
                  fieldState = state;
                  return child!;
                },
                child: _textField(),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(fieldState!.isEnabled, isFalse);

      rebuild(() => enabled = true);
      await tester.pump();

      expect(fieldState!.isEnabled, isTrue);
    });

    testWidgets('Field builder reports writable immediately when unlocked', (
      tester,
    ) async {
      late StateSetter rebuild;
      var readOnly = true;
      NakedFieldState? fieldState;

      await tester.pumpWidget(
        _testApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NakedField(
                label: 'Email',
                readOnly: readOnly,
                builder: (context, state, child) {
                  fieldState = state;
                  return child!;
                },
                child: _textField(),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(fieldState!.isReadOnly, isTrue);

      rebuild(() => readOnly = false);
      await tester.pump();

      expect(fieldState!.isReadOnly, isFalse);
    });

    testWidgets('replacing the primary control registers only the new field', (
      tester,
    ) async {
      final firstFocusNode = FocusNode();
      final secondFocusNode = FocusNode();
      addTearDown(firstFocusNode.dispose);
      addTearDown(secondFocusNode.dispose);
      late StateSetter rebuild;
      var showFirst = true;

      await tester.pumpWidget(
        _testApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NakedField(
                label: 'Email',
                child: Column(
                  children: [
                    const NakedFieldLabel(
                      child: Text('Email', key: ValueKey('label')),
                    ),
                    if (showFirst)
                      _textField(
                        key: const ValueKey('first'),
                        focusNode: firstFocusNode,
                      )
                    else
                      _textField(
                        key: const ValueKey('second'),
                        focusNode: secondFocusNode,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      rebuild(() => showFirst = false);
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('label')));
      await tester.pump();
      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
    });

    testWidgets('Field error metadata governs the control builder state', (
      tester,
    ) async {
      NakedTextFieldState? textFieldState;

      await tester.pumpWidget(
        _testApp(
          NakedField(
            label: 'Email',
            child: _textField(
              error: true,
              onBuild: (state) => textFieldState = state,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(textFieldState!.isError, isFalse);

      await tester.pumpWidget(
        _testApp(
          NakedField(
            label: 'Email',
            errorText: 'Field error',
            child: _textField(
              error: false,
              onBuild: (state) => textFieldState = state,
            ),
          ),
        ),
      );
      expect(textFieldState!.isError, isTrue);
    });

    testWidgets('multiple mounted text fields assert', (tester) async {
      await tester.pumpWidget(
        _testApp(
          NakedField(
            label: 'Email',
            child: Column(children: [_textField(), _textField()]),
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('visual helpers assert when used outside a Field', (
      tester,
    ) async {
      final helpers = <Widget>[
        const NakedFieldLabel(child: Text('Label')),
        const NakedFieldDescription(child: Text('Description')),
        const NakedFieldError(child: Text('Error')),
      ];

      for (final helper in helpers) {
        await tester.pumpWidget(_testApp(helper));
        expect(tester.takeException(), isAssertionError);
      }
    });
  });

  group('NakedField metadata precedence', () {
    final conflicts = <String, Widget Function()>{
      'label': () => NakedField(
        label: 'Field label',
        child: _textField(semanticLabel: 'Control label'),
      ),
      'description': () => NakedField(
        label: 'Email',
        description: 'Field description',
        child: _textField(semanticHint: 'Control description'),
      ),
      'error': () => NakedField(
        label: 'Email',
        errorText: 'Field error',
        child: _textField(error: true, semanticErrorText: 'Control error'),
      ),
      'required': () => NakedField(
        label: 'Email',
        isRequired: true,
        child: _textField(isRequired: false),
      ),
      'validation': () => NakedField(
        label: 'Email',
        validationResult: SemanticsValidationResult.invalid,
        child: _textField(validationResult: SemanticsValidationResult.valid),
      ),
    };

    for (final entry in conflicts.entries) {
      testWidgets('${entry.key} conflict asserts independently', (
        tester,
      ) async {
        await tester.pumpWidget(_testApp(entry.value()));
        expect(tester.takeException(), isAssertionError);
      });
    }

    testWidgets('identical explicit metadata is accepted', (tester) async {
      await tester.pumpWidget(
        _testApp(
          NakedField(
            label: 'Email',
            description: 'Work address',
            errorText: 'Invalid email',
            isRequired: true,
            validationResult: SemanticsValidationResult.invalid,
            child: _textField(
              semanticLabel: 'Email',
              semanticHint: 'Work address',
              semanticErrorText: 'Invalid email',
              error: true,
              isRequired: true,
              validationResult: SemanticsValidationResult.invalid,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(EditableText), findsOneWidget);
    });
  });
}
