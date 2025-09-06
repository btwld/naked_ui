import 'package:flutter/material.dart';

import 'utilities/naked_toggleable.dart';

/// Headless checkbox built on NakedToggleable with proper semantics and callbacks.
class NakedCheckbox extends StatelessWidget {
  const NakedCheckbox({
    super.key,
    this.child,
    this.value = false,
    this.tristate = false,
    this.onChanged,
    this.enabled = true,
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

  @override
  Widget build(BuildContext context) {
    // Use NakedToggleable for checkbox behavior
    Widget result = NakedToggleable(
      selected: value,
      tristate: tristate,
      onChanged: onChanged,
      enabled: enabled,
      mouseCursor: mouseCursor,
      disabledMouseCursor: SystemMouseCursors.basic,
      focusNode: focusNode,
      autofocus: autofocus,
      onStatesChange: onStatesChange,
      onFocusChange: onFocusChange,
      onHoverChange: onHoverChange,
      onPressChange: onPressChange,
      statesController: statesController,
      enableFeedback: enableFeedback,
      focusOnPress: focusOnPress,
      child: child,
      builder: builder ?? ((context, states, child) => child!),
    );

    // Add semantics for accessibility
    return Semantics(
      checked: value,
      mixed: tristate && value == null,
      child: result,
    );
  }
}