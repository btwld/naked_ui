import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mixins/naked_mixins.dart'; // your WidgetStatesMixin, etc.

/// Provides button interaction behavior without visual styling.
///
/// Users control presentation and semantics through the child or builder parameter.
class NakedButton extends StatefulWidget {
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

  final Widget? child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onPressChange;

  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  final bool enabled;
  final MouseCursor mouseCursor;
  final bool enableFeedback;

  final FocusNode? focusNode;
  final bool autofocus;

  /// When true, pressing requests focus in addition to activating.
  final bool focusOnPress;

  final String? tooltip;
  final String? semanticLabel;

  bool get _effectiveEnabled => enabled && onPressed != null;

  @override
  State<NakedButton> createState() => _NakedButtonState();
}

class _NakedButtonState extends State<NakedButton>
    with WidgetStatesMixin<NakedButton>, FocusableMixin<NakedButton> {
  static const Duration _activationDuration = Duration(milliseconds: 100);
  Timer? _activationTimer;

  // --- FocusableMixin contract ----------------------------------------------

  @override
  FocusNode? get focusableExternalNode => widget.focusNode;

  // --- Activation & gestures -------------------------------------------------

  void _handleKeyboardActivation([Intent? _]) {
    if (!widget._effectiveEnabled || widget.onPressed == null) return;

    if (widget.enableFeedback) {
      Feedback.forTap(context);
    }

    updatePressState(true, widget.onPressChange);
    widget.onPressed!();

    _activationTimer?.cancel();
    _activationTimer = Timer(_activationDuration, () {
      if (mounted) {
        updatePressState(false, widget.onPressChange);
      }
    });
  }

  void _handleTap() {
    if (!widget._effectiveEnabled) return;
    if (widget.enableFeedback) {
      Feedback.forTap(context);
    }
    widget.onPressed?.call();
  }

  void _handleLongPress() {
    if (!widget._effectiveEnabled) return;
    if (widget.enableFeedback) {
      Feedback.forLongPress(context);
    }
    widget.onLongPress?.call();
    // Pressed visual is kept during hold; cleared by onLongPressEnd.
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.focusOnPress) {
      // Delegates to mixin; works with internal or external node.
      requestEffectiveFocus();
    }
    updatePressState(true, widget.onPressChange);
  }

  // --- WidgetStates initialization ------------------------------------------

  @override
  void initializeWidgetStates() {
    updateDisabledState(!widget._effectiveEnabled);
  }

  // --- Lifecycle -------------------------------------------------------------

  @override
  void didUpdateWidget(covariant NakedButton oldWidget) {
    super.didUpdateWidget(
      oldWidget,
    ); // lets FocusableMixin/other mixins run first

    // Track *effective* enabled, not just `enabled`.
    if (oldWidget._effectiveEnabled != widget._effectiveEnabled) {
      updateDisabledState(!widget._effectiveEnabled);

      // If disabled mid-press, clear press & timer defensively.
      if (!widget._effectiveEnabled) {
        _activationTimer?.cancel();
        updatePressState(false, widget.onPressChange);
      }
    }
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    super.dispose(); // FocusableMixin disposes internal focus node
  }

  // --- Semantics -------------------------------------------------------------

  VoidCallback? get _semanticsTapHandler =>
      widget._effectiveEnabled ? _handleTap : null;

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final content = widget.builder != null
        ? widget.builder!(context, widgetStates, widget.child)
        : widget.child!;

    return FocusableActionDetector(
      enabled: widget._effectiveEnabled,
      focusNode: effectiveFocusNode, // <-- from mixin
      autofocus: widget.autofocus,
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
        enabled: widget._effectiveEnabled,
        button: true,
        label: widget.semanticLabel,
        tooltip: widget.tooltip,
        onTap: _semanticsTapHandler,
        onLongPress: widget._effectiveEnabled ? widget.onLongPress : null,
        child: GestureDetector(
          onTapDown: widget._effectiveEnabled ? _handleTapDown : null,
          onTapUp: widget._effectiveEnabled
              ? (_) => updatePressState(false, widget.onPressChange)
              : null,
          onTap: widget._effectiveEnabled ? _handleTap : null,
          onTapCancel: widget._effectiveEnabled
              ? () => updatePressState(false, widget.onPressChange)
              : null,
          onDoubleTap: widget._effectiveEnabled ? widget.onDoubleTap : null,
          onLongPress: widget._effectiveEnabled ? _handleLongPress : null,
          // Long-press symmetry: pressed while holding, clear on end.
          onLongPressStart: widget._effectiveEnabled
              ? (_) => updatePressState(true, widget.onPressChange)
              : null,
          onLongPressEnd: widget._effectiveEnabled
              ? (_) => updatePressState(false, widget.onPressChange)
              : null,
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          child: content,
        ),
      ),
    );
  }
}
