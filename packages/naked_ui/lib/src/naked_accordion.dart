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

  /// Creates a group snapshot and derives its expansion affordances.
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
      NakedState.controllerOfType<NakedAccordionGroupState>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOfType<NakedAccordionGroupState>(context);

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

  /// Creates an accordion-item state snapshot for [value].
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
      NakedState.controllerOfType<NakedAccordionItemState<dynamic>>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOfType<NakedAccordionItemState<dynamic>>(
        context,
      );

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

  final LinkedHashSet<T> _values = LinkedHashSet<T>();

  /// An immutable snapshot of the expanded values, oldest first.
  ///
  /// Use [open], [close], [toggle], [openAll], [replaceAll], or [clear] to
  /// update the controller while preserving constraints and notifications.
  Set<T> get values => Set<T>.unmodifiable(_values);

  /// Creates an accordion controller with optional expansion constraints.
  ///
  /// Throws an [ArgumentError] when [min] is negative or [max] is less than
  /// [min].
  NakedAccordionController({this.min = 0, this.max}) {
    if (min < 0) {
      throw ArgumentError.value(min, 'min', 'must be non-negative');
    }
    if (max != null && max! < min) {
      throw ArgumentError.value(max, 'max', 'must be at least min ($min)');
    }
  }

  /// Reports whether the item with [value] is currently expanded.
  bool contains(T value) => _values.contains(value);

  /// Whether [value] can be opened.
  ///
  /// Reaching [max] does not prevent opening a new value: the oldest expanded
  /// value is evicted first. A value cannot be opened only when it is already
  /// open or [max] is zero.
  bool canOpen(T value) => !_values.contains(value) && max != 0;

  /// Whether [value] can be closed without crossing the [min] floor.
  bool canClose(T value) => _values.contains(value) && _values.length > min;

  /// Whether toggling [value] would change this controller.
  bool canToggle(T value) =>
      _values.contains(value) ? canClose(value) : canOpen(value);

  /// Opens [value], evicting the oldest entry when [max] is reached.
  void open(T value) {
    if (!canOpen(value)) return;
    final maxValue = max;
    if (maxValue != null && _values.length >= maxValue) {
      // Close oldest to make room.
      if (_values.isNotEmpty) {
        _values.remove(_values.first);
      }
    }
    _values.add(value);
    notifyListeners();
  }

  /// Closes [value] while respecting the [min] floor.
  void close(T value) {
    if (!canClose(value)) return;
    _values.remove(value);
    notifyListeners();
  }

  /// Toggles [value], applying both [min] and [max] constraints.
  void toggle(T value) {
    if (_values.contains(value)) {
      close(value);
    } else {
      open(value);
    }
  }

  /// Removes all expanded values but preserves the first [min] entries.
  void clear() {
    if (_values.isEmpty) return;
    if (min <= 0) {
      _values.clear();
      notifyListeners();

      return;
    }
    if (_values.length <= min) return;
    final keep = _values.take(min).toList(growable: false);
    _values
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
      if (_values.contains(v)) continue;
      if (maxValue != null && _values.length >= maxValue) {
        if (_values.isNotEmpty) {
          _values.remove(_values.first);
        }
      }
      _values.add(v);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Replaces all expanded values with [newValues], respecting [max].
  ///
  /// This may produce fewer than [min] expanded items because it is a direct
  /// programmatic update. User-initiated closing still honors [min].
  void replaceAll(Iterable<T> newValues) {
    final maxValue = max;
    final next = <T>{};
    for (final value in newValues) {
      if (maxValue != null && next.length >= maxValue) break;
      next.add(value);
    }
    if (listEquals(_values.toList(), next.toList())) return;
    _values
      ..clear()
      ..addAll(next);
    notifyListeners();
  }
}

/// Provides a [NakedAccordionController] to descendant widgets.
///
/// This extends [InheritedNotifier] to automatically notify dependents when
/// the controller's state changes, eliminating the need for explicit
/// [ListenableBuilder] wrappers in accordion items.
///
/// Descendants that depend on this scope rebuild when the controller notifies.
class NakedAccordionScope<T>
    extends InheritedNotifier<NakedAccordionController<T>> {
  /// Creates a scope for [controller] around [child].
  const NakedAccordionScope({
    super.key,
    required NakedAccordionController<T> controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller managing accordion expansion state.
  ///
  /// This is guaranteed non-null because the constructor requires it.
  NakedAccordionController<T> get controller => notifier!;

  /// Returns the nearest [NakedAccordionScope] without asserting.
  static NakedAccordionScope<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NakedAccordionScope<T>>();
  }

  /// Returns the nearest [NakedAccordionScope], throwing when absent.
  static NakedAccordionScope<T> of<T>(BuildContext context) {
    final scope = maybeOf<T>(context);
    if (scope == null) {
      throw StateError('NakedAccordionScope<$T> not found in context.');
    }
    return scope;
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
///   child: Column(
///     children: [
///       NakedAccordion(
///         value: 'section1',
///         builder: (context, state) => Text('Section 1'),
///         child: Text('Content 1'),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// See also:
/// - `ExpansionPanelList`, the Material-styled accordion for typical apps.
class NakedAccordionGroup<T> extends StatefulWidget {
  /// Creates an accordion group controlled by [controller].
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
    final controllerChanged = !identical(
      oldWidget.controller,
      widget.controller,
    );
    final initialValuesChanged = !listEquals(
      oldWidget.initialExpandedValues,
      widget.initialExpandedValues,
    );
    if ((controllerChanged || initialValuesChanged) &&
        _controller.values.isEmpty) {
      _controller.replaceAll(widget.initialExpandedValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    // NakedAccordionScope (InheritedNotifier) notifies dependents when
    // controller state changes. The Builder below depends on the scope,
    // so it rebuilds and updates NakedAccordionGroupState automatically.
    return NakedAccordionScope<T>(
      controller: _controller,
      child: Builder(
        builder: (context) {
          // Create dependency on the InheritedNotifier.
          // When controller notifies, this Builder rebuilds.
          context.dependOnInheritedWidgetOfExactType<NakedAccordionScope<T>>();

          return NakedStateScope(
            value: NakedAccordionGroupState(
              states: const {},
              expandedCount: _controller.values.length,
              minExpanded: _controller.min,
              maxExpanded: _controller.max,
            ),
            child: FocusTraversalGroup(child: widget.child),
          );
        },
      ),
    );
  }
}

/// Builds an accordion trigger from its current item [state].
typedef NakedAccordionTriggerBuilder<T> =
    Widget Function(BuildContext context, NakedAccordionItemState<T> state);

/// A headless accordion item with a customizable trigger and panel.
///
/// The [builder] receives a [NakedAccordionItemState] that includes
/// expansion status, constraint affordances, and interaction states.
///
/// See also:
/// - [NakedAccordionGroup], the container that manages accordion items.
class NakedAccordion<T> extends StatefulWidget {
  /// Creates an accordion item identified by [value].
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

  /// Whether to omit the accordion's button and expanded-state semantics.
  ///
  /// The semantics supplied by [builder] remain in the tree, allowing callers
  /// to provide a complete custom accessibility contract.
  final bool excludeSemantics;

  @override
  State<NakedAccordion<T>> createState() => _NakedAccordionState<T>();
}

class _NakedAccordionState<T> extends State<NakedAccordion<T>>
    with WidgetStatesMixin<NakedAccordion<T>> {
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
      if (!widget.enabled) {
        clearInteractionStates(
          onHoverChange: widget.onHoverChange,
          onFocusChange: widget.onFocusChange,
          onPressChange: widget.onPressChange,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the controller from scope. This creates a dependency on
    // NakedAccordionScope (InheritedNotifier), so this widget rebuilds
    // automatically when controller state changes.
    final controller = NakedAccordionScope.of<T>(context).controller;

    return _buildContent(context, controller);
  }

  Widget _buildContent(
    BuildContext context,
    NakedAccordionController<T> controller,
  ) {
    // Derive state directly from controller.
    final isExpanded = controller.contains(widget.value);
    final canCollapse = controller.canClose(widget.value);
    final canExpand = controller.canOpen(widget.value);
    final effectiveEnabled =
        widget.enabled && controller.canToggle(widget.value);
    final effectiveStates = widgetStates;
    if (!effectiveEnabled) {
      effectiveStates
        ..add(WidgetState.disabled)
        ..remove(WidgetState.pressed);
    }

    // Build the panel only when expanded.
    final Widget panel = isExpanded ? widget.child : const SizedBox.shrink();

    void onTap() {
      if (!effectiveEnabled) return;
      if (widget.enableFeedback) Feedback.forTap(context);
      _toggle(controller);
    }

    final accordionState = NakedAccordionItemState<T>(
      states: effectiveStates,
      value: widget.value,
      isExpanded: isExpanded,
      canCollapse: canCollapse,
      canExpand: canExpand,
    );

    final Widget trigger = NakedStateScopeBuilder(
      value: accordionState,
      builder: (context, accordionState, child) =>
          widget.builder(context, accordionState),
    );

    final excludeTriggerSemantics =
        !widget.excludeSemantics && widget.semanticLabel != null;

    Widget triggerContent = GestureDetector(
      onTapDown: effectiveEnabled
          ? (_) => updatePressState(true, widget.onPressChange)
          : null,
      onTapUp: effectiveEnabled
          ? (_) => updatePressState(false, widget.onPressChange)
          : null,
      onTap: effectiveEnabled ? onTap : null,
      onTapCancel: effectiveEnabled
          ? () => updatePressState(false, widget.onPressChange)
          : null,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: excludeTriggerSemantics
          ? ExcludeSemantics(child: trigger)
          : trigger,
    );

    Widget accordionChild = widget.excludeSemantics
        ? triggerContent
        : Semantics(
            enabled: effectiveEnabled,
            button: true,
            expanded: isExpanded,
            label: widget.semanticLabel,
            onTap: effectiveEnabled ? onTap : null,
            child: triggerContent,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NakedFocusableDetector(
          enabled: effectiveEnabled,
          autofocus: widget.autofocus,
          onFocusChange: (f) => updateFocusState(f, widget.onFocusChange),
          onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
          focusNode: widget.focusNode,
          mouseCursor: effectiveEnabled
              ? widget.mouseCursor
              : SystemMouseCursors.basic,
          shortcuts: NakedIntentActions.buttonShortcuts,
          actions: NakedIntentActions.accordionActions(onToggle: onTap),
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
