import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  group('Simple Enabled Test', () {
    testWidgets('Disabled NakedMenuItem does not select or close menu', (
      tester,
    ) async {
      bool selected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedMenu<String>(
              controller: MenuController(),
              builder: (context, state, child) => const Text('Open'),
              overlayBuilder: (context, info) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedMenuItem<String>(
                    value: 'item1',
                    enabled: false,
                    child: Text('Menu Item'),
                  ),
                ],
              ),
              onSelected: (_) => selected = true,
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.text('Menu Item'), findsOneWidget);

      // Tap disabled item
      await tester.tap(find.text('Menu Item'));
      await tester.pump();

      // Should not select and menu should remain open
      expect(selected, isFalse);
      expect(find.text('Menu Item'), findsOneWidget);
    });

    testWidgets('Enabled NakedMenuItem selects and closes menu', (
      tester,
    ) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedMenu<String>(
              controller: MenuController(),
              builder: (context, state, child) => const Text('Open'),
              overlayBuilder: (context, info) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedMenuItem<String>(
                    value: 'item1',
                    enabled: true,
                    child: Text('Menu Item'),
                  ),
                ],
              ),
              onSelected: (v) => selectedValue = v,
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.text('Menu Item'), findsOneWidget);

      // Tap the menu item - it should select and close
      await tester.tap(find.text('Menu Item'));
      await tester.pump();

      expect(selectedValue, 'item1');
      // Menu should be closed
      expect(find.text('Menu Item'), findsNothing);
    });
  });
}
