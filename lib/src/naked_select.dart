import 'package:flutter/widgets.dart';

import 'base/overlay_base.dart';
import 'naked_button.dart';
import 'utilities/anchored_overlay_shell.dart';
import 'utilities/positioning.dart';

/// Internal scope provided by [NakedSelect] to its overlay subtree.
class _NakedSelectScope<T> extends OverlayScope<T> {
  const _NakedSelectScope({
    super.key,
    required super.child,
    required this.controller,
    required this.closeOnSelect,
    required this.enabled,
    this.onChanged,
    this.value,
  });

  /// Returns the [_NakedSelectScope] that most tightly encloses the given [context].
  ///
  /// If no [NakedSelect] ancestor is found, this method throws a [FlutterError].
  static _NakedSelectScope<T> of<T>(BuildContext context) {
    return OverlayScope.of(
      context,
      scopeConsumer: NakedSelectOption,
      scopeOwner: NakedSelect,
    );
  }

  final MenuController controller;
  final bool closeOnSelect;
  final bool enabled;
  final ValueChanged<T?>? onChanged;

  final T? value;

  @override
  bool updateShouldNotify(covariant _NakedSelectScope<T> oldWidget) {
    return controller != oldWidget.controller ||
        closeOnSelect != oldWidget.closeOnSelect ||
        enabled != oldWidget.enabled ||
        onChanged != oldWidget.onChanged ||
        value != oldWidget.value;
  }
}

/// Widget-based select option that binds to the nearest [NakedSelect] scope.
///
/// This enables fully declarative composition inside [NakedSelect.overlayBuilder]
/// without relying on the data-driven approach.
class NakedSelectOption<T> extends OverlayItem<T> {
  const NakedSelectOption({
    super.key,
    required super.value,
    super.enabled = true,
    super.semanticLabel,
    super.child,
    super.builder,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _NakedSelectScope.of<T>(context);

    final isSelected = scope.value == value;
    final effectiveEnabled = enabled && scope.enabled;
    final VoidCallback? onPressed = effectiveEnabled
        ? () {
            scope.onChanged?.call(value);
            if (scope.closeOnSelect) scope.controller.close();
          }
        : null;

    Set<WidgetState>? additionalStates;
    if (isSelected) {
      additionalStates = {WidgetState.selected};
    }

    return buildButton(
      onPressed: onPressed,
      effectiveEnabled: effectiveEnabled,
      additionalStates: additionalStates,
    );
  }
}

/// Headless select/dropdown that renders items in an overlay anchored to a trigger.
class NakedSelect<T> extends StatefulWidget {
  const NakedSelect({
    super.key,
    required this.triggerBuilder,
    required this.overlayBuilder,
    this.value,
    this.onChanged,
    this.closeOnSelect = true,
    this.closeOnClickOutside = true,
    this.enabled = true,
    this.triggerFocusNode,
    this.semanticLabel,
    this.positioning = const OverlayPositionConfig(
      alignment: Alignment.bottomLeft,
      fallbackAlignment: Alignment.topLeft,
    ),
    this.onOpen,
    this.onClose,
    this.onCanceled,
    this.onOpenRequested,
    this.onCloseRequested,
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
  });

  /// Type alias for NakedSelectOption for cleaner API access
  static final Option = NakedSelectOption.new;

  /// Builds the trigger surface.
  final Widget Function(BuildContext context, Set<WidgetState> states)
  triggerBuilder;

  /// Builds the overlay panel.
  final RawMenuAnchorOverlayBuilder overlayBuilder;

  /// Single selection value.
  final T? value;

  /// Callback for single selection changes.
  final ValueChanged<T?>? onChanged;

  /// Whether selecting an item closes the menu.
  final bool closeOnSelect;

  /// Whether tapping outside closes the menu.
  final bool closeOnClickOutside;

  /// Whether the select is interactive.
  final bool enabled;

  /// Focus node for the trigger.
  final FocusNode? triggerFocusNode;

  /// Optional semantics label for the trigger.
  final String? semanticLabel;

  /// Overlay positioning configuration.
  final OverlayPositionConfig positioning;

  /// Lifecycle callbacks.
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// Called when the select closes without selection.
  final VoidCallback? onCanceled;

  /// Open/close interceptors.
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;
  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  /// Whether outside taps on the trigger are consumed.
  final bool consumeOutsideTaps;

  /// Whether to target the root overlay instead of the nearest ancestor.
  final bool useRootOverlay;

  @override
  State<NakedSelect<T>> createState() => _NakedSelectState<T>();
}

class _NakedSelectState<T> extends State<NakedSelect<T>>
    with OverlayStateMixin<NakedSelect<T>> {
  final _controller = MenuController();

  bool get _isOpen => _controller.isOpen;

  void _toggle() => _isOpen ? _controller.close() : _controller.open();

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

  void _handleSelection(T? value) {
    markSelectionMade();
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final String? semanticsValue = widget.value?.toString();

    return Semantics(
      container: true,
      enabled: widget.enabled,
      button: true,
      focusable: true,
      expanded: _isOpen,
      label: widget.semanticLabel,
      value: semanticsValue,
      onTap: widget.enabled ? _toggle : null,
      child: AnchoredOverlayShell(
        controller: _controller,
        overlayBuilder: (context, info) {
          return _NakedSelectScope<T>(
            controller: _controller,
            closeOnSelect: widget.closeOnSelect,
            enabled: widget.enabled,
            onChanged: _handleSelection,
            value: widget.value,
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
        child: NakedButton(
          onPressed: widget.enabled ? _toggle : null,
          enabled: widget.enabled,
          focusNode: widget.triggerFocusNode,
          builder: (context, states, _) {
            return widget.triggerBuilder(context, states);
          },
        ),
      ),
    );
  }
}
