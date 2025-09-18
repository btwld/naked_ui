import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'utilities/positioning.dart';

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
/// - [NakedTooltip], for hover-triggered lightweight hints.
/// - [NakedDialog], for modal dialog functionality.
class NakedPopover extends StatefulWidget {
  const NakedPopover({
    super.key,
    required this.child,
    required this.popoverBuilder,
    this.positioning = const OverlayPositionConfig(),
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.openOnTap = true,
    this.triggerFocusNode,
    this.onOpen,
    this.onClose,
    this.onOpenRequested,
    this.onCloseRequested,
  });

  /// The trigger widget that opens the popover.
  final Widget child;

  /// The builder for popover content.
  final WidgetBuilder popoverBuilder;

  /// Positioning configuration for the overlay.
  final OverlayPositionConfig positioning;

  /// The outside tap consumption flag.
  final bool consumeOutsideTaps;

  /// The root overlay usage flag.
  final bool useRootOverlay;

  /// The tap-to-open enablement flag.
  final bool openOnTap;

  /// Focus node for the trigger widget.
  final FocusNode? triggerFocusNode;

  /// Called when the popover opens.
  final VoidCallback? onOpen;

  /// Called when the popover closes.
  final VoidCallback? onClose;

  /// Called when a request is made to open the popover.
  ///
  /// This callback allows you to customize the opening behavior, such as
  /// adding animations or delays. Call `showOverlay` to actually show the popover.
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  /// Called when a request is made to close the popover.
  ///
  /// This callback allows you to customize the closing behavior, such as
  /// adding animations or delays. Call `hideOverlay` to actually hide the popover.
  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  static void _defaultOnOpenRequested(Offset? position, VoidCallback showOverlay) {
    showOverlay();
  }

  static void _defaultOnCloseRequested(VoidCallback hideOverlay) {
    hideOverlay();
  }

  @override
  State<NakedPopover> createState() => _NakedPopoverState();
}

class _NakedPopoverState extends State<NakedPopover> {
  // ignore: dispose-fields
  final _menuController = MenuController();

  // Internal node used when the child doesn't already provide a Focus.
  final _internalTriggerNode = FocusNode(
    debugLabel: 'NakedPopover trigger (internal)',
  );

  void _toggle() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
  }

  void _handleOpen() {
    widget.onOpen?.call();
  }

  void _handleClose() {
    widget.onClose?.call();
  }

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
    final returnNode = widget.triggerFocusNode ??
        _extractChildFocusNode() ??
        _internalTriggerNode;

    return RawMenuAnchor(
      controller: _menuController,
      childFocusNode: returnNode,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      useRootOverlay: widget.useRootOverlay,
      onOpen: _handleOpen,
      onClose: _handleClose,
      onOpenRequested: widget.onOpenRequested ?? NakedPopover._defaultOnOpenRequested,
      onCloseRequested: widget.onCloseRequested ?? NakedPopover._defaultOnCloseRequested,
      overlayBuilder: (context, info) {
        final overlayRect = calculateOverlayPosition(
          anchorRect: info.anchorRect,
          overlaySize: info.overlaySize,
          childSize: info.overlaySize, // Will be constrained by content
          config: widget.positioning,
          pointerPosition: info.position,
        );

        return Positioned.fromRect(
          rect: overlayRect,
          child: TapRegion(
            groupId: info.tapRegionGroupId,
            onTapOutside: (event) => _menuController.close(),
            child: FocusTraversalGroup(
              child: Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
                },
                child: Actions(
                  actions: {
                    DismissIntent: CallbackAction<DismissIntent>(
                      onInvoke: (_) => _menuController.close(),
                    ),
                  },
                  child: widget.popoverBuilder(context),
                ),
              ),
            ),
          ),
        );
      },
      child: _buildTrigger(returnNode),
    );
  }
}
