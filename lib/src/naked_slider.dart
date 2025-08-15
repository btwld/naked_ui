import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable slider with no default styling.
///
/// Provides interaction behavior and keyboard navigation without visual styling.
/// Supports discrete divisions and both horizontal and vertical orientation.
class NakedSlider extends StatefulWidget {
  /// Creates a naked slider.
  const NakedSlider({
    super.key,
    required this.child,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.onDragStart,
    this.onDragEnd,
    this.onHoveredState,
    this.onDraggedState,
    this.onFocusedState,
    this.enabled = true,
    this.semanticLabel,
    this.cursor = SystemMouseCursors.click,
    this.focusNode,
    this.direction = Axis.horizontal,
    this.divisions,
    this.keyboardStep = 0.01,
    this.largeKeyboardStep = 0.1,
    this.excludeSemantics = false,
  }) : assert(min < max, 'min must be less than max');

  /// The child widget to display.
  final Widget child;

  /// The current value of the slider.
  final double value;

  /// Minimum value of the slider.
  final double min;

  /// Maximum value of the slider.
  final double max;

  /// Called when the slider value changes.
  final ValueChanged<double>? onChanged;

  /// Called when the user starts dragging the slider.
  final VoidCallback? onDragStart;

  /// Called when the user ends dragging the slider.
  final ValueChanged<double>? onDragEnd;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoveredState;

  /// Called when dragging state changes.
  final ValueChanged<bool>? onDraggedState;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusedState;

  /// Whether the slider is disabled.
  ///
  /// When true, the slider will not respond to user interaction.
  final bool enabled;

  /// Optional semantic label for accessibility.
  ///
  /// This is used by screen readers to describe the slider.
  final String? semanticLabel;

  /// The cursor to show when hovering over the slider.
  final MouseCursor cursor;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Direction of the slider.
  final Axis direction;

  /// Number of discrete divisions.
  final int? divisions;

  /// Step size for keyboard navigation.
  final double keyboardStep;

  /// Step size for large keyboard navigation.
  final double largeKeyboardStep;

  /// Whether to exclude child semantics from the semantic tree.
  final bool excludeSemantics;

  @override
  State<NakedSlider> createState() => _NakedSliderState();
}

class _NakedSliderState extends State<NakedSlider> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  bool _isDragging = false;

  Offset? _dragStartPosition;
  double? _dragStartValue;

  void _callOnChangeIfNeeded(double value) {
    if (value != widget.value) {
      widget.onChanged?.call(value);
    }
  }

  double _normalizeValue(double value) {
    // Ensure value is within bounds
    double normalizedValue = value.clamp(widget.min, widget.max);

    // Apply divisions if specified
    if (widget.divisions != null) {
      double step = (widget.max - widget.min) / widget.divisions!;
      int steps = ((normalizedValue - widget.min) / step).round();
      normalizedValue = widget.min + steps * step;
    }

    return normalizedValue;
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enabled || widget.onChanged == null) return;

    setState(() {
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
      _dragStartValue = widget.value;
    });

    widget.onDraggedState?.call(true);
    widget.onDragStart?.call();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || !widget.enabled || widget.onChanged == null) return;

    // Calculate the drag delta in the proper direction
    final Offset currentPosition = details.globalPosition;
    final Offset dragDelta = currentPosition - _dragStartPosition!;

    // Get the RenderBox of the slider
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    // Convert the drag delta to a value change
    double dragExtent = widget.direction == Axis.horizontal
        ? box.size.width
        : box.size.height;

    double dragDistance = widget.direction == Axis.horizontal
        ? dragDelta.dx
        : -dragDelta.dy; // Invert for vertical slider (up is positive)

    double valueDelta = dragDistance / dragExtent * (widget.max - widget.min);
    double newValue = _normalizeValue(_dragStartValue! + valueDelta);

    if (newValue != widget.value) {
      widget.onChanged?.call(newValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
      _dragStartValue = null;
    });

    widget.onDraggedState?.call(false);
    widget.onDragEnd?.call(widget.value);
  }

  double _calculateStep(bool isShiftPressed) {
    final divisions = widget.divisions;
    if (divisions != null) return (widget.max - widget.min) / divisions;

    return isShiftPressed ? widget.largeKeyboardStep : widget.keyboardStep;
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  bool get _isInteractive => widget.enabled && widget.onChanged != null;

  Map<ShortcutActivator, Intent> get _shortcuts {
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;
    const arrowLeft = LogicalKeyboardKey.arrowLeft;
    const arrowRight = LogicalKeyboardKey.arrowRight;
    const arrowUp = LogicalKeyboardKey.arrowUp;
    const arrowDown = LogicalKeyboardKey.arrowDown;
    const home = LogicalKeyboardKey.home;
    const end = LogicalKeyboardKey.end;

    final decrementIntent = SingleActivator(isRTL ? arrowRight : arrowLeft);
    final incrementIntent = SingleActivator(isRTL ? arrowLeft : arrowRight);

    final shiftDecrementIntent = SingleActivator(
      isRTL ? arrowRight : arrowLeft,
      shift: true,
    );
    final shiftIncrementIntent = SingleActivator(
      isRTL ? arrowLeft : arrowRight,
      shift: true,
    );

    return {
      // Horizontal
      incrementIntent: const _SliderIncrementIntent(),
      decrementIntent: const _SliderDecrementIntent(),
      shiftDecrementIntent: const _SliderShiftDecrementIntent(),
      shiftIncrementIntent: const _SliderShiftIncrementIntent(),

      // Vertical
      const SingleActivator(arrowUp): const _SliderIncrementIntent(),
      const SingleActivator(arrowUp, shift: true):
          const _SliderShiftIncrementIntent(),

      const SingleActivator(arrowDown): const _SliderDecrementIntent(),
      const SingleActivator(arrowDown, shift: true):
          const _SliderShiftDecrementIntent(),

      // Home/End
      const SingleActivator(home): const _SliderSetToMinIntent(),
      const SingleActivator(end): const _SliderSetToMaxIntent(),
    };
  }

  Map<Type, Action<Intent>> get _actions {
    return {
      _SliderIncrementIntent: _SliderIncrementAction(this),
      _SliderDecrementIntent: _SliderDecrementAction(this),
      _SliderShiftDecrementIntent: _SliderDecrementAction(
        this,
        isShiftPressed: true,
      ),
      _SliderShiftIncrementIntent: _SliderIncrementAction(
        this,
        isShiftPressed: true,
      ),
      _SliderSetToMinIntent: _SliderSetToMinAction(this),
      _SliderSetToMaxIntent: _SliderSetToMaxAction(this),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage for accessibility
    final double percentage = widget.max > widget.min
        ? ((widget.value - widget.min) / (widget.max - widget.min)) * 100
        : 0.0;

    // Calculate value change for accessibility notifications
    final double step = widget.keyboardStep;
    final double increasedValue = _normalizeValue(widget.value + step);
    final double decreasedValue = _normalizeValue(widget.value - step);

    return Semantics(
      excludeSemantics: widget.excludeSemantics,
      enabled: _isInteractive,
      slider: true,
      label: widget.semanticLabel,
      value: '${percentage.round()}%',
      increasedValue:
          '${((increasedValue - widget.min) / (widget.max - widget.min) * 100).round()}%',
      decreasedValue:
          '${((decreasedValue - widget.min) / (widget.max - widget.min) * 100).round()}%',
      child: FocusableActionDetector(
        enabled: _isInteractive,
        focusNode: _focusNode,
        descendantsAreTraversable: false,
        shortcuts: _shortcuts,
        actions: _actions,
        onShowHoverHighlight: widget.onHoveredState,
        onFocusChange: widget.onFocusedState,
        mouseCursor: _isInteractive
            ? widget.cursor
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onVerticalDragStart:
              widget.direction == Axis.vertical && _isInteractive
              ? _handleDragStart
              : null,
          onVerticalDragUpdate:
              widget.direction == Axis.vertical && _isInteractive
              ? _handleDragUpdate
              : null,
          onVerticalDragEnd: widget.direction == Axis.vertical && _isInteractive
              ? _handleDragEnd
              : null,
          onHorizontalDragStart:
              widget.direction == Axis.horizontal && _isInteractive
              ? _handleDragStart
              : null,
          onHorizontalDragUpdate:
              widget.direction == Axis.horizontal && _isInteractive
              ? _handleDragUpdate
              : null,
          onHorizontalDragEnd:
              widget.direction == Axis.horizontal && _isInteractive
              ? _handleDragEnd
              : null,
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        ),
      ),
    );
  }
}

class _SliderShiftIncrementIntent extends _SliderIncrementIntent {
  const _SliderShiftIncrementIntent();
}

class _SliderShiftDecrementIntent extends _SliderDecrementIntent {
  const _SliderShiftDecrementIntent();
}

class _SliderIncrementIntent extends Intent {
  const _SliderIncrementIntent();
}

class _SliderDecrementIntent extends Intent {
  const _SliderDecrementIntent();
}

class _SliderSetToMinIntent extends Intent {
  const _SliderSetToMinIntent();
}

class _SliderSetToMaxIntent extends Intent {
  const _SliderSetToMaxIntent();
}

// Create actions that respond to these intents

class _SliderIncrementAction extends Action<_SliderIncrementIntent> {
  final _NakedSliderState state;

  final bool isShiftPressed;
  _SliderIncrementAction(this.state, {this.isShiftPressed = false});

  @override
  void invoke(_SliderIncrementIntent intent) {
    final step = state._calculateStep(isShiftPressed);

    final newValue = state._normalizeValue(state.widget.value + step);
    state._callOnChangeIfNeeded(newValue);
  }
}

class _SliderDecrementAction extends Action<_SliderDecrementIntent> {
  final _NakedSliderState state;

  final bool isShiftPressed;
  _SliderDecrementAction(this.state, {this.isShiftPressed = false});

  @override
  void invoke(_SliderDecrementIntent intent) {
    final step = state._calculateStep(isShiftPressed);

    final newValue = state._normalizeValue(state.widget.value - step);
    state._callOnChangeIfNeeded(newValue);
  }
}

class _SliderSetToMinAction extends Action<_SliderSetToMinIntent> {
  final _NakedSliderState state;

  _SliderSetToMinAction(this.state);

  @override
  void invoke(_SliderSetToMinIntent intent) {
    state._callOnChangeIfNeeded(state.widget.min);
  }
}

class _SliderSetToMaxAction extends Action<_SliderSetToMaxIntent> {
  final _NakedSliderState state;

  _SliderSetToMaxAction(this.state);

  @override
  void invoke(_SliderSetToMaxIntent intent) {
    state._callOnChangeIfNeeded(state.widget.max);
  }
}
