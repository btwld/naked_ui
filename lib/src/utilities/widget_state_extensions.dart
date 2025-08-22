import 'package:flutter/widgets.dart';

/// Extension methods for convenient access to widget state properties.
///
/// Provides readable getters and helper methods for working with
/// [Set<WidgetState>] to simplify state checking in widget builders.
///
/// Example usage:
/// ```dart
/// builder: (context, states, child) {
///   if (states.isPressed) {
///     return ColoredBox(color: Colors.blue, child: child);
///   }
///   if (states.isHovered) {
///     return ColoredBox(color: Colors.grey, child: child);
///   }
///   return child;
/// }
/// ```
extension WidgetStateExtensions on Set<WidgetState> {
  /// Whether the widget is currently being hovered over by a mouse cursor.
  bool get isHovered => contains(WidgetState.hovered);

  /// Whether the widget currently has keyboard focus.
  bool get isFocused => contains(WidgetState.focused);

  /// Whether the widget is currently being pressed.
  bool get isPressed => contains(WidgetState.pressed);

  /// Whether the widget is currently being dragged.
  bool get isDragged => contains(WidgetState.dragged);

  /// Whether the widget is currently selected.
  bool get isSelected => contains(WidgetState.selected);

  /// Whether the widget is disabled and cannot be interacted with.
  bool get isDisabled => contains(WidgetState.disabled);

  /// Whether the widget is in an error state.
  bool get isError => contains(WidgetState.error);

  /// Whether the widget is scrolled under another widget (e.g., behind an app bar).
  bool get isScrolledUnder => contains(WidgetState.scrolledUnder);

  // Inverse getters for convenience

  /// Whether the widget is enabled (not disabled).
  bool get isEnabled => !isDisabled;

  /// Whether the widget is not being hovered over.
  bool get isNotHovered => !isHovered;

  /// Whether the widget does not have focus.
  bool get isNotFocused => !isFocused;

  /// Whether the widget is not being pressed.
  bool get isNotPressed => !isPressed;

  /// Whether the widget is not selected.
  bool get isNotSelected => !isSelected;

  /// Whether the widget is not being dragged.
  bool get isNotDragged => !isDragged;

  /// Whether the widget is not in an error state.
  bool get isNotError => !isError;

  // Common state combinations

  /// Whether the widget is in any interactive state (hovered, focused, or pressed).
  ///
  /// Returns false if the widget is disabled.
  bool get isInteractive => !isDisabled && (isHovered || isFocused || isPressed);

  /// Whether the widget is highlighted (pressed or dragged).
  bool get isHighlighted => isPressed || isDragged;

  /// Whether the widget is in an active state (pressed, dragged, or selected).
  bool get isActive => isPressed || isDragged || isSelected;

  /// Whether the widget has any visual feedback state (hovered, focused, pressed, or dragged).
  bool get hasVisualFeedback => isHovered || isFocused || isPressed || isDragged;

  /// Whether the widget is in its default state (no special states except possibly enabled).
  bool get isDefault =>
      !isHovered &&
      !isFocused &&
      !isPressed &&
      !isDragged &&
      !isSelected &&
      !isDisabled &&
      !isError &&
      !isScrolledUnder;

  // Helper methods

  /// Checks if this set contains any of the given [states].
  ///
  /// Example:
  /// ```dart
  /// if (states.hasAny({WidgetState.pressed, WidgetState.dragged})) {
  ///   // Handle pressed or dragged state
  /// }
  /// ```
  bool hasAny(Set<WidgetState> states) => states.any(contains);

  /// Checks if this set contains all of the given [states].
  ///
  /// Example:
  /// ```dart
  /// if (states.hasAll({WidgetState.selected, WidgetState.focused})) {
  ///   // Handle state when both selected AND focused
  /// }
  /// ```
  bool hasAll(Set<WidgetState> states) => states.every(contains);

  /// Checks if this set contains none of the given [states].
  ///
  /// Example:
  /// ```dart
  /// if (states.hasNone({WidgetState.error, WidgetState.disabled})) {
  ///   // Handle state when neither error nor disabled
  /// }
  /// ```
  bool hasNone(Set<WidgetState> states) => !hasAny(states);

  /// Checks if this set contains exactly the given [states] and no others.
  ///
  /// Example:
  /// ```dart
  /// if (states.hasExactly({WidgetState.hovered})) {
  ///   // Handle state when ONLY hovered, nothing else
  /// }
  /// ```
  bool hasExactly(Set<WidgetState> states) =>
      length == states.length && states.every(contains);

  /// Creates a copy of this set with the given [state] added.
  ///
  /// This is useful for immutable state updates.
  Set<WidgetState> copyWith(WidgetState state) => {...this, state};

  /// Creates a copy of this set with the given [state] removed.
  ///
  /// This is useful for immutable state updates.
  Set<WidgetState> copyWithout(WidgetState state) =>
      {...this}..remove(state);

  /// Creates a copy of this set with the given [state] toggled.
  ///
  /// If the state is present, it's removed. If absent, it's added.
  Set<WidgetState> copyToggled(WidgetState state) =>
      contains(state) ? copyWithout(state) : copyWith(state);
}