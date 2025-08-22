import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'utilities/naked_focusable.dart';

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
class NakedRadio<T> extends StatefulWidget {
  const NakedRadio({
    super.key,
    required this.value,
    this.child,
    this.enabled = true,
    this.cursor,
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
    this.enableHapticFeedback = true,
    this.builder,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  final T value;
  final Widget? child;
  final bool enabled;
  final MouseCursor? cursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool toggleable;

  // State change callbacks
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onHighlightChanged; // For pressed state
  final ValueChanged<WidgetStatesDelta>? onStateChange;

  final WidgetStatesController? statesController;
  final String? semanticLabel;
  final String? semanticHint;
  final bool excludeSemantics;
  final bool enableHapticFeedback;
  final WidgetStateBuilder? builder;

  @override
  State<NakedRadio<T>> createState() => _NakedRadioState<T>();
}

class _NakedRadioState<T> extends State<NakedRadio<T>> {
  // Internal resources we manage
  FocusNode? _internalFocusNode;
  WidgetStatesController? _internalStatesController;

  // Track the delta for state changes
  WidgetStatesDelta _currentDelta = (
    previous: <WidgetState>{},
    current: <WidgetState>{},
  );

  // Cache for the last built widget to avoid unnecessary rebuilds
  Widget? _cachedWidget;

  FocusNode get focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  WidgetStatesController? get statesController =>
      widget.statesController ??
      (_internalStatesController ??= WidgetStatesController());

  @override
  void initState() {
    super.initState();
    // Initialize disabled state if we have a controller
    statesController?.update(WidgetState.disabled, !widget.enabled);
  }

  /// Process state changes from RawRadio
  void _processStates(Set<WidgetState> newStates) {
    // Debug print to see what states we're getting
    print('_processStates called with: $newStates');
    
    // Create new delta
    final newDelta = (previous: _currentDelta.current, current: newStates);

    // Use the extension to check if there's any change
    if (!newDelta.hasChanged) {
      print('No state changes detected');
      return; // No change, nothing to do
    }

    print('State change detected: ${newDelta.previous} -> ${newDelta.current}');
    
    // Update our tracked delta
    _currentDelta = newDelta;

    // Update external controller if provided
    if (statesController != null) {
      for (final state in WidgetState.values) {
        statesController!.update(state, newStates.contains(state));
      }
    }

    // Call individual callbacks using the extension methods
    if (newDelta.focusedHasChanged) {
      widget.onFocusChange?.call(newDelta.isFocused);
    }

    if (newDelta.hoveredHasChanged) {
      widget.onHoverChange?.call(newDelta.isHovered);
    }

    if (newDelta.pressedHasChanged) {
      widget.onHighlightChanged?.call(newDelta.isPressed);
    }

    // Haptic feedback on selection using extension methods
    if (widget.enableHapticFeedback &&
        widget.enabled &&
        newDelta.selectedHasChanged &&
        newDelta.isSelected) {
      HapticFeedback.selectionClick();
    }

    // Call unified state change callback
    widget.onStateChange?.call(newDelta);

    // Clear cache since states changed
    _cachedWidget = null;
  }

  /// Build the widget from builder or child
  Widget _buildWidget() {
    if (widget.builder != null) {
      return widget.builder!(_currentDelta);
    }

    return widget.child!;
  }

  @override
  void didUpdateWidget(NakedRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update disabled state if enabled changed
    if (oldWidget.enabled != widget.enabled) {
      statesController?.update(WidgetState.disabled, !widget.enabled);
    }

    // Clean up internal focus node if switching to external
    if (oldWidget.focusNode == null && widget.focusNode != null) {
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    }

    // Clean up internal states controller if switching to external
    if (oldWidget.statesController == null && widget.statesController != null) {
      _internalStatesController?.dispose();
      _internalStatesController = null;
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    _internalStatesController?.dispose();
    super.dispose();
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
    final effectiveCursor = widget.cursor != null
        ? WidgetStateMouseCursor.resolveWith((_) => widget.cursor!)
        : widget.enabled
        ? WidgetStateMouseCursor.clickable
        : WidgetStateMouseCursor.resolveWith(
            (_) => SystemMouseCursors.forbidden,
          );

    return Semantics(
      excludeSemantics: widget.excludeSemantics,
      enabled: widget.enabled,
      checked: isSelected,
      inMutuallyExclusiveGroup: true,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      child: RawRadio<T>(
        value: widget.value,
        mouseCursor: effectiveCursor,
        toggleable: widget.toggleable,
        focusNode: focusNode,
        autofocus: widget.autofocus && widget.enabled,
        groupRegistry: registry,
        enabled: widget.enabled,
        builder: (context, states) {
          // Process the states from RawRadio immediately
          _processStates(states.states);

          // Build the widget fresh each time for now
          return _buildWidget();
        },
      ),
    );
  }
}
