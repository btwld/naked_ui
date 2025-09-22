import 'package:flutter/widgets.dart';

import 'base/overlay_base.dart';
import 'naked_button.dart';
import 'utilities/anchored_overlay_shell.dart';
import 'utilities/positioning.dart';
import 'utilities/state.dart';

typedef NakedMenuController = MenuController;

/// Immutable view passed to [NakedMenu.triggerBuilder].
class NakedMenuState extends NakedState {
  /// Whether the overlay is currently open.
  final bool isOpen;

  NakedMenuState({required super.states, required this.isOpen});
}

/// Immutable view passed to [NakedMenuItem] builders.
class NakedMenuItemState<T> extends NakedState {
  /// The menu item's value.
  final T value;

  NakedMenuItemState({required super.states, required this.value});
}

/// Internal scope provided by [NakedMenu] to its overlay subtree.
class _NakedMenuScope<T> extends OverlayScope<T> {
  const _NakedMenuScope({
    required this.onSelected,
    required this.controller,
    required super.child,
    super.key,
  });

  /// Returns the [_NakedMenuScope] that most tightly encloses the given [context].
  ///
  /// Returns null if no [NakedMenu] ancestor is found.
  static _NakedMenuScope<T>? maybeOf<T>(BuildContext context) {
    return OverlayScope.maybeOf(context);
  }

  final ValueChanged<T>? onSelected;
  final MenuController controller;

  @override
  bool updateShouldNotify(covariant _NakedMenuScope<T> oldWidget) {
    return onSelected != oldWidget.onSelected ||
        controller != oldWidget.controller;
  }
}

/// Widget-based menu action that binds to the nearest [NakedMenu] scope.
///
/// This enables fully declarative composition inside [NakedMenu.overlayBuilder]
/// without relying on the data-driven [NakedMenuItem] list.
class NakedMenuItem<T> extends OverlayItem<T, NakedMenuItemState<T>> {
  const NakedMenuItem({
    super.key,
    required super.value,
    super.enabled = true,
    super.semanticLabel,
    super.child,
    super.builder,
    this.closeOnActivate = true,
  });

  /// Whether the menu closes when this item is activated.
  ///
  /// Defaults to true. Set to false to keep the menu open after this
  /// item is selected, which is useful for toggle actions or when
  /// the menu contains interactive content.
  final bool closeOnActivate;

  /// Handles activation of this menu item.
  ///
  /// Gracefully handles missing scope using null-safe operators.
  /// This allows NakedMenuItem to function as a basic button
  /// even when not used within a NakedMenu context, following
  /// Material's MenuItemButton pattern of graceful degradation.
  void _handleActivation(_NakedMenuScope<T>? menu) {
    menu?.onSelected?.call(value);
    if (closeOnActivate) menu?.controller.close();
  }

  @override
  Widget build(BuildContext context) {
    // Use maybeOf instead of of to handle InheritedWidget timing gracefully.
    // This follows Material's MenuItemButton pattern where scope may not be
    // available during the same build phase when it's being created.
    // The scope is created in overlayBuilder and may not be fully established
    // in the widget tree when NakedMenuItem builds in the same cycle.
    final scope = _NakedMenuScope.maybeOf<T>(context);

    final VoidCallback? onPressed = enabled
        ? () => _handleActivation(scope)
        : null;

    return buildButton(
      onPressed: onPressed,
      effectiveEnabled: enabled,

      mapStates: (states) =>
          NakedMenuItemState<T>(states: states, value: value),
    );
  }
}

/// A headless menu that renders items in an overlay anchored to its trigger.
///
/// ## Keyboard Navigation
///
/// The menu follows Flutter's standard keyboard navigation patterns:
///
/// ### Opening and Closing
/// - **Space/Enter on trigger**: Opens the overlay
/// - **Escape**: Closes the overlay and returns focus to trigger
/// - **Click outside**: Closes the overlay (if [closeOnClickOutside] is true)
///
/// ### Navigating Items
/// - **Arrow Up/Down**: Navigate between focusable items in the overlay
/// - **Enter/Space on item**: Activates the focused item
/// - **Tab**: Moves focus through items in traversal order
///
/// ### Focus Management
/// When the overlay opens, focus transfers to the overlay container but does NOT
/// automatically focus the first item. Users must use arrow keys to navigate to
/// items before activating them. This follows Flutter Material patterns where
/// explicit navigation is required.
///
/// The focus behavior ensures:
/// - Keyboard-only users can access all functionality
/// - Screen readers receive proper focus announcements
/// - Navigation is predictable and explicit
///
/// ### Example Usage
/// ```dart
/// final menuController = NakedMenuController<String>();
/// NakedMenu<String>(
///   controller: menuController,
///   triggerBuilder: (context, state) => Text('Menu'),
///   overlayBuilder: (context, info) => Column(
///     children: [
///       NakedMenu.Item(value: 'copy', child: Text('Copy')),
///       NakedMenu.Item(value: 'paste', child: Text('Paste')),
///     ],
///   ),
///   onSelected: (value) => menuController.select(value),
/// )
/// ```
///
/// See also:
/// - [NakedMenuItem], for individual actionable items
/// - [NakedSelect], for selection-based menus with similar keyboard behavior
class NakedMenu<T> extends StatefulWidget {
  const NakedMenu({
    super.key,
    required this.triggerBuilder,
    required this.overlayBuilder,
    required this.controller,
    this.onSelected,
    this.onOpen,
    this.onClose,
    this.onCanceled,
    this.onOpenRequested,
    this.onCloseRequested,
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.closeOnClickOutside = true,
    this.triggerFocusNode,
    this.positioning = const OverlayPositionConfig(),
  });

  /// Type alias for [NakedMenuItem] for cleaner API access.
  static final Item = NakedMenuItem.new;

  /// Builds the trigger surface.
  final Widget Function(BuildContext context, NakedMenuState state)
  triggerBuilder;

  /// Builds the overlay panel.
  final RawMenuAnchorOverlayBuilder overlayBuilder;

  /// Controls show/hide of the underlying [RawMenuAnchor] and manages selection state.
  final NakedMenuController controller;

  /// Called when an item is selected.
  ///
  /// Note: You can also use [controller.select] to update selection state directly.
  final ValueChanged<T>? onSelected;

  /// Lifecycle callbacks.
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// Called when the menu closes without a selection.
  final VoidCallback? onCanceled;

  /// Open/close interceptors (for example, to drive animations).
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  /// Whether taps outside the overlay close the menu.
  final bool closeOnClickOutside;

  /// Whether outside taps on the trigger are consumed.
  final bool consumeOutsideTaps;

  /// Whether to target the root overlay instead of the nearest ancestor.
  final bool useRootOverlay;

  /// Optional focus node for the trigger.
  final FocusNode? triggerFocusNode;

  /// Overlay positioning configuration.
  final OverlayPositionConfig positioning;

  @override
  State<NakedMenu<T>> createState() => _NakedMenuState<T>();
}

class _NakedMenuState<T> extends State<NakedMenu<T>>
    with OverlayStateMixin<NakedMenu<T>> {
  bool get _isOpen => widget.controller.isOpen;

  void _toggle() => widget.controller.isOpen
      ? widget.controller.close()
      : widget.controller.open();

  void _handleOpen() {
    handleOpen(widget.onOpen);
  }

  void _handleClose() {
    handleClose(
      onClose: widget.onClose,
      onCanceled: widget.onCanceled,
      triggerFocusNode: widget.triggerFocusNode,
    );
  }

  void _handleSelection(T value) {
    markSelectionMade();
    widget.onSelected?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return AnchoredOverlayShell(
      controller: widget.controller,
      overlayBuilder: (context, info) {
        return _NakedMenuScope<T>(
          onSelected: _handleSelection,
          controller: widget.controller,
          child: Builder(
            builder: (context) => widget.overlayBuilder(context, info),
          ),
        );
      },
      onOpen: _handleOpen,
      onClose: _handleClose,
      onOpenRequested: widget.onOpenRequested,
      onCloseRequested: widget.onCloseRequested,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      useRootOverlay: widget.useRootOverlay,
      closeOnClickOutside: widget.closeOnClickOutside,
      triggerFocusNode: widget.triggerFocusNode,
      offset: widget.positioning.offset,
      child: Semantics(
        toggled: _isOpen,
        child: NakedButton(
          onPressed: _toggle,
          focusNode: widget.triggerFocusNode,
          builder: (context, states, _) {
            return widget.triggerBuilder(
              context,
              NakedMenuState(states: states, isOpen: _isOpen),
            );
          },
        ),
      ),
    );
  }
}
