import 'package:flutter/material.dart';

import 'utilities/naked_toggleable.dart';

/// Headless switch built on NakedToggleable with proper semantics and callbacks.
class NakedSwitch extends StatelessWidget {
  const NakedSwitch({
    super.key,
    this.child,
    required this.value,
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
         value != null,
         'NakedSwitch is binary and requires a non-null value.',
       ),
       assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// Visual representation of the switch.
  final Widget? child;

  /// Whether this switch is on.
  final bool? value;

  /// Called when the switch is toggled.
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

  /// Whether the switch is enabled.
  final bool enabled;

  /// Cursor when hovering over the switch.
  final MouseCursor? mouseCursor;

  /// Whether to provide haptic feedback on tap.
  final bool enableFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to autofocus when created.
  final bool autofocus;

  /// Optional builder that receives the current states for visuals.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Whether to request focus when the switch is pressed.
  final bool focusOnPress;

  @override
  Widget build(BuildContext context) {
    // Use NakedToggleable for switch behavior (binary only)
    final Widget result = NakedToggleable(
      selected: value,
      tristate: false,
      onChanged: onChanged,
      enabled: enabled,
      focusNode: focusNode,
      autofocus: autofocus,
      mouseCursor: mouseCursor,
      disabledMouseCursor: SystemMouseCursors.basic,
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
    final bool _interactive = enabled && onChanged != null;

    return Semantics(
      toggled: value,
      // Provide tap action for assistive tech
      onTap: _interactive ? () => onChanged!(!(value ?? false)) : null,
      child: result,
    );
  }
}
