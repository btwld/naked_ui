import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/naked_interactable.dart';

/// Thin wrapper over Flutter's RadioGroup to preserve Naked API.
class NakedRadioGroup<T> extends StatelessWidget {
  const NakedRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: child,
    );
  }
}

/// Radio button built on RawRadio with proper semantics and state callbacks.
class NakedRadio<T> extends StatefulWidget with NakedFocusable {
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
    this.onHighlightChanged,
    this.onStateChange,
    this.statesController,
    this.semanticLabel,
    this.semanticHint,
    this.excludeSemantics = false,
    this.builder,
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
  final ValueChanged<bool>? onHighlightChanged; // For pressed state
  final ValueChanged<Set<WidgetState>>? onStateChange;

  final WidgetStatesController? statesController;
  final String? semanticLabel;
  final String? semanticHint;
  final bool excludeSemantics;
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  @override
  State<NakedRadio<T>> createState() => _NakedRadioState<T>();
}

class _NakedRadioState<T> extends State<NakedRadio<T>>
    with NakedFocusableStateMixin {
  @override
  Widget build(BuildContext context) {
    final registry = RadioGroup.maybeOf<T>(context);

    // Always require registry
    if (registry == null) {
      throw FlutterError.fromParts([
        ErrorSummary(
          'NakedRadio<$T> must be used within a NakedRadioGroup<$T>.',
        ),
        ErrorDescription(
          'No NakedRadioGroup<$T> ancestor was found in the widget tree.',
        ),
        ErrorHint(
          'Wrap your NakedRadio widgets with a NakedRadioGroup:\n'
          'NakedRadioGroup<$T>(\n'
          '  groupValue: selectedValue,\n'
          '  onChanged: (value) { ... },\n'
          '  child: Column(\n'
          '    children: [\n'
          '      NakedRadio<$T>(value: ...),\n'
          '      NakedRadio<$T>(value: ...),\n'
          '    ],\n'
          '  ),\n'
          ')',
        ),
      ]);
    }

    // Check if selected
    final isSelected = registry.groupValue == widget.value;

    // Determine mouse cursor
    final effectiveCursor = widget.mouseCursor != null
        ? WidgetStateMouseCursor.resolveWith((_) => widget.mouseCursor!)
        : widget.enabled
        ? WidgetStateMouseCursor.clickable
        : WidgetStateMouseCursor.resolveWith(
            (_) => SystemMouseCursors.forbidden,
          );

    return NakedInteractable(
      statesController: widget.statesController,
      enabled: widget.enabled,
      onHighlightChanged: widget.onHighlightChanged,
      onHoverChange: widget.onHoverChange,
      onFocusChange: widget.onFocusChange,
      onStateChange: widget.onStateChange,
      selected: isSelected,
      autofocus: widget.autofocus,
      focusNode: effectiveFocusNode,
      builder: (context, states, child) {
        return RawRadio<T>(
          value: widget.value,
          mouseCursor: effectiveCursor,
          toggleable: widget.toggleable,
          focusNode: effectiveFocusNode,
          autofocus: widget.autofocus && widget.enabled,
          groupRegistry: registry,
          enabled: widget.enabled,
          builder: (context, radioStates) {
            // Build the widget using NakedInteractable's states
            if (widget.builder != null) {
              return widget.builder!(context, states, child);
            }

            return widget.child!;
          },
        );
      },
    );
  }
}
