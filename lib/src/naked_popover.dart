import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'utilities/naked_menu_anchor.dart';

/// A headless popover without visuals.
///
/// Provides toggleable overlay functionality with custom content rendering.
/// Handles tap interactions, positioning, and focus management.
///
/// ```dart
/// NakedPopover(
///   popoverBuilder: (context) => Container(
///     padding: EdgeInsets.all(16),
///     child: Text('Popover content'),
///   ),
///   child: Text('Click me'),
/// )
/// ```
///
/// See also:
/// - [NakedMenu], for dropdown menu functionality.
/// - [NakedDialog], for modal dialog functionality.
class NakedPopover extends StatefulWidget implements OverlayChildLifecycle {
  const NakedPopover({
    super.key,
    required this.child,
    required this.popoverBuilder,
    this.position = const NakedMenuPosition(),
    this.fallbackPositions = const [],
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.openOnTap = true,
    this.removalDelay = Duration.zero,
    this.onStateChange,
  });

  /// The trigger widget that opens the popover.
  final Widget child;
  /// The builder for popover content.
  final WidgetBuilder popoverBuilder;

  /// The popover position relative to its trigger.
  final NakedMenuPosition position;
  /// The fallback positions if preferred doesn't fit.
  final List<NakedMenuPosition> fallbackPositions;

  /// The outside tap consumption flag.
  final bool consumeOutsideTaps;
  /// The root overlay usage flag.
  final bool useRootOverlay;
  /// The tap-to-open enablement flag.
  final bool openOnTap;

  @override
  final Duration removalDelay;

  @override
  final OverlayChildLifecycleCallback? onStateChange;

  @override
  State<NakedPopover> createState() => _NakedPopoverState();
}

class _NakedPopoverState extends State<NakedPopover>
    with MenuAnchorChildLifecycleMixin {
  // Internal node used when the child doesn't already provide a Focus.
  final _internalTriggerNode = FocusNode(
    debugLabel: 'NakedPopover trigger (internal)',
  );

  void _toggle() => showNotifier.value = !showNotifier.value;

  /// If the child is a Focus widget, extract its node so we can return focus to it.
  FocusNode? _extractChildFocusNode() {
    final c = widget.child;
    if (c is Focus) return c.focusNode;

    return null;
  }

  Widget _buildTrigger(FocusNode returnNode) {
    // Case A: We own the focus node (no Focus provided by the child).
    if (identical(returnNode, _internalTriggerNode)) {
      if (!widget.openOnTap) {
        return Focus(focusNode: _internalTriggerNode, child: widget.child);
      }

      return FocusableActionDetector(
        focusNode: _internalTriggerNode,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _toggle(),
          ),
        },
        child: GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        ),
      );
    }

    // Case B: Child already provides a Focus node; don't add another focus owner.
    // Keep behavior headless: tap toggles if enabled.
    return GestureDetector(
      onTap: widget.openOnTap ? _toggle : null,
      behavior: HitTestBehavior.opaque,
      child: widget.child, // retains the caller's Focus node
    );
  }

  @override
  void dispose() {
    _internalTriggerNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final returnNode = _extractChildFocusNode() ?? _internalTriggerNode;

    return NakedMenuAnchor(
      controller: controller,
      overlayBuilder: (ctx) => widget.popoverBuilder(ctx),
      childFocusNode: returnNode, // focus returns here on close
      useRootOverlay: widget.useRootOverlay,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      closeOnOutsideTap: true,
      removalDelay: widget.removalDelay,
      position: widget.position,
      fallbackPositions: widget.fallbackPositions,
      onClose: () {
        // Keep internal state in sync if closed by ESC/outside tap.
        if (showNotifier.value) showNotifier.value = false;
      },
      child: _buildTrigger(returnNode),
    );
  }
}
