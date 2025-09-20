import 'dart:collection';

import 'package:flutter/widgets.dart';

/// Immutable view over a widget's state set with convenient helpers.
///
/// Use subclasses to expose component-specific metadata while retaining
/// access to the underlying [WidgetState] set for custom styling.
abstract class NakedWidgetState {
  final UnmodifiableSetView<WidgetState> _states;

  NakedWidgetState({required Set<WidgetState> states})
    : _states = UnmodifiableSetView(states);

  /// Raw set of [WidgetState]s reported by the underlying control.
  ///
  /// Remains useful for custom logic not covered by convenience getters.
  Set<WidgetState> get widgetStates => _states;

  bool get isHovered => _states.contains(WidgetState.hovered);
  bool get isFocused => _states.contains(WidgetState.focused);
  bool get isPressed => _states.contains(WidgetState.pressed);
  bool get isDragged => _states.contains(WidgetState.dragged);
  bool get isSelected => _states.contains(WidgetState.selected);
  bool get isDisabled => _states.contains(WidgetState.disabled);
  bool get isError => _states.contains(WidgetState.error);
  bool get isScrolledUnder => _states.contains(WidgetState.scrolledUnder);
  bool get isEnabled => !isDisabled;

  /// Whether *all* of the provided [states] are present.
  bool matchesAll(Iterable<WidgetState> states, {bool requireExact = false}) {
    final required = states.toSet();
    if (required.isEmpty) return true;
    if (!required.every(_states.contains)) return false;
    if (requireExact) return _states.length == required.length;

    return true;
  }

  /// Whether *any* of the provided [states] are present.
  bool matchesAny(Iterable<WidgetState> states) {
    for (final state in states) {
      if (_states.contains(state)) return true;
    }

    return false;
  }

  /// Resolves to the first matching branch in priority order.
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
    return maybeWhen<T>(
          selected: selected,
          hovered: hovered,
          focused: focused,
          pressed: pressed,
          disabled: disabled,
          dragged: dragged,
          error: error,
          scrolledUnder: scrolledUnder,
          orElse: orElse,
        ) ??
        orElse;
  }

  /// Nullable variant of [when] that returns null when no branch matches.
  T? maybeWhen<T>({
    T? selected,
    T? hovered,
    T? focused,
    T? pressed,
    T? disabled,
    T? dragged,
    T? error,
    T? scrolledUnder,
    T? orElse,
  }) {
    if (selected != null && isSelected) return selected;
    if (hovered != null && isHovered) return hovered;
    if (focused != null && isFocused) return focused;
    if (pressed != null && isPressed) return pressed;
    if (disabled != null && isDisabled) return disabled;
    if (dragged != null && isDragged) return dragged;
    if (error != null && isError) return error;
    if (scrolledUnder != null && isScrolledUnder) return scrolledUnder;

    return orElse;
  }
}

/// Builder signature that receives a typed view over widget states.
typedef NakedStateBuilder<S extends NakedWidgetState> =
    Widget Function(BuildContext context, S state, Widget? child);
