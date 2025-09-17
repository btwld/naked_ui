import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../../test_helpers.dart';

void main() {
  group('Tabs - Panel visibility and semantics exposure', () {
    testWidgets(
      'Only active panel is visible/exposed when maintainState=false',
      (tester) async {
        String selected = '1';
        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) => NakedTabGroup(
              selectedTabId: selected,
              onChanged: (id) => setState(() => selected = id),
              child: Column(
                children: const [
                  NakedTabList(
                    child: Row(
                      children: [
                        NakedTab(tabId: '1', child: Text('Tab 1')),
                        SizedBox(width: 8),
                        NakedTab(tabId: '2', child: Text('Tab 2')),
                      ],
                    ),
                  ),
                  NakedTabPanel(
                    tabId: '1',
                    maintainState: false,
                    child: Text('Panel 1'),
                  ),
                  NakedTabPanel(
                    tabId: '2',
                    maintainState: false,
                    child: Text('Panel 2'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Initially, only Panel 1 should be visible
        expect(find.text('Panel 1'), findsOneWidget);
        expect(find.text('Panel 2'), findsNothing);

        // Switch to Tab 2 by tapping
        await tester.tap(find.text('Tab 2'));
        await tester.pumpAndSettle();

        // Now only Panel 2 should be visible
        expect(find.text('Panel 2'), findsOneWidget);
        expect(find.text('Panel 1'), findsNothing);
      },
    );
  });
}
