import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Dismiss with Escape using default shortcuts; we only tell *this* anchor how to close.
class NakedDismissMenuAction extends DismissAction {
  final MenuController controller;
  NakedDismissMenuAction({required this.controller});
  @override
  void invoke(DismissIntent intent) => controller.close();

  @override
  bool isEnabled(DismissIntent intent) => controller.isOpen;
}

/// Alignment pair for target (anchor) and follower (overlay).
class NakedMenuPosition {
  final Alignment target;

  final Alignment follower;
  const NakedMenuPosition({
    this.target = Alignment.bottomLeft,
    this.follower = Alignment.topLeft,
  });
}

/// A thin, headless wrapper over RawMenuAnchor with sane defaults.
///
/// - Closes on outside tap via TapRegion (as recommended by the docs)
/// - Lets `consumeOutsideTaps` decide if that outside tap propagates
/// - Supports delayed hide via `removalDelay` using onCloseRequested
/// - Respects `RawMenuOverlayInfo.position` when provided (context menus)
class NakedMenuAnchor extends StatefulWidget {
  const NakedMenuAnchor({
    super.key,
    required this.controller,
    required this.overlayBuilder,
    this.child,
    this.childFocusNode,
    this.useRootOverlay = false,
    this.consumeOutsideTaps = true,
    this.closeOnOutsideTap = true,
    this.removalDelay = Duration.zero,
    this.position = const NakedMenuPosition(
      target: Alignment.topCenter,
      follower: Alignment.bottomCenter,
    ),
    this.fallbackPositions = const [],
    this.onClose,
    this.onOpen,
    this.onKeyEvent,
  });

  final MenuController controller;
  final WidgetBuilder overlayBuilder;
  final Widget? child;

  /// If supplied, forwarded to RawMenuAnchor.childFocusNode.
  final FocusNode? childFocusNode;

  /// Whether the outside tap that *closes* the menu is swallowed.
  final bool consumeOutsideTaps;

  /// Whether tapping outside should close the menu.
  final bool closeOnOutsideTap;

  /// Delay before the overlay is actually hidden (for exit animations).
  final Duration removalDelay;

  final bool useRootOverlay;
  final NakedMenuPosition position;
  final List<NakedMenuPosition> fallbackPositions;

  final VoidCallback? onClose;
  final VoidCallback? onOpen;

  /// Optional raw key listener (e.g., type‑ahead). Return handled/ignored.
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  @override
  State<NakedMenuAnchor> createState() => _NakedMenuAnchorState();
}

class _NakedMenuAnchorState extends State<NakedMenuAnchor> {
  final FocusNode _overlayFocusNode = FocusNode(
    debugLabel: 'NakedMenu overlay',
  );

  @override
  void dispose() {
    _overlayFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      childFocusNode: widget.childFocusNode,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      onOpen: widget.onOpen,
      onClose: widget.onClose,
      // Animation-friendly: show immediately on open request; delay hide on close request.
      onOpenRequested: (Offset? _, VoidCallback showOverlay) {
        showOverlay();
      },
      onCloseRequested: (VoidCallback hideOverlay) {
        if (widget.removalDelay == Duration.zero) {
          hideOverlay();

          return;
        }
        Future<void>.delayed(widget.removalDelay, hideOverlay);
      },
      useRootOverlay: widget.useRootOverlay,
      controller: widget.controller,
      overlayBuilder: (context, info) {
        return Positioned.fill(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          child: TapRegion(
            onTapOutside: widget.closeOnOutsideTap
                ? (PointerDownEvent _) => widget.controller.close()
                : null,
            groupId: info.tapRegionGroupId,
            child: CustomSingleChildLayout(
              delegate: _NakedPositionDelegate(
                anchorRect: info.anchorRect,
                overlaySize: info.overlaySize,
                anchorAlignment: widget.position,
                fallbackAlignments: widget.fallbackPositions,
                pointerPosition:
                    info.position, // respects MenuController.open(position: …)
              ),
              child: Actions(
                actions: {
                  // Esc/Gamepad-B: dismiss via default shortcut mapping.
                  DismissIntent: NakedDismissMenuAction(
                    controller: widget.controller,
                  ),
                },
                child: Focus(
                  focusNode: _overlayFocusNode,
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    final res = widget.onKeyEvent?.call(event);

                    return res ?? KeyEventResult.ignored;
                  },
                  child: widget.overlayBuilder(context),
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _NakedPositionDelegate extends SingleChildLayoutDelegate {
  final Rect anchorRect;

  final Size overlaySize;
  final NakedMenuPosition anchorAlignment;
  final List<NakedMenuPosition> fallbackAlignments;
  final Offset? pointerPosition;
  // RawMenuOverlayInfo.position (if open(position: …))

  const _NakedPositionDelegate({
    required this.anchorRect,
    required this.overlaySize,
    required this.anchorAlignment,
    required this.fallbackAlignments,
    required this.pointerPosition,
  });

  bool _fits(Offset topLeft, Size child, Size overlay) {
    return topLeft.dx >= 0 &&
        topLeft.dy >= 0 &&
        topLeft.dx + child.width <= overlay.width &&
        topLeft.dy + child.height <= overlay.height;
  }

  Offset _clampToBounds(Offset topLeft, Size child, Size overlay) {
    final dx = topLeft.dx.clamp(0.0, overlay.width - child.width);
    final dy = topLeft.dy.clamp(0.0, overlay.height - child.height);

    return Offset(dx, dy);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // If `position` is provided, anchor the follower’s alignment spot to that point.
    if (pointerPosition != null) {
      final followerAnchor = anchorAlignment.follower.alongSize(childSize);
      final desired = pointerPosition! - followerAnchor;

      return _clampToBounds(desired, childSize, size);
    }

    // Otherwise, align follower to anchorRect using preferred + fallbacks.
    Offset aligned(NakedMenuPosition pos) {
      final targetAnchor = pos.target.alongSize(anchorRect.size);
      final followerAnchor = pos.follower.alongSize(childSize);

      return anchorRect.topLeft + targetAnchor - followerAnchor;
    }

    final candidates = [anchorAlignment, ...fallbackAlignments];
    for (final pos in candidates) {
      final off = aligned(pos);
      if (_fits(off, childSize, size)) return off;
    }

    return _clampToBounds(aligned(anchorAlignment), childSize, size);
  }

  @override
  bool shouldRelayout(_NakedPositionDelegate old) {
    return anchorRect != old.anchorRect ||
        overlaySize != old.overlaySize ||
        anchorAlignment != old.anchorAlignment ||
        !listEquals(fallbackAlignments, old.fallbackAlignments) ||
        pointerPosition != old.pointerPosition;
  }
}

/// Overlay lifecycle states to help parents coordinate open/close animations.
enum OverlayChildLifecycleState { present, pendingRemoval, removed }

typedef OverlayChildLifecycleCallback =
    void Function(OverlayChildLifecycleState state);

abstract class OverlayChildLifecycle {
  final OverlayChildLifecycleCallback? onStateChange;

  final Duration removalDelay;
  const OverlayChildLifecycle({
    this.onStateChange,
    this.removalDelay = Duration.zero,
  });
}

/// Turns a `showNotifier` into `controller.open/close` and emits lifecycle states.
/// Note: the actual *hide* is delayed by `NakedMenuAnchor.onCloseRequested`.
mixin MenuAnchorChildLifecycleMixin<T extends StatefulWidget> on State<T> {
  OverlayChildLifecycle get overlayChildLifecycle =>
      widget as OverlayChildLifecycle;

  final MenuController controller = MenuController();
  final ValueNotifier<bool> showNotifier = ValueNotifier(false);

  Timer? _removedTick;
  OverlayChildLifecycleCallback? get _onState =>
      overlayChildLifecycle.onStateChange;

  @override
  void initState() {
    super.initState();
    showNotifier.addListener(_handleShowChanged);
  }

  @override
  void dispose() {
    _removedTick?.cancel();
    showNotifier.removeListener(_handleShowChanged);
    super.dispose();
  }

  void _handleShowChanged() {
    _removedTick?.cancel();
    if (showNotifier.value) {
      controller.open();
      _onState?.call(OverlayChildLifecycleState.present);
    } else {
      _onState?.call(OverlayChildLifecycleState.pendingRemoval);
      // We close immediately; NakedMenuAnchor defers *hide* via its removalDelay.
      controller.close();
      _removedTick = Timer(overlayChildLifecycle.removalDelay, () {
        _onState?.call(OverlayChildLifecycleState.removed);
      });
    }
  }
}
