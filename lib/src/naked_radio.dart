import 'package:flutter/material.dart';

import 'mixins/naked_mixins.dart';

/// A headless radio without visuals.
///
/// Must be placed under a [RadioGroup]. Exposes interaction states
/// including hovered, pressed, focused, selected, and disabled.
///
/// ```dart
/// RadioGroup<String>(
///   value: selectedValue,
///   onChanged: (value) => setState(() => selectedValue = value),
///   child: Column(children: [
///     NakedRadio(value: 'option1', child: Text('Option 1')),
///     NakedRadio(value: 'option2', child: Text('Option 2')),
///   ]),
/// )
/// ```
///
/// See also:
/// - [Radio], the Material-styled radio for typical apps.
/// - [RadioGroup], which manages the selected value and provides grouping.
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

  /// The value represented by this radio.
  final T value;

  /// The visual content when not using [builder].
  final Widget? child;

  /// The enabled state of the radio.
  final bool enabled;

  /// The mouse cursor when hovering.
  final MouseCursor? mouseCursor;

  /// The focus node for the radio.
  final FocusNode? focusNode;

  /// The autofocus flag.
  final bool autofocus;

  /// The toggleable flag for clearing selection.
  final bool toggleable;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when press state changes.
  final ValueChanged<bool>? onPressChange;

  /// The builder that receives current interaction states.
  ///
  /// Includes the selected state when [value] matches the group's
  /// selected value.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// The registry override for advanced usage and testing.
  ///
  /// When null, the nearest [RadioGroup] ancestor is used.
  final RadioGroupRegistry<T>? groupRegistry;

  @override
  State<NakedRadio<T>> createState() => _NakedRadioState<T>();
}

class _NakedRadioState<T> extends State<NakedRadio<T>>
    with FocusNodeMixin<NakedRadio<T>> {
  bool? _lastReportedPressed;
  bool? _lastReportedHover;

  @protected
  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;

  @protected
  @override
  ValueChanged<bool>? get onFocusChange => widget.onFocusChange;

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
      focusNode: effectiveFocusNode!,
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
