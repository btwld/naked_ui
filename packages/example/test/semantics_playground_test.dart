import 'dart:ui' show CheckedState, Tristate;

import 'package:example/api/naked_semantics_playground.dart';
import 'package:example/registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: child),
  );

  testWidgets('semantics playground demo is registered', (tester) async {
    expect(DemoRegistry.find('semantics-playground'), isNotNull);
  });

  testWidgets('playground exposes expected Flutter semantics', (tester) async {
    final handle = tester.ensureSemantics();

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(const SemanticsPlayground()));
    await tester.pumpAndSettle();

    final root = tester.getSemantics(find.byType(Scaffold));
    final dump = _dumpTree(root);
    final labels = _collectLabels(root);

    const defaultNames = [
      'Default menu',
      'Default accordion',
      'Default radio',
      'Default select',
      'Default slider',
      'Default text field',
    ];
    for (final name in defaultNames) {
      expect(
        labels,
        contains(name),
        reason: 'Missing default label "$name"\n$dump',
      );
    }

    const overrideNames = [
      'Override menu trigger',
      'Override accordion trigger',
      'Override radio option',
      'Override select trigger',
      'Override slider',
      'Override text field',
    ];
    for (final name in overrideNames) {
      expect(
        labels,
        contains(name),
        reason: 'Missing override label "$name"\n$dump',
      );
    }

    // Visual override labels must never be exposed on a control node.
    for (final visual in const [
      'Visual menu',
      'Visual accordion',
      'Visual radio',
      'Visual select',
    ]) {
      final offenders = _collectAll(root, (node) {
        final data = node.getSemanticsData();
        return data.label == visual && _isControlNode(data);
      });
      expect(
        offenders,
        isEmpty,
        reason: '"$visual" must not be a control label\n$dump',
      );
    }

    // Menu, accordion, and select triggers all expose button + expanded state.
    for (final entry in const <String, String>{
      'Default menu': 'menu trigger (default)',
      'Override menu trigger': 'menu trigger (override)',
      'Default accordion': 'accordion trigger (default)',
      'Override accordion trigger': 'accordion trigger (override)',
      'Default select': 'select trigger (default)',
      'Override select trigger': 'select trigger (override)',
    }.entries) {
      final node = _findByLabel(root, entry.key);
      expect(
        node,
        isNotNull,
        reason: 'Missing ${entry.value} node "${entry.key}"\n$dump',
      );
      final data = node!.getSemanticsData();
      expect(
        data.flagsCollection.isButton,
        isTrue,
        reason: '${entry.value} should be a button',
      );
      expect(
        data.flagsCollection.isExpanded,
        Tristate.isFalse,
        reason: '${entry.value} should expose collapsed expanded state',
      );
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason: '${entry.value} should expose tap action',
      );
    }

    // Radio: mutually exclusive group + checked.
    for (final label in const ['Default radio', 'Override radio option']) {
      final node = _findByLabel(root, label);
      expect(node, isNotNull, reason: 'Missing radio "$label"\n$dump');
      final data = node!.getSemanticsData();
      expect(
        data.flagsCollection.isInMutuallyExclusiveGroup,
        isTrue,
        reason: '"$label" should be in a radio group',
      );
      expect(
        data.flagsCollection.isChecked,
        CheckedState.isTrue,
        reason: '"$label" should be checked (only option in the group)',
      );
    }

    // Slider: slider flag + value/increase/decrease.
    for (final label in const ['Default slider', 'Override slider']) {
      final node = _findByLabel(root, label);
      expect(node, isNotNull, reason: 'Missing slider "$label"\n$dump');
      final data = node!.getSemanticsData();
      expect(data.flagsCollection.isSlider, isTrue);
      expect(
        data.value,
        isNotEmpty,
        reason: '"$label" should expose a semantic value',
      );
      expect(data.increasedValue, isNotEmpty);
      expect(data.decreasedValue, isNotEmpty);
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
    }
    final overrideSliderData = _findByLabel(
      root,
      'Override slider',
    )!.getSemanticsData();
    expect(
      overrideSliderData.value,
      startsWith('Override slider percent'),
      reason: 'override slider should use its semanticFormatterCallback',
    );

    // Text field: exactly two text fields, none nested.
    bool isTextField(SemanticsNode node) =>
        node.getSemanticsData().flagsCollection.isTextField;
    final textFields = _collectAll(root, isTextField);
    expect(
      textFields,
      hasLength(2),
      reason: 'Expected exactly two text fields\n$dump',
    );
    _expectNoNested(root, predicate: isTextField, debugName: 'text field');

    final tfLabels = textFields.map((n) => n.getSemanticsData().label).toSet();
    expect(
      tfLabels,
      containsAll(<String>['Default text field', 'Override text field']),
    );

    final defaultTfData = textFields
        .firstWhere((n) => n.getSemanticsData().label == 'Default text field')
        .getSemanticsData();
    expect(
      defaultTfData.flagsCollection.isLiveRegion,
      isFalse,
      reason: 'default text field has no error, should not be live',
    );

    final overrideTfData = textFields
        .firstWhere((n) => n.getSemanticsData().label == 'Override text field')
        .getSemanticsData();
    expect(
      overrideTfData.flagsCollection.isLiveRegion,
      isFalse,
      reason: 'an initial text field error is discoverable but not live',
    );
    expect(
      overrideTfData.hint,
      contains('Override text field error'),
      reason: 'override text field hint should include error text',
    );

    // Select triggers: identified by label, none nested.
    bool isSelectTrigger(SemanticsNode node) {
      final label = node.getSemanticsData().label;
      return label == 'Default select' || label == 'Override select trigger';
    }

    final selects = _collectAll(root, isSelectTrigger);
    expect(selects, hasLength(2));
    _expectNoNested(
      root,
      predicate: isSelectTrigger,
      debugName: 'select trigger',
    );

    // Unmount the playground so its internal SemanticsHandle is disposed,
    // then dispose ours before the framework's leaked-handle check runs.
    await tester.pumpWidget(const SizedBox.shrink());
    handle.dispose();
  });
}

List<SemanticsNode> _collectAll(
  SemanticsNode root,
  bool Function(SemanticsNode) predicate,
) {
  final out = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent && predicate(node)) out.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return out;
}

SemanticsNode? _findByLabel(SemanticsNode root, String label) {
  final matches = _collectAll(root, (n) => n.getSemanticsData().label == label);
  return matches.isEmpty ? null : matches.first;
}

Set<String> _collectLabels(SemanticsNode root) {
  final labels = <String>{};
  void visit(SemanticsNode node) {
    final raw = node.getSemanticsData().label;
    if (raw.isNotEmpty) {
      for (final part in raw.split('\n')) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) labels.add(trimmed);
      }
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return labels;
}

bool _isControlNode(SemanticsData data) {
  return data.flagsCollection.isButton ||
      data.flagsCollection.isSlider ||
      data.flagsCollection.isTextField ||
      data.flagsCollection.isInMutuallyExclusiveGroup ||
      data.flagsCollection.isChecked != CheckedState.none ||
      data.flagsCollection.isToggled != Tristate.none ||
      data.hasAction(SemanticsAction.tap) ||
      data.hasAction(SemanticsAction.increase) ||
      data.hasAction(SemanticsAction.decrease);
}

void _expectNoNested(
  SemanticsNode root, {
  required bool Function(SemanticsNode) predicate,
  required String debugName,
}) {
  bool hasMatchingDescendant(SemanticsNode node) {
    var found = false;
    bool visit(SemanticsNode child) {
      if (found) return true;
      if (!child.isMergedIntoParent && predicate(child)) {
        found = true;
        return true;
      }
      child.visitChildren(visit);
      return true;
    }

    node.visitChildren(visit);
    return found;
  }

  final offenders = <SemanticsNode>[];
  for (final node in _collectAll(root, predicate)) {
    if (hasMatchingDescendant(node)) offenders.add(node);
  }
  expect(
    offenders,
    isEmpty,
    reason: 'Expected no nested $debugName semantics nodes',
  );
}

String _dumpTree(SemanticsNode root) {
  final buf = StringBuffer('Semantics tree:\n');
  void visit(SemanticsNode node, int depth) {
    final data = node.getSemanticsData();
    final parts = <String>[];
    if (data.label.isNotEmpty) {
      parts.add('label="${data.label.replaceAll('\n', '\\n')}"');
    }
    if (data.value.isNotEmpty) parts.add('value="${data.value}"');
    if (data.hint.isNotEmpty) parts.add('hint="${data.hint}"');
    if (data.flagsCollection.isButton) parts.add('button');
    if (data.flagsCollection.isExpanded != Tristate.none) {
      parts.add('expanded=${data.flagsCollection.isExpanded}');
    }
    if (data.flagsCollection.isSlider) parts.add('slider');
    if (data.flagsCollection.isTextField) parts.add('textField');
    if (data.flagsCollection.isInMutuallyExclusiveGroup) parts.add('radio');
    if (data.flagsCollection.isChecked != CheckedState.none) {
      parts.add('checked=${data.flagsCollection.isChecked}');
    }
    if (data.flagsCollection.isLiveRegion) parts.add('liveRegion');
    buf.writeln('${'  ' * depth}#${node.id} ${parts.join(' ')}');
    node.visitChildren((child) {
      visit(child, depth + 1);
      return true;
    });
  }

  visit(root, 0);
  return buf.toString();
}
