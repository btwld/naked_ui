import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/pressed_state_region.dart';

/// A context provider for a radio group that manages a single selection
/// across multiple radio buttons.
///
/// This widget provides a simple callback-based API for managing radio button groups
/// without imposing any visual styling.
///
/// The radio group handles keyboard navigation between radio buttons using arrow keys.
/// When a radio button is focused, arrow keys will move focus to the next/previous
/// enabled radio button in reading order. Selection follows focus.
class NakedRadioGroup<T> extends StatefulWidget {
  /// Creates a naked radio group.
  ///
  /// The [child] parameter is required, which typically contains NakedRadioButton widgets.
  /// The [groupValue] parameter represents the currently selected value within the group.
  /// The [onChanged] callback is called when a radio button is selected.
  /// The [enabled] parameter controls whether the entire group is interactive.
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
        .where((radio) => radio._getInterative(this))
        .toList();
    if (enabledRadios.length <= 1) {
      return;
    }
    final (int, _NakedRadioState<T>)? selected = enabledRadios.indexed
        .firstWhereOrNull((e) => e.$2._focusNode.hasFocus);
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

    final index = selected.$1;

    final nextIndex = (index + (forward ? 1 : -1)) % enabledRadios.length;
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

/// A fully customizable radio button with no default styling.
///
/// NakedRadio provides interaction behavior and accessibility
/// without imposing any visual styling, allowing complete design freedom.
/// It must be used within a NakedRadioGroup to function properly.
///
/// Features:
/// - Customizable appearance through child widget
/// - Hover, pressed, select and focus state callbacks
/// - Keyboard navigation support via arrow keys
/// - Selection follows focus
/// - Haptic feedback on selection
/// - Accessibility support
/// - Disabled state handling
///
/// Example:
/// ```dart
/// NakedRadio<String>(
///   value: 'option1',
///   child: Container(
///     width: 20,
///     height: 20,
///     decoration: BoxDecoration(
///       shape: BoxShape.circle,
///       border: Border.all(
///         color: selected ? Colors.blue : Colors.grey,
///       ),
///     ),
///     child: selected
///       ? Center(child: Icon(Icons.check, size: 16))
///       : null,
///   ),
///   onHoverState: (isHovered) => print('Hover: $isHovered'),
///   onPressedState: (isPressed) => print('Pressed: $isPressed'),
///   onSelectState: (isSelected) => print('Selected: $isSelected'),
///   onFocusState: (isFocused) => print('Focus: $isFocused'),
/// )
/// ```
class NakedRadio<T> extends StatefulWidget {
  /// Creates a naked radio button.
  ///
  /// The [child] and [value] parameters are required.
  /// This component must be used within a NakedRadioGroup.
  const NakedRadio({
    super.key,
    required this.child,
    required this.value,
    this.onHoverState,
    this.onPressedState,
    this.onSelectState,
    this.onFocusState,
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
  final ValueChanged<bool>? onHoverState;

  /// Called when pressed state changes.
  ///
  /// Can be used to update visual feedback when the user presses the radio button.
  final ValueChanged<bool>? onPressedState;

  /// Called when select state changes.
  ///
  /// Can be used to update visual feedback when the radio button is selected.
  final ValueChanged<bool>? onSelectState;

  /// Called when focus state changes.
  ///
  /// Can be used to update visual feedback when the radio button gains or loses focus.
  /// Selection automatically follows focus.
  final ValueChanged<bool>? onFocusState;

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
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _handleTap),
  };
  NakedRadioGroupScope<T> get _group => NakedRadioGroupScope.of(context);

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

  bool _getInterative(NakedRadioGroupState<T> group) =>
      widget.enabled && group.widget.enabled && group.widget.onChanged != null;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = NakedRadioGroupScope.of<T>(context);
    // Register this radio button with the group
    group.state._registerRadioButton(this);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _group.groupValue == widget.value;
    final isInteractive = _getInterative(_group.state);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelectState?.call(isSelected);
    });

    return Semantics(
      enabled: isInteractive,
      checked: isSelected,
      selected: accessibilitySelected,
      child: FocusableActionDetector(
        enabled: isInteractive,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        actions: _actionMap,
        onShowFocusHighlight: widget.onFocusState,
        onShowHoverHighlight: widget.onHoverState,
        onFocusChange: (hasFocus) {
          onChanged?.call(widget.value);
          widget.onFocusState?.call(hasFocus);
        },
        mouseCursor: isInteractive
            ? widget.cursor
            : SystemMouseCursors.forbidden,
        child: PressedStateRegion(
          onPressedState: widget.onPressedState,
          onTap: _handleTap,
          enabled: isInteractive,
          child: Builder(builder: (context) => widget.child),
        ),
      ),
    );
  }
}

extension _IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }

    return null;
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
