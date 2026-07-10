import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

void main() {
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
                NakedTabBar(
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
                const NakedTabView(tabId: 'A', child: Text('A body')),
                const NakedTabView(tabId: 'B', child: Text('B body')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('NakedTab Semantics', () {
    testWidgets('first tab exposes explicit selected button contract', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildNakedTabs(selected: 'A'));

      final summary = summarizeMergedFromRoot(tester, control: ControlType.tab);
      expect(summary.label, 'A');
      expect(summary.flags, containsAll(['isButton', 'isSelected']));
      expect(summary.flags, containsAll(['hasEnabledState', 'isEnabled']));
      expect(summary.actions, contains('tap'));

      handle.dispose();
    });

    testWidgets('second tab exposes explicit selected button contract', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildNakedTabs(selected: 'B'));

      final tabB = tester.getSemantics(find.text('B'));
      final data = tabB.getSemanticsData();
      expect(data.label, 'B');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      handle.dispose();
    });

    testWidgets('explicit semanticLabel replaces content semantics', (
      tester,
    ) async {
      // Regression: matching content and semantic labels were announced twice.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedTabs(
              selectedTabId: 'overview',
              onChanged: (_) {},
              child: NakedTabBar(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    NakedTab(
                      tabId: 'overview',
                      semanticLabel: 'Overview',
                      child: Text('Overview'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // A duplicated raw label would fail this exact finder.
      final node = tester.getSemantics(find.bySemanticsLabel('Overview'));
      expect(node.label, 'Overview');

      // Replacing content semantics must retain the tab contract.
      final summary = summarizeMergedFromRoot(tester, control: ControlType.tab);
      expect(summary.label, 'Overview');
      expect(summary.flags, containsAll(['isButton', 'isSelected']));
      expect(summary.flags, containsAll(['hasEnabledState', 'isEnabled']));
      expect(summary.actions, contains('tap'));
      handle.dispose();
    });

    testWidgets('hovered selected tab keeps selected button contract', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await tester.pump();

      await tester.pumpWidget(_buildNakedTabs(selected: 'A'));
      await mouse.moveTo(tester.getCenter(find.text('A').first));
      await tester.pump();
      final nak = summarizeMergedFromRoot(tester, control: ControlType.tab);

      expect(nak.label, 'A');
      expect(nak.flags, contains('isButton'));
      expect(nak.flags, contains('isSelected'));
      expect(nak.actions, contains('tap'));

      await mouse.removePointer();
      handle.dispose();
    });
  });
}
