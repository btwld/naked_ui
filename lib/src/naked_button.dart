import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedButton.builder].
class NakedButtonState extends NakedState {
  NakedButtonState({required super.states});

  static NakedButtonState of(BuildContext context) => NakedState.of(context);
  static NakedButtonState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedButtonState && setEquals(other.states, states);
  }

  @override
  int get hashCode => states.hashCode;
}

/// A headless button without visuals that provides interaction states.
class NakedButton extends StatefulWidget {
  const NakedButton({
    super.key,
    this.child,
    this.onPressed,
    this.onLongPress,
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
    this.excludeSemantics = false,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  final Widget? child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onPressChange;
  final ValueWidgetBuilder<NakedButtonState>? builder;
  final bool enabled;
  final MouseCursor mouseCursor;
  final bool enableFeedback;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool focusOnPress;
  final String? tooltip;
  final String? semanticLabel;
  final bool excludeSemantics;

  @override
  State<NakedButton> createState() => _NakedButtonState();
}

class _NakedButtonState extends State<NakedButton>
    with WidgetStatesMixin<NakedButton>, FocusNodeMixin<NakedButton> {
  Timer? _keyboardPressTimer;

  // Simple derived state - no over-engineering
  bool get _isInteractive =>
      widget.enabled &&
      (widget.onPressed != null || widget.onLongPress != null);

  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;

  void _cleanupKeyboardTimer() {
    _keyboardPressTimer?.cancel();
    _keyboardPressTimer = null;
  }

  void _handleKeyboardActivation() {
    if (!widget.enabled || widget.onPressed == null) return;

    if (widget.enableFeedback) {
      Feedback.forTap(context);
    }

    widget.onPressed!();

    // Visual feedback for keyboard activation
    updatePressState(true, widget.onPressChange);

    _cleanupKeyboardTimer();
    _keyboardPressTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        updatePressState(false, widget.onPressChange);
      }
      _keyboardPressTimer = null;
    });
  }

  void _handleTap() {
    if (!widget.enabled || widget.onPressed == null) return;

    if (widget.enableFeedback) {
      Feedback.forTap(context);
    }
    widget.onPressed!();
  }

  void _handleLongPress() {
    if (!widget.enabled) return;

    if (widget.enableFeedback && widget.onLongPress != null) {
      Feedback.forLongPress(context);
    }

    // Only call user's handler if they provided one
    widget.onLongPress?.call();
  }

  void _onPressStart(TapDownDetails details) {
    if (widget.focusOnPress) {
      requestEffectiveFocus();
    }
    updatePressState(true, widget.onPressChange);
  }

  void _onPressEnd() {
    updatePressState(false, widget.onPressChange);
  }

  @override
  void initializeWidgetStates() {
    // Set initial disabled state based on interactive state
    updateDisabledState(!_isInteractive);
  }

  @override
  void didUpdateWidget(covariant NakedButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update if interactive state actually changed
    final wasInteractive =
        oldWidget.enabled &&
        (oldWidget.onPressed != null || oldWidget.onLongPress != null);

    if (wasInteractive != _isInteractive) {
      updateDisabledState(!_isInteractive);

      // Clean up if becoming non-interactive
      if (!_isInteractive) {
        _cleanupKeyboardTimer();
        // Force clear pressed state when disabled
        updatePressState(false, widget.onPressChange);
      }
    }
  }

  @override
  void dispose() {
    _cleanupKeyboardTimer();
    super.dispose(); // Mixins handle their cleanup
  }

  @override
  Widget build(BuildContext context) {
    final buttonState = NakedButtonState(states: widgetStates);

    final content = NakedStateScope(
      value: buttonState,
      child: widget.builder != null
          ? widget.builder!(context, buttonState, widget.child)
          : widget.child!,
    );

    // Step 1: Build core gesture detector
    Widget child = GestureDetector(
      // GESTURE LIFECYCLE (based on Flutter's documented behavior):
      //
      // Quick tap: onTapDown → onTapUp → onTap
      // Long hold: onTapDown → onTapCancel → onLongPressStart → onLongPress → onLongPressEnd
      // Drag away: onTapDown → onTapCancel
      //
      // The key issue: onTapCancel fires when tap times out (~400ms) even though
      // finger is still down. onLongPressStart then fires immediately after to
      // indicate long press has begun. We use this to re-establish pressed state.

      // Initial press
      onTapDown: _isInteractive ? _onPressStart : null,

      // Tap completion or cancellation
      onTapUp: _isInteractive ? (_) => _onPressEnd() : null,
      onTap: _isInteractive ? _handleTap : null,

      onTapCancel: _isInteractive ? _onPressEnd : null,
      // Always provide onLongPress when interactive to ensure Flutter creates
      // LongPressGestureRecognizer, which enables onLongPressStart/End lifecycle
      onLongPress: _isInteractive ? _handleLongPress : null,
      // Long press sequence - onLongPressStart is CRITICAL
      // It re-establishes pressed=true after onTapCancel clears it
      onLongPressStart: _isInteractive
          ? (details) => updatePressState(true, widget.onPressChange)
          : null,
      onLongPressEnd: _isInteractive ? (_) => _onPressEnd() : null,

      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: content,
    );

    // Step 2: Conditionally wrap with semantics
    if (!widget.excludeSemantics) {
      child = Semantics(
        enabled: _isInteractive,
        button: true,
        label: widget.semanticLabel,
        tooltip: widget.tooltip,
        // Semantics check internally if needed
        onTap: widget.onPressed != null ? _handleTap : null,
        onLongPress: widget.onLongPress != null ? _handleLongPress : null,
        child: child,
      );
    }

    // Step 3: Wrap with focusable detector
    return NakedFocusableDetector(
      enabled: _isInteractive,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        updateFocusState(focused, widget.onFocusChange);
      },
      onHoverChange: (hovered) {
        updateHoverState(hovered, widget.onHoverChange);
      },
      focusNode: effectiveFocusNode,
      mouseCursor: _isInteractive
          ? widget.mouseCursor
          : SystemMouseCursors.basic,
      shortcuts: NakedIntentActions.button.shortcuts,
      actions: NakedIntentActions.button.actions(
        onPressed: _handleKeyboardActivation,
      ),
      child: child,
    );
  }
}
