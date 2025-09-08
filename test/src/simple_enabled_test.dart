import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  group('Simple Enabled Test', () {
    testWidgets('NakedMenuItem with null callback', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            onTap: () => tapped = true,
            child: const NakedMenuItem(
              enabled: true,
              // No onPressed callback - should be effectively disabled
              child: Text('Menu Item'),
            ),
          ),
        ),
      ));

      // Try to tap - the gesture should not be processed
      await tester.tap(find.text('Menu Item'));
      await tester.pump();
      
      // Should have triggered the outer GestureDetector since disabled menu item doesn't consume taps
      expect(tapped, true);
    });

    testWidgets('NakedMenuItem with callback', (tester) async {
      bool itemPressed = false;
      bool outerTapped = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            onTap: () => outerTapped = true,
            child: NakedMenuItem(
              enabled: true,
              onPressed: () => itemPressed = true,
              child: const Text('Menu Item'),
            ),
          ),
        ),
      ));

      // Tap the menu item - it should respond since callback is provided
      await tester.tap(find.text('Menu Item'));
      await tester.pump();
      
      // The menu item should have been pressed
      expect(itemPressed, true);
      // The outer gesture should not have been triggered
      expect(outerTapped, false);
    });
  });
}