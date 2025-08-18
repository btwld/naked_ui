import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'primitives/naked_interactable.dart';

/// A customizable checkbox with no default styling.
///
/// Provides interaction behavior and accessibility without visual styling.
/// Supports checked, unchecked, and tristate (indeterminate) values.
class NakedCheckbox extends StatelessWidget {
  /// Creates a naked checkbox.
  const NakedCheckbox({
    super.key,
    required this.child,
    this.value = false,
    this.tristate = false,
    this.onChanged,
    this.onHoverChange,
    this.onPressChange,
    this.onFocusChange,
    this.onDisabledChange,
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
  /// (value, onHoverChange, etc.).
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
  final ValueChanged<bool>? onHoverChange;

  /// Callback triggered when the checkbox is pressed or released.
  final ValueChanged<bool>? onPressChange;

  /// Callback triggered when the checkbox gains or loses focus.
  final ValueChanged<bool>? onFocusChange;

  /// Callback triggered when the checkbox's disabled state changes.
  final ValueChanged<bool>? onDisabledChange;

  /// Whether the checkbox is disabled.
  final bool enabled;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  /// The cursor to show when hovering over the checkbox.
  final MouseCursor cursor;

  /// Whether to provide haptic feedback on tap.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether the checkbox should be autofocused when the widget is created.
  final bool autofocus;

  bool get _isInteractive => enabled && onChanged != null;
  MouseCursor get _mouseCursor =>
      _isInteractive ? cursor : SystemMouseCursors.forbidden;

  void _onPressed() {
    if (!_isInteractive) return;
    if (enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    switch (value) {
      case false:
        onChanged!(true);
      case true:
        onChanged!(tristate ? null : false);
      case null:
        onChanged!(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: _isInteractive,
      checked: value ?? false,
      mixed: tristate ? value == null : null,
      label: semanticLabel,
      child: NakedInteractable(
        builder: (context, states) => child,
        onPressed: _isInteractive ? _onPressed : null,
        enabled: enabled,
        autofocus: autofocus,
        focusNode: focusNode,
        mouseCursor: _mouseCursor,
        onHoverChange: onHoverChange,
        onPressChange: onPressChange,
        onFocusChange: onFocusChange,
        onDisabledChange: onDisabledChange,
        excludeFromSemantics: false,
      ),
    );
  }
}
