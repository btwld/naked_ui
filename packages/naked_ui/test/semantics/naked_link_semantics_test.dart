import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  group('NakedLink semantics', () {
    testWidgets('enabled Link exposes exact name role URL hint and action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final linkUrl = Uri.parse('https://example.com/docs');

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            linkUrl: linkUrl,
            semanticLabel: 'Documentation',
            semanticHint: 'Opens in a new window',
            onPressed: () {},
            child: const Text('Visible documentation'),
          ),
        ),
      );

      final data = _singleLinkData(tester);
      expect(data.label, 'Documentation');
      expect(data.hint, 'Opens in a new window');
      expect(data.linkUrl, linkUrl);
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.flagsCollection.isFocused, Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('visible text supplies the name when no override is given', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _testApp(
          NakedLink(onPressed: () {}, child: const Text('Visible name')),
        ),
      );

      expect(_singleLinkData(tester).label, 'Visible name');
      handle.dispose();
    });

    testWidgets('semantic label replaces child naming without duplication', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            semanticLabel: 'Accessible documentation',
            onPressed: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Visible documentation'),
                Semantics(
                  label: 'Decorative arrow',
                  image: true,
                  child: const SizedBox(width: 16, height: 16),
                ),
              ],
            ),
          ),
        ),
      );

      final data = _singleLinkData(tester);
      expect(data.label, 'Accessible documentation');
      final allLabels = _allSemanticsData(
        tester,
      ).map((value) => value.label).where((label) => label.isNotEmpty).toList();
      expect(
        allLabels.where((label) => label == 'Accessible documentation'),
        hasLength(1),
      );
      expect(allLabels, isNot(contains('Visible documentation')));
      expect(allLabels, isNot(contains('Decorative arrow')));
      handle.dispose();
    });

    testWidgets('caller can exclude a decorative external icon', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            semanticHint: 'Opens in a new window',
            onPressed: () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('External documentation'),
                ExcludeSemantics(
                  child: Icon(Icons.open_in_new, semanticLabel: 'External'),
                ),
              ],
            ),
          ),
        ),
      );

      final data = _singleLinkData(tester);
      expect(data.label, 'External documentation');
      expect(data.hint, 'Opens in a new window');
      expect(
        _allSemanticsData(tester).where((value) => value.label == 'External'),
        isEmpty,
      );
      handle.dispose();
    });

    testWidgets('focus flags follow the known focus node', (tester) async {
      final handle = tester.ensureSemantics();
      final focusNode = FocusNode(debugLabel: 'semantic link');
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            focusNode: focusNode,
            onPressed: () {},
            child: const Text('Documentation'),
          ),
        ),
      );
      expect(
        _singleLinkData(tester).flagsCollection.isFocused,
        Tristate.isFalse,
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(
        _singleLinkData(tester).flagsCollection.isFocused,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('semantic tap uses the same activation path exactly once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var callbackCount = 0;

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            onPressed: () => callbackCount++,
            child: const Text('Documentation'),
          ),
        ),
      );

      final node = _singleLinkNode(tester);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      expect(callbackCount, 1);
      handle.dispose();
    });

    testWidgets('callback removal retains disabled Link and removes action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      VoidCallback? callback = () {};
      late StateSetter rebuild;

      await tester.pumpWidget(
        _testApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NakedLink(
                linkUrl: Uri.parse('https://example.com/docs'),
                semanticLabel: 'Documentation',
                onPressed: callback,
                child: const Text('Visible documentation'),
              );
            },
          ),
        ),
      );
      expect(_singleLinkData(tester).hasAction(SemanticsAction.tap), isTrue);

      rebuild(() => callback = null);
      await tester.pump();
      final data = _singleLinkData(tester);
      expect(data.label, 'Documentation');
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.flagsCollection.isFocused, Tristate.none);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('Arabic label and hint remain exact in RTL', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _testApp(
          Directionality(
            textDirection: TextDirection.rtl,
            child: NakedLink(
              semanticLabel: 'الوثائق',
              semanticHint: 'يفتح في نافذة جديدة',
              onPressed: () {},
              child: const Text('المستندات'),
            ),
          ),
        ),
      );

      final data = _singleLinkData(tester);
      expect(data.label, 'الوثائق');
      expect(data.hint, 'يفتح في نافذة جديدة');
      expect(data.textDirection, TextDirection.rtl);
      handle.dispose();
    });

    testWidgets('excludeSemantics removes Link and descendant semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            semanticLabel: 'Documentation',
            onPressed: () {},
            child: const Text('Visible documentation'),
          ),
        ),
      );
      expect(_linkNodes(tester), hasLength(1));

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            semanticLabel: 'Documentation',
            excludeSemantics: true,
            onPressed: () {},
            child: const Text('Visible documentation'),
          ),
        ),
      );

      expect(_linkNodes(tester), isEmpty);
      expect(
        _allSemanticsData(tester).where(
          (value) =>
              value.label == 'Documentation' ||
              value.label == 'Visible documentation',
        ),
        isEmpty,
      );
      handle.dispose();
    });
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

SemanticsNode _singleLinkNode(WidgetTester tester) {
  final nodes = _linkNodes(tester);
  expect(nodes, hasLength(1));
  return nodes.single;
}

SemanticsData _singleLinkData(WidgetTester tester) =>
    _singleLinkNode(tester).getSemanticsData();

List<SemanticsNode> _linkNodes(WidgetTester tester) {
  final root = tester.getSemantics(find.byType(Scaffold));
  final nodes = <SemanticsNode>[];

  void collect(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isLink) {
      nodes.add(node);
    }
    node.visitChildren((child) {
      collect(child);
      return true;
    });
  }

  collect(root);
  return nodes;
}

List<SemanticsData> _allSemanticsData(WidgetTester tester) {
  final root = tester.getSemantics(find.byType(Scaffold));
  final data = <SemanticsData>[];

  void collect(SemanticsNode node) {
    data.add(node.getSemanticsData());
    node.visitChildren((child) {
      collect(child);
      return true;
    });
  }

  collect(root);
  return data;
}
