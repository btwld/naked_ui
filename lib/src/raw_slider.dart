import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Defines the threshold for determining a "fast" slider drag.
/// Measured in slider extent per second.
const double _kVelocityThreshold = 1.0;

/// The adjustment unit for keyboard navigation when no divisions are set.
const double _kAdjustmentUnit = 0.1;

/// A raw slider widget that provides dragging behavior without any visuals.
///
/// This is extracted from CupertinoSlider's behavior, removing all visual
/// rendering. Like RawRadio, this provides just the interaction logic.
class RawSlider extends StatefulWidget {
  /// Creates a raw slider.
  const RawSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    required this.child,
  }) : assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0);

  /// The currently selected value for this slider.
  final double value;

  /// Called when the user selects a new value for the slider.
  final ValueChanged<double>? onChanged;

  /// Called when the user starts selecting a new value for the slider.
  /// The value passed will be the last [value] that the slider had before the
  /// change began.
  final ValueChanged<double>? onChangeStart;

  /// Called when the user is done selecting a new value for the slider.
  final ValueChanged<double>? onChangeEnd;

  /// The minimum value the user can select.
  final double min;

  /// The maximum value the user can select.
  final double max;

  /// The number of discrete divisions.
  final int? divisions;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<RawSlider> createState() => _RawSliderState();
}

class _RawSliderState extends State<RawSlider> {
  // Drag tracking
  double _currentDragValue = 0.0;
  Duration? _lastUpdateTimestamp;

  // Focus management
  late final FocusNode _focusNode = FocusNode();

  bool get isInteractive => widget.onChanged != null;

  double get _discretizedCurrentDragValue {
    double dragValue = _currentDragValue.clamp(0.0, 1.0);
    if (widget.divisions != null) {
      dragValue = (dragValue * widget.divisions!).round() / widget.divisions!;
    }

    return dragValue;
  }

  void _handleChanged(double value, bool isFastDrag) {
    assert(widget.onChanged != null);
    final double lerpValue = lerpDouble(widget.min, widget.max, value)!;

    if (lerpValue != widget.value) {
      final bool isAtEdge = lerpValue == widget.max || lerpValue == widget.min;
      if (isAtEdge) {
        _emitHapticFeedback(isFastDrag);
      }
      widget.onChanged!(lerpValue);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (!isInteractive) return;

    _startInteraction(details);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!isInteractive) return;

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final double extent = box.size.width;
    final double valueDelta = details.primaryDelta! / extent;

    final TextDirection textDirection = Directionality.of(context);
    _currentDragValue += switch (textDirection) {
      TextDirection.rtl => -valueDelta,
      TextDirection.ltr => valueDelta,
    };

    // Calculate velocity for haptic feedback
    bool isFast = false;
    final Duration? currentTimestamp = details.sourceTimeStamp;
    if (currentTimestamp != null && _lastUpdateTimestamp != null) {
      final int timeDelta =
          (currentTimestamp - _lastUpdateTimestamp!).inMilliseconds;
      if (timeDelta > 0) {
        final double velocity = valueDelta.abs() * 1000.0 / timeDelta;
        isFast = velocity > _kVelocityThreshold;
      }
    }
    _lastUpdateTimestamp = currentTimestamp;

    _handleChanged(_discretizedCurrentDragValue, isFast);
  }

  void _handleDragEnd(DragEndDetails details) {
    _endInteraction();
  }

  void _startInteraction(DragStartDetails details) {
    if (isInteractive) {
      // Convert current value to 0-1 range
      _currentDragValue =
          (widget.value - widget.min) / (widget.max - widget.min);
      _lastUpdateTimestamp = details.sourceTimeStamp;

      widget.onChangeStart?.call(widget.value);
      _handleChanged(_discretizedCurrentDragValue, false);
    }
  }

  void _endInteraction() {
    widget.onChangeEnd?.call(widget.value);
    _currentDragValue = 0.0;
    _lastUpdateTimestamp = null;
  }

  void _emitHapticFeedback(bool isFastDrag) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        if (isFastDrag) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.selectionClick();
        }
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        break;
    }
  }

  double get _semanticActionUnit =>
      widget.divisions != null ? 1.0 / widget.divisions! : _kAdjustmentUnit;

  void _increaseAction() {
    if (isInteractive) {
      final double newValue =
          (widget.value - widget.min) / (widget.max - widget.min) +
          _semanticActionUnit;
      _handleChanged(newValue.clamp(0.0, 1.0), false);
    }
  }

  void _decreaseAction() {
    if (isInteractive) {
      final double newValue =
          (widget.value - widget.min) / (widget.max - widget.min) -
          _semanticActionUnit;
      _handleChanged(newValue.clamp(0.0, 1.0), false);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    final double normalizedValue =
        (widget.value - widget.min) / (widget.max - widget.min);

    return Semantics(
      slider: true,
      value: '${(normalizedValue * 100).round()}%',
      increasedValue:
          '${((normalizedValue + _semanticActionUnit).clamp(0.0, 1.0) * 100).round()}%',
      decreasedValue:
          '${((normalizedValue - _semanticActionUnit).clamp(0.0, 1.0) * 100).round()}%',
      onIncrease: isInteractive ? _increaseAction : null,
      onDecrease: isInteractive ? _decreaseAction : null,
      child: FocusableActionDetector(
        enabled: isInteractive,
        focusNode: _focusNode,
        shortcuts: {
          const SingleActivator(
            LogicalKeyboardKey.arrowLeft,
          ): textDirection == TextDirection.ltr
              ? const _DecrementIntent()
              : const _IncrementIntent(),
          const SingleActivator(
            LogicalKeyboardKey.arrowRight,
          ): textDirection == TextDirection.ltr
              ? const _IncrementIntent()
              : const _DecrementIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _IncrementIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _DecrementIntent(),
        },
        actions: {
          _IncrementIntent: CallbackAction<_IncrementIntent>(
            onInvoke: (_) => _increaseAction(),
          ),
          _DecrementIntent: CallbackAction<_DecrementIntent>(
            onInvoke: (_) => _decreaseAction(),
          ),
        },
        child: GestureDetector(
          onHorizontalDragStart: isInteractive ? _handleDragStart : null,
          onHorizontalDragUpdate: isInteractive ? _handleDragUpdate : null,
          onHorizontalDragEnd: isInteractive ? _handleDragEnd : null,
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            cursor: isInteractive
                ? (kIsWeb ? SystemMouseCursors.click : MouseCursor.defer)
                : SystemMouseCursors.forbidden,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _IncrementIntent extends Intent {
  const _IncrementIntent();
}

class _DecrementIntent extends Intent {
  const _DecrementIntent();
}
