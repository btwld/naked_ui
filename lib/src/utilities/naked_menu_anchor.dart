import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Dismiss with Escape using the app's default shortcut mapping.
/// We only need to provide an Action that knows how to close *this* menu.
class NakedDismissMenuAction extends DismissAction {
  final MenuController controller;
  NakedDismissMenuAction({required this.controller});
  @override
  void invoke(DismissIntent intent) => controller.close();

  @override
  bool isEnabled(DismissIntent intent) => controller.isOpen;
}

/// Defines how an overlay (follower) is positioned relative to its target.
class NakedMenuPosition {
  final Alignment target;

  final Alignment follower;
  const NakedMenuPosition({
    this.target = Alignment.bottomLeft,
    this.follower = Alignment.topLeft,
  });
}

/// Anchors an overlay to a target and manages its lifecycle, headlessly.
///
/// - Uses RawMenuAnchor to handle open/close and outside taps
/// - Groups overlay + anchor via TapRegion to define "inside"
/// - Lets default Shortcuts handle arrows/activate; adds Dismiss (Esc) action
class NakedMenuAnchor extends StatefulWidget {
  const NakedMenuAnchor({
    super.key,
    required this.controller,
    required this.overlayBuilder,
    this.child,
    this.useRootOverlay = false,
    this.consumeOutsideTaps = true,
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

  /// Whether the outside tap that closes the menu is swallowed.
  final bool consumeOutsideTaps;

  final bool useRootOverlay;
  final NakedMenuPosition position;
  final List<NakedMenuPosition> fallbackPositions;

  final VoidCallback? onClose;
  final VoidCallback? onOpen;

  /// Optional raw key listener (e.g., type‑ahead).
  final void Function(KeyEvent)? onKeyEvent;

  @override
  State<NakedMenuAnchor> createState() => _NakedMenuAnchorState();
}

class _NakedMenuAnchorState extends State<NakedMenuAnchor> {
  // Focus so overlay receives key events immediately on open.
  final FocusNode _overlayFocusNode = FocusNode(
    debugLabel: 'NakedMenu overlay',
  );

  Widget _overlayBuilder(BuildContext context, RawMenuOverlayInfo info) {
    return Positioned.fill(
      bottom: MediaQuery.viewInsetsOf(context).bottom,
      child: TapRegion(
        // Group anchor + overlay so taps inside either aren't "outside".
        groupId: info.tapRegionGroupId,
        child: CustomSingleChildLayout(
          delegate: _NakedPositionDelegate(
            target: info.anchorRect.topLeft,
            targetSize: info.anchorRect.size,
            alignment: widget.position,
            fallbackAlignments: widget.fallbackPositions,
          ),
          child: Actions(
            actions: {
              DismissIntent: NakedDismissMenuAction(
                controller: widget.controller,
              ),
            },
            // Let default Shortcuts handle arrows/activate; we still read raw keys.
            child: Focus(
              focusNode: _overlayFocusNode,
              autofocus: true,
              onKeyEvent: (node, event) {
                widget.onKeyEvent?.call(event);

                return KeyEventResult.ignored; // allow bubbling
              },
              child: widget.overlayBuilder(context),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _overlayFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      consumeOutsideTaps: widget.consumeOutsideTaps,
      onOpen: widget.onOpen,
      onClose: widget.onClose,
      useRootOverlay: widget.useRootOverlay,
      controller: widget.controller,
      overlayBuilder: _overlayBuilder,
      child: widget.child,
    );
  }
}

abstract class OverlayChildLifecycle {
  /// Called as the overlay transitions through states.
  final OverlayChildLifecycleCallback? onStateChange;

  /// Delay removal after close (for exit animations).
  final Duration removalDelay;

  const OverlayChildLifecycle({
    this.onStateChange,
    this.removalDelay = Duration.zero,
  });
}

typedef OverlayChildLifecycleCallback =
    void Function(OverlayChildLifecycleState state);

mixin MenuAnchorChildLifecycleMixin<T extends StatefulWidget> on State<T> {
  OverlayChildLifecycle get overlayChildLifecycle =>
      widget as OverlayChildLifecycle;

  final MenuController controller = MenuController();
  final ValueNotifier<bool> showNotifier = ValueNotifier(false);

  Timer? _removalTimer;

  OverlayChildLifecycleCallback? get _onStateChange =>
      overlayChildLifecycle.onStateChange;

  @override
  void initState() {
    super.initState();
    showNotifier.addListener(_handleShowNotifierChange);
  }

  @override
  void dispose() {
    _removalTimer?.cancel();
    showNotifier.removeListener(_handleShowNotifierChange);
    super.dispose();
  }

  void _handleShowNotifierChange() {
    if (showNotifier.value) {
      _removalTimer?.cancel();
      controller.open();
      _onStateChange?.call(OverlayChildLifecycleState.present);
    } else {
      _onStateChange?.call(OverlayChildLifecycleState.pendingRemoval);
      _removalTimer?.cancel();
      _removalTimer = Timer(overlayChildLifecycle.removalDelay, () {
        controller.close();
        _onStateChange?.call(OverlayChildLifecycleState.removed);
      });
    }
  }
}

class _NakedPositionDelegate extends SingleChildLayoutDelegate {
  /// Target's top-left in global coords.
  final Offset target;

  /// Target's size.
  final Size targetSize;

  final NakedMenuPosition alignment;

  final List<NakedMenuPosition> fallbackAlignments;
  const _NakedPositionDelegate({
    required this.target,
    required this.targetSize,
    required this.alignment,
    required this.fallbackAlignments,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    Offset aligned(NakedMenuPosition pos) {
      final targetAnchor = pos.target.alongSize(targetSize);
      final followerAnchor = pos.follower.alongSize(childSize);

      return target + targetAnchor - followerAnchor;
    }

    // Try preferred + fallbacks; pick first that fits fully on screen.
    final candidates = [alignment, ...fallbackAlignments];
    for (final pos in candidates) {
      final off = aligned(pos);
      final fullyVisible =
          off.dx >= 0 &&
          off.dy >= 0 &&
          off.dx + childSize.width <= size.width &&
          off.dy + childSize.height <= size.height;
      if (fullyVisible) return off;
    }

    // Otherwise return preferred (may overflow slightly).
    return aligned(alignment);
  }

  @override
  bool shouldRelayout(_NakedPositionDelegate old) {
    return target != old.target ||
        targetSize != old.targetSize ||
        alignment != old.alignment ||
        !listEquals(fallbackAlignments, old.fallbackAlignments);
  }
}

enum OverlayChildLifecycleState { present, pendingRemoval, removed }
