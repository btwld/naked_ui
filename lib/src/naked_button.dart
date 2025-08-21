import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/naked_interactable.dart';
import 'utilities/semantics.dart';

/// Provides button interaction behavior without visual styling.
///
/// Exposes state callbacks for hover, press, focus, and disabled states.
class NakedButton extends StatelessWidget {
  /// Creates a naked button.
  const NakedButton({
    super.key,
    required this.child,
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
    this.statesController,
  });

  /// Child widget to display.
  final Widget child;

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

  /// Optional external controller for interaction states.
  final WidgetStatesController? statesController;

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
        builder: (context, states) => child,
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
        mouseCursor: _mouseCursor,
        excludeFromSemantics: excludeSemantics,
      ),
    );
  }
}
