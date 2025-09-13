import 'package:flutter/material.dart';

import 'mixins/naked_mixins.dart';

/// Radio button built with simplified architecture.
///
/// Provides radio functionality while letting users control presentation
/// and semantics through the child or builder parameter.
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

  final T value;
  final Widget? child;
  final bool enabled;
  final MouseCursor? mouseCursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool toggleable;

  // State change callbacks
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Optional registry override for advanced usage and testing.
  /// When null, the nearest RadioGroup<T> ancestor is used.
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

        // Notify hover changes without setState in build
        final hovered = states.contains(WidgetState.hovered);
        if (_lastReportedHover != hovered) {
          _lastReportedHover = hovered;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onHoverChange?.call(hovered);
          });
        }

        // Notify press changes derived from RawRadio
        if (_lastReportedPressed != pressed) {
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
