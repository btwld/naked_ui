import 'package:flutter/material.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/hit_testable_container.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedRadio.builder].
class NakedRadioState<T> extends NakedState {
  /// The value represented by this radio.
  final T value;

  NakedRadioState({required super.states, required this.value});
}

/// A headless radio without visuals.
///
/// Must be placed under a [RadioGroup]. The builder receives a [NakedRadioState]
/// with the radio value, group value, and interaction states.
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
/// ## Accessibility
/// For optimal accessibility, ensure your radio has a minimum touch target
/// of 48x48dp. Smaller sizes will work but may be difficult for some users
/// to tap accurately.
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

  /// Whether the radio is enabled.
  final bool enabled;

  /// The mouse cursor when hovering.
  final MouseCursor? mouseCursor;

  /// The focus node for the radio.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  /// Whether tapping the selected radio clears the selection.
  final bool toggleable;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when press state changes.
  final ValueChanged<bool>? onPressChange;

  /// Builds the radio using the current [NakedRadioState].
  final NakedStateBuilder<NakedRadioState<T>>? builder;

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
  void didUpdateWidget(covariant NakedRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When enablement flips, clear sentinels so the next interactive state
    // change is reported instead of being suppressed by stale values.
    if (oldWidget.enabled != widget.enabled) {
      _lastReportedHover = null;
      _lastReportedPressed = null;
    }
  }

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
      focusNode: effectiveFocusNode, // FocusNodeMixin guarantees non-null
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
          final isSelected = registry.groupValue == widget.value;
          final statesWithSelection = {
            ...states,
            if (isSelected) WidgetState.selected,
          };
          final radioStateTyped = NakedRadioState<T>(
            states: statesWithSelection,
            value: widget.value,
          );

          final built = widget.builder!(context, radioStateTyped, widget.child);

          // Ensure the area is hit-testable so RawRadio's GestureDetector
          // can receive taps even if the built widget has no gesture handlers.
          return HitTestableContainer(child: built);
        }

        // Ensure the child area is hit-testable for taps.
        return HitTestableContainer(child: widget.child!);
      },
    );
  }
}
