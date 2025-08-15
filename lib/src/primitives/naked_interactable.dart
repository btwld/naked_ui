import 'package:flutter/material.dart';

/// A headless interactive primitive that unifies hover, focus, and press
/// handling into a single Set<WidgetState> model.
///
/// Key principles:
/// - Enabled logic is determined exclusively by [enabled]. The presence of
///   [onPressed] must not affect whether this widget is considered enabled/disabled.
/// - Consumers decide how to compute and pass [enabled] (e.g., a button may pass
///   `enabled && onPressed != null`).
/// - Hover and focus states are tracked when [enabled] is true.
/// - Pressed state and activation are only meaningful when [enabled] is true; if
///   [onPressed] is null, pressed visuals/handlers are not attached.
class NakedInteractable extends StatefulWidget {
  const NakedInteractable({
    super.key,
    required this.builder,
    this.onPressed,
    this.enabled = true,
    this.autofocus = false,
    this.behavior = HitTestBehavior.opaque,
    this.focusNode,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
    this.mouseCursor,
    this.onHoverChange,
    this.onPressChange,
    this.onFocusChange,
  });

  /// Builds the widget tree based on current interaction states.
  ///
  /// The builder receives a Set<WidgetState> which can contain:
  /// - WidgetState.hovered
  /// - WidgetState.focused
  /// - WidgetState.pressed
  /// - WidgetState.disabled
  final Widget Function(BuildContext context, Set<WidgetState> states) builder;

  /// Called when the control is activated via tap/click/keyboard.
  final VoidCallback? onPressed;

  /// Whether this control should be considered enabled.
  ///
  /// This flag alone determines disabled state and whether hover/focus are tracked.
  final bool enabled;

  /// Whether this control should request focus initially.
  final bool autofocus;

  /// Gesture hit test behavior when gestures are attached.
  final HitTestBehavior behavior;

  /// Optional focus node to control focus programmatically.
  final FocusNode? focusNode;

  /// Whether descendants of this control can receive focus.
  final bool descendantsAreFocusable;

  /// Whether descendants are traversable via keyboard navigation.
  final bool descendantsAreTraversable;

  /// Optional override for mouse cursor. If null, defaults to:
  /// - forbidden when disabled
  /// - click when enabled and has handler
  /// - defer when enabled and no handler
  final MouseCursor? mouseCursor;

  /// Optional callbacks for state changes.
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onPressChange;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<NakedInteractable> createState() => _NakedInteractableState();
}

class _NakedInteractableState extends State<NakedInteractable> {
  late final FocusNode _focusNode;
  final Set<WidgetState> _states = <WidgetState>{};

  bool _ownsFocusNode = false;

  bool get _hasHandler => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _syncEnabledState();
  }

  void _syncEnabledState() {
    if (!widget.enabled && !_states.contains(WidgetState.disabled)) {
      setState(() => _states.add(WidgetState.disabled));
    } else if (widget.enabled && _states.contains(WidgetState.disabled)) {
      setState(() => _states.remove(WidgetState.disabled));
    }
  }

  void _updateState(WidgetState state, bool add) {
    final hadState = _states.contains(state);
    if (add && !hadState) {
      setState(() => _states.add(state));
    } else if (!add && hadState) {
      setState(() => _states.remove(state));
    }

    if (state == WidgetState.pressed && hadState != add) {
      widget.onPressChange?.call(add);
    }
  }

  void _handleActivate() {
    if (!widget.enabled || !_hasHandler) return;

    // Show pressed state briefly for keyboard activation
    _updateState(WidgetState.pressed, true);
    widget.onPressed!();
    // Reset pressed state after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateState(WidgetState.pressed, false);
      }
    });
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || !_hasHandler) return;
    _updateState(WidgetState.pressed, true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || !_hasHandler) return;
    _updateState(WidgetState.pressed, false);
  }

  void _handleTapCancel() {
    if (!widget.enabled || !_hasHandler) return;
    _updateState(WidgetState.pressed, false);
  }

  @override
  void didUpdateWidget(NakedInteractable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      if (widget.focusNode != null) {
        _ownsFocusNode = false;
        _focusNode = widget.focusNode!;
      } else {
        _ownsFocusNode = true;
        _focusNode = FocusNode();
      }
    }
    _syncEnabledState();
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  MouseCursor get _cursor {
    if (!widget.enabled) return SystemMouseCursors.forbidden;
    if (widget.mouseCursor != null) return widget.mouseCursor!;

    return _hasHandler ? SystemMouseCursors.click : MouseCursor.defer;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = FocusableActionDetector(
      enabled: widget.enabled,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      descendantsAreFocusable: widget.descendantsAreFocusable,
      descendantsAreTraversable: widget.descendantsAreTraversable,
      actions: widget.enabled && _hasHandler
          ? {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  _handleActivate();

                  return null;
                },
              ),
            }
          : const {},
      onShowHoverHighlight: (value) {
        if (!widget.enabled) return;
        _updateState(WidgetState.hovered, value);
        widget.onHoverChange?.call(value);
      },
      onFocusChange: (value) {
        if (!widget.enabled) return;
        _updateState(WidgetState.focused, value);
        widget.onFocusChange?.call(value);
      },
      mouseCursor: _cursor,
      child: widget.builder(context, Set.unmodifiable(_states)),
    );

    if (widget.enabled && _hasHandler) {
      child = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTap: _handleActivate,
        onTapCancel: _handleTapCancel,
        behavior: widget.behavior,
        excludeFromSemantics: true,
        child: child,
      );
    }

    return child;
  }
}

/// Extension methods for cleaner state checking.
extension WidgetStateSetX on Set<WidgetState> {
  bool get isHovered => contains(WidgetState.hovered);
  bool get isFocused => contains(WidgetState.focused);
  bool get isPressed => contains(WidgetState.pressed);
  bool get isDisabled => contains(WidgetState.disabled);
  bool get isEnabled => !isDisabled;
}
