import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/naked_interactable.dart';
import 'utilities/semantics.dart';

/// Headless checkbox built on NakedInteractable with proper semantics and callbacks.
class NakedCheckbox extends StatelessWidget {
  const NakedCheckbox({
    super.key,
    this.child,
    this.value = false,
    this.tristate = false,
    this.onChanged,
    this.enabled = true,
    this.semanticLabel,
    this.semanticHint,
    this.excludeSemantics = false,
    this.mouseCursor,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onHighlightChanged,
    this.onStateChange,
    this.statesController,
    this.builder,
  }) : assert(
         (tristate || value != null),
         'Non-tristate checkbox must have a non-null value',
       ),
       assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// Visual representation of the checkbox.
  ///
  /// Renders different states based on callback properties.
  final Widget? child;

  /// Whether this checkbox is checked.
  ///
  /// When [tristate] is true, null corresponds to mixed state.
  final bool? value;

  /// Whether the checkbox can be true, false, or null.
  ///
  /// When true, tapping cycles through false => true => null => false.
  /// When false, [value] must not be null.
  final bool tristate;

  /// Called when the checkbox is toggled.
  ///
  /// If null, the checkbox is disabled and unresponsive.
  final ValueChanged<bool?>? onChanged;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when highlight (pressed) state changes.
  final ValueChanged<bool>? onHighlightChanged;

  /// Called when any widget state changes.
  final ValueChanged<Set<WidgetState>>? onStateChange;

  /// Optional external controller for interaction states.
  final WidgetStatesController? statesController;

  /// Whether the checkbox is enabled.
  final bool enabled;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Semantic hint for accessibility.
  final String? semanticHint;

  /// Whether to exclude child semantics from the semantic tree.
  final bool excludeSemantics;

  /// Cursor when hovering over the checkbox.
  final MouseCursor? mouseCursor;

  /// Whether to provide haptic feedback on tap.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to autofocus when created.
  final bool autofocus;

  /// Optional builder that receives the current states for visuals.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  bool? _getNextTristate(bool? currentValue) {
    // Tristate cycling: false → true → null → false
    switch (currentValue) {
      case false:
        return true;
      case true:
        return null;
      case null:
        return false;
    }
  }

  void _handlePressed() {
    if (onChanged == null) return;

    if (enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }

    final bool? newValue = tristate
        ? _getNextTristate(value)
        : !(value ?? false);

    onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final bool isChecked = value ?? false;
    final bool isInteractive = enabled && onChanged != null;

    return NakedSemantics.checkbox(
      label: semanticLabel,
      checked: value,
      tristate: tristate,
      onTap: isInteractive ? _handlePressed : null,
      hint: semanticHint,
      excludeSemantics: excludeSemantics,
      child: Shortcuts(
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.enter):
              const ActivateIntent(),
          const SingleActivator(LogicalKeyboardKey.space):
              const ActivateIntent(),
        },
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (ActivateIntent intent) =>
                  isInteractive ? _handlePressed() : null,
            ),
          },
          child: GestureDetector(
            onTap: isInteractive ? _handlePressed : null,
            behavior: HitTestBehavior.opaque,
            child: NakedInteractable(
              mouseCursor: mouseCursor,
              statesController: statesController,
              enabled: isInteractive,
              onHighlightChanged: onHighlightChanged,
              onHoverChange: onHoverChange,
              onFocusChange: onFocusChange,
              onStateChange: onStateChange,
              selected: isChecked,
              autofocus: autofocus,
              focusNode: focusNode,
              builder: (context, states, child) {
                if (builder != null) {
                  return builder!(context, states, child);
                }

                return this.child!;
              },
            ),
          ),
        ),
      ),
    );
  }
}
