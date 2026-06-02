import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
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

  group('NakedSlider Semantics', () {
    testWidgets('enabled slider exposes value and keyboard step semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedSlider(
            value: 0.5,
            min: 0,
            max: 1,
            onChanged: (_) {},
            child: const SizedBox(width: 200, height: 40),
          ),
        ),
      );

      final summary = summarizeMergedFromRoot(
        tester,
        control: ControlType.slider,
      );
      expect(summary.value, '50%');
      expect(summary.increasedValue, '51%');
      expect(summary.decreasedValue, '49%');
      expect(summary.flags, containsAll(['isSlider', 'hasEnabledState']));
      expect(summary.flags, contains('isEnabled'));
      expect(summary.actions, containsAll(['increase', 'decrease']));

      handle.dispose();
    });

    testWidgets('disabled slider exposes value without semantic actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedSlider(
            value: 0.5,
            min: 0,
            max: 1,
            onChanged: null,
            child: const SizedBox(width: 200, height: 40),
          ),
        ),
      );

      final summary = summarizeMergedFromRoot(
        tester,
        control: ControlType.slider,
      );
      expect(summary.value, '50%');
      expect(summary.flags, contains('isSlider'));
      expect(summary.flags, isNot(contains('isEnabled')));
      expect(summary.actions, isEmpty);

      handle.dispose();
    });

    testWidgets('focus parity', (tester) async {
      final handle = tester.ensureSemantics();
      final fm = FocusNode();
      final fn = FocusNode();

      await tester.pumpWidget(
        _buildTestApp(
          Slider(value: 0.2, min: 0, max: 1, onChanged: (_) {}, focusNode: fm),
        ),
      );
      fm.requestFocus();
      await tester.pump();
      final materialFocused = summarizeMergedFromRoot(
        tester,
        control: ControlType.slider,
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedSlider(
            value: 0.2,
            min: 0,
            max: 1,
            onChanged: (_) {},
            focusNode: fn,
            child: const SizedBox(width: 200, height: 40),
          ),
        ),
      );
      fn.requestFocus();
      await tester.pump();
      final nakedFocused = summarizeMergedFromRoot(
        tester,
        control: ControlType.slider,
      );

      expect(nakedFocused.label, materialFocused.label);
      expect(nakedFocused.value, materialFocused.value);
      expect(nakedFocused.flags, materialFocused.flags);
      expect(nakedFocused.actions, materialFocused.actions);

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
        _buildTestApp(Slider(value: 0.7, min: 0, max: 1, onChanged: (_) {})),
      );
      await mouse.moveTo(tester.getCenter(find.byType(Slider)));
      await tester.pump();
      final materialHovered = summarizeMergedFromRoot(
        tester,
        control: ControlType.slider,
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedSlider(
            value: 0.7,
            min: 0,
            max: 1,
            onChanged: (_) {},
            child: const SizedBox(width: 200, height: 40),
          ),
        ),
      );
      await mouse.moveTo(tester.getCenter(find.byType(NakedSlider)));
      await tester.pump();
      final nakedHovered = summarizeMergedFromRoot(
        tester,
        control: ControlType.slider,
      );

      expect(nakedHovered.label, materialHovered.label);
      expect(nakedHovered.value, materialHovered.value);
      expect(nakedHovered.flags, materialHovered.flags);
      expect(nakedHovered.actions, materialHovered.actions);
      await mouse.removePointer();
      handle.dispose();
    });

    testWidgets('semanticFormatterCallback customizes value announcements', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedSlider(
            value: 50,
            min: 0,
            max: 100,
            keyboardStep: 10,
            semanticFormatterCallback: (value) => '${value.round()} dollars',
            onChanged: (_) {},
            child: const SizedBox(width: 200, height: 40),
          ),
        ),
      );

      final summary = summarizeMergedFromRoot(
        tester,
        control: ControlType.slider,
      );
      expect(summary.value, '50 dollars');
      expect(summary.increasedValue, '60 dollars');
      expect(summary.decreasedValue, '40 dollars');

      handle.dispose();
    });

    testWidgets('semantic increase and decrease actions step and clamp value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final reportedValues = <double>[];

      await tester.pumpWidget(
        _buildTestApp(
          NakedSlider(
            value: 0.5,
            min: 0,
            max: 1,
            keyboardStep: 0.1,
            onChanged: reportedValues.add,
            child: const SizedBox(width: 200, height: 40),
          ),
        ),
      );

      var root = tester.getSemantics(find.byType(Scaffold));
      var sliderNode = findSemanticsNode(
        root,
        (node) => node.getSemanticsData().flagsCollection.isSlider,
      );
      expect(sliderNode, isNotNull);

      void performSliderAction(ui.SemanticsAction action) {
        tester.binding.performSemanticsAction(
          ui.SemanticsActionEvent(
            type: action,
            viewId: tester.view.viewId,
            nodeId: sliderNode!.id,
          ),
        );
      }

      performSliderAction(ui.SemanticsAction.increase);
      await tester.pump();
      performSliderAction(ui.SemanticsAction.decrease);
      await tester.pump();

      expect(reportedValues, [closeTo(0.6, 0.0001), closeTo(0.4, 0.0001)]);

      reportedValues.clear();
      await tester.pumpWidget(
        _buildTestApp(
          NakedSlider(
            value: 0.95,
            min: 0,
            max: 1,
            keyboardStep: 0.1,
            onChanged: reportedValues.add,
            child: const SizedBox(width: 200, height: 40),
          ),
        ),
      );
      root = tester.getSemantics(find.byType(Scaffold));
      sliderNode = findSemanticsNode(
        root,
        (node) => node.getSemanticsData().flagsCollection.isSlider,
      );
      expect(sliderNode, isNotNull);

      performSliderAction(ui.SemanticsAction.increase);
      await tester.pump();

      expect(reportedValues, [1.0]);

      handle.dispose();
    });
  });
}
