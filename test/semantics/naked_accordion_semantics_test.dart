import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
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
      final strict = buildStrictMatcherFromSemanticsData(mNode.getSemanticsData());

      await tester.pumpWidget(
        _buildTestApp(
          NakedAccordion<String>(
            controller: NakedAccordionController<String>(),
            children: [
              NakedAccordionItem<String>(
                value: 'item',
                semanticLabel: 'Header',
                trigger: (context, isExpanded) => const Text('Header'),
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

    testWidgets('expanded strict parity vs ExpansionTile', (tester) async {
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

      final mNode = tester.getSemantics(find.bySemanticsLabel('Header'));
      final strict = buildStrictMatcherFromSemanticsData(mNode.getSemanticsData());

      await tester.pumpWidget(
        _buildTestApp(
          NakedAccordion<String>(
            controller: NakedAccordionController<String>(),
            initialExpandedValues: const ['item'],
            children: [
              NakedAccordionItem<String>(
                value: 'item',
                semanticLabel: 'Header',
                trigger: (context, isExpanded) => const Text('Header'),
                child: const Text('Body'),
              ),
            ],
          ),
        ),
      );

      expect(tester.getSemantics(find.bySemanticsLabel('Header')), strict);
      handle.dispose();
    });
  }, skip: true);
}
