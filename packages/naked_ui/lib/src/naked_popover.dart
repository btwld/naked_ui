import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'naked_button.dart';
import 'utilities/anchored_overlay_shell.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/positioning.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedPopover.builder].
class NakedPopoverState extends NakedState {
  /// Whether the overlay is currently open.
  final bool isOpen;

  /// Creates a popover state snapshot.
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
      NakedState.controllerOfType<NakedPopoverState>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOfType<NakedPopoverState>(context);
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
/// - `NakedMenu`, for dropdown menu functionality.
/// - `NakedTooltip`, for hover-triggered lightweight hints.
/// - `NakedDialog`, for modal dialog functionality.
class NakedPopover extends StatefulWidget {
  /// Creates a headless popover.
  ///
  /// Either [child] or [builder] must be provided for the trigger.
  const NakedPopover({
    super.key,
    this.child,
    this.builder,
    required this.popoverBuilder,
    this.positioning = const OverlayPositionConfig(),
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.closeOnClickOutside = true,
    this.openOnTap = true,
    this.enabled = true,
    this.mouseCursor = SystemMouseCursors.click,
    this.triggerFocusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
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

  /// Whether tapping outside the popover requests that it close.
  final bool closeOnClickOutside;

  /// Whether tapping the trigger opens the popover.
  final bool openOnTap;

  /// Whether the trigger is interactive.
  final bool enabled;

  /// The mouse cursor shown over an interactive trigger.
  final MouseCursor mouseCursor;

  /// Focus node for the trigger widget.
  final FocusNode? triggerFocusNode;

  /// Whether the trigger should request focus when first built.
  final bool autofocus;

  /// Called when the trigger focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when the trigger hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when the trigger press state changes.
  final ValueChanged<bool>? onPressChange;

  /// Called when the popover opens.
  final VoidCallback? onOpen;

  /// Called when the popover closes.
  final VoidCallback? onClose;

  /// Controls the popover programmatically.
  final MenuController? controller;

  /// Replaces the trigger's derived accessible name when non-null.
  final String? semanticLabel;

  /// Whether NakedPopover should omit its trigger semantics.
  ///
  /// Descendant semantics are preserved.
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

class _NakedPopoverState extends State<NakedPopover>
    with FocusNodeMixin<NakedPopover> {
  late MenuController _menuController;

  @override
  FocusNode? get widgetProvidedNode => widget.triggerFocusNode;

  FocusNode? get _directChildFocusNode {
    final child = widget.child;
    return child is Focus ? child.focusNode : null;
  }

  bool get _triggerEnabled => widget.enabled && widget.openOnTap;

  @override
  void initState() {
    super.initState();
    _menuController = widget.controller ?? MenuController();
  }

  void _toggle() {
    if (!_triggerEnabled) return;

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

  @override
  void didUpdateWidget(covariant NakedPopover oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(widget.controller, oldWidget.controller)) {
      final nextController = widget.controller ?? MenuController();
      if (!identical(nextController, _menuController)) {
        if (_menuController.isOpen) _menuController.close();
        _menuController = nextController;
      }
    }

    if (oldWidget.enabled && !widget.enabled && _menuController.isOpen) {
      _menuController.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final button = NakedButton(
      onPressed: _triggerEnabled ? _toggle : null,
      enabled: _triggerEnabled,
      mouseCursor: widget.mouseCursor,
      focusNode: effectiveFocusNode,
      autofocus: widget.autofocus,
      onFocusChange: widget.onFocusChange,
      onHoverChange: widget.onHoverChange,
      onPressChange: widget.onPressChange,
      semanticLabel: widget.semanticLabel,
      excludeSemantics: widget.excludeSemantics || !widget.openOnTap,
      builder: (context, buttonState, child) {
        final popoverState = NakedPopoverState(
          states: buttonState.states,
          isOpen: _menuController.isOpen,
        );

        return NakedStateScopeBuilder(
          value: popoverState,
          builder: widget.builder,
          child: child,
        );
      },
      child: widget.child,
    );

    final trigger = widget.excludeSemantics || !widget.openOnTap
        ? button
        : MergeSemantics(
            child: Semantics(expanded: _menuController.isOpen, child: button),
          );

    return AnchoredOverlayShell(
      controller: _menuController,
      overlayBuilder: widget.popoverBuilder,
      triggerFocusNode:
          widget.triggerFocusNode ??
          _directChildFocusNode ??
          effectiveFocusNode,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      onOpen: _handleOpen,
      onClose: _handleClose,
      onOpenRequested: widget.onOpenRequested,
      onCloseRequested: widget.onCloseRequested,
      useRootOverlay: widget.useRootOverlay,
      closeOnClickOutside: widget.closeOnClickOutside,
      positioning: widget.positioning,
      child: trigger,
    );
  }
}
