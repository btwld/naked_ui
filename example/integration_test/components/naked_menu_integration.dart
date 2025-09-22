import 'package:example/api/naked_menu.0.dart' as menu_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedMenu Integration Tests', () {
    testWidgets('menu opens and closes via controller', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const menu_example.MyApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Find the trigger button
      final triggerButton = find.byType(NakedButton);
      expect(triggerButton, findsOneWidget);

      // Initially menu should be closed (no overlay content)
      expect(find.text('Edit'), findsNothing);

      // Tap to open menu
      await tester.tap(triggerButton);
      await tester.pumpAndSettle();

      // Menu should be open now
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('menu items respond to selection', (tester) async {
      final menuController = MenuController();
      String selectedItem = '';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedMenu<String>(
              controller: menuController,
              triggerBuilder: (context, state) => const Text('Open Menu'),
              overlayBuilder: (context, info) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NakedMenuItem<String>(
                        value: 'Item 1', child: Text('Item 1')),
                    NakedMenuItem<String>(
                        value: 'Item 2', child: Text('Item 2')),
                  ],
                ),
              ),
              onSelected: (value) {
                selectedItem = value;
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      // Tap menu item
      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();

      // Verify selection
      expect(selectedItem, 'Item 1');

      // Menu should be closed after selection
      expect(find.text('Item 1'), findsNothing);
    });

    testWidgets('menu onClose callback works', (tester) async {
      final menuController = MenuController();
      bool menuClosed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedMenu<String>(
              controller: menuController,
              onClose: () => menuClosed = true,
              triggerBuilder: (context, state) => const Text('Open Menu'),
              overlayBuilder: (context, info) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NakedMenuItem<String>(
                      value: 'content',
                      child: Text('Menu Content'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Menu Content'), findsOneWidget);

      // Close menu programmatically
      menuController.close();
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(menuClosed, isTrue);
      expect(find.text('Menu Content'), findsNothing);
    });

    testWidgets('menu responds to keyboard navigation', (tester) async {
      final menuController = MenuController();
      final menuKey = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedMenu<String>(
              key: menuKey,
              controller: menuController,
              triggerBuilder: (context, state) => const Text('Open Menu'),
              overlayBuilder: (context, info) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NakedMenuItem<String>(
                      value: 'content',
                      child: Text('Menu Content'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Menu Content'), findsOneWidget);

      // Test keyboard navigation - Escape should close menu
      await tester.testKeyboardActivation(find.byKey(menuKey));
      await tester.pumpAndSettle();

      // Menu should still be open (keyboard activation tests Enter, not Escape)
      expect(find.text('Menu Content'), findsOneWidget);
    });

    testWidgets('menu closes on outside tap when enabled', (tester) async {
      final menuController = MenuController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              children: [
                NakedMenu<String>(
                  controller: menuController,
                  consumeOutsideTaps: true,
                  triggerBuilder: (context, state) => const Text('Open Menu'),
                  overlayBuilder: (context, info) => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NakedMenuItem<String>(
                          value: 'content',
                          child: Text('Menu Content'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
                const Text('Outside Area'),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Menu Content'), findsOneWidget);

      // Tap outside the menu
      await tester.tap(find.text('Outside Area'));
      await tester.pumpAndSettle();

      // Menu should close
      expect(find.text('Menu Content'), findsNothing);
    });

    testWidgets('works with example app complex interaction', (tester) async {
      // Test the full example with real menu items and snackbar
      await tester.pumpWidget(const menu_example.MyApp());
      await tester.pump(const Duration(milliseconds: 100));

      final triggerButton = find.byType(NakedButton);

      // Open menu
      await tester.tap(triggerButton);
      await tester.pumpAndSettle();

      // Find and tap a menu item
      final menuItem = find.text('Edit');
      expect(menuItem, findsOneWidget);

      await tester.tap(menuItem);
      await tester.pumpAndSettle();

      // Check that snackbar appears (from the example's onPressed callback)
      expect(find.text('Selected: edit'), findsOneWidget);

      // Menu should be closed after item selection
      expect(find.text('Edit'), findsNothing);
    });
  });
}
