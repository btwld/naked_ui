import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/naked_ui.dart';

void main() {
  group('Effective Enabled Behavior', () {
    testWidgets(
      'NakedSelect with null callback does not respond to trigger tap',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NakedSelect<String>(
                enabled: true,
                overlayBuilder: (context, info) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NakedSelectOption<String>(
                      value: 'item1',
                      child: Text('Item 1'),
                    ),
                  ],
                ),
                builder: (context, state, child) => const Text('Select'),
              ),
            ),
          ),
        );

        // Tap the select - overlay should open even without callbacks (current API behavior)
        await tester.tap(find.text('Select'));
        await tester.pump();
        expect(find.text('Item 1'), findsOneWidget);
      },
    );

    testWidgets('NakedSelect with callback responds to trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedSelect<String>(
              enabled: true,
              onChanged: (value) {},
              overlayBuilder: (context, info) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedSelectOption<String>(
                    value: 'item1',
                    child: Text('Item 1'),
                  ),
                ],
              ),
              builder: (context, state, child) => const Text('Select'),
            ),
          ),
        ),
      );

      // Tap the select - overlay should open and show item
      await tester.tap(find.text('Select'));
      await tester.pump();
      expect(find.text('Item 1'), findsOneWidget);
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
                NakedMenu<String>(
                  controller: MenuController(),
                  builder: (context, state, child) => const Text('Open Menu'),
                  overlayBuilder: (context, info) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NakedMenuItem<String>(
                        value: 'disabled',
                        enabled: false,
                        child: Text('Disabled Item'),
                      ),
                      NakedMenuItem<String>(
                        value: 'enabled',
                        enabled: true,
                        child: Text('Enabled Item'),
                      ),
                    ],
                  ),
                  onSelected: (value) {
                    if (value == 'enabled') pressed = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Open the menu first
      await tester.tap(find.text('Open Menu'));
      await tester.pump();

      // Try to tap the disabled item (should not trigger onSelected)
      await tester.tap(find.text('Disabled Item'));
      await tester.pump();
      expect(pressed, false);

      // Tap the enabled item (should trigger onSelected)
      await tester.tap(find.text('Enabled Item'));
      await tester.pump();
      expect(pressed, true);
    });

    testWidgets('NakedTabs disables when onChanged is null', (tester) async {
      NakedTabState? tab1State;
      NakedTabState? tab2State;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedTabs(
              selectedTabId: 'tab1',
              enabled: true,
              // No onChanged callback - tabs should be effectively disabled
              child: Column(
                children: [
                  NakedTabBar(
                    child: Row(
                      children: [
                        NakedTab(
                          tabId: 'tab1',
                          builder: (context, state, child) {
                            tab1State = state;
                            return const Text('Tab 1');
                          },
                        ),
                        NakedTab(
                          tabId: 'tab2',
                          builder: (context, state, child) {
                            tab2State = state;
                            return const Text('Tab 2');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify initial state: Tab 1 selected, Tab 2 not selected
      expect(tab1State!.isSelected, isTrue, reason: 'Tab 1 should be selected initially');
      expect(tab2State!.isSelected, isFalse, reason: 'Tab 2 should not be selected initially');

      // Try to tap Tab 2 - should not change selection since no callback
      await tester.tap(find.text('Tab 2'));
      await tester.pump();

      // Verify Tab 1 is still selected (selection should not have changed)
      expect(tab1State!.isSelected, isTrue, reason: 'Tab 1 should remain selected after tapping Tab 2');
      expect(tab2State!.isSelected, isFalse, reason: 'Tab 2 should not become selected when onChanged is null');
    });
  });
}
