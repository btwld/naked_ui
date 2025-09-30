import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/state.dart';

/// Immutable view passed to [NakedToggle.builder].
class NakedToggleState extends NakedState {
  /// Whether the toggle is currently on.
  final bool isToggled;

  NakedToggleState({required super.states, required this.isToggled});

  /// Returns the nearest [NakedToggleState] from context.
  static NakedToggleState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedToggleState] if available.
  static NakedToggleState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedToggleState &&
        setEquals(other.states, states) &&
        other.isToggled == isToggled;
  }

  @override
  int get hashCode => Object.hash(states, isToggled);
}

/// Immutable view passed to [NakedToggleOption.builder].
class NakedToggleOptionState<T> extends NakedState {
  /// The option's value.
  final T value;

  NakedToggleOptionState({required super.states, required this.value});

  /// Returns the nearest [NakedToggleOptionState] of the requested type.
  static NakedToggleOptionState<S> of<S>(BuildContext context) =>
      NakedState.of(context);

  /// Returns the nearest [NakedToggleOptionState] if available.
  static NakedToggleOptionState<S>? maybeOf<S>(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedToggleOptionState<T> &&
        setEquals(other.states, states) &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(states, value);
}

/// A headless binary toggle control without visuals.
///
/// Behaves as a toggle button or switch based on [asSwitch]. The builder receives
/// a [NakedToggleState] with the toggle value and interaction states.
///
/// ```dart
/// NakedToggle(
///   value: isToggled,
///   onChanged: (value) => setState(() => isToggled = value),
///   child: MyCustomToggleUI(),
/// )
/// ```
///
/// See also:
/// - [NakedCheckbox], for a boolean form control alternative.
/// - [NakedRadio], for exclusive selection among options.

class NakedToggle extends StatefulWidget {
  const NakedToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.child,
    this.enabled = true,
    this.mouseCursor,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
    this.builder,
    this.semanticLabel,
    this.asSwitch = false,
    this.excludeSemantics = false,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// The current selection state.
  final bool value;

  /// Called when selection changes.
  final ValueChanged<bool>? onChanged;

  /// The child widget; ignored if [builder] is provided.
  final Widget? child;

  /// Whether the control is interactive.
  final bool enabled;

  /// The mouse cursor when interactive.
  final MouseCursor? mouseCursor;

  /// Whether to provide platform feedback on interactions.
  final bool enableFeedback;

  /// The focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when the pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Builds the toggle using the current [NakedToggleState].
  final ValueWidgetBuilder<NakedToggleState>? builder;

  /// Semantic label for screen readers.
  final String? semanticLabel;

  /// Whether to use switch semantics instead of button semantics.
  final bool asSwitch;

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, the widget and its children are hidden from accessibility services.
  final bool excludeSemantics;

  bool get _effectiveEnabled => enabled && onChanged != null;

  @override
  State<NakedToggle> createState() => _NakedToggleState();
}

class _NakedToggleState extends State<NakedToggle>
    with WidgetStatesMixin<NakedToggle> {
  void _activate() {
    if (!widget._effectiveEnabled) return;

    if (widget.enableFeedback) {
      if (widget.asSwitch) {
        HapticFeedback.selectionClick();
      } else {
        Feedback.forTap(context);
      }
    }

    widget.onChanged?.call(!widget.value);
  }

  Widget _buildContent() {
    final toggleState = NakedToggleState(
      states: widgetStates,
      isToggled: widget.value,
    );

    return NakedStateScopeBuilder(
      value: toggleState,
      child: widget.child,
      builder: widget.builder,
    );
  }

  Widget _buildToggle() {
    Widget gestureDetector = GestureDetector(
      onTapDown: widget._effectiveEnabled
          ? (_) => updatePressState(true, widget.onPressChange)
          : null,
      onTapUp: widget._effectiveEnabled
          ? (_) => updatePressState(false, widget.onPressChange)
          : null,
      onTap: widget._effectiveEnabled ? _activate : null,
      onTapCancel: widget._effectiveEnabled
          ? () => updatePressState(false, widget.onPressChange)
          : null,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: _buildContent(),
    );

    return widget.excludeSemantics
        ? gestureDetector
        : Semantics(
            enabled: widget._effectiveEnabled,
            toggled: widget.value,
            button: !widget.asSwitch,
            label: widget.semanticLabel,
            onTap: widget._effectiveEnabled ? _activate : null,
            child: gestureDetector,
          );
  }

  MouseCursor get _effectiveCursor => widget._effectiveEnabled
      ? (widget.mouseCursor ?? SystemMouseCursors.click)
      : SystemMouseCursors.basic;

  @override
  void initializeWidgetStates() {
    updateDisabledState(!widget._effectiveEnabled);
    updateSelectedState(widget.value, null);
  }

  @override
  void didUpdateWidget(covariant NakedToggle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget._effectiveEnabled != widget._effectiveEnabled) {
      final nowDisabled = !widget._effectiveEnabled;
      updateDisabledState(nowDisabled);
      if (nowDisabled) {
        updateState(WidgetState.hovered, false);
        updateState(WidgetState.pressed, false);
        updateState(WidgetState.focused, false);
      }
    }

    if (oldWidget.value != widget.value) {
      updateSelectedState(widget.value, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NakedFocusableDetector(
      enabled: widget._effectiveEnabled,
      autofocus: widget.autofocus,
      onFocusChange: (f) => updateFocusState(f, widget.onFocusChange),
      onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
      focusNode: widget.focusNode,
      mouseCursor: _effectiveCursor,
      shortcuts: NakedIntentActions.toggle.shortcuts,
      actions: NakedIntentActions.toggle.actions(
        onToggle: () {
          if (widget._effectiveEnabled) {
            _activate();
          }
        },
      ),
      child: _buildToggle(),
    );
  }
}

/// Headless single-select toggle group (segmented control-like).
///
/// Provides an inherited scope for items to read `selectedValue` and call
/// `onChanged` when activated. No styling is provided.
class NakedToggleGroup<T> extends StatelessWidget {
  const NakedToggleGroup({
    super.key,
    required this.child,
    required this.selectedValue,
    this.onChanged,
    this.enabled = true,
  });

  /// The widget containing toggle options.
  final Widget child;

  /// The currently selected value.
  final T? selectedValue;

  /// Called when selection changes.
  final ValueChanged<T?>? onChanged;

  /// The enabled state of the group.
  final bool enabled;

  bool get _effectiveEnabled => enabled && onChanged != null;

  @override
  Widget build(BuildContext context) {
    return _ToggleScope<T>(
      selectedValue: selectedValue,
      onChanged: _effectiveEnabled ? onChanged : null,
      enabled: _effectiveEnabled,
      child: child,
    );
  }
}

class _ToggleScope<T> extends InheritedWidget {
  const _ToggleScope({
    required this.selectedValue,
    required this.onChanged,
    required this.enabled,
    required super.child,
  });

  static _ToggleScope<T>? maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType();
  static _ToggleScope<T> of<T>(BuildContext context) {
    final scope = maybeOf<T>(context);
    if (scope == null) {
      throw FlutterError(
        'NakedToggleGroup<$T> scope not found. Wrap options in NakedToggleGroup.',
      );
    }

    return scope;
  }

  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  bool isSelected(T value) => selectedValue == value;

  @override
  bool updateShouldNotify(_ToggleScope<T> old) {
    return selectedValue != old.selectedValue || enabled != old.enabled;
  }
}

/// A headless toggle option that participates in a [NakedToggleGroup].
///
/// Uses button-like semantics and exposes selected state via WidgetStates.
class NakedToggleOption<T> extends StatefulWidget {
  const NakedToggleOption({
    super.key,
    required this.value,
    this.child,
    this.enabled = true,
    this.mouseCursor,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
    this.builder,
    this.semanticLabel,
    this.excludeSemantics = false,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  final T value;
  final Widget? child;
  final bool enabled;
  final MouseCursor? mouseCursor;
  final bool enableFeedback;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onPressChange;
  final ValueWidgetBuilder<NakedToggleOptionState<T>>? builder;
  final String? semanticLabel;

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, the widget and its children are hidden from accessibility services.
  final bool excludeSemantics;

  @override
  State<NakedToggleOption<T>> createState() => _NakedToggleOptionState<T>();
}

class _NakedToggleOptionState<T> extends State<NakedToggleOption<T>>
    with WidgetStatesMixin<NakedToggleOption<T>> {
  void _activate(_ToggleScope<T> scope) {
    final isEnabled = scope.enabled && widget.enabled;
    if (!isEnabled) return;
    if (widget.enableFeedback) HapticFeedback.selectionClick();
    if (scope.onChanged != null && scope.selectedValue != widget.value) {
      scope.onChanged!(widget.value);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = _ToggleScope.of<T>(context);
    final isEnabled = scope.enabled && widget.enabled;
    updateDisabledState(!isEnabled);
    updateSelectedState(scope.selectedValue == widget.value, null);
  }

  @override
  void didUpdateWidget(covariant NakedToggleOption<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final scope = _ToggleScope.of<T>(context);
    updateDisabledState(!(scope.enabled && widget.enabled));

    // If *this item's* value changed identity, recompute selected.
    if (widget.value != oldWidget.value) {
      updateSelectedState(scope.selectedValue == widget.value, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _ToggleScope.of<T>(context);
    final isEnabled = scope.enabled && widget.enabled;
    final isSelected = scope.selectedValue == widget.value;

    final optionState = NakedToggleOptionState<T>(
      states: widgetStates,
      value: widget.value,
    );

    final content = widget.builder != null
        ? widget.builder!(context, optionState, widget.child)
        : widget.child!;

    final wrappedContent = NakedStateScope(value: optionState, child: content);

    final cursor = isEnabled
        ? (widget.mouseCursor ?? SystemMouseCursors.click)
        : SystemMouseCursors.basic;

    Widget gestureDetector = GestureDetector(
      onTapDown: isEnabled
          ? (_) => updatePressState(true, widget.onPressChange)
          : null,
      onTapUp: isEnabled
          ? (_) => updatePressState(false, widget.onPressChange)
          : null,
      onTap: isEnabled ? () => _activate(scope) : null,
      onTapCancel: isEnabled
          ? () => updatePressState(false, widget.onPressChange)
          : null,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: wrappedContent,
    );

    Widget optionChild = widget.excludeSemantics
        ? gestureDetector
        : Semantics(
            container: true,
            enabled: isEnabled,
            selected: isSelected,
            button: true,
            label: widget.semanticLabel,
            onTap: isEnabled ? () => _activate(scope) : null,
            child: gestureDetector,
          );

    return NakedFocusableDetector(
      enabled: isEnabled,
      autofocus: widget.autofocus,
      onFocusChange: (f) => updateFocusState(f, widget.onFocusChange),
      onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
      focusNode: widget.focusNode,
      mouseCursor: cursor,
      shortcuts: NakedIntentActions.toggle.shortcuts,
      actions: NakedIntentActions.toggle.actions(
        onToggle: () => _activate(scope),
      ),
      child: optionChild,
    );
  }
}
