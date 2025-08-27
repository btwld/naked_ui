import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'naked_interactable.dart';

/// A headless pressable widget that handles gestures and keyboard activation.
///
/// Wraps [NakedInteractable] with gesture detection, keyboard shortcuts,
/// and mouse cursor behavior. Provides proper visual feedback during
/// keyboard activation by temporarily setting the pressed state.
///
/// This widget follows Material Design patterns for button behavior:
/// - Keyboard activation (Enter/Space) shows pressed state for 100ms
/// - Mouse cursor changes based on enabled state
/// - Haptic feedback on activation
///
/// Example:
/// ```dart
/// NakedPressable(
///   onPressed: () => print('Pressed!'),
///   enabled: true,
///   mouseCursor: SystemMouseCursors.click,
///   disabledMouseCursor: SystemMouseCursors.forbidden,
///   builder: (context, states, child) {
///     return Container(
///       padding: EdgeInsets.all(16),
///       decoration: BoxDecoration(
///         color: states.contains(WidgetState.pressed)
///             ? Colors.blue.shade700
///             : states.contains(WidgetState.hovered)
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
  ///
  /// The builder receives the current [WidgetState] set and an optional
  /// child widget that doesn't rebuild when states change.
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
  ///
  /// Defaults to [SystemMouseCursors.click] when enabled.
  final MouseCursor? mouseCursor;

  /// Mouse cursor when the widget is disabled.
  ///
  /// Defaults to [SystemMouseCursors.basic] when disabled.
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
  ///
  /// On Android: plays system click sound for taps, vibration for long press
  /// On iOS: no feedback for taps, sound + heavy haptic for long press
  /// For keyboard activation: always uses light haptic feedback
  final bool enableFeedback;

  /// Whether to request focus when the widget is tapped.
  ///
  /// When true, tapping the widget will request focus in addition to
  /// calling the onPressed callback. This is useful for form controls
  /// and input widgets where focus indication after interaction improves
  /// user experience.
  ///
  /// Defaults to false to maintain Material Design consistency where
  /// tapping buttons does not automatically focus them.
  ///
  /// Only takes effect if a [focusNode] is provided and the widget is enabled.
  final bool focusOnPress;

  @override
  State<NakedPressable> createState() => _NakedPressableState();
}

class _NakedPressableState extends State<NakedPressable> {
  /// Duration for keyboard activation visual feedback.
  ///
  /// Matches Material Design button behavior from InkWell.
  static const Duration _activationDuration = Duration(milliseconds: 100);

  /// Timer for clearing pressed state after keyboard activation.
  Timer? _activationTimer;

  /// Internal controller when external one is not provided.
  WidgetStatesController? _internalController;

  /// Gets the effective controller (external or internal).
  WidgetStatesController get _effectiveController =>
      widget.statesController ??
      (_internalController ??= WidgetStatesController());

  /// Whether this widget should respond to interactions.
  bool get _isInteractive =>
      widget.enabled &&
      (widget.onPressed != null ||
          widget.onDoubleTap != null ||
          widget.onLongPress != null);

  @override
  void initState() {
    super.initState();
    // Initialize internal controller if needed
    if (widget.statesController == null) {
      _internalController = WidgetStatesController();
    }
  }

  /// Clears transient states (hover, pressed, focused).
  ///
  /// Called when the widget becomes disabled to ensure
  /// visual consistency and proper state management.
  void _clearTransientStates() {
    _effectiveController
      ..update(WidgetState.hovered, false)
      ..update(WidgetState.pressed, false)
      ..update(WidgetState.focused, false);

    // Notify callbacks
    widget.onHoverChange?.call(false);
    widget.onPressChange?.call(false);
    widget.onFocusChange?.call(false);
  }

  /// Handles keyboard activation with proper pressed state animation.
  ///
  /// Follows Material Design pattern from InkWell:
  /// 1. Set pressed state immediately for visual feedback
  /// 2. Trigger haptic feedback and callback
  /// 3. Use timer to clear pressed state after 100ms
  void _handleKeyboardActivation(Intent? intent) {
    if (!_isInteractive || widget.onPressed == null) return;

    // Cancel any existing activation timer
    _activationTimer?.cancel();
    _activationTimer = null;

    // Set pressed state for visual feedback
    _effectiveController.update(WidgetState.pressed, true);
    widget.onPressChange?.call(true);

    // Trigger haptic feedback for keyboard activation
    // Keyboard activation always uses haptic, regardless of platform
    if (widget.enableFeedback) {
      HapticFeedback.lightImpact();
    }

    // Call the onPressed callback
    widget.onPressed!();

    // Delay clearing pressed state to show visual feedback
    // This matches Material button behavior and gives users visual confirmation
    _activationTimer = Timer(_activationDuration, () {
      if (mounted) {
        // Use addPostFrameCallback to avoid setState during build
        // This follows Flutter's official recommendation for state updates
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _effectiveController.update(WidgetState.pressed, false);
            widget.onPressChange?.call(false);
          }
        });
      }
    });
  }

  /// Handles tap gesture.
  void _handleTap() {
    if (!_isInteractive || widget.onPressed == null) return;

    // Provide platform-specific feedback for tap
    // Android: click sound, iOS: nothing, others: nothing
    if (widget.enableFeedback) {
      Feedback.forTap(context);
    }

    // Request focus if focusOnPress is enabled and widget has a focusNode
    if (widget.focusOnPress && widget.focusNode != null) {
      widget.focusNode!.requestFocus();
    }

    // Call the onPressed callback
    widget.onPressed!();
  }

  /// Handles long press gesture.
  void _handleLongPress() {
    if (!_isInteractive || widget.onLongPress == null) return;

    // Provide platform-specific feedback for long press
    // Android: vibration, iOS: sound + heavy haptic, others: nothing
    if (widget.enableFeedback) {
      Feedback.forLongPress(context);
    }

    // Call the onLongPress callback
    widget.onLongPress!();
  }

  @override
  void didUpdateWidget(NakedPressable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes between external and internal
    if (oldWidget.statesController != widget.statesController) {
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
    }

    // Only update states that actually changed
    if (oldWidget.selected != widget.selected) {
      _effectiveController.update(WidgetState.selected, widget.selected);
    }
    if (oldWidget.error != widget.error) {
      _effectiveController.update(WidgetState.error, widget.error);
    }

    // Handle enabled state changes
    if (oldWidget.enabled != widget.enabled) {
      _effectiveController.update(WidgetState.disabled, !widget.enabled);
      
      // Clear transient states when becoming disabled
      if (!widget.enabled) {
        _clearTransientStates();
        // Unfocus if we have focus
        if (_effectiveController.value.contains(WidgetState.focused)) {
          widget.focusNode?.unfocus();
        }
      }
    }
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine mouse cursor based on interactive state
    // Simple logic: interactive gets click cursor, non-interactive gets basic
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
        child: MouseRegion(
          cursor: effectiveCursor,
          child: GestureDetector(
            onTap: _isInteractive ? _handleTap : null,
            onDoubleTap: _isInteractive ? widget.onDoubleTap : null,
            onLongPress: _isInteractive ? _handleLongPress : null,
            behavior: widget.behavior,
            // Let parent widgets handle semantics
            excludeFromSemantics: true,
            child: NakedInteractable(
              statesController: _effectiveController,
              enabled: _isInteractive,
              selected: widget.selected,
              error: widget.error,
              autofocus: widget.autofocus,
              focusNode: widget.focusNode,
              onStatesChange: widget.onStatesChange,
              onFocusChange: widget.onFocusChange,
              onHoverChange: widget.onHoverChange,
              onPressChange: widget.onPressChange,
              child: widget.child,
              builder: widget.builder,
            ),
          ),
        ),
      ),
    );
  }
}
