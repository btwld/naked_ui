import 'package:flutter/widgets.dart';

/// A utility class that provides semantic wrapper methods for common UI patterns.
///
/// These methods ensure consistent and correct semantic markup for accessibility,
/// with parameter names that exactly match Flutter's [Semantics] widget properties
/// to avoid confusion and make the API self-documenting.
class NakedSemantics {
  const NakedSemantics._();

  /// Creates semantic markup for a button element.
  ///
  /// The [label] describes the button's action for screen readers.
  /// The [onTap] callback is called when the button is activated.
  /// The button is marked as disabled when [onTap] is null.
  /// When [excludeSemantics] is true, child semantics are excluded (default: true for headless widgets).
  static Widget button({
    required String label,
    required VoidCallback? onTap,
    required Widget child,
    String? hint,
    bool excludeSemantics = true,
  }) {
    return Semantics(
      excludeSemantics: excludeSemantics,
      enabled: onTap != null,
      button: true,
      label: label,
      hint: hint,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates semantic markup for a checkbox element.
  ///
  /// The [checked] parameter uses the exact same name as the [Semantics] property.
  /// When [tristate] is true and [checked] is null, the checkbox is marked as mixed.
  /// The checkbox is marked as disabled when [onTap] is null.
  /// When [excludeSemantics] is true, child semantics are excluded (default: true for headless widgets).
  static Widget checkbox({
    required String? label,
    required bool? checked,
    required bool tristate,
    required VoidCallback? onTap,
    required Widget child,
    required String? hint,
    bool excludeSemantics = true,
  }) {
    return Semantics(
      excludeSemantics: excludeSemantics,
      enabled: onTap != null,
      checked: tristate && checked == null ? null : (checked ?? false),
      mixed: tristate && checked == null,
      label: label,
      hint: hint,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates semantic markup for a switch/toggle element.
  ///
  /// The [toggled] parameter uses the exact same name as the [Semantics] property.
  /// The switch is marked as disabled when [onTap] is null.
  /// When [excludeSemantics] is true, child semantics are excluded (default: true for headless widgets).
  ///
  /// Named [switchToggle] because 'switch' is a reserved keyword in Dart.
  static Widget switchToggle({
    required String label,
    required bool toggled,
    required VoidCallback? onTap,
    required Widget child,
    String? hint,
    bool excludeSemantics = true,
  }) {
    return Semantics(
      excludeSemantics: excludeSemantics,
      enabled: onTap != null,
      toggled: toggled,
      label: label,
      hint: hint,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates semantic markup for a radio button element.
  ///
  /// The [checked] parameter uses the exact same name as the [Semantics] property.
  /// Radio buttons are automatically marked as [inMutuallyExclusiveGroup].
  /// The radio is marked as disabled when [onTap] is null.
  /// When [excludeSemantics] is true, child semantics are excluded (default: true for headless widgets).
  static Widget radio({
    required String label,
    required bool checked,
    required VoidCallback? onTap,
    required Widget child,
    String? hint,
    bool excludeSemantics = true,
  }) {
    return Semantics(
      excludeSemantics: excludeSemantics,
      enabled: onTap != null,
      checked: checked,
      inMutuallyExclusiveGroup: true,
      label: label,
      hint: hint,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates semantic markup for a slider element.
  ///
  /// All parameter names match the exact [Semantics] property names:
  /// - [value]: The current value description
  /// - [increasedValue]: The value after increasing (optional)
  /// - [decreasedValue]: The value after decreasing (optional)
  ///
  /// The slider is marked as disabled when both [onIncrease] and [onDecrease] are null.
  /// When [excludeSemantics] is true, child semantics are excluded (default: true for headless widgets).
  static Widget slider({
    required String label,
    required String value,
    required VoidCallback? onIncrease,
    required VoidCallback? onDecrease,
    required Widget child,
    String? increasedValue,
    String? decreasedValue,
    String? hint,
    bool excludeSemantics = true,
  }) {
    final enabled = onIncrease != null || onDecrease != null;

    return Semantics(
      excludeSemantics: excludeSemantics,
      enabled: enabled,
      slider: true,
      label: label,
      value: value,
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      hint: hint,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: child,
    );
  }

  /// Creates semantic markup for a text field element.
  ///
  /// All parameter names match the exact [Semantics] property names:
  /// - [value]: The current text content
  /// - [readOnly]: Whether the field is read-only
  /// - [obscured]: Whether the text is obscured (e.g., password)
  /// - [multiline]: Whether the field supports multiple lines
  /// - [maxValueLength]: Maximum character count (not 'maxLength')
  /// - [currentValueLength]: Current character count
  ///
  /// The field is marked as disabled when [onTap] is null or [readOnly] is true.
  /// When [excludeSemantics] is true, child semantics are excluded (default: true for headless widgets).
  static Widget textField({
    required String label,
    required String value,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onDidGainAccessibilityFocus,
    VoidCallback? onDidLoseAccessibilityFocus,
    bool readOnly = false,
    bool obscured = false,
    bool multiline = false,
    int? maxValueLength,
    int? currentValueLength,
    String? hint,
    bool excludeSemantics = true,
  }) {
    return Semantics(
      excludeSemantics: excludeSemantics,
      enabled: onTap != null && !readOnly,
      textField: true,
      readOnly: readOnly,
      obscured: obscured,
      multiline: multiline,
      maxValueLength: maxValueLength,
      currentValueLength: currentValueLength ?? value.length,
      label: label,
      value: value,
      hint: hint,
      onTap: onTap,
      onDidGainAccessibilityFocus: onDidGainAccessibilityFocus,
      onDidLoseAccessibilityFocus: onDidLoseAccessibilityFocus,
      child: child,
    );
  }

  /// Creates semantic markup for a tab element.
  ///
  /// The [selected] parameter uses the exact same name as the [Semantics] property.
  /// Tabs use [selected] rather than [checked] to indicate the active tab.
  /// The tab is marked as disabled when [onTap] is null.
  /// When [excludeSemantics] is true, child semantics are excluded (default: true for headless widgets).
  ///
  /// Note: Flutter lacks proper tab role (Issue #107861).
  static Widget tab({
    required String? label,
    required bool selected,
    required VoidCallback? onTap,
    required Widget child,
    String? hint,
    bool excludeSemantics = true,
  }) {
    return Semantics(
      excludeSemantics: excludeSemantics,
      enabled: onTap != null,
      selected: selected,
      label: label,
      hint: hint,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates semantic markup for an expandable/collapsible element.
  ///
  /// The [expanded] parameter uses the exact same name as the [Semantics] property.
  /// Used for accordions, expansion tiles, and other collapsible content.
  /// Auto-generates hint if not provided based on current expansion state.
  /// The element is marked as disabled when [onTap] is null.
  /// When [excludeSemantics] is true, child semantics are excluded (default: true for headless widgets).
  ///
  /// Note: Flutter's expanded property doesn't work properly on all platforms yet (Issue #92040).
  static Widget expandable({
    required String? label,
    required bool expanded,
    required VoidCallback? onTap,
    required Widget child,
    String? hint,
    bool excludeSemantics = true,
  }) {
    // Auto-generate hint if not provided
    final expandHint = hint ?? (expanded 
      ? 'Double tap to collapse' 
      : 'Double tap to expand');
    
    return Semantics(
      excludeSemantics: excludeSemantics,
      enabled: onTap != null,
      expanded: expanded,
      label: label,
      hint: expandHint,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates semantic markup for a tooltip element.
  ///
  /// The [tooltip] parameter uses the exact same name as the [Semantics] property.
  /// Tooltips typically don't exclude child semantics by default.
  /// When [excludeSemantics] is true, child semantics are excluded (default: false for tooltips).
  static Widget tooltip({
    required String? tooltip,
    required Widget child,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      excludeSemantics: excludeSemantics,
      container: true,
      tooltip: tooltip,
      child: child,
    );
  }

  /// Creates semantic markup for a progress indicator.
  ///
  /// The [value] describes the current progress state.
  /// Use [label] to describe what is loading.
  /// When [excludeSemantics] is true, child semantics are excluded (default: true for headless widgets).
  static Widget progressIndicator({
    required String label,
    required Widget child,
    String? value,
    bool excludeSemantics = true,
  }) {
    return Semantics(
      excludeSemantics: excludeSemantics,
      label: label,
      value: value,
      child: child,
    );
  }
}
