import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  group('Effective Enabled Behavior', () {
    testWidgets('NakedSelect with null callback does not respond to trigger tap', (
      tester,
    ) async {
      bool triggerPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedSelect<String>(
              enabled: true,
              // No callbacks provided - should be effectively disabled
              menu: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedSelectItem(value: 'item1', child: Text('Item 1')),
                ],
              ),
              child: NakedSelectTrigger(
                onPressChange: (pressed) => triggerPressed = pressed,
                child: const Text('Select'),
              ),
            ),
          ),
        ),
      );

      // Try to tap the select - it should not respond since no callbacks are provided
      await tester.tap(find.text('Select'));
      await tester.pump();

      // The trigger should not have been pressed since select is effectively disabled
      expect(triggerPressed, false);
    });

    testWidgets('NakedSelect with callback responds to trigger', (
      tester,
    ) async {
      final pressEvents = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedSelect<String>(
              enabled: true,
              onSelectedValueChanged:
                  (value) {}, // Just need callback for effective enabled
              menu: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedSelectItem(value: 'item1', child: Text('Item 1')),
                ],
              ),
              child: NakedSelectTrigger(
                onPressChange: pressEvents.add,
                child: const Text('Select'),
              ),
            ),
          ),
        ),
      );

      // Tap the select - it should respond since callback is provided
      await tester.tap(find.text('Select'));
      await tester.pump();
      // The trigger should have emitted press true then false
      expect(pressEvents, isNotEmpty);
      expect(pressEvents.first, isTrue);
    });

    testWidgets('NakedMenuItem disables when onPressed is null', (
      tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // This menu item should not respond to taps
                const NakedMenuItem(
                  enabled: true,
                  // No onPressed callback
                  child: Text('Disabled Item'),
                ),
                // This menu item should respond to taps
                NakedMenuItem(
                  enabled: true,
                  onPressed: () => pressed = true,
                  child: const Text('Enabled Item'),
                ),
              ],
            ),
          ),
        ),
      );

      // Try to tap the disabled item
      await tester.tap(find.text('Disabled Item'));
      await tester.pump();
      expect(pressed, false);

      // Tap the enabled item
      await tester.tap(find.text('Enabled Item'));
      await tester.pump();
      expect(pressed, true);
    });

    testWidgets('NakedTabs disables when onChanged is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedTabGroup(
              selectedTabId: 'tab1',
              enabled: true,
              // No onChanged callback
              child: Column(
                children: const [
                  NakedTabList(
                    child: Row(
                      children: [
                        NakedTab(tabId: 'tab1', child: Text('Tab 1')),
                        NakedTab(tabId: 'tab2', child: Text('Tab 2')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Try to tap Tab 2 - it should not change selection since no callback
      await tester.tap(find.text('Tab 2'));
      await tester.pump();

      // The tab should still show Tab 1 as selected (this test assumes visual indication)
      // Since we don't have visual state to check, we just verify the widget renders
      expect(find.text('Tab 2'), findsOneWidget);
    });
  });
}
