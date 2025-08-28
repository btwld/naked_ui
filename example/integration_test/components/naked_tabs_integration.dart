import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:example/api/naked_tabs.0.dart' as tabs_example;

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('NakedTabs Integration Tests', () {
    testWidgets('tabs change panel visibility correctly', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const tabs_example.MyApp());
      await tester.pumpAndSettle();
      
      final tabGroupFinder = find.byType(NakedTabGroup);
      expect(tabGroupFinder, findsOneWidget);
      
      // Find all tabs
      final lightTab = find.text('Light');
      final darkTab = find.text('Dark');
      final systemTab = find.text('System');
      
      expect(lightTab, findsOneWidget);
      expect(darkTab, findsOneWidget);
      expect(systemTab, findsOneWidget);
      
      // Verify initial state - Light tab content should be visible
      expect(find.text('Content for Tab 1'), findsOneWidget);
      expect(find.text('Content for Tab 2'), findsNothing);
      expect(find.text('Content for Tab 3'), findsNothing);
      
      // Click Dark tab
      await tester.tap(darkTab);
      await tester.pumpAndSettle();
      
      // Verify Dark tab content is now visible
      expect(find.text('Content for Tab 1'), findsNothing);
      expect(find.text('Content for Tab 2'), findsOneWidget);
      expect(find.text('Content for Tab 3'), findsNothing);
      
      // Click System tab
      await tester.tap(systemTab);
      await tester.pumpAndSettle();
      
      // Verify System tab content is now visible
      expect(find.text('Content for Tab 1'), findsNothing);
      expect(find.text('Content for Tab 2'), findsNothing);
      expect(find.text('Content for Tab 3'), findsOneWidget);
      
      // Click Light tab again
      await tester.tap(lightTab);
      await tester.pumpAndSettle();
      
      // Verify Light tab content is visible again
      expect(find.text('Content for Tab 1'), findsOneWidget);
      expect(find.text('Content for Tab 2'), findsNothing);
      expect(find.text('Content for Tab 3'), findsNothing);
    });
    
    testWidgets('tabs respond to keyboard navigation', (tester) async {
      final lightTabKey = UniqueKey();
      final darkTabKey = UniqueKey();
      final systemTabKey = UniqueKey();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: _StatefulTabsWidget(
              lightTabKey: lightTabKey,
              darkTabKey: darkTabKey,
              systemTabKey: systemTabKey,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Test keyboard activation on tabs
      await tester.testKeyboardActivation(find.byKey(darkTabKey));
      await tester.pumpAndSettle();
      
      // Test tab order navigation
      await tester.verifyTabOrder([
        find.byKey(lightTabKey),
        find.byKey(darkTabKey),
        find.byKey(systemTabKey),
      ]);
    });
    
    testWidgets('tab state callbacks work correctly', (tester) async {
      final tabKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool isHovered = false;
      bool isFocused = false;
      bool isPressed = false;
      Set<WidgetState>? lastStates;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: _StatefulTabsWidget(
              customTab: NakedTab(
                key: tabKey,
                tabId: 'test',
                focusNode: focusNode,
                onHoverChange: (hovered) => isHovered = hovered,
                onFocusChange: (focused) => isFocused = focused,
                onPressChange: (pressed) => isPressed = pressed,
                onStatesChange: (states) => lastStates = states,
                child: const Text('Test Tab'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Test hover state
      await tester.simulateHover(tabKey, onHover: () {
        expect(isHovered, isTrue);
        if (lastStates != null) {
          tester.expectWidgetStates(lastStates!, expectHovered: true, expectSelected: true);
        }
      });
      
      // Test focus state
      focusNode.requestFocus();
      await tester.pump();
      expect(isFocused, isTrue);
      
      // Test press state
      await tester.simulatePress(tabKey, onPressed: () {
        expect(isPressed, isTrue);
        if (lastStates != null) {
          tester.expectWidgetStates(lastStates!, expectPressed: true, expectSelected: true);
        }
      });
    });
    
    testWidgets('tab builder method works with states', (tester) async {
      final tabKey = UniqueKey();
      bool isSelected = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: _StatefulTabsWidget(
              customTab: NakedTab(
                key: tabKey,
                tabId: 'test',
                builder: (context, states, child) {
                  isSelected = states.isSelected;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: states.isSelected ? Colors.blue : Colors.grey,
                      border: Border.all(
                        color: states.isHovered ? Colors.red : Colors.black,
                        width: states.isPressed ? 4 : 2,
                      ),
                    ),
                    child: child,
                  );
                },
                child: const Text('Builder Tab'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Test that builder receives states correctly
      expect(isSelected, isTrue); // Tab should be selected by default in our helper
      
      // Test hover state changes styling
      await tester.simulateHover(tabKey);
      await tester.pump();
      
      // Verify the styled container exists
      final containerFinder = find.descendant(
        of: find.byKey(tabKey),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);
    });
    
    testWidgets('tab panels show/hide based on selection', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: _StatefulTabsWidget(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Initially tab1 should be selected
      expect(find.text('Light Content'), findsOneWidget);
      expect(find.text('Dark Content'), findsNothing);
      expect(find.text('System Content'), findsNothing);
      
      // Click dark tab
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      
      // Now dark tab content should be visible
      expect(find.text('Light Content'), findsNothing);
      expect(find.text('Dark Content'), findsOneWidget);
      expect(find.text('System Content'), findsNothing);
    });
    
    testWidgets('complex tabs layout works correctly', (tester) async {
      // Test the full example with styling and state
      await tester.pumpWidget(const tabs_example.MyApp());
      await tester.pumpAndSettle();
      
      // Find the tab list container
      final tabListFinder = find.byType(NakedTabList);
      expect(tabListFinder, findsOneWidget);
      
      // Find all tab panels
      final tabPanelFinders = find.byType(NakedTabPanel);
      expect(tabPanelFinders, findsNWidgets(3));
      
      // Test interaction with styled tabs
      final tabs = ['Light', 'Dark', 'System'];
      final expectedContents = [
        'Content for Tab 1',
        'Content for Tab 2', 
        'Content for Tab 3'
      ];
      
      for (int i = 0; i < tabs.length; i++) {
        // Click tab
        await tester.tap(find.text(tabs[i]));
        await tester.pumpAndSettle();
        
        // Verify correct panel is visible
        expect(find.text(expectedContents[i]), findsOneWidget);
        
        // Verify other panels are hidden
        for (int j = 0; j < expectedContents.length; j++) {
          if (j != i) {
            expect(find.text(expectedContents[j]), findsNothing);
          }
        }
      }
    });
  });
}

class _StatefulTabsWidget extends StatefulWidget {
  const _StatefulTabsWidget({
    this.lightTabKey,
    this.darkTabKey,
    this.systemTabKey,
    this.customTab,
  });
  
  final Key? lightTabKey;
  final Key? darkTabKey;
  final Key? systemTabKey;
  final Widget? customTab;

  @override
  State<_StatefulTabsWidget> createState() => _StatefulTabsWidgetState();
}

class _StatefulTabsWidgetState extends State<_StatefulTabsWidget> {
  String selectedTabId = 'light';
  
  @override
  void initState() {
    super.initState();
    // If using a custom tab, set the selectedTabId to 'test' to match the custom tab's tabId
    if (widget.customTab != null) {
      selectedTabId = 'test';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.customTab != null) {
      return NakedTabGroup(
        selectedTabId: selectedTabId,
        onChanged: (tabId) => setState(() => selectedTabId = tabId),
        child: widget.customTab!,
      );
    }
    
    return NakedTabGroup(
      selectedTabId: selectedTabId,
      onChanged: (tabId) => setState(() => selectedTabId = tabId),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NakedTabList(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedTab(
                  key: widget.lightTabKey,
                  tabId: 'light',
                  child: const Text('Light'),
                ),
                NakedTab(
                  key: widget.darkTabKey,
                  tabId: 'dark',
                  child: const Text('Dark'),
                ),
                NakedTab(
                  key: widget.systemTabKey,
                  tabId: 'system',
                  child: const Text('System'),
                ),
              ],
            ),
          ),
          const NakedTabPanel(
            tabId: 'light',
            child: Text('Light Content'),
          ),
          const NakedTabPanel(
            tabId: 'dark',
            child: Text('Dark Content'),
          ),
          const NakedTabPanel(
            tabId: 'system',
            child: Text('System Content'),
          ),
        ],
      ),
    );
  }
}