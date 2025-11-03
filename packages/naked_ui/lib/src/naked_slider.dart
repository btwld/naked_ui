import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedSlider.builder].
class NakedSliderState extends NakedState {
  /// The current slider value.
  final double value;

  /// The minimum value of the slider.
  final double min;

  /// The maximum value of the slider.
  final double max;

  /// The number of discrete divisions, if any.
  final int? divisions;

  /// Whether the slider is currently being dragged.
  final bool isDragging;

  NakedSliderState({
    required super.states,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.isDragging,
  });

  /// Returns the nearest [NakedSliderState] provided by [NakedStateScope].
  static NakedSliderState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedSliderState] if one is available.
  static NakedSliderState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);

  /// The slider value as a percentage (0.0 to 1.0).
  double get percentage => (value - min) / (max - min);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedSliderState &&
        setEquals(other.states, states) &&
        other.value == value &&
        other.min == min &&
        other.max == max &&
        other.divisions == divisions &&
        other.isDragging == isDragging;
  }

  @override
  int get hashCode =>
      Object.hash(states, value, min, max, divisions, isDragging);
}

/// A headless slider without visuals.
///
/// Controlled by [value] in the range
/// from [min] to [max]. Supports discrete [divisions] or continuous values.
/// Handles keyboard navigation and drag gestures.
///
/// The [builder] receives a [NakedSliderState] with the current value,
/// range information, and interaction states.
///
/// ```dart
/// NakedSlider(
///   value: sliderValue,
///   onChanged: (value) => setState(() => sliderValue = value),
///   builder: (context, state, child) => MyCustomSliderTrack(
///     value: state.value,
///     isDragging: state.isDragging,
///     isHovered: state.isHovered,
///   ),
/// )
/// ```
///
/// See also:
/// - [Slider], the Material-styled slider for typical apps.
/// - [NakedFocusableDetector], used to integrate keyboard and focus handling.
class NakedSlider extends StatefulWidget {
  const NakedSlider({
    super.key,
    this.child,
    this.builder,
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
    this.excludeSemantics = false,
  }) : assert(min < max, 'min must be less than max'),
       assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// The slider content (track/handle/etc.).
  final Widget? child;

  /// Builds the slider using the current [NakedSliderState].
  final ValueWidgetBuilder<NakedSliderState>? builder;

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

  /// Whether the slider is enabled.
  final bool enabled;

  /// The mouse cursor when enabled.
  final MouseCursor mouseCursor;

  /// Whether to provide haptic feedback on interactions.
  final bool enableFeedback;

  /// The focus node for the slider.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  /// The slider orientation.
  final Axis direction;

  /// The number of discrete divisions. When null, the value is continuous.
  final int? divisions;

  /// The small keyboard step when [divisions] is null.
  final double keyboardStep;

  /// The large keyboard step when holding Shift.
  final double largeKeyboardStep;

  /// Semantic label for assistive technologies.
  final String? semanticLabel;

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, the widget and its children are hidden from accessibility services.
  final bool excludeSemantics;

  @override
  State<NakedSlider> createState() => _NakedSliderState();
}

class _NakedSliderState extends State<NakedSlider>
    with WidgetStatesMixin<NakedSlider>, FocusNodeMixin<NakedSlider> {
  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;

  bool _isDragging = false;
  // track latest normalized value we told the world about
  double? _lastEmittedValue;
  Offset? _dragStartPosition;
  double? _dragStartValue;

  bool get _isEnabled => widget.enabled && widget.onChanged != null;
  bool get _isRTL => Directionality.of(context) == TextDirection.rtl;

  MouseCursor get _cursor =>
      _isEnabled ? widget.mouseCursor : SystemMouseCursors.basic;

  void _callOnChangeIfNeeded(double value) {
    _lastEmittedValue = value;
    if (value != widget.value) {
      widget.onChanged?.call(value);
    }
  }

  double _normalizeValue(double value) {
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

  void _handleDragStart(DragStartDetails details) {
    if (!_isEnabled) return;

    _isDragging = true;
    _dragStartPosition = details.globalPosition;
    _dragStartValue = widget.value;

    updateState(WidgetState.pressed, true);
    widget.onDragChange?.call(true);
    widget.onDragStart?.call();

    if (effectiveFocusNode.canRequestFocus) effectiveFocusNode.requestFocus();
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
    final node = effectiveFocusNode;
    node
      ..canRequestFocus = _isEnabled
      ..skipTraversal = !_isEnabled;
  }

  @override
  void didUpdateWidget(covariant NakedSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    syncWidgetStates();

    if (!_isEnabled) {
      updateState(WidgetState.hovered, false);
      updateState(WidgetState.pressed, false);
    }

    final node2 = effectiveFocusNode;
    node2
      ..canRequestFocus = _isEnabled
      ..skipTraversal = !_isEnabled;

    _lastEmittedValue = widget.value;
  }

  Map<ShortcutActivator, Intent> get _shortcuts {
    return NakedIntentActions.slider.shortcuts(isRTL: _isRTL);
  }

  Map<Type, Action<Intent>> get _actions {
    return NakedIntentActions.slider.actions(
      onChanged: _callOnChangeIfNeeded,
      calculateStep: _calculateStep,
      normalizeValue: _normalizeValue,
      currentValue: widget.value,
      minValue: widget.min,
      maxValue: widget.max,
      enableFeedback: widget.enableFeedback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sliderState = NakedSliderState(
      states: widgetStates,
      value: widget.value,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      isDragging: _isDragging,
    );

    final content = widget.builder != null
        ? Builder(
            builder: (context) {
              return widget.builder!(context, sliderState, widget.child);
            },
          )
        : widget.child!;

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
      excludeFromSemantics: true,
      child: content,
    );

    final wrappedContent = NakedStateScope(
      value: sliderState,
      child: childGesture,
    );

    return NakedFocusableDetector(
      enabled: _isEnabled,
      autofocus: widget.autofocus,
      descendantsAreTraversable: false,
      onFocusChange: (focused) =>
          updateFocusState(focused, widget.onFocusChange),
      onHoverChange: (hover) => updateHoverState(hover, widget.onHoverChange),
      focusNode: effectiveFocusNode,
      mouseCursor: _cursor,
      shortcuts: _shortcuts,
      actions: _actions,
      child: widget.excludeSemantics
          ? wrappedContent
          : Semantics(
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
                      _callOnChangeIfNeeded(
                        _normalizeValue(widget.value + step),
                      );
                    }
                  : null,
              onDecrease: _isEnabled
                  ? () {
                      final step = _calculateStep(false);
                      _callOnChangeIfNeeded(
                        _normalizeValue(widget.value - step),
                      );
                    }
                  : null,
              child: wrappedContent,
            ),
    );
  }
}
