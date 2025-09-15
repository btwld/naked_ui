import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'mixins/naked_mixins.dart'; // WidgetStatesMixin, FocusableMixin

/// A headless, focusable button that exposes interaction states.
///
/// - No visuals are provided; pass a [child] or a [builder] to render UI.
/// - Keyboard: Enter/Space activate the button. Optional [focusOnPress].
/// - Semantics: exposes a "button" role and supports [tooltip]/[semanticLabel].
/// - States: when using [builder], you receive a `Set<WidgetState>` that
///   reflects the current hovered/pressed/focused/disabled states.
///
/// See also:
/// - [NakedMenuItem], which composes a menu item from [NakedButton].
/// - [FocusableActionDetector], the underlying keyboard/hover integration.
/// - [TextButton], [ElevatedButton], and [FilledButton] for Material-styled
///   buttons when you don’t need a headless control.
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

  /// Visual contents of the button when not using [builder].
  final Widget? child;

  /// Called when the button is activated (tap, Enter/Space).
  final VoidCallback? onPressed;

  /// Called when the button is long-pressed.
  final VoidCallback? onLongPress;

  /// Called when the button is double-tapped.
  final VoidCallback? onDoubleTap;

  /// Notifies when focus changes. Receives `true` when focused.
  final ValueChanged<bool>? onFocusChange;

  /// Notifies when hover changes. Receives `true` when hovered.
  final ValueChanged<bool>? onHoverChange;

  /// Notifies when pressed (highlight) changes. Receives `true` when down.
  final ValueChanged<bool>? onPressChange;

  /// Builder that receives the current interaction [WidgetState]s.
  ///
  /// The signature is `(BuildContext, Set<WidgetState>, Widget? child)`.
  /// Use this to render custom visuals based on button state.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Whether the button is enabled.
  ///
  /// The button is effectively enabled only if [enabled] is true and at least
  /// one handler among [onPressed], [onLongPress], or [onDoubleTap] is set.
  final bool enabled;

  /// Mouse cursor when the button is enabled.
  final MouseCursor mouseCursor;

  /// Whether to provide platform haptic/aural feedback on activation.
  final bool enableFeedback;

  /// Optional external [FocusNode] to control focus ownership.
  final FocusNode? focusNode;

  /// Whether to autofocus this button on build.
  final bool autofocus;

  /// Whether pressing requests focus in addition to activating.
  final bool focusOnPress;

  /// Optional tooltip exposed to assistive technologies.
  ///
  /// Consider providing concise text; long labels are read verbosely.
  final String? tooltip;

  /// Optional semantic label announced by screen readers.
  final String? semanticLabel;

  // Consider button interactive if any handler is provided.
  bool get _hasAnyHandler =>
      onPressed != null || onLongPress != null || onDoubleTap != null;

  // Effective enabled combines `enabled` with having at least one handler.
  bool get _effectiveEnabled => enabled && _hasAnyHandler;

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
      (widget.enabled && widget.onPressed != null) ? _handleTap : null;

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
        onLongPress:
            (widget.enabled && widget.onLongPress != null) ? _handleLongPress : null,
        child: GestureDetector(
          onTapDown: widget._effectiveEnabled ? _handleTapDown : null,
          onTapUp: widget._effectiveEnabled
              ? (_) => updatePressState(false, widget.onPressChange)
              : null,
          onTap: (widget.enabled && widget.onPressed != null) ? _handleTap : null,
          onTapCancel: widget._effectiveEnabled
              ? () => updatePressState(false, widget.onPressChange)
              : null,
          onDoubleTap:
              (widget.enabled && widget.onDoubleTap != null) ? widget.onDoubleTap : null,
          onLongPress:
              (widget.enabled && widget.onLongPress != null) ? _handleLongPress : null,
          // Long-press symmetry: pressed while holding, clear on end.
          onLongPressStart: (widget.enabled && widget.onLongPress != null)
              ? (_) => updatePressState(true, widget.onPressChange)
              : null,
          onLongPressEnd: (widget.enabled && widget.onLongPress != null)
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
