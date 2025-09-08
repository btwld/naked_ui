// ABOUTME: Interactive widget that handles focus, hover, and press states with built-in state management.
// ABOUTME: Provides complete interaction handling through a builder pattern for custom styling.
import 'package:flutter/widgets.dart';

import 'naked_focusable.dart';

// Re-export the WidgetStateExtensions for convenience
export 'widget_state_extensions.dart';

/// Handles focus, hover, and press behaviors for complete interaction handling.
///
/// The behaviors are composed in a specific order to ensure proper event handling:
/// - Focus (outermost) - Manages keyboard focus
/// - Hover (middle) - Tracks mouse/stylus hover
/// - Press (innermost) - Detects press/touch events
///
/// When [enabled] is false, all interactions are blocked via [IgnorePointer].
///
/// This widget provides state management and interaction detection, but no gestures
/// or keyboard activation. For full button behavior, use [NakedPressable].
///
/// Example:
/// ```dart
/// NakedInteractable(
///   enabled: true,
///   selected: false,
///   onFocusChange: (focused) => print('Focus: $focused'),
///   onHoverChange: (hovered) => print('Hover: $hovered'),
///   onPressChange: (pressed) => print('Press: $pressed'),
///   builder: (context, states, child) {
///     return Container(
///       padding: EdgeInsets.all(16),
///       decoration: BoxDecoration(
///         color: states.isPressed
///             ? Colors.blue.shade700
///             : states.isHovered
///                 ? Colors.blue.shade400
///                 : Colors.grey,
///         border: states.isFocused
///             ? Border.all(color: Colors.black, width: 2)
///             : null,
///       ),
///       child: Text('Interactive Widget'),
///     );
///   },
/// )
/// ```
class NakedInteractable extends StatefulWidget {
  /// Creates an interactive widget with composed behaviors.
  const NakedInteractable({
    super.key,
    required this.builder,
    this.statesController,
    this.enabled = true,
    this.selected = false,
    this.error = false,
    this.focusNode,
    this.autofocus = false,
    this.cursor = MouseCursor.defer,
    this.behavior = HitTestBehavior.opaque,
    this.child,
    this.onStatesChange,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
  });

  /// Builds the widget based on current interaction states.
  final ValueWidgetBuilder<Set<WidgetState>> builder;

  /// Controls the widget states externally.
  final WidgetStatesController? statesController;

  /// Whether this widget responds to input.
  final bool enabled;

  /// Whether this widget is in a selected state.
  final bool selected;

  /// Whether this widget has an error state.
  final bool error;

  /// Optional focus node for focus management.
  final FocusNode? focusNode;

  /// Whether to autofocus this widget.
  final bool autofocus;

  /// The mouse cursor for this widget.
  final MouseCursor cursor;

  /// How this widget should behave during hit testing.
  final HitTestBehavior behavior;

  /// Optional child widget that doesn't rebuild when states change.
  final Widget? child;

  /// Called whenever the widget state set changes.
  final ValueChanged<Set<WidgetState>>? onStatesChange;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;

  @override
  State<NakedInteractable> createState() => _NakedInteractableState();
}

class _NakedInteractableState extends State<NakedInteractable> {
  WidgetStatesController? _internalController;
  bool _isPressed = false;

  WidgetStatesController get _effectiveController =>
      widget.statesController ??
      (_internalController ??= _createInternalController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_handleStateChange);
  }

  /// Creates an internal controller with initial states.
  WidgetStatesController _createInternalController() {
    return WidgetStatesController({
      if (widget.selected) WidgetState.selected,
      if (widget.error) WidgetState.error,
      if (!widget.enabled) WidgetState.disabled,
    });
  }

  /// Notifies listeners when states change and triggers rebuild.
  void _handleStateChange() {
    widget.onStatesChange?.call({..._effectiveController.value});
    if (mounted) {
      // ignore: avoid-empty-setstate, no-empty-block
      setState(() {});
    }
  }

  /// Handles focus state changes and updates controller.
  void _handleFocusChange(bool focused) {
    _effectiveController.update(WidgetState.focused, focused);
    widget.onFocusChange?.call(focused);
  }

  /// Handles hover state changes and updates controller.
  void _handleHoverChange(bool hovered) {
    if (!widget.enabled) return;
    _effectiveController.update(WidgetState.hovered, hovered);
    widget.onHoverChange?.call(hovered);
  }

  /// Handles press state changes and updates controller.
  void _handlePressChange(bool pressed) {
    if (!widget.enabled) return;
    _effectiveController.update(WidgetState.pressed, pressed);
    widget.onPressChange?.call(pressed);
  }

  // Press detection methods
  void _setPressed(bool pressed) {
    if (_isPressed != pressed) {
      _isPressed = pressed;
      _handlePressChange(pressed);
    }
  }

  bool _isPointerWithinBounds(Offset localPosition) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;

    return box != null && box.size.contains(localPosition);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _setPressed(true);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isPressed && !_isPointerWithinBounds(event.localPosition)) {
      _setPressed(false);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _setPressed(false);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _setPressed(false);
  }

  @override
  void didUpdateWidget(NakedInteractable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (oldWidget.statesController != widget.statesController) {
      _effectiveController.removeListener(_handleStateChange);
      if (widget.statesController == null) {
        // Switching to internal controller - preserve existing states
        _internalController ??= WidgetStatesController(
          oldWidget.statesController?.value ?? {},
        );
      } else {
        // Switching to external controller - dispose internal
        _internalController?.dispose();
        _internalController = null;
      }
      _effectiveController.addListener(_handleStateChange);
    }

    // Only update states that actually changed
    if (oldWidget.selected != widget.selected) {
      _effectiveController.update(WidgetState.selected, widget.selected);
    }
    if (oldWidget.error != widget.error) {
      _effectiveController.update(WidgetState.error, widget.error);
    }
    if (oldWidget.enabled != widget.enabled) {
      _effectiveController.update(WidgetState.disabled, !widget.enabled);

      // Clear transient states when becoming disabled
      if (!widget.enabled) {
        _effectiveController
          ..update(WidgetState.hovered, false)
          ..update(WidgetState.pressed, false)
          ..update(WidgetState.focused, false);

        // Notify callbacks of clearing
        widget.onHoverChange?.call(false);
        widget.onPressChange?.call(false);
        widget.onFocusChange?.call(false);
      }
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleStateChange);
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build child with current states
    final builtChild = widget.builder(
      context,
      _effectiveController.value,
      widget.child,
    );

    // Widget hierarchy (outermost to innermost):
    // IgnorePointer -> Focus -> MouseRegion -> Listener -> child
    final listenerLayer = Listener(
      onPointerDown: widget.enabled && widget.onPressChange != null
          ? _handlePointerDown
          : null,
      onPointerMove: widget.enabled && widget.onPressChange != null
          ? _handlePointerMove
          : null,
      onPointerUp: widget.enabled && widget.onPressChange != null
          ? _handlePointerUp
          : null,
      onPointerCancel: widget.enabled && widget.onPressChange != null
          ? _handlePointerCancel
          : null,
      behavior: widget.behavior,
      child: builtChild,
    );

    final mouseRegionLayer = MouseRegion(
      onEnter: widget.enabled && widget.onHoverChange != null
          ? (_) => _handleHoverChange(true)
          : null,
      onExit: widget.enabled && widget.onHoverChange != null
          ? (_) => _handleHoverChange(false)
          : null,
      cursor: widget.enabled ? widget.cursor : MouseCursor.defer,
      child: listenerLayer,
    );

    final focusLayer = widget.enabled
        ? NakedFocusable(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onFocusChange: _handleFocusChange,
            child: mouseRegionLayer,
          )
        : mouseRegionLayer;

    return IgnorePointer(ignoring: !widget.enabled, child: focusLayer);
  }
}
