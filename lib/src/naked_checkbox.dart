import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/naked_pressable.dart';
import 'utilities/utilities.dart';

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
    this.mouseCursor,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
    this.onStatesChange,
    this.statesController,
    this.builder,
    this.focusOnPress = false,
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
  final ValueChanged<bool>? onPressChange;

  /// Called when any widget state changes.
  final ValueChanged<Set<WidgetState>>? onStatesChange;

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
  final MouseCursor? mouseCursor;

  /// Whether to provide haptic feedback on tap.
  ///
  /// Note: Checkboxes use selectionClick haptic feedback for state changes,
  /// which is consistent across platforms for selection controls.
  final bool enableFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to autofocus when created.
  final bool autofocus;

  /// Optional builder that receives the current states for visuals.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Whether to request focus when the checkbox is pressed.
  ///
  /// When true, tapping the checkbox will request focus in addition to
  /// toggling the value. This is useful for form controls where focus
  /// indication after interaction improves user experience.
  ///
  /// Defaults to false to maintain Material Design consistency.
  final bool focusOnPress;

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

    if (enableFeedback) {
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
    final bool isInteractive = enabled && onChanged != null;

    // Use NakedPressable for consistent gesture and cursor behavior
    Widget result = NakedPressable(
      onPressed: isInteractive ? _handlePressed : null,
      enabled: enabled,
      selected: isChecked,
      mouseCursor: mouseCursor,
      // Forbidden cursor for disabled checkbox
      disabledMouseCursor: SystemMouseCursors.forbidden,
      focusNode: focusNode,
      autofocus: autofocus,
      onStatesChange: onStatesChange,
      onFocusChange: onFocusChange,
      onHoverChange: onHoverChange,
      onPressChange: onPressChange,
      statesController: statesController,
      // We handle our own selectionClick haptic feedback
      enableFeedback: false,
      focusOnPress: focusOnPress,
      child: child,
      builder: (context, states, child) {
        if (builder != null) {
          return builder!(context, states, child);
        }

        return this.child!;
      },
    );

    // Wrap with checkbox semantics
    return Semantics(
      excludeSemantics: excludeSemantics,
      enabled: isInteractive,
      checked: tristate && value == null ? null : (value ?? false),
      mixed: tristate && value == null,
      focusable: isInteractive,
      label: semanticLabel,
      hint: semanticHint,
      onTap: isInteractive ? _handlePressed : null,
      // Expose focus action when enabled
      onFocus: isInteractive ? semanticsFocusNoop : null,
      child: result,
    );
  }
}
