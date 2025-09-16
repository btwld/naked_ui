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
    testWidgets('parity with Material Slider - enabled', (tester) async {
      final handle = tester.ensureSemantics();

      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(
          Slider(value: 0.5, min: 0, max: 1, onChanged: (_) {}),
        ),
        naked: _buildTestApp(
          NakedSlider(
            value: 0.5,
            min: 0,
            max: 1,
            onChanged: (_) {},
            child: const SizedBox(width: 200, height: 40),
          ),
        ),
        control: ControlType.slider,
      );
      handle.dispose();
    });

    testWidgets('parity with Material Slider - disabled', (tester) async {
      final handle = tester.ensureSemantics();

      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(
          const Slider(value: 0.5, min: 0, max: 1, onChanged: null),
        ),
        naked: _buildTestApp(
          NakedSlider(
            value: 0.5,
            min: 0,
            max: 1,
            onChanged: null,
            child: const SizedBox(width: 200, height: 40),
          ),
        ),
        control: ControlType.slider,
      );
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

      expect(nakedHovered, equals(materialHovered));
      await mouse.removePointer();
      handle.dispose();
    });
  });
}
