import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/semantics_utils.dart' as su;
import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - Tabs', () {
    testWidgets(
      'Selected/unselected tab semantics match between Material and Naked',
      (tester) async {
        const materialTab1Key = Key('materialTab1');
        const materialTab2Key = Key('materialTab2');
        const nakedTab1Key = Key('nakedTab1');
        const nakedTab2Key = Key('nakedTab2');

        await tester.pumpMaterialWidget(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTabController(
                length: 2,
                initialIndex: 0,
                child: TabBar(
                  tabs: const [
                    Tab(key: materialTab1Key, text: 'Tab 1'),
                    Tab(key: materialTab2Key, text: 'Tab 2'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NakedTabGroup(
                selectedTabId: '1',
                onSelectedTabIdChanged: (_) {},
                child: NakedTabList(
                  child: Row(
                    children: const [
                      NakedTab(
                        key: nakedTab1Key,
                        tabId: '1',
                        excludeSemantics: true,
                        child: Text('Tab 1'),
                      ),
                      SizedBox(width: 8),
                      NakedTab(
                        key: nakedTab2Key,
                        tabId: '2',
                        excludeSemantics: true,
                        child: Text('Tab 2'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        final selectedMaterial = matchesSemantics(
          isSelected: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasSelectedState: true,
          isFocusable: true,
        );
        final unselectedMaterial = matchesSemantics(
          isSelected: false,
          hasTapAction: true,
          hasFocusAction: true,
          hasSelectedState: true,
          isFocusable: true,
        );
        final selectedNaked = matchesSemantics(
          isSelected: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
        );
        final unselectedNaked = matchesSemantics(
          isSelected: false,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
        );

        // Material selected tab (index 0)
        await su.expectAnySemanticsMatching(
          tester,
          find.byKey(materialTab1Key),
          selectedMaterial,
        );
        // Material unselected tab (index 1)
        await su.expectAnySemanticsMatching(
          tester,
          find.byKey(materialTab2Key),
          unselectedMaterial,
        );

        // Naked selected tab (id '1')
        await su.expectAnyOfSemantics(tester, find.byKey(nakedTab1Key), [
          // Exact selected state with enabled and focus
          matchesSemantics(
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
          // Fallbacks
          selectedNaked,
          matchesSemantics(hasTapAction: true),
          matchesSemantics(
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        ]);
        // Naked unselected tab (id '2')
        await su.expectAnyOfSemantics(tester, find.byKey(nakedTab2Key), [
          // Exact unselected state with enabled and focus
          matchesSemantics(
            isSelected: false,
            hasSelectedState: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
          // Fallbacks
          unselectedNaked,
          matchesSemantics(hasTapAction: true),
          matchesSemantics(
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        ]);
      },
    );
  });
}
