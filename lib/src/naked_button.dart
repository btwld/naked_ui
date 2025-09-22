import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart'; // WidgetStatesMixin, FocusNodeMixin
import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedButton.builder].
class NakedButtonState extends NakedState {
  NakedButtonState({required super.states});

  /// Returns the nearest [NakedButtonState] provided by [NakedStateScope].
  static NakedButtonState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedButtonState] if one is available.
  static NakedButtonState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
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

/// A headless button without visuals.
///
/// Exposes interaction states and supports keyboard activation.
/// Requires [child] or [builder] for custom rendering.
///
/// ```dart
/// NakedButton(
///   onPressed: () => print('Pressed'),
///   child: Text('Click me'),
/// )
/// ```
///
/// See also:
/// - [ElevatedButton], the Material-styled button for typical apps.
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
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// The visual contents of the button when not using [builder].
  final Widget? child;

  /// Called when the button is activated (tap, Enter/Space).
  final VoidCallback? onPressed;

  /// Called when the button is long-pressed.
  final VoidCallback? onLongPress;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Builds the button using the current [NakedButtonState].
  final NakedStateBuilder<NakedButtonState>? builder;

  /// Whether the button is enabled.
  final bool enabled;

  /// The mouse cursor when enabled.
  final MouseCursor mouseCursor;

  /// Whether to provide platform feedback on interactions.
  final bool enableFeedback;

  /// The external [FocusNode] to control focus ownership.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  /// Whether pressing the button requests focus.
  final bool focusOnPress;

  /// Tooltip text for assistive technologies.
  ///
  /// Consider providing concise text; long labels are read verbosely.
  final String? tooltip;

  /// Semantic label announced by assistive technologies.
  final String? semanticLabel;

  /// Whether the button has any interaction handlers.
  ///
  /// Returns true if either [onPressed] or [onLongPress] is provided.
  bool get _hasAnyHandler => onPressed != null || onLongPress != null;

  /// Whether the button is effectively enabled for interactions.
  ///
  /// Combines [enabled] with having at least one interaction handler.
  /// A button is only interactive if it's enabled AND has handlers.
  bool get _effectiveEnabled => enabled && _hasAnyHandler;

  @override
  State<NakedButton> createState() => _NakedButtonState();
}

class _NakedButtonState extends State<NakedButton>
    with WidgetStatesMixin<NakedButton>, FocusNodeMixin<NakedButton> {
  static const Duration _activationDuration = Duration(milliseconds: 100);
  Timer? _activationTimer;

  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;

  void _handleKeyboardActivation() {
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
    // Press state is maintained during long press hold.
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.focusOnPress) {
      // Delegates to mixin; works with internal or external node.
      requestEffectiveFocus();
    }
    updatePressState(true, widget.onPressChange);
  }

  Widget _buildContent(BuildContext context) {
    final buttonState = NakedButtonState(states: widgetStates);

    return widget.builder != null
        ? widget.builder!(context, buttonState, widget.child)
        : widget.child!;
  }

  @override
  void initializeWidgetStates() {
    updateDisabledState(!widget._effectiveEnabled);
  }

  @override
  void didUpdateWidget(covariant NakedButton oldWidget) {
    super.didUpdateWidget(
      oldWidget,
    ); // Allows FocusNodeMixin and other mixins to run first.

    // Track effective enabled state, not just the enabled property.
    if (oldWidget._effectiveEnabled != widget._effectiveEnabled) {
      updateDisabledState(!widget._effectiveEnabled);

      // Clear press state and timer if disabled during interaction.
      if (!widget._effectiveEnabled) {
        _activationTimer?.cancel();
        updatePressState(false, widget.onPressChange);
      }
    }
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    super.dispose(); // FocusNodeMixin disposes internal focus node
  }

  VoidCallback? get _semanticsTapHandler =>
      (widget.enabled && widget.onPressed != null) ? _handleTap : null;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    return NakedFocusableDetector(
      enabled: widget._effectiveEnabled,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        updateFocusState(focused, widget.onFocusChange);
      },
      onHoverChange: (hovered) {
        updateHoverState(hovered, widget.onHoverChange);
      },
      focusNode: effectiveFocusNode,
      mouseCursor: widget._effectiveEnabled
          ? widget.mouseCursor
          : SystemMouseCursors.basic,
      shortcuts: NakedIntentActions.button.shortcuts,
      actions: NakedIntentActions.button.actions(
        onPressed: () => _handleKeyboardActivation(),
      ),
      child: Semantics(
        enabled: widget._effectiveEnabled,

        button: true,
        label: widget.semanticLabel,
        tooltip: widget.tooltip,
        onTap: _semanticsTapHandler,
        onLongPress: (widget.enabled && widget.onLongPress != null)
            ? _handleLongPress
            : null,
        child: GestureDetector(
          onTapDown: widget._effectiveEnabled ? _handleTapDown : null,
          onTapUp: widget._effectiveEnabled
              ? (_) => updatePressState(false, widget.onPressChange)
              : null,
          onTap: (widget.enabled && widget.onPressed != null)
              ? _handleTap
              : null,
          onTapCancel: widget._effectiveEnabled
              ? () => updatePressState(false, widget.onPressChange)
              : null,
          onLongPress: (widget.enabled && widget.onLongPress != null)
              ? _handleLongPress
              : null,
          // Maintains press state symmetry: active during hold, cleared on end.
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
