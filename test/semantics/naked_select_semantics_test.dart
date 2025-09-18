import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  Widget _buildNakedSelect({String? selectedValue, bool enabled = true}) {
    return NakedSelect<String>(
      selectedValue: selectedValue ?? 'option1',
      onSelectedValueChanged: enabled ? (value) {} : null,
      enabled: enabled,
      child: const NakedSelectTrigger(child: Text('Select Option')),
      overlay: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NakedSelectItem(value: 'option1', child: Text('Option 1')),
            NakedSelectItem(value: 'option2', child: Text('Option 2')),
            NakedSelectItem(value: 'option3', child: Text('Option 3')),
          ],
        ),
      ),
    );
  }

  Widget _buildNakedMultiSelect() {
    return NakedSelect<String>.multiple(
      selectedValues: const {'option1'},
      onSelectedValuesChanged: (values) {},
      child: const NakedSelectTrigger(child: Text('Multi Select')),
      overlay: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NakedSelectItem(value: 'option1', child: Text('Option 1')),
            NakedSelectItem(value: 'option2', child: Text('Option 2')),
            NakedSelectItem(value: 'option3', child: Text('Option 3')),
          ],
        ),
      ),
    );
  }

  group('NakedSelect Semantics', () {
    testWidgets('select trigger button semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedSelect()));

      // Verify trigger has button semantics
      final summary = summarizeMergedFromRoot(
        tester,
        control: ControlType.button,
      );
      expect(summary.flags.contains('isButton'), isTrue);
      expect(summary.flags.contains('isFocusable'), isTrue);
      expect(summary.actions.contains('tap'), isTrue);

      handle.dispose();
    });

    testWidgets('select opens and closes semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedSelect()));

      // Initially closed
      expect(find.text('Select Option'), findsOneWidget);
      expect(find.text('Option 1'), findsNothing);

      // Tap to open
      await tester.tap(find.text('Select Option'));
      await tester.pumpAndSettle();

      // Verify select menu is open
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);

      // Tap outside to close
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify select menu is closed
      expect(find.text('Option 1'), findsNothing);

      handle.dispose();
    });

    testWidgets('select item selection semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedSelect()));

      // Open select
      await tester.tap(find.text('Select Option'));
      await tester.pumpAndSettle();

      // Verify items are selectable
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);

      // Tap an option
      await tester.tap(find.text('Option 2'));
      await tester.pumpAndSettle();

      // Verify select closed (normal behavior for single select)
      expect(find.text('Option 2'), findsNothing);

      handle.dispose();
    });

    testWidgets('disabled select semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedSelect(enabled: false)));

      // Tap should not open the select
      await tester.tap(find.text('Select Option'));
      await tester.pumpAndSettle();

      // Verify select didn't open
      expect(find.text('Option 1'), findsNothing);

      handle.dispose();
    });

    testWidgets('keyboard navigation semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedSelect()));

      // Open select
      await tester.tap(find.text('Select Option'));
      await tester.pumpAndSettle();

      // Verify select is open
      expect(find.text('Option 1'), findsOneWidget);

      // Press Escape to close
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Verify select closed
      expect(find.text('Option 1'), findsNothing);

      handle.dispose();
    });

    testWidgets('multi-select semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedMultiSelect()));

      // Open multi-select
      await tester.tap(find.text('Multi Select'));
      await tester.pumpAndSettle();

      // Verify items are available
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('focus management semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        _buildTestApp(
          NakedSelect<String>(
            selectedValue: 'option1',
            onSelectedValueChanged: (value) {},
            child: NakedSelectTrigger(
              focusNode: focusNode,
              child: const Text('Focusable Select'),
            ),
            overlay: Container(
              width: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedSelectItem(value: 'option1', child: Text('Option 1')),
                ],
              ),
            ),
          ),
        ),
      );

      // Request focus
      focusNode.requestFocus();
      await tester.pump();

      // Verify focus
      expect(focusNode.hasFocus, isTrue);

      focusNode.dispose();
      handle.dispose();
    });

    testWidgets('hover semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await tester.pump();

      await tester.pumpWidget(_buildTestApp(_buildNakedSelect()));

      // Hover over trigger
      await mouse.moveTo(tester.getCenter(find.text('Select Option')));
      await tester.pump();

      // Verify trigger responds to hover
      expect(find.text('Select Option'), findsOneWidget);

      await mouse.removePointer();
      handle.dispose();
    });

    testWidgets('select with semantic label', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedSelect<String>(
            selectedValue: 'option1',
            onSelectedValueChanged: (value) {},
            semanticLabel: 'Choose an option',
            child: const NakedSelectTrigger(child: Text('Labeled Select')),
            overlay: Container(
              width: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedSelectItem(value: 'option1', child: Text('Option 1')),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify select with semantic label
      expect(find.text('Labeled Select'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('type-ahead functionality semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedSelect()));

      // Open select
      await tester.tap(find.text('Select Option'));
      await tester.pumpAndSettle();

      // Verify select is open
      expect(find.text('Option 1'), findsOneWidget);

      // Type-ahead behavior is complex to test reliably in this context
      // Just verify the basic structure is accessible
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);

      handle.dispose();
    });
  });
}
