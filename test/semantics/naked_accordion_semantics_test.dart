import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

SemanticsNode _findExpandableNode(WidgetTester tester) {
  final SemanticsNode root = tester.getSemantics(find.byType(Scaffold));
  SemanticsNode? found;
  bool dfs(SemanticsNode n) {
    final d = n.getSemanticsData();
    if (d.hasFlag(SemanticsFlag.hasExpandedState)) {
      found = n;
      return true;
    }
    n.visitChildren(dfs);
    return true;
  }

  root.visitChildren(dfs);
  if (found == null) throw StateError('No expandable node found');
  return found!;
}

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('NakedAccordion Semantics', () {
    testWidgets('collapsed vs expanded parity', (tester) async {
      final handle = tester.ensureSemantics();

      // Material collapsed
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
      final mCollapsed = _findExpandableNode(tester);
      final strictCollapsed = buildStrictMatcherFromSemanticsData(
        mCollapsed.getSemanticsData(),
      );

      // Naked collapsed
      final controller = NakedAccordionController<String>();
      await tester.pumpWidget(
        _buildTestApp(
          NakedAccordion<String>(
            controller: controller,
            children: [
              NakedAccordionItem<String>(
                value: 'item',
                trigger: (context, isExpanded) => const Text('Header'),
                child: const Text('Body'),
              ),
            ],
          ),
        ),
      );
      expect(_findExpandableNode(tester), strictCollapsed);

      // Material expanded
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
      final mExpanded = _findExpandableNode(tester);
      final strictExpanded = buildStrictMatcherFromSemanticsData(
        mExpanded.getSemanticsData(),
      );

      // Naked expanded
      await tester.pumpWidget(
        _buildTestApp(
          NakedAccordion<String>(
            controller: NakedAccordionController<String>(),
            initialExpandedValues: const ['item'],
            children: [
              NakedAccordionItem<String>(
                value: 'item',
                trigger: (context, isExpanded) => const Text('Header'),
                child: const Text('Body'),
              ),
            ],
          ),
        ),
      );
      expect(_findExpandableNode(tester), strictExpanded);

      handle.dispose();
    });
  });
}

