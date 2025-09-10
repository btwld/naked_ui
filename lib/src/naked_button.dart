import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mixins/naked_mixins.dart';

/// Provides button interaction behavior without visual styling.
///
/// State changes are reported through onStatesChange callback.
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
  State<NakedButton> createState() => _NakedButtonState();
}

class _NakedButtonState extends State<NakedButton>
    with
        WidgetStatesControllerMixin<NakedButton>,
        NakedFocusableMixin<NakedButton>,
        NakedHoverableMixin<NakedButton>,
        NakedPressableMixin<NakedButton> {
  static const Duration _activationDuration = Duration(milliseconds: 100);

  Timer? _activationTimer;

  // Bridge to mixins
  @override
  WidgetStatesController? get providedStatesController =>
      widget.statesController;

  @override
  ValueChanged<Set<WidgetState>>? get onStatesChange =>
      widget.onStatesChange != null ||
          widget.onFocusChange != null ||
          widget.onHoverChange != null ||
          widget.onPressChange != null
      ? (states) {
          emitStateCallbacks(
            states: states,
            onStatesChange: widget.onStatesChange,
            onFocusChange: widget.onFocusChange,
            onHoverChange: widget.onHoverChange,
            onPressChange: widget.onPressChange,
          );
        }
      : null;

  @override
  FocusNode? get providedFocusNode => widget.focusNode;

  @override
  String get focusDebugLabel => 'NakedButton';

  void _handleKeyboardActivation([Intent? _]) {
    if (!widget._effectiveEnabled || widget.onPressed == null) return;
    // show pressed briefly
    effectiveStatesController.update(WidgetState.pressed, true);
    if (widget.enableFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed!();
    _activationTimer?.cancel();
    _activationTimer = Timer(_activationDuration, () {
      if (mounted) {
        effectiveStatesController.update(WidgetState.pressed, false);
      }
    });
  }

  void _handleHoverChange(bool hovered) {
    if (widget.enabled) {
      updateState(WidgetState.hovered, hovered);
    }
  }

  void _handleFocusChange(bool focused) {
    updateState(WidgetState.focused, focused);
  }

  void _handlePressChange(bool pressed) {
    // Update controller-backed state
    updateState(WidgetState.pressed, pressed);
    // Also emit immediate per-event callback for robustness in integration envs
    widget.onPressChange?.call(pressed);
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
    if (widget.focusOnPress && providedFocusNode != null) {
      providedFocusNode!.requestFocus();
    }
    // Ensure pressed state is visible immediately on tap down
    _handlePressChange(true);
  }

  Widget _buildContent(BuildContext context) {
    final states = currentStates;

    return widget.builder != null
        ? widget.builder!(context, states, widget.child)
        : widget.child!;
  }

  @override
  void didUpdateWidget(covariant NakedButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller sync
    syncStatesController();
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    super.dispose();
  }

  @override
  void syncWidgetStates(WidgetStatesController controller) {
    // Only sync the disabled state from widget constructor props.
    controller.update(WidgetState.disabled, !widget.enabled);
  }

  MouseCursor get _effectiveCursor =>
      widget._effectiveEnabled ? widget.mouseCursor : SystemMouseCursors.basic;

  VoidCallback? get _semanticsTapHandler =>
      widget._effectiveEnabled ? () => _handleKeyboardActivation() : null;

  VoidCallback get _semanticsFocusHandler =>
      () => providedFocusNode?.requestFocus();

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: _handleKeyboardActivation,
          ),
        },
        child: buildFocus(
          autofocus: widget.autofocus,
          onFocusChange: _handleFocusChange,
          includeSemantics: false,
          child: Semantics(
            enabled: widget._effectiveEnabled,
            button: true,
            focusable: true,
            focused: currentStates.contains(WidgetState.focused),
            onTap: _semanticsTapHandler,
            onFocus: _semanticsFocusHandler,
            child: buildHoverRegion(
              cursor: _effectiveCursor,
              onHoverChange: _handleHoverChange,
              child: buildPressDetector(
                enabled: widget.enabled,
                behavior: HitTestBehavior.opaque,
                onPressChange: _handlePressChange,
                onTap: _handleTap,
                onTapDown: _handleTapDown,
                onDoubleTap: widget._effectiveEnabled
                    ? widget.onDoubleTap
                    : null,
                onLongPress: _handleLongPress,
                child: _buildContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
