import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/utilities.dart';

// Slider keyboard shortcuts (left-to-right layout)
const Map<ShortcutActivator, Intent> _kSliderShortcutsLtr =
    <ShortcutActivator, Intent>{
      // Horizontal
      SingleActivator(LogicalKeyboardKey.arrowRight): _SliderIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft): _SliderDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
          _SliderShiftDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
          _SliderShiftIncrementIntent(),

      // Vertical
      SingleActivator(LogicalKeyboardKey.arrowUp): _SliderIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
          _SliderShiftIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): _SliderDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
          _SliderShiftDecrementIntent(),

      // Home/End
      SingleActivator(LogicalKeyboardKey.home): _SliderSetToMinIntent(),
      SingleActivator(LogicalKeyboardKey.end): _SliderSetToMaxIntent(),
    };

// Slider keyboard shortcuts (right-to-left layout)
const Map<ShortcutActivator, Intent> _kSliderShortcutsRtl =
    <ShortcutActivator, Intent>{
      // Horizontal (swapped for RTL)
      SingleActivator(LogicalKeyboardKey.arrowLeft): _SliderIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowRight): _SliderDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
          _SliderShiftDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
          _SliderShiftIncrementIntent(),

      // Vertical
      SingleActivator(LogicalKeyboardKey.arrowUp): _SliderIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
          _SliderShiftIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): _SliderDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
          _SliderShiftDecrementIntent(),

      // Home/End
      SingleActivator(LogicalKeyboardKey.home): _SliderSetToMinIntent(),
      SingleActivator(LogicalKeyboardKey.end): _SliderSetToMaxIntent(),
    };

/// Provides slider interaction behavior without visual styling.
///
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
    this.onHoverChange,
    this.onDragChange,
    this.onFocusChange,
    this.enabled = true,
    this.semanticLabel,
    this.semanticHint,
    this.mouseCursor = SystemMouseCursors.click,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.direction = Axis.horizontal,
    this.divisions,
    this.keyboardStep = 0.01,
    this.largeKeyboardStep = 0.1,
    this.excludeSemantics = false,
    this.statesController,
  }) : assert(min < max, 'min must be less than max');

  /// Child widget to display.
  final Widget child;

  /// Current value of the slider.
  final double value;

  /// Minimum slider value.
  final double min;

  /// Maximum slider value.
  final double max;

  /// Called when the slider value changes.
  final ValueChanged<double>? onChanged;

  /// Called when dragging starts.
  final VoidCallback? onDragStart;

  /// Called when dragging ends.
  final ValueChanged<double>? onDragEnd;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when dragging state changes.
  final ValueChanged<bool>? onDragChange;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Whether the slider is enabled.
  final bool enabled;

  /// Semantic label for screen readers.
  final String? semanticLabel;

  /// Semantic hint for screen readers.
  final String? semanticHint;

  /// Cursor when hovering over the slider.
  final MouseCursor mouseCursor;

  /// Whether to provide haptic feedback on keyboard navigation.
  final bool enableFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to automatically request focus when created.
  final bool autofocus;

  /// Slider direction.
  final Axis direction;

  /// Number of discrete divisions.
  final int? divisions;

  /// Keyboard navigation step size.
  final double keyboardStep;

  /// Large keyboard navigation step size.
  final double largeKeyboardStep;

  /// Whether to exclude child semantics.
  final bool excludeSemantics;

  /// Optional external controller for interaction states.
  final WidgetStatesController? statesController;

  @override
  State<NakedSlider> createState() => _NakedSliderState();
}

class _NakedSliderState extends State<NakedSlider> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  bool _isDragging = false;

  WidgetStatesController? _internalController;
  WidgetStatesController get _controller =>
      widget.statesController ??
      (_internalController ??= WidgetStatesController());

  // Hover and focus are tracked via the states controller only

  Offset? _dragStartPosition;
  double? _dragStartValue;

  @override
  void initState() {
    super.initState();
    // Initialize disabled state based on interactivity
    _controller.update(WidgetState.disabled, !_isEnabled);
  }

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

    _isDragging = true;
    _dragStartPosition = details.globalPosition;
    _dragStartValue = widget.value;

    _controller.update(WidgetState.pressed, true);

    widget.onDragChange?.call(true);
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

    // Invert for vertical slider (up is positive)
    double dragDistance = widget.direction == Axis.horizontal
        ? dragDelta.dx
        : -dragDelta.dy;

    double valueDelta = dragDistance / dragExtent * (widget.max - widget.min);
    double newValue = _normalizeValue(_dragStartValue! + valueDelta);

    if (newValue != widget.value) {
      widget.onChanged?.call(newValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;
    _dragStartPosition = null;
    _dragStartValue = null;

    _controller.update(WidgetState.pressed, false);

    widget.onDragChange?.call(false);
    widget.onDragEnd?.call(widget.value);
  }

  double _calculateStep(bool isShiftPressed) {
    final divisions = widget.divisions;
    if (divisions != null) return (widget.max - widget.min) / divisions;

    return isShiftPressed ? widget.largeKeyboardStep : widget.keyboardStep;
  }

  // No bulk state setter; we update individual flags per event.

  void _handleHoverChange(bool value) {
    if (!_isEnabled) return;
    _controller.update(WidgetState.hovered, value);
    widget.onHoverChange?.call(value);
  }

  void _handleFocusChange(bool value) {
    _controller.update(WidgetState.focused, value);
    widget.onFocusChange?.call(value);
  }

  Widget _buildSliderInteractable() {
    return FocusableActionDetector(
      enabled: _isEnabled,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      descendantsAreTraversable: false,
      shortcuts: _shortcuts,
      actions: _actions,
      onShowHoverHighlight: _handleHoverChange,
      onFocusChange: _handleFocusChange,
      mouseCursor: _cursor,
      child: MouseRegion(
        onEnter: (_) => _handleHoverChange(true),
        onExit: (_) => _handleHoverChange(false),
        cursor: _cursor,
        child: GestureDetector(
          onVerticalDragStart: widget.direction == Axis.vertical && _isEnabled
              ? _handleDragStart
              : null,
          onVerticalDragUpdate: widget.direction == Axis.vertical && _isEnabled
              ? _handleDragUpdate
              : null,
          onVerticalDragEnd: widget.direction == Axis.vertical && _isEnabled
              ? _handleDragEnd
              : null,
          onHorizontalDragStart:
              widget.direction == Axis.horizontal && _isEnabled
              ? _handleDragStart
              : null,
          onHorizontalDragUpdate:
              widget.direction == Axis.horizontal && _isEnabled
              ? _handleDragUpdate
              : null,
          onHorizontalDragEnd: widget.direction == Axis.horizontal && _isEnabled
              ? _handleDragEnd
              : null,
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(NakedSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statesController != oldWidget.statesController) {
      if (widget.statesController != null) {
        _internalController?.dispose();
        _internalController = null;
      } else {
        _internalController ??= WidgetStatesController();
      }
    }
    // Sync disabled state when interactivity changes
    _controller.update(WidgetState.disabled, !_isEnabled);
    if (!_isEnabled) {
      // Clear transient hover/pressed states when disabled
      _controller
        ..update(WidgetState.hovered, false)
        ..update(WidgetState.pressed, false);
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  bool get _isEnabled => widget.enabled && widget.onChanged != null;

  MouseCursor get _cursor =>
      _isEnabled ? widget.mouseCursor : SystemMouseCursors.forbidden;

  Map<ShortcutActivator, Intent> get _shortcuts {
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    return isRTL ? _kSliderShortcutsRtl : _kSliderShortcutsLtr;
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

    if (widget.excludeSemantics) {
      // If excluding semantics, use original Semantics widget
      return Semantics(
        excludeSemantics: true,
        child: _buildSliderInteractable(),
      );
    }

    // Use direct Semantics for Material parity
    return Semantics(
      excludeSemantics: widget.excludeSemantics,
      enabled: _isEnabled,
      slider: true,
      focusable: _isEnabled,
      label: widget.semanticLabel ?? '',
      value: '${percentage.round()}%',
      increasedValue:
          '${((increasedValue - widget.min) / (widget.max - widget.min) * 100).round()}%',
      decreasedValue:
          '${((decreasedValue - widget.min) / (widget.max - widget.min) * 100).round()}%',
      hint: widget.semanticHint,
      onIncrease: _isEnabled
          ? () => _callOnChangeIfNeeded(increasedValue)
          : null,
      onDecrease: _isEnabled
          ? () => _callOnChangeIfNeeded(decreasedValue)
          : null,
      // Expose focus action when enabled
      onFocus: _isEnabled ? semanticsFocusNoop : null,
      child: ExcludeSemantics(
        excluding: !_isEnabled,
        child: _buildSliderInteractable(),
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
    if (state.widget.enableFeedback && newValue != state.widget.value) {
      HapticFeedback.selectionClick();
    }
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
    if (state.widget.enableFeedback && newValue != state.widget.value) {
      HapticFeedback.selectionClick();
    }
    state._callOnChangeIfNeeded(newValue);
  }
}

class _SliderSetToMinAction extends Action<_SliderSetToMinIntent> {
  final _NakedSliderState state;

  _SliderSetToMinAction(this.state);

  @override
  void invoke(_SliderSetToMinIntent intent) {
    if (state.widget.enableFeedback && state.widget.value != state.widget.min) {
      HapticFeedback.selectionClick();
    }
    state._callOnChangeIfNeeded(state.widget.min);
  }
}

class _SliderSetToMaxAction extends Action<_SliderSetToMaxIntent> {
  final _NakedSliderState state;

  _SliderSetToMaxAction(this.state);

  @override
  void invoke(_SliderSetToMaxIntent intent) {
    if (state.widget.enableFeedback && state.widget.value != state.widget.max) {
      HapticFeedback.selectionClick();
    }
    state._callOnChangeIfNeeded(state.widget.max);
  }
}
