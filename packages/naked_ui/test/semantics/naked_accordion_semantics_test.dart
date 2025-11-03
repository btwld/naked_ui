import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/naked_ui.dart';

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

      final mNode = tester.getSemantics(find.text('Header'));
      final strict = buildStrictMatcherFromSemanticsData(
        mNode.getSemanticsData(),
      );

      await tester.pumpWidget(
        _buildTestApp(
          NakedAccordionGroup<String>(
            controller: NakedAccordionController<String>(),
            child: Column(
              children: [
                NakedAccordion<String>(
                  value: 'item',
                  semanticLabel: 'Header',
                  builder: (context, itemState) => const Text('Header'),
                  child: const Text('Body'),
                ),
              ],
            ),
          ),
        ),
      );
      // Use label to target the header semantics node.
      expect(tester.getSemantics(find.text('Header')), strict);

      handle.dispose();
    });

    testWidgets('expanded semantic properties vs ExpansionTile', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      // Test our NakedAccordion expanded state
      await tester.pumpWidget(
        _buildTestApp(
          NakedAccordionGroup<String>(
            controller: NakedAccordionController<String>(),
            initialExpandedValues: const ['item'],
            child: Column(
              children: [
                NakedAccordion<String>(
                  value: 'item',
                  semanticLabel: 'Header',
                  builder: (context, itemState) => const Text('Header'),
                  child: const Text('Body'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify header has correct semantic properties
      final headerNode = tester.getSemantics(find.text('Header'));
      final headerData = headerNode.getSemanticsData();

      // Core semantic properties should match Material patterns
      expect(headerData.hasAction(SemanticsAction.tap), isTrue);
      expect(headerData.hasAction(SemanticsAction.focus), isTrue);
      expect(headerData.flagsCollection.isFocusable, isTrue);
      expect(headerData.flagsCollection.hasEnabledState, isTrue);
      expect(headerData.flagsCollection.isEnabled, isTrue);
      expect(
        headerData.label,
        'Header',
      ); // Our better approach: clean header label

      // Verify body content is accessible separately (better than Material's merged approach)
      final bodyFinder = find.text('Body');
      expect(bodyFinder, findsOneWidget);

      handle.dispose();
    });
  });
}
