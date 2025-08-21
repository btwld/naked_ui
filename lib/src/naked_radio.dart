import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Thin wrapper over Flutter's RadioGroup to preserve Naked API.
class NakedRadioGroup<T> extends StatelessWidget {
  const NakedRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
    this.enabled = true,
  });

  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: groupValue,
      // Always provide a non-null handler as RadioGroup requires it.
      onChanged: (T? value) {
        if (enabled && onChanged != null) {
          onChanged!(value);
        }
      },
      child: child,
    );
  }
}

/// Thin wrapper over Flutter's RawRadio to preserve Naked API surface.
class NakedRadio<T> extends StatefulWidget {
  const NakedRadio({
    super.key,
    required this.value,
    required this.child,
    this.enabled = true,
    this.cursor,
    this.focusNode,
    this.autofocus = false,
    this.toggleable = false,
    // The following callbacks are retained for API compatibility but are not
    // wired to RawRadio internals in this thin wrapper.
    this.onSelectChange,
    this.onFocusChange,
    this.onHoverChange,
    this.onHighlightChanged,
    this.statesController,
    this.semanticLabel,
    this.semanticHint,
    this.excludeSemantics = false,
    this.enableHapticFeedback = true,
    this.builder,
  });

  final T value;
  final Widget child;
  final bool enabled;
  final MouseCursor? cursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool toggleable;

  final ValueChanged<bool>? onSelectChange;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onHighlightChanged;
  final WidgetStatesController? statesController;
  final String? semanticLabel;
  final String? semanticHint;
  final bool excludeSemantics;
  final bool enableHapticFeedback;
  final Widget Function(NakedRadioScope<T>)? builder;

  @override
  State<NakedRadio<T>> createState() => _NakedRadioState<T>();
}

class _NakedRadioState<T> extends State<NakedRadio<T>> {
  FocusNode? _internalFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  WidgetStateProperty<MouseCursor> get _mouseCursorProp => widget.cursor != null
      ? WidgetStatePropertyAll<MouseCursor>(widget.cursor!)
      : WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click;
        });

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = RadioGroup.maybeOf<T>(context);
    if (registry == null) {
      throw FlutterError(
        'NakedRadio must be used within a NakedRadioGroup. No NakedRadioGroup ancestor found.',
      );
    }

    return RawRadio<T>(
      value: widget.value,
      mouseCursor: _mouseCursorProp,
      toggleable: widget.toggleable,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      groupRegistry: registry,
      enabled: widget.enabled,
      builder: (context, state) {
        return NakedRadioScope<T>(
          radioValue: widget.value,
          groupValue: registry.groupValue,
          tristate: widget.toggleable,
          enabled: widget.enabled,
          states: state.states,
          child: Builder(
            builder: (scopeContext) {
              if (widget.builder != null) {
                return widget.builder!(NakedRadioScope.of(scopeContext));
              }

              return widget.child;
            },
          ),
        );
      },
    );
  }
}

/// Provides radio view state to descendants.
class NakedRadioScope<T> extends InheritedWidget {
  const NakedRadioScope({
    super.key,
    required this.radioValue,
    required this.groupValue,
    required this.tristate,
    required this.enabled,
    required this.states,
    required super.child,
  });

  static NakedRadioScope<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  static NakedRadioScope<T> of<T>(BuildContext context) {
    final result = maybeOf<T>(context);
    assert(result != null, 'No NakedRadioScope<$T> found in context');

    return result!;
  }

  final T radioValue;
  final T? groupValue;
  final bool tristate;

  final bool enabled;

  final Set<WidgetState> states;

  bool get isSelected => groupValue == radioValue;

  @override
  bool updateShouldNotify(covariant NakedRadioScope<T> oldWidget) {
    return radioValue != oldWidget.radioValue ||
        groupValue != oldWidget.groupValue ||
        tristate != oldWidget.tristate ||
        enabled != oldWidget.enabled ||
        !setEquals(states, oldWidget.states);
  }
}
