import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

void main() {
  Widget _buildMaterialTabs({required int initialIndex}) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        initialIndex: initialIndex,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Tabs'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'A'),
                Tab(text: 'B'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              Center(child: Text('A body')),
              Center(child: Text('B body')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNakedTabs({required String selected}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: NakedTabs(
            selectedTabId: selected,
            onChanged: (_) {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedTabList(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      NakedTab(tabId: 'A', child: Text('A')),
                      SizedBox(width: 16),
                      NakedTab(tabId: 'B', child: Text('B')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const NakedTabPanel(tabId: 'A', child: Text('A body')),
                const NakedTabPanel(tabId: 'B', child: Text('B body')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('NakedTab Semantics', () {
    testWidgets('parity when first tab selected', (tester) async {
      final handle = tester.ensureSemantics();
      await expectSemanticsParity(
        tester: tester,
        material: _buildMaterialTabs(initialIndex: 0),
        naked: _buildNakedTabs(selected: 'A'),
        control: ControlType.tab,
      );
      handle.dispose();
    });

    testWidgets('parity when second tab selected', (tester) async {
      final handle = tester.ensureSemantics();
      await expectSemanticsParity(
        tester: tester,
        material: _buildMaterialTabs(initialIndex: 1),
        naked: _buildNakedTabs(selected: 'B'),
        control: ControlType.tab,
      );
      handle.dispose();
    });

    testWidgets('hover parity on first tab', (tester) async {
      final handle = tester.ensureSemantics();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await tester.pump();

      // Material hovered
      await tester.pumpWidget(_buildMaterialTabs(initialIndex: 0));
      // Hover over first tab labeled 'A'
      await mouse.moveTo(tester.getCenter(find.text('A').first));
      await tester.pump();
      final mat = summarizeMergedFromRoot(tester, control: ControlType.tab);

      // Naked hovered
      await tester.pumpWidget(_buildNakedTabs(selected: 'A'));
      await mouse.moveTo(tester.getCenter(find.text('A').first));
      await tester.pump();
      final nak = summarizeMergedFromRoot(tester, control: ControlType.tab);

      SemanticsSummary normalize(SemanticsSummary s) => SemanticsSummary(
        label: s.label,
        value: s.value,
        flags: s.flags
            .where(
              (f) =>
                  f != 'isButton' && f != 'isEnabled' && f != 'hasEnabledState',
            )
            .toSet(),
        actions: s.actions,
      );

      expect(normalize(nak), equals(normalize(mat)));
      await mouse.removePointer();
      handle.dispose();
    });
  });
}
