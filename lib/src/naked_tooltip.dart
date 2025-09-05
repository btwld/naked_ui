import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'utilities/utilities.dart';

/// Provides tooltip behavior without visual styling.
///
/// Handles showing, hiding, and positioning tooltips relative to target widgets.
/// Automatically dismisses after specified duration.
///
/// Example:
/// ```dart
/// class MyTooltip extends StatefulWidget {
///   @override
///   _MyTooltipState createState() => _MyTooltipState();
/// }
///
/// class _MyTooltipState extends State<MyTooltip>
///     with SingleTickerProviderStateMixin {
///   late final _controller = OverlayPortalController();
///   late final animationController = AnimationController(
///     duration: const Duration(milliseconds: 2000),
///     vsync: this,
///   );
///   late final CurvedAnimation _animation;
///
///   @override
///   void initState() {
///     super.initState();
///     _animation = CurvedAnimation(
///       parent: animationController,
///       curve: Curves.easeInOut,
///     );
///   }
///
///   @override
///   void dispose() {
///     animationController.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return NakedTooltip(
///       fallbackAlignments: [
///         AlignmentPair(
///           target: Alignment.topCenter,
///           follower: Alignment.bottomCenter,
///           offset: const Offset(0, -8),
///         ),
///       ],
///       targetAnchor: Alignment.bottomCenter,
///       followerAnchor: Alignment.topCenter,
///       offset: const Offset(0, 8),
///       tooltipWidgetBuilder:
///           (context) => FadeTransition(
///             opacity: _animation,
///             child: Container(
///               padding: EdgeInsets.all(8),
///               decoration: BoxDecoration(
///                 color: Colors.grey[800],
///                 borderRadius: BorderRadius.circular(4),
///               ),
///               child: Text(
///                 'This is a tooltip',
///                 style: TextStyle(color: Colors.white),
///               ),
///             ),
///           ),
///       controller: _controller,
///       child: MouseRegion(
///         onEnter: (_) {
///           _controller.show();
///           animationController.forward();
///         },
///         onExit: (_) {
///           animationController.reverse().then((_) {
///             _controller.hide();
///           });
///         },
///         child: Container(
///           padding: EdgeInsets.all(8),
///           decoration: BoxDecoration(
///             color: const Color(0xFF2196F3),
///             borderRadius: BorderRadius.circular(4),
///           ),
///           child: Text('Hover me', style: TextStyle(color: Colors.white)),
///         ),
///       ),
///     );
///   }
/// }
/// ```
class NakedTooltip extends StatefulWidget implements OverlayChildLifecycle {
  /// Creates a naked tooltip.
  const NakedTooltip({
    super.key,
    required this.child,
    required this.tooltipBuilder,
    this.showDuration = const Duration(seconds: 2),
    this.waitDuration = const Duration(seconds: 1),
    this.position = const NakedMenuPosition(
      target: Alignment.topCenter,
      follower: Alignment.bottomCenter,
    ),
    this.fallbackPositions = const [],
    this.removalDelay = Duration.zero,
    this.onStateChange,
  });

  /// Widget that triggers the tooltip.
  final Widget child;

  /// Widget to display in the tooltip.
  final WidgetBuilder tooltipBuilder;

  /// Tooltip position relative to the target.
  final NakedMenuPosition position;

  /// Fallback alignments for the tooltip.
  final List<NakedMenuPosition> fallbackPositions;

  /// Duration tooltip remains visible.
  final Duration showDuration;

  /// Duration to wait before showing tooltip after hover.
  final Duration waitDuration;

  /// Duration before removing widget from overlay after tooltip is hidden.
  @override
  final Duration removalDelay;

  /// Event handler for the tooltip.
  @override
  final void Function(OverlayChildLifecycleState state)? onStateChange;

  @override
  State<NakedTooltip> createState() => _NakedTooltipState();
}

class _NakedTooltipState extends State<NakedTooltip>
    with MenuAnchorChildLifecycleMixin {
  Timer? _showTimer;
  Timer? _waitTimer;

  void _handleMouseEnter(PointerEnterEvent _) {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    _waitTimer = Timer(widget.waitDuration, () {
      showNotifier.value = true;
    });
  }

  void _handleMouseExit(PointerExitEvent _) {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    _showTimer = Timer(widget.showDuration, () {
      showNotifier.value = false;
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: showNotifier,
        builder: (context, child) {
          return NakedMenuAnchor(
            controller: controller,
            overlayBuilder: widget.tooltipBuilder,
            position: widget.position,
            fallbackPositions: widget.fallbackPositions,
            child: MouseRegion(
              onEnter: _handleMouseEnter,
              onExit: _handleMouseExit,
              child: widget.child,
            ),
          );
        },
    );
  }
}
