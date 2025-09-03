import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button_behavior.dart';

/// A headless, stateless toggle behavior for checkbox/radio/switch patterns.
///
/// - Wraps button activation and forwards focus/hover/press callbacks
/// - Computes next selection for checkbox-like patterns (including tristate)
/// - Emits value via [onChanged]
/// - Leaves semantics to higher-level wrappers/components
class ToggleableBehavior extends StatelessWidget {
  const ToggleableBehavior({
    super.key,
    required this.child,
    this.enabled = true,
    this.selected,
    this.tristate = false,
    this.onChanged,
    this.onPressChange,
    this.onHoverChange,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.disabledMouseCursor,
    this.enableFeedback = true,
    this.behavior = HitTestBehavior.opaque,
  });

  /// Child content to render.
  final Widget child;

  /// Whether interactions are enabled.
  final bool enabled;

  /// Current selection state. When [tristate] is true, null means mixed.
  final bool? selected;

  /// Whether the control supports three states (false → true → null → false).
  final bool tristate;

  /// Called with the next selection when activated.
  final ValueChanged<bool?>? onChanged;

  /// Press state change callback (true on press, false on release/cancel).
  final ValueChanged<bool>? onPressChange;

  /// Hover state change callback.
  final ValueChanged<bool>? onHoverChange;

  /// Focus state change callback.
  final ValueChanged<bool>? onFocusChange;

  /// Optional focus node used by InteractiveBehavior.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  /// Cursor when interactive.
  final MouseCursor? mouseCursor;

  /// Cursor when not interactive.
  final MouseCursor? disabledMouseCursor;

  /// Whether to emit platform-specific feedback on activation.
  final bool enableFeedback;

  /// Hit test behavior for the internal [GestureDetector].
  final HitTestBehavior behavior;

  bool get _isInteractive => enabled && onChanged != null;

  MouseCursor get _effectiveCursor => _isInteractive
      ? (mouseCursor ?? SystemMouseCursors.click)
      : (disabledMouseCursor ?? SystemMouseCursors.basic);

  bool? _computeNextValue() {
    if (!_isInteractive) return selected;
    if (tristate) {
      switch (selected) {
        case false:
          return true;
        case true:
          return null;
        case null:
          return false;
      }
    }
    // Non-tristate: toggle between true/false; treat null as false → true.
    final bool current = selected ?? false;

    return !current;
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = _isInteractive
        ? () {
            if (enableFeedback) HapticFeedback.selectionClick();
            onChanged?.call(_computeNextValue());
          }
        : null;

    return ButtonBehavior(
      enabled: _isInteractive,
      onPressed: onPressed,
      onDoubleTap: null,
      onLongPress: null,
      onPressChange: onPressChange,
      onHoverChange: onHoverChange,
      onFocusChange: onFocusChange,
      focusNode: focusNode,
      autofocus: autofocus,
      mouseCursor: _effectiveCursor,
      disabledMouseCursor: disabledMouseCursor,
      enableFeedback: false,
      focusOnPress: false,
      behavior: behavior,
      child: child,
    );
  }
}
