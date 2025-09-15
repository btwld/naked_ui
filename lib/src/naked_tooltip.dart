import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'utilities/utilities.dart';

/// Provides tooltip behavior without visual styling.
///
/// Handles showing, hiding, and positioning tooltips relative to target widgets.
/// Automatically dismisses after specified duration.
///
/// Example:
/// ```dart
/// class TooltipExample extends StatefulWidget {
///   const TooltipExample({super.key});
///   @override
///   State<TooltipExample> createState() => _TooltipExampleState();
/// }
///
/// class _TooltipExampleState extends State<TooltipExample>
///     with SingleTickerProviderStateMixin {
///   late final _controller = AnimationController(
///     duration: const Duration(milliseconds: 300),
///     vsync: this,
///   );
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return NakedTooltip(
///       position: const NakedMenuPosition(
///         target: Alignment.topCenter,
///         follower: Alignment.bottomCenter,
///       ),
///       waitDuration: const Duration(milliseconds: 0),
///       showDuration: const Duration(milliseconds: 0),
///       removalDelay: const Duration(milliseconds: 300),
///       onStateChange: (state) {
///         switch (state) {
///           case OverlayChildLifecycleState.present:
///             _controller.forward();
///             break;
///           case OverlayChildLifecycleState.pendingRemoval:
///             _controller.reverse();
///             break;
///           case OverlayChildLifecycleState.removed:
///             break;
///         }
///       },
///       tooltipBuilder: (context) => SlideTransition(
///         position: _controller.drive(Tween<Offset>(
///           begin: const Offset(0, 0.1),
///           end: const Offset(0, 0),
///         )),
///         child: FadeTransition(
///           opacity: _controller,
///           child: Container(
///             padding: const EdgeInsets.all(8),
///             decoration: BoxDecoration(
///               color: Colors.grey[800],
///               borderRadius: BorderRadius.circular(4),
///             ),
///             child: const Text(
///               'This is a tooltip',
///               style: TextStyle(color: Colors.white),
///             ),
///           ),
///         ),
///       ),
///       child: Container(
///         padding: const EdgeInsets.all(8),
///         decoration: BoxDecoration(
///           color: const Color(0xFF2196F3),
///           borderRadius: BorderRadius.circular(4),
///         ),
///         child: const Text(
///           'Hover me',
///           style: TextStyle(color: Colors.white),
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
    this.semanticsLabel,
  });

  /// See also:
  /// - [NakedMenuAnchor], which is used to position the tooltip overlay
  ///   relative to its trigger.

  /// Widget that triggers the tooltip.
  final Widget child;

  /// Widget to display in the tooltip.
  final WidgetBuilder tooltipBuilder;

  /// Optional semantics tooltip label applied to the trigger.
  /// Screen readers announce this on focus/hover.
  final String? semanticsLabel;


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

  Widget _buildTooltipWidget(BuildContext _) {
    return NakedMenuAnchor(
      controller: controller,
      overlayBuilder: widget.tooltipBuilder,
      removalDelay: widget.removalDelay,
      position: widget.position,
      fallbackPositions: widget.fallbackPositions,
      child: MouseRegion(
        onEnter: _handleMouseEnter,
        onExit: _handleMouseExit,
        child: widget.child,
      ),
    );
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
        Widget tooltipWidget = _buildTooltipWidget(context);

        return Semantics(
          container: true,
          tooltip: widget.semanticsLabel,
          child: tooltipWidget,
        );
      },
    );
  }
}
