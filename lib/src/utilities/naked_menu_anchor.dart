import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
    TraversalDirection.down,
  ),
  SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
    TraversalDirection.up,
  ),
  SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(
    TraversalDirection.left,
  ),
  SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(
    TraversalDirection.right,
  ),
};

/// An action that closes the menu when a dismiss intent is received.
/// 
/// Typically triggered by the Escape key to close the currently open menu.
class NakedDismissMenuAction extends DismissAction {
  /// The [MenuController] that manages the menu to be dismissed.
  final MenuController controller;
  
  /// Creates a [NakedDismissMenuAction].
  NakedDismissMenuAction({required this.controller});
  
  @override
  void invoke(DismissIntent intent) {
    controller.close();
  }
  
  @override
  bool isEnabled(DismissIntent intent) {
    return controller.isOpen;
  }
}

/// Defines how an overlay (follower) is positioned relative to its target.
///
/// The [target] alignment picks a point within the target's bounds and the
/// [follower] alignment picks a point within the overlay's bounds. The overlay
/// is positioned so that these points coincide. For example, the default
/// [Alignment.bottomLeft] target with [Alignment.topLeft] follower positions
/// the overlay directly below the target, left aligned.
class NakedMenuPosition {
  final Alignment target;
  final Alignment follower;

  const NakedMenuPosition({
    this.target = Alignment.bottomLeft,
    this.follower = Alignment.topLeft,
  });
}

/// Anchors an overlay to a target widget and manages its lifecycle.
///
/// This widget wires up keyboard navigation, focus management, outside-tap
/// dismissal, and fallback positioning for overlays such as menus and selects.
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
  final bool useRootOverlay;
  final bool consumeOutsideTaps;
  final Widget? child;
  final NakedMenuPosition position;
  final List<NakedMenuPosition> fallbackPositions;
  final VoidCallback? onClose;
  final VoidCallback? onOpen;

  final void Function(KeyEvent)? onKeyEvent;

  @override
  State<NakedMenuAnchor> createState() => _NakedMenuAnchorState();
}

class _NakedMenuAnchorState extends State<NakedMenuAnchor> {
  final _focusScopeNode = FocusScopeNode();
  ScrollPosition? _scrollPosition;
  Size? _viewSize;

  void _handleScroll() {
    // Close menu when ancestor scrolls (but not when menu content itself scrolls)
    if (widget.controller.isOpen) {
      widget.controller.close();
    }
  }

  Widget _overlayBuilder(BuildContext context, RawMenuOverlayInfo info) {
    return Positioned.fill(
      bottom: MediaQuery.of(context).viewInsets.bottom,
      child: Semantics(
        explicitChildNodes: true,
        scopesRoute: true,
        child: TapRegion(
          onTapOutside: (PointerDownEvent event) {
            widget.controller.close();
          },
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
                DismissIntent: NakedDismissMenuAction(controller: widget.controller),
              },
              child: Shortcuts(
                shortcuts: _shortcuts,
                child: KeyboardListener(
                  focusNode: _focusScopeNode,
                  autofocus: true,
                  onKeyEvent: widget.onKeyEvent,
                  child: widget.overlayBuilder(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Set up scroll listener for auto-close behavior
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.isScrollingNotifier.addListener(_handleScroll);
    
    // Monitor view size changes for auto-close on resize
    final Size newSize = MediaQuery.sizeOf(context);
    if (_viewSize != null && newSize != _viewSize && widget.controller.isOpen) {
      // Close the menu if the view changes size while open
      widget.controller.close();
    }
    _viewSize = newSize;
  }

  @override
  void dispose() {
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
    _focusScopeNode.dispose();
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
  final Duration removalDelay;

  final OverlayChildLifecycleCallback? onStateChange;

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

  Timer? _removalTimer;
  OverlayChildLifecycleCallback? get _onStateChange =>
      overlayChildLifecycle.onStateChange;

  final showNotifier = ValueNotifier<bool>(false);

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
  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The amount of vertical distance between the target and the displayed
  /// tooltip.
  final Size targetSize;

  final NakedMenuPosition alignment;

  final List<NakedMenuPosition> fallbackAlignments;

  const
  /// Creates a delegate for computing the layout of a tooltip.
  _NakedPositionDelegate({
    required this.target,
    required this.targetSize,
    required this.alignment,
    required this.fallbackAlignments,
  });

  Offset _calculateOverlayPosition({
    required Size screenSize,
    required Size targetSize,
    required Offset targetPosition,
    required Size overlaySize,
    required NakedMenuPosition alignment,
    List<NakedMenuPosition> fallbackAlignments = const [],
  }) {
    final allAlignments = [alignment, ...fallbackAlignments];

    for (final pair in allAlignments) {
      final candidate = _calculateAlignedOffset(
        targetTopLeft: targetPosition,
        targetSize: targetSize,
        overlaySize: overlaySize,
        alignment: pair,
      );

      if (_isOverlayFullyVisible(candidate, overlaySize, screenSize)) {
        return candidate;
      }
    }

    // Return first attempt even if it overflows
    return _calculateAlignedOffset(
      targetTopLeft: targetPosition,
      targetSize: targetSize,
      overlaySize: overlaySize,
      alignment: alignment,
    );
  }

  Offset _calculateAlignedOffset({
    required Offset targetTopLeft,
    required Size targetSize,
    required Size overlaySize,
    required NakedMenuPosition alignment,
  }) {
    final targetAnchorOffset = alignment.target.alongSize(targetSize);
    final followerAnchorOffset = alignment.follower.alongSize(overlaySize);

    return targetTopLeft + targetAnchorOffset - followerAnchorOffset;
  }

  bool _isOverlayFullyVisible(
    Offset overlayTopLeft,
    Size overlaySize,
    Size screenSize,
  ) {
    return overlayTopLeft.dx >= 0 &&
        overlayTopLeft.dy >= 0 &&
        overlayTopLeft.dx + overlaySize.width <= screenSize.width &&
        overlayTopLeft.dy + overlaySize.height <= screenSize.height;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return _calculateOverlayPosition(
      screenSize: size,
      targetSize: targetSize,
      targetPosition: target,
      overlaySize: childSize,
      alignment: alignment,
      fallbackAlignments: fallbackAlignments,
    );
  }

  @override
  bool shouldRelayout(_NakedPositionDelegate oldDelegate) {
    return target != oldDelegate.target || targetSize != oldDelegate.targetSize;
  }
}

enum OverlayChildLifecycleState { present, pendingRemoval, removed }
