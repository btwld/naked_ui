import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

SemanticsNode _findToggleNode(WidgetTester tester) {
  final SemanticsNode root = tester.getSemantics(find.byType(Scaffold));
  SemanticsNode? found;
  bool dfs(SemanticsNode n) {
    final d = n.getSemanticsData();
    final hasToggle = d.flagsCollection.hasToggledState ||
        d.flagsCollection.hasCheckedState;
    if (hasToggle && found == null) {
      found = n;
      return true;
    }
    n.visitChildren(dfs);
    return true;
  }

  root.visitChildren(dfs);
  if (found == null) {
    throw StateError('No toggle-like semantics node found');
  }
  return found!;
}

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('NakedSwitch Semantics', () {
    testWidgets('parity with Material Switch - on/off enabled', (tester) async {
      final handle = tester.ensureSemantics();

      // Off strict parity
      await tester.pumpWidget(
        _buildTestApp(Switch(value: false, onChanged: (_) {})),
      );
      final mOff = _findToggleNode(tester);
      final strictOff = buildStrictMatcherFromSemanticsData(
        mOff.getSemanticsData(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedSwitch(
            value: false,
            onChanged: (_) {},
            child: const SizedBox(width: 40, height: 24),
          ),
        ),
      );
      expect(_findToggleNode(tester), strictOff);

      // On strict parity
      await tester.pumpWidget(
        _buildTestApp(Switch(value: true, onChanged: (_) {})),
      );
      final mOn = _findToggleNode(tester);
      final strictOn = buildStrictMatcherFromSemanticsData(
        mOn.getSemanticsData(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedSwitch(
            value: true,
            onChanged: (_) {},
            child: const SizedBox(width: 40, height: 24),
          ),
        ),
      );
      expect(_findToggleNode(tester), strictOn);
      handle.dispose();
    });

    testWidgets('disabled parity', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildTestApp(const Switch(value: false, onChanged: null)),
      );
      final mNode = _findToggleNode(tester);
      final strict = buildStrictMatcherFromSemanticsData(mNode.getSemanticsData());

      await tester.pumpWidget(
        _buildTestApp(
          const NakedSwitch(
            value: false,
            onChanged: null,
            child: SizedBox(width: 40, height: 24),
          ),
        ),
      );
      expect(_findToggleNode(tester), strict);
      handle.dispose();
    });

    testWidgets('focus parity', (tester) async {
      final handle = tester.ensureSemantics();
      final fm = FocusNode();
      final fn = FocusNode();

      await tester.pumpWidget(
        _buildTestApp(Switch(value: false, onChanged: (_) {}, focusNode: fm)),
      );
      fm.requestFocus();
      await tester.pump();
      final mNode = _findToggleNode(tester);
      final strict = buildStrictMatcherFromSemanticsData(mNode.getSemanticsData());

      await tester.pumpWidget(
        _buildTestApp(
          NakedSwitch(
            value: false,
            onChanged: (_) {},
            focusNode: fn,
            child: const SizedBox(width: 40, height: 24),
          ),
        ),
      );
      fn.requestFocus();
      await tester.pump();
      expect(_findToggleNode(tester), strict);

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
        _buildTestApp(Switch(value: false, onChanged: (_) {})),
      );
      await mouse.moveTo(tester.getCenter(find.byType(Switch)));
      await tester.pump();
      final mNode = tester.getSemantics(find.byType(Switch));
      final strict = buildStrictMatcherFromSemanticsData(mNode.getSemanticsData());

      await tester.pumpWidget(
        _buildTestApp(
          NakedSwitch(
            value: false,
            onChanged: (_) {},
            child: const SizedBox(width: 40, height: 24),
          ),
        ),
      );
      await mouse.moveTo(tester.getCenter(find.byType(NakedSwitch)));
      await tester.pump();
      expect(tester.getSemantics(find.byType(NakedSwitch)), strict);
      await mouse.removePointer();
      handle.dispose();
    });
  });
}
