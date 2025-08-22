import 'package:flutter/widgets.dart';

import 'naked_focusable.dart';

/// Full interactable widget with gestures + focus
class NakedInteractable extends StatefulWidget {
  const NakedInteractable({
    super.key,
    required this.builder,
    this.enabled = true,
    this.selected = false,
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
    this.onStateChange,
    this.mouseCursor,
    this.behavior = HitTestBehavior.opaque,
    this.excludeFromSemantics = false,
  });

  final bool enabled;
  final bool selected;

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
  final ValueChanged<WidgetStatesDelta>? onStateChange;
  final MouseCursor? mouseCursor;
  final HitTestBehavior behavior;
  final bool excludeFromSemantics;

  @override
  State<NakedInteractable> createState() => _NakedInteractableState();
}

class _NakedInteractableState extends State<NakedInteractable> {
  WidgetStatesController? _internalController;

  WidgetStatesController get controller =>
      widget.statesController ??
      (_internalController ??= WidgetStatesController());

  // Single source of truth for interactivity
  bool get isInteractive =>
      widget.enabled &&
      (widget.onPressed != null ||
          widget.onLongPress != null ||
          widget.onDoubleTap != null ||
          widget.onSecondaryTap != null);

  // Simplified cursor logic
  MouseCursor get effectiveCursor {
    if (widget.mouseCursor != null) return widget.mouseCursor!;
    if (!isInteractive) return SystemMouseCursors.forbidden;

    return SystemMouseCursors.click;
  }

  @override
  void initState() {
    super.initState();
    _updateControllerStates();
  }

  void _updateControllerStates() {
    controller
      ..update(WidgetState.selected, widget.selected)
      ..update(WidgetState.disabled, !isInteractive);
  }

  void _handleTapDown(TapDownDetails details) {
    widget.onTapDown?.call(details);
    controller.update(WidgetState.pressed, true);
    widget.onHighlightChanged?.call(true);
  }

  void _handleTapUp(TapUpDetails details) {
    widget.onTapUp?.call(details);
    controller.update(WidgetState.pressed, false);
    widget.onHighlightChanged?.call(false);
  }

  void _handleTapCancel() {
    widget.onTapCancel?.call();
    controller.update(WidgetState.pressed, false);
    widget.onHighlightChanged?.call(false);
  }

  void _handleTap() {
    widget.onPressed?.call();
  }

  void _handleActivate(Intent intent) {
    if (widget.onPressed == null) return;

    controller.update(WidgetState.pressed, true);
    widget.onHighlightChanged?.call(true);

    // Ensure press state is cleared even if onPressed throws
    try {
      widget.onPressed!();
    } finally {
      if (mounted) {
        controller.update(WidgetState.pressed, false);
        widget.onHighlightChanged?.call(false);
      }
    }
  }

  @override
  void didUpdateWidget(NakedInteractable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateControllerStates();
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NakedFocusable(
      enabled: isInteractive,
      statesController: controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      actions: isInteractive
          ? {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: _handleActivate,
              ),
            }
          : const {},
      descendantsAreFocusable: widget.descendantsAreFocusable,
      descendantsAreTraversable: widget.descendantsAreTraversable,
      onFocusChange: widget.onFocusChange,
      onHoverChange: widget.onHoverChange,
      onStateChange: widget.onStateChange,
      mouseCursor: effectiveCursor,
      builder: (delta) {
        return GestureDetector(
          onTapDown: isInteractive ? _handleTapDown : null,
          onTapUp: isInteractive ? _handleTapUp : null,
          onTap: isInteractive ? _handleTap : null,
          onTapCancel: isInteractive ? _handleTapCancel : null,
          onSecondaryTap: widget.enabled ? widget.onSecondaryTap : null,
          onDoubleTap: widget.enabled ? widget.onDoubleTap : null,
          onLongPress: widget.enabled ? widget.onLongPress : null,
          behavior: widget.behavior,
          excludeFromSemantics: widget.excludeFromSemantics,
          child: widget.builder(delta),
        );
      },
    );
  }
}
