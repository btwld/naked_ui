import 'package:flutter/widgets.dart';

import 'intents.dart';

/// Signature for a function that positions overlay content.
typedef OverlayPositioner =
    Widget Function(
      BuildContext context,
      RawMenuOverlayInfo info,
      Widget overlayChild,
    );

/// Shared overlay shell used by NakedMenu and NakedSelect.
///
/// Wraps a target child with RawMenuAnchor and renders the overlay content
/// positioned relative to the anchor. Handles outside taps, simple keyboard
/// traversal (Esc and Arrow Up/Down), and focus traversal grouping.
class AnchoredOverlayShell extends StatelessWidget {
  const AnchoredOverlayShell({
    super.key,
    required this.controller,
    required this.child,
    required this.overlayBuilder,
    this.onOpen,
    this.onClose,
    this.onOpenRequested,
    this.onCloseRequested,
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.closeOnClickOutside = true,
    this.triggerFocusNode,
    this.offset = Offset.zero,
    this.positioner,
  });

  /// Default positioner that provides simple top-left positioning.
  static Widget defaultPositioner(
    BuildContext context,
    RawMenuOverlayInfo info,
    Widget overlayChild,
    Offset offset,
    bool closeOnClickOutside,
    MenuController controller,
  ) {
    // Compute a simple top-left offset relative to the anchor.
    // We intentionally avoid measuring the overlay child to keep things
    // simple and robust across dynamic resizing. We prefer bottom-left,
    // and fallback to top-left if the anchor is near the bottom.
    final useTop = info.anchorRect.bottom > info.overlaySize.height * 0.66;
    final left = info.anchorRect.left + offset.dx;
    final top =
        (useTop ? (info.anchorRect.top) : (info.anchorRect.bottom)) + offset.dy;

    // Clamp left/top into the overlay's bounds to avoid going negative.
    final double clampedLeft = left
        .clamp(0.0, info.overlaySize.width)
        .toDouble();
    final double clampedTop = top
        .clamp(0.0, info.overlaySize.height)
        .toDouble();

    return Stack(
      children: [
        Positioned(
          left: clampedLeft,
          top: clampedTop,
          child: TapRegion(
            onTapOutside: closeOnClickOutside
                ? (event) => controller.close()
                : null,
            groupId: info.tapRegionGroupId,
            child: FocusTraversalGroup(
              child: Shortcuts(
                shortcuts: NakedIntentActions.menu.shortcuts,
                child: Actions(
                  actions: NakedIntentActions.menu.actions(
                    onDismiss: () => controller.close(),
                    onNextFocus: () => FocusScope.of(context).nextFocus(),
                    onPreviousFocus: () =>
                        FocusScope.of(context).previousFocus(),
                  ),
                  child: Focus(
                    autofocus: true,
                    canRequestFocus: true,
                    child: overlayChild,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The controller that manages overlay visibility.
  final MenuController controller;

  /// The inline target widget (e.g., trigger button).
  final Widget child;

  /// Builds the overlay content shown when open.
  final RawMenuAnchorOverlayBuilder overlayBuilder;

  /// Called when the overlay opens.
  final VoidCallback? onOpen;

  /// Called when the overlay closes.
  final VoidCallback? onClose;

  /// Intercepts open requests. Call `showOverlay` to actually show.
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  /// Intercepts close requests. Call `hideOverlay` to actually hide.
  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  /// Whether taps outside should be consumed by the anchor region.
  final bool consumeOutsideTaps;

  /// Whether to render in the root overlay.
  final bool useRootOverlay;

  /// Whether clicking outside closes the overlay.
  final bool closeOnClickOutside;

  /// Focus node to return focus to on close.
  final FocusNode? triggerFocusNode;

  /// Additional offset applied to the computed top-left.
  final Offset offset;

  /// Optional custom positioner for overlay content.
  final OverlayPositioner? positioner;

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      childFocusNode: triggerFocusNode,
      consumeOutsideTaps: consumeOutsideTaps,
      onOpen: onOpen,
      onClose: onClose,
      onOpenRequested: onOpenRequested ?? (_, show) => show(),
      onCloseRequested: onCloseRequested ?? (hide) => hide(),
      useRootOverlay: useRootOverlay,
      controller: controller,
      overlayBuilder: (context, info) {
        final overlayChild = overlayBuilder(context, info);

        final effectivePositioner =
            positioner ??
            (context, info, overlayChild) => defaultPositioner(
              context,
              info,
              overlayChild,
              offset,
              closeOnClickOutside,
              controller,
            );

        return effectivePositioner(context, info, overlayChild);
      },
      child: child,
    );
  }
}
