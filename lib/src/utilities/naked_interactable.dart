import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A headless interactive widget that manages interaction states.
///
/// Provides pure interaction behavior without any visual styling,
/// managing states like pressed, hovered, focused, disabled, selected, and error.
/// Uses a builder pattern to allow complete control over the visual
/// representation based on the current interaction states.
///
/// The widget uses [MouseRegion] for hover detection and [Listener] for
/// press/drag interactions. Touch devices will not trigger hover states
/// as they don't emit enter/exit events.
///
/// Example:
/// ```dart
/// NakedInteractable(
///   enabled: true,
///   selected: false,
///   error: hasValidationError,
///   builder: (context, states, child) {
///     return Container(
///       padding: EdgeInsets.all(16),
///       decoration: BoxDecoration(
///         color: states.contains(WidgetState.pressed)
///             ? Colors.blue.shade700
///             : states.contains(WidgetState.hovered)
///                 ? Colors.blue.shade400
///                 : Colors.grey,
///         border: states.contains(WidgetState.focused)
///             ? Border.all(color: Colors.black, width: 2)
///             : states.contains(WidgetState.error)
///                 ? Border.all(color: Colors.red, width: 2)
///                 : null,
///       ),
///       child: child ?? Text('Click me'),
///     );
///   },
/// )
/// ```
///
/// The widget does not interfere with parent or child [MouseRegion] widgets:
/// - Parent cursors are inherited automatically
/// - All [MouseRegion] widgets in the hierarchy receive their events
/// - Multiple hover handlers can coexist at different levels
class NakedInteractable extends StatefulWidget {
  /// Creates a headless interactive widget.
  const NakedInteractable({
    super.key,
    required this.builder,
    this.statesController,
    this.enabled = true,
    this.selected = false,
    this.error = false,
    this.autofocus = false,
    this.focusNode,
    this.child,
    this.onStatesChange,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
  });

  /// Builds the widget based on current interaction states.
  ///
  /// The builder receives the current [WidgetState] set and an optional
  /// child widget that doesn't rebuild when states change.
  final ValueWidgetBuilder<Set<WidgetState>> builder;

  /// Controls the widget states externally.
  ///
  /// If null, an internal controller is created and managed by this widget.
  /// When provided, the caller is responsible for disposing the controller.
  final WidgetStatesController? statesController;

  /// Whether this widget responds to input.
  ///
  /// When false, the widget will not respond to touch, hover, or focus events,
  /// and will have [WidgetState.disabled] in its state set. Transient states
  /// (hovered, pressed, focused) are cleared when becoming disabled.
  final bool enabled;

  /// Whether this widget is in a selected state.
  ///
  /// Useful for toggleable widgets like checkboxes or radio buttons.
  /// When true, [WidgetState.selected] is added to the state set.
  final bool selected;

  /// Whether this widget has an error state.
  ///
  /// Useful for form validation feedback and error indicators.
  /// When true, [WidgetState.error] is added to the state set.
  final bool error;

  /// Whether this widget should be focused initially.
  final bool autofocus;

  /// Controls focus state for this widget.
  ///
  /// If null, focus is managed internally when [enabled] is true.
  final FocusNode? focusNode;

  /// Optional child widget that doesn't rebuild when states change.
  ///
  /// Useful for expensive widgets that don't need to react to
  /// interaction state changes.
  final Widget? child;

  /// Called whenever the widget state set changes.
  final ValueChanged<Set<WidgetState>>? onStatesChange;

  /// Called when the focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when the hover state changes.
  ///
  /// Only triggered by mouse or stylus pointers that support hover.
  /// Touch pointers do not trigger hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when the pressed state changes.
  final ValueChanged<bool>? onPressChange;

  @override
  State<NakedInteractable> createState() => _NakedInteractableState();
}

class _NakedInteractableState extends State<NakedInteractable> {
  // State management
  WidgetStatesController? _internalController;
  bool _isPointerInside = false;

  WidgetStatesController get _effectiveController =>
      widget.statesController ??
      (_internalController ??= _createInternalController());

  bool get _isDisabled => !widget.enabled;

  @override
  void initState() {
    super.initState();
    _setupWidgetStates();
    _effectiveController.addListener(_handleStateChange);
  }

  // ==================== State Management ====================

  /// Creates an internal controller with initial states.
  WidgetStatesController _createInternalController() {
    return WidgetStatesController({
      if (widget.selected) WidgetState.selected,
      if (widget.error) WidgetState.error,
      if (_isDisabled) WidgetState.disabled,
    });
  }

  /// Updates states when widget properties change.
  void _setupWidgetStates() {
    _effectiveController
      ..update(WidgetState.selected, widget.selected)
      ..update(WidgetState.error, widget.error)
      ..update(WidgetState.disabled, _isDisabled);
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

  /// Handles state controller changes between external and internal.
  void _handleControllerChange(NakedInteractable oldWidget) {
    // Remove listener from old controller
    final oldEffective = oldWidget.statesController ?? _internalController;
    oldEffective?.removeListener(_handleStateChange);

    // Handle internal controller lifecycle
    if (widget.statesController == null) {
      // Switching to internal controller
      _internalController ??= WidgetStatesController(
        oldWidget.statesController?.value ?? {},
      );
    } else {
      // Switching to external controller
      _internalController?.dispose();
      _internalController = null;
    }

    // Add listener to new controller
    _effectiveController.addListener(_handleStateChange);
  }

  /// Notifies listeners when states change and triggers rebuild.
  void _handleStateChange() {
    widget.onStatesChange?.call({..._effectiveController.value});
    if (mounted) {
      // Use addPostFrameCallback to avoid setState during build
      // This follows Flutter's official recommendation for WidgetStatesController listeners
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  /// Clears the pressed state and notifies listeners.
  ///
  /// Extracted helper to avoid code duplication across multiple handlers.
  void _clearPressedState() {
    if (!_effectiveController.value.contains(WidgetState.pressed)) return;

    _effectiveController.update(WidgetState.pressed, false);
    widget.onPressChange?.call(false);
  }

  // ==================== MouseRegion Event Handlers ====================

  /// Handles pointer entering the widget bounds.
  ///
  /// Only triggered by mouse/stylus pointers that support hover.
  /// Touch pointers do not emit enter events.
  void _handlePointerEnter(PointerEnterEvent event) {
    if (_isDisabled) return;

    _isPointerInside = true;
    _effectiveController.update(WidgetState.hovered, true);
    widget.onHoverChange?.call(true);
  }

  /// Handles pointer exiting the widget bounds.
  ///
  /// Only triggered by mouse/stylus pointers that support hover.
  /// Touch pointers do not emit exit events. Also clears pressed
  /// state to handle edge cases where exit occurs while pressed.
  void _handlePointerExit(PointerExitEvent event) {
    _isPointerInside = false;

    if (_isDisabled) return;

    // Clear hover state
    _effectiveController.update(WidgetState.hovered, false);
    widget.onHoverChange?.call(false);

    // Clear pressed state if active (edge case handling)
    _clearPressedState();
  }

  // ==================== Listener Event Handlers ====================

  /// Handles pointer down events for all pointer types.
  ///
  /// CRITICAL: No boundary check here! Touch devices don't emit
  /// onPointerEnter, so checking _isPointerInside would break touch input.
  /// The Listener widget already ensures this only fires when the
  /// pointer is actually inside the widget bounds.
  void _handlePointerDown(PointerDownEvent event) {
    if (_isDisabled) return;
    // NO _isPointerInside check - this is critical for touch support!

    _effectiveController.update(WidgetState.pressed, true);
    widget.onPressChange?.call(true);
  }

  /// Handles pointer up events.
  void _handlePointerUp(PointerUpEvent event) {
    if (_isDisabled) return;
    _clearPressedState();
  }

  /// Handles pointer cancel events.
  void _handlePointerCancel(PointerCancelEvent event) {
    if (_isDisabled) return;
    _clearPressedState();
  }

  /// Handles pointer move events to track boundary crossings.
  ///
  /// Updates hover state when the pointer crosses widget boundaries
  /// and clears pressed state if the pointer moves outside while pressed.
  /// This provides proper drag-out behavior for both mouse and touch.
  void _handlePointerMove(PointerMoveEvent event) {
    if (_isDisabled) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final isInside = box.size.contains(event.localPosition);

    // For hover-capable devices, only update if boundary actually changed
    // For touch devices, _isPointerInside may never be updated (no hover events)
    // so we always check if pressed state needs to be cleared
    if (isInside != _isPointerInside) {
      _isPointerInside = isInside;
    }

    // Always clear pressed state when moving outside, regardless of device type
    if (!isInside) {
      _clearPressedState();
    }
  }
  // ==================== Focus Handler ====================

  /// Handles focus state changes.
  void _handleFocusChange(bool focused) {
    if (_isDisabled) return;

    _effectiveController.update(WidgetState.focused, focused);
    widget.onFocusChange?.call(focused);
  }

  @override
  void didUpdateWidget(NakedInteractable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (oldWidget.statesController != widget.statesController) {
      _handleControllerChange(oldWidget);
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
    _effectiveController.removeListener(_handleStateChange);
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build from inside out: Builder -> Listener -> MouseRegion -> Focus

    // 1. Core: Listener for press/drag events
    Widget result = Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.opaque,
      child: widget.builder(context, _effectiveController.value, widget.child),
    );

    // 2. Wrap with MouseRegion for hover state
    // MouseRegion is REQUIRED for onEnter/onExit events
    // We don't set cursor to allow parent/child cursor control
    result = MouseRegion(
      onEnter: _handlePointerEnter,
      onExit: _handlePointerExit,
      // NO cursor property - inherits from parent or uses default
      // NO opaque property - not needed for our use case
      // NO onHover - we handle movement in Listener.onPointerMove
      child: result,
    );

    // 3. Conditionally wrap with Focus when enabled
    if (!_isDisabled) {
      result = Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onFocusChange: _handleFocusChange,
        child: result,
      );
    }

    return result;
  }
}
