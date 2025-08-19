import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/naked_interactable.dart';

/// Provides button interaction behavior without visual styling.
///
/// Exposes state callbacks for hover, press, focus, and disabled states.
class NakedButton extends StatelessWidget {
  /// Creates a naked button.
  const NakedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onHoverChange,
    this.onPressChange,
    this.onFocusChange,
    this.enabled = true,
    this.isSemanticButton = true,
    this.semanticLabel,
    this.cursor = SystemMouseCursors.click,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.excludeSemantics = false,
  });

  /// Child widget to display.
  final Widget child;

  /// Called when the button is tapped or activated via keyboard.
  final VoidCallback? onPressed;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Whether the button is enabled.
  final bool enabled;

  /// Whether the button should be treated as a semantic button.
  final bool isSemanticButton;

  /// The semantic label for the button.
  final String? semanticLabel;

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
    return Semantics(
      container: true,
      explicitChildNodes: true,
      excludeSemantics: excludeSemantics,
      enabled: _effectiveEnabled,
      button: isSemanticButton,
      focusable: _effectiveEnabled,
      label: semanticLabel,
      onFocus: _effectiveEnabled ? () => true : null,
      child: NakedInteractable(
        builder: (context, states) => child,
        onPressed: onPressed == null ? null : _onPressed,
        enabled: _effectiveEnabled,
        focusNode: focusNode,
        autofocus: autofocus,
        mouseCursor: _mouseCursor,
        onHoverChange: onHoverChange,
        onPressChange: onPressChange,
        onFocusChange: onFocusChange,
      ),
    );
  }
}
