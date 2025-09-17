import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'mixins/naked_mixins.dart';

/// Headless checkbox that exposes states and semantics without visuals.
///
/// See also:
/// - [Checkbox], the Material-styled checkbox for typical apps.
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
  }) : assert(
         (tristate || value != null),
         'Non-tristate checkbox must have a non-null value',
       ),
       assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// The visual representation of the checkbox.
  final Widget? child;

  /// Whether the checkbox is checked.
  ///
  /// When [tristate] is true, null represents mixed state.
  final bool? value;

  /// Whether the checkbox supports a mixed state.
  ///
  /// When true, tapping cycles through false → true → null → false.
  /// When false, [value] must not be null.
  final bool tristate;

  /// Called when the checkbox value changes.
  final ValueChanged<bool?>? onChanged;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when press state changes.
  final ValueChanged<bool>? onPressChange;

  /// Whether the checkbox is enabled.
  final bool enabled;

  /// The cursor when hovering over the checkbox.
  final MouseCursor? mouseCursor;

  /// Whether to provide haptic feedback on tap.
  final bool enableFeedback;

  /// The focus node for the checkbox.
  final FocusNode? focusNode;

  /// Whether to autofocus when created.
  final bool autofocus;

  /// Builder that receives current interaction states.
  ///
  /// States include: disabled, focused, hovered, pressed, selected.
  /// The selected state reflects `value == true`.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// The semantic label for accessibility.
  final String? semanticLabel;

  bool get _effectiveEnabled => enabled && onChanged != null;

  @override
  State<NakedCheckbox> createState() => _NakedCheckboxState();
}

class _NakedCheckboxState extends State<NakedCheckbox>
    with WidgetStatesMixin<NakedCheckbox> {
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

  @override
  void initializeWidgetStates() {
    updateDisabledState(!widget.enabled);
    // Reflect current value into selected state for builder consumers.
    updateSelectedState(widget.value == true, null);
  }

  @override
  void didUpdateWidget(covariant NakedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncWidgetStates();
    if (oldWidget.value != widget.value) {
      updateSelectedState(widget.value == true, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: FocusableActionDetector(
        // Keyboard and focus handling
        enabled: widget._effectiveEnabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        // Use default includeFocusSemantics: true to let it handle focus semantics automatically
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
        child: Semantics(
          container: true,
          enabled: widget._effectiveEnabled,
          checked: widget.value == true,
          mixed: widget.tristate && widget.value == null,
          label: widget.semanticLabel,
          onTap: _semanticsTapHandler,
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
        ),
      ),
    );
  }
}
