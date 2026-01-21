/// ARIA Focus Behavior Tests for NakedTabs
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
/// - Tab (into tablist): Focus lands on the **selected tab**; if none selected, first tab
/// - Tab (from tablist): Focus moves to the **tab panel** content (or next focusable outside)
/// - Arrow Left/Up: Moves focus to previous tab
/// - Arrow Right/Down: Moves focus to next tab
/// - Home: Moves focus to first tab
/// - End: Moves focus to last tab
/// - Space/Enter: Activates the focused tab (in manual activation mode)
///
/// Activation Modes:
/// - **Automatic**: Moving focus with arrows immediately activates (shows) the tab panel
/// - **Manual**: Arrow keys only move focus; user must press Space/Enter to activate
///
/// Focus Management:
/// - Uses **roving `tabindex`** within tablist
/// - Tablist is ONE tab stop
/// - Tab panels should be focusable only if they contain no focusable content
/// - Arrow keys should wrap from last tab to first (and vice versa)
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedTabs ARIA Focus Behavior', () {
    group('Tab Navigation - Single Tab Stop for Tablist', () {
      testWidgets('Tab enters tablist on selected tab', (
        WidgetTester tester,
      ) async {
        final focusNodeBefore = FocusNode(debugLabel: 'before');
        final focusNodeAfter = FocusNode(debugLabel: 'after');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNodeBefore),
              NakedTabs(
                selectedTabId: 'tab2',
                onChanged: (_) {},
                child: Column(
                  children: [
                    NakedTabBar(
                      child: Row(
                        children: const [
                          NakedTab(tabId: 'tab1', child: Text('Tab 1')),
                          NakedTab(tabId: 'tab2', child: Text('Tab 2')),
                          NakedTab(tabId: 'tab3', child: Text('Tab 3')),
                        ],
                      ),
                    ),
                    const NakedTabView(tabId: 'tab1', child: Text('Content 1')),
                    const NakedTabView(tabId: 'tab2', child: Text('Content 2')),
                    const NakedTabView(tabId: 'tab3', child: Text('Content 3')),
                  ],
                ),
              ),
              TextField(focusNode: focusNodeAfter),
            ],
          ),
        );

        // Focus the first element
        focusNodeBefore.requestFocus();
        await tester.pump();
        expect(focusNodeBefore.hasFocus, isTrue);

        // Tab should enter the tablist
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Focus should be within the tablist (on selected tab)
        expect(focusNodeBefore.hasFocus, isFalse);
        expect(focusNodeAfter.hasFocus, isFalse);

        focusNodeBefore.dispose();
        focusNodeAfter.dispose();
      });
    });

    group('Arrow Key Navigation', () {
      testWidgets('Arrow Right moves focus to next tab', (
        WidgetTester tester,
      ) async {
        String selectedTabId = 'tab1';
        final tab1FocusNode = FocusNode(debugLabel: 'tab1');
        final tab2FocusNode = FocusNode(debugLabel: 'tab2');
        final tab3FocusNode = FocusNode(debugLabel: 'tab3');

        addTearDown(() {
          tab1FocusNode.dispose();
          tab2FocusNode.dispose();
          tab3FocusNode.dispose();
        });

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedTabs(
                selectedTabId: selectedTabId,
                onChanged: (id) => setState(() => selectedTabId = id),
                child: Column(
                  children: [
                    NakedTabBar(
                      child: Row(
                        children: [
                          NakedTab(
                            tabId: 'tab1',
                            autofocus: true,
                            focusNode: tab1FocusNode,
                            child: Text('Tab 1'),
                          ),
                          NakedTab(
                            tabId: 'tab2',
                            focusNode: tab2FocusNode,
                            child: Text('Tab 2'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Right should move to next tab and select it (automatic activation)
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(selectedTabId, 'tab2');
        expect(tab2FocusNode.hasFocus, isTrue);
      });

      testWidgets('Arrow Left moves focus to previous tab', (
        WidgetTester tester,
      ) async {
        String selectedTabId = 'tab2';
        final tab1FocusNode = FocusNode(debugLabel: 'tab1');
        final tab2FocusNode = FocusNode(debugLabel: 'tab2');
        final tab3FocusNode = FocusNode(debugLabel: 'tab3');

        addTearDown(() {
          tab1FocusNode.dispose();
          tab2FocusNode.dispose();
          tab3FocusNode.dispose();
        });

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedTabs(
                selectedTabId: selectedTabId,
                onChanged: (id) => setState(() => selectedTabId = id),
                child: Column(
                  children: [
                    NakedTabBar(
                      child: Row(
                        children: [
                          NakedTab(
                            tabId: 'tab1',
                            focusNode: tab1FocusNode,
                            child: Text('Tab 1'),
                          ),
                          NakedTab(
                            tabId: 'tab2',
                            autofocus: true,
                            focusNode: tab2FocusNode,
                            child: Text('Tab 2'),
                          ),
                          NakedTab(
                            tabId: 'tab3',
                            focusNode: tab3FocusNode,
                            child: Text('Tab 3'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Left should move to previous tab and select it
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();

        expect(selectedTabId, 'tab1');
        expect(tab1FocusNode.hasFocus, isTrue);
      });

      testWidgets('Arrow Down moves focus to next tab (vertical orientation)', (
        WidgetTester tester,
      ) async {
        String selectedTabId = 'tab1';
        final tab1FocusNode = FocusNode(debugLabel: 'tab1');
        final tab2FocusNode = FocusNode(debugLabel: 'tab2');

        addTearDown(() {
          tab1FocusNode.dispose();
          tab2FocusNode.dispose();
        });

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedTabs(
                selectedTabId: selectedTabId,
                onChanged: (id) => setState(() => selectedTabId = id),
                orientation: Axis.vertical,
                child: Row(
                  children: [
                    NakedTabBar(
                      child: Column(
                        children: [
                          NakedTab(
                            tabId: 'tab1',
                            autofocus: true,
                            focusNode: tab1FocusNode,
                            child: Text('Tab 1'),
                          ),
                          NakedTab(
                            tabId: 'tab2',
                            focusNode: tab2FocusNode,
                            child: Text('Tab 2'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Down should move to next tab in vertical orientation
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(selectedTabId, 'tab2');
        expect(tab2FocusNode.hasFocus, isTrue);
      });

      testWidgets(
        'Arrow Up moves focus to previous tab (vertical orientation)',
        (WidgetTester tester) async {
          String selectedTabId = 'tab2';
          final tab1FocusNode = FocusNode(debugLabel: 'tab1');
          final tab2FocusNode = FocusNode(debugLabel: 'tab2');
          final tab3FocusNode = FocusNode(debugLabel: 'tab3');

          addTearDown(() {
            tab1FocusNode.dispose();
            tab2FocusNode.dispose();
            tab3FocusNode.dispose();
          });

          await tester.pumpMaterialWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return NakedTabs(
                  selectedTabId: selectedTabId,
                  onChanged: (id) => setState(() => selectedTabId = id),
                  orientation: Axis.vertical,
                  child: Row(
                    children: [
                      NakedTabBar(
                        child: Column(
                          children: [
                            NakedTab(
                              tabId: 'tab1',
                              focusNode: tab1FocusNode,
                              child: Text('Tab 1'),
                            ),
                            NakedTab(
                              tabId: 'tab2',
                              autofocus: true,
                              focusNode: tab2FocusNode,
                              child: Text('Tab 2'),
                            ),
                            NakedTab(
                              tabId: 'tab3',
                              focusNode: tab3FocusNode,
                              child: Text('Tab 3'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );

          await tester.pump();

          // Arrow Up should move to previous tab in vertical orientation
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pump();

          expect(selectedTabId, 'tab1');
          expect(tab1FocusNode.hasFocus, isTrue);
        },
      );

      testWidgets('Arrow Down wraps from last tab to first tab (vertical)', (
        WidgetTester tester,
      ) async {
        String selectedTabId = 'tab3';
        final tab1FocusNode = FocusNode(debugLabel: 'tab1');
        final tab2FocusNode = FocusNode(debugLabel: 'tab2');
        final tab3FocusNode = FocusNode(debugLabel: 'tab3');

        addTearDown(() {
          tab1FocusNode.dispose();
          tab2FocusNode.dispose();
          tab3FocusNode.dispose();
        });

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedTabs(
                selectedTabId: selectedTabId,
                onChanged: (id) => setState(() => selectedTabId = id),
                orientation: Axis.vertical,
                child: Row(
                  children: [
                    NakedTabBar(
                      child: Column(
                        children: [
                          NakedTab(
                            tabId: 'tab1',
                            focusNode: tab1FocusNode,
                            child: Text('Tab 1'),
                          ),
                          NakedTab(
                            tabId: 'tab2',
                            focusNode: tab2FocusNode,
                            child: Text('Tab 2'),
                          ),
                          NakedTab(
                            tabId: 'tab3',
                            autofocus: true,
                            focusNode: tab3FocusNode,
                            child: Text('Tab 3'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Down on last tab should wrap to first tab
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(selectedTabId, 'tab1');
        expect(tab1FocusNode.hasPrimaryFocus, isTrue);
      });

      testWidgets('Arrow Up wraps from first tab to last tab (vertical)', (
        WidgetTester tester,
      ) async {
        String selectedTabId = 'tab1';
        final tab1FocusNode = FocusNode(debugLabel: 'tab1');
        final tab2FocusNode = FocusNode(debugLabel: 'tab2');
        final tab3FocusNode = FocusNode(debugLabel: 'tab3');

        addTearDown(() {
          tab1FocusNode.dispose();
          tab2FocusNode.dispose();
          tab3FocusNode.dispose();
        });

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedTabs(
                selectedTabId: selectedTabId,
                onChanged: (id) => setState(() => selectedTabId = id),
                orientation: Axis.vertical,
                child: Row(
                  children: [
                    NakedTabBar(
                      child: Column(
                        children: [
                          NakedTab(
                            tabId: 'tab1',
                            autofocus: true,
                            focusNode: tab1FocusNode,
                            child: Text('Tab 1'),
                          ),
                          NakedTab(
                            tabId: 'tab2',
                            focusNode: tab2FocusNode,
                            child: Text('Tab 2'),
                          ),
                          NakedTab(
                            tabId: 'tab3',
                            focusNode: tab3FocusNode,
                            child: Text('Tab 3'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Up on first tab should wrap to last tab
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(selectedTabId, 'tab3');
        expect(tab3FocusNode.hasFocus, isTrue);
      });

      testWidgets('Arrow Left wraps from first tab to last tab (horizontal)', (
        WidgetTester tester,
      ) async {
        String selectedTabId = 'tab1';
        final tab1FocusNode = FocusNode(debugLabel: 'tab1');
        final tab2FocusNode = FocusNode(debugLabel: 'tab2');
        final tab3FocusNode = FocusNode(debugLabel: 'tab3');

        addTearDown(() {
          tab1FocusNode.dispose();
          tab2FocusNode.dispose();
          tab3FocusNode.dispose();
        });

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedTabs(
                selectedTabId: selectedTabId,
                onChanged: (id) => setState(() => selectedTabId = id),
                child: Column(
                  children: [
                    NakedTabBar(
                      child: Row(
                        children: [
                          NakedTab(
                            tabId: 'tab1',
                            autofocus: true,
                            focusNode: tab1FocusNode,
                            child: Text('Tab 1'),
                          ),
                          NakedTab(
                            tabId: 'tab2',
                            focusNode: tab2FocusNode,
                            child: Text('Tab 2'),
                          ),
                          NakedTab(
                            tabId: 'tab3',
                            focusNode: tab3FocusNode,
                            child: Text('Tab 3'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Left on first tab should wrap to last tab
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();

        expect(selectedTabId, 'tab3');
        expect(tab3FocusNode.hasFocus, isTrue);
      });

      testWidgets('Arrow Right wraps from last tab to first tab (horizontal)', (
        WidgetTester tester,
      ) async {
        String selectedTabId = 'tab3';
        final tab1FocusNode = FocusNode(debugLabel: 'tab1');
        final tab2FocusNode = FocusNode(debugLabel: 'tab2');
        final tab3FocusNode = FocusNode(debugLabel: 'tab3');

        addTearDown(() {
          tab1FocusNode.dispose();
          tab2FocusNode.dispose();
          tab3FocusNode.dispose();
        });

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedTabs(
                selectedTabId: selectedTabId,
                onChanged: (id) => setState(() => selectedTabId = id),
                child: Column(
                  children: [
                    NakedTabBar(
                      child: Row(
                        children: [
                          NakedTab(
                            tabId: 'tab1',
                            focusNode: tab1FocusNode,
                            child: Text('Tab 1'),
                          ),
                          NakedTab(
                            tabId: 'tab2',
                            focusNode: tab2FocusNode,
                            child: Text('Tab 2'),
                          ),
                          NakedTab(
                            tabId: 'tab3',
                            autofocus: true,
                            focusNode: tab3FocusNode,
                            child: Text('Tab 3'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Right on last tab should wrap to first tab
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(selectedTabId, 'tab1');
        expect(tab1FocusNode.hasFocus, isTrue);
      });
    });

    group('Home/End Keys', () {
      testWidgets('Home moves focus to first tab', (WidgetTester tester) async {
        String selectedTabId = 'tab3';

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedTabs(
                selectedTabId: selectedTabId,
                onChanged: (id) => setState(() => selectedTabId = id),
                child: Column(
                  children: [
                    NakedTabBar(
                      child: Row(
                        children: const [
                          NakedTab(tabId: 'tab1', child: Text('Tab 1')),
                          NakedTab(tabId: 'tab2', child: Text('Tab 2')),
                          NakedTab(
                            tabId: 'tab3',
                            autofocus: true,
                            child: Text('Tab 3'),
                          ),
                        ],
                      ),
                    ),
                    const NakedTabView(tabId: 'tab1', child: Text('Content 1')),
                    const NakedTabView(tabId: 'tab2', child: Text('Content 2')),
                    const NakedTabView(tabId: 'tab3', child: Text('Content 3')),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();

        expect(selectedTabId, 'tab1');
      });

      testWidgets('End moves focus to last tab', (WidgetTester tester) async {
        String selectedTabId = 'tab1';

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedTabs(
                selectedTabId: selectedTabId,
                onChanged: (id) => setState(() => selectedTabId = id),
                child: Column(
                  children: [
                    NakedTabBar(
                      child: Row(
                        children: const [
                          NakedTab(
                            tabId: 'tab1',
                            autofocus: true,
                            child: Text('Tab 1'),
                          ),
                          NakedTab(tabId: 'tab2', child: Text('Tab 2')),
                          NakedTab(tabId: 'tab3', child: Text('Tab 3')),
                        ],
                      ),
                    ),
                    const NakedTabView(tabId: 'tab1', child: Text('Content 1')),
                    const NakedTabView(tabId: 'tab2', child: Text('Content 2')),
                    const NakedTabView(tabId: 'tab3', child: Text('Content 3')),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();

        expect(selectedTabId, 'tab3');
      });
    });

    group('Focus State Reporting', () {
      testWidgets('onFocusChange is called when tab gains focus', (
        WidgetTester tester,
      ) async {
        bool? focusState;

        await tester.pumpMaterialWidget(
          NakedTabs(
            selectedTabId: 'tab1',
            onChanged: (_) {},
            child: Column(
              children: [
                NakedTabBar(
                  child: Row(
                    children: [
                      NakedTab(
                        tabId: 'tab1',
                        autofocus: true,
                        onFocusChange: (focused) => focusState = focused,
                        child: const Text('Tab 1'),
                      ),
                      const NakedTab(tabId: 'tab2', child: Text('Tab 2')),
                    ],
                  ),
                ),
                const NakedTabView(tabId: 'tab1', child: Text('Content 1')),
                const NakedTabView(tabId: 'tab2', child: Text('Content 2')),
              ],
            ),
          ),
        );

        await tester.pump();
        expect(focusState, isTrue);
      });
    });

    group('Disabled Tab Behavior', () {
      testWidgets('Disabled tab is skipped in navigation', (
        WidgetTester tester,
      ) async {
        String selectedTabId = 'tab1';

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedTabs(
                selectedTabId: selectedTabId,
                onChanged: (id) => setState(() => selectedTabId = id),
                child: Column(
                  children: [
                    NakedTabBar(
                      child: Row(
                        children: const [
                          NakedTab(
                            tabId: 'tab1',
                            autofocus: true,
                            child: Text('Tab 1'),
                          ),
                          NakedTab(
                            tabId: 'tab2',
                            enabled: false,
                            child: Text('Tab 2 (disabled)'),
                          ),
                          NakedTab(tabId: 'tab3', child: Text('Tab 3')),
                        ],
                      ),
                    ),
                    const NakedTabView(tabId: 'tab1', child: Text('Content 1')),
                    const NakedTabView(tabId: 'tab2', child: Text('Content 2')),
                    const NakedTabView(tabId: 'tab3', child: Text('Content 3')),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pump();

        // Arrow Right should skip disabled tab2 and go to tab3
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(selectedTabId, 'tab3');
      });
    });
  });
}
