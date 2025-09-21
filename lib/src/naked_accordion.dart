import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/widget_state_snapshot.dart';

/// Immutable view passed to [NakedAccordionItem.trigger] builder.
class NakedAccordionItemState<T> extends NakedWidgetState {
  /// The item's unique identifier.
  final T value;

  /// Whether this item is currently expanded.
  final bool isExpanded;

  /// Whether this item can be collapsed, respecting the [NakedAccordionController.min] constraint.
  final bool canCollapse;

  /// Whether this item can be expanded, respecting the [NakedAccordionController.max] constraint.
  final bool canExpand;

  NakedAccordionItemState({
    required super.states,
    required this.value,
    required this.isExpanded,
    required this.canCollapse,
    required this.canExpand,
  });
}

/// A headless accordion controller without visuals.
///
/// Manages accordion state with optional min/max expansion constraints.
/// Prevents closing below [min] and caps items at [max].
///
/// See also:
/// - [NakedAccordionGroup], the container that uses this controller.
class NakedAccordionController<T> with ChangeNotifier {
  /// The minimum number of expanded items allowed when closing.
  final int min;

  /// The maximum number of expanded items allowed.
  ///
  /// When null, the number of expanded items is unlimited.
  final int? max;

  /// The expanded values in insertion order (oldest → newest).
  final LinkedHashSet<T> values = LinkedHashSet<T>();

  NakedAccordionController({this.min = 0, this.max})
    : assert(min >= 0, 'min must be >= 0'),
      assert(max == null || max >= min, 'max must be >= min');

  bool _setEquals(Set<T> a, Set<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }

    return true;
  }

  /// Returns whether the item with [value] is currently expanded.
  bool contains(T value) => values.contains(value);

  /// Opens [value]. If at [max], closes the oldest first.
  void open(T value) {
    if (values.contains(value)) return; // no-op
    if (max != null && values.length >= max!) {
      // Close oldest to make room.
      if (values.isNotEmpty) {
        final oldest = values.first;
        values.remove(oldest);
      }
    }
    values.add(value);
    notifyListeners();
  }

  /// Closes [value], respecting the [min] floor.
  void close(T value) {
    if (!values.contains(value)) return; // no-op
    if (min > 0 && values.length <= min) return; // floor
    values.remove(value);
    notifyListeners();
  }

  /// Toggles [value], respecting [min] and [max].
  void toggle(T value) {
    if (values.contains(value)) {
      close(value); // close() will notify
    } else {
      open(value); // open() will notify
    }
  }

  /// Removes all expanded values but keeps the first [min] when needed.
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

  /// Opens multiple [newValues] in order without exceeding [max].
  ///
  /// Existing expanded values are preserved (FIFO).
  void openAll(Iterable<T> newValues) {
    var changed = false;
    for (final v in newValues) {
      if (values.contains(v)) continue;
      if (max != null && values.length >= max!) {
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
  /// This may result in fewer than [min] items expanded—by design—since this is
  /// a direct, programmatic state set. User-initiated closing still honors [min].
  void replaceAll(Iterable<T> newValues) {
    final target = (max != null) ? newValues.take(max!) : newValues;
    final next = LinkedHashSet<T>.of(target);
    if (_setEquals(values, next)) return; // no change
    values
      ..clear()
      ..addAll(next);
    notifyListeners();
  }
}

/// Provides the accordion controller to descendant items.
class NakedAccordionScope<T> extends InheritedWidget {
  const NakedAccordionScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static NakedAccordionScope<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

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
///       triggerBuilder: (context, isExpanded) => Text('Section 1'),
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

  /// The accordion items.
  final List<Widget> children;

  /// The controller that manages expanded values.
  final NakedAccordionController<T> controller;

  /// The values expanded on first build when the controller is empty.
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
    )) {
      _controller.replaceAll(widget.initialExpandedValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Maintains well-defined traversal without hijacking arrow keys globally.
    return NakedAccordionScope<T>(
      controller: _controller,
      child: FocusTraversalGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.children,
        ),
      ),
    );
  }
}

typedef NakedAccordionTriggerBuilder<T> =
    /// Builds the header/trigger for an accordion item.
    ///
    /// Receives a [NakedAccordionItemState] with expansion state, constraints, and interactions.
    Widget Function(BuildContext context, NakedAccordionItemState<T> state);

/// A headless accordion item without visuals.
///
/// An individual expandable item with a custom trigger and panel content.
///
/// The trigger builder receives a [NakedAccordionItemState] with expansion
/// state, constraints, and interaction states.
///
/// See also:
/// - [NakedAccordionGroup], the container that manages accordion items.
class NakedAccordion<T> extends StatefulWidget {
  const NakedAccordion({
    super.key,
    required this.triggerBuilder,
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
  });

  /// Builds the header/trigger.
  final NakedAccordionTriggerBuilder<T> triggerBuilder;

  /// Optional transition wrapper around the expanding panel.
  final Widget Function(Widget panel)? transitionBuilder;

  /// The content shown when expanded.
  final Widget child;

  /// The unique identifier tracked by the controller.
  final T value;

  /// Called when the header's focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when the header's hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when the header's pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Semantic label for the header.
  final String? semanticLabel;

  /// Whether the header is interactive.
  final bool enabled;

  /// The mouse cursor when interactive.
  final MouseCursor mouseCursor;

  /// Whether to provide platform feedback on interactions.
  final bool enableFeedback;

  /// Whether the header should autofocus.
  final bool autofocus;

  /// The focus node for the header.
  final FocusNode? focusNode;

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
              child: Semantics(
                enabled: widget.enabled,
                label: widget.semanticLabel,
                onTap: widget.enabled ? onTap : null,
                child: GestureDetector(
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
                        final accordionState = NakedAccordionItemState<T>(
                          states: widgetStates,
                          value: widget.value,
                          isExpanded: isExpanded,
                          canCollapse:
                              !isExpanded ||
                              controller.values.length > controller.min,
                          canExpand:
                              isExpanded ||
                              controller.max == null ||
                              controller.values.length < controller.max!,
                        );

                        return widget.triggerBuilder(context, accordionState);
                      },
                    ),
                  ),
                ),
              ),
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
