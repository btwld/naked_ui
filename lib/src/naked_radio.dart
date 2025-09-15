import 'package:flutter/material.dart';

import 'mixins/naked_mixins.dart';

/// A headless radio that participates in a [RadioGroup] without default visuals.
///
/// - Must be placed under a [RadioGroup] (or provide a custom [groupRegistry]).
/// - No visuals are provided; pass a [child] or [builder] to render UI.
/// - States are exposed to [builder] as a `Set<WidgetState>` including
///   at least hovered/pressed/focused/selected/disabled.
/// - Keyboard: focus + Enter/Space select; semantics exposed as a radio.
///
/// Example:
/// ```dart
/// RadioGroup<int>(
///   value: selected,
///   onChanged: (v) => setState(() => selected = v),
///   child: Row(children: [
///     NakedRadio<int>(value: 1, child: const Text('One')),
///     NakedRadio<int>(value: 2, child: const Text('Two')),
///   ]),
/// )
/// ```
///
/// See also:
/// - [RawRadio], the underlying primitive widget used to implement radio
///   interaction and semantics.
/// - [RadioGroup], which manages the selected value and provides the grouping
///   context for radios.
class NakedRadio<T> extends StatefulWidget {
  const NakedRadio({
    super.key,
    required this.value,
    this.child,
    this.enabled = true,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.toggleable = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
    this.builder,
    this.groupRegistry,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// Value represented by this radio.
  final T value;

  /// Visual contents when not using [builder].
  final Widget? child;

  /// Whether this radio is enabled.
  final bool enabled;

  /// Mouse cursor when enabled.
  ///
  /// Defaults to [SystemMouseCursors.click] when interactive and
  /// [SystemMouseCursors.basic] when disabled.
  final MouseCursor? mouseCursor;

  /// External [FocusNode] to control focus ownership.
  final FocusNode? focusNode;

  /// Whether to autofocus when built.
  final bool autofocus;

  /// Whether tapping the selected radio clears the selection (nullable group).
  final bool toggleable;

  // State change callbacks
  /// Notifies when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Notifies when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Notifies when pressed (highlight) changes.
  final ValueChanged<bool>? onPressChange;

  /// Builder that receives the current interaction [WidgetState]s.
  ///
  /// Includes the `selected` state when this radio's [value] matches the
  /// group's selected value.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Registry override for advanced usage and testing.
  ///
  /// When null, the nearest [RadioGroup] ancestor is used.
  final RadioGroupRegistry<T>? groupRegistry;

  @override
  State<NakedRadio<T>> createState() => _NakedRadioState<T>();
}

class _NakedRadioState<T> extends State<NakedRadio<T>>
    with FocusableMixin<NakedRadio<T>> {
  bool? _lastReportedPressed;
  bool? _lastReportedHover;

  @protected
  @override
  FocusNode? get focusableExternalNode => widget.focusNode;

  @protected
  @override
  ValueChanged<bool>? get focusableOnFocusChange => widget.onFocusChange;

  @override
  Widget build(BuildContext context) {
    final registry = widget.groupRegistry ?? RadioGroup.maybeOf<T>(context);
    if (registry == null) {
      throw FlutterError(
        'NakedRadio<$T> must be used within a RadioGroup<$T>.',
      );
    }

    final effectiveCursor =
        widget.mouseCursor ??
        (widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic);

    return RawRadio<T>(
      value: widget.value,
      mouseCursor: WidgetStateMouseCursor.resolveWith((_) => effectiveCursor),
      toggleable: widget.toggleable,
      focusNode: effectiveFocusNode!, // from FocusableMixin
      autofocus: widget.autofocus && widget.enabled,
      groupRegistry: registry,
      enabled: widget.enabled,
      builder: (context, radioState) {
        // Derive "pressed" from RawRadio's internal down position to avoid
        // intercepting gestures with an external Listener.
        final bool pressed = radioState.downPosition != null;
        final states = {...radioState.states, if (pressed) WidgetState.pressed};

        // Notify hover changes only when interactive, without setState in build
        final hovered = states.contains(WidgetState.hovered);
        if (widget.enabled && _lastReportedHover != hovered) {
          _lastReportedHover = hovered;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onHoverChange?.call(hovered);
          });
        }

        // Notify press changes only when interactive
        if (widget.enabled && _lastReportedPressed != pressed) {
          _lastReportedPressed = pressed;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onPressChange?.call(pressed);
          });
        }

        if (widget.builder != null) {
          final built = widget.builder!(context, states, widget.child);

          // Ensure the area is hit-testable so RawRadio's GestureDetector
          // can receive taps even if the built widget has no gesture handlers.
          return ColoredBox(color: Colors.transparent, child: built);
        }

        // Ensure the child area is hit-testable for taps.
        return ColoredBox(color: Colors.transparent, child: widget.child!);
      },
    );
  }
}
