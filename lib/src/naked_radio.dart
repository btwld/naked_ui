import 'package:flutter/material.dart';

import 'utilities/naked_pressable.dart';

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

/// Radio button built with simplified architecture.
class NakedRadio<T> extends StatelessWidget {
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

  void _handlePointerTap(RadioGroupRegistry<T> registry, bool isSelected) {
    if (!enabled) return;
    
    if (toggleable && isSelected) {
      registry.onChanged(null);
    } else if (!isSelected) {
      registry.onChanged(value);
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
    final isSelected = registry.groupValue == value;

    // Determine mouse cursor
    final effectiveCursor = mouseCursor != null
        ? mouseCursor!
        : enabled
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic;

    return NakedPressable(
      builder: (context, states, child) {
        return RawRadio<T>(
          value: value,
          mouseCursor: WidgetStateMouseCursor.resolveWith((_) => effectiveCursor),
          toggleable: toggleable,
          focusNode: focusNode ?? FocusNode(),
          autofocus: autofocus && enabled,
          groupRegistry: registry,
          enabled: enabled,
          builder: (context, radioStates) {
            // Build the widget using NakedPressable's states
            if (builder != null) {
              return builder!(context, states, child);
            }

            return this.child!;
          },
        );
      },
      onPressed: enabled
          ? () => _handlePointerTap(registry, isSelected)
          : null,
      enabled: enabled,
      selected: isSelected,
      mouseCursor: effectiveCursor,
      focusNode: focusNode,
      autofocus: autofocus,
      onStatesChange: onStatesChange,
      onFocusChange: onFocusChange,
      onHoverChange: onHoverChange,
      onPressChange: onPressChange,
      statesController: statesController,
    );
  }
}