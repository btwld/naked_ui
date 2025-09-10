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
    this.onStatesChange,
    this.statesController,
    this.builder,
    this.focusOnPress = false,
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

  /// Called when any widget state changes.
  final ValueChanged<Set<WidgetState>>? onStatesChange;

  /// Optional external controller for interaction states.
  final WidgetStatesController? statesController;

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

  /// Whether to request focus when the checkbox is pressed.
  ///
  /// When true, tapping the checkbox will request focus in addition to
  /// toggling the value. This is useful for form controls where focus
  /// indication after interaction improves user experience.
  ///
  /// Defaults to false to maintain Material Design consistency.
  final bool focusOnPress;

  bool get _effectiveEnabled => enabled && onChanged != null;

  @override
  State<NakedCheckbox> createState() => _NakedCheckboxState();
}

class _NakedCheckboxState extends State<NakedCheckbox>
    with
        WidgetStatesControllerMixin<NakedCheckbox>,
        NakedFocusableMixin<NakedCheckbox>,
        NakedHoverableMixin<NakedCheckbox>,
        NakedPressableMixin<NakedCheckbox>,
        NakedSelectableMixin<NakedCheckbox> {
  // Bridge to mixins
  @override
  WidgetStatesController? get providedStatesController =>
      widget.statesController;

  @override
  ValueChanged<Set<WidgetState>>? get onStatesChange =>
      widget.onStatesChange != null ||
          widget.onFocusChange != null ||
          widget.onHoverChange != null ||
          widget.onPressChange != null
      ? (states) {
          emitStateCallbacks(
            states: states,
            onStatesChange: widget.onStatesChange,
            onFocusChange: widget.onFocusChange,
            onHoverChange: widget.onHoverChange,
            onPressChange: widget.onPressChange,
          );
        }
      : null;

  @override
  FocusNode? get providedFocusNode => widget.focusNode;

  @override
  String get focusDebugLabel => 'NakedCheckbox';

  void _handleKeyboardActivation([Intent? _]) {
    if (!widget._effectiveEnabled) return;

    _handleActivation();
  }

  void _handleActivation() {
    if (!widget._effectiveEnabled) return;

    handleSelectableActivation(
      selected: widget.value,
      tristate: widget.tristate,
      onChanged: widget.onChanged,
      enableFeedback: widget.enableFeedback,
    );
  }

  void _handleHoverChange(bool hovered) {
    if (widget.enabled) {
      updateState(WidgetState.hovered, hovered);
    }
  }

  void _handleFocusChange(bool focused) {
    updateState(WidgetState.focused, focused);
  }

  void _handlePressChange(bool pressed) {
    updateState(WidgetState.pressed, pressed);
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.focusOnPress && providedFocusNode != null) {
      providedFocusNode!.requestFocus();
    }
  }

  Widget _buildContent(BuildContext context) {
    final states = currentStates;

    return widget.builder != null
        ? widget.builder!(context, states, widget.child)
        : widget.child!;
  }

  @override
  void didUpdateWidget(covariant NakedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncStatesController();
  }

  @override
  void syncWidgetStates(WidgetStatesController controller) {
    // Only sync the disabled state from widget constructor props.
    controller.update(WidgetState.disabled, !widget.enabled);
  }

  MouseCursor get _effectiveCursor => widget._effectiveEnabled
      ? (widget.mouseCursor ?? SystemMouseCursors.click)
      : SystemMouseCursors.basic;

  VoidCallback? get _semanticsTapHandler =>
      widget._effectiveEnabled ? _handleActivation : null;

  VoidCallback get _semanticsFocusHandler =>
      () => providedFocusNode?.requestFocus();

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: _handleKeyboardActivation,
          ),
        },
        child: buildFocus(
          autofocus: widget.autofocus,
          onFocusChange: _handleFocusChange,
          includeSemantics: false,
          child: Semantics(
            enabled: widget._effectiveEnabled,
            checked: widget.value,
            mixed: widget.tristate && widget.value == null,
            onTap: _semanticsTapHandler,
            onFocus: _semanticsFocusHandler,
            child: buildHoverRegion(
              cursor: _effectiveCursor,
              onHoverChange: _handleHoverChange,
              child: buildPressDetector(
                enabled: widget.enabled,
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: false,
                onPressChange: _handlePressChange,
                onTap: widget._effectiveEnabled ? _handleActivation : null,
                onTapDown: _handleTapDown,
                child: _buildContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
