import 'package:flutter/widgets.dart';

import 'intents.dart';
import 'positioning.dart';

/// Shared overlay shell used by NakedMenu and NakedSelect.
///
/// Wraps a target child with RawMenuAnchor and renders the overlay content
/// positioned relative to the anchor. Handles outside taps, simple keyboard
/// traversal (Esc and Arrow Up/Down), and focus traversal grouping.
class AnchoredOverlayShell extends StatelessWidget {
  /// Creates a positioned overlay bound to [controller] and [child].
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
    this.positioning = const OverlayPositionConfig(),
  });

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

  /// Positioning configuration for the overlay.
  final OverlayPositionConfig positioning;

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
        final traversalPolicy = ReadingOrderTraversalPolicy();

        return OverlayPositioner(
          targetRect: info.anchorRect,
          positioning: positioning,
          child: TapRegion(
            onTapOutside: closeOnClickOutside
                ? (event) => controller.close()
                : null,
            groupId: info.tapRegionGroupId,
            child: FocusTraversalGroup(
              policy: traversalPolicy,
              child: FocusScope(
                child: Builder(
                  builder: (focusContext) {
                    final focusScope = FocusScope.of(focusContext);
                    return Shortcuts(
                      shortcuts: NakedIntentActions.menuShortcuts,
                      child: Actions(
                        actions: NakedIntentActions.menuActions(
                          onDismiss: controller.close,
                          onNextFocus: focusScope.nextFocus,
                          onPreviousFocus: focusScope.previousFocus,
                          onFirstFocus: () => traversalPolicy
                              .findFirstFocus(
                                focusScope,
                                ignoreCurrentFocus: true,
                              )
                              ?.requestFocus(),
                          onLastFocus: () => traversalPolicy
                              .findLastFocus(
                                focusScope,
                                ignoreCurrentFocus: true,
                              )
                              .requestFocus(),
                        ),
                        child: Focus(
                          autofocus: true,
                          canRequestFocus: true,
                          skipTraversal: true,
                          child: overlayChild,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}
