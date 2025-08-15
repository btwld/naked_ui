import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable checkbox with no default styling.
///
/// Provides interaction behavior and accessibility without visual styling.
/// Supports checked, unchecked, and tristate (indeterminate) values.
class NakedCheckbox extends StatefulWidget {
  /// Creates a naked checkbox.
  const NakedCheckbox({
    super.key,
    required this.child,
    this.value = false,
    this.tristate = false,
    this.onChanged,
    this.onHoveredState,
    this.onPressedState,
    this.onFocusedState,
    this.enabled = true,
    this.semanticLabel,
    this.cursor = SystemMouseCursors.click,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         (tristate || value != null),
         'Non-tristate checkbox must have a non-null value',
       );

  /// Visual representation of the checkbox.
  ///
  /// Render different visual states based on the callback properties
  /// (value, onHoveredState, etc.).
  final Widget child;

  /// Whether this checkbox is checked.
  ///
  /// When [tristate] is true, a value of null corresponds to the mixed state.
  /// When [tristate] is false, this value must not be null.
  final bool? value;

  /// If true the checkbox's [value] can be true, false, or null.
  ///
  /// When a tri-state checkbox ([tristate] is true) is tapped, its [onChanged]
  /// callback will be applied to true if the current value is false, to null if
  /// value is true, and to false if value is null (i.e. it cycles through false
  /// => true => null => false when tapped).
  ///
  /// If tristate is false (the default), [value] must not be null.
  final bool tristate;

  /// Called when the checkbox is toggled.
  ///
  /// The callback provides the new state of the checkbox (true for checked, false for unchecked).
  /// If null, the checkbox will be considered disabled and will not respond to user interaction.
  final ValueChanged<bool?>? onChanged;

  /// Callback triggered when the checkbox's hover state changes.
  ///
  /// Passes `true` when the pointer enters the checkbox bounds, and `false`
  /// when it exits. Useful for implementing hover effects.
  final ValueChanged<bool>? onHoveredState;

  /// Callback triggered when the checkbox is pressed or released.
  ///
  /// Passes `true` when the checkbox is pressed down, and `false` when released.
  /// Useful for implementing press effects.
  final ValueChanged<bool>? onPressedState;

  /// Callback triggered when the checkbox gains or loses focus.
  ///
  /// Passes `true` when the checkbox gains focus, and `false` when it loses focus.
  /// Useful for implementing focus indicators.
  final ValueChanged<bool>? onFocusedState;

  /// Whether the checkbox is disabled.
  ///
  /// When true, the checkbox will not respond to user interaction
  /// and should be styled accordingly.
  final bool enabled;

  /// Optional semantic label for accessibility.
  ///
  /// Provides a description of the checkbox's purpose for screen readers.
  /// If not provided, screen readers will use a default description.
  final String? semanticLabel;

  /// The cursor to show when hovering over the checkbox.
  ///
  /// Defaults to [SystemMouseCursors.click] when enabled,
  /// or [SystemMouseCursors.forbidden] when disabled.
  final MouseCursor cursor;

  /// Whether to provide haptic feedback on tap.
  ///
  /// When true (the default), the device will produce a haptic feedback effect
  /// when the checkbox is toggled.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  ///
  /// If not provided, the checkbox will create its own focus node.
  final FocusNode? focusNode;

  /// Whether the checkbox should be autofocused when the widget is created.
  ///
  /// Defaults to false.
  final bool autofocus;

  @override
  State<NakedCheckbox> createState() => _NakedCheckboxState();
}

class _NakedCheckboxState extends State<NakedCheckbox> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: toggleValue),
  };
  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void toggleValue([Intent? _]) {
    if (!_isInteractive) return;

    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }

    switch (widget.value) {
      case false:
        widget.onChanged!(true);
      case true:
        widget.onChanged!(widget.tristate ? null : false);
      case null:
        widget.onChanged!(false);
    }
  }

  bool get _isInteractive => widget.enabled && widget.onChanged != null;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: _isInteractive,
      checked: widget.value ?? false,
      mixed: widget.tristate ? widget.value == null : null,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _isInteractive,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        actions: _actionMap,
        onShowFocusHighlight: widget.onFocusedState,
        onShowHoverHighlight: widget.onHoveredState,
        onFocusChange: widget.onFocusedState,
        mouseCursor: _isInteractive
            ? widget.cursor
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: _isInteractive
              ? (_) => widget.onPressedState?.call(true)
              : null,
          onTapUp: _isInteractive
              ? (_) => widget.onPressedState?.call(false)
              : null,
          onTap: _isInteractive ? toggleValue : null,
          onTapCancel: _isInteractive
              ? () => widget.onPressedState?.call(false)
              : null,
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        ),
      ),
    );
  }
}
