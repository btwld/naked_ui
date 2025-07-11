import 'dart:async';

import 'package:flutter/material.dart';

import 'utilities/utilities.dart';

/// A fully customizable tooltip with no default styling.
///
/// NakedTooltip provides core tooltip behavior and accessibility
/// without imposing any visual styling, giving consumers complete design freedom.
///
/// This component handles showing and hiding tooltips, positioning the tooltip
/// relative to the target widget, and automatically dismissing the tooltip
/// after a specified duration.
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
  ///
  /// The [child] and [tooltipWidget] parameters are required.
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
    this.tooltipSemantics,
    this.excludeFromSemantics = false,
    this.fallbackPositions = const [],
    this.removalDelay = Duration.zero,
    this.onStateChange,
  });

  /// The widget that triggers the tooltip.
  final Widget child;

  /// The widget to display in the tooltip.
  final WidgetBuilder tooltipBuilder;

  /// The position of the tooltip relative to the target.
  final NakedMenuPosition position;

  /// Optional semantic label for accessibility.
  final String? tooltipSemantics;

  /// Whether to exclude the tooltip from the semantics tree.
  final bool excludeFromSemantics;

  /// The fallback alignments for the tooltip.
  final List<NakedMenuPosition> fallbackPositions;

  /// The duration for which the tooltip remains visible.
  final Duration showDuration;

  /// The duration to wait before showing the tooltip after hover.
  final Duration waitDuration;

  /// The duration to wait before removing the Widget from the Overlay after the tooltip is hidden.
  @override
  final Duration removalDelay;

  /// The event handler for the tooltip.
  @override
  final void Function(OverlayChildLifecycleState state)? onStateChange;

  @override
  State<NakedTooltip> createState() => _NakedTooltipState();
}

class _NakedTooltipState extends State<NakedTooltip>
    with MenuAnchorChildLifecycleMixin {
  Timer? _showTimer;
  Timer? _waitTimer;

  @override
  void dispose() {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: widget.excludeFromSemantics,
      tooltip: widget.excludeFromSemantics ? null : widget.tooltipSemantics,
      child: ListenableBuilder(
        listenable: showNotifier,
        builder: (context, child) {
          return NakedMenuAnchor(
            controller: controller,
            overlayBuilder: widget.tooltipBuilder,
            position: widget.position,
            fallbackPositions: widget.fallbackPositions,
            child: MouseRegion(
              onEnter: (_) {
                _showTimer?.cancel();
                _waitTimer?.cancel();
                _waitTimer = Timer(widget.waitDuration, () {
                  showNotifier.value = true;
                });
              },
              onExit: (_) {
                _showTimer?.cancel();
                _waitTimer?.cancel();
                _showTimer = Timer(widget.showDuration, () {
                  showNotifier.value = false;
                });
              },
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
