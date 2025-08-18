import 'package:flutter/material.dart';

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
    this.onDisabledChange,
    this.excludeFromSemantics = true,
  });

  final Widget Function(BuildContext context, Set<WidgetState> states) builder;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool autofocus;
  final HitTestBehavior behavior;
  final FocusNode? focusNode;
  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;
  final MouseCursor? mouseCursor;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onPressChange;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onDisabledChange;
  final bool excludeFromSemantics;

  @override
  State<NakedInteractable> createState() => _NakedInteractableState();
}

class _NakedInteractableState extends State<NakedInteractable> {
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  bool get _ownsFocusNode => widget.focusNode == null;
  bool get _isInteractive => widget.enabled && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.canRequestFocus = widget.enabled;
    // Call onDisabledChange with initial disabled state after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDisabledChange?.call(!widget.enabled);
      }
    });
  }

  void _setHovered(bool value) {
    if (_isHovered != value) {
      setState(() => _isHovered = value);
      widget.onHoverChange?.call(value);
    }
  }

  void _setFocused(bool value) {
    if (_isFocused != value) {
      setState(() => _isFocused = value);
      widget.onFocusChange?.call(value);
    }
  }

  void _setPressed(bool value) {
    if (_isPressed != value) {
      setState(() => _isPressed = value);
      widget.onPressChange?.call(value);
    }
  }

  void _handleActivate() {
    if (!_isInteractive) return;
    if (!_isPressed) {
      _setPressed(true);
      Future.microtask(() {
        if (mounted) _setPressed(false);
      });
    }
    widget.onPressed!();
  }

  @override
  void didUpdateWidget(NakedInteractable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
    // Keep focus ability in sync with enabled
    _focusNode.canRequestFocus = widget.enabled;

    // Call onDisabledChange if disabled state changed
    if (widget.enabled != oldWidget.enabled) {
      widget.onDisabledChange?.call(!widget.enabled);
    }

    if (!widget.enabled && oldWidget.enabled && _isPressed) {
      _isPressed =
          false; // No setState in didUpdateWidget; build will run anyway
      widget.onPressChange?.call(false);
    }
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  Set<WidgetState> get _states => {
    if (!widget.enabled) WidgetState.disabled,
    if (_isHovered) WidgetState.hovered,
    if (_isFocused) WidgetState.focused,
    if (_isPressed) WidgetState.pressed,
  };

  MouseCursor get _cursor {
    return switch (widget.mouseCursor) {
      MouseCursor cursor => cursor,
      null when !widget.enabled => SystemMouseCursors.forbidden,
      null when widget.onPressed != null => SystemMouseCursors.click,
      null => MouseCursor.defer,
    };
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.builder(context, _states);

    content = GestureDetector(
      onTapDown: (_) {
        if (_isInteractive) _setPressed(true);
      },
      onTapUp: (_) {
        if (_isInteractive) _setPressed(false);
      },
      onTap: () {
        if (_isInteractive) {
          _setPressed(false);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (_isInteractive) _setPressed(false);
      },
      behavior: widget.behavior,
      excludeFromSemantics: widget.excludeFromSemantics,
      child: content,
    );

    return FocusableActionDetector(
      enabled: widget.enabled,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      descendantsAreFocusable: widget.enabled && widget.descendantsAreFocusable,
      descendantsAreTraversable: widget.descendantsAreTraversable,
      actions: _isInteractive
          ? {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) => _handleActivate(),
              ),
            }
          : const {},
      onShowHoverHighlight: widget.enabled ? _setHovered : null,
      onFocusChange: widget.enabled ? _setFocused : null,
      mouseCursor: _cursor,
      child: content,
    );
  }
}

extension WidgetStateSetX on Set<WidgetState> {
  bool get isHovered => contains(WidgetState.hovered);
  bool get isFocused => contains(WidgetState.focused);
  bool get isPressed => contains(WidgetState.pressed);
  bool get isDisabled => contains(WidgetState.disabled);
  bool get isEnabled => !isDisabled;
}
