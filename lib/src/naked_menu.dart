import 'package:flutter/widgets.dart';

import 'base/overlay_base.dart';
import 'naked_button.dart';
import 'utilities/anchored_overlay_shell.dart';
import 'utilities/positioning.dart';

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
class NakedMenuItem<T> extends OverlayItem<T> {
  const NakedMenuItem({
    super.key,
    required super.value,
    super.enabled = true,
    super.semanticLabel,
    super.child,
    super.builder,
  });

  @override
  Widget build(BuildContext context) {
    final menu = _NakedMenuScope.of<T>(context);

    Set<WidgetState>? additionalStates;
    // Reserve optional support for "checked"/selected semantics when provided by scope.
    if (menu.selectedValue != null && menu.selectedValue == value) {
      additionalStates = {WidgetState.selected};
    }

    return buildButton(
      onPressed: enabled
          ? () {
              menu.onSelected?.call(value);
              menu.controller.close();
            }
          : null,
      effectiveEnabled: enabled,
      additionalStates: additionalStates,
    );
  }
}

/// A headless menu that renders items in an overlay anchored to its trigger.
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
  final Widget Function(BuildContext context, Set<WidgetState> states)
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
            return widget.triggerBuilder(context, states);
          },
        ),
      ),
    );
  }
}
