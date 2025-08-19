import 'package:flutter/material.dart';

/// Bare-bones interactable widget providing hover, focus, and gesture states.
///
/// Design follows Flutter SDK patterns:
/// - Uses ListenableBuilder for external controller changes
/// - Conditionally adds GestureDetector when gestures present
/// - Does NOT request focus on tap by default
/// - Keyboard activation simulates pressed state for visual feedback
class NakedInteractable extends StatefulWidget {
  const NakedInteractable({
    super.key,
    required this.builder,
    this.onPressed,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.requestFocusOnTap = false,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
    this.behavior = HitTestBehavior.opaque,
    this.mouseCursor,
    this.onHoverChange,
    this.onPressChange,
    this.onFocusChange,
    this.onStateChanged,
    this.excludeFromSemantics = false,
  });

  /// Builds widget with current interaction states.
  final Widget Function(BuildContext context, Set<WidgetState> states) builder;

  /// Called when tapped.
  final VoidCallback? onPressed;

  /// Called when double tapped.
  final VoidCallback? onDoubleTap;

  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;

  /// Called when long pressed.
  final VoidCallback? onLongPress;

  /// Called when right-clicked or secondary tapped.
  final VoidCallback? onSecondaryTap;

  /// Whether this widget is enabled.
  final bool enabled;

  /// Optional external controller for state management.
  final WidgetStatesController? controller;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus this widget.
  final bool autofocus;

  /// Whether to request focus when tapped.
  final bool requestFocusOnTap;

  /// How this widget behaves during hit testing.
  final HitTestBehavior behavior;

  /// Mouse cursor for this widget.
  final MouseCursor? mouseCursor;

  /// Whether to exclude from semantics tree.
  final bool excludeFromSemantics;

  // State change callbacks
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onPressChange;
  final ValueChanged<bool>? onFocusChange;

  /// Called whenever the set of [WidgetState]s changes.
  /// Receives a copy of the current states. Mutating it does not affect the widget.
  final ValueChanged<Set<WidgetState>>? onStateChanged;

  @override
  State<NakedInteractable> createState() => _NakedInteractableState();
}

class _NakedInteractableState extends State<NakedInteractable> {
  WidgetStatesController? _internalController;
  FocusNode? _internalFocusNode;

  WidgetStatesController get _controller =>
      widget.controller ?? (_internalController ??= WidgetStatesController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool get _hasAnyGesture =>
      widget.onPressed != null ||
      widget.onDoubleTap != null ||
      widget.onLongPress != null ||
      widget.onSecondaryTap != null;

  bool get _canInteract => widget.enabled && _hasAnyGesture;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_controllerListener);
    if (!widget.enabled) {
      _controller.update(WidgetState.disabled, true);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _controller.update(WidgetState.pressed, true);
    widget.onPressChange?.call(true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    _controller.update(WidgetState.pressed, false);
    widget.onPressChange?.call(false);
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    _controller.update(WidgetState.pressed, false);
    widget.onPressChange?.call(false);
  }

  void _handleTap() {
    if (!widget.enabled || widget.onPressed == null) return;

    if (widget.requestFocusOnTap) {
      _focusNode.requestFocus();
    }

    widget.onPressed!();
  }

  void _handleDoubleTap() {
    if (!widget.enabled || widget.onDoubleTap == null) return;
    widget.onDoubleTap!();
  }

  void _handleLongPress() {
    if (!widget.enabled || widget.onLongPress == null) return;
    _controller.update(WidgetState.pressed, false);
    widget.onLongPress!();
  }

  void _handleSecondaryTap() {
    if (!widget.enabled || widget.onSecondaryTap == null) return;
    widget.onSecondaryTap!();
  }

  void _handleHoverHighlight(bool value) {
    _controller.update(WidgetState.hovered, value);
    widget.onHoverChange?.call(value);
  }

  void _handleFocusChange(bool value) {
    _controller.update(WidgetState.focused, value);
    widget.onFocusChange?.call(value);
  }

  void _handleActivateAction(Intent intent) {
    if (!widget.enabled || widget.onPressed == null) return;

    // Simulate press for visual feedback on keyboard activation
    _controller.update(WidgetState.pressed, true);
    widget.onPressChange?.call(true);
    widget.onPressed!();

    // Release press state after callback
    Future.microtask(() {
      if (mounted) {
        _controller.update(WidgetState.pressed, false);
        widget.onPressChange?.call(false);
      }
    });
  }

  void _controllerListener() {
    widget.onStateChanged?.call(Set.of(_controller.value));
  }

  @override
  void didUpdateWidget(NakedInteractable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled != oldWidget.enabled) {
      _controller.update(WidgetState.disabled, !widget.enabled);
      if (!widget.enabled && _controller.value.contains(WidgetState.pressed)) {
        _controller.update(WidgetState.pressed, false);
      }
    }

    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_controllerListener);
      _controller.addListener(_controllerListener);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_controllerListener);
    if (widget.controller == null) {
      _internalController?.dispose();
    }
    if (widget.focusNode == null) {
      _internalFocusNode?.dispose();
    }
    super.dispose();
  }

  MouseCursor get _effectiveCursor {
    if (widget.mouseCursor != null) return widget.mouseCursor!;
    if (!widget.enabled) return SystemMouseCursors.forbidden;
    if (_hasAnyGesture) return SystemMouseCursors.click;

    return MouseCursor.defer;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when controller changes
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final states = _controller.value;

        Widget result = widget.builder(context, states);

        // Add GestureDetector only if gestures are provided
        if (_hasAnyGesture) {
          result = GestureDetector(
            onTapDown: widget.onPressed != null ? _handleTapDown : null,
            onTapUp: widget.onPressed != null ? _handleTapUp : null,
            onTap: widget.onPressed != null ? _handleTap : null,
            onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
            onSecondaryTap: widget.onSecondaryTap != null
                ? _handleSecondaryTap
                : null,
            onDoubleTap: widget.onDoubleTap != null ? _handleDoubleTap : null,
            onLongPress: widget.onLongPress != null ? _handleLongPress : null,
            behavior: widget.behavior,
            excludeFromSemantics: widget.excludeFromSemantics,
            child: result,
          );
        }

        return FocusableActionDetector(
          enabled: widget.enabled,
          focusNode: _focusNode,
          autofocus: widget.autofocus && widget.enabled,
          descendantsAreFocusable: widget.descendantsAreFocusable,
          descendantsAreTraversable: widget.descendantsAreTraversable,
          actions: _canInteract && widget.onPressed != null
              ? {
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: _handleActivateAction,
                  ),
                }
              : const {},
          onShowHoverHighlight: widget.enabled ? _handleHoverHighlight : null,
          onFocusChange: widget.enabled ? _handleFocusChange : null,
          mouseCursor: _effectiveCursor,
          child: result,
        );
      },
    );
  }
}

/// Convenient getters for [WidgetStatesController].
extension WidgetStatesControllerX on WidgetStatesController {
  bool get isHovered => value.contains(WidgetState.hovered);
  bool get isFocused => value.contains(WidgetState.focused);
  bool get isPressed => value.contains(WidgetState.pressed);

  bool hasState(WidgetState state) => value.contains(state);

  void toggle(WidgetState state, bool active) => update(state, active);
}

/// Convenient getters for widget states.
extension WidgetStateSetX on Set<WidgetState> {
  bool get isHovered => contains(WidgetState.hovered);
  bool get isFocused => contains(WidgetState.focused);
  bool get isPressed => contains(WidgetState.pressed);
  bool get isDisabled => contains(WidgetState.disabled);
  bool get isEnabled => !isDisabled;
}
