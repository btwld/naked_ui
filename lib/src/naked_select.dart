import 'package:flutter/widgets.dart';

import 'base/overlay_base.dart';
import 'naked_button.dart';
import 'utilities/anchored_overlay_shell.dart';
import 'utilities/intents.dart';
import 'utilities/positioning.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedSelect.triggerBuilder].
class NakedSelectState<T> extends NakedState {
  /// Whether the overlay is currently open.
  final bool isOpen;

  /// Currently selected value, if any.
  final T? value;

  NakedSelectState({
    required super.states,
    required this.isOpen,
    required this.value,
  });

  /// Returns the nearest [NakedSelectState] of the requested type.
  static NakedSelectState<S> of<S>(BuildContext context) =>
      NakedState.of(context);

  /// Returns the nearest [NakedSelectState] if available.
  static NakedSelectState<S>? maybeOf<S>(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);

  /// Whether a selection exists.
  bool get hasValue => value != null;
}

/// Immutable view passed to [NakedSelectOption] builders.
class NakedSelectOptionState<T> extends NakedState {
  /// The option's value.
  final T value;

  NakedSelectOptionState({required super.states, required this.value});

  /// Returns the nearest [NakedSelectOptionState] of the requested type.
  static NakedSelectOptionState<S> of<S>(BuildContext context) =>
      NakedState.of(context);

  /// Returns the nearest [NakedSelectOptionState] if available.
  static NakedSelectOptionState<S>? maybeOf<S>(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);
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
class NakedSelectOption<T> extends OverlayItem<T, NakedSelectOptionState<T>> {
  const NakedSelectOption({
    super.key,
    required super.value,
    super.enabled = true,
    super.semanticLabel,
    super.child,
    super.builder,
  });

  /// Handles selection of this option.
  void _handleSelection(_NakedSelectScope<T> scope) {
    scope.onChanged?.call(value);
    if (scope.closeOnSelect) scope.controller.close();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _NakedSelectScope.of<T>(context);

    final isSelected = scope.value == value;
    final effectiveEnabled = enabled && scope.enabled;
    final onPressed = effectiveEnabled ? () => _handleSelection(scope) : null;

    return buildButton(
      onPressed: onPressed,
      effectiveEnabled: effectiveEnabled,
      isSelected: isSelected,
      mapStates: (states) {
        return NakedSelectOptionState<T>(states: states, value: value);
      },
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

  /// Type alias for [NakedSelectOption] for cleaner API access.
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

  /// Called when the select closes without a selection.
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
  // ignore: dispose-fields
  late final MenuController _menuController;
  T? _internalValue;

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();
    _internalValue = widget.value;
  }

  T? get _effectiveValue => widget.value ?? _internalValue;

  void _toggle() =>
      _menuController.isOpen ? _menuController.close() : _menuController.open();

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
    setState(() {
      _internalValue = value;
    });
    widget.onChanged?.call(value);
  }

  @override
  void didUpdateWidget(covariant NakedSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync internal value when widget value changes
    if (widget.value != oldWidget.value) {
      _internalValue = widget.value;
    }
  }

  bool get _isOpen => _menuController.isOpen;

  @override
  Widget build(BuildContext context) {
    final semanticsValue = _effectiveValue?.toString();

    return Shortcuts(
      shortcuts: NakedIntentActions.select.shortcuts,
      child: Actions(
        actions: NakedIntentActions.select.actions(
          onDismiss: () => _menuController.close(),
          onOpenOverlay: () => _menuController.open(),
        ),
        child: Semantics(
          container: true,
          enabled: widget.enabled,
          button: true,
          focusable: true,
          expanded: _isOpen,
          label: widget.semanticLabel,
          value: semanticsValue,
          onTap: widget.enabled ? _toggle : null,
          child: AnchoredOverlayShell(
            controller: _menuController,
            overlayBuilder: (context, info) {
              return _NakedSelectScope<T>(
                controller: _menuController,
                closeOnSelect: widget.closeOnSelect,
                enabled: widget.enabled,
                onChanged: _handleSelection,
                value: _effectiveValue,
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
              builder: (context, buttonState, _) {
                return widget.triggerBuilder(
                  context,
                  NakedSelectState(
                    states: buttonState.states,
                    isOpen: _isOpen,
                    value: _effectiveValue,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
