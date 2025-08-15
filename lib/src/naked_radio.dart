import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A context provider for a radio group that manages a single selection
/// across multiple radio buttons.
///
/// Provides keyboard navigation and manages focus between radio buttons.
class NakedRadioGroup<T> extends StatefulWidget {
  /// Creates a naked radio group.
  const NakedRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
    this.enabled = true,
  });

  /// The currently selected value within the group.
  final T? groupValue;

  /// Called when a selection changes.
  final ValueChanged<T?>? onChanged;

  /// Child widgets (typically containing NakedRadioButtons).
  final Widget child;

  /// Whether the entire group is disabled.
  ///
  /// When true, all radio buttons in the group will not respond to user interaction.
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
    final enabledRadios = _radios
        .where((radio) => radio._getInteractive(this))
        .toList();
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

/// Internal InheritedWidget that provides radio group state to child radio buttons.
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

  /// Allows radio buttons to access their parent group without throwing an error.
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

/// A customizable radio button with no default styling.
///
/// Provides interaction behavior and keyboard navigation without visual styling.
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

  /// The child widget that represents the radio button visually.
  final Widget child;

  /// The value this radio button represents.
  ///
  /// When this value matches the group's value, this radio button is considered selected.
  final T value;

  /// Called when hover state changes.
  ///
  /// Can be used to update visual feedback when the user hovers over the radio button.
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  ///
  /// Can be used to update visual feedback when the user presses the radio button.
  final ValueChanged<bool>? onPressChange;

  /// Called when select state changes.
  ///
  /// Can be used to update visual feedback when the radio button is selected.
  final ValueChanged<bool>? onSelectChange;

  /// Called when focus state changes.
  ///
  /// Can be used to update visual feedback when the radio button gains or loses focus.
  /// Selection automatically follows focus.
  final ValueChanged<bool>? onFocusChange;

  /// Whether this radio button is enabled.
  ///
  /// When false, the radio button will not respond to user interaction,
  /// regardless of the group's enabled state.
  final bool enabled;

  /// The cursor to show when hovering over the radio button.
  ///
  /// Defaults to [SystemMouseCursors.click]. When disabled, shows [SystemMouseCursors.forbidden].
  final MouseCursor cursor;

  /// Whether to provide haptic feedback on tap.
  ///
  /// When true, triggers a selection click feedback when the radio button is selected.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  ///
  /// If not provided, a new [FocusNode] will be created internally.
  final FocusNode? focusNode;

  /// Whether to automatically focus this radio button when first built.
  final bool autofocus;

  @override
  State<NakedRadio<T>> createState() => _NakedRadioState<T>();
}

class _NakedRadioState<T> extends State<NakedRadio<T>> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _handleTap),
  };
  NakedRadioGroupScope<T> get _group => NakedRadioGroupScope.of(context);
  bool? _lastReportedSelection;
  NakedRadioGroupState<T>? _groupState;

  ValueChanged<T?>? get onChanged => _group.state.widget.onChanged;

  void _handleTap([Intent? intent]) {
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

  bool get _isInteractive =>
      widget.enabled &&
      _group.state.widget.enabled &&
      _group.state.widget.onChanged != null;

  bool _getInteractive(NakedRadioGroupState<T> group) =>
      widget.enabled && group.widget.enabled && group.widget.onChanged != null;

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
      enabled: _isInteractive,
      checked: isSelected,
      selected: accessibilitySelected,
      child: FocusableActionDetector(
        enabled: _isInteractive,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        actions: _actionMap,
        onShowFocusHighlight: widget.onFocusChange,
        onShowHoverHighlight: widget.onHoverChange,
        onFocusChange: (hasFocus) {
          if (hasFocus && _isInteractive && _group.groupValue != widget.value) {
            onChanged?.call(widget.value);
          }
          widget.onFocusChange?.call(hasFocus);
        },
        mouseCursor: _isInteractive
            ? widget.cursor
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: _isInteractive
              ? (_) => widget.onPressChange?.call(true)
              : null,
          onTapUp: _isInteractive
              ? (_) => widget.onPressChange?.call(false)
              : null,
          onTap: _isInteractive ? _handleTap : null,
          onTapCancel: _isInteractive
              ? () => widget.onPressChange?.call(false)
              : null,
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        ),
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
