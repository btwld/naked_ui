import 'dart:async';

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

  /// Creates an immutable snapshot of binary toggle state.
  NakedToggleState({required super.states, required this.isToggled});

  /// Returns the nearest [NakedToggleState] from context.
  static NakedToggleState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedToggleState] if available.
  static NakedToggleState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf<NakedToggleState>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf<NakedToggleState>(context);

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

  /// Creates an immutable snapshot for the option associated with [value].
  NakedToggleOptionState({required super.states, required this.value});

  /// Returns the nearest [NakedToggleOptionState] of the requested type.
  static NakedToggleOptionState<S> of<S>(BuildContext context) =>
      NakedState.of(context);

  /// Returns the nearest [NakedToggleOptionState] if available.
  static NakedToggleOptionState<S>? maybeOf<S>(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf<S>(BuildContext context) =>
      NakedState.controllerOf<NakedToggleOptionState<S>>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf<S>(BuildContext context) =>
      NakedState.maybeControllerOf<NakedToggleOptionState<S>>(context);

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
/// - [NakedCheckbox], for a boolean form control alternative.
/// - [NakedRadio], for exclusive selection among options.

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
        ? ExcludeSemantics(child: gestureDetector)
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
class NakedToggleGroup<T> extends StatefulWidget {
  /// Creates a single-select group controlled by [selectedValue].
  const NakedToggleGroup({
    super.key,
    required this.child,
    required this.selectedValue,
    this.onChanged,
    this.enabled = true,
    this.orientation = Axis.horizontal,
    this.loop = true,
    this.semanticLabel,
    this.excludeSemantics = false,
  });

  /// The widget containing toggle options.
  final Widget child;

  /// The currently selected value.
  final T? selectedValue;

  /// Called when selection changes.
  final ValueChanged<T?>? onChanged;

  /// The enabled state of the group.
  final bool enabled;

  /// The axis along which arrow keys move focus between options.
  final Axis orientation;

  /// Whether arrow-key focus movement wraps at either end of the group.
  final bool loop;

  /// The accessibility label for the group.
  final String? semanticLabel;

  /// Whether to hide the group and its options from accessibility services.
  final bool excludeSemantics;

  bool get _effectiveEnabled => enabled && onChanged != null;

  @override
  State<NakedToggleGroup<T>> createState() => _NakedToggleGroupState<T>();
}

class _NakedToggleGroupState<T> extends State<NakedToggleGroup<T>> {
  late final _ToggleGroupController<T> _controller = _ToggleGroupController<T>(
    this,
  );
  var _generation = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.updateConfiguration(
      selectedValue: widget.selectedValue,
      enabled: widget._effectiveEnabled,
      orientation: widget.orientation,
      loop: widget.loop,
      textDirection: Directionality.of(context),
    );

    Widget result = FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: _ToggleScope<T>(
        generation: ++_generation,
        controller: _controller,
        selectedValue: widget.selectedValue,
        onChanged: widget._effectiveEnabled ? widget.onChanged : null,
        enabled: widget._effectiveEnabled,
        child: widget.child,
      ),
    );

    result = widget.excludeSemantics
        ? ExcludeSemantics(child: result)
        : Semantics(
            container: true,
            explicitChildNodes: true,
            label: widget.semanticLabel,
            child: result,
          );

    return result;
  }
}

class _ToggleScope<T> extends InheritedWidget {
  const _ToggleScope({
    required this.generation,
    required this.controller,
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

  final int generation;
  final _ToggleGroupController<T> controller;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  bool isSelected(T value) => selectedValue == value;

  @override
  bool updateShouldNotify(_ToggleScope<T> old) {
    return generation != old.generation ||
        selectedValue != old.selectedValue ||
        enabled != old.enabled ||
        onChanged != old.onChanged;
  }
}

class _ToggleGroupEntry<T> {
  _ToggleGroupEntry(this.owner);

  final _NakedToggleOptionState<T> owner;
  late T value;
  var enabled = false;
  var autofocus = false;

  FocusNode get focusNode => owner.effectiveFocusNode;
}

class _ToggleGroupController<T> {
  _ToggleGroupController(this.owner);

  final _NakedToggleGroupState<T> owner;
  final List<_ToggleGroupEntry<T>> _entries = [];
  final List<_ToggleGroupEntry<T>> _orderedEntries = [];

  _ToggleGroupEntry<T>? _target;
  _ToggleGroupEntry<T>? _lastFocused;
  _ToggleGroupEntry<T>? _focusedEntry;
  T? _selectedValue;
  var _enabled = false;
  var _orientation = Axis.horizontal;
  var _loop = true;
  var _textDirection = TextDirection.ltr;
  var _reconcileScheduled = false;
  var _disposed = false;
  var _autofocusHandled = false;
  int? _repairSuccessorIndex;
  int? _repairPredecessorIndex;
  var _repairFocus = false;

  _ToggleGroupEntry<T> register(_NakedToggleOptionState<T> option) {
    final entry = _ToggleGroupEntry<T>(option);
    _entries.add(entry);
    _orderedEntries.add(entry);
    _scheduleReconcile();
    return entry;
  }

  void unregister(_ToggleGroupEntry<T> entry) {
    if (!_entries.contains(entry)) return;

    final oldIndex = _orderedEntries.indexOf(entry);
    final repairFocusedEntry =
        (entry.focusNode.hasFocus || identical(_focusedEntry, entry)) &&
        oldIndex >= 0;
    if (repairFocusedEntry) {
      _repairSuccessorIndex = oldIndex;
      _repairPredecessorIndex = oldIndex - 1;
      _repairFocus = true;
    }

    _entries.remove(entry);
    _orderedEntries.remove(entry);
    if (identical(_target, entry)) _target = null;
    if (identical(_lastFocused, entry)) _lastFocused = null;
    if (identical(_focusedEntry, entry)) _focusedEntry = null;
    if (repairFocusedEntry) {
      _repairFocusImmediately(
        successorIndex: oldIndex,
        predecessorIndex: oldIndex - 1,
      );
    } else {
      _choosePriorityTarget();
    }
    _scheduleReconcile();
  }

  void updateConfiguration({
    required T? selectedValue,
    required bool enabled,
    required Axis orientation,
    required bool loop,
    required TextDirection textDirection,
  }) {
    _selectedValue = selectedValue;
    _enabled = enabled;
    _orientation = orientation;
    _loop = loop;
    _textDirection = textDirection;
    _choosePriorityTarget();
    _scheduleReconcile();
  }

  void updateEntry(
    _ToggleGroupEntry<T> entry, {
    required T value,
    required bool enabled,
    required bool autofocus,
  }) {
    final wasEnabled = entry.enabled;
    final wasFocused =
        entry.focusNode.hasFocus || identical(_focusedEntry, entry);
    final oldIndex = _orderedEntries.indexOf(entry);
    final shouldRepairFocus =
        wasEnabled && !enabled && wasFocused && oldIndex >= 0;
    entry
      ..value = value
      ..enabled = enabled
      ..autofocus = autofocus;

    if (shouldRepairFocus) {
      _repairSuccessorIndex = oldIndex + 1;
      _repairPredecessorIndex = oldIndex - 1;
      _repairFocus = true;
    }

    if (!enabled) {
      if (identical(_target, entry)) _target = null;
      if (identical(_lastFocused, entry)) _lastFocused = null;
      if (identical(_focusedEntry, entry)) _focusedEntry = null;
    }

    if (shouldRepairFocus) {
      _repairFocusImmediately(
        successorIndex: oldIndex + 1,
        predecessorIndex: oldIndex - 1,
      );
    } else {
      _choosePriorityTarget(preferredEntry: entry);
    }
    _applyFocusability(entry);
    _scheduleReconcile();
  }

  bool isRovingTarget(_ToggleGroupEntry<T> entry) =>
      _enabled && entry.enabled && identical(_target, entry);

  void handleFocusChange(_ToggleGroupEntry<T> entry, bool focused) {
    if (focused && entry.enabled) {
      _focusedEntry = entry;
      _lastFocused = entry;
      _target = entry;
      _scheduleReconcile();
      return;
    }
    if (!focused && identical(_focusedEntry, entry)) {
      scheduleMicrotask(() {
        if (!_disposed &&
            identical(_focusedEntry, entry) &&
            !entry.focusNode.hasFocus) {
          _focusedEntry = null;
        }
      });
    }
  }

  void move(_ToggleGroupEntry<T> entry, int delta) {
    if (!entry.enabled || _orderedEntries.isEmpty) return;
    final currentIndex = _orderedEntries.indexOf(entry);
    if (currentIndex < 0) return;

    var index = currentIndex;
    for (var visited = 0; visited < _orderedEntries.length; visited++) {
      index += delta;
      if (index < 0 || index >= _orderedEntries.length) {
        if (!_loop) return;
        index = index < 0 ? _orderedEntries.length - 1 : 0;
      }

      final candidate = _orderedEntries[index];
      if (candidate.enabled) {
        _focus(candidate);
        return;
      }
    }
  }

  void focusFirst() {
    for (final entry in _orderedEntries) {
      if (entry.enabled) {
        _focus(entry);
        return;
      }
    }
  }

  void focusLast() {
    for (final entry in _orderedEntries.reversed) {
      if (entry.enabled) {
        _focus(entry);
        return;
      }
    }
  }

  int horizontalDeltaFor(LogicalKeyboardKey key) {
    final movesForward = key == LogicalKeyboardKey.arrowRight;
    if (_textDirection == TextDirection.rtl) {
      return movesForward ? -1 : 1;
    }
    return movesForward ? 1 : -1;
  }

  void _focus(_ToggleGroupEntry<T> entry) {
    if (!entry.enabled) return;
    _setTarget(entry);
    entry.focusNode.requestFocus();
  }

  void _repairFocusImmediately({
    required int successorIndex,
    required int predecessorIndex,
  }) {
    final repairTarget = _findRepairTarget(
      successorIndex: successorIndex,
      predecessorIndex: predecessorIndex,
    );

    if (repairTarget == null) {
      _setTarget(null);
      return;
    }
    _lastFocused = repairTarget;
    _setTarget(repairTarget);
    final node = repairTarget.focusNode;
    scheduleMicrotask(() {
      if (!_disposed &&
          repairTarget.owner.mounted &&
          identical(_target, repairTarget)) {
        node.requestFocus();
      }
    });
  }

  _ToggleGroupEntry<T>? _findRepairTarget({
    required int successorIndex,
    required int predecessorIndex,
  }) {
    for (var i = successorIndex; i < _orderedEntries.length; i++) {
      if (_orderedEntries[i].enabled) return _orderedEntries[i];
    }

    final lastIndex = _orderedEntries.length - 1;
    for (var i = predecessorIndex.clamp(-1, lastIndex); i >= 0; i--) {
      if (_orderedEntries[i].enabled) return _orderedEntries[i];
    }

    return null;
  }

  void _choosePriorityTarget({_ToggleGroupEntry<T>? preferredEntry}) {
    final validLastFocused =
        _lastFocused != null &&
        _entries.contains(_lastFocused) &&
        _lastFocused!.enabled;
    if (validLastFocused) {
      _setTarget(_lastFocused);
      return;
    }

    if (preferredEntry != null &&
        preferredEntry.enabled &&
        preferredEntry.value == _selectedValue) {
      _setTarget(preferredEntry);
      return;
    }

    for (final entry in _orderedEntries) {
      if (entry.enabled && entry.value == _selectedValue) {
        _setTarget(entry);
        return;
      }
    }

    if (_target != null && _entries.contains(_target) && _target!.enabled) {
      _applyAllFocusability();
      return;
    }

    for (final entry in _orderedEntries) {
      if (entry.enabled) {
        _setTarget(entry);
        return;
      }
    }
    _setTarget(null);
  }

  void _setTarget(_ToggleGroupEntry<T>? entry) {
    _target = entry;
    _applyAllFocusability();
  }

  void _applyAllFocusability() {
    for (final entry in _entries) {
      _applyFocusability(entry);
    }
  }

  void _applyFocusability(_ToggleGroupEntry<T> entry) {
    final isEnabled = _enabled && entry.enabled;
    entry.focusNode
      ..canRequestFocus = isEnabled
      ..skipTraversal = !isEnabled || !identical(_target, entry);
  }

  void _scheduleReconcile() {
    if (_disposed || _reconcileScheduled) return;
    _reconcileScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reconcileScheduled = false;
      if (!_disposed && owner.mounted) _reconcile();
    });
  }

  void _reconcile() {
    final attachedEntries = _entries
        .where(
          (entry) => entry.owner.mounted && entry.focusNode.context != null,
        )
        .toList();
    attachedEntries.sort((a, b) {
      final aRect = a.focusNode.rect;
      final bRect = b.focusNode.rect;
      if (_orientation == Axis.vertical) {
        final vertical = aRect.top.compareTo(bRect.top);
        if (vertical != 0) return vertical;
      } else {
        final horizontal = _textDirection == TextDirection.ltr
            ? aRect.left.compareTo(bRect.left)
            : bRect.right.compareTo(aRect.right);
        if (horizontal != 0) return horizontal;
      }
      return _entries.indexOf(a).compareTo(_entries.indexOf(b));
    });

    _orderedEntries
      ..clear()
      ..addAll(attachedEntries);

    final repairTarget = _repairFocus
        ? _findRepairTarget(
            successorIndex: _repairSuccessorIndex ?? 0,
            predecessorIndex: _repairPredecessorIndex ?? -1,
          )
        : null;

    final shouldRepairFocus = _repairFocus && repairTarget != null;
    _repairFocus = false;
    _repairSuccessorIndex = null;
    _repairPredecessorIndex = null;

    if (repairTarget != null) {
      _lastFocused = repairTarget;
      _setTarget(repairTarget);
      if (shouldRepairFocus) repairTarget.focusNode.requestFocus();
    } else {
      _choosePriorityTarget();
    }

    if (!_autofocusHandled &&
        _target != null &&
        _entries.any((entry) => entry.autofocus)) {
      _autofocusHandled = true;
      FocusScope.of(_target!.owner.context).autofocus(_target!.focusNode);
    }
  }

  void dispose() {
    _disposed = true;
    _entries.clear();
    _orderedEntries.clear();
    _target = null;
    _lastFocused = null;
    _focusedEntry = null;
  }
}

class _ToggleGroupMoveIntent extends Intent {
  const _ToggleGroupMoveIntent(this.delta);

  final int delta;
}

class _ToggleGroupFirstIntent extends Intent {
  const _ToggleGroupFirstIntent();
}

class _ToggleGroupLastIntent extends Intent {
  const _ToggleGroupLastIntent();
}

/// A headless toggle option that participates in a [NakedToggleGroup].
///
/// Uses button-like semantics and exposes selected state via WidgetStates.
class NakedToggleOption<T> extends StatefulWidget {
  /// Creates a headless group option associated with [value].
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

  /// The value selected when this option is activated.
  final T value;

  /// The option content when [builder] is not used.
  final Widget? child;

  /// Whether this option can be activated.
  final bool enabled;

  /// The cursor shown while hovering over an enabled option.
  final MouseCursor? mouseCursor;

  /// Whether activation provides platform feedback.
  final bool enableFeedback;

  /// The focus node used by this option.
  final FocusNode? focusNode;

  /// Whether this option requests focus when first built.
  final bool autofocus;

  /// Called when the option's focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when the pointer enters or leaves the option.
  final ValueChanged<bool>? onHoverChange;

  /// Called when the option's pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Builds the option from its current interaction and selection state.
  final ValueWidgetBuilder<NakedToggleOptionState<T>>? builder;

  /// The accessibility label for this option.
  final String? semanticLabel;

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, the widget and its children are hidden from accessibility services.
  final bool excludeSemantics;

  @override
  State<NakedToggleOption<T>> createState() => _NakedToggleOptionState<T>();
}

class _NakedToggleOptionState<T> extends State<NakedToggleOption<T>>
    with
        WidgetStatesMixin<NakedToggleOption<T>>,
        FocusNodeMixin<NakedToggleOption<T>> {
  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;

  _ToggleScope<T>? _scope;
  _ToggleGroupEntry<T>? _entry;
  bool? _lastEffectiveEnabled;
  var _effectiveEnabledGeneration = 0;

  void _activate(_ToggleScope<T> scope) {
    final isEnabled = scope.enabled && widget.enabled;
    if (!isEnabled) return;
    if (widget.enableFeedback) HapticFeedback.selectionClick();
    if (scope.onChanged != null && scope.selectedValue != widget.value) {
      scope.onChanged!(widget.value);
    }
  }

  void _updateEffectiveEnabled(bool isEnabled) {
    if (_lastEffectiveEnabled != isEnabled) {
      _lastEffectiveEnabled = isEnabled;
      _effectiveEnabledGeneration++;
    }
    final becameDisabled = updateDisabledState(!isEnabled) && !isEnabled;
    if (!becameDisabled) return;
    final generation = _effectiveEnabledGeneration;
    if (updateHoverState(false, null)) {
      _deferDisabledCallback(widget.onHoverChange, generation);
    }
    if (updatePressState(false, null)) {
      _deferDisabledCallback(widget.onPressChange, generation);
    }
    if (updateFocusState(false, null)) {
      _deferDisabledCallback(widget.onFocusChange, generation);
    }
  }

  void _deferDisabledCallback(ValueChanged<bool>? callback, int generation) {
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _effectiveEnabledGeneration == generation &&
          _lastEffectiveEnabled == false) {
        callback(false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = _ToggleScope.of<T>(context);
    if (!identical(_scope?.controller, scope.controller)) {
      final oldEntry = _entry;
      if (oldEntry != null) _scope?.controller.unregister(oldEntry);
      _entry = scope.controller.register(this);
    }
    _scope = scope;
    _syncEntry();
    final isEnabled = scope.enabled && widget.enabled;
    _updateEffectiveEnabled(isEnabled);
    updateSelectedState(scope.selectedValue == widget.value, null);
  }

  @override
  void didUpdateWidget(covariant NakedToggleOption<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final scope = _ToggleScope.of<T>(context);
    _scope = scope;
    _syncEntry();
    _updateEffectiveEnabled(scope.enabled && widget.enabled);

    // If *this item's* value changed identity, recompute selected.
    if (widget.value != oldWidget.value) {
      updateSelectedState(scope.selectedValue == widget.value, null);
    }
  }

  void _syncEntry() {
    final scope = _scope;
    final entry = _entry;
    if (scope == null || entry == null) return;
    scope.controller.updateEntry(
      entry,
      value: widget.value,
      enabled: scope.enabled && widget.enabled,
      autofocus: widget.autofocus,
    );
  }

  @override
  void dispose() {
    final entry = _entry;
    if (entry != null) _scope?.controller.unregister(entry);
    _entry = null;
    _scope = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _ToggleScope.of<T>(context);
    _scope = scope;
    _syncEntry();
    final entry = _entry!;
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
        ? ExcludeSemantics(child: gestureDetector)
        : Semantics(
            container: true,
            enabled: isEnabled,
            selected: isSelected,
            button: true,
            label: widget.semanticLabel,
            onTap: isEnabled ? () => _activate(scope) : null,
            child: gestureDetector,
          );

    final shortcuts = <ShortcutActivator, Intent>{
      ...NakedIntentActions.toggle.shortcuts,
      if (scope.controller._orientation == Axis.horizontal) ...{
        const SingleActivator(
          LogicalKeyboardKey.arrowLeft,
        ): _ToggleGroupMoveIntent(
          scope.controller.horizontalDeltaFor(LogicalKeyboardKey.arrowLeft),
        ),
        const SingleActivator(
          LogicalKeyboardKey.arrowRight,
        ): _ToggleGroupMoveIntent(
          scope.controller.horizontalDeltaFor(LogicalKeyboardKey.arrowRight),
        ),
      } else ...{
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const _ToggleGroupMoveIntent(-1),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const _ToggleGroupMoveIntent(1),
      },
      const SingleActivator(LogicalKeyboardKey.home):
          const _ToggleGroupFirstIntent(),
      const SingleActivator(LogicalKeyboardKey.end):
          const _ToggleGroupLastIntent(),
    };
    final actions = <Type, Action<Intent>>{
      ...NakedIntentActions.toggle.actions(onToggle: () => _activate(scope)),
      _ToggleGroupMoveIntent: CallbackAction<_ToggleGroupMoveIntent>(
        onInvoke: (intent) => scope.controller.move(entry, intent.delta),
      ),
      _ToggleGroupFirstIntent: CallbackAction<_ToggleGroupFirstIntent>(
        onInvoke: (_) => scope.controller.focusFirst(),
      ),
      _ToggleGroupLastIntent: CallbackAction<_ToggleGroupLastIntent>(
        onInvoke: (_) => scope.controller.focusLast(),
      ),
    };

    return NakedFocusableDetector(
      enabled: isEnabled,
      autofocus: false,
      canRequestFocus: isEnabled,
      skipTraversal: !scope.controller.isRovingTarget(entry),
      onFocusChange: (f) {
        scope.controller.handleFocusChange(entry, f);
        updateFocusState(f, widget.onFocusChange);
      },
      onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
      focusNode: effectiveFocusNode,
      mouseCursor: cursor,
      shortcuts: shortcuts,
      actions: actions,
      child: optionChild,
    );
  }
}
