import 'package:flutter/widgets.dart';

// ============================================================================
// ATOMIC BEHAVIORS - Pure event detection, no state management
// ============================================================================

/// Detects focus state changes for a widget.
///
/// This widget manages the lifecycle of a [FocusNode] and reports
/// focus changes through [onFocusChange].
///
/// If [focusNode] is provided, it will be used and not disposed.
/// If null, an internal [FocusNode] is created and disposed automatically.
class FocusableBehavior extends StatefulWidget {
  const FocusableBehavior({
    super.key,
    required this.child,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// An optional focus node to use.
  /// If null, an internal node is created and managed.
  final FocusNode? focusNode;

  /// Whether this widget should be focused initially.
  final bool autofocus;

  /// Called when the focus state changes.
  final ValueChanged<bool>? onFocusChange;

  @override
  State<FocusableBehavior> createState() => _FocusableBehaviorState();
}

class _FocusableBehaviorState extends State<FocusableBehavior> {
  FocusNode? _internalNode;
  FocusNode get _effectiveNode => widget.focusNode ?? _internalNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalNode = FocusNode(debugLabel: 'FocusBehavior');
    }
  }

  @override
  void didUpdateWidget(FocusableBehavior oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle switch from internal to external node
    if (oldWidget.focusNode == null && widget.focusNode != null) {
      _internalNode?.dispose();
      _internalNode = null;
    }
    // Handle switch from external to internal node
    else if (oldWidget.focusNode != null && widget.focusNode == null) {
      _internalNode = FocusNode(debugLabel: 'FocusBehavior');
    }
  }

  @override
  void dispose() {
    _internalNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _effectiveNode,
      autofocus: widget.autofocus,
      onFocusChange: widget.onFocusChange,
      child: widget.child,
    );
  }
}

/// Detects hover state changes for a widget.
///
/// Uses [MouseRegion] to detect when a pointer enters or exits the widget.
/// Only mouse and stylus pointers trigger hover - touch does not.
class HoverableBehavior extends StatelessWidget {
  const HoverableBehavior({
    super.key,
    required this.child,
    this.onHoverChange,
    this.cursor = MouseCursor.defer,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when the hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// The mouse cursor for this widget.
  final MouseCursor cursor;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: onHoverChange != null ? (_) => onHoverChange!(true) : null,
      onExit: onHoverChange != null ? (_) => onHoverChange!(false) : null,
      cursor: cursor,
      child: child,
    );
  }
}

/// Detects press state changes for a widget.
///
/// Uses [Listener] to track pointer down/up/move events.
/// Handles edge cases like dragging outside the widget bounds.
class PressableBehavior extends StatefulWidget {
  const PressableBehavior({
    super.key,
    required this.child,
    this.onPressChange,
    this.behavior = HitTestBehavior.opaque,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when the press state changes.
  final ValueChanged<bool>? onPressChange;

  /// How this widget should behave during hit testing.
  final HitTestBehavior behavior;

  @override
  State<PressableBehavior> createState() => _PressableBehaviorState();
}

class _PressableBehaviorState extends State<PressableBehavior> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed != pressed) {
      _isPressed = pressed;
      widget.onPressChange?.call(pressed);
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
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.onPressChange != null ? _handlePointerDown : null,
      onPointerMove: widget.onPressChange != null ? _handlePointerMove : null,
      onPointerUp: widget.onPressChange != null ? _handlePointerUp : null,
      onPointerCancel: widget.onPressChange != null
          ? _handlePointerCancel
          : null,
      behavior: widget.behavior,
      child: widget.child,
    );
  }
}

// ============================================================================
// COMPOSITE BEHAVIOR - Combines all interaction behaviors
// ============================================================================

/// Composes focus, hover, and press behaviors for complete interaction handling.
///
/// The behaviors are composed in a specific order to ensure proper event handling:
/// - Focus (outermost) - Manages keyboard focus
/// - Hover (middle) - Tracks mouse/stylus hover
/// - Press (innermost) - Detects press/touch events
///
/// When [enabled] is false, all interactions are blocked via [IgnorePointer].
///
/// Example:
/// ```dart
/// InteractiveBehavior(
///   enabled: true,
///   onFocusChange: (focused) => print('Focus: $focused'),
///   onHoverChange: (hovered) => print('Hover: $hovered'),
///   onPressChange: (pressed) => print('Press: $pressed'),
///   child: Container(
///     padding: EdgeInsets.all(16),
///     color: Colors.blue,
///     child: Text('Interactive Widget'),
///   ),
/// )
/// ```
class InteractiveBehavior extends StatelessWidget {
  const InteractiveBehavior({
    super.key,
    required this.child,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.cursor = MouseCursor.defer,
    this.behavior = HitTestBehavior.opaque,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
  });

  /// The widget to apply interaction behaviors to.
  final Widget child;

  /// Whether this widget is enabled and can receive input.
  ///
  /// When false:
  /// - All interaction is blocked via [IgnorePointer]
  /// - No callbacks will be triggered
  final bool enabled;

  /// Optional focus node for focus management.
  /// If null, an internal focus node is created when needed.
  final FocusNode? focusNode;

  /// Whether to autofocus this widget.
  final bool autofocus;

  /// The mouse cursor for this widget.
  final MouseCursor cursor;

  /// How this widget should behave during hit testing.
  final HitTestBehavior behavior;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;

  @override
  Widget build(BuildContext context) {
    // Widget hierarchy (outermost to innermost):
    // IgnorePointer -> Focus -> Hover -> Press -> child
    final pressLayer = PressableBehavior(
      onPressChange: enabled ? onPressChange : null,
      behavior: behavior,
      child: child,
    );

    final hoverLayer = HoverableBehavior(
      onHoverChange: enabled ? onHoverChange : null,
      cursor: enabled ? cursor : MouseCursor.defer,
      child: pressLayer,
    );

    // Only include Focus when enabled to avoid setting isFocusable semantics
    final focusLayer = enabled
        ? FocusableBehavior(
            focusNode: focusNode,
            autofocus: autofocus,
            onFocusChange: onFocusChange,
            child: hoverLayer,
          )
        : hoverLayer;

    return IgnorePointer(ignoring: !enabled, child: focusLayer);
  }
}
