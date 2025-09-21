import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('NakedAccordion Semantics', () {
    testWidgets('collapsed strict parity vs ExpansionTile', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          Material(
            child: ListView(
              shrinkWrap: true,
              children: const [
                ExpansionTile(title: Text('Header'), children: [Text('Body')]),
              ],
            ),
          ),
        ),
      );

      final mNode = tester.getSemantics(find.bySemanticsLabel('Header'));
      final strict = buildStrictMatcherFromSemanticsData(
        mNode.getSemanticsData(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedAccordion<String>(
            controller: NakedAccordionController<String>(),
            children: [
              NakedAccordionItem<String>(
                value: 'item',
                semanticLabel: 'Header',
                trigger: (context, itemState) => const Text('Header'),
                child: const Text('Body'),
              ),
            ],
          ),
        ),
      );
      // Use label to target the header semantics node.
      expect(tester.getSemantics(find.bySemanticsLabel('Header')), strict);

      handle.dispose();
    });

    testWidgets('expanded accessibility parity vs ExpansionTile', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          Material(
            child: ListView(
              shrinkWrap: true,
              children: const [
                ExpansionTile(
                  initiallyExpanded: true,
                  title: Text('Header'),
                  children: [Text('Body')],
                ),
              ],
            ),
          ),
        ),
      );

      final mNode = tester.getSemantics(find.bySemanticsLabel('Header\nBody'));
      final mData = mNode.getSemanticsData();

      await tester.pumpWidget(
        _buildTestApp(
          NakedAccordion<String>(
            controller: NakedAccordionController<String>(),
            initialExpandedValues: const ['item'],
            children: [
              NakedAccordionItem<String>(
                value: 'item',
                semanticLabel: 'Header',
                trigger: (context, itemState) => const Text('Header'),
                child: const Text('Body'),
              ),
            ],
          ),
        ),
      );

      final nNode = tester.getSemantics(find.bySemanticsLabel('Header'));
      final nData = nNode.getSemanticsData();

      // Test essential semantic properties for accessibility parity
      expect(
        nData.hasAction(SemanticsAction.tap),
        mData.hasAction(SemanticsAction.tap),
        reason: 'Both should have tap action',
      );
      expect(
        nData.hasAction(SemanticsAction.focus),
        mData.hasAction(SemanticsAction.focus),
        reason: 'Both should have focus action',
      );
      expect(
        nData.flagsCollection.isEnabled,
        mData.flagsCollection.isEnabled,
        reason: 'Both should have enabled flag',
      );
      expect(
        nData.flagsCollection.hasEnabledState,
        mData.flagsCollection.hasEnabledState,
        reason: 'Both should have enabled state flag',
      );
      expect(
        nData.flagsCollection.isFocusable,
        mData.flagsCollection.isFocusable,
        reason: 'Both should be focusable',
      );

      // Note: Label differs by design - NakedAccordion provides better accessibility
      // by keeping header and body semantics separate rather than merged
      expect(
        nData.label,
        contains('Header'),
        reason: 'NakedAccordion header should contain "Header"',
      );
      expect(
        mData.label,
        contains('Header'),
        reason: 'ExpansionTile should contain "Header"',
      );

      handle.dispose();
    });
  });
}
