import 'package:flutter/material.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/utilities.dart';

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
    this.onPressChange,
    this.onStatesChange,
    this.statesController,
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

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;
  final ValueChanged<Set<WidgetState>>? onStatesChange;

  final WidgetStatesController? statesController;
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  @override
  State<NakedRadio<T>> createState() => _NakedRadioState<T>();
}

class _NakedRadioState<T> extends State<NakedRadio<T>>
    with NakedFocusableStateMixin {

  void _handlePointerTap(RadioGroupRegistry<T> registry, bool isSelected) {
    if (!widget.enabled) return;
    
    if (widget.toggleable && isSelected) {
      registry.onChanged(null);
    } else if (!isSelected) {
      registry.onChanged(widget.value);
    }
  }

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
            (_) => SystemMouseCursors.basic,
          );

    return MouseRegion(
        cursor: effectiveCursor.resolve({
          if (!widget.enabled) WidgetState.disabled,
          if (isSelected) WidgetState.selected,
        }),
        child: GestureDetector(
          onTap: widget.enabled
              ? () => _handlePointerTap(registry, isSelected)
              : null,
          behavior: HitTestBehavior.opaque,
          child: NakedInteractable(
            statesController: widget.statesController,
            enabled: widget.enabled,
            selected: isSelected,
            autofocus: widget.autofocus,
            onStatesChange: widget.onStatesChange,
            onFocusChange: widget.onFocusChange,
            onHoverChange: widget.onHoverChange,
            onPressChange: widget.onPressChange,
            // Don't pass focusNode here since RawRadio will manage it
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
          ),
        ),
    );
  }
}
