import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/naked_interactable.dart';

/// Manages single selection across multiple radio buttons.
///
/// Provides keyboard navigation and focus management.
class NakedRadioGroup<T> extends StatefulWidget {
  /// Creates a naked radio group.
  const NakedRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
    this.enabled = true,
  });

  /// Currently selected value within the group.
  final T? groupValue;

  /// Called when a selection changes.
  final ValueChanged<T?>? onChanged;

  /// Child widgets (typically containing NakedRadio widgets).
  final Widget child;

  /// Whether the entire group is disabled.
  ///
  /// When true, all radio buttons become unresponsive.
  final bool enabled;

  @override
  State<NakedRadioGroup<T>> createState() => NakedRadioGroupState<T>();
}

class NakedRadioGroupState<T> extends State<NakedRadioGroup<T>> {
  // Set of registered radio buttons
  final Set<_NakedRadioState<T>> _radios = {};

  late final Map<ShortcutActivator, Intent> _radioGroupShortcuts =
      <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): VoidCallbackIntent(
          _selectPreviousRadio,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            VoidCallbackIntent(_selectNextRadio),
        const SingleActivator(LogicalKeyboardKey.arrowDown): VoidCallbackIntent(
          _selectNextRadio,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowUp): VoidCallbackIntent(
          _selectPreviousRadio,
        ),
      };

  void _registerRadioButton(_NakedRadioState<T> radio) {
    _radios.add(radio);
  }

  void _selectRadioInDirection(bool forward) {
    final enabledRadios = _radios.where((radio) => radio._isEnabled).toList();
    if (enabledRadios.length <= 1) {
      return;
    }
    // Find the currently focused radio button
    (int, _NakedRadioState<T>)? selected;
    for (final (index, state) in enabledRadios.indexed) {
      if (state._focusNode.hasFocus) {
        selected = (index, state);
        break;
      }
    }
    if (selected == null) {
      // The focused node is either a non interactive radio or other controls.
      return;
    }
    final policy = ReadingOrderTraversalPolicy();
    final sorted = policy
        .sortDescendants(
          enabledRadios.map((e) => e._focusNode),
          selected.$2._focusNode,
        )
        .toList();

    final currentIndex = sorted.indexOf(selected.$2._focusNode);
    final nextIndex =
        (currentIndex + (forward ? 1 : -1) + sorted.length) % sorted.length;
    final nextFocus = sorted[nextIndex];

    nextFocus.requestFocus();
  }

  void _selectPreviousRadio() {
    _selectRadioInDirection(false);
  }

  void _selectNextRadio() {
    _selectRadioInDirection(true);
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: _SkipUnselectedRadioPolicy<T>(_radios, widget.groupValue),
      child: Shortcuts(
        shortcuts: _radioGroupShortcuts,
        child: NakedRadioGroupScope<T>(
          state: this,
          groupValue: widget.groupValue,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Provides radio group state to child radio buttons.
class NakedRadioGroupScope<T> extends InheritedWidget {
  /// Creates a radio group scope.
  const NakedRadioGroupScope({
    super.key,
    required this.state,
    required this.groupValue,
    required super.child,
  });

  /// Allows radio buttons to access their parent group.
  static NakedRadioGroupScope<T> of<T>(BuildContext context) {
    final group = maybeOf<T>(context);
    if (group == null) {
      throw FlutterError(
        'NakedRadioButton must be used within a NakedRadioGroup.\n'
        'No NakedRadioGroup ancestor could be found for a NakedRadioButton',
      );
    }

    return group;
  }

  /// Accesses parent group without throwing on failure.
  static NakedRadioGroupScope<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  final NakedRadioGroupState<T> state;

  final T? groupValue;

  @override
  bool updateShouldNotify(NakedRadioGroupScope<T> oldWidget) {
    return state != oldWidget.state || groupValue != oldWidget.groupValue;
  }
}

/// Provides radio button interaction behavior without visual styling.
///
/// Must be used within a NakedRadioGroup to function properly.
class NakedRadio<T> extends StatefulWidget {
  /// Creates a naked radio button.
  const NakedRadio({
    super.key,
    required this.child,
    required this.value,
    this.onHoverChange,
    this.onPressChange,
    this.onSelectChange,
    this.onFocusChange,
    this.enabled = true,
    this.cursor = SystemMouseCursors.click,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Child widget that represents the radio button visually.
  final Widget child;

  /// Value this radio button represents.
  ///
  /// When matching the group's value, this button is selected.
  final T value;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Called when select state changes.
  final ValueChanged<bool>? onSelectChange;

  /// Called when focus state changes.
  ///
  /// Selection automatically follows focus.
  final ValueChanged<bool>? onFocusChange;

  /// Whether this radio button is enabled.
  ///
  /// When false, becomes unresponsive regardless of group state.
  final bool enabled;

  /// Cursor when hovering over the radio button.
  final MouseCursor cursor;

  /// Whether to provide haptic feedback on selection.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to automatically focus when first built.
  final bool autofocus;

  @override
  State<NakedRadio<T>> createState() => _NakedRadioState<T>();
}

class _NakedRadioState<T> extends State<NakedRadio<T>> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  bool get _isEnabled =>
      widget.enabled &&
      _group.state.widget.enabled &&
      _group.state.widget.onChanged != null;
  MouseCursor get _cursor =>
      _isEnabled ? widget.cursor : SystemMouseCursors.forbidden;

  NakedRadioGroupScope<T> get _group => NakedRadioGroupScope.of(context);
  bool? _lastReportedSelection;
  NakedRadioGroupState<T>? _groupState;

  ValueChanged<T?>? get onChanged => _group.state.widget.onChanged;

  void _handlePressed() {
    if (!_isEnabled) return;

    // If group is already set to this value, do nothing
    if (_group.groupValue == widget.value) {
      return;
    }

    // Notify the group of the selection
    onChanged?.call(widget.value);

    // Add haptic feedback if enabled
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  void _handleFocusChange(bool focused) {
    if (focused && _group.groupValue != widget.value) {
      onChanged?.call(widget.value);
    }
    widget.onFocusChange?.call(focused);
  }

  @override
  void dispose() {
    _groupState?._radios.remove(this);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = NakedRadioGroupScope.of<T>(context);
    final newState = group.state;
    if (!identical(_groupState, newState)) {
      _groupState?._radios.remove(this);
      _groupState = newState;
    }
    _groupState!._registerRadioButton(this);

    // Check if selection state has changed and notify
    final isSelected = group.groupValue == widget.value;
    if (_lastReportedSelection != isSelected) {
      _lastReportedSelection = isSelected;
      // Safe to call synchronously in didChangeDependencies
      widget.onSelectChange?.call(isSelected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _group.groupValue == widget.value;

    final bool? accessibilitySelected;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        accessibilitySelected = null;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        accessibilitySelected = isSelected;
    }
    // State change notification is handled in didChangeDependencies

    return Semantics(
      enabled: _isEnabled,
      checked: isSelected,
      selected: accessibilitySelected,
      child: NakedInteractable(
        builder: (context, states) => widget.child,
        onPressed: _isEnabled ? _handlePressed : null,
        enabled: _isEnabled,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        mouseCursor: _cursor,
        onHoverChange: widget.onHoverChange,
        onPressChange: widget.onPressChange,
        onFocusChange: _handleFocusChange,
        excludeFromSemantics: false,
      ),
    );
  }
}

class _SkipUnselectedRadioPolicy<T> extends ReadingOrderTraversalPolicy {
  final Set<_NakedRadioState<T>> radios;
  final T? groupValue;
  _SkipUnselectedRadioPolicy(this.radios, this.groupValue);
  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    if (radios.every((radio) => groupValue != radio.widget.value)) {
      // None of the radio are selected. Defaults to ReadingOrderTraversalPolicy.
      return super.sortDescendants(descendants, currentNode);
    }
    // Nodes that are not selected AND not currently focused, since we can't
    // remove the focused node from the sorted result.
    final Set<FocusNode> nodeToSkip = radios
        .where(
          (_NakedRadioState<T> radio) =>
              groupValue != radio.widget.value &&
              radio._focusNode != currentNode,
        )
        .map<FocusNode>((_NakedRadioState<T> radio) => radio._focusNode)
        .toSet();
    final Iterable<FocusNode> skipsNonSelected = descendants.where(
      (FocusNode node) => !nodeToSkip.contains(node),
    );

    return super.sortDescendants(skipsNonSelected, currentNode);
  }
}
