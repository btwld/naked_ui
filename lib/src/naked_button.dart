import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// A customizable button with no default styling.
///
/// Provides interaction behavior and accessibility without visual styling.
/// Exposes state callbacks for hover, press, focus, and disabled states.
class NakedButton extends StatefulWidget {
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

  /// The child widget to display.
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

  /// The cursor to show when hovering over the button.
  ///
  /// Defaults to [SystemMouseCursors.click] when enabled,
  /// or [SystemMouseCursors.forbidden] when disabled.
  final MouseCursor cursor;

  /// Whether to provide haptic feedback on press.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  ///
  /// If not provided, the button will create its own focus node.
  final FocusNode? focusNode;

  /// Whether the button should be focused when first built.
  final bool autofocus;

  /// Whether to exclude child semantics from the semantic tree.
  final bool excludeSemantics;

  bool get _isInteractive => enabled && onPressed != null;

  @override
  State<NakedButton> createState() => _NakedButtonState();
}

class _NakedButtonState extends State<NakedButton> {
  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _focusNode!;

  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: handleTap),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: handleTap,
    ),
  };

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
    }
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  void handleTap([Intent? intent]) {
    if (!widget._isInteractive) return;
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }


  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: widget.excludeSemantics,
      enabled: widget._isInteractive,
      button: widget.isSemanticButton,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: widget._isInteractive,
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        actions: _actionMap,
        onShowHoverHighlight: widget.onHoverChange,
        onFocusChange: widget.onFocusChange,
        mouseCursor: widget._isInteractive
            ? widget.cursor
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: widget._isInteractive
              ? (_) => widget.onPressChange?.call(true)
              : null,
          onTapUp: widget._isInteractive
              ? (_) => widget.onPressChange?.call(false)
              : null,
          onTap: widget._isInteractive ? handleTap : null,
          onTapCancel: widget._isInteractive
              ? () => widget.onPressChange?.call(false)
              : null,
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        ),
      ),
    );
  }
}
