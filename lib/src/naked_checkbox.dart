import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/naked_focusable.dart';
import 'utilities/naked_interactable.dart';

/// Headless checkbox built on NakedInteractable with proper semantics and callbacks.
class NakedCheckbox extends StatelessWidget {
  const NakedCheckbox({
    super.key,
    this.child,
    this.value = false,
    this.tristate = false,
    this.onChanged,
    this.enabled = true,
    this.semanticLabel,
    this.semanticHint,
    this.excludeSemantics = false,
    this.cursor,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onHighlightChanged,
    this.onStateChange,
    this.statesController,
    this.builder,
  }) : assert(
         (tristate || value != null),
         'Non-tristate checkbox must have a non-null value',
       ),
       assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// Visual representation of the checkbox.
  ///
  /// Renders different states based on callback properties.
  final Widget? child;

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

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when highlight (pressed) state changes.
  final ValueChanged<bool>? onHighlightChanged;

  /// Called when any widget state changes.
  final ValueChanged<WidgetStatesDelta>? onStateChange;

  /// Optional external controller for interaction states.
  final WidgetStatesController? statesController;

  /// Whether the checkbox is enabled.
  final bool enabled;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Semantic hint for accessibility.
  final String? semanticHint;

  /// Whether to exclude child semantics from the semantic tree.
  final bool excludeSemantics;

  /// Cursor when hovering over the checkbox.
  final MouseCursor? cursor;

  /// Whether to provide haptic feedback on tap.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to autofocus when created.
  final bool autofocus;

  /// Optional builder that receives the current delta for visuals.
  final WidgetStateBuilder? builder;

  bool? _getNextTristate(bool? currentValue) {
    // Tristate cycling: false → true → null → false
    switch (currentValue) {
      case false:
        return true;
      case true:
        return null;
      case null:
        return false;
    }
  }

  void _handlePressed() {
    if (onChanged == null) return;

    if (enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }

    final bool? newValue = tristate
        ? _getNextTristate(value)
        : !(value ?? false);

    onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final bool isChecked = value ?? false;
    final bool isMixed = tristate && value == null;

    return Semantics(
      excludeSemantics: excludeSemantics,
      enabled: enabled,
      checked: isChecked,
      mixed: isMixed,
      label: semanticLabel,
      hint: semanticHint,
      child: NakedInteractable(
        enabled: enabled,
        selected: isChecked,
        onPressed: _handlePressed,
        statesController: statesController,
        focusNode: focusNode,
        autofocus: autofocus,
        onFocusChange: onFocusChange,
        onHoverChange: onHoverChange,
        onHighlightChanged: onHighlightChanged,
        onStateChange: onStateChange,
        mouseCursor: cursor,
        builder: (states) {
          if (builder != null) {
            return builder!(states);
          }

          return child!;
        },
      ),
    );
  }
}
