import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'naked_widgets.dart';
import 'utilities/positioning.dart';

/// Provides tooltip behavior without visual styling.
///
/// Handles showing, hiding, and positioning tooltips with automatic
/// dismissal after specified duration.
///
/// Example:
/// ```dart
/// class TooltipExample extends StatefulWidget {
///  const TooltipExample({super.key});
///
///   @override
///   State<TooltipExample> createState() => _TooltipExampleState();
/// }
///
/// class _TooltipExampleState extends State<TooltipExample>
///     with SingleTickerProviderStateMixin {
///   late final _animationController = AnimationController(
///     duration: const Duration(milliseconds: 300),
///     vsync: this,
///   );
///
///   @override
///   void dispose() {
///     _animationController.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return NakedTooltip(
///       semanticsLabel: 'This is a tooltip',
///       positioning: const OverlayPositionConfig(
///         targetAnchor: Alignment.bottomCenter,
///         followerAnchor: Alignment.topCenter,
///         offset: Offset(0, 4),
///       ),
///       waitDuration: const Duration(seconds: 0),
///       showDuration: const Duration(seconds: 1),
///       onOpenRequested: (_, show) {
///         show();
///         _animationController.forward();
///       },
///       onCloseRequested: (hide) {
///         _animationController.reverse().then((value) {
///           hide();
///         });
///       },
///       overlayBuilder: (context, info) => FadeTransition(
///         opacity: _animationController,
///         child: Container(
///           decoration: BoxDecoration(
///             color: Colors.black54,
///             borderRadius: BorderRadius.circular(4),
///           ),
///           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
///           child: const Text('This is a tooltip',
///               style: TextStyle(color: Colors.white)),
///         ),
///       ),
///       child: Container(
///         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
///         decoration: BoxDecoration(
///           color: const Color(0xFF3D3D3D),
///           borderRadius: BorderRadius.circular(10),
///         ),
///         child: const Text(
///           'Hover me',
///           style: TextStyle(
///             color: Colors.white,
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
class NakedTooltip extends StatefulWidget {
  /// Creates a headless tooltip.
  const NakedTooltip({
    super.key,
    required this.child,
    required this.overlayBuilder,
    this.showDuration = const Duration(seconds: 2),
    this.waitDuration = const Duration(seconds: 1),
    this.positioning = const OverlayPositionConfig(
      targetAnchor: Alignment.topCenter,
      followerAnchor: Alignment.bottomCenter,
    ),
    this.onOpen,
    this.onClose,
    this.onOpenRequested,
    this.onCloseRequested,
    this.semanticsLabel,
    this.excludeSemantics = false,
  });

  /// See also:
  /// - [NakedPopover], for anchored, click-triggered overlays.

  /// The widget that triggers the tooltip.
  final Widget child;

  /// The tooltip content overlayBuilder.
  final RawMenuAnchorOverlayBuilder overlayBuilder;

  /// The semantic label for screen readers.
  final String? semanticsLabel;

  /// Positioning configuration for the overlay.
  final OverlayPositionConfig positioning;

  /// The duration tooltip remains visible.
  final Duration showDuration;

  /// The duration to wait before showing tooltip.
  final Duration waitDuration;

  /// Called when the tooltip opens.
  final VoidCallback? onOpen;

  /// Called when the tooltip closes.
  final VoidCallback? onClose;

  /// Called when a request is made to open the tooltip.
  ///
  /// Allows customizing opening behavior with animations or delays.
  /// Call the provided callback to show the tooltip.
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  /// Called when a request is made to close the tooltip.
  ///
  /// Allows customizing closing behavior with animations or delays.
  /// Call the provided callback to hide the tooltip.
  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, the widget and its children are hidden from accessibility services.
  final bool excludeSemantics;

  @override
  State<NakedTooltip> createState() => _NakedTooltipState();
}

class _NakedTooltipState extends State<NakedTooltip>
    with WidgetStatesMixin<NakedTooltip> {
  // ignore: dispose-fields
  final _menuController = MenuController();
  Timer? _showTimer;
  Timer? _waitTimer;

  void _handleMouseEnter(PointerEnterEvent _) {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    _waitTimer = Timer(widget.waitDuration, () {
      _menuController.open();
    });
  }

  void _handleMouseExit(PointerExitEvent _) {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    _showTimer = Timer(widget.showDuration, () {
      _menuController.close();
    });
  }

  void _handleOpen() {
    widget.onOpen?.call();
  }

  void _handleClose() {
    widget.onClose?.call();
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tooltipContent = MouseRegion(
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      child: widget.child,
    );

    Widget tooltipChild = widget.excludeSemantics
        ? tooltipContent
        : Semantics(
            container: true,
            tooltip: widget.semanticsLabel,
            child: tooltipContent,
          );

    return RawMenuAnchor(
      consumeOutsideTaps: false,
      onOpen: _handleOpen,
      onClose: _handleClose,
      onOpenRequested: widget.onOpenRequested ?? (_, show) => show(),
      onCloseRequested: widget.onCloseRequested ?? (hide) => hide(),
      controller: _menuController,
      overlayBuilder: (context, info) => OverlayPositioner(
        targetRect: info.anchorRect,
        positioning: widget.positioning,
        child: widget.overlayBuilder(context, info),
      ),
      child: tooltipChild,
    );
  }
}
