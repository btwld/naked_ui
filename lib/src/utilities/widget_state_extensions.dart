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

  /// Whether the widget is enabled (not disabled).
  bool get isEnabled => !isDisabled;

  // Reserved for future combinations if needed.

  // Helper methods removed as YAGNI; add back when real use-cases arise.
}
