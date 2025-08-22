import 'package:flutter/widgets.dart';

import 'widget_state_extensions.dart';

/// A minimal headless interactable widget providing pure interaction behavior.
///
/// This widget manages interaction states (pressed, hovered, focused, disabled, selected)
/// and provides a builder to create UI based on these states.
///
/// Example usage:
/// ```dart
/// NakedInteractable(
///   onPressed: () => print('Tapped!'),
///   builder: (context, states, child) {
///     return Container(
///       color: states.isPressed
///           ? Colors.blue
///           : Colors.grey,
///       child: child,
///     );
///   },
/// )
/// ```
class NakedInteractable extends StatefulWidget {
  const NakedInteractable({
    super.key,
    this.statesController,
    required this.builder,
    this.enabled = true,
    this.child,
    this.onHighlightChanged,
    this.onHoverChange,
    this.onFocusChange,
    this.onStateChange,
    this.selected = false,
    this.autofocus = false,
    this.focusNode,
    this.mouseCursor,
  });

  final bool enabled;

  /// Controller for widget states. If null, an internal controller is created.
  final WidgetStatesController? statesController;

  /// Builds the widget based on current states.
  final ValueWidgetBuilder<Set<WidgetState>> builder;

  /// Optional child that doesn't rebuild on state changes.
  final Widget? child;

  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onHighlightChanged;

  /// Called when any widget state changes.
  final ValueChanged<Set<WidgetState>>? onStateChange;
  final bool selected;
  final bool autofocus;
  final FocusNode? focusNode;

  /// The mouse cursor for this widget.
  final MouseCursor? mouseCursor;

  @override
  State<NakedInteractable> createState() => _NakedInteractableState();
}

class _NakedInteractableState extends State<NakedInteractable> {
  WidgetStatesController? _internalController;

  WidgetStatesController get _effectiveController =>
      widget.statesController ??
      (_internalController ??= _createInternalController());

  bool get _isDisabled => !widget.enabled;

  // Simplified cursor logic
  MouseCursor get effectiveCursor {
    if (widget.mouseCursor != null) return widget.mouseCursor!;
    if (_isDisabled) return SystemMouseCursors.forbidden;

    return SystemMouseCursors.click;
  }

  @override
  void initState() {
    super.initState();
    _effectiveController
      ..update(WidgetState.selected, widget.selected)
      ..update(WidgetState.disabled, _isDisabled)
      ..addListener(_handleStateChange);
  }

  WidgetStatesController _createInternalController() {
    return WidgetStatesController({
      if (widget.selected) WidgetState.selected,
      if (_isDisabled) WidgetState.disabled,
    });
  }

  void _handleStateChange() {
    final states = {..._effectiveController.value};
    widget.onStateChange?.call(states);
    if (mounted) {
      // ignore: avoid-empty-setstate, no-empty-block
      setState(() {}); // Rebuild for builder
    }
  }

  void _updatePressed(bool pressed) {
    if (!_isDisabled) {
      _effectiveController.update(WidgetState.pressed, pressed);
      widget.onHighlightChanged?.call(pressed);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    // Only check boundaries if currently pressed
    if (!_isDisabled &&
        _effectiveController.value.isPressed) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && !box.size.contains(event.localPosition)) {
        _effectiveController.update(WidgetState.pressed, false);
      }
    }
  }

  void _handleOnHover(bool hovered) {
    if (!_isDisabled) {
      _effectiveController.update(WidgetState.hovered, hovered);
      widget.onHoverChange?.call(hovered);
    }
  }

  void _handleOnFocus(bool focused) {
    if (!_isDisabled) {
      _effectiveController.update(WidgetState.focused, focused);
      widget.onFocusChange?.call(focused);
    }
  }

  @override
  void didUpdateWidget(NakedInteractable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller change
    if (oldWidget.statesController != widget.statesController) {
      // Remove listener from old effective controller
      final oldEffective = oldWidget.statesController ?? _internalController;
      oldEffective?.removeListener(_handleStateChange);

      // Handle internal controller lifecycle
      if (widget.statesController == null) {
        // Switching to internal - create if needed, preserving states
        if (_internalController == null) {
          _internalController = WidgetStatesController(
            oldWidget.statesController?.value ?? {},
          );
        }
      } else {
        // Switching to external - dispose internal if exists
        _internalController?.dispose();
        _internalController = null;
      }

      // Add listener to new effective controller
      // ignore: always-remove-listener
      _effectiveController.addListener(_handleStateChange);
    }

    // Always update states
    _effectiveController
      ..update(WidgetState.selected, widget.selected)
      ..update(WidgetState.disabled, _isDisabled);
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleStateChange);
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleOnFocus,
      child: MouseRegion(
        onEnter: (_) => _handleOnHover(true),
        onExit: (_) => _handleOnHover(false),
        cursor: effectiveCursor,
        child: Listener(
          onPointerDown: (_) => _updatePressed(true),
          onPointerMove: _handlePointerMove,
          onPointerUp: (_) => _updatePressed(false),
          onPointerCancel: (_) => _updatePressed(false),
          child: widget.builder(
            context,
            _effectiveController.value,
            widget.child,
          ),
        ),
      ),
    );
  }
}
