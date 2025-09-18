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


  Widget _buildNakedPopover() {
    return NakedPopover(
      popoverBuilder: (context) => Container(
        width: 200,
        padding: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Menu Item 1'),
            const SizedBox(height: 8),
            const Text('Menu Item 2'),
          ],
        ),
      ),
      child: const Text('Show Menu'),
    );
  }

  group('NakedPopover Semantics', () {
    testWidgets('basic popover trigger semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedPopover()));

      // Verify trigger element has button-like semantics
      final summary = summarizeMergedFromRoot(tester, control: ControlType.button);
      expect(summary.actions.contains('tap'), isTrue);
      expect(summary.flags.contains('isFocusable'), isTrue);

      handle.dispose();
    });

    testWidgets('popover opens and closes semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedPopover()));

      // Initially closed
      expect(find.text('Show Menu'), findsOneWidget);
      expect(find.text('Menu Item 1'), findsNothing);

      // Tap to open
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // Verify popover is open
      expect(find.text('Menu Item 1'), findsOneWidget);
      expect(find.text('Menu Item 2'), findsOneWidget);

      // Tap outside to close
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify popover is closed
      expect(find.text('Menu Item 1'), findsNothing);

      handle.dispose();
    });

    testWidgets('keyboard focus semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedPopover()));

      // Verify trigger is focusable (basic semantics test)
      final summary = summarizeMergedFromRoot(tester, control: ControlType.button);
      expect(summary.flags.contains('isFocusable'), isTrue);

      handle.dispose();
    });

    testWidgets('escape key behavior semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedPopover()));

      // Open popover first
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // Verify popover is open
      expect(find.text('Menu Item 1'), findsOneWidget);

      // Press Escape to close
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Verify popover closed
      expect(find.text('Menu Item 1'), findsNothing);

      handle.dispose();
    });

    testWidgets('focus management semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        _buildTestApp(
          NakedPopover(
            popoverBuilder: (context) => Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Popover Content'),
            ),
            child: Focus(
              focusNode: focusNode,
              child: const Text('Focusable Trigger'),
            ),
          ),
        ),
      );

      // Request focus on the trigger
      focusNode.requestFocus();
      await tester.pump();

      // Verify focus is on the trigger
      expect(focusNode.hasFocus, isTrue);

      // Open popover
      await tester.tap(find.text('Focusable Trigger'));
      await tester.pumpAndSettle();

      // Verify popover is open
      expect(find.text('Popover Content'), findsOneWidget);

      focusNode.dispose();
      handle.dispose();
    });

    testWidgets('hover behavior semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await tester.pump();

      await tester.pumpWidget(_buildTestApp(_buildNakedPopover()));

      // Hover over trigger
      await mouse.moveTo(tester.getCenter(find.text('Show Menu')));
      await tester.pump();

      // Verify trigger responds to hover (basic test)
      expect(find.text('Show Menu'), findsOneWidget);

      await mouse.removePointer();
      handle.dispose();
    });

    testWidgets('disabled popover semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedPopover(
            openOnTap: false, // Disable tap interaction
            popoverBuilder: (context) => const Text('Disabled Popover'),
            child: const Text('Disabled Trigger'),
          ),
        ),
      );

      // Tap should not open the popover
      await tester.tap(find.text('Disabled Trigger'));
      await tester.pumpAndSettle();

      // Verify popover didn't open
      expect(find.text('Disabled Popover'), findsNothing);

      handle.dispose();
    });

    testWidgets('popover with custom positioning semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          NakedPopover(
            positioning: const OverlayPositionConfig(
              alignment: Alignment.bottomLeft,
            ),
            popoverBuilder: (context) => Container(
              width: 150,
              height: 100,
              color: Colors.blue,
              child: const Center(child: Text('Positioned')),
            ),
            child: const Text('Position Test'),
          ),
        ),
      );

      // Open popover
      await tester.tap(find.text('Position Test'));
      await tester.pumpAndSettle();

      // Verify positioned popover is visible
      expect(find.text('Positioned'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('multiple popovers semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          Column(
            children: [
              NakedPopover(
                popoverBuilder: (context) => Container(
                  width: 150,
                  padding: const EdgeInsets.all(8),
                  color: Colors.red,
                  child: const Text('Popover 1'),
                ),
                child: const Text('Trigger 1'),
              ),
              const SizedBox(height: 50),
              NakedPopover(
                popoverBuilder: (context) => Container(
                  width: 150,
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue,
                  child: const Text('Popover 2'),
                ),
                child: const Text('Trigger 2'),
              ),
            ],
          ),
        ),
      );

      // Open first popover
      await tester.tap(find.text('Trigger 1'));
      await tester.pumpAndSettle();

      expect(find.text('Popover 1'), findsOneWidget);
      expect(find.text('Popover 2'), findsNothing);

      // Tap outside to close first
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Popover 1'), findsNothing);

      // Open second popover
      await tester.tap(find.text('Trigger 2'));
      await tester.pumpAndSettle();

      expect(find.text('Popover 2'), findsOneWidget);

      handle.dispose();
    });
  });
}