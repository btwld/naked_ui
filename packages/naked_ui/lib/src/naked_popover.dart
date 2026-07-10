import 'package:flutter/widgets.dart';

import 'naked_button.dart';
import 'utilities/anchored_overlay_shell.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/positioning.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedPopover.builder].
class NakedPopoverState extends NakedState {
  /// Whether the overlay is currently open.
  final bool isOpen;

  NakedPopoverState({required super.states, required this.isOpen});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedPopoverState &&
        statesEqual(other) &&
        other.isOpen == isOpen;
  }

  @override
  int get hashCode => Object.hash(statesHashCode, isOpen);

  /// Returns the nearest [NakedPopoverState] provided by [NakedStateScope].
  static NakedPopoverState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedPopoverState] if available.
  static NakedPopoverState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf<NakedPopoverState>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf<NakedPopoverState>(context);
}

/// A headless popover without visuals.
///
/// Provides toggleable overlay functionality with custom content rendering.
/// Handles tap interactions, positioning, and focus management.
///
/// ```dart
/// // Static trigger
/// NakedPopover(
///   popoverBuilder: (context, info) => Container(
///     padding: EdgeInsets.all(16),
///     child: Text('Popover content'),
///   ),
///   child: Text('Click me'),
/// )
///
/// // Dynamic trigger with state
/// NakedPopover(
///   popoverBuilder: (context, info) => Container(
///     padding: EdgeInsets.all(16),
///     child: Text('Popover content'),
///   ),
///   builder: (context, state, child) => Container(
///     color: state.isPressed ? Colors.blue : Colors.grey,
///     child: Text('Click me'),
///   ),
/// )
/// ```
///
/// See also:
/// - [NakedMenu], for dropdown menu functionality.
/// - [NakedTooltip], for hover-triggered lightweight hints.
/// - [NakedDialog], for modal dialog functionality.
class NakedPopover extends StatefulWidget {
  const NakedPopover({
    super.key,
    this.child,
    this.builder,
    required this.popoverBuilder,
    this.positioning = const OverlayPositionConfig(),
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.openOnTap = true,
    this.triggerFocusNode,
    this.onOpen,
    this.onClose,
    this.onOpenRequested,
    this.onCloseRequested,
    this.controller,
    this.semanticLabel,
    this.excludeSemantics = false,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// The static trigger widget.
  final Widget? child;

  /// Builds the trigger surface.
  final ValueWidgetBuilder<NakedPopoverState>? builder;

  /// The builder for popover content.
  final RawMenuAnchorOverlayBuilder popoverBuilder;

  /// Positioning configuration for the overlay.
  final OverlayPositionConfig positioning;

  /// Whether to consume taps outside the overlay.
  final bool consumeOutsideTaps;

  /// Whether to use the root overlay.
  final bool useRootOverlay;

  /// Whether tapping the trigger opens the popover.
  final bool openOnTap;

  /// Focus node for the trigger widget.
  final FocusNode? triggerFocusNode;

  /// Called when the popover opens.
  final VoidCallback? onOpen;

  /// Called when the popover closes.
  final VoidCallback? onClose;

  final MenuController? controller;

  /// Optional semantics label for the trigger.
  final String? semanticLabel;

  /// Whether to hide the popover trigger subtree from accessibility.
  final bool excludeSemantics;

  /// Called when a request is made to open the popover.
  ///
  /// This callback allows you to customize the opening behavior, such as
  /// adding animations or delays. Call `showOverlay` to actually show the popover.
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  /// Called when a request is made to close the popover.
  ///
  /// This callback allows you to customize the closing behavior, such as
  /// adding animations or delays. Call `hideOverlay` to actually hide the popover.
  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  @override
  State<NakedPopover> createState() => _NakedPopoverState();
}

class _NakedPopoverState extends State<NakedPopover> {
  // ignore: dispose-fields
  final _internalMenuController = MenuController();

  // Internal node used when the child does not already provide a Focus.
  final _internalTriggerNode = FocusNode(
    debugLabel: 'NakedPopover trigger (internal)',
  );

  MenuController get _menuController =>
      widget.controller ?? _internalMenuController;

  void _toggle() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
  }

  void _handleOpen() {
    if (mounted) setState(() {});
    widget.onOpen?.call();
  }

  void _handleClose() {
    if (mounted) setState(() {});
    widget.onClose?.call();
  }

  /// If the child is a Focus widget, extract its node so we can return focus to it.
  FocusNode? _extractChildFocusNode() {
    final c = widget.child;
    if (c is Focus) return c.focusNode;

    return null;
  }

  Widget _buildTrigger(FocusNode returnNode, FocusNode? childFocusNode) {
    if (widget.openOnTap) {
      return NakedButton(
        onPressed: _toggle,
        focusNode: identical(returnNode, childFocusNode) ? null : returnNode,
        semanticLabel: widget.semanticLabel,
        child: widget.child,
        builder: (context, buttonState, child) {
          return NakedStateScopeBuilder(
            value: NakedPopoverState(
              states: buttonState.states,
              isOpen: _menuController.isOpen,
            ),
            child: child,
            builder: widget.builder,
          );
        },
      );
    }

    final child = NakedStateScopeBuilder(
      value: NakedPopoverState(
        states: const <WidgetState>{},
        isOpen: _menuController.isOpen,
      ),
      child: widget.child,
      builder: widget.builder,
    );

    return identical(returnNode, childFocusNode)
        ? child
        : Focus(focusNode: returnNode, child: child);
  }

  @override
  void dispose() {
    _internalTriggerNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final childFocusNode = _extractChildFocusNode();
    final returnNode =
        widget.triggerFocusNode ?? childFocusNode ?? _internalTriggerNode;

    final result = AnchoredOverlayShell(
      controller: _menuController,
      triggerFocusNode: returnNode,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      onOpen: _handleOpen,
      onClose: _handleClose,
      onOpenRequested: widget.onOpenRequested ?? (_, show) => show(),
      onCloseRequested: widget.onCloseRequested ?? (hide) => hide(),
      useRootOverlay: widget.useRootOverlay,
      closeOnClickOutside: true,
      positioning: widget.positioning,
      overlayBuilder: (context, info) {
        return widget.popoverBuilder(context, info);
      },
      child: _buildTrigger(returnNode, childFocusNode),
    );

    return widget.excludeSemantics ? ExcludeSemantics(child: result) : result;
  }
}
