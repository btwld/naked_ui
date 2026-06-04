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

  Widget _buildMaterialTooltip({
    required String message,
    required String child,
  }) {
    return Tooltip(message: message, child: Text(child));
  }

  Widget _buildNakedTooltip({required String message, required String child}) {
    return NakedTooltip(
      semanticLabel: message,
      overlayBuilder: (context, animation) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(message, style: const TextStyle(color: Colors.white)),
      ),
      child: Text(child),
    );
  }

  group('NakedTooltip Semantics', () {
    testWidgets('basic tooltip semantics structure', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          _buildNakedTooltip(message: 'Tooltip message', child: 'Trigger text'),
        ),
      );

      expect(find.text('Trigger text'), findsOneWidget);

      final triggerNode = tester.getSemantics(find.text('Trigger text'));
      expect(triggerNode, isNotNull);

      handle.dispose();
    });

    testWidgets('tooltip with button-like trigger semantics', (tester) async {
      final handle = tester.ensureSemantics();

      Widget buildMaterialButtonWithTooltip() {
        return _buildTestApp(
          const Tooltip(
            message: 'Button tooltip',
            child: ElevatedButton(onPressed: null, child: Text('Button')),
          ),
        );
      }

      Widget buildNakedButtonWithTooltip() {
        return _buildTestApp(
          NakedTooltip(
            semanticLabel: 'Button tooltip',
            overlayBuilder: (context, animation) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Button tooltip',
                style: TextStyle(color: Colors.white),
              ),
            ),
            child: const NakedButton(onPressed: null, child: Text('Button')),
          ),
        );
      }

      await expectSemanticsParity(
        tester: tester,
        material: buildMaterialButtonWithTooltip(),
        naked: buildNakedButtonWithTooltip(),
        control: ControlType.button,
      );

      handle.dispose();
    });

    testWidgets('tooltip hover behavior semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await tester.pump();

      await tester.pumpWidget(
        _buildTestApp(
          _buildMaterialTooltip(message: 'Hover tooltip', child: 'Hover me'),
        ),
      );

      await mouse.moveTo(tester.getCenter(find.text('Hover me')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Hover tooltip'), findsOneWidget);

      await tester.pumpWidget(
        _buildTestApp(
          _buildNakedTooltip(message: 'Hover tooltip', child: 'Hover me'),
        ),
      );

      await mouse.moveTo(tester.getCenter(find.text('Hover me')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Hover me'), findsOneWidget);

      await mouse.removePointer();
      handle.dispose();
    });

    testWidgets('semantics label accessibility', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          _buildNakedTooltip(
            message: 'This is a helpful tooltip',
            child: 'Help',
          ),
        ),
      );

      final data = tester.getSemantics(find.text('Help')).getSemanticsData();
      expect(data.label, 'Help');
      expect(data.tooltip, 'This is a helpful tooltip');

      handle.dispose();
    });

    testWidgets('tooltip without semantics label', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedTooltip(
            overlayBuilder: (context, animation) =>
                const Text('Tooltip content'),
            child: const Text('No label'),
          ),
        ),
      );

      expect(find.text('No label'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('No label')),
        matchesSemantics(label: 'No label'),
      );
      expect(
        tester.getSemantics(find.text('No label')).getSemanticsData().tooltip,
        isEmpty,
      );

      handle.dispose();
    });
  });
}
