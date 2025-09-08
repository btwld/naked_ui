// ABOUTME: Headless pressable widget that adds gestures and keyboard activation to NakedInteractable.
// ABOUTME: Provides tap, double-tap, long-press detection with proper feedback and focus management.
import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'naked_interactable.dart';

/// A headless pressable widget that adds gesture and keyboard activation.
///
/// Builds on [NakedInteractable] to provide:
/// - Gesture detection (tap, double-tap, long-press)
/// - Keyboard activation (Enter/Space) with visual feedback
/// - Platform-appropriate feedback
/// - Mouse cursor handling
///
/// This is the foundation for buttons and other pressable widgets.
///
/// Example:
/// ```dart
/// NakedPressable(
///   onPressed: () => print('Pressed!'),
///   enabled: true,
///   mouseCursor: SystemMouseCursors.click,
///   builder: (context, states, child) {
///     return Container(
///       padding: EdgeInsets.all(16),
///       decoration: BoxDecoration(
///         color: states.isPressed
///             ? Colors.blue.shade700
///             : states.isHovered
///                 ? Colors.blue.shade400
///                 : Colors.grey,
///       ),
///       child: Text('Press me'),
///     );
///   },
/// )
/// ```
class NakedPressable extends StatefulWidget {
  /// Creates a headless pressable widget.
  const NakedPressable({
    super.key,
    required this.builder,
    this.onPressed,
    this.onDoubleTap,
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
    this.error = false,
    this.mouseCursor,
    this.disabledMouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.onStatesChange,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
    this.statesController,
    this.child,
    this.behavior = HitTestBehavior.opaque,
    this.enableFeedback = true,
    this.focusOnPress = false,
  });

  /// Builds the widget based on current interaction states.
  final ValueWidgetBuilder<Set<WidgetState>> builder;

  /// Called when the widget is tapped or activated via keyboard.
  final VoidCallback? onPressed;

  /// Called when the widget is double tapped.
  final VoidCallback? onDoubleTap;

  /// Called when the widget is long pressed.
  final VoidCallback? onLongPress;

  /// Whether this widget responds to input.
  final bool enabled;

  /// Whether this widget is in a selected state.
  final bool selected;

  /// Whether this widget has an error state.
  final bool error;

  /// Mouse cursor when the widget is interactive.
  final MouseCursor? mouseCursor;

  /// Mouse cursor when the widget is disabled.
  final MouseCursor? disabledMouseCursor;

  /// Controls focus state for this widget.
  final FocusNode? focusNode;

  /// Whether this widget should be focused initially.
  final bool autofocus;

  /// Called whenever the widget state set changes.
  final ValueChanged<Set<WidgetState>>? onStatesChange;

  /// Called when the focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when the hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when the pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Controls the widget states externally.
  final WidgetStatesController? statesController;

  /// Optional child widget that doesn't rebuild when states change.
  final Widget? child;

  /// How to behave during hit tests.
  final HitTestBehavior behavior;

  /// Whether to provide platform-specific feedback on activation.
  final bool enableFeedback;

  /// Whether to request focus when the widget is tapped.
  final bool focusOnPress;

  @override
  State<NakedPressable> createState() => _NakedPressableState();
}

class _NakedPressableState extends State<NakedPressable> {
  /// Duration for keyboard activation visual feedback.
  static const Duration _activationDuration = Duration(milliseconds: 100);

  /// Timer for clearing pressed state after keyboard activation.
  Timer? _activationTimer;

  /// Internal controller for managing pressed state during keyboard activation.
  WidgetStatesController? _keyboardController;

  /// Whether this widget should respond to interactions.
  bool get _isInteractive =>
      widget.enabled &&
      (widget.onPressed != null ||
          widget.onDoubleTap != null ||
          widget.onLongPress != null);

  /// Gets the effective controller, creating keyboard controller if needed.
  WidgetStatesController get _effectiveController {
    if (widget.statesController != null) {
      return widget.statesController!;
    }

    // For keyboard activation, we need our own controller
    return _keyboardController ??= WidgetStatesController({
      if (widget.selected) WidgetState.selected,
      if (widget.error) WidgetState.error,
      if (!widget.enabled) WidgetState.disabled,
    });
  }

  /// Handles keyboard activation with proper pressed state animation.
  void _handleKeyboardActivation(Intent? intent) {
    if (!_isInteractive || widget.onPressed == null) return;

    final controller = _effectiveController;

    // Cancel any existing activation timer
    _activationTimer?.cancel();

    // Set pressed state for visual feedback
    controller.update(WidgetState.pressed, true);
    widget.onPressChange?.call(true);

    // Trigger haptic feedback for keyboard activation
    if (widget.enableFeedback) {
      HapticFeedback.lightImpact();
    }

    // Call the onPressed callback
    widget.onPressed!();

    // Delay clearing pressed state to show visual feedback
    _activationTimer = Timer(_activationDuration, () {
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            controller.update(WidgetState.pressed, false);
            widget.onPressChange?.call(false);
          }
        });
      }
    });
  }

  /// Handles tap gesture.
  void _handleTap() {
    if (!_isInteractive || widget.onPressed == null) return;

    if (widget.enableFeedback) {
      Feedback.forTap(context);
    }

    if (widget.focusOnPress && widget.focusNode != null) {
      widget.focusNode!.requestFocus();
    }

    widget.onPressed!();
  }

  /// Handles long press gesture.
  void _handleLongPress() {
    if (!_isInteractive || widget.onLongPress == null) return;

    if (widget.enableFeedback) {
      Feedback.forLongPress(context);
    }

    widget.onLongPress!();
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    _keyboardController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine mouse cursor based on interactive state
    final effectiveCursor = _isInteractive
        ? (widget.mouseCursor ?? SystemMouseCursors.click)
        : (widget.disabledMouseCursor ?? SystemMouseCursors.basic);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: _handleKeyboardActivation,
          ),
        },
        child: GestureDetector(
          onTap: _isInteractive ? _handleTap : null,
          onDoubleTap: _isInteractive ? widget.onDoubleTap : null,
          onLongPress: _isInteractive ? _handleLongPress : null,
          behavior: widget.behavior,
          excludeFromSemantics: true,
          child: NakedInteractable(
            statesController: _effectiveController,
            enabled: widget.enabled,
            selected: widget.selected,
            error: widget.error,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            cursor: effectiveCursor,
            behavior: widget.behavior,
            onStatesChange: widget.onStatesChange,
            onFocusChange: widget.onFocusChange,
            onHoverChange: widget.onHoverChange,
            onPressChange: widget.onPressChange,
            child: widget.child,
            builder: widget.builder,
          ),
        ),
      ),
    );
  }
}
