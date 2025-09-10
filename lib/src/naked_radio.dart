import 'package:flutter/material.dart';

import 'mixins/naked_mixins.dart';

/// Radio button built with simplified architecture.
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

  @override
  State<NakedRadio<T>> createState() => _NakedRadioState<T>();
}

class _NakedRadioState<T> extends State<NakedRadio<T>>
    with NakedPressableListenerMixin<NakedRadio<T>> {
  FocusNode? _internalFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    // Ensure internal node exists if needed and listen for focus changes
    // so we can surface onFocusChange from the single RawRadio focus node.
    _focusNode.addListener(_handleFocusNodeChanged);
  }

  void _handlePointerTap(RadioGroupRegistry<T> registry, bool isSelected) {
    if (!widget.enabled) return;
    if (widget.toggleable && isSelected) {
      registry.onChanged(null);
    } else if (!isSelected) {
      registry.onChanged(widget.value);
    }
  }

  void _handleFocusNodeChanged() {
    widget.onFocusChange?.call(_focusNode.hasFocus);
  }

  @override
  void didUpdateWidget(NakedRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      // Move listener to the new effective node
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(
        _handleFocusNodeChanged,
      );
      _focusNode.addListener(_handleFocusNodeChanged);
    }
  }

  @override
  void dispose() {
    // Detach listener from the current effective node before disposing.
    (widget.focusNode ?? _internalFocusNode)?.removeListener(
      _handleFocusNodeChanged,
    );
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = RadioGroup.maybeOf<T>(context);

    // Always require registry
    if (registry == null) {
      throw FlutterError.fromParts([
        ErrorSummary('NakedRadio<$T> must be used within a RadioGroup<$T>.'),
        ErrorDescription(
          'No RadioGroup<$T> ancestor was found in the widget tree.',
        ),
        ErrorHint(
          'Wrap your NakedRadio widgets with a RadioGroup:\n'
          'RadioGroup<$T>(\n'
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
        ? widget.mouseCursor!
        : widget.enabled
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic;

    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        child: GestureDetector(
          onTap: widget.enabled
              ? () => _handlePointerTap(registry, isSelected)
              : null,
          behavior: HitTestBehavior.opaque,
          child: buildPressListener(
            enabled: widget.enabled,
            behavior: HitTestBehavior.opaque,
            onPressChange: widget.onPressChange,
            child: RawRadio<T>(
              value: widget.value,
              mouseCursor: WidgetStateMouseCursor.resolveWith(
                (_) => effectiveCursor,
              ),
              toggleable: widget.toggleable,
              focusNode: _focusNode,
              autofocus: widget.autofocus && widget.enabled,
              groupRegistry: registry,
              enabled: widget.enabled,
              builder: (context, radioState) {
                // Create states set from basic state info
                final states = <WidgetState>{
                  if (!widget.enabled) WidgetState.disabled,
                  if (isSelected) WidgetState.selected,
                  // Note: RawRadio doesn't expose hover/press states through builder
                  // This is a limitation of the RawRadio API
                };


                if (widget.builder != null) {
                  return widget.builder!(context, states, widget.child);
                }

                return widget.child!;
              },
            ),
          ),
        ),
      ),
    );
  }
}
