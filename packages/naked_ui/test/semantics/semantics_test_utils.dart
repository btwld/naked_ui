// ignore_for_file: deprecated_member_use
import 'dart:ui'
    show
        CheckedState,
        SemanticsInputType,
        SemanticsRole,
        SemanticsValidationResult,
        Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

typedef SemanticsPredicate = bool Function(SemanticsNode node);

/// Minimal control kinds supported for parity comparisons
enum ControlType { button, checkbox, radio, slider, textField, toggle, tab }

class SemanticsSummary {
  SemanticsSummary({
    required this.label,
    required this.value,
    required this.increasedValue,
    required this.decreasedValue,
    required this.identifier,
    required this.hint,
    required this.tooltip,
    required this.minValue,
    required this.maxValue,
    required this.role,
    required this.validationResult,
    required this.inputType,
    required this.maxValueLength,
    required this.currentValueLength,
    required this.controlsNodes,
    required this.flags,
    required this.actions,
  });

  final String? label;
  final String? value;
  final String? increasedValue;
  final String? decreasedValue;
  final String? identifier;
  final String? hint;
  final String? tooltip;
  final String? minValue;
  final String? maxValue;
  final SemanticsRole role;
  final SemanticsValidationResult validationResult;
  final SemanticsInputType inputType;
  final int? maxValueLength;
  final int? currentValueLength;
  final Set<String>? controlsNodes;
  final Set<String> flags;
  final Set<String> actions;

  SemanticsSummary copyWith({Set<String>? flags, Set<String>? actions}) {
    return SemanticsSummary(
      label: label,
      value: value,
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      identifier: identifier,
      hint: hint,
      tooltip: tooltip,
      minValue: minValue,
      maxValue: maxValue,
      role: role,
      validationResult: validationResult,
      inputType: inputType,
      maxValueLength: maxValueLength,
      currentValueLength: currentValueLength,
      controlsNodes: controlsNodes,
      flags: flags ?? this.flags,
      actions: actions ?? this.actions,
    );
  }

  @override
  String toString() {
    return 'SemanticsSummary('
        'label: ${label ?? ''}, '
        'value: ${value ?? ''}, '
        'increasedValue: ${increasedValue ?? ''}, '
        'decreasedValue: ${decreasedValue ?? ''}, '
        'identifier: ${identifier ?? ''}, '
        'hint: ${hint ?? ''}, '
        'tooltip: ${tooltip ?? ''}, '
        'minValue: ${minValue ?? ''}, '
        'maxValue: ${maxValue ?? ''}, '
        'role: $role, '
        'validationResult: $validationResult, '
        'inputType: $inputType, '
        'maxValueLength: $maxValueLength, '
        'currentValueLength: $currentValueLength, '
        'controlsNodes: $controlsNodes, '
        'flags: ${flags.join(',')}, '
        'actions: ${actions.join(',')})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemanticsSummary &&
        other.label == label &&
        other.value == value &&
        other.increasedValue == increasedValue &&
        other.decreasedValue == decreasedValue &&
        other.identifier == identifier &&
        other.hint == hint &&
        other.tooltip == tooltip &&
        other.minValue == minValue &&
        other.maxValue == maxValue &&
        other.role == role &&
        other.validationResult == validationResult &&
        other.inputType == inputType &&
        other.maxValueLength == maxValueLength &&
        other.currentValueLength == currentValueLength &&
        _setsEqual(other.controlsNodes, controlsNodes) &&
        other.flags.length == flags.length &&
        other.flags.containsAll(flags) &&
        other.actions.length == actions.length &&
        other.actions.containsAll(actions);
  }

  @override
  int get hashCode => Object.hash(
    label,
    value,
    increasedValue,
    decreasedValue,
    identifier,
    hint,
    tooltip,
    minValue,
    maxValue,
    role,
    validationResult,
    inputType,
    maxValueLength,
    currentValueLength,
    controlsNodes == null ? null : Object.hashAllUnordered(controlsNodes!),
    Object.hashAllUnordered(flags),
    Object.hashAllUnordered(actions),
  );
}

bool _setsEqual<T>(Set<T>? left, Set<T>? right) {
  if (identical(left, right)) return true;
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  return left.containsAll(right);
}

/// Traverses semantics tree depth-first and returns the first node
/// that matches the provided predicate.
SemanticsNode? findSemanticsNode(
  SemanticsNode root,
  SemanticsPredicate predicate,
) {
  if (predicate(root)) return root;
  SemanticsNode? found;
  bool visitor(SemanticsNode node) {
    if (found != null) return true;
    if (predicate(node)) {
      found = node;
      return true;
    }
    node.visitChildren(visitor);
    return true;
  }

  root.visitChildren(visitor);
  return found;
}

/// Traverses the semantics tree depth-first and returns every matching node.
List<SemanticsNode> collectSemanticsNodes(
  SemanticsNode root,
  SemanticsPredicate predicate, {
  bool includeMerged = false,
}) {
  final nodes = <SemanticsNode>[];

  bool visitor(SemanticsNode node) {
    if ((includeMerged || !node.isMergedIntoParent) && predicate(node)) {
      nodes.add(node);
    }
    node.visitChildren(visitor);
    return true;
  }

  visitor(root);
  return nodes;
}

/// Counts every semantics node matching [predicate].
int countSemanticsNodes(
  SemanticsNode root,
  SemanticsPredicate predicate, {
  bool includeMerged = false,
}) {
  return collectSemanticsNodes(
    root,
    predicate,
    includeMerged: includeMerged,
  ).length;
}

/// Asserts that no matching semantics node contains another matching child node.
void expectNoNestedSemanticsNodes(
  SemanticsNode root, {
  required SemanticsPredicate predicate,
  required String debugName,
}) {
  final offendingNodes = <SemanticsNode>[];

  bool containsMatchingDescendant(SemanticsNode node) {
    var found = false;
    bool visitor(SemanticsNode child) {
      if (!child.isMergedIntoParent && predicate(child)) {
        found = true;
        return true;
      }
      child.visitChildren(visitor);
      return true;
    }

    node.visitChildren(visitor);
    return found;
  }

  for (final node in collectSemanticsNodes(root, predicate)) {
    if (containsMatchingDescendant(node)) {
      offendingNodes.add(node);
    }
  }

  expect(
    offendingNodes,
    isEmpty,
    reason: 'Expected no nested $debugName semantics nodes.',
  );
}

/// Extracts a concise summary of a semantics node's label, value,
/// key flags and common actions for parity comparison.
SemanticsSummary summarizeNode(SemanticsNode node) {
  final data = node.getSemanticsData();

  final flags = <String>{
    for (final flag in SemanticsFlag.values)
      if (data.hasFlag(flag)) flag.name,
  };
  final actions = <String>{
    for (final action in SemanticsAction.values)
      if (data.hasAction(action)) action.name,
  };

  return SemanticsSummary(
    label: data.label.isEmpty ? null : data.label,
    value: data.value.isEmpty ? null : data.value,
    increasedValue: data.increasedValue.isEmpty ? null : data.increasedValue,
    decreasedValue: data.decreasedValue.isEmpty ? null : data.decreasedValue,
    identifier: data.identifier.isEmpty ? null : data.identifier,
    hint: data.hint.isEmpty ? null : data.hint,
    tooltip: data.tooltip.isEmpty ? null : data.tooltip,
    minValue: data.minValue,
    maxValue: data.maxValue,
    role: data.role,
    validationResult: data.validationResult,
    inputType: data.inputType,
    maxValueLength: data.maxValueLength,
    currentValueLength: data.currentValueLength,
    controlsNodes: data.controlsNodes == null
        ? null
        : Set<String>.unmodifiable(data.controlsNodes!),
    flags: flags,
    actions: actions,
  );
}

/// Helper: from the page root (Scaffold), find the button-like semantics node
/// and return a concise summary for equality comparison.
SemanticsSummary summarizeButtonFromPageRoot(WidgetTester tester) {
  // Keep for backward compatibility; delegate to generic implementation.
  return summarizeMergedFromRoot(tester, control: ControlType.button);
}

/// Merges semantics of the first button-like node with any focus-related semantics
/// from its ancestor chain. This helps normalize differences where Material merges
/// focus semantics into the button node but a custom widget may attach them above.
SemanticsSummary summarizeMergedButtonFromRoot(WidgetTester tester) {
  final SemanticsNode root = tester.getSemantics(find.byType(Scaffold));

  SemanticsSummary? found;
  final List<bool> focusableStack = <bool>[];
  final List<bool> focusedStack = <bool>[];
  final List<bool> hasFocusActionStack = <bool>[];

  bool dfs(SemanticsNode node) {
    final data = node.getSemanticsData();
    final bool isFocusable = data.flagsCollection.isFocused != Tristate.none;
    final bool isFocused = data.flagsCollection.isFocused == Tristate.isTrue;
    final bool hasFocusAction = data.hasAction(SemanticsAction.focus);
    focusableStack.add(isFocusable);
    focusedStack.add(isFocused);
    hasFocusActionStack.add(hasFocusAction);

    final bool isButtonLike =
        data.flagsCollection.isButton || data.hasAction(SemanticsAction.tap);
    if (isButtonLike && found == null) {
      final summary = summarizeNode(node);
      final Set<String> mergedFlags = Set<String>.from(summary.flags);
      final Set<String> mergedActions = Set<String>.from(summary.actions);

      if (focusableStack.any((b) => b)) mergedFlags.add('isFocusable');
      if (focusedStack.any((b) => b)) mergedFlags.add('isFocused');
      if (hasFocusActionStack.any((b) => b)) mergedActions.add('focus');

      found = summary.copyWith(flags: mergedFlags, actions: mergedActions);
      // Continue traversal to allow deeper nodes to override? We can stop now.
      // But returning true continues; instead, we short-circuit by skipping children.
    } else {
      node.visitChildren(dfs);
    }

    focusableStack.removeLast();
    focusedStack.removeLast();
    hasFocusActionStack.removeLast();
    return true;
  }

  root.visitChildren(dfs);
  if (found == null) {
    throw StateError('No button-like semantics node found under Scaffold');
  }
  return found!;
}

/// Generic version of merged semantics summary for any supported control type.
SemanticsSummary summarizeMergedFromRoot(
  WidgetTester tester, {
  required ControlType control,
}) {
  final SemanticsNode root = tester.getSemantics(find.byType(Scaffold));

  SemanticsSummary? found;
  final List<bool> focusableStack = <bool>[];
  final List<bool> focusedStack = <bool>[];
  final List<bool> hasFocusActionStack = <bool>[];

  bool dfs(SemanticsNode node) {
    final data = node.getSemanticsData();
    final bool isFocusable = data.flagsCollection.isFocused != Tristate.none;
    final bool isFocused = data.flagsCollection.isFocused == Tristate.isTrue;
    final bool hasFocusAction = data.hasAction(SemanticsAction.focus);
    focusableStack.add(isFocusable);
    focusedStack.add(isFocused);
    hasFocusActionStack.add(hasFocusAction);

    final bool isControlNode = _isControlNode(data, control);
    if (isControlNode && found == null) {
      final summary = summarizeNode(node);
      final Set<String> mergedFlags = Set<String>.from(summary.flags);
      final Set<String> mergedActions = Set<String>.from(summary.actions);

      if (focusableStack.any((b) => b)) mergedFlags.add('isFocusable');
      if (focusedStack.any((b) => b)) mergedFlags.add('isFocused');
      if (hasFocusActionStack.any((b) => b)) mergedActions.add('focus');

      found = summary.copyWith(flags: mergedFlags, actions: mergedActions);
    } else {
      node.visitChildren(dfs);
    }

    focusableStack.removeLast();
    focusedStack.removeLast();
    hasFocusActionStack.removeLast();
    return true;
  }

  root.visitChildren(dfs);
  if (found == null) {
    throw StateError('No matching control semantics node found under Scaffold');
  }
  return found!;
}

bool _isControlNode(SemanticsData data, ControlType control) {
  switch (control) {
    case ControlType.button:
      return data.flagsCollection.isButton ||
          data.hasAction(SemanticsAction.tap);
    case ControlType.tab:
      // Tabs are generally button-like; rely on tap/button semantics.
      return data.flagsCollection.isButton ||
          data.hasAction(SemanticsAction.tap);
    case ControlType.checkbox:
      return data.flagsCollection.isChecked != CheckedState.none;
    case ControlType.toggle:
      return data.flagsCollection.isToggled != Tristate.none ||
          data.flagsCollection.isChecked != CheckedState.none;
    case ControlType.radio:
      return data.flagsCollection.isInMutuallyExclusiveGroup;
    case ControlType.slider:
      return data.flagsCollection.isSlider;
    case ControlType.textField:
      return data.flagsCollection.isTextField;
  }
}

/// Expect parity by pumping Material, then Naked, and comparing merged summaries.
Future<void> expectSemanticsParity({
  required WidgetTester tester,
  required Widget material,
  required Widget naked,
  required ControlType control,
}) async {
  await tester.pumpWidget(material);
  SemanticsSummary materialSummary = summarizeMergedFromRoot(
    tester,
    control: control,
  );
  await tester.pumpWidget(naked);
  SemanticsSummary nakedSummary = summarizeMergedFromRoot(
    tester,
    control: control,
  );

  expect(nakedSummary, equals(materialSummary));
}

/// Run a test with semantics enabled and ensure proper dispose.
Future<T> withSemantics<T>(
  WidgetTester tester,
  Future<T> Function() body,
) async {
  final handle = tester.ensureSemantics();
  try {
    return await body();
  } finally {
    handle.dispose();
  }
}

/// Minimal strict matcher builder derived directly from SemanticsData
Matcher buildStrictMatcherFromSemanticsData(SemanticsData m) {
  return matchesSemantics(
    label: m.label.isEmpty ? null : m.label,
    value: m.value.isEmpty ? null : m.value,
    increasedValue: m.increasedValue.isEmpty ? null : m.increasedValue,
    decreasedValue: m.decreasedValue.isEmpty ? null : m.decreasedValue,
    isButton: m.hasFlag(SemanticsFlag.isButton),
    isEnabled: m.hasFlag(SemanticsFlag.isEnabled),
    hasEnabledState: m.hasFlag(SemanticsFlag.hasEnabledState),
    isFocusable: m.hasFlag(SemanticsFlag.isFocusable),
    isFocused: m.hasFlag(SemanticsFlag.isFocused),
    hasCheckedState: m.hasFlag(SemanticsFlag.hasCheckedState),
    isChecked: m.hasFlag(SemanticsFlag.isChecked),
    isCheckStateMixed: m.hasFlag(SemanticsFlag.isCheckStateMixed),
    isSelected: m.hasFlag(SemanticsFlag.isSelected),
    isInMutuallyExclusiveGroup: m.hasFlag(
      SemanticsFlag.isInMutuallyExclusiveGroup,
    ),
    isSlider: m.hasFlag(SemanticsFlag.isSlider),
    isTextField: m.hasFlag(SemanticsFlag.isTextField),
    isReadOnly: m.hasFlag(SemanticsFlag.isReadOnly),
    isMultiline: m.hasFlag(SemanticsFlag.isMultiline),
    hasToggledState: m.hasFlag(SemanticsFlag.hasToggledState),
    isToggled: m.hasFlag(SemanticsFlag.isToggled),
    hasTapAction: m.hasAction(SemanticsAction.tap),
    hasFocusAction: m.hasAction(SemanticsAction.focus),
    hasLongPressAction: m.hasAction(SemanticsAction.longPress),
    hasIncreaseAction: m.hasAction(SemanticsAction.increase),
    hasDecreaseAction: m.hasAction(SemanticsAction.decrease),
    hasScrollLeftAction: m.hasAction(SemanticsAction.scrollLeft),
    hasScrollRightAction: m.hasAction(SemanticsAction.scrollRight),
    hasScrollUpAction: m.hasAction(SemanticsAction.scrollUp),
    hasScrollDownAction: m.hasAction(SemanticsAction.scrollDown),
    hasShowOnScreenAction: m.hasAction(SemanticsAction.showOnScreen),
    hasSetSelectionAction: m.hasAction(SemanticsAction.setSelection),
    hasCopyAction: m.hasAction(SemanticsAction.copy),
    hasCutAction: m.hasAction(SemanticsAction.cut),
    hasPasteAction: m.hasAction(SemanticsAction.paste),
    hasDidGainAccessibilityFocusAction: m.hasAction(
      SemanticsAction.didGainAccessibilityFocus,
    ),
    hasDidLoseAccessibilityFocusAction: m.hasAction(
      SemanticsAction.didLoseAccessibilityFocus,
    ),
    hasDismissAction: m.hasAction(SemanticsAction.dismiss),
    hasSetTextAction: m.hasAction(SemanticsAction.setText),
  );
}
