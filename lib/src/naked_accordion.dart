import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'primitives/naked_interactable.dart';

/// Controller that manages the state of an accordion.
///
/// This controller keeps track of which accordion items are expanded or collapsed
/// and provides methods to open, close, or toggle items. It can also enforce
/// minimum and maximum limits on the number of expanded items.
///
/// **Architecture Decision**: This component uses a controller-based approach to handle:
/// - Complex state constraints (min/max expanded items)
/// - Batch operations (openAll, replaceAll)
/// - Business logic encapsulation (preventing invalid states)
/// - External programmatic control beyond simple selection callbacks
///
/// Generic type [T] represents the unique identifier for each accordion item.
/// This could be a String, int, or any other type that can uniquely identify sections.
class NakedAccordionController<T> with ChangeNotifier {
  /// The minimum number of expanded items allowed.
  final int min;

  /// The maximum number of expanded items allowed.
  /// If null, there is no maximum limit.
  final int? max;

  /// Set of currently expanded values.
  final Set<T> values = {};

  /// Creates an accordion controller.
  ///
  /// [min] specifies the minimum number of expanded items (default: 0).
  /// [max] specifies the maximum number of expanded items (optional).
  /// When [max] is specified and reached, opening a new item will close the oldest one.
  NakedAccordionController({this.min = 0, this.max})
    : assert(min >= 0, 'min must be greater than or equal to 0'),
      assert(
        max == null || max >= min,
        'max must be greater than or equal to min',
      );

  /// Opens the accordion item with the given [value].
  ///
  /// If [max] is specified and the maximum number of expanded items is reached,
  /// this will close the oldest expanded item to maintain the limit.
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
  /// Will not close if doing so would violate the [min] constraint.
  void close(T value) {
    if (min > 0 && values.length <= min) {
      return;
    }
    values.remove(value);
    notifyListeners();
  }

  /// Toggles the accordion item with the given [value].
  ///
  /// If the item is expanded, it will be closed (subject to [min] constraint).
  /// If the item is collapsed, it will be opened (subject to [max] constraint).
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
  /// Note that if [min] is greater than 0, this operation may not be allowed.
  void clear() {
    values.clear();
    notifyListeners();
  }

  /// Opens accordion items with the given [newValues].
  ///
  /// If [max] is specified, only opens as many items as allowed
  /// by the constraint, preserving existing open items.
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

  /// Replaces all expanded values with a new set.
  ///
  /// This method clears all existing expanded values and replaces them
  /// with [newValues], respecting the [max] constraint if specified.
  ///
  /// This is useful for programmatically setting the entire accordion state,
  /// such as when responding to external state changes.
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

  /// Checks if an item with the given [value] is currently expanded.
  bool contains(T value) => values.contains(value);
}

/// A fully customizable accordion with no default styling.
///
/// NakedAccordion provides expandable/collapsible sections without imposing any visual styling,
/// giving consumers complete design freedom. It manages the state of expanded sections through
/// an [NakedAccordionController].
///
/// This component includes:
/// - [NakedAccordionController]: Manages which sections are expanded/collapsed
/// - [NakedAccordion]: The container for accordion items
/// - [NakedAccordionItem]: Individual collapsible sections
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
  /// The [children] should be [NakedAccordionItem] widgets with the same
  /// generic type [T] as the [controller].
  const NakedAccordion({
    super.key,
    required this.children,
    required this.controller,
    this.initialExpandedValues = const [],
  });

  /// The accordion items to display.
  final List<Widget> children;

  /// The controller that manages which items are expanded or collapsed.
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

/// An individual item in a [NakedAccordion].
///
/// Each item consists of a trigger widget that toggles expansion state
/// and content that is shown when expanded. The [transitionBuilder] can be
/// used to customize how content appears/disappears.
///
/// Generic type [T] should match the type used in the [NakedAccordionController].
class NakedAccordionItem<T> extends StatelessWidget {
  /// Creates a naked accordion item.
  ///
  /// The [trigger] and [child] parameters are required.
  /// The [value] must be unique among all items controlled by the same controller.
  const NakedAccordionItem({
    super.key,
    required this.trigger,
    required this.value,
    required this.child,
    this.transitionBuilder,
    this.semanticLabel,
    this.onHoverChange,
    this.onPressChange,
    this.onFocusChange,
    this.onDisabledChange,
    this.enabled = true,
    this.enableHapticFeedback = true,
    this.autoFocus = false,
    this.focusNode,
  });

  /// Builder function that creates the trigger widget.
  ///
  /// The builder provides:
  /// - [BuildContext] for accessing theme and other data
  /// - [bool] indicating if the item is expanded
  final NakedAccordionTriggerBuilder trigger;

  /// Optional builder to customize the transition when expanding/collapsing.
  ///
  /// If not provided, content will appear/disappear instantly.
  final Widget Function(Widget child)? transitionBuilder;

  /// The content displayed when this item is expanded.
  final Widget child;

  /// The unique identifier for this accordion item.
  ///
  /// This value is used by the [NakedAccordionController] to track expansion state.
  final T value;

  /// Optional semantic label describing the section for screen readers.
  final String? semanticLabel;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when disabled state changes.
  final ValueChanged<bool>? onDisabledChange;

  /// Whether the accordion item is enabled.
  final bool enabled;

  /// Whether to provide haptic feedback on interaction.
  final bool enableHapticFeedback;

  /// Whether the item should be focused when the accordion is opened.
  final bool autoFocus;

  /// The focus node for the item.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_NakedAccordionState<T>>();

    return ListenableBuilder(
      listenable: state!._controller,
      builder: (context, child) {
        final isExpanded = state._controller.contains(value);
        final child = isExpanded ? this.child : const SizedBox.shrink();

        return Semantics(
          container: true,
          label: semanticLabel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Use NakedInteractable for the trigger to handle all interaction states
              NakedInteractable(
                builder: (context, states) => trigger(context, isExpanded),
                onPressed: enabled
                    ? () {
                        if (enableHapticFeedback) {
                          HapticFeedback.lightImpact();
                        }
                        state._controller.toggle(value);
                      }
                    : null,
                enabled: enabled,
                autofocus: autoFocus,
                focusNode: focusNode,
                onHoverChange: onHoverChange,
                onPressChange: onPressChange,
                onFocusChange: onFocusChange,
                onDisabledChange: onDisabledChange,
              ),
              transitionBuilder != null ? transitionBuilder!(child) : child,
            ],
          ),
        );
      },
    );
  }
}
