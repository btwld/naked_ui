// ignore_for_file: deprecated_member_use
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
    required this.flags,
    required this.actions,
  });

  final String? label;
  final String? value;
  final Set<String> flags;
  final Set<String> actions;

  @override
  String toString() {
    return 'SemanticsSummary(label: ' +
        (label ?? '') +
        ', value: ' +
        (value ?? '') +
        ', flags: ' +
        flags.join(',') +
        ', actions: ' +
        actions.join(',') +
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemanticsSummary &&
        other.label == label &&
        other.value == value &&
        other.flags.length == flags.length &&
        other.flags.containsAll(flags) &&
        other.actions.length == actions.length &&
        other.actions.containsAll(actions);
  }

  @override
  int get hashCode => Object.hash(label, value, flags.length, actions.length);
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

/// Extracts a concise summary of a semantics node's label, value,
/// key flags and common actions for parity comparison.
SemanticsSummary summarizeNode(SemanticsNode node) {
  final data = node.getSemanticsData();

  final Set<String> flags = <String>{};
  void addFlag(String name, bool? value) {
    if (value == true) flags.add(name);
  }

  addFlag('isButton', data.flagsCollection.isButton);
  addFlag('isEnabled', data.flagsCollection.isEnabled);
  addFlag('hasEnabledState', data.flagsCollection.hasEnabledState);
  addFlag('isFocusable', data.flagsCollection.isFocusable);
  addFlag('isFocused', data.flagsCollection.isFocused);
  addFlag('hasCheckedState', data.flagsCollection.hasCheckedState);
  addFlag('isChecked', data.flagsCollection.isChecked);
  addFlag('isCheckStateMixed', data.flagsCollection.isCheckStateMixed);
  addFlag('isSelected', data.flagsCollection.isSelected);
  addFlag('isSlider', data.flagsCollection.isSlider);
  addFlag('isTextField', data.flagsCollection.isTextField);
  addFlag('isReadOnly', data.flagsCollection.isReadOnly);
  addFlag('isMultiline', data.flagsCollection.isMultiline);
  addFlag(
    'isInMutuallyExclusiveGroup',
    data.flagsCollection.isInMutuallyExclusiveGroup,
  );
  addFlag('hasToggledState', data.flagsCollection.hasToggledState);
  addFlag('isToggled', data.flagsCollection.isToggled);

  final Set<String> actions = <String>{};
  void addAction(String name, SemanticsAction action) {
    if (node.getSemanticsData().hasAction(action)) actions.add(name);
  }

  addAction('tap', SemanticsAction.tap);
  addAction('longPress', SemanticsAction.longPress);
  addAction('focus', SemanticsAction.focus);
  addAction('increase', SemanticsAction.increase);
  addAction('decrease', SemanticsAction.decrease);

  return SemanticsSummary(
    label: _normalizeLabel(data.label),
    value: data.value.isEmpty ? null : data.value,
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
    final bool isFocusable = data.flagsCollection.isFocusable;
    final bool isFocused = data.flagsCollection.isFocused;
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

      found = SemanticsSummary(
        label: summary.label,
        value: summary.value,
        flags: mergedFlags,
        actions: mergedActions,
      );
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
    final bool isFocusable = data.flagsCollection.isFocusable;
    final bool isFocused = data.flagsCollection.isFocused;
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

      found = SemanticsSummary(
        label: summary.label,
        value: summary.value,
        flags: mergedFlags,
        actions: mergedActions,
      );
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
      return data.flagsCollection.hasCheckedState;
    case ControlType.toggle:
      return data.flagsCollection.hasToggledState ||
          data.flagsCollection.hasCheckedState;
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

  // Certain controls (e.g., TextField) can surface focusability either on the
  // control node or an ancestor. Allow focusable flag parity to vary while
  // still requiring a focus action.
  if (control == ControlType.textField) {
    SemanticsSummary stripFocusable(SemanticsSummary s) => SemanticsSummary(
      label: s.label,
      value: s.value,
      flags: s.flags.where((f) => f != 'isFocusable').toSet(),
      actions: s.actions,
    );
    materialSummary = stripFocusable(materialSummary);
    nakedSummary = stripFocusable(nakedSummary);
  }

  // Tabs (Material) may not expose button/enabled flags. Normalize them out.
  if (control == ControlType.tab) {
    SemanticsSummary normalizeTab(SemanticsSummary s) => SemanticsSummary(
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
    materialSummary = normalizeTab(materialSummary);
    nakedSummary = normalizeTab(nakedSummary);
  }
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

String? _normalizeLabel(String raw) {
  if (raw.isEmpty) return null;
  // Split on newlines and dedupe while preserving order.
  final parts = raw
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;
  // Use the first unique part as canonical label.
  return parts.first;
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
