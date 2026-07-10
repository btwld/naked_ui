import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'naked_state_scope.dart';

/// Immutable view over a widget's state set with convenient helpers.
///
/// Use subclasses to expose component-specific metadata while retaining
/// access to the underlying [WidgetState] set for custom styling.
@immutable
abstract class NakedState {
  final Set<WidgetState> _states;
  final int _statesHashCode;

  /// Creates a [NakedState] snapshot from the given [states] set.
  ///
  /// The [states] parameter contains the widget states to track.
  NakedState({required Set<WidgetState> states})
    : _states = Set<WidgetState>.unmodifiable(states),
      _statesHashCode = Object.hashAllUnordered(states);

  /// Gets the state of type [T] from the nearest [NakedStateScope].
  ///
  /// Throws a [FlutterError] if no provider is found.
  ///
  /// ```dart
  /// final menuState = NakedState.of<NakedMenuState>(context);
  /// ```
  ///
  /// See also:
  /// - [maybeOf], which returns null instead of throwing
  /// - [NakedStateScope], for providing states to the widget tree
  static T of<T extends NakedState>(BuildContext context) {
    final T? state = maybeOf<T>(context);
    if (state == null) {
      throw FlutterError.fromParts([
        ErrorSummary(
          'NakedState.of<$T>() called with a context that does not contain a $T.',
        ),
        ErrorDescription('No NakedStateScope<$T> was found above this widget.'),
        ErrorHint(
          'Ensure that a NakedStateScope<$T> is above this widget in the tree.\n'
          'Example:\n'
          '  NakedStateScope<$T>(\n'
          '    value: $T(...),\n'
          '    child: YourWidget(),\n'
          '  )',
        ),
        context.describeElement('The context used was'),
      ]);
    }

    return state;
  }

  /// Gets the state of type [T] from the nearest [NakedStateScope].
  ///
  /// Returns null if no provider is found.
  ///
  /// ```dart
  /// final menuState = NakedState.maybeOf<NakedMenuState>(context);
  /// if (menuState != null) {
  ///   // Use the state
  /// }
  /// ```
  ///
  /// See also:
  /// - [of], which throws instead of returning null
  /// - [NakedStateScope], for providing states to the widget tree
  static T? maybeOf<T extends NakedState>(BuildContext context) {
    return NakedStateScope.maybeOf(context);
  }

  /// Gets the [WidgetStatesController] from the nearest [NakedStateScope].
  ///
  /// This method does not create a dependency, so the calling widget won't
  /// rebuild when the controller's value changes. Use this when you need
  /// the controller but want to manage subscriptions manually.
  ///
  /// Throws if no [NakedStateScope] with a controller is found.
  ///
  /// ```dart
  /// final controller = NakedState.controllerOf(context);
  /// ```
  ///
  /// See also:
  /// - [maybeControllerOf], which returns null instead of throwing
  /// - [NakedStateScope], for providing states and controllers
  static WidgetStatesController controllerOf(BuildContext context) {
    return NakedStateScope.controllerOf(context);
  }

  /// Gets the controller for the nearest [NakedStateScope] containing [T].
  ///
  /// This is the safe lookup for nested component builders because unrelated
  /// state scopes are skipped. It does not create a dependency.
  static WidgetStatesController controllerOfType<T extends NakedState>(
    BuildContext context,
  ) {
    return NakedStateScope.controllerOfType<T>(context);
  }

  /// Gets the [WidgetStatesController] from the nearest [NakedStateScope].
  ///
  /// Returns null if no scope with a controller is found.
  ///
  /// This method does not create a dependency, so the calling widget won't
  /// rebuild when the controller's value changes.
  ///
  /// ```dart
  /// final controller = NakedState.maybeControllerOf(context);
  /// if (controller != null) {
  ///   // Use the controller
  /// }
  /// ```
  ///
  /// See also:
  /// - [controllerOf], which throws instead of returning null
  /// - [NakedStateScope], for providing states and controllers
  static WidgetStatesController? maybeControllerOf(BuildContext context) {
    return NakedStateScope.maybeControllerOf(context);
  }

  /// Gets the controller for the nearest [NakedStateScope] containing [T].
  ///
  /// Returns null when no matching scope exists and does not create a
  /// dependency.
  static WidgetStatesController? maybeControllerOfType<T extends NakedState>(
    BuildContext context,
  ) {
    return NakedStateScope.maybeControllerOfType<T>(context);
  }

  /// Raw set of [WidgetState]s reported by the underlying control.
  ///
  /// Remains useful for custom logic not covered by convenience getters.
  Set<WidgetState> get states => _states;

  /// Whether this snapshot and [other] contain the same widget states.
  @protected
  bool statesEqual(NakedState other) => setEquals(other._states, _states);

  /// An order-independent hash of [states].
  @protected
  int get statesHashCode => _statesHashCode;

  /// Whether the widget is hovered.
  bool get isHovered => _states.contains(WidgetState.hovered);

  /// Whether the widget has focus.
  bool get isFocused => _states.contains(WidgetState.focused);

  /// Whether the widget is pressed.
  bool get isPressed => _states.contains(WidgetState.pressed);

  /// Whether the widget is being dragged.
  bool get isDragged => _states.contains(WidgetState.dragged);

  /// Whether the widget is selected.
  bool get isSelected => _states.contains(WidgetState.selected);

  /// Whether the widget is disabled.
  bool get isDisabled => _states.contains(WidgetState.disabled);

  /// Whether the widget is in an error state.
  bool get isError => _states.contains(WidgetState.error);

  /// Whether content has scrolled underneath the widget.
  bool get isScrolledUnder => _states.contains(WidgetState.scrolledUnder);

  /// Whether the widget is not disabled.
  bool get isEnabled => !isDisabled;

  /// Whether [states] contains every state in [requiredStates].
  bool matches(Set<WidgetState> requiredStates) {
    return _states.containsAll(requiredStates);
  }

  /// Resolves to the first matching branch in priority order.
  ///
  /// Checks widget states in priority order and returns the first
  /// matching value. If no states match, returns [orElse].
  ///
  /// Priority order: disabled → pressed → dragged → selected → hovered
  /// → focused → error → scrolledUnder → [orElse].
  T when<T>({
    T? selected,
    T? hovered,
    T? focused,
    T? pressed,
    T? disabled,
    T? dragged,
    T? error,
    T? scrolledUnder,
    required T orElse,
  }) {
    if (disabled != null && isDisabled) return disabled;
    if (pressed != null && isPressed) return pressed;
    if (dragged != null && isDragged) return dragged;
    if (selected != null && isSelected) return selected;
    if (hovered != null && isHovered) return hovered;
    if (focused != null && isFocused) return focused;
    if (error != null && isError) return error;
    if (scrolledUnder != null && isScrolledUnder) return scrolledUnder;

    return orElse;
  }

  /// Nullable variant of [when] that returns null when no branch matches.
  ///
  /// Like [when], but returns null if no states match.
  /// Useful when you want to check for specific states without a fallback.
  ///
  /// Returns the first matching state value, or null.
  T? whenOrNull<T>({
    T? selected,
    T? hovered,
    T? focused,
    T? pressed,
    T? disabled,
    T? dragged,
    T? error,
    T? scrolledUnder,
  }) {
    return when(
      selected: selected,
      hovered: hovered,
      focused: focused,
      pressed: pressed,
      disabled: disabled,
      dragged: dragged,
      error: error,
      scrolledUnder: scrolledUnder,
      orElse: null,
    );
  }
}
