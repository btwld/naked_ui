import 'package:flutter/widgets.dart';

import 'base/overlay_base.dart';
import 'naked_button.dart';
import 'utilities/anchored_overlay_shell.dart';
import 'utilities/positioning.dart';
import 'utilities/widget_state_snapshot.dart';

/// State snapshot provided to [NakedMenu.triggerBuilder].
class NakedMenuState<T> extends NakedWidgetStateSnapshot {
  /// Whether the overlay is currently open.
  final bool isOpen;

  /// The value currently marked as selected, if any.
  final T? selectedValue;

  NakedMenuState({
    required super.states,
    required this.isOpen,
    required this.selectedValue,
  });

  bool get hasSelection => selectedValue != null;
}

/// State snapshot provided to [NakedMenuItem] builders.
class NakedMenuItemState<T> extends NakedWidgetStateSnapshot {
  /// The menu item's value.
  final T value;

  /// The parent menu's selected value.
  final T? selectedValue;

  NakedMenuItemState({
    required super.states,
    required this.value,
    required this.selectedValue,
  });

  /// Whether this item matches the selected value.
  bool get isCurrentSelection =>
      selectedValue != null && value == selectedValue;
}

/// Internal scope provided by [NakedMenu] to its overlay subtree.
class _NakedMenuScope<T> extends OverlayScope<T> {
  const _NakedMenuScope({
    required this.onSelected,
    required this.controller,
    required super.child,
    this.selectedValue,
    super.key,
  });

  /// Returns the [_NakedMenuScope] that most tightly encloses the given [context].
  ///
  /// Returns null if no [NakedMenu] ancestor is found.
  static _NakedMenuScope<T>? maybeOf<T>(BuildContext context) {
    return OverlayScope.maybeOf(context);
  }

  /// Returns the [_NakedMenuScope] that most tightly encloses the given [context].
  ///
  /// If no [NakedMenu] ancestor is found, this method throws a [FlutterError].
  static _NakedMenuScope<T> of<T>(BuildContext context) {
    return OverlayScope.of(
      context,
      scopeConsumer: NakedMenuItem,
      scopeOwner: NakedMenu,
    );
  }

  final ValueChanged<T>? onSelected;
  final MenuController controller;
  final T? selectedValue; // reserved for optional "checked" semantics

  @override
  bool updateShouldNotify(covariant _NakedMenuScope<T> oldWidget) {
    return onSelected != oldWidget.onSelected ||
        controller != oldWidget.controller ||
        selectedValue != oldWidget.selectedValue;
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

  /// Whether the menu will be closed when this item is activated.
  ///
  /// Defaults to true. Set to false to keep the menu open after this
  /// item is selected, which is useful for toggle actions or when
  /// the menu contains interactive content.
  final bool closeOnActivate;

  /// Handles the activation of this menu item.
  ///
  /// Gracefully handles missing scope using null-safe operators.
  /// This allows NakedMenuItem to function as a basic button
  /// even when not used within a NakedMenu context, following
  /// Material's MenuItemButton pattern of graceful degradation.
  void _handleActivation(_NakedMenuScope<T>? menu) {
    menu?.onSelected?.call(value);
    if (closeOnActivate) menu?.controller.close();
  }

  /// Computes additional widget states based on menu scope.
  ///
  /// Reserve optional support for "checked"/selected semantics when provided by scope.
  /// Use null-safe access since scope may not be available in all contexts.
  Set<WidgetState>? _computeAdditionalStates(_NakedMenuScope<T>? menu) {
    if (menu?.selectedValue != null && menu!.selectedValue == value) {
      return {WidgetState.selected};
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Use maybeOf instead of of to handle InheritedWidget timing gracefully.
    // This follows Material's MenuItemButton pattern where scope may not be
    // available during the same build phase when it's being created.
    // The scope is created in overlayBuilder and may not be fully established
    // in the widget tree when NakedMenuItem builds in the same cycle.
    final menu = _NakedMenuScope.maybeOf<T>(context);

    final VoidCallback? onPressed = enabled
        ? () => _handleActivation(menu)
        : null;
    final additionalStates = _computeAdditionalStates(menu);

    return buildButton(
      onPressed: onPressed,
      effectiveEnabled: enabled,
      additionalStates: additionalStates,
      mapStates: (states) => NakedMenuItemState<T>(
        states: states,
        value: value,
        // Use null-safe access for selectedValue since scope may be null
        selectedValue: menu?.selectedValue,
      ),
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
/// NakedMenu<String>(
///   controller: MenuController(),
///   triggerBuilder: (context, state) => Text('Menu'),
///   overlayBuilder: (context, info) => Column(
///     children: [
///       NakedMenu.Item(value: 'copy', child: Text('Copy')),
///       NakedMenu.Item(value: 'paste', child: Text('Paste')),
///     ],
///   ),
///   onSelected: (value) => print('Action: $value'),
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
    this.selectedValue,
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

  /// Type alias for NakedMenuItem for cleaner API access
  static final Item = NakedMenuItem.new;

  /// Builds the trigger surface.
  final Widget Function(BuildContext context, NakedMenuState<T> state)
  triggerBuilder;

  /// Builds the overlay panel.
  final RawMenuAnchorOverlayBuilder overlayBuilder;

  /// Controller that manages show/hide of the underlying [RawMenuAnchor].
  final MenuController controller;

  /// Called when an item is selected.
  final ValueChanged<T>? onSelected;

  /// Optional selected value to mark items with [WidgetState.selected].
  final T? selectedValue;

  /// Lifecycle callbacks.
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// Called when the menu closes without selection.
  final VoidCallback? onCanceled;

  /// Open/close interceptors (e.g. for animations).
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  /// Whether taps outside the overlay should close the menu.
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

  void _toggle() =>
      _isOpen ? widget.controller.close() : widget.controller.open();

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
          selectedValue: widget.selectedValue,
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
              NakedMenuState(
                states: states,
                isOpen: _isOpen,
                selectedValue: widget.selectedValue,
              ),
            );
          },
        ),
      ),
    );
  }
}
