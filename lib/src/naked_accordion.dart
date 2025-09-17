import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Manages accordion state with optional min/max expansion constraints.
///
/// Prevents closing below [min] and caps items at [max] (closes oldest when exceeded).
/// All operations are idempotent.
class NakedAccordionController<T> with ChangeNotifier {
  /// Minimum expanded items allowed when closing.
  final int min;

  /// Maximum expanded items allowed. If null, unlimited.
  final int? max;

  /// Expanded values in insertion order (oldest → newest).
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

  /// Open [value]. If at max, closes the oldest first.
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

  /// Close [value]. Respects [min] floor.
  void close(T value) {
    if (!values.contains(value)) return; // no-op
    if (min > 0 && values.length <= min) return; // floor
    values.remove(value);
    notifyListeners();
  }

  /// Toggle [value], respecting [min]/[max].
  void toggle(T value) {
    if (values.contains(value)) {
      close(value); // close() will notify
    } else {
      open(value); // open() will notify
    }
  }

  /// Remove all expanded values, but keep the first [min] if needed.
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

  /// Open multiple [newValues] (in order), without exceeding [max].
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

  /// Replace all expanded values with [newValues], respecting [max].
  /// This may result in fewer than [min] items expanded—by design—since this
  /// is a direct, programmatic state set. User-initiated closing still honors [min].
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

/// Provides accordion controller to descendant items.
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

/// Headless expandable/collapsible sections container.
///
/// Children should be [NakedAccordionItem] widgets. State managed by
/// [NakedAccordionController].
class NakedAccordion<T> extends StatefulWidget {
  const NakedAccordion({
    super.key,
    required this.children,
    required this.controller,
    this.initialExpandedValues = const [],
  });

  /// The accordion items.
  final List<Widget> children;

  /// The controller managing expanded values.
  final NakedAccordionController<T> controller;

  /// Values expanded on first build if controller is empty.
  final List<T> initialExpandedValues;

  @override
  State<NakedAccordion<T>> createState() => _NakedAccordionState<T>();
}

class _NakedAccordionState<T> extends State<NakedAccordion<T>> {
  NakedAccordionController<T> get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (widget.initialExpandedValues.isNotEmpty && _controller.values.isEmpty) {
      _controller.replaceAll(widget.initialExpandedValues);
    }
  }

  @override
  void didUpdateWidget(covariant NakedAccordion<T> oldWidget) {
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
    // Keep traversal well-defined without hijacking arrow keys globally.
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

typedef NakedAccordionTriggerBuilder =
    /// Build the *header/trigger* for an accordion item.
    /// The trigger should visually reflect [isExpanded]; activation toggles it.
    Widget Function(BuildContext context, bool isExpanded);

/// Individual accordion item with custom trigger and panel content.
///
/// Headless design requiring custom visuals. Supports keyboard toggle
/// (Enter/Space) and button semantics with expanded state.
class NakedAccordionItem<T> extends StatelessWidget {
  const NakedAccordionItem({
    super.key,
    required this.trigger,
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

  /// Builder for the header/trigger.
  final NakedAccordionTriggerBuilder trigger;

  /// Optional transition wrapper around the expanding panel.
  final Widget Function(Widget panel)? transitionBuilder;

  /// Content shown when expanded.
  final Widget child;

  /// Unique identifier tracked by controller.
  final T value;

  /// Called when header focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when header hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when header press changes.
  final ValueChanged<bool>? onPressChange;

  /// The semantic label for the header.
  final String? semanticLabel;

  /// Whether the header is interactive.
  final bool enabled;
  /// The mouse cursor when interactive.
  final MouseCursor mouseCursor;
  /// Whether to provide platform feedback.
  final bool enableFeedback;

  /// Whether to autofocus the header on build.
  final bool autofocus;

  /// The focus node for the header.
  final FocusNode? focusNode;

  void _toggle(NakedAccordionController<T> controller) =>
      controller.toggle(value);

  @override
  Widget build(BuildContext context) {
    final scope = NakedAccordionScope.of<T>(context);
    final controller = scope.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isExpanded = controller.contains(value);

        // Build the panel *only* when expanded (keeps semantics/reading order clean).
        final Widget panel = isExpanded ? child : const SizedBox.shrink();

        void onTap() {
          if (!enabled) return;
          if (enableFeedback) Feedback.forTap(context);
          _toggle(controller);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FocusableActionDetector(
              enabled: enabled,
              focusNode: focusNode,
              autofocus: autofocus,
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) => onTap(),
                ),
              },
              onShowHoverHighlight: onHoverChange,
              onFocusChange: onFocusChange,
              mouseCursor: enabled ? mouseCursor : SystemMouseCursors.basic,
              child: Semantics(
                container: true,
                enabled: enabled,
                button: true,
                expanded: isExpanded,
                label: semanticLabel,
                onTap: enabled ? onTap : null,
                child: GestureDetector(
                  onTapDown: (enabled && onPressChange != null)
                      ? (_) => onPressChange!(true)
                      : null,
                  onTapUp: (enabled && onPressChange != null)
                      ? (_) => onPressChange!(false)
                      : null,
                  onTap: enabled ? onTap : null,
                  onTapCancel: (enabled && onPressChange != null)
                      ? () => onPressChange!(false)
                      : null,
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  child: trigger(context, isExpanded),
                ),
              ),
            ),
            transitionBuilder != null ? transitionBuilder!(panel) : panel,
          ],
        );
      },
    );
  }
}
