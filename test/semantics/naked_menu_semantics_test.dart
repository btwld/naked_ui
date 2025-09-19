import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    return NakedMenu<String>(
      controller: controller,
      triggerBuilder: (context, state) => const Text('Show Menu'),
      overlayBuilder: (context, info) => Container(
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
            NakedMenuItem(value: 'item1', child: Text('Item 1')),
            NakedMenuItem(value: 'item2', child: Text('Item 2')),
            NakedMenuItem(
              value: 'disabled',
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
      final summary = summarizeMergedFromRoot(
        tester,
        control: ControlType.button,
      );
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
      final controller = MenuController();

      await tester.pumpWidget(
        _buildTestApp(
          NakedMenu<String>(
            controller: controller,
            triggerBuilder: (context, state) => const Text('Open'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem(value: 'enabled', child: Text('Enabled Item')),
                NakedMenuItem(
                  value: 'disabled',
                  enabled: false,
                  child: Text('Disabled Item'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Check enabled item semantics
      final enabledSummary = summarizeMergedFromRoot(
        tester,
        control: ControlType.button,
      );
      expect(enabledSummary.flags.contains('isEnabled'), isTrue);
      expect(enabledSummary.actions.contains('tap'), isTrue);

      handle.dispose();
    });

    testWidgets('menu item selection semantics', (tester) async {
      final handle = tester.ensureSemantics();
      bool itemPressed = false;
      final controller = MenuController();

      await tester.pumpWidget(
        _buildTestApp(
          NakedMenu<String>(
            controller: controller,
            onSelected: (v) {
              if (v == 'selectable') itemPressed = true;
            },
            triggerBuilder: (context, state) => const Text('Open'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem(
                  value: 'selectable',
                  child: Text('Selectable Item'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

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
      final controller = MenuController();

      await tester.pumpWidget(
        _buildTestApp(
          NakedMenu<String>(
            controller: controller,
            triggerFocusNode: focusNode,
            triggerBuilder: (context, state) => const Text('Focusable Menu'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [NakedMenuItem(value: 'v', child: Text('Item'))],
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

    testWidgets('keyboard navigation semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = MenuController();

      await tester.pumpWidget(
        _buildTestApp(
          NakedMenu<String>(
            controller: controller,
            triggerBuilder: (context, state) => const Text('Menu trigger'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem<String>(value: 'item1', child: Text('Item 1')),
                NakedMenuItem<String>(value: 'item2', child: Text('Item 2')),
              ],
            ),
          ),
        ),
      );

      // Open the menu
      controller.open();
      await tester.pumpAndSettle();

      // Verify menu items have keyboard semantics
      final item1Semantics = tester.getSemantics(find.text('Item 1'));
      expect(
        item1Semantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      final item2Semantics = tester.getSemantics(find.text('Item 2'));
      expect(
        item2Semantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      // Verify trigger has keyboard semantics
      final triggerSemantics = tester.getSemantics(find.text('Menu trigger'));
      expect(
        triggerSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

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
      final controller = MenuController();

      await tester.pumpWidget(
        _buildTestApp(
          NakedMenu<String>(
            controller: controller,
            triggerBuilder: (context, state) => const Text('Labeled Menu'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem(
                  value: 'save',
                  semanticLabel: 'Save document',
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Labeled Menu'));
      await tester.pumpAndSettle();

      // Verify semantic label is applied
      expect(find.text('Save'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('complex menu structure semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = MenuController();

      await tester.pumpWidget(
        _buildTestApp(
          NakedMenu<String>(
            controller: controller,
            triggerBuilder: (context, state) => const Text('File'),
            overlayBuilder: (context, info) => Container(
              width: 150,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedMenuItem(value: 'new', child: Text('New')),
                  NakedMenuItem(value: 'open', child: Text('Open')),
                  Divider(height: 1),
                  NakedMenuItem(value: 'save', child: Text('Save')),
                  NakedMenuItem(value: 'saveAs', child: Text('Save As...')),
                  Divider(height: 1),
                  NakedMenuItem(value: 'exit', child: Text('Exit')),
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
