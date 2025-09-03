import 'package:flutter/widgets.dart';

import 'interaction_behaviors.dart';

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
      // ignore: avoid-empty-setstate, no-empty-block
      setState(() {});
    }
  }

  // ==================== Behavior Callback Handlers ====================

  void _handleHoverChange(bool hovered) {
    _effectiveController.update(WidgetState.hovered, hovered);
    widget.onHoverChange?.call(hovered);
  }

  void _handlePressChange(bool pressed) {
    _effectiveController.update(WidgetState.pressed, pressed);
    widget.onPressChange?.call(pressed);
  }

  void _handleFocusChange(bool focused) {
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
    final builtChild = widget.builder(
      context,
      _effectiveController.value,
      widget.child,
    );

    return InteractiveBehavior(
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      // Allow parent to control cursors; do not set here
      behavior: HitTestBehavior.opaque,
      onFocusChange: _handleFocusChange,
      onHoverChange: _handleHoverChange,
      onPressChange: _handlePressChange,
      child: builtChild,
    );
  }
}
