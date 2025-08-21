import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Headless checkbox built on Flutter's toggleable behaviors.
class NakedCheckbox extends StatefulWidget {
  const NakedCheckbox({
    super.key,
    required this.child,
    this.value = false,
    this.tristate = false,
    this.onChanged,
    this.enabled = true,
    this.semanticLabel,
    this.semanticHint,
    this.excludeSemantics = false,
    this.cursor,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onHighlightChanged,
    this.statesController,
    this.builder,
  }) : assert(
         (tristate || value != null),
         'Non-tristate checkbox must have a non-null value',
       );

  /// Visual representation of the checkbox.
  ///
  /// Renders different states based on callback properties.
  final Widget child;

  /// Whether this checkbox is checked.
  ///
  /// When [tristate] is true, null corresponds to mixed state.
  final bool? value;

  /// Whether the checkbox can be true, false, or null.
  ///
  /// When true, tapping cycles through false => true => null => false.
  /// When false, [value] must not be null.
  final bool tristate;

  /// Called when the checkbox is toggled.
  ///
  /// If null, the checkbox is disabled and unresponsive.
  final ValueChanged<bool?>? onChanged;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when highlight (pressed) state changes.
  final ValueChanged<bool>? onHighlightChanged;

  /// Optional external controller for interaction states.
  final WidgetStatesController? statesController;

  /// Whether the checkbox is enabled.
  final bool enabled;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Semantic hint for accessibility.
  final String? semanticHint;

  /// Whether to exclude child semantics from the semantic tree.
  final bool excludeSemantics;

  /// Cursor when hovering over the checkbox.
  final MouseCursor? cursor;

  /// Whether to provide haptic feedback on tap.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to autofocus when created.
  final bool autofocus;

  /// Optional builder that receives the current scope for visuals.
  final Widget Function(NakedCheckboxScope scope)? builder;

  @override
  State<NakedCheckbox> createState() => _NakedCheckboxState();
}

class _NakedCheckboxState extends State<NakedCheckbox>
    with TickerProviderStateMixin, ToggleableStateMixin {
  WidgetStateProperty<MouseCursor> get _mouseCursorProp => widget.cursor != null
      ? WidgetStatePropertyAll<MouseCursor>(widget.cursor!)
      : WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click;
        });

  @override
  bool get tristate => widget.tristate;

  @override
  bool? get value => widget.value;

  @override
  bool get isInteractive => widget.enabled && widget.onChanged != null;

  @override
  ValueChanged<bool?>? get onChanged =>
      widget.enabled ? widget.onChanged : null;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: widget.value ?? false,
      mixed: widget.tristate ? widget.value == null : null,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      child: buildToggleableWithChild(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: _mouseCursorProp,
        child: widget.builder != null
            ? NakedCheckboxScope(
                value: widget.value,
                tristate: widget.tristate,
                enabled: widget.enabled,
                states: states,
                child: Builder(
                  builder: (scopeCtx) =>
                      widget.builder!(NakedCheckboxScope.of(scopeCtx)),
                ),
              )
            : widget.child,
      ),
    );
  }
}

/// Provides checkbox state to visuals.
class NakedCheckboxScope extends InheritedWidget {
  const NakedCheckboxScope({
    super.key,
    required this.value,
    required this.tristate,
    required this.enabled,
    required this.states,
    required super.child,
  });

  static NakedCheckboxScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  static NakedCheckboxScope of(BuildContext context) {
    final NakedCheckboxScope? result = maybeOf(context);
    assert(result != null, 'No NakedCheckboxScope found in context');

    return result!;
  }

  final bool? value;
  final bool tristate;

  final bool enabled;
  final Set<WidgetState> states;

  bool get isSelected => value == true;

  bool get isMixed => tristate && value == null;

  @override
  bool updateShouldNotify(covariant NakedCheckboxScope oldWidget) {
    return value != oldWidget.value ||
        tristate != oldWidget.tristate ||
        enabled != oldWidget.enabled ||
        !setEquals(states, oldWidget.states);
  }
}
