import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'helpers/simulate_hover.dart';



class _Counter extends StatefulWidget {
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Count: $_count'),
        ElevatedButton(onPressed: _increment, child: const Text('Increment')),
      ],
    );
  }
}

void main() {
  group('Basic Functionality', () {
    testWidgets('renders child widgets', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(
        const NakedTabGroup(
          selectedTabId: 'tab1',
          child: Column(
            children: [
              NakedTabList(
                child: Row(
                  children: [NakedTab(tabId: 'tab1', child: Text('Tab 1'))],
                ),
              ),
              NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
            ],
          ),
        ),
      );

      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Panel 1'), findsOneWidget);
    });

    testWidgets('shows selected tab panel', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(
        const NakedTabGroup(
          selectedTabId: 'tab2',
          child: Column(
            children: [
              NakedTabList(
                child: Row(
                  children: [
                    NakedTab(tabId: 'tab1', child: Text('Tab 1')),
                    NakedTab(tabId: 'tab2', child: Text('Tab 2')),
                  ],
                ),
              ),
              NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
              NakedTabPanel(tabId: 'tab2', child: Text('Panel 2')),
            ],
          ),
        ),
      );

      expect(find.text('Panel 1'), findsNothing);
      expect(find.text('Panel 2'), findsOneWidget);
    });

    testWidgets('changes selected tab on tap', (WidgetTester tester) async {
      String selectedTabId = 'tab1';
      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedTabGroup(
              selectedTabId: selectedTabId,
              onChanged: (id) =>
                  setState(() => selectedTabId = id),
              child: const Column(
                children: [
                  NakedTabList(
                    child: Row(
                      children: [
                        NakedTab(tabId: 'tab1', child: Text('Tab 1')),
                        NakedTab(tabId: 'tab2', child: Text('Tab 2')),
                      ],
                    ),
                  ),
                  NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
                  NakedTabPanel(tabId: 'tab2', child: Text('Panel 2')),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('Panel 1'), findsOneWidget);
      expect(find.text('Panel 2'), findsNothing);

      await tester.tap(find.text('Tab 2'));
      await tester.pump();

      expect(find.text('Panel 1'), findsNothing);
      expect(find.text('Panel 2'), findsOneWidget);
    });

    testWidgets('ignores tab selection when NakedTabs is disabled', (
      WidgetTester tester,
    ) async {
      String selectedTabId = 'tab1';
      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedTabGroup(
              selectedTabId: selectedTabId,
              enabled: false,
              onChanged: (id) =>
                  setState(() => selectedTabId = id),
              child: const Column(
                children: [
                  NakedTabList(
                    child: Row(
                      children: [
                        NakedTab(tabId: 'tab1', child: Text('Tab 1')),
                        NakedTab(tabId: 'tab2', child: Text('Tab 2')),
                      ],
                    ),
                  ),
                  NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
                  NakedTabPanel(tabId: 'tab2', child: Text('Panel 2')),
                ],
              ),
            );
          },
        ),
      );

      await tester.tap(find.text('Tab 2'));
      await tester.pump();

      expect(find.text('Panel 1'), findsOneWidget);
      expect(find.text('Panel 2'), findsNothing);
    });

    testWidgets('ignores tab selection when individual tab is disabled', (
      WidgetTester tester,
    ) async {
      String selectedTabId = 'tab1';
      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedTabGroup(
              selectedTabId: selectedTabId,
              onChanged: (id) =>
                  setState(() => selectedTabId = id),
              child: const Column(
                children: [
                  NakedTabList(
                    child: Row(
                      children: [
                        NakedTab(tabId: 'tab1', child: Text('Tab 1')),
                        NakedTab(
                          tabId: 'tab2',
                          enabled: false,
                          child: Text('Tab 2'),
                        ),
                        NakedTab(tabId: 'tab3', child: Text('Tab 3')),
                      ],
                    ),
                  ),
                  NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
                  NakedTabPanel(tabId: 'tab2', child: Text('Panel 2')),
                  NakedTabPanel(tabId: 'tab3', child: Text('Panel 3')),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('Panel 1'), findsOneWidget);
      expect(find.text('Panel 2'), findsNothing);
      expect(find.text('Panel 3'), findsNothing);

      await tester.tap(find.text('Tab 2'));
      await tester.pump();

      expect(find.text('Panel 1'), findsOneWidget);
      expect(find.text('Panel 2'), findsNothing);
      expect(find.text('Panel 3'), findsNothing);

      await tester.tap(find.text('Tab 3'));
      await tester.pump();

      expect(find.text('Panel 1'), findsNothing);
      expect(find.text('Panel 2'), findsNothing);
      expect(find.text('Panel 3'), findsOneWidget);
    });
  });

  group('State Callbacks', () {
    testWidgets('calls onHoverChange when hovered', (
      WidgetTester tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      bool isHovered = false;
      final key = GlobalKey();
      await tester.pumpMaterialWidget(
        Padding(
          padding: const EdgeInsets.all(1),
          child: NakedTabGroup(
            selectedTabId: 'tab1',
            child: Column(
              children: [
                NakedTabList(
                  child: Row(
                    children: [
                      NakedTab(
                        key: key,
                        tabId: 'tab1',
                        onHoverChange: (hovered) => isHovered = hovered,
                        child: const Text('Tab 1'),
                      ),
                    ],
                  ),
                ),
                const NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
              ],
            ),
          ),
        ),
      );

      await tester.simulateHover(
        key,
        onHover: () {
          expect(isHovered, true);
        },
      );

      expect(isHovered, false);
    });

    testWidgets('calls onPressChange on tap down/up', (
      WidgetTester tester,
    ) async {
      bool isPressed = false;
      await tester.pumpMaterialWidget(
        NakedTabGroup(
          selectedTabId: 'tab1',
          child: Column(
            children: [
              NakedTabList(
                child: Row(
                  children: [
                    NakedTab(
                      tabId: 'tab1',
                      onPressChange: (pressed) => isPressed = pressed,
                      child: const Text('Tab 1'),
                    ),
                  ],
                ),
              ),
              const NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
            ],
          ),
        ),
      );

      final gesture = await tester.press(find.byType(NakedTab));
      await tester.pump();
      expect(isPressed, true);

      await gesture.up();
      await tester.pump();
      expect(isPressed, false);
    });

    testWidgets('calls onFocusChange when focused/unfocused', (
      WidgetTester tester,
    ) async {
      bool isFocused = false;
      final focusNode = FocusNode();

      await tester.pumpMaterialWidget(
        NakedTabGroup(
          selectedTabId: 'tab1',
          child: Column(
            children: [
              NakedTabList(
                child: Row(
                  children: [
                    NakedTab(
                      tabId: 'tab1',
                      focusNode: focusNode,
                      onFocusChange: (focused) => isFocused = focused,
                      child: const Text('Tab 1'),
                    ),
                  ],
                ),
              ),
              const NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
            ],
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(isFocused, true);

      focusNode.unfocus();
      await tester.pump();
      expect(isFocused, false);
    });
  });

  group('Keyboard Interaction', () {
    testWidgets('activates tab with Space key', (WidgetTester tester) async {
      String selectedTabId = 'tab1';
      final focusNode = FocusNode();

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedTabGroup(
              selectedTabId: selectedTabId,
              onChanged: (id) =>
                  setState(() => selectedTabId = id),
              child: Column(
                children: [
                  NakedTabList(
                    child: Row(
                      children: [
                        const NakedTab(tabId: 'tab1', child: Text('Tab 1')),
                        NakedTab(
                          tabId: 'tab2',
                          focusNode: focusNode,
                          child: const Text('Tab 2'),
                        ),
                      ],
                    ),
                  ),
                  const NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
                  const NakedTabPanel(tabId: 'tab2', child: Text('Panel 2')),
                ],
              ),
            );
          },
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(selectedTabId, 'tab2');
    });

    testWidgets('navigates tabs with arrow keys in horizontal orientation', (
      WidgetTester tester,
    ) async {
      String selectedTabId = 'tab1';
      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return NakedTabGroup(
              selectedTabId: selectedTabId,
              onChanged: (id) =>
                  setState(() => selectedTabId = id),
              child: const Column(
                children: [
                  NakedTabList(
                    child: Row(
                      children: [
                        NakedTab(tabId: 'tab1', child: Text('Tab 1')),
                        NakedTab(tabId: 'tab2', child: Text('Tab 2')),
                        NakedTab(tabId: 'tab3', child: Text('Tab 3')),
                      ],
                    ),
                  ),
                  NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
                  NakedTabPanel(tabId: 'tab2', child: Text('Panel 2')),
                  NakedTabPanel(tabId: 'tab3', child: Text('Panel 3')),
                ],
              ),
            );
          },
        ),
      );

      // Focus the component
      await tester.tap(find.text('Tab 1'));
      await tester.pump();

      // Navigate to next tab with right arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selectedTabId, 'tab2');

      // Navigate to next tab with right arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selectedTabId, 'tab3');

      // Navigate to first tab with left arrow from last tab
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selectedTabId, 'tab2');
    });

    testWidgets(
      'navigates tabs with arrow keys in horizontal orientation with MaterialApp',
      (WidgetTester tester) async {
        String selectedTabId = 'tab1';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return NakedTabGroup(
                    selectedTabId: selectedTabId,
                    onChanged: (id) =>
                        setState(() => selectedTabId = id),
                    child: const Column(
                      children: [
                        NakedTabList(
                          child: Row(
                            children: [
                              NakedTab(tabId: 'tab1', child: Text('Tab 1')),
                              NakedTab(tabId: 'tab2', child: Text('Tab 2')),
                              NakedTab(tabId: 'tab3', child: Text('Tab 3')),
                            ],
                          ),
                        ),
                        NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
                        NakedTabPanel(tabId: 'tab2', child: Text('Panel 2')),
                        NakedTabPanel(tabId: 'tab3', child: Text('Panel 3')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Focus the component
        await tester.tap(find.text('Tab 1'));
        await tester.pump();

        // Navigate to next tab with right arrow
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(selectedTabId, 'tab2');

        // Navigate to next tab with right arrow
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(selectedTabId, 'tab3');

        // Navigate to first tab with left arrow from last tab
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(selectedTabId, 'tab2');
      },
    );
  });

}
