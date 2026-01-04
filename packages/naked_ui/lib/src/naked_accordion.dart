import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/state.dart';

/// Immutable state exposed to a [NakedAccordionGroup] container.
class NakedAccordionGroupState extends NakedState {
  /// Number of currently expanded items.
  final int expandedCount;

  /// Whether more items can be expanded based on [maxExpanded].
  final bool canExpandMore;

  /// Whether items can be collapsed based on [minExpanded].
  final bool canCollapseMore;

  /// The minimum number of expanded items allowed.
  final int minExpanded;

  /// The maximum number of expanded items allowed (null = unlimited).
  final int? maxExpanded;

  NakedAccordionGroupState._({
    required super.states,
    required this.expandedCount,
    required this.canExpandMore,
    required this.canCollapseMore,
    required this.minExpanded,
    required this.maxExpanded,
  });

  factory NakedAccordionGroupState({
    required Set<WidgetState> states,
    required int expandedCount,
    required int minExpanded,
    int? maxExpanded,
  }) {
    final canExpandMore = maxExpanded == null || expandedCount < maxExpanded;
    final canCollapseMore = expandedCount > minExpanded;

    return NakedAccordionGroupState._(
      states: states,
      expandedCount: expandedCount,
      canExpandMore: canExpandMore,
      canCollapseMore: canCollapseMore,
      minExpanded: minExpanded,
      maxExpanded: maxExpanded,
    );
  }

  /// Returns the nearest [NakedAccordionGroupState] from context.
  static NakedAccordionGroupState of(BuildContext context) =>
      NakedState.of(context);

  /// Returns the nearest [NakedAccordionGroupState] if available.
  static NakedAccordionGroupState? maybeOf(BuildContext context) =>
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

    return other is NakedAccordionGroupState &&
        statesEqual(other) &&
        other.expandedCount == expandedCount &&
        other.canExpandMore == canExpandMore &&
        other.canCollapseMore == canCollapseMore &&
        other.minExpanded == minExpanded &&
        other.maxExpanded == maxExpanded;
  }

  @override
  int get hashCode => Object.hash(
    statesHashCode,
    expandedCount,
    canExpandMore,
    canCollapseMore,
    minExpanded,
    maxExpanded,
  );
}

/// Immutable state exposed to a [NakedAccordion] trigger builder.
class NakedAccordionItemState<T> extends NakedState {
  /// The item's unique identifier.
  final T value;

  /// Whether this item is currently expanded.
  final bool isExpanded;

  /// Whether this item can be collapsed while honoring [NakedAccordionController.min].
  final bool canCollapse;

  /// Whether this item can be expanded while honoring [NakedAccordionController.max].
  final bool canExpand;

  NakedAccordionItemState({
    required super.states,
    required this.value,
    required this.isExpanded,
    required this.canCollapse,
    required this.canExpand,
  });

  /// Returns the nearest [NakedAccordionItemState] of the requested type.
  static NakedAccordionItemState<S> of<S>(BuildContext context) =>
      NakedState.of<NakedAccordionItemState<S>>(context);

  /// Returns the nearest [NakedAccordionItemState] if available.
  static NakedAccordionItemState<S>? maybeOf<S>(BuildContext context) =>
      NakedState.maybeOf<NakedAccordionItemState<S>>(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedAccordionItemState<T> &&
        statesEqual(other) &&
        other.value == value &&
        other.isExpanded == isExpanded &&
        other.canCollapse == canCollapse &&
        other.canExpand == canExpand;
  }

  @override
  int get hashCode =>
      Object.hash(statesHashCode, value, isExpanded, canCollapse, canExpand);
}

/// Maintains accordion expansion state without imposing visuals.
///
/// Enforces optional [min] and [max] constraints and exposes helper methods for
/// updating the expanded set.
///
/// See also:
/// - [NakedAccordionGroup], the container that uses this controller.
class NakedAccordionController<T> with ChangeNotifier {
  /// Minimum number of expanded items allowed when closing.
  final int min;

  /// Maximum number of expanded items allowed.
  ///
  /// When `null`, expansion count is unlimited.
  final int? max;

  /// Expanded values tracked in insertion order (oldest → newest).
  final LinkedHashSet<T> values = LinkedHashSet<T>();

  NakedAccordionController({this.min = 0, this.max})
    : assert(min >= 0, 'min must be >= 0'),
      assert(max == null || max >= min, 'max must be >= min');

  /// Reports whether the item with [value] is currently expanded.
  bool contains(T value) => values.contains(value);

  /// Opens [value], evicting the oldest entry when [max] is reached.
  void open(T value) {
    if (values.contains(value)) return; // no-op
    final maxValue = max;
    if (maxValue == 0) return; // never allow expands when max is zero
    if (maxValue != null && values.length >= maxValue) {
      // Close oldest to make room.
      if (values.isNotEmpty) {
        final oldest = values.first;
        values.remove(oldest);
      }
    }
    values.add(value);
    notifyListeners();
  }

  /// Closes [value] while respecting the [min] floor.
  void close(T value) {
    if (!values.contains(value)) return; // no-op
    if (min > 0 && values.length <= min) return; // floor
    values.remove(value);
    notifyListeners();
  }

  /// Toggles [value], applying both [min] and [max] constraints.
  void toggle(T value) {
    if (values.contains(value)) {
      close(value); // close() will notify
    } else {
      open(value); // open() will notify
    }
  }

  /// Removes all expanded values but preserves the first [min] entries.
  void clear() {
    if (values.isEmpty) return;
    if (min <= 0) {
      values.clear();
      notifyListeners();

      return;
    }
    if (values.length <= min) return; // already at/under floor
    final keep = values.take(min).toList(growable: false);
    values
      ..clear()
      ..addAll(keep);
    notifyListeners();
  }

  /// Opens [newValues] in order without exceeding [max], preserving FIFO.
  void openAll(Iterable<T> newValues) {
    final maxValue = max;
    if (maxValue == 0) return;
    var changed = false;
    for (final v in newValues) {
      if (values.contains(v)) continue;
      if (maxValue != null && values.length >= maxValue) {
        if (values.isNotEmpty) {
          final oldest = values.first;
          values.remove(oldest);
        }
      }
      values.add(v);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Replaces all expanded values with [newValues], respecting [max].
  ///
  /// This may produce fewer than [min] expanded items because it is a direct
  /// programmatic update. User-initiated closing still honors [min].
  void replaceAll(Iterable<T> newValues) {
    final target = (max != null) ? newValues.take(max!) : newValues;
    final next = LinkedHashSet<T>.of(target);
    if (setEquals(values, next)) return; // no change
    values
      ..clear()
      ..addAll(next);
    notifyListeners();
  }
}

/// Immutable snapshot of accordion expansion state at a point in time.
///
/// Used by [NakedAccordionScope] to enable selective rebuilds via
/// [InheritedModel]. Each accordion item depends only on its own value
/// as an "aspect", so only affected items rebuild when state changes.
@immutable
class _AccordionSnapshot<T> {
  const _AccordionSnapshot({
    required this.expandedValues,
    required this.controller,
  });

  /// Set of currently expanded values (immutable snapshot).
  final Set<T> expandedValues;

  /// The controller (for accessing min/max constraints).
  final NakedAccordionController<T> controller;

  /// Check if a specific value is expanded.
  bool isExpanded(T value) => expandedValues.contains(value);

  /// Whether the item can be collapsed (respecting min constraint).
  bool canCollapse(T value) =>
      isExpanded(value) && expandedValues.length > controller.min;

  /// Whether the item can be expanded (respecting max constraint).
  bool canExpand(T value) =>
      !isExpanded(value) &&
      (controller.max == null || expandedValues.length < controller.max!);
}

/// Provides accordion state to descendant widgets with selective rebuilds.
///
/// Uses [InheritedModel] pattern (like Flutter's [MediaQuery]) to ensure
/// each accordion item only rebuilds when its own expansion state changes,
/// not when other items change. This reduces O(n) rebuilds to O(1).
///
/// ## How It Works
///
/// Each [NakedAccordion] item specifies its value as an "aspect" when
/// accessing the scope. The [updateShouldNotifyDependent] method checks
/// if that specific value's state changed, enabling surgical rebuilds.
///
/// ## Example
///
/// ```dart
/// // Internal usage - items use aspectOf for selective dependency
/// final isExpanded = NakedAccordionScope.isExpandedOf<String>(context, 'section1');
/// ```
///
/// See also:
/// - [InheritedModel], Flutter's selective rebuild mechanism
/// - [MediaQuery], which uses the same pattern for size/padding aspects
class NakedAccordionScope<T> extends InheritedModel<T> {
  const NakedAccordionScope({
    super.key,
    required this.snapshot,
    required super.child,
  });

  /// The immutable snapshot of current accordion state.
  final _AccordionSnapshot<T> snapshot;

  /// Returns the nearest [NakedAccordionScope] without creating a dependency.
  ///
  /// Use this when you need the controller but don't want to rebuild
  /// when expansion state changes.
  static NakedAccordionScope<T>? maybeOf<T>(BuildContext context) {
    return context.getInheritedWidgetOfExactType<NakedAccordionScope<T>>();
  }

  /// Returns the nearest [NakedAccordionScope], throwing when absent.
  ///
  /// Use this when you need the controller but don't want to rebuild
  /// when expansion state changes.
  static NakedAccordionScope<T> of<T>(BuildContext context) {
    final scope = maybeOf<T>(context);
    if (scope == null) {
      throw StateError('NakedAccordionScope<$T> not found in context.');
    }
    return scope;
  }

  /// Returns whether [value] is expanded, creating an aspect-based dependency.
  ///
  /// The calling widget will only rebuild when this specific value's
  /// expansion state changes, not when other items change.
  ///
  /// This is the primary method for accordion items to check their state.
  static bool isExpandedOf<T extends Object>(BuildContext context, T value) {
    final scope = InheritedModel.inheritFrom<NakedAccordionScope<T>>(
      context,
      aspect: value,
    );
    if (scope == null) {
      throw StateError('NakedAccordionScope<$T> not found in context.');
    }
    return scope.snapshot.isExpanded(value);
  }

  /// Returns whether [value] can be collapsed, creating an aspect-based dependency.
  static bool canCollapseOf<T extends Object>(BuildContext context, T value) {
    final scope = InheritedModel.inheritFrom<NakedAccordionScope<T>>(
      context,
      aspect: value,
    );
    if (scope == null) {
      throw StateError('NakedAccordionScope<$T> not found in context.');
    }
    return scope.snapshot.canCollapse(value);
  }

  /// Returns whether [value] can be expanded, creating an aspect-based dependency.
  static bool canExpandOf<T extends Object>(BuildContext context, T value) {
    final scope = InheritedModel.inheritFrom<NakedAccordionScope<T>>(
      context,
      aspect: value,
    );
    if (scope == null) {
      throw StateError('NakedAccordionScope<$T> not found in context.');
    }
    return scope.snapshot.canExpand(value);
  }

  /// Returns the controller without creating a rebuild dependency.
  NakedAccordionController<T> get controller => snapshot.controller;

  @override
  bool updateShouldNotify(covariant NakedAccordionScope<T> oldWidget) {
    // Always check dependents - the fine-grained logic is in updateShouldNotifyDependent.
    // This returns true if ANY expansion state changed.
    return !setEquals(
          snapshot.expandedValues,
          oldWidget.snapshot.expandedValues,
        ) ||
        snapshot.controller != oldWidget.snapshot.controller;
  }

  @override
  bool updateShouldNotifyDependent(
    covariant NakedAccordionScope<T> oldWidget,
    Set<T> dependencies,
  ) {
    // Only notify dependents whose specific aspect (value) changed.
    // This is the key optimization: O(affected items) instead of O(n).
    for (final value in dependencies) {
      final wasExpanded = oldWidget.snapshot.isExpanded(value);
      final isNowExpanded = snapshot.isExpanded(value);
      if (wasExpanded != isNowExpanded) {
        return true;
      }

      // Also check constraint changes that affect this item.
      final couldCollapse = oldWidget.snapshot.canCollapse(value);
      final canNowCollapse = snapshot.canCollapse(value);
      if (couldCollapse != canNowCollapse) {
        return true;
      }

      final couldExpand = oldWidget.snapshot.canExpand(value);
      final canNowExpand = snapshot.canExpand(value);
      if (couldExpand != canNowExpand) {
        return true;
      }
    }
    return false;
  }
}

/// A headless accordion without visuals.
///
/// Contains expandable/collapsible sections managed by
/// [NakedAccordionController].
///
/// ```dart
/// final controller = NakedAccordionController<String>();
/// NakedAccordionGroup<String>(
///   controller: controller,
///   children: [
///     NakedAccordion(
///       value: 'section1',
///       builder: (context, state) => Text('Section 1'),
///       child: Text('Content 1'),
///     ),
///   ],
/// )
/// ```
///
/// See also:
/// - [ExpansionPanelList], the Material-styled accordion for typical apps.
class NakedAccordionGroup<T> extends StatefulWidget {
  const NakedAccordionGroup({
    super.key,
    required this.child,
    required this.controller,
    this.initialExpandedValues = const [],
  });

  /// Accordion items to render.
  final Widget child;

  /// Controller that manages expanded values.
  final NakedAccordionController<T> controller;

  /// Values expanded on the first build when the controller is empty.
  ///
  /// Updated values apply only while the controller remains empty to avoid
  /// clobbering user interaction.
  final List<T> initialExpandedValues;

  @override
  State<NakedAccordionGroup<T>> createState() => _NakedAccordionGroupState<T>();
}

class _NakedAccordionGroupState<T> extends State<NakedAccordionGroup<T>> {
  NakedAccordionController<T> get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (widget.initialExpandedValues.isNotEmpty && _controller.values.isEmpty) {
      _controller.replaceAll(widget.initialExpandedValues);
    }
  }

  @override
  void didUpdateWidget(covariant NakedAccordionGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
          oldWidget.initialExpandedValues,
          widget.initialExpandedValues,
        ) &&
        _controller.values.isEmpty) {
      _controller.replaceAll(widget.initialExpandedValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder triggers rebuild when controller notifies.
    // NakedAccordionScope (InheritedModel) then provides selective rebuilds
    // to individual accordion items based on their value aspect.
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        // Create immutable snapshot for InheritedModel comparison.
        final snapshot = _AccordionSnapshot<T>(
          expandedValues: Set<T>.of(_controller.values),
          controller: _controller,
        );

        return NakedStateScope(
          value: NakedAccordionGroupState(
            states: const {},
            expandedCount: _controller.values.length,
            minExpanded: _controller.min,
            maxExpanded: _controller.max,
          ),
          child: NakedAccordionScope<T>(
            snapshot: snapshot,
            child: FocusTraversalGroup(child: widget.child),
          ),
        );
      },
    );
  }
}

typedef NakedAccordionTriggerBuilder<T> =
    Widget Function(BuildContext context, NakedAccordionItemState<T> state);

/// A headless accordion item with a customizable trigger and panel.
///
/// The [builder] receives a [NakedAccordionItemState] that includes
/// expansion status, constraint affordances, and interaction states.
///
/// See also:
/// - [NakedAccordionGroup], the container that manages accordion items.
class NakedAccordion<T extends Object> extends StatefulWidget {
  const NakedAccordion({
    super.key,
    required this.builder,
    required this.value,
    required this.child,
    this.transitionBuilder,
    this.enabled = true,
    this.mouseCursor = SystemMouseCursors.click,
    this.enableFeedback = true,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
    this.semanticLabel,
    this.excludeSemantics = false,
  });

  /// Builds the header or trigger for the item.
  final NakedAccordionTriggerBuilder<T> builder;

  /// Optional transition builder applied to the expanding panel.
  final Widget Function(Widget panel)? transitionBuilder;

  /// Content rendered while expanded.
  final Widget child;

  /// Unique identifier tracked by the controller.
  final T value;

  /// Called when the header's focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when the header's hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when the header's pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Semantic label announced for the header.
  final String? semanticLabel;

  /// Whether the header is interactive.
  final bool enabled;

  /// Mouse cursor to use when interactive.
  final MouseCursor mouseCursor;

  /// Whether to provide platform feedback on interactions.
  final bool enableFeedback;

  /// Whether the header should autofocus.
  final bool autofocus;

  /// Focus node associated with the header.
  final FocusNode? focusNode;

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, the widget and its children are hidden from accessibility services.
  final bool excludeSemantics;

  @override
  State<NakedAccordion<T>> createState() => _NakedAccordionState<T>();
}

class _NakedAccordionState<T extends Object> extends State<NakedAccordion<T>>
    with WidgetStatesMixin<NakedAccordion<T>> {
  // No manual caching needed - InheritedModel handles selective rebuilds.
  // Each accordion item depends on its value as an "aspect", so only
  // affected items rebuild when expansion state changes.

  void _toggle(NakedAccordionController<T> controller) =>
      controller.toggle(widget.value);

  @override
  void initializeWidgetStates() {
    updateDisabledState(!widget.enabled);
  }

  @override
  void didUpdateWidget(covariant NakedAccordion<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      updateDisabledState(!widget.enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use aspect-based dependency via InheritedModel.
    // This widget only rebuilds when THIS item's expansion state changes,
    // not when other accordion items change. This is the Flutter-idiomatic
    // pattern used by MediaQuery for selective rebuilds.
    final isExpanded = NakedAccordionScope.isExpandedOf<T>(
      context,
      widget.value,
    );
    final canCollapse = NakedAccordionScope.canCollapseOf<T>(
      context,
      widget.value,
    );
    final canExpand = NakedAccordionScope.canExpandOf<T>(context, widget.value);

    // Get controller without creating a dependency (for toggle action).
    final scope = NakedAccordionScope.of<T>(context);
    final controller = scope.controller;

    // Build the panel only when expanded.
    final Widget panel = isExpanded ? widget.child : const SizedBox.shrink();

    void onTap() {
      if (!widget.enabled) return;
      if (widget.enableFeedback) Feedback.forTap(context);
      _toggle(controller);
    }

    final accordionState = NakedAccordionItemState<T>(
      states: widgetStates,
      value: widget.value,
      isExpanded: isExpanded,
      canCollapse: canCollapse,
      canExpand: canExpand,
    );

    Widget triggerContent = GestureDetector(
      onTapDown: (widget.enabled && widget.onPressChange != null)
          ? (_) => updatePressState(true, widget.onPressChange)
          : null,
      onTapUp: (widget.enabled && widget.onPressChange != null)
          ? (_) => updatePressState(false, widget.onPressChange)
          : null,
      onTap: widget.enabled ? onTap : null,
      onTapCancel: (widget.enabled && widget.onPressChange != null)
          ? () => updatePressState(false, widget.onPressChange)
          : null,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: ExcludeSemantics(
        child: NakedStateScopeBuilder(
          value: accordionState,
          builder: (context, accordionState, child) =>
              widget.builder(context, accordionState),
        ),
      ),
    );

    Widget accordionChild = widget.excludeSemantics
        ? triggerContent
        : Semantics(
            enabled: widget.enabled,
            label: widget.semanticLabel,
            onTap: widget.enabled ? onTap : null,
            child: triggerContent,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NakedFocusableDetector(
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          onFocusChange: (f) => updateFocusState(f, widget.onFocusChange),
          onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
          focusNode: widget.focusNode,
          mouseCursor: widget.enabled
              ? widget.mouseCursor
              : SystemMouseCursors.basic,
          shortcuts: NakedIntentActions.accordion.shortcuts,
          actions: NakedIntentActions.accordion.actions(onToggle: onTap),
          child: accordionChild,
        ),
        NakedStateScopeBuilder(
          value: accordionState,
          builder: (context, accordionState, child) =>
              widget.transitionBuilder != null
              ? widget.transitionBuilder!(panel)
              : panel,
        ),
      ],
    );
  }
}
