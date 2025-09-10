import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'naked_button.dart';

/// Manages accordion state with optional min/max expansion constraints.
///
/// Uses a controller-based approach to handle complex state constraints,
/// batch operations, and business logic encapsulation beyond simple callbacks.
///
/// Generic type [T] represents the unique identifier for each accordion item.
class NakedAccordionController<T> with ChangeNotifier {
  /// Minimum number of expanded items allowed.
  final int min;

  /// Maximum number of expanded items allowed. If null, no maximum limit.
  final int? max;

  /// Currently expanded values.
  final Set<T> values = {};

  /// Creates an accordion controller.
  ///
  /// When [max] is reached, opening a new item closes the oldest one.
  NakedAccordionController({this.min = 0, this.max})
    : assert(min >= 0, 'min must be greater than or equal to 0'),
      assert(
        max == null || max >= min,
        'max must be greater than or equal to min',
      );

  /// Opens the accordion item with the given [value].
  ///
  /// Closes the oldest expanded item if [max] limit is reached.
  void open(T value) {
    if (max != null && values.length >= max!) {
      final first = values.first;

      values.remove(first);
      values.add(value);
    } else {
      values.add(value);
    }
    notifyListeners();
  }

  /// Closes the accordion item with the given [value].
  ///
  /// Ignores request if closing would violate [min] constraint.
  void close(T value) {
    if (min > 0 && values.length <= min) {
      return;
    }
    values.remove(value);
    notifyListeners();
  }

  /// Toggles the accordion item with the given [value].
  ///
  /// Respects [min] and [max] constraints when changing state.
  void toggle(T value) {
    if (values.contains(value)) {
      close(value);
    } else {
      open(value);
    }
    notifyListeners();
  }

  /// Removes all expanded values.
  ///
  /// May not clear all items if [min] constraint prevents it.
  void clear() {
    values.clear();
    notifyListeners();
  }

  /// Opens accordion items with the given [newValues].
  ///
  /// Respects [max] constraint, preserving existing open items.
  void openAll(List<T> newValues) {
    if (max != null) {
      final availableSlots = max! - values.length;
      if (availableSlots > 0) {
        values.addAll(newValues.take(availableSlots));
      }
      // If no available slots, do nothing
    } else {
      values.addAll(newValues);
    }
    notifyListeners();
  }

  /// Replaces all expanded values with [newValues].
  ///
  /// Useful for programmatically setting entire accordion state.
  /// Respects [max] constraint.
  void replaceAll(List<T> newValues) {
    values.clear();

    // Respect the max constraint
    if (max != null && newValues.length > max!) {
      values.addAll(newValues.take(max!));
    } else {
      values.addAll(newValues);
    }

    notifyListeners();
  }

  /// Returns whether the item with [value] is currently expanded.
  bool contains(T value) => values.contains(value);
}

/// Provides expandable/collapsible sections without visual styling.
///
/// Manages state through [NakedAccordionController] for complete design freedom.
///
/// Example:
/// ```dart
/// final controller = AccordionController<String>();
///
/// NakedAccordion<String>(
///   controller: controller,
///   initialExpandedValues: ['section1'],
///   children: [
///     NakedAccordionItem<String>(
///       value: 'section1',
///       trigger: (context, isExpanded, toggle) {
///         return TextButton(
///           onPressed: toggle,
///           child: Text(isExpanded ? 'Close' : 'Open'),
///         );
///       },
///       child: Text('Content for section 1'),
///       transitionBuilder: (child) => AnimatedSwitcher(
///         duration: Duration(milliseconds: 300),
///         child: child,
///       ),
///     ),
///   ],
/// )
/// ```
class NakedAccordion<T> extends StatefulWidget {
  /// Creates a naked accordion.
  ///
  /// The [children] should be [NakedAccordionItem] widgets with matching generic type [T].
  const NakedAccordion({
    super.key,
    required this.children,
    required this.controller,
    this.initialExpandedValues = const [],
  });

  /// Accordion items to display.
  final List<Widget> children;

  /// Controller that manages which items are expanded or collapsed.
  final NakedAccordionController<T> controller;

  /// Values that should be expanded when the accordion is first built.
  final List<T> initialExpandedValues;

  @override
  State<NakedAccordion<T>> createState() => _NakedAccordionState<T>();
}

class _NakedAccordionState<T> extends State<NakedAccordion<T>> {
  NakedAccordionController<T> get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Only set initial values if provided and controller is empty
    // This preserves any pre-existing values set on the controller
    if (widget.initialExpandedValues.isNotEmpty && _controller.values.isEmpty) {
      _controller.replaceAll(widget.initialExpandedValues);
    }
  }

  @override
  void didUpdateWidget(covariant NakedAccordion<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Use deep equality check for lists
    final areEqual = listEquals(
      oldWidget.initialExpandedValues,
      widget.initialExpandedValues,
    );

    if (!areEqual) {
      // Use the new encapsulated method
      _controller.replaceAll(widget.initialExpandedValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: widget.children);
  }
}

typedef NakedAccordionTriggerBuilder =
    // ignore: prefer-named-boolean-parameters
    Widget Function(BuildContext context, bool isExpanded);

/// Individual item in a [NakedAccordion].
///
/// Consists of a trigger widget and expandable content.
/// Generic type [T] should match the [NakedAccordionController] type.
class NakedAccordionItem<T> extends StatelessWidget {
  /// Creates a naked accordion item.
  ///
  /// The [value] must be unique among all items in the same controller.
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
  });

  /// Builder function that creates the trigger widget.
  ///
  /// Receives context and current expansion state.
  final NakedAccordionTriggerBuilder trigger;

  /// Customizes transition when expanding/collapsing.
  ///
  /// If not provided, content appears/disappears instantly.
  final Widget Function(Widget child)? transitionBuilder;

  /// Content displayed when this item is expanded.
  final Widget child;

  /// Unique identifier for this accordion item.
  ///
  /// Used by [NakedAccordionController] to track expansion state.
  final T value;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when highlight (pressed) state changes.
  final ValueChanged<bool>? onPressChange;


  /// Whether the accordion item is enabled.
  final bool enabled;

  /// Cursor when hovering over the accordion trigger.
  final MouseCursor mouseCursor;

  /// Whether to provide platform-specific feedback on interaction.
  final bool enableFeedback;

  /// Whether the item should be focused when the accordion is opened.
  final bool autofocus;

  /// Focus node for the item.
  final FocusNode? focusNode;

  void _handleToggle(_NakedAccordionState? state) {
    state?._controller.toggle(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_NakedAccordionState<T>>();

    return ListenableBuilder(
      listenable: state!._controller,
      builder: (context, child) {
        final isExpanded = state._controller.contains(value);
        final child = isExpanded ? this.child : const SizedBox.shrink();

        void onTap() => _handleToggle(state);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              child: Actions(
                actions: {
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (intent) => enabled ? onTap() : null,
                  ),
                },
                child: NakedButton(
                  onPressed: onTap,
                  enabled: enabled,
                  mouseCursor: mouseCursor,
                  enableFeedback: enableFeedback,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  onFocusChange: onFocusChange,
                  onHoverChange: onHoverChange,
                  onPressChange: onPressChange,
                  builder: (context, states, child) =>
                      trigger(context, isExpanded),
                ),
              ),
            ),
            transitionBuilder != null ? transitionBuilder!(child) : child,
          ],
        );
      },
    );
  }
}
