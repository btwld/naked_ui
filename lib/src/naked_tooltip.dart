import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/positioning.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedTooltip.builder].
class NakedTooltipState extends NakedState {
  /// Whether the tooltip is currently open.
  final bool isOpen;

  NakedTooltipState({required super.states, required this.isOpen});

  /// Returns the nearest [NakedTooltipState] provided by [NakedStateScope].
  static NakedTooltipState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedTooltipState] if one is available.
  static NakedTooltipState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedTooltipState &&
        setEquals(other.states, states) &&
        other.isOpen == isOpen;
  }

  @override
  int get hashCode => Object.hash(states, isOpen);
}

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
///       overlayBuilder: (context, info) {
///         return AnimatedBuilder(
///           animation: _controller,
///           overlayBuilder: (context, child) {
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
    this.child,
    this.builder,
    required this.overlayBuilder,
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
    this.excludeSemantics = false,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// See also:
  /// - [NakedPopover], for anchored, click-triggered overlays.

  /// The widget that triggers the tooltip.
  final Widget? child;

  /// Builds the tooltip trigger using the current [NakedTooltipState].
  final ValueWidgetBuilder<NakedTooltipState>? builder;

  /// The tooltip content overlayBuilder.
  final RawMenuAnchorOverlayBuilder overlayBuilder;

  /// The semantic label for screen readers.
  final String? semanticsLabel;

  /// Whether to exclude this widget from the semantic tree.
  final bool excludeSemantics;

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
    final tooltipState = NakedTooltipState(
      states: widgetStates,
      isOpen: _menuController.isOpen,
    );

    final content = widget.builder != null
        ? widget.builder!(context, tooltipState, widget.child)
        : widget.child!;

    final wrappedContent = NakedStateScope(value: tooltipState, child: content);

    // Step 1: Build core anchor with mouse region
    Widget child = RawMenuAnchor(
      consumeOutsideTaps: false, // Do not consume taps for tooltips
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
          child: widget.overlayBuilder(context, info),
        );
      },
      child: MouseRegion(
        onEnter: _handleMouseEnter,
        onExit: _handleMouseExit,
        child: wrappedContent,
      ),
    );

    // Step 2: Conditionally wrap with semantics
    if (!widget.excludeSemantics) {
      child = Semantics(
        container: true,
        tooltip: widget.semanticsLabel,
        child: child,
      );
    }

    return child;
  }
}
