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
    with PressListenerMixin<NakedRadio<T>>, FocusableMixin<NakedRadio<T>> {
  // Track which node currently has our listener so we can move it safely.
  FocusNode? _listenedFocusNode;

  @protected
  @override
  FocusNode? get focusableExternalNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    // Attach listener to the effective focus node to surface onFocusChange.
    _listenedFocusNode = effectiveFocusNode;
    _listenedFocusNode?.addListener(_handleFocusNodeChanged);
  }

  // Removed unused _handlePointerTap (selection is handled by RawRadio).

  void _handleFocusNodeChanged() {
    widget.onFocusChange?.call(effectiveFocusNode?.hasFocus ?? false);
  }

  Widget _buildRadioWidget(
    BuildContext _,
    RadioGroupRegistry<T> registry,
    bool isSelected,
  ) {
    final effectiveCursor = widget.mouseCursor != null
        ? widget.mouseCursor!
        : widget.enabled
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic;

    return buildPressListener(
      enabled: widget.enabled,
      behavior: HitTestBehavior.translucent,
      onPressChange: widget.onPressChange,
      child: Listener(
        onPointerUp: (_) {
          if (!widget.enabled) return;
          // If not toggleable and already selected, do nothing (no change).
          if (!widget.toggleable && isSelected) return;
          final next = widget.toggleable && isSelected ? null : widget.value;
          registry.onChanged(next);
        },
        behavior: HitTestBehavior.translucent,
        child: RawRadio<T>(
          value: widget.value,
          mouseCursor: WidgetStateMouseCursor.resolveWith(
            (_) => effectiveCursor,
          ),
          toggleable: widget.toggleable,
          focusNode: effectiveFocusNode!,
          autofocus: widget.autofocus && widget.enabled,
          groupRegistry: registry,
          enabled: widget.enabled,
          builder: (context, radioState) {
            if (widget.builder != null) {
              final states = <WidgetState>{
                if (!widget.enabled) WidgetState.disabled,
                if (isSelected) WidgetState.selected,
              };

              return widget.builder!(context, states, widget.child);
            }

            return widget.child!;
          },
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(NakedRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the effective focus node changed (external swap or internal allocation),
    // move the listener to the new node.
    final FocusNode? newNode = effectiveFocusNode;
    if (!identical(newNode, _listenedFocusNode)) {
      _listenedFocusNode?.removeListener(_handleFocusNodeChanged);
      _listenedFocusNode = newNode;
      _listenedFocusNode?.addListener(_handleFocusNodeChanged);
    }
  }

  @override
  void dispose() {
    // Detach our listener; FocusableMixin handles internal node disposal.
    _listenedFocusNode?.removeListener(_handleFocusNodeChanged);
    _listenedFocusNode = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = widget.groupRegistry ?? RadioGroup.maybeOf<T>(context);

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

    final isSelected = registry.groupValue == widget.value;
    Widget radioWidget = _buildRadioWidget(context, registry, isSelected);

    // RawRadio handles all radio-specific semantics (checked, mutually exclusive, focus, etc.)
    // Users can control child semantics through their child or builder
    return radioWidget;
  }
}
