import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'utilities/positioning.dart';

/// Provides tooltip behavior without visual styling.
///
/// Handles showing, hiding, and positioning tooltips with automatic
/// dismissal after specified duration.
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
///       positioning: const OverlayPositionConfig(
///         alignment: Alignment.topCenter,
///         fallbackAlignment: Alignment.bottomCenter,
///       ),
///       onOpen: () => _controller.forward(),
///       onClose: () => _controller.reverse(),
///       child: NakedButton(
///         onPressed: () {},
///         child: const Text('Show Tooltip'),
///       ),
///       tooltipBuilder: (context) {
///         return AnimatedBuilder(
///           animation: _controller,
///           builder: (context, child) {
///             return Opacity(
///               opacity: _controller.value,
///               child: Container(
///                 decoration: BoxDecoration(
///                   color: Colors.black,
///                   borderRadius: BorderRadius.circular(8),
///                 ),
///                 padding: const EdgeInsets.all(12),
///                 child: const Text(
///                   'This is a tooltip!',
///                   style: TextStyle(color: Colors.white),
///                 ),
///               ),
///             );
///           },
///         );
///       },
///     );
///   }
/// }
/// ```
class NakedTooltip extends StatefulWidget {
  /// Creates a headless tooltip.
  const NakedTooltip({
    super.key,
    required this.child,
    required this.tooltipBuilder,
    this.showDuration = const Duration(seconds: 2),
    this.waitDuration = const Duration(seconds: 1),
    this.positioning = const OverlayPositionConfig(
      alignment: Alignment.topCenter,
      fallbackAlignment: Alignment.bottomCenter,
    ),
    this.onOpen,
    this.onClose,
    this.onOpenRequested,
    this.onCloseRequested,
    this.semanticsLabel,
  });

  /// See also:
  /// - [NakedPopover], for anchored, click-triggered overlays.

  /// The widget that triggers the tooltip.
  final Widget child;

  /// The tooltip content builder.
  final WidgetBuilder tooltipBuilder;

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
  /// This callback allows you to customize the opening behavior, such as
  /// adding animations or delays. Call `showOverlay` to actually show the tooltip.
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  /// Called when a request is made to close the tooltip.
  ///
  /// This callback allows you to customize the closing behavior, such as
  /// adding animations or delays. Call `hideOverlay` to actually hide the tooltip.
  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  @override
  State<NakedTooltip> createState() => _NakedTooltipState();
}

class _NakedTooltipState extends State<NakedTooltip> {
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
    return RawMenuAnchor(
      consumeOutsideTaps: false, // Don't consume taps for tooltips
      onOpen: _handleOpen,
      onClose: _handleClose,
      onOpenRequested: widget.onOpenRequested ?? (_, show) => show(),
      onCloseRequested: widget.onCloseRequested ?? (hide) => hide(),
      controller: _menuController,
      overlayBuilder: (context, info) {
        final overlayRect = calculateOverlayPosition(
          anchorRect: info.anchorRect,
          overlaySize: info.overlaySize,
          childSize: info.overlaySize, // Will be constrained by content
          config: widget.positioning,
          pointerPosition: info.position,
        );

        return Positioned.fromRect(
          rect: overlayRect,
          child: widget.tooltipBuilder(context),
        );
      },
      child: Semantics(
        container: true,
        tooltip: widget.semanticsLabel,
        child: MouseRegion(
          onEnter: _handleMouseEnter,
          onExit: _handleMouseExit,
          child: widget.child,
        ),
      ),
    );
  }
}
