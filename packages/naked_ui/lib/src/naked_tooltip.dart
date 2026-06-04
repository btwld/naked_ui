import 'package:flutter/widgets.dart';

import 'naked_widgets.dart';
import 'utilities/positioning.dart';

/// Provides tooltip behavior without visual styling.
///
/// Handles showing, hiding, and positioning tooltips with automatic
/// dismissal. Wraps Flutter's [RawTooltip] to provide a consistent
/// naked_ui API with support for [OverlayPositionConfig]-based positioning.
///
/// The [overlayBuilder] receives an [Animation] that drives the tooltip's
/// show/hide transition, making it easy to add fade, scale, or custom
/// animations.
///
/// Example:
/// ```dart
/// class TooltipExample extends StatelessWidget {
///   const TooltipExample({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return NakedTooltip(
///       semanticLabel: 'This is a tooltip',
///       positioning: const OverlayPositionConfig(
///         targetAnchor: Alignment.bottomCenter,
///         followerAnchor: Alignment.topCenter,
///         offset: Offset(0, 4),
///       ),
///       hoverDelay: Duration.zero,
///       dismissDelay: const Duration(seconds: 1),
///       overlayBuilder: (context, animation) => FadeTransition(
///         opacity: animation,
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
    this.hoverDelay = Duration.zero,
    this.touchDelay = const Duration(milliseconds: 1500),
    this.dismissDelay = const Duration(milliseconds: 100),
    this.enableTapToDismiss = true,
    this.triggerMode = TooltipTriggerMode.longPress,
    this.enableFeedback = true,
    this.onTriggered,
    this.animationStyle = const AnimationStyle(
      curve: Curves.fastOutSlowIn,
      duration: Duration(milliseconds: 150),
      reverseDuration: Duration(milliseconds: 75),
    ),
    this.positioning = const OverlayPositionConfig(),
    this.semanticLabel,
    this.excludeSemantics = false,
  });

  /// See also:
  /// - [NakedPopover], for anchored, click-triggered overlays.

  /// The widget that triggers the tooltip.
  final Widget child;

  /// Builds the tooltip content displayed in the overlay.
  ///
  /// The [animation] drives the show/hide transition (0.0 → 1.0 when showing,
  /// 1.0 → 0.0 when hiding). Use it with [FadeTransition], [ScaleTransition],
  /// or similar widgets for animated tooltips.
  final TooltipComponentBuilder overlayBuilder;

  /// The semantic label for screen readers.
  ///
  /// When null, the trigger keeps its own accessible name, but no tooltip
  /// semantic text is exposed.
  final String? semanticLabel;

  /// Positioning configuration for the overlay using anchor-based alignment.
  final OverlayPositionConfig positioning;

  /// The delay before the tooltip is shown when hovering with a mouse.
  ///
  /// Defaults to [Duration.zero] (shown immediately on hover).
  final Duration hoverDelay;

  /// The duration the tooltip remains visible after a touch trigger is released.
  ///
  /// Does not affect mouse pointer devices.
  ///
  /// Defaults to 1500 milliseconds.
  final Duration touchDelay;

  /// The delay before the tooltip is hidden after the mouse exits.
  ///
  /// Defaults to 100 milliseconds.
  final Duration dismissDelay;

  /// Whether the tooltip can be dismissed by tapping elsewhere.
  ///
  /// Defaults to true.
  final bool enableTapToDismiss;

  /// How touch events should trigger the tooltip.
  ///
  /// Does not affect mouse hover behavior.
  ///
  /// Defaults to [TooltipTriggerMode.longPress].
  final TooltipTriggerMode triggerMode;

  /// Whether haptic/acoustic feedback is provided on touch trigger.
  ///
  /// Defaults to true.
  final bool enableFeedback;

  /// Called when the tooltip is triggered by tap or long press.
  ///
  /// Not called for mouse hover triggers.
  final TooltipTriggeredCallback? onTriggered;

  /// The animation style for the tooltip show/hide transition.
  ///
  /// Use [AnimationStyle.noAnimation] to disable animation.
  final AnimationStyle animationStyle;

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, no tooltip semantics text is exposed to
  /// accessibility services.
  final bool excludeSemantics;

  @override
  State<NakedTooltip> createState() => _NakedTooltipState();
}

class _NakedTooltipState extends State<NakedTooltip> {
  late TooltipPositionDelegate _positionDelegate;

  @override
  void initState() {
    super.initState();
    _positionDelegate = _buildPositionDelegate(widget.positioning);
  }

  @override
  void didUpdateWidget(NakedTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.positioning != oldWidget.positioning) {
      _positionDelegate = _buildPositionDelegate(widget.positioning);
    }
  }

  static TooltipPositionDelegate _buildPositionDelegate(
    OverlayPositionConfig config,
  ) {
    return (TooltipPositionContext context) {
      final targetTopLeft =
          context.target - context.targetSize.center(Offset.zero);
      final targetAnchorOffset = config.targetAnchor.alongSize(
        context.targetSize,
      );
      final followerAnchorOffset = config.followerAnchor.alongSize(
        context.tooltipSize,
      );
      final position =
          targetTopLeft +
          targetAnchorOffset -
          followerAnchorOffset +
          config.offset;

      return Offset(
        position.dx.clamp(
          0.0,
          (context.overlaySize.width - context.tooltipSize.width).clamp(
            0.0,
            double.infinity,
          ),
        ),
        position.dy.clamp(
          0.0,
          (context.overlaySize.height - context.tooltipSize.height).clamp(
            0.0,
            double.infinity,
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return RawTooltip(
      semanticsTooltip: widget.excludeSemantics ? null : widget.semanticLabel,
      tooltipBuilder: widget.overlayBuilder,
      hoverDelay: widget.hoverDelay,
      touchDelay: widget.touchDelay,
      dismissDelay: widget.dismissDelay,
      enableTapToDismiss: widget.enableTapToDismiss,
      triggerMode: widget.triggerMode,
      enableFeedback: widget.enableFeedback,
      onTriggered: widget.onTriggered,
      animationStyle: widget.animationStyle,
      positionDelegate: _positionDelegate,
      child: widget.child,
    );
  }
}
