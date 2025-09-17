import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart'; // uses WidgetStatesMixin

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

      // Vertical (unchanged)
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

/// A headless slider without visuals.
///
/// Controlled by [value] in range [[min], [max]]. Supports discrete
/// [divisions] or continuous values. Handles keyboard navigation and
/// drag gestures.
///
/// ```dart
/// NakedSlider(
///   value: sliderValue,
///   onChanged: (value) => setState(() => sliderValue = value),
///   child: MyCustomSliderTrack(),
/// )
/// ```
///
/// See also:
/// - [Slider], the Material-styled slider for typical apps.
/// - [FocusableActionDetector], used to integrate keyboard and focus handling.
class NakedSlider extends StatefulWidget {
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
    this.mouseCursor = SystemMouseCursors.click,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.direction = Axis.horizontal,
    this.divisions,
    this.keyboardStep = 0.01,
    this.largeKeyboardStep = 0.1,
    this.semanticLabel,
  }) : assert(min < max, 'min must be less than max');

  /// The slider content (track/handle/etc.).
  final Widget child;

  /// The current slider value.
  final double value;

  /// The minimum value of the range.
  final double min;

  /// The maximum value of the range.
  final double max;

  /// Called when the value changes.
  final ValueChanged<double>? onChanged;

  /// Called when a drag begins.
  final VoidCallback? onDragStart;

  /// Called when a drag ends.
  final ValueChanged<double>? onDragEnd;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when drag state changes.
  final ValueChanged<bool>? onDragChange;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// The enabled state of the slider.
  final bool enabled;

  /// The mouse cursor when enabled.
  final MouseCursor mouseCursor;

  /// The haptic feedback enablement flag.
  final bool enableFeedback;

  /// The focus node for the slider.
  final FocusNode? focusNode;

  /// The autofocus flag.
  final bool autofocus;

  /// The slider orientation.
  final Axis direction;

  /// The number of discrete divisions. When null, continuous.
  final int? divisions;

  /// The small keyboard step when [divisions] is null.
  final double keyboardStep;

  /// The large keyboard step when holding Shift.
  final double largeKeyboardStep;

  /// The semantic label for assistive technologies.
  final String? semanticLabel;

  @override
  State<NakedSlider> createState() => _NakedSliderState();
}

class _NakedSliderState extends State<NakedSlider>
    with WidgetStatesMixin<NakedSlider> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ??
      (_internalFocusNode ??= FocusNode(debugLabel: 'NakedSlider'));

  bool _isDragging = false;
  // track latest normalized value we told the world about
  double? _lastEmittedValue;
  Offset? _dragStartPosition;
  double? _dragStartValue;

  // ---------------------------
  // Helpers & lifecycle
  // ---------------------------

  bool get _isEnabled => widget.enabled && widget.onChanged != null;
  bool get _isRTL => Directionality.of(context) == TextDirection.rtl;

  MouseCursor get _cursor =>
      _isEnabled ? widget.mouseCursor : SystemMouseCursors.basic;

  // ---------------------------
  // Value math & normalization
  // ---------------------------

  void _callOnChangeIfNeeded(double value) {
    _lastEmittedValue = value;
    if (value != widget.value) {
      widget.onChanged?.call(value);
    }
  }

  double _normalizeValue(double value) {
    // Clamp to bounds
    double v = value.clamp(widget.min, widget.max);

    // Snap to divisions if provided
    final divisions = widget.divisions;
    if (divisions != null && divisions > 0) {
      final step = (widget.max - widget.min) / divisions;
      final steps = ((v - widget.min) / step).round();
      v = widget.min + steps * step;
      // Avoid tiny floating drift outside bounds
      v = v.clamp(widget.min, widget.max);
    }

    return v;
  }

  double _calculateStep(bool isShiftPressed) {
    final divisions = widget.divisions;
    if (divisions != null && divisions > 0) {
      return (widget.max - widget.min) / divisions;
    }

    return isShiftPressed ? widget.largeKeyboardStep : widget.keyboardStep;
  }

  String _percentString(double v) {
    final total = widget.max - widget.min;
    if (total == 0) return '0%';
    final pct = (((v - widget.min) / total) * 100).round();

    return '$pct%';
  }

  // (no absolute-position jump; drag uses relative deltas for expected behavior)

  // ---------------------------
  // Pointer handlers
  // ---------------------------

  void _handleDragStart(DragStartDetails details) {
    if (!_isEnabled) return;

    _isDragging = true;
    _dragStartPosition = details.globalPosition;
    _dragStartValue = widget.value;

    updateState(WidgetState.pressed, true);
    widget.onDragChange?.call(true);
    widget.onDragStart?.call();

    // Ensure subsequent keyboard nudges apply here.
    if (_focusNode.canRequestFocus) _focusNode.requestFocus();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || !_isEnabled) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || _dragStartPosition == null || _dragStartValue == null)
      return;

    final Offset dragDelta = details.globalPosition - _dragStartPosition!;
    final double dragExtent = widget.direction == Axis.horizontal
        ? box.size.width
        : box.size.height;
    if (dragExtent <= 0) return;

    final double dragDistance = widget.direction == Axis.horizontal
        ? (_isRTL ? -dragDelta.dx : dragDelta.dx)
        : -dragDelta.dy; // up increases for vertical

    final double valueDelta =
        (dragDistance / dragExtent) * (widget.max - widget.min);
    final double newValue = _normalizeValue(_dragStartValue! + valueDelta);

    if (newValue != widget.value) {
      _callOnChangeIfNeeded(newValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;
    _dragStartPosition = null;
    _dragStartValue = null;

    updateState(WidgetState.pressed, false);
    widget.onDragChange?.call(false);

    final v = _lastEmittedValue ?? widget.value;
    widget.onDragEnd?.call(v);
  }

  void _handleDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _dragStartPosition = null;
    _dragStartValue = null;
    updateState(WidgetState.pressed, false);
    widget.onDragChange?.call(false);

    final v = _lastEmittedValue ?? widget.value;
    widget.onDragEnd?.call(v);
  }

  @override
  void initializeWidgetStates() {
    updateDisabledState(!_isEnabled);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep focus traversal flags aligned with enablement.
    _focusNode
      ..canRequestFocus = _isEnabled
      ..skipTraversal = !_isEnabled;
  }

  @override
  void didUpdateWidget(covariant NakedSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Keep state flags in sync (handles enabled and onChanged changes).
    syncWidgetStates();

    // Clear transient states when disabled.
    if (!_isEnabled) {
      updateState(WidgetState.hovered, false);
      updateState(WidgetState.pressed, false);
    }

    // If the focusNode source changed, swap internal/external cleanly and preserve focus.
    if (oldWidget.focusNode != widget.focusNode) {
      final oldEffective = oldWidget.focusNode ?? _internalFocusNode;
      final hadFocus = oldEffective?.hasFocus ?? false;

      if (oldWidget.focusNode == null && widget.focusNode != null) {
        // internal -> external
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      } else if (oldWidget.focusNode != null && widget.focusNode == null) {
        // external -> internal
        _internalFocusNode = FocusNode(debugLabel: 'NakedSlider');
      }

      if (hadFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
    }

    // Maintain traversal flags under prop changes.
    _focusNode
      ..canRequestFocus = _isEnabled
      ..skipTraversal = !_isEnabled;

    // Keep last value in step with controller updates.
    _lastEmittedValue = widget.value;
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  // ---------------------------
  // Keyboard actions/shortcuts
  // ---------------------------

  Map<ShortcutActivator, Intent> get _shortcuts {
    final rtl = _isRTL;

    return rtl ? _kSliderShortcutsRtl : _kSliderShortcutsLtr;
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

  // ---------------------------
  // Build
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    final childGesture = GestureDetector(
      onVerticalDragStart: widget.direction == Axis.vertical && _isEnabled
          ? _handleDragStart
          : null,
      onVerticalDragUpdate: widget.direction == Axis.vertical && _isEnabled
          ? _handleDragUpdate
          : null,
      onVerticalDragEnd: widget.direction == Axis.vertical && _isEnabled
          ? _handleDragEnd
          : null,
      onVerticalDragCancel: widget.direction == Axis.vertical && _isEnabled
          ? _handleDragCancel
          : null,
      // Only one axis active to avoid competing recognizers.
      onHorizontalDragStart: widget.direction == Axis.horizontal && _isEnabled
          ? _handleDragStart
          : null,
      onHorizontalDragUpdate: widget.direction == Axis.horizontal && _isEnabled
          ? _handleDragUpdate
          : null,
      onHorizontalDragEnd: widget.direction == Axis.horizontal && _isEnabled
          ? _handleDragEnd
          : null,
      onHorizontalDragCancel: widget.direction == Axis.horizontal && _isEnabled
          ? _handleDragCancel
          : null,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true, // semantics provided by the wrapper below
      child: widget.child,
    );

    return FocusableActionDetector(
      enabled: _isEnabled,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      descendantsAreTraversable: false, // no focus into the visual child
      shortcuts: _shortcuts,
      actions: _actions,
      onShowHoverHighlight: (hover) =>
          updateHoverState(hover, widget.onHoverChange),
      onFocusChange: (focused) =>
          updateFocusState(focused, widget.onFocusChange),
      mouseCursor: _cursor,
      child: Semantics(
        container: true,
        enabled: _isEnabled,
        slider: true,
        focusable: _isEnabled,
        focused: isFocused,
        label: widget.semanticLabel,
        value: _percentString(widget.value),
        increasedValue: _percentString(
          _normalizeValue(widget.value + _calculateStep(false)),
        ),
        decreasedValue: _percentString(
          _normalizeValue(widget.value - _calculateStep(false)),
        ),
        onIncrease: _isEnabled
            ? () {
                final step = _calculateStep(false);
                _callOnChangeIfNeeded(_normalizeValue(widget.value + step));
              }
            : null,
        onDecrease: _isEnabled
            ? () {
                final step = _calculateStep(false);
                _callOnChangeIfNeeded(_normalizeValue(widget.value - step));
              }
            : null,
        child: childGesture,
      ),
    );
  }
}

// ---- Intents ----

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

// ---- Actions ----

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
