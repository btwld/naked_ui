import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// Material exports widgets; no separate widgets import needed.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

class _FakeRegistry<T> extends RadioGroupRegistry<T> {
  _FakeRegistry(this._groupValue);
  final T? _groupValue;
  @override
  T? get groupValue => _groupValue;
  @override
  ValueChanged<T?> get onChanged => (_) {};
  @override
  void registerClient(RadioClient<T> radio) {}
  @override
  void unregisterClient(RadioClient<T> radio) {}
}

SemanticsNode _findRadioNode(WidgetTester tester) {
  final SemanticsNode root = tester.getSemantics(find.byType(Scaffold));
  SemanticsNode? found;
  bool dfs(SemanticsNode n) {
    final d = n.getSemanticsData();
    if (d.flagsCollection.isInMutuallyExclusiveGroup) {
      found = n;
      return true;
    }
    n.visitChildren(dfs);
    return true;
  }

  root.visitChildren(dfs);
  if (found == null) throw StateError('No radio node found');
  return found!;
}

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }


  group('NakedRadio Semantics', () {
    testWidgets('parity with Material Radio - selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      final reg = _FakeRegistry<String>('a');
      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(
          Radio<String>(value: 'a', groupRegistry: reg),
        ),
        naked: _buildTestApp(
          NakedRadio<String>(
            value: 'a',
            groupRegistry: reg,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
        control: ControlType.radio,
      );
      handle.dispose();
    });

    testWidgets('parity with Material Radio - unselected', (tester) async {
      final handle = tester.ensureSemantics();
      final reg = _FakeRegistry<String>('b');
      await expectSemanticsParity(
        tester: tester,
        material: _buildTestApp(
          Radio<String>(value: 'a', groupRegistry: reg),
        ),
        naked: _buildTestApp(
          NakedRadio<String>(
            value: 'a',
            groupRegistry: reg,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
        control: ControlType.radio,
      );
      handle.dispose();
    });

    testWidgets('focus parity', (tester) async {
      final handle = tester.ensureSemantics();
      final fm = FocusNode();
      final fn = FocusNode();

      final reg = _FakeRegistry<String>('a');
      await tester.pumpWidget(
        _buildTestApp(Radio<String>(value: 'a', focusNode: fm, groupRegistry: reg)),
      );
      fm.requestFocus();
      await tester.pump();
      final materialFocused = summarizeMergedFromRoot(
        tester,
        control: ControlType.radio,
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedRadio<String>(
            value: 'a',
            groupRegistry: reg,
            focusNode: fn,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      fn.requestFocus();
      await tester.pump();
      final nakedFocused = summarizeMergedFromRoot(
        tester,
        control: ControlType.radio,
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

      final reg = _FakeRegistry<String>('a');
      await tester.pumpWidget(
        _buildTestApp(Radio<String>(value: 'a', groupRegistry: reg)),
      );
      await mouse.moveTo(tester.getCenter(find.byType(Radio<String>)));
      await tester.pump();
      final materialHovered = summarizeMergedFromRoot(
        tester,
        control: ControlType.radio,
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedRadio<String>(
            value: 'a',
            groupRegistry: reg,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      await mouse.moveTo(tester.getCenter(find.byType(NakedRadio<String>)));
      await tester.pump();
      final nakedHovered = summarizeMergedFromRoot(
        tester,
        control: ControlType.radio,
      );

      expect(nakedHovered, equals(materialHovered));
      await mouse.removePointer();
      handle.dispose();
    });

    testWidgets('disabled strict parity', (tester) async {
      final handle = tester.ensureSemantics();

      final reg = _FakeRegistry<String>('a');
      await tester.pumpWidget(
        _buildTestApp(Radio<String>(value: 'a', enabled: false, groupRegistry: reg)),
      );
      final mNode = tester.getSemantics(find.byType(Radio<String>));
      final strict = buildStrictMatcherFromSemanticsData(mNode.getSemanticsData());

      final reg2 = _FakeRegistry<String>('a');
      await tester.pumpWidget(
        _buildTestApp(
          NakedRadio<String>(
            value: 'a',
            groupRegistry: reg2,
            enabled: false,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      expect(_findRadioNode(tester), strict);

      handle.dispose();
    });
  });
}
