import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../../test_helpers.dart';

void main() {
  group('Tabs - View visibility and semantics exposure', () {
    testWidgets(
      'Only active view is visible/exposed when maintainState=false',
      (tester) async {
        String selected = '1';
        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) => NakedTabs(
              selectedTabId: selected,
              onChanged: (id) => setState(() => selected = id),
              child: Column(
                children: const [
                  NakedTabBar(
                    child: Row(
                      children: [
                        NakedTab(tabId: '1', child: Text('Tab 1')),
                        SizedBox(width: 8),
                        NakedTab(tabId: '2', child: Text('Tab 2')),
                      ],
                    ),
                  ),
                  NakedTabView(
                    tabId: '1',
                    maintainState: false,
                    child: Text('View 1'),
                  ),
                  NakedTabView(
                    tabId: '2',
                    maintainState: false,
                    child: Text('View 2'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Initially, only View 1 should be visible
        expect(find.text('View 1'), findsOneWidget);
        expect(find.text('View 2'), findsNothing);

        // Switch to Tab 2 by tapping
        await tester.tap(find.text('Tab 2'));
        await tester.pumpAndSettle();

        // Now only View 2 should be visible
        expect(find.text('View 2'), findsOneWidget);
        expect(find.text('View 1'), findsNothing);
      },
    );
  });
}
