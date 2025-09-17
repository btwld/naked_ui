import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Alignment pair for target (anchor) and follower (overlay).
class NakedMenuPosition {
  /// Alignment on the target (anchor) used for positioning the follower.
  final Alignment target;

  /// Alignment on the follower (overlay) used to meet the target.
  final Alignment follower;

  /// Creates an alignment pair for target and follower.
  ///
  /// For example, `target: Alignment.bottomLeft` with
  /// `follower: Alignment.topLeft` places the follower directly below the
  /// target, left aligned.
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
///
/// Example:
/// ```dart
/// NakedMenuAnchor(
///   controller: MenuController(),
///   overlayBuilder: (context) => Text('Overlay'),
///   child: Text('Trigger'),
/// )
/// ```

/// See also:
/// - [NakedMenu], a headless dropdown menu built on this anchor.
/// - [NakedTooltip], which uses this anchor to position tooltips.
/// - [NakedPopover], which also uses this anchor for positioning.

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

  /// If supplied, forwarded to RawMenuAnchor.childFocusNode
  /// (lets Raw restore focus to the trigger on close).
  final FocusNode? childFocusNode;

  /// Whether the outside tap that *closes* the menu is swallowed.
  final bool consumeOutsideTaps;

  /// Whether tapping outside should close the menu.
  final bool closeOnOutsideTap;

  /// Delay before the overlay is actually hidden (for exit animations).
  final Duration removalDelay;

  /// Whether to insert the overlay in the root [Overlay].
  final bool useRootOverlay;

  /// Preferred position of the follower relative to the target.
  final NakedMenuPosition position;

  /// Fallback positions when the preferred position does not fit.
  final List<NakedMenuPosition> fallbackPositions;

  final VoidCallback? onClose;
  final VoidCallback? onOpen;

  /// Optional raw key listener (e.g., type-ahead). Return handled/ignored.
  /// If null, we still handle ESC/Up/Down via Shortcuts, but only request
  /// overlay focus when appropriate (see heuristic below).
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  @override
  State<NakedMenuAnchor> createState() => _NakedMenuAnchorState();
}

class _NakedMenuAnchorState extends State<NakedMenuAnchor> {
  final FocusNode _overlayFocusNode = FocusNode(
    debugLabel: 'NakedMenu overlay',
  );

  // Cancelable delayed hide (prevents closing a just‑reopened overlay).
  Timer? _pendingHide;

  @override
  void dispose() {
    _pendingHide?.cancel();
    _overlayFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Heuristic:
    // - Menus (default closeOnOutsideTap == true) should get overlay focus.
    // - Tooltips (closeOnOutsideTap == false) should not steal focus,
    //   unless the caller explicitly supplies onKeyEvent.
    final bool wantsOverlayFocus =
        widget.onKeyEvent != null || widget.closeOnOutsideTap;

    return RawMenuAnchor(
      childFocusNode: widget.childFocusNode,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      onOpen: widget.onOpen,
      onClose: widget.onClose,

      // Animation-friendly hooks.
      onOpenRequested: (Offset? _, VoidCallback showOverlay) {
        _pendingHide?.cancel();
        showOverlay();
      },
      onCloseRequested: (VoidCallback hideOverlay) {
        _pendingHide?.cancel();
        if (widget.removalDelay == Duration.zero) {
          hideOverlay();

          return;
        }
        _pendingHide = Timer(widget.removalDelay, () {
          _pendingHide = null;
          hideOverlay();
        });
      },

      useRootOverlay: widget.useRootOverlay,
      controller: widget.controller,

      overlayBuilder: (context, info) {
        return Positioned.fill(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          child: FocusTraversalGroup(
            child: CustomSingleChildLayout(
              delegate: _NakedPositionDelegate(
                anchorRect: info.anchorRect,
                overlaySize: info.overlaySize,
                anchorAlignment: widget.position,
                fallbackAlignments: widget.fallbackPositions,
                pointerPosition:
                    info.position, // honors MenuController.open(position: …)
              ),
              child: _OverlayInteractionShell(
                groupId: info.tapRegionGroupId,
                closeOnOutsideTap: widget.closeOnOutsideTap,
                controller: widget.controller,
                focusNode: _overlayFocusNode,
                autofocus: wantsOverlayFocus,
                onKeyEvent: widget.onKeyEvent,
                child: widget.overlayBuilder(context),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Internal shell that wires outside-tap, ESC dismissal, and focus handling.
class _OverlayInteractionShell extends StatelessWidget {
  const _OverlayInteractionShell({
    required this.groupId,
    required this.closeOnOutsideTap,
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.child,
    this.onKeyEvent,
  });

  final Object? groupId;
  final bool closeOnOutsideTap;
  final MenuController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final KeyEventResult Function(KeyEvent event)? onKeyEvent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: closeOnOutsideTap
          ? (PointerDownEvent _) => controller.close()
          : null,
      groupId: groupId,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
        },
        child: Actions(
          actions: {
            DismissIntent: DismissMenuAction(controller: controller),
            NextFocusIntent: CallbackAction<NextFocusIntent>(
              onInvoke: (_) => FocusScope.of(context).nextFocus(),
            ),
            PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
              onInvoke: (_) => FocusScope.of(context).previousFocus(),
            ),
          },
          child: Focus(
            focusNode: focusNode,
            autofocus: autofocus,
            onKeyEvent: (node, event) =>
                onKeyEvent?.call(event) ?? KeyEventResult.ignored,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NakedPositionDelegate extends SingleChildLayoutDelegate {
  final Rect anchorRect;
  final Size overlaySize;
  final NakedMenuPosition anchorAlignment;
  final List<NakedMenuPosition> fallbackAlignments;
  final Offset?
  pointerPosition; // RawMenuOverlayInfo.position (if open(position: …))

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

/// Marker interface with timing + callback; used by [MenuAnchorChildLifecycleMixin].
abstract class OverlayChildLifecycle {
  final OverlayChildLifecycleCallback? onStateChange;
  final Duration removalDelay;
  const OverlayChildLifecycle({
    this.onStateChange,
    this.removalDelay = Duration.zero,
  });
}

/// Converts a `showNotifier` boolean into controller.open/close and emits lifecycle states.
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
