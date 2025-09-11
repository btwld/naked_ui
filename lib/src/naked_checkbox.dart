import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mixins/naked_mixins.dart';

/// Headless checkbox built with mixins for proper semantics and callbacks.
class NakedCheckbox extends StatefulWidget {
  const NakedCheckbox({
    super.key,
    this.child,
    this.value = false,
    this.tristate = false,
    this.onChanged,
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
    this.addSemantics = true,
    this.excludeChildSemantics = false,
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
  final ValueChanged<bool>? onPressChange;

  /// Whether the checkbox is enabled.
  final bool enabled;

  /// Cursor when hovering over the checkbox.
  final MouseCursor? mouseCursor;

  /// Whether to provide haptic feedback on tap.
  ///
  /// Note: Checkboxes use selectionClick haptic feedback for state changes,
  /// which is consistent across platforms for selection controls.
  final bool enableFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to autofocus when created.
  final bool autofocus;

  /// Optional builder that receives the current states for visuals.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Whether to add semantics to this checkbox.
  final bool addSemantics;

  /// Whether to exclude child semantics.
  final bool excludeChildSemantics;

  bool get _effectiveEnabled => enabled && onChanged != null;

  @override
  State<NakedCheckbox> createState() => _NakedCheckboxState();
}

class _NakedCheckboxState extends State<NakedCheckbox>
    with WidgetStatesMixin<NakedCheckbox>, PressListenerMixin<NakedCheckbox> {
  // Private methods
  void _handleKeyboardActivation([Intent? _]) {
    if (!widget._effectiveEnabled) return;

    _handleActivation();
  }

  void _handleActivation() {
    if (!widget._effectiveEnabled || widget.onChanged == null) return;

    if (widget.enableFeedback) {
      HapticFeedback.selectionClick();
    }

    final bool? nextValue;
    if (widget.tristate) {
      if (widget.value == null) {
        nextValue = false;
      } else if (widget.value == false) {
        nextValue = true;
      } else {
        nextValue = null; // true → null
      }
    } else {
      final current = widget.value ?? false;
      nextValue = !current;
    }

    widget.onChanged!(nextValue);
  }

  Widget _buildContent(BuildContext context) {
    final states = widgetStates;

    return widget.builder != null
        ? widget.builder!(context, states, widget.child)
        : widget.child!;
  }

  // Private getters
  MouseCursor get _effectiveCursor => widget._effectiveEnabled
      ? (widget.mouseCursor ?? SystemMouseCursors.click)
      : SystemMouseCursors.basic;

  VoidCallback? get _semanticsTapHandler =>
      widget._effectiveEnabled ? _handleActivation : null;

  VoidCallback get _semanticsFocusHandler =>
      () => (widget.focusNode ?? FocusScope.of(context)).requestFocus();

  @override
  void initializeWidgetStates() {
    updateDisabledState(!widget.enabled);
  }

  @override
  void didUpdateWidget(covariant NakedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncWidgetStates();
  }

  @override
  Widget build(BuildContext context) {
    Widget checkboxWidget = FocusableActionDetector(
      // Keyboard and focus handling
      enabled: widget._effectiveEnabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: _handleKeyboardActivation,
        ),
      },
      onShowHoverHighlight: (hovered) {
        updateHoverState(hovered, widget.onHoverChange);
      },
      onFocusChange: (focused) {
        updateFocusState(focused, widget.onFocusChange);
      },
      mouseCursor: _effectiveCursor,
      child: GestureDetector(
        onTapDown: widget._effectiveEnabled
            ? (details) {
                updatePressState(true, widget.onPressChange);
              }
            : null,
        onTapUp: widget._effectiveEnabled
            ? (details) {
                updatePressState(false, widget.onPressChange);
              }
            : null,
        onTap: widget._effectiveEnabled ? _handleActivation : null,
        onTapCancel: widget._effectiveEnabled
            ? () {
                updatePressState(false, widget.onPressChange);
              }
            : null,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        child: _buildContent(context),
      ),
    );

    if (!widget.addSemantics) return checkboxWidget;

    return Semantics(
      excludeSemantics: widget.excludeChildSemantics,
      enabled: widget._effectiveEnabled,
      checked: widget.value,
      mixed: widget.tristate && widget.value == null,
      focusable: true,
      focused: isFocused,
      inMutuallyExclusiveGroup: false,
      label: widget.semanticLabel,
      onTap: _semanticsTapHandler,
      onFocus: _semanticsFocusHandler,
      child: checkboxWidget,
    );
  }
}
