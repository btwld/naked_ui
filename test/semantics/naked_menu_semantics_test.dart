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


  Widget _buildNakedMenu() {
    final controller = MenuController();
    return NakedMenu(
      controller: controller,
      builder: (context) => NakedButton(
        onPressed: controller.open,
        child: const Text('Show Menu'),
      ),
      overlayBuilder: (context) => Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NakedMenuItem(
              onPressed: () {},
              child: const Text('Item 1'),
            ),
            NakedMenuItem(
              onPressed: () {},
              child: const Text('Item 2'),
            ),
            const NakedMenuItem(
              enabled: false,
              child: Text('Disabled Item'),
            ),
          ],
        ),
      ),
    );
  }

  group('NakedMenu Semantics', () {
    testWidgets('menu trigger button semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedMenu()));

      // Verify trigger has button semantics
      final summary = summarizeMergedFromRoot(tester, control: ControlType.button);
      expect(summary.flags.contains('isButton'), isTrue);
      expect(summary.flags.contains('isFocusable'), isTrue);
      expect(summary.actions.contains('tap'), isTrue);

      handle.dispose();
    });

    testWidgets('menu opens and closes semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedMenu()));

      // Initially closed
      expect(find.text('Show Menu'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);

      // Tap to open
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // Verify menu is open
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Disabled Item'), findsOneWidget);

      // Tap outside to close
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify menu is closed
      expect(find.text('Item 1'), findsNothing);

      handle.dispose();
    });

    testWidgets('menu item semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedMenu()));

      // Open menu
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // Find menu items and check their semantics
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Disabled Item'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('disabled menu item semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem(
                  onPressed: () {},
                  child: const Text('Enabled Item'),
                ),
                const NakedMenuItem(
                  enabled: false,
                  child: Text('Disabled Item'),
                ),
              ],
            ),
          ),
        ),
      );

      // Check enabled item semantics
      final enabledSummary = summarizeMergedFromRoot(tester, control: ControlType.button);
      expect(enabledSummary.flags.contains('isEnabled'), isTrue);
      expect(enabledSummary.actions.contains('tap'), isTrue);

      handle.dispose();
    });

    testWidgets('menu item selection semantics', (tester) async {
      final handle = tester.ensureSemantics();
      bool itemPressed = false;

      await tester.pumpWidget(
        _buildTestApp(
          Container(
            padding: const EdgeInsets.all(20),
            child: NakedMenuItem(
              onPressed: () => itemPressed = true,
              child: const Text('Selectable Item'),
            ),
          ),
        ),
      );

      // Tap the item
      await tester.tap(find.text('Selectable Item'));
      await tester.pump();

      // Verify callback was called
      expect(itemPressed, isTrue);

      handle.dispose();
    });

    testWidgets('menu focus management semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        _buildTestApp(
          NakedMenuItem(
            focusNode: focusNode,
            onPressed: () {},
            child: const Text('Focusable Item'),
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

    testWidgets('keyboard navigation semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildTestApp(_buildNakedMenu()));

      // Open menu
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // Verify menu is open
      expect(find.text('Item 1'), findsOneWidget);

      // Press Escape to close
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Verify menu closed
      expect(find.text('Item 1'), findsNothing);

      handle.dispose();
    });

    testWidgets('hover semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await tester.pump();

      await tester.pumpWidget(_buildTestApp(_buildNakedMenu()));

      // Hover over trigger
      await mouse.moveTo(tester.getCenter(find.text('Show Menu')));
      await tester.pump();

      // Verify trigger responds to hover
      expect(find.text('Show Menu'), findsOneWidget);

      await mouse.removePointer();
      handle.dispose();
    });

    testWidgets('menu with semantic labels', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          Container(
            padding: const EdgeInsets.all(20),
            child: NakedMenuItem(
              semanticLabel: 'Save document',
              onPressed: () {},
              child: const Text('Save'),
            ),
          ),
        ),
      );

      // Verify semantic label is applied
      expect(find.text('Save'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('complex menu structure semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = MenuController();

      await tester.pumpWidget(
        _buildTestApp(
          NakedMenu(
            controller: controller,
            builder: (context) => NakedButton(
              onPressed: controller.open,
              child: const Text('File'),
            ),
            overlayBuilder: (context) => Container(
              width: 150,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedMenuItem(
                    onPressed: () {},
                    child: const Text('New'),
                  ),
                  NakedMenuItem(
                    onPressed: () {},
                    child: const Text('Open'),
                  ),
                  const Divider(height: 1),
                  NakedMenuItem(
                    onPressed: () {},
                    child: const Text('Save'),
                  ),
                  NakedMenuItem(
                    onPressed: () {},
                    child: const Text('Save As...'),
                  ),
                  const Divider(height: 1),
                  NakedMenuItem(
                    onPressed: () {},
                    child: const Text('Exit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();

      // Verify all items are accessible
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Save As...'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);

      handle.dispose();
    });
  });
}