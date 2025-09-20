import 'package:flutter/widgets.dart';

import 'base/overlay_base.dart';
import 'naked_button.dart';
import 'utilities/anchored_overlay_shell.dart';
import 'utilities/positioning.dart';
import 'utilities/widget_state_snapshot.dart';

/// State snapshot provided to [NakedSelect.triggerBuilder].
class NakedSelectState<T> extends NakedWidgetStateSnapshot {
  /// Whether the overlay is currently open.
  final bool isOpen;

  /// Currently selected value, if any.
  final T? value;

  NakedSelectState({
    required super.states,
    required this.isOpen,
    required this.value,
  });

  /// Convenience flag to check if a selection exists.
  bool get hasValue => value != null;
}

/// State snapshot provided to [NakedSelectOption] builders.
class NakedSelectItemState<T> extends NakedWidgetStateSnapshot {
  /// The option's value.
  final T value;

  /// The currently selected value from the surrounding select.
  final T? selectedValue;

  NakedSelectItemState({
    required super.states,
    required this.value,
    required this.selectedValue,
  });

  /// Whether this option matches the current selection.
  bool get isCurrentSelection =>
      selectedValue != null && value == selectedValue;
}

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
class NakedSelectOption<T> extends OverlayItem<T, NakedSelectItemState<T>> {
  const NakedSelectOption({
    super.key,
    required super.value,
    super.enabled = true,
    super.semanticLabel,
    super.child,
    super.builder,
  });

  /// Handles the selection of this option.
  void _handleSelection(_NakedSelectScope<T> scope) {
    scope.onChanged?.call(value);
    if (scope.closeOnSelect) scope.controller.close();
  }

  /// Computes additional widget states based on selection status.
  Set<WidgetState>? _computeAdditionalStates(bool isSelected) {
    return isSelected ? {WidgetState.selected} : null;
  }

  @override
  Widget build(BuildContext context) {
    final scope = _NakedSelectScope.of<T>(context);

    final isSelected = scope.value == value;
    final effectiveEnabled = enabled && scope.enabled;
    final VoidCallback? onPressed = effectiveEnabled
        ? () => _handleSelection(scope)
        : null;
    final additionalStates = _computeAdditionalStates(isSelected);

    return buildButton(
      onPressed: onPressed,
      effectiveEnabled: effectiveEnabled,
      additionalStates: additionalStates,
      mapStates: (states) => NakedSelectItemState<T>(
        states: states,
        value: value,
        selectedValue: scope.value,
      ),
    );
  }
}

/// Headless select/dropdown that renders items in an overlay anchored to a trigger.
///
/// ## Keyboard Navigation
///
/// The select follows Flutter's standard keyboard navigation patterns:
///
/// ### Opening and Closing
/// - **Space/Enter on trigger**: Opens the overlay
/// - **Escape**: Closes the overlay and returns focus to trigger
/// - **Click outside**: Closes the overlay (if [closeOnClickOutside] is true)
///
/// ### Navigating Items
/// - **Arrow Up/Down**: Navigate between focusable items in the overlay
/// - **Enter/Space on item**: Selects the focused item
/// - **Tab**: Moves focus through items in traversal order
///
/// ### Focus Management
/// When the overlay opens, focus transfers to the overlay container but does NOT
/// automatically focus the first item. Users must use arrow keys to navigate to
/// items before selecting them. This follows Flutter Material patterns where
/// explicit navigation is required.
///
/// The focus behavior ensures:
/// - Keyboard-only users can access all functionality
/// - Screen readers receive proper focus announcements
/// - Navigation is predictable and explicit
///
/// ### Example Usage
/// ```dart
/// NakedSelect<String>(
///   triggerBuilder: (context, state) => Text('Select: ${state.value ?? 'None'}'),
///   overlayBuilder: (context, info) => Column(
///     children: [
///       NakedSelect.Option(value: 'apple', child: Text('Apple')),
///       NakedSelect.Option(value: 'banana', child: Text('Banana')),
///     ],
///   ),
///   onChanged: (value) => print('Selected: $value'),
/// )
/// ```
///
/// See also:
/// - [NakedSelectOption], for individual selectable items
/// - [NakedMenu], for action-based menus with similar keyboard behavior
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
  final Widget Function(BuildContext context, NakedSelectState<T> state)
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
            return widget.triggerBuilder(
              context,
              NakedSelectState(
                states: states,
                isOpen: _isOpen,
                value: widget.value,
              ),
            );
          },
        ),
      ),
    );
  }
}
