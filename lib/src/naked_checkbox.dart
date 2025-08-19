import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/naked_interactable.dart';

/// Provides checkbox interaction behavior without visual styling.
///
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
  /// Renders different states based on callback properties.
  final Widget child;

  /// Whether this checkbox is checked.
  ///
  /// When [tristate] is true, null corresponds to mixed state.
  final bool? value;

  /// Whether the checkbox can be true, false, or null.
  ///
  /// When true, tapping cycles through false => true => null => false.
  /// When false, [value] must not be null.
  final bool tristate;

  /// Called when the checkbox is toggled.
  ///
  /// If null, the checkbox is disabled and unresponsive.
  final ValueChanged<bool?>? onChanged;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Whether the checkbox is enabled.
  final bool enabled;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Cursor when hovering over the checkbox.
  final MouseCursor cursor;

  /// Whether to provide haptic feedback on tap.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to autofocus when created.
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
      container: true,
      explicitChildNodes: true,
      enabled: _isInteractive,
      checked: value ?? false,
      mixed: tristate ? value == null : null,
      focusable: true,
      label: semanticLabel,
      // Always expose tap and focus actions for accessibility expectations
      onTap: () {},
      onFocus: () => true,
      child: NakedInteractable(
        builder: (context, states) => child,
        onPressed: _isInteractive ? _onPressed : null,
        enabled: enabled,
        focusNode: focusNode,
        autofocus: autofocus,
        mouseCursor: _mouseCursor,
        onHoverChange: onHoverChange,
        onPressChange: onPressChange,
        onFocusChange: onFocusChange,
        excludeFromSemantics: false,
      ),
    );
  }
}
