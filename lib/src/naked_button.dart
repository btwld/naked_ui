import 'package:flutter/material.dart';

import 'utilities/naked_pressable.dart';

/// Provides button interaction behavior without visual styling.
///
/// Exposes state callbacks for hover, press, focus, and disabled states.
class NakedButton extends StatelessWidget {
  /// Creates a naked button.
  const NakedButton({
    super.key,
    this.child,
    this.onPressed,
    this.onLongPress,
    this.onDoubleTap,
    this.enabled = true,
    this.mouseCursor = SystemMouseCursors.click,
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
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// Child widget to display.
  final Widget? child;

  /// Called when the button is tapped or activated via keyboard.
  final VoidCallback? onPressed;

  /// Called when the button is long pressed.
  final VoidCallback? onLongPress;

  /// Called when the button is double tapped.
  final VoidCallback? onDoubleTap;

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

  /// Optional builder that receives the current states for visuals.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Whether the button is enabled.
  final bool enabled;

  /// Cursor when hovering over the button.
  ///
  /// Defaults to [SystemMouseCursors.click] when enabled.
  final MouseCursor mouseCursor;

  /// Whether to provide platform-specific feedback on press.
  final bool enableFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to focus the button when first built.
  final bool autofocus;

  /// Whether to request focus when the button is pressed.
  ///
  /// When true, tapping the button will request focus in addition to
  /// calling the onPressed callback. This is useful for form submission
  /// buttons and input-related actions where focus indication improves
  /// user experience.
  ///
  /// Defaults to false to maintain Material Design consistency.
  final bool focusOnPress;

  bool get _effectiveEnabled => enabled && onPressed != null;

  @override
  Widget build(BuildContext context) {
    return NakedPressable(
      onPressed: _effectiveEnabled ? onPressed : null,
      onDoubleTap: _effectiveEnabled ? onDoubleTap : null,
      onLongPress: _effectiveEnabled ? onLongPress : null,
      enabled: enabled,
      mouseCursor: mouseCursor,
      // Use basic cursor for disabled buttons instead of forbidden
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
      builder: (context, states, child) {
        if (builder != null) {
          return builder!(context, states, child);
        }

        return child!;
      },
    );
  }
}
