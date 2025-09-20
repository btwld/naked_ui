import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/widget_state_snapshot.dart';

/// Immutable view passed to [NakedToggle.builder].
class NakedToggleState extends NakedWidgetState {
  /// Whether the toggle is currently on.
  final bool isToggled;

  NakedToggleState({required super.states, required this.isToggled});
}

/// Immutable view passed to [NakedToggleOption.builder].
class NakedToggleOptionState<T> extends NakedWidgetState {
  /// The option's value.
  final T value;

  /// The currently selected value from the surrounding toggle group.
  final T? selectedValue;

  NakedToggleOptionState({
    required super.states,
    required this.value,
    required this.selectedValue,
  });

  /// Whether this option matches the current selection.
  bool get isCurrentSelection =>
      selectedValue != null && value == selectedValue;
}

/// A headless binary toggle control without visuals.
///
/// Behaves as toggle button or switch based on [asSwitch]. Builder receives
/// [NakedToggleState] with toggle value and interaction states.
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

  /// The interactive state of the control.
  final bool enabled;

  /// The mouse cursor when interactive.
  final MouseCursor? mouseCursor;

  /// The platform feedback enablement flag.
  final bool enableFeedback;

  /// The focus node.
  final FocusNode? focusNode;

  /// The autofocus flag.
  final bool autofocus;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when press changes.
  final ValueChanged<bool>? onPressChange;

  /// The builder that receives current toggle state.
  final NakedStateBuilder<NakedToggleState>? builder;

  /// The semantic label for screen readers.
  final String? semanticLabel;

  /// The switch semantics flag instead of button semantics.
  final bool asSwitch;

  bool get _effectiveEnabled => enabled && onChanged != null;

  @override
  State<NakedToggle> createState() => _NakedToggleState();
}

class _NakedToggleState extends State<NakedToggle>
    with WidgetStatesMixin<NakedToggle> {
  // Keyboard activation handled inline in actions.onInvoke.

  void _activate() {
    if (!widget._effectiveEnabled) return;

    // Use appropriate feedback based on widget type
    if (widget.enableFeedback) {
      if (widget.asSwitch) {
        HapticFeedback.selectionClick();
      } else {
        Feedback.forTap(context);
      }
    }

    widget.onChanged?.call(!widget.value);
  }

  Widget _buildContent(BuildContext context) {
    final toggleState = NakedToggleState(
      states: widgetStates,
      isToggled: widget.value,
    );

    return widget.builder != null
        ? widget.builder!(context, toggleState, widget.child)
        : widget.child!;
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
        // Keep state set consistent with reality when disabling.
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
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget._effectiveEnabled ? _activate() : null,
        ),
      },
      child: Semantics(
        enabled: widget._effectiveEnabled,
        toggled: widget.value,
        button: !widget.asSwitch,
        label: widget.semanticLabel,
        onTap: widget._effectiveEnabled ? _activate : null,
        child: GestureDetector(
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
          child: _buildContent(context),
        ),
      ),
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

  // Fix: use the class generic T, not a new type parameter.
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
  final NakedStateBuilder<NakedToggleOptionState<T>>? builder;
  final String? semanticLabel;

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
    // When the group's selectedValue changes, didChangeDependencies() will run
    // because _ToggleScope<T>.updateShouldNotify returned true.
  }

  @override
  Widget build(BuildContext context) {
    final scope = _ToggleScope.of<T>(context);
    final isEnabled = scope.enabled && widget.enabled;
    final isSelected = scope.selectedValue == widget.value;

    final optionState = NakedToggleOptionState<T>(
      states: widgetStates,
      value: widget.value,
      selectedValue: scope.selectedValue,
    );

    final content = widget.builder != null
        ? widget.builder!(context, optionState, widget.child)
        : widget.child!;

    final cursor = isEnabled
        ? (widget.mouseCursor ?? SystemMouseCursors.click)
        : SystemMouseCursors.basic;

    return NakedFocusableDetector(
      enabled: isEnabled,
      autofocus: widget.autofocus,
      onFocusChange: (f) => updateFocusState(f, widget.onFocusChange),
      onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
      focusNode: widget.focusNode,
      mouseCursor: cursor,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => _activate(scope),
        ),
      },
      child: Semantics(
        container: true,
        enabled: isEnabled,
        selected: isSelected,
        button: true,
        label: widget.semanticLabel,
        onTap: isEnabled ? () => _activate(scope) : null,
        child: GestureDetector(
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
          child: content,
        ),
      ),
    );
  }
}
