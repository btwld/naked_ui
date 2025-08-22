import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/naked_focusable.dart';
import 'utilities/naked_interactable.dart';
import 'utilities/semantics.dart';

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
    this.isSemanticButton = true,
    this.semanticLabel,
    this.semanticHint,
    this.cursor = SystemMouseCursors.click,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.excludeSemantics = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onHighlightChanged,
    this.onStateChange,
    this.statesController,
    this.builder,
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
  final ValueChanged<bool>? onHighlightChanged;

  /// Called when any widget state changes.
  final ValueChanged<WidgetStatesDelta>? onStateChange;

  /// Optional external controller for interaction states.
  final WidgetStatesController? statesController;

  /// Optional builder that receives the current states for visuals.
  final WidgetStateBuilder? builder;

  /// Whether the button is enabled.
  final bool enabled;

  /// Whether the button should be treated as a semantic button.
  final bool isSemanticButton;

  /// The semantic label for the button.
  final String? semanticLabel;

  /// The semantic hint for the button.
  final String? semanticHint;

  /// Cursor when hovering over the button.
  ///
  /// Defaults to [SystemMouseCursors.click] when enabled.
  final MouseCursor cursor;

  /// Whether to provide haptic feedback on press.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to focus the button when first built.
  final bool autofocus;

  /// Whether to exclude child semantics.
  final bool excludeSemantics;

  bool get _effectiveEnabled => enabled && onPressed != null;

  MouseCursor get _mouseCursor =>
      _effectiveEnabled ? cursor : SystemMouseCursors.forbidden;

  void _onPressed() {
    if (enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return NakedSemantics.button(
      label: semanticLabel,
      onTap: _effectiveEnabled ? _onPressed : null,
      hint: semanticHint,
      excludeSemantics: excludeSemantics,
      child: NakedInteractable(
        enabled: _effectiveEnabled,
        onPressed: onPressed == null ? null : _onPressed,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        statesController: statesController,
        focusNode: focusNode,
        autofocus: autofocus,
        onFocusChange: onFocusChange,
        onHoverChange: onHoverChange,
        onHighlightChanged: onHighlightChanged,
        onStateChange: onStateChange,
        mouseCursor: _mouseCursor,
        excludeFromSemantics: excludeSemantics,
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
