import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/widget_state_snapshot.dart';

/// Immutable view passed to [NakedCheckbox.builder].
class NakedCheckboxState extends NakedWidgetState {
  /// The current checked state (null for tristate intermediate).
  final bool? isChecked;

  /// Whether the checkbox is in tristate mode.
  final bool tristate;

  NakedCheckboxState({
    required super.states,
    required this.isChecked,
    required this.tristate,
  });

  /// Whether the checkbox is in intermediate/mixed state.
  bool get isIntermediate => tristate && isChecked == null;
}

/// A headless checkbox without visuals.
///
/// Builder receives [NakedCheckboxState] with checked value, tristate flag,
/// and interaction states for custom styling.
///
/// ```dart
/// NakedCheckbox(
///   value: isChecked,
///   onChanged: (value) => setState(() => isChecked = value),
///   child: MyCustomCheckboxUI(),
/// )
/// ```
///
/// See also:
/// - [Checkbox], the Material-styled checkbox for typical apps.
/// - [NakedToggle], for a headless binary toggle alternative.

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

  /// The current checked state.
  ///
  /// When [tristate] is true, null represents mixed state.
  final bool? value;

  /// The tristate support flag.
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

  /// The enabled state of the checkbox.
  final bool enabled;

  /// The mouse cursor for the checkbox.
  final MouseCursor? mouseCursor;

  /// The haptic feedback enablement flag.
  final bool enableFeedback;

  /// The focus node for the checkbox.
  final FocusNode? focusNode;

  /// The autofocus flag.
  final bool autofocus;

  /// The builder that receives current checkbox state.
  final NakedStateBuilder<NakedCheckboxState>? builder;

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
    final checkboxState = NakedCheckboxState(
      states: widgetStates,
      isChecked: widget.value,
      tristate: widget.tristate,
    );

    return widget.builder != null
        ? widget.builder!(context, checkboxState, widget.child)
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
      child: NakedFocusableDetector(
        // Keyboard and focus handling
        enabled: widget._effectiveEnabled,
        autofocus: widget.autofocus,
        onFocusChange: (focused) {
          updateFocusState(focused, widget.onFocusChange);
        },
        onHoverChange: (hovered) {
          updateHoverState(hovered, widget.onHoverChange);
        },
        focusNode: widget.focusNode,
        mouseCursor: _effectiveCursor,
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
