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
        setEquals(other.states, states) &&
        other.expandedCount == expandedCount &&
        other.canExpandMore == canExpandMore &&
        other.canCollapseMore == canCollapseMore &&
        other.minExpanded == minExpanded &&
        other.maxExpanded == maxExpanded;
  }

  @override
  int get hashCode => Object.hash(
    states,
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
      NakedState.of(context);

  /// Returns the nearest [NakedAccordionItemState] if available.
  static NakedAccordionItemState<S>? maybeOf<S>(BuildContext context) =>
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

    return other is NakedAccordionItemState<T> &&
        setEquals(other.states, states) &&
        other.value == value &&
        other.isExpanded == isExpanded &&
        other.canCollapse == canCollapse &&
        other.canExpand == canExpand;
  }

  @override
  int get hashCode =>
      Object.hash(states, value, isExpanded, canCollapse, canExpand);
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

/// Provides a [NakedAccordionController] to descendant widgets.
class NakedAccordionScope<T> extends InheritedWidget {
  const NakedAccordionScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// Returns the nearest [NakedAccordionScope] without asserting.
  static NakedAccordionScope<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  /// Returns the nearest [NakedAccordionScope], throwing when absent.
  static NakedAccordionScope<T> of<T>(BuildContext context) {
    final scope = maybeOf<T>(context);
    if (scope == null) {
      throw StateError('NakedAccordionScope<$T> not found in context.');
    }

    return scope;
  }

  final NakedAccordionController<T> controller;

  @override
  bool updateShouldNotify(covariant NakedAccordionScope<T> oldWidget) {
    // Controller identity changes are rare; items listen to controller directly.
    return oldWidget.controller != controller;
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
    required this.children,
    required this.controller,
    this.initialExpandedValues = const [],
  });

  /// Accordion items to render.
  final List<Widget> children;

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
    // Keep traversal predictable without overriding global arrow key handling.
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return NakedStateScope(
          value: NakedAccordionGroupState(
            states: const {},
            expandedCount: _controller.values.length,
            minExpanded: _controller.min,
            maxExpanded: _controller.max,
          ),
          child: NakedAccordionScope<T>(
            controller: _controller,
            child: FocusTraversalGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.children,
              ),
            ),
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
class NakedAccordion<T> extends StatefulWidget {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = NakedAccordionScope.of<T>(context);
    final controller = scope.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isExpanded = controller.contains(widget.value);

        // Build the panel *only* when expanded.
        final Widget panel = isExpanded
            ? widget.child
            : const SizedBox.shrink();

        void onTap() {
          if (!widget.enabled) return;
          if (widget.enableFeedback) Feedback.forTap(context);
          _toggle(controller);
        }

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
              child: () {
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
                    child: Builder(
                      builder: (context) {
                        final canCollapse =
                            isExpanded &&
                            (controller.values.length > controller.min);

                        final canExpand =
                            !isExpanded &&
                            (controller.max == null ||
                                controller.values.length < controller.max!);
                        final accordionState = NakedAccordionItemState<T>(
                          states: widgetStates,
                          value: widget.value,
                          isExpanded: isExpanded,
                          canCollapse: canCollapse,
                          canExpand: canExpand,
                        );

                        return NakedStateScopeBuilder(
                          value: accordionState,
                          builder: (context, accordionState, child) =>
                              widget.builder(context, accordionState),
                        );
                      },
                    ),
                  ),
                );

                return widget.excludeSemantics
                    ? triggerContent
                    : Semantics(
                        enabled: widget.enabled,
                        label: widget.semanticLabel,
                        onTap: widget.enabled ? onTap : null,
                        child: triggerContent,
                      );
              }(),
            ),
            widget.transitionBuilder != null
                ? widget.transitionBuilder!(panel)
                : panel,
          ],
        );
      },
    );
  }
}
