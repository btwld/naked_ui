import 'dart:async';
import 'package:flutter/widgets.dart';

import 'naked_focusable.dart';

/// Full interactable widget with gestures + focus
class NakedInteractable extends StatefulWidget {
  const NakedInteractable({
    super.key,
    required this.builder,
    this.enabled = true, // Default to true
    this.onPressed,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
    this.onFocusChange,
    this.onHoverChange,
    this.onHighlightChanged,
    this.mouseCursor,
    this.behavior = HitTestBehavior.opaque,
    this.excludeFromSemantics = false,
  });

  final bool enabled;

  final WidgetStateBuilder builder; // Gesture callbacks
  final VoidCallback? onPressed;

  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback? onTapCancel;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap; // Focus properties
  final WidgetStatesController? statesController;

  final FocusNode? focusNode;
  final bool autofocus;

  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onHighlightChanged;
  final MouseCursor? mouseCursor; // Gesture-specific
  final HitTestBehavior behavior;

  final bool excludeFromSemantics;

  @override
  State<NakedInteractable> createState() => _NakedInteractableState();
}

class _NakedInteractableState extends State<NakedInteractable> {
  WidgetStatesController? _internalStateController;

  void _handleTapDown(TapDownDetails details) {
    if (!canPress) return;
    _setPressed(true);
    widget.onTapDown?.call(details);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!canPress) return;
    _setPressed(false);
    widget.onTapUp?.call(details);
  }

  void _handleTapCancel() {
    if (!canPress) return;
    _setPressed(false);
    widget.onTapCancel?.call();
  }

  void _handleTap() {
    if (!canPress) return;
    widget.onPressed?.call();
  }

  void _setPressed(bool pressed) {
    stateController.update(WidgetState.pressed, pressed);
    widget.onHighlightChanged?.call(pressed);
  }

  void _handleActivateAction(Intent intent) {
    if (!canPress) return;

    _setPressed(true);
    widget.onPressed!();

    // Quick visual feedback using microtask
    scheduleMicrotask(() {
      if (mounted) _setPressed(false);
    });
  }

  Map<Type, Action<Intent>> get _actionMap {
    if (!canPress) return const {};

    return {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: _handleActivateAction,
      ),
    };
  }

  WidgetStatesController get stateController =>
      widget.statesController ?? (_internalStateController ??= WidgetStatesController());

  /// Whether the widget is enabled and can receive interactions
  bool get isEnabled => widget.enabled;

  /// Whether the widget can be pressed (has onPressed and is enabled)
  bool get canPress => isEnabled && widget.onPressed != null;

  /// Whether any interactive callbacks are defined
  bool get hasInteractions => 
      widget.onPressed != null ||
      widget.onDoubleTap != null ||
      widget.onLongPress != null ||
      widget.onSecondaryTap != null;

  /// Computes the effective mouse cursor based on widget state
  MouseCursor get effectiveCursor {
    // 1. Explicit cursor always takes precedence
    if (widget.mouseCursor != null) return widget.mouseCursor!;
    
    // 2. Disabled state shows forbidden cursor
    if (!isEnabled) return SystemMouseCursors.forbidden;
    
    // 3. Interactive elements show click cursor
    if (hasInteractions) return SystemMouseCursors.click;
    
    // 4. Non-interactive elements defer to parent
    return MouseCursor.defer;
  }

  @override
  void dispose() {
    _internalStateController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NakedFocusable(
      builder: (context, states) {
        // Wrap with GestureDetector for touch/mouse interactions
        return GestureDetector(
          onTapDown: canPress ? _handleTapDown : null,
          onTapUp: canPress ? _handleTapUp : null,
          onTap: canPress ? _handleTap : null,
          onTapCancel: canPress ? _handleTapCancel : null,
          onSecondaryTap: isEnabled ? widget.onSecondaryTap : null,
          onDoubleTap: isEnabled ? widget.onDoubleTap : null,
          onLongPress: isEnabled ? widget.onLongPress : null,
          behavior: widget.behavior,
          excludeFromSemantics: widget.excludeFromSemantics,
          child: widget.builder(context, states),
        );
      },
      enabled: isEnabled,
      statesController: stateController,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      actions: _actionMap,
      descendantsAreFocusable: widget.descendantsAreFocusable,
      descendantsAreTraversable: widget.descendantsAreTraversable,
      onFocusChange: widget.onFocusChange,
      onHoverChange: widget.onHoverChange,
      mouseCursor: effectiveCursor,
    );
  }
}
