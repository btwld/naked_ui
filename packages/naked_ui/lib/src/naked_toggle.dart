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

  /// Creates a toggle state snapshot.
  NakedToggleState({required super.states, required this.isToggled});

  /// Returns the nearest [NakedToggleState] from context.
  static NakedToggleState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedToggleState] if available.
  static NakedToggleState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOfType<NakedToggleState>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOfType<NakedToggleState>(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedToggleState &&
        statesEqual(other) &&
        other.isToggled == isToggled;
  }

  @override
  int get hashCode => Object.hash(statesHashCode, isToggled);
}

/// Immutable view passed to [NakedToggleOption.builder].
class NakedToggleOptionState<T> extends NakedState {
  /// The option's value.
  final T value;

  /// Creates a toggle-option state snapshot for [value].
  NakedToggleOptionState({required super.states, required this.value});

  /// Returns the nearest [NakedToggleOptionState] of the requested type.
  static NakedToggleOptionState<S> of<S>(BuildContext context) =>
      NakedState.of(context);

  /// Returns the nearest [NakedToggleOptionState] if available.
  static NakedToggleOptionState<S>? maybeOf<S>(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOfType<NakedToggleOptionState<dynamic>>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOfType<NakedToggleOptionState<dynamic>>(
        context,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedToggleOptionState<T> &&
        statesEqual(other) &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(statesHashCode, value);
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
/// - `NakedCheckbox`, for a boolean form control alternative.
/// - `NakedRadio`, for exclusive selection among options.
class NakedToggle extends StatefulWidget {
  /// Creates a headless binary toggle controlled by [value].
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

  /// Whether to omit the semantics contributed by [NakedToggle].
  ///
  /// Semantics supplied by [child] or [builder] remain available.
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
      builder: widget.builder,
      child: widget.child,
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
            excludeSemantics: widget.semanticLabel != null,
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
        clearInteractionStates(
          onHoverChange: widget.onHoverChange,
          onFocusChange: widget.onFocusChange,
          onPressChange: widget.onPressChange,
        );
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
      shortcuts: NakedIntentActions.buttonShortcuts,
      actions: NakedIntentActions.toggleActions(
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
  /// Creates a single-selection group around [child].
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

  static _ToggleScope<dynamic>? maybeOf(BuildContext context) {
    final exact = context
        .dependOnInheritedWidgetOfExactType<_ToggleScope<dynamic>>();
    if (exact != null) return exact;

    _ToggleScope<dynamic>? covariantMatch;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is _ToggleScope<dynamic>) {
        context.dependOnInheritedElement(element as InheritedElement);
        covariantMatch = widget;
        return false;
      }
      return true;
    });
    return covariantMatch;
  }

  static _ToggleScope<dynamic> of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw FlutterError(
        'NakedToggleGroup scope not found. Wrap options in NakedToggleGroup.',
      );
    }

    return scope;
  }

  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  bool isSelected(T value) => selectedValue == value;

  void select(Object? value) => onChanged?.call(value as T?);

  @override
  bool updateShouldNotify(_ToggleScope<T> old) {
    return selectedValue != old.selectedValue ||
        enabled != old.enabled ||
        onChanged != old.onChanged;
  }
}

/// A headless toggle option that participates in a [NakedToggleGroup].
///
/// Uses button-like semantics and exposes selected state via WidgetStates.
class NakedToggleOption<T> extends StatefulWidget {
  /// Creates an option representing [value].
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

  /// The value represented by this option.
  final T value;

  /// The option content when [builder] is not provided.
  final Widget? child;

  /// Whether this option can be selected.
  final bool enabled;

  /// The mouse cursor when the option is interactive.
  final MouseCursor? mouseCursor;

  /// Whether activation produces platform feedback.
  final bool enableFeedback;

  /// The focus node for this option.
  final FocusNode? focusNode;

  /// Whether this option requests focus initially.
  final bool autofocus;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when the pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Builds the option from its current state.
  final ValueWidgetBuilder<NakedToggleOptionState<T>>? builder;

  /// Replaces the option content's accessible name when non-null.
  final String? semanticLabel;

  /// Whether to omit the semantics contributed by [NakedToggleOption].
  ///
  /// Semantics supplied by [child] or [builder] remain available.
  final bool excludeSemantics;

  @override
  State<NakedToggleOption<T>> createState() => _NakedToggleOptionState<T>();
}

class _NakedToggleOptionState<T> extends State<NakedToggleOption<T>>
    with WidgetStatesMixin<NakedToggleOption<T>> {
  void _activate(_ToggleScope<dynamic> scope) {
    final isEnabled = scope.enabled && widget.enabled;
    if (!isEnabled) return;
    if (widget.enableFeedback) HapticFeedback.selectionClick();
    if (scope.selectedValue != widget.value) {
      scope.select(widget.value);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = _ToggleScope.of(context);
    final isEnabled = scope.enabled && widget.enabled;
    final wasEnabled = !isDisabled;
    updateDisabledState(!isEnabled);
    updateSelectedState(scope.selectedValue == widget.value, null);
    if (wasEnabled && !isEnabled) {
      clearInteractionStates(
        onHoverChange: widget.onHoverChange,
        onFocusChange: widget.onFocusChange,
        onPressChange: widget.onPressChange,
      );
    }
  }

  @override
  void didUpdateWidget(covariant NakedToggleOption<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final scope = _ToggleScope.of(context);
    final isEnabled = scope.enabled && widget.enabled;
    final wasEnabled = !isDisabled;
    updateDisabledState(!isEnabled);
    if (wasEnabled && !isEnabled) {
      clearInteractionStates(
        onHoverChange: widget.onHoverChange,
        onFocusChange: widget.onFocusChange,
        onPressChange: widget.onPressChange,
      );
    }

    // If *this item's* value changed identity, recompute selected.
    if (widget.value != oldWidget.value) {
      updateSelectedState(scope.selectedValue == widget.value, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _ToggleScope.of(context);
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
            excludeSemantics: widget.semanticLabel != null,
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
      shortcuts: NakedIntentActions.buttonShortcuts,
      actions: NakedIntentActions.toggleActions(
        onToggle: () => _activate(scope),
      ),
      child: optionChild,
    );
  }
}
