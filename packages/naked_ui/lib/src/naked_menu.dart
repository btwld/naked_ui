import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

import 'base/overlay_base.dart';
import 'mixins/naked_mixins.dart';
import 'naked_button.dart';
import 'utilities/anchored_overlay_shell.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/positioning.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedMenu.builder].
class NakedMenuState extends NakedState {
  /// Whether the overlay is currently open.
  final bool isOpen;

  /// Creates a menu state snapshot.
  NakedMenuState({required super.states, required this.isOpen});

  /// Returns the nearest [NakedMenuState] provided by [NakedStateScope].
  static NakedMenuState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedMenuState] if available.
  static NakedMenuState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOfType<NakedMenuState>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOfType<NakedMenuState>(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedMenuState &&
        statesEqual(other) &&
        other.isOpen == isOpen;
  }

  @override
  int get hashCode => Object.hash(statesHashCode, isOpen);
}

/// Immutable view passed to [NakedMenuItem] builders.
class NakedMenuItemState<T> extends NakedState {
  /// The menu item's value.
  final T value;

  /// Creates a menu-item state snapshot for [value].
  NakedMenuItemState({required super.states, required this.value});

  /// Returns the nearest [NakedMenuItemState] of the requested type.
  static NakedMenuItemState<S> of<S>(BuildContext context) =>
      NakedState.of(context);

  /// Returns the nearest [NakedMenuItemState] if available.
  static NakedMenuItemState<S>? maybeOf<S>(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOfType<NakedMenuItemState<dynamic>>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOfType<NakedMenuItemState<dynamic>>(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedMenuItemState<T> &&
        statesEqual(other) &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(statesHashCode, value);
}

/// Internal scope provided by [NakedMenu] to its overlay subtree.
class _NakedMenuScope<T> extends OverlayScope<T> {
  const _NakedMenuScope({
    required this.onSelected,
    required this.controller,
    required super.child,
    super.key,
  });

  /// Returns the [_NakedMenuScope] that encloses [context].
  ///
  /// Throws a [FlutterError] if no [NakedMenu] ancestor exists.
  static _NakedMenuScope<dynamic> of(BuildContext context) {
    return OverlayScope.of<_NakedMenuScope<dynamic>>(
      context,
      scopeConsumer: NakedMenuItem,
      scopeOwner: NakedMenu,
    );
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
  /// Creates an actionable item for a [NakedMenu] overlay.
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

  void _handleActivation(_NakedMenuScope<dynamic> menu) {
    menu.onSelected?.call(value);
    if (closeOnActivate) menu.controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _NakedMenuScope.of(context);

    final VoidCallback? onPressed = enabled
        ? () => _handleActivation(scope)
        : null;

    return buildButton(
      onPressed: onPressed,
      effectiveEnabled: enabled,
      semanticRole: SemanticsRole.menuItem,
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
/// final menuController = MenuController();
/// NakedMenu<String>(
///   controller: menuController,
///   builder: (context, state, child) => const Text('Menu'),
///   overlayBuilder: (context, info) => Column(
///     children: [
///       NakedMenuItem(value: 'copy', child: Text('Copy')),
///       NakedMenuItem(value: 'paste', child: Text('Paste')),
///     ],
///   ),
///   onSelected: (value) => handleMenuAction(value),
/// )
/// ```
///
/// See also:
/// - [NakedMenuItem], for individual actionable items
/// - `NakedSelect`, for selection-based menus with similar keyboard behavior
class NakedMenu<T> extends StatefulWidget {
  /// Creates a menu controlled by [controller].
  ///
  /// Either [child] or [builder] must be provided for the trigger.
  const NakedMenu({
    super.key,
    this.child,
    this.builder,
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
    this.semanticLabel,
    this.excludeSemantics = false,
  });

  /// Type alias for [NakedMenuItem] for cleaner API access.
  // Retains the established `NakedMenu.Item(...)` public API.
  // ignore: non_constant_identifier_names
  static final Item = NakedMenuItem.new;

  /// The static trigger widget.
  final Widget? child;

  /// Builds the trigger surface.
  final ValueWidgetBuilder<NakedMenuState>? builder;

  /// Builds the overlay panel.
  final RawMenuAnchorOverlayBuilder overlayBuilder;

  /// Controls show/hide of the underlying [RawMenuAnchor] and manages selection state.
  final MenuController controller;

  /// Called when an item is selected.
  ///
  /// Use [controller] to open or close the menu programmatically.
  final ValueChanged<T>? onSelected;

  /// Called when the menu opens.
  final VoidCallback? onOpen;

  /// Called when the menu closes.
  final VoidCallback? onClose;

  /// Called when the menu closes without a selection.
  final VoidCallback? onCanceled;

  /// Open/close interceptors (for example, to drive animations).
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  /// Intercepts close requests, for example to drive an exit animation.
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

  /// Semantic label for the menu trigger.
  final String? semanticLabel;

  /// Whether to omit the menu trigger semantics contributed by [NakedMenu].
  ///
  /// Semantics supplied by [child] or [builder] remain available. The overlay
  /// and its menu items keep their standard menu semantics.
  final bool excludeSemantics;

  @override
  State<NakedMenu<T>> createState() => _NakedMenuState<T>();
}

class _NakedMenuState<T> extends State<NakedMenu<T>>
    with OverlayStateMixin<NakedMenu<T>>, FocusNodeMixin<NakedMenu<T>> {
  @override
  FocusNode? get widgetProvidedNode => widget.triggerFocusNode;

  bool get _isOpen => widget.controller.isOpen;

  void _toggle() => widget.controller.isOpen
      ? widget.controller.close()
      : widget.controller.open();

  void _handleOpen() {
    handleOpen(widget.onOpen);
    if (mounted) setState(() {});
  }

  void _handleClose() {
    handleClose(
      onClose: widget.onClose,
      onCanceled: widget.onCanceled,
      triggerFocusNode: effectiveFocusNode,
    );
    if (mounted) setState(() {});
  }

  void _handleSelection(T value) {
    markSelectionMade();
    widget.onSelected?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final button = NakedButton(
      onPressed: _toggle,
      focusNode: effectiveFocusNode,
      semanticLabel: widget.semanticLabel,
      excludeSemantics: widget.excludeSemantics,
      builder: (context, buttonState, child) {
        final menuState = NakedMenuState(
          states: buttonState.states,
          isOpen: _isOpen,
        );

        final trigger = NakedStateScopeBuilder(
          value: menuState,
          builder: widget.builder,
          child: child,
        );

        return widget.semanticLabel == null || widget.excludeSemantics
            ? trigger
            : ExcludeSemantics(child: trigger);
      },
      child: widget.child,
    );

    final menuChild = widget.excludeSemantics
        ? button
        : MergeSemantics(
            child: Semantics(expanded: _isOpen, child: button),
          );

    return AnchoredOverlayShell(
      controller: widget.controller,
      overlayBuilder: (context, info) {
        return Semantics(
          role: SemanticsRole.menu,
          explicitChildNodes: true,
          child: _NakedMenuScope<T>(
            onSelected: _handleSelection,
            controller: widget.controller,
            child: Builder(
              builder: (context) => widget.overlayBuilder(context, info),
            ),
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
      triggerFocusNode: effectiveFocusNode,
      positioning: widget.positioning,
      child: menuChild,
    );
  }
}
