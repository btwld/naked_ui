import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mixins/naked_mixins.dart';

/// Provides button interaction behavior without visual styling.
///
/// Users control presentation and semantics through the child or builder parameter.
class NakedButton extends StatefulWidget {
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
    this.builder,
    this.focusOnPress = false,
    this.tooltip,
    this.semanticLabel,
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

  /// Tooltip message for accessibility.
  final String? tooltip;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  bool get _effectiveEnabled => enabled && onPressed != null;

  @override
  State<NakedButton> createState() => _NakedButtonState();
}

class _NakedButtonState extends State<NakedButton>
    with WidgetStatesMixin<NakedButton> {
  static const Duration _activationDuration = Duration(milliseconds: 100);

  Timer? _activationTimer;

  void initializeWidgetStates() {
    updateDisabledState(!widget._effectiveEnabled);
  }

  void _handleKeyboardActivation([Intent? _]) {
    if (!widget._effectiveEnabled || widget.onPressed == null) return;
    // show pressed briefly
    updateState(WidgetState.pressed, true);
    if (widget.enableFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed!();
    _activationTimer?.cancel();
    _activationTimer = Timer(_activationDuration, () {
      if (mounted) {
        updateState(WidgetState.pressed, false);
      }
    });
  }

  void _handleTap() {
    if (widget._effectiveEnabled) {
      if (widget.enableFeedback) {
        Feedback.forTap(context);
      }
      widget.onPressed?.call();
    }
  }

  void _handleLongPress() {
    if (widget._effectiveEnabled) {
      if (widget.enableFeedback) {
        Feedback.forLongPress(context);
      }
      widget.onLongPress?.call();
    }
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.focusOnPress && widget.focusNode != null) {
      widget.focusNode!.requestFocus();
    }
    updatePressState(true, widget.onPressChange);
  }

  @override
  void didUpdateWidget(covariant NakedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      updateDisabledState(!widget._effectiveEnabled);
    }
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    super.dispose();
  }

  VoidCallback? get _semanticsTapHandler =>
      widget._effectiveEnabled ? _handleTap : null;

  @override
  Widget build(BuildContext context) {
    final content = widget.builder != null
        ? widget.builder!(context, widgetStates, widget.child)
        : widget.child!;

    return FocusableActionDetector(
      enabled: widget._effectiveEnabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      // Use default includeFocusSemantics: true to let it handle focus semantics automatically
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: _handleKeyboardActivation,
        ),
      },
      onShowHoverHighlight: (hovered) {
        updateHoverState(hovered, widget.onHoverChange);
      },
      onFocusChange: (focused) {
        updateFocusState(focused, widget.onFocusChange);
      },
      mouseCursor: widget._effectiveEnabled
          ? widget.mouseCursor
          : SystemMouseCursors.basic,
      child: Semantics(
        container: true,
        enabled: widget._effectiveEnabled,
        button: true,
        label: widget.semanticLabel,
        tooltip: widget.tooltip,
        onTap: _semanticsTapHandler,
        onLongPress: widget._effectiveEnabled ? widget.onLongPress : null,
        child: GestureDetector(
          onTapDown: widget._effectiveEnabled ? _handleTapDown : null,
          onTapUp: widget._effectiveEnabled
              ? (details) {
                  updatePressState(false, widget.onPressChange);
                }
              : null,
          onTap: widget._effectiveEnabled ? _handleTap : null,
          onTapCancel: widget._effectiveEnabled
              ? () {
                  updatePressState(false, widget.onPressChange);
                }
              : null,
          onDoubleTap: widget._effectiveEnabled ? widget.onDoubleTap : null,
          onLongPress: widget._effectiveEnabled ? _handleLongPress : null,
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          child: content,
        ),
      ),
    );
  }
}
