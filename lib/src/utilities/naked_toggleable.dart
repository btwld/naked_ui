// ABOUTME: Headless toggle widget for checkbox/radio/switch patterns with built-in state management.
// ABOUTME: Handles selection state computation, tristate logic, and proper feedback for selection controls.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'naked_pressable.dart';

/// A headless toggleable widget for checkbox/radio/switch patterns.
///
/// Wraps [NakedPressable] with toggle-specific behavior:
/// - Computes next selection state (including tristate)
/// - Provides selection-specific haptic feedback
/// - Manages selected state automatically
///
/// This widget is the foundation for checkboxes, radio buttons, and switches.
///
/// Example:
/// ```dart
/// NakedToggleable(
///   selected: isChecked,
///   onChanged: (value) => setState(() => isChecked = value!),
///   builder: (context, states, child) {
///     return Container(
///       width: 24,
///       height: 24,
///       decoration: BoxDecoration(
///         color: states.isSelected
///             ? Colors.blue
///             : Colors.transparent,
///         border: Border.all(
///           color: states.isFocused
///               ? Colors.blue
///               : Colors.grey,
///         ),
///       ),
///       child: states.isSelected
///           ? Icon(Icons.check, size: 16, color: Colors.white)
///           : null,
///     );
///   },
/// )
/// ```
class NakedToggleable extends StatelessWidget {
  /// Creates a headless toggleable widget.
  const NakedToggleable({
    super.key,
    required this.builder,
    this.selected,
    this.tristate = false,
    this.onChanged,
    this.enabled = true,
    this.error = false,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.disabledMouseCursor,
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

  /// Current selection state.
  ///
  /// When [tristate] is true, null represents a mixed/indeterminate state.
  /// When [tristate] is false, null is treated as false.
  final bool? selected;

  /// Whether the control supports three states.
  ///
  /// When true, tapping cycles through: false → true → null → false
  /// When false, tapping toggles between true and false.
  final bool tristate;

  /// Called with the next selection state when activated.
  ///
  /// If null, the widget is disabled and unresponsive to input.
  final ValueChanged<bool?>? onChanged;

  /// Whether this widget responds to input.
  final bool enabled;

  /// Whether this widget has an error state.
  final bool error;

  /// Controls focus state for this widget.
  final FocusNode? focusNode;

  /// Whether this widget should be focused initially.
  final bool autofocus;

  /// Mouse cursor when the widget is interactive.
  final MouseCursor? mouseCursor;

  /// Mouse cursor when the widget is disabled.
  final MouseCursor? disabledMouseCursor;

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
  /// Uses selectionClick haptic feedback for toggle state changes,
  /// which is consistent across platforms for selection controls.
  final bool enableFeedback;

  /// Whether to request focus when the widget is activated.
  final bool focusOnPress;

  /// Whether this widget should respond to interactions.
  bool get _isInteractive => enabled && onChanged != null;

  /// Computes the next selection state based on current state and tristate mode.
  bool? _computeNextValue() {
    if (!_isInteractive) {
      return selected;
    }

    if (tristate) {
      // Material tristate cycle: null → false → true → null
      if (selected == null) return false;
      if (selected == false) return true;

      return null; // true → null (complete the cycle)
    }
    // Binary toggle: treat null as false, then toggle
    final current = selected ?? false;

    return !current;
  }

  /// Handles activation (tap/keyboard).
  void _handleActivation() {
    if (!_isInteractive) return;

    // Provide selection-specific haptic feedback
    // This is consistent across platforms for selection controls
    if (enableFeedback) {
      HapticFeedback.selectionClick();
    }

    // Compute and emit the next value
    final nextValue = _computeNextValue();
    onChanged!(nextValue);
  }

  @override
  Widget build(BuildContext context) {
    return NakedPressable(
      onPressed: _isInteractive ? _handleActivation : null,
      enabled: enabled,
      selected: selected ?? false,
      error: error,
      mouseCursor: mouseCursor,
      disabledMouseCursor: disabledMouseCursor,
      focusNode: focusNode,
      autofocus: autofocus,
      onStatesChange: onStatesChange,
      onFocusChange: onFocusChange,
      onHoverChange: onHoverChange,
      onPressChange: onPressChange,
      statesController: statesController,
      behavior: behavior,
      // We handle our own selectionClick feedback
      enableFeedback: false,
      focusOnPress: focusOnPress,
      semanticsIsButton: false,
      child: child,
      builder: builder,
    );
  }
}
