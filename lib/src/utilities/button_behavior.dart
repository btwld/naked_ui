import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'interaction_behaviors.dart';

/// A headless, stateless tap behavior that unifies pointer and keyboard
/// activation without owning any state.
///
/// Responsibilities:
/// - Wraps [InteractiveBehavior] to receive pointer-driven focus/hover/press
///   callbacks from the outside.
/// - Adds [GestureDetector] for onTap/onDoubleTap/onLongPress.
/// - Adds keyboard activation via Shortcuts/Actions (Enter/Space) and
///   synthesizes a brief pressed flash using [onPressChange] callbacks.
/// - Provides optional feedback and focus-on-press behavior.
/// - Does not provide semantics; higher-level wrappers (e.g., ButtonBehavior)
///   should handle semantics roles.
class ButtonBehavior extends StatelessWidget {
  const ButtonBehavior({
    super.key,
    required this.child,
    this.enabled = true,
    this.onPressed,
    this.onDoubleTap,
    this.onLongPress,
    this.onPressChange,
    this.onHoverChange,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.disabledMouseCursor,
    this.enableFeedback = true,
    this.focusOnPress = false,
    this.behavior = HitTestBehavior.opaque,
    this.extraShortcuts,
    this.extraActions,
  });

  static const Duration _flash = Duration(milliseconds: 100);

  /// Child content to render.
  final Widget child;

  /// Whether interactions are enabled.
  final bool enabled;

  /// Tap/click activation handler.
  final VoidCallback? onPressed;

  /// Double-tap handler.
  final VoidCallback? onDoubleTap;

  /// Long-press handler.
  final VoidCallback? onLongPress;

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

  /// Whether to request focus on tap when a [focusNode] is provided.
  final bool focusOnPress;

  /// Hit test behavior for the internal [GestureDetector].
  final HitTestBehavior behavior;

  /// Additional shortcuts to merge with the default Enter/Space activators.
  final Map<ShortcutActivator, Intent>? extraShortcuts;

  /// Additional actions to merge with the default [ActivateIntent] action.
  final Map<Type, Action<Intent>>? extraActions;

  bool get _hasAnyTapHandler =>
      onPressed != null || onDoubleTap != null || onLongPress != null;

  bool get _isInteractive => enabled && _hasAnyTapHandler;

  MouseCursor get _effectiveCursor => _isInteractive
      ? (mouseCursor ?? SystemMouseCursors.click)
      : (disabledMouseCursor ?? SystemMouseCursors.basic);

  Future<void> _keyboardActivate(BuildContext context) async {
    if (!(enabled && onPressed != null)) return;
    onPressChange?.call(true);
    try {
      if (enableFeedback) Feedback.forTap(context);
      onPressed!();
      await Future<void>.delayed(_flash);
    } finally {
      onPressChange?.call(false);
    }
  }

  void _handleTap(BuildContext context) {
    if (!(enabled && onPressed != null)) return;
    if (enableFeedback) Feedback.forTap(context);
    if (focusOnPress && focusNode != null) {
      focusNode!.requestFocus();
    }
    onPressed!();
  }

  void _handleLongPress(BuildContext context) {
    if (!(enabled && onLongPress != null)) return;
    if (enableFeedback) Feedback.forLongPress(context);
    onLongPress!();
  }

  @override
  Widget build(BuildContext context) {
    final interactive = InteractiveBehavior(
      enabled: _isInteractive,
      focusNode: focusNode,
      autofocus: autofocus,
      cursor: _effectiveCursor,
      behavior: behavior,
      onFocusChange: onFocusChange,
      onHoverChange: onHoverChange,
      onPressChange: onPressChange,
      child: GestureDetector(
        onTap: onPressed != null && enabled ? () => _handleTap(context) : null,
        onDoubleTap: onDoubleTap != null && enabled
            ? () => onDoubleTap!()
            : null,
        onLongPress: onLongPress != null && enabled
            ? () => _handleLongPress(context)
            : null,
        behavior: behavior,
        excludeFromSemantics: true,
        child: child,
      ),
    );

    final mergedShortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
      ...?extraShortcuts,
    };

    final mergedActions = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          _keyboardActivate(context);

          return true;
        },
      ),
      ...?extraActions,
    };

    return Shortcuts(
      shortcuts: mergedShortcuts,
      child: Actions(actions: mergedActions, child: interactive),
    );
  }
}
