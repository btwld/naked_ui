import 'package:flutter/widgets.dart';

import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/positioning.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedPopover.builder].
class NakedPopoverState extends NakedState {
  /// Whether the overlay is currently open.
  final bool isOpen;

  NakedPopoverState({required super.states, required this.isOpen});

  /// Returns the nearest [NakedPopoverState] provided by [NakedStateScope].
  static NakedPopoverState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedPopoverState] if available.
  static NakedPopoverState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);
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
  late final _menuController = widget.controller ?? MenuController();
  late final _statesController = WidgetStatesController();

  // Internal node used when the child does not already provide a Focus.
  final _internalTriggerNode = FocusNode(
    debugLabel: 'NakedPopover trigger (internal)',
  );

  void _toggle() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
  }

  void _handleOpen() {
    widget.onOpen?.call();
  }

  void _handleClose() {
    widget.onClose?.call();
  }

  /// If the child is a Focus widget, extract its node so we can return focus to it.
  FocusNode? _extractChildFocusNode() {
    final c = widget.child;
    if (c is Focus) return c.focusNode;

    return null;
  }

  Widget _buildTrigger(BuildContext context, FocusNode returnNode) {
    final popoverState = NakedPopoverState(
      states: _statesController.value,
      isOpen: _menuController.isOpen,
    );

    final content = widget.builder != null
        ? widget.builder!(context, popoverState, widget.child)
        : (widget.child ?? const SizedBox.shrink());

    final child = NakedStateScope(value: popoverState, child: content);

    // Case A: We own the focus node (no Focus provided by the child).
    if (identical(returnNode, _internalTriggerNode)) {
      if (!widget.openOnTap) {
        return Focus(focusNode: _internalTriggerNode, child: child);
      }

      return NakedFocusableDetector(
        focusNode: _internalTriggerNode,
        shortcuts: NakedIntentActions.button.shortcuts,
        actions: NakedIntentActions.button.actions(onPressed: () => _toggle()),
        child: GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
      );
    }

    // Case B: Child already provides a Focus node; don't add another focus owner.
    // Keep behavior headless: tap toggles when enabled.
    return GestureDetector(
      onTap: widget.openOnTap ? _toggle : null,
      behavior: HitTestBehavior.opaque,
      child: child, // retains the caller's Focus node
    );
  }

  @override
  void dispose() {
    _statesController.dispose();
    _internalTriggerNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final returnNode =
        widget.triggerFocusNode ??
        _extractChildFocusNode() ??
        _internalTriggerNode;

    return RawMenuAnchor(
      childFocusNode: returnNode,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      onOpen: _handleOpen,
      onClose: _handleClose,
      onOpenRequested: widget.onOpenRequested ?? (_, show) => show(),
      onCloseRequested: widget.onCloseRequested ?? (hide) => hide(),
      useRootOverlay: widget.useRootOverlay,
      controller: _menuController,
      overlayBuilder: (context, info) {
        // Center horizontally on the trigger; place the popover's top at the
        // trigger's bottom. This avoids needing the child's size by using a
        // FractionalTranslation of -0.5 on X to center the child around the
        // computed anchor X coordinate.
        final anchor = info.anchorRect;
        final left = anchor.center.dx + widget.positioning.offset.dx;
        final top = anchor.bottom + widget.positioning.offset.dy;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: TapRegion(
                onTapOutside: (event) => _menuController.close(),
                groupId: info.tapRegionGroupId,
                child: FocusTraversalGroup(
                  child: Shortcuts(
                    shortcuts: NakedIntentActions.menu.shortcuts,
                    child: Actions(
                      actions: NakedIntentActions.menu.actions(
                        onDismiss: () => _menuController.close(),
                        onNextFocus: () => FocusScope.of(context).nextFocus(),
                        onPreviousFocus: () =>
                            FocusScope.of(context).previousFocus(),
                      ),
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0.0),
                        child: widget.popoverBuilder(context, info),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },

      child: _buildTrigger(context, returnNode),
    );
  }
}
