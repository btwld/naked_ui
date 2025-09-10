import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mixins/naked_mixins.dart';

/// Headless switch built with mixins for proper semantics and callbacks.
class NakedSwitch extends StatefulWidget {
  const NakedSwitch({
    super.key,
    this.child,
    required this.value,
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
    this.focusOnPress = false,
  }) : assert(
         value != null,
         'NakedSwitch is binary and requires a non-null value.',
       ),
       assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// Visual representation of the switch.
  final Widget? child;

  /// Whether this switch is on.
  final bool? value;

  /// Called when the switch is toggled.
  final ValueChanged<bool?>? onChanged;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when highlight (pressed) state changes.
  final ValueChanged<bool>? onPressChange;


  /// Whether the switch is enabled.
  final bool enabled;

  /// Cursor when hovering over the switch.
  final MouseCursor? mouseCursor;

  /// Whether to provide haptic feedback on tap.
  final bool enableFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to autofocus when created.
  final bool autofocus;

  /// Optional builder that receives the current states for visuals.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Whether to request focus when the switch is pressed.
  final bool focusOnPress;

  bool get _effectiveEnabled => enabled && onChanged != null;

  @override
  State<NakedSwitch> createState() => _NakedSwitchState();
}

class _NakedSwitchState extends State<NakedSwitch>
    with
        SimpleWidgetStatesMixin<NakedSwitch>,
        NakedFocusableMixin<NakedSwitch>,
        NakedHoverableMixin<NakedSwitch>,
        NakedPressableMixin<NakedSwitch>,
        NakedSelectableMixin<NakedSwitch> {
  @override
  void initializeWidgetStates() {
    updateState(WidgetState.disabled, !widget.enabled);
  }


  @override
  FocusNode? get providedFocusNode => widget.focusNode;

  @override
  String get focusDebugLabel => 'NakedSwitch';

  void _handleKeyboardActivation([Intent? _]) {
    if (!widget._effectiveEnabled) return;

    _handleActivation();
  }

  void _handleActivation() {
    if (!widget._effectiveEnabled) return;

    handleSelectableActivation(
      selected: widget.value,
      tristate: false, // Switch is binary
      onChanged: widget.onChanged,
      enableFeedback: widget.enableFeedback,
    );
  }


  void _handleTapDown(TapDownDetails _) {
    if (widget.focusOnPress && providedFocusNode != null) {
      providedFocusNode!.requestFocus();
    }
  }

  Widget _buildContent(BuildContext context) {
    final states = widgetStates;

    return widget.builder != null
        ? widget.builder!(context, states, widget.child)
        : widget.child!;
  }

  @override
  void didUpdateWidget(covariant NakedSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncWidgetStates();
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
          onFocusChange: (focused) {
            if (updateState(WidgetState.focused, focused)) {
              widget.onFocusChange?.call(focused);
            }
          },
          includeSemantics: false,
          child: Semantics(
            enabled: widget._effectiveEnabled,
            toggled: widget.value,
            onTap: _semanticsTapHandler,
            onFocus: _semanticsFocusHandler,
            child: buildHoverRegion(
              cursor: _effectiveCursor,
              onHoverChange: (hovered) {
                if (widget.enabled && updateState(WidgetState.hovered, hovered)) {
                  widget.onHoverChange?.call(hovered);
                }
              },
              child: buildPressDetector(
                enabled: widget.enabled,
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: false,
                onPressChange: (pressed) {
                  if (updateState(WidgetState.pressed, pressed)) {
                    widget.onPressChange?.call(pressed);
                  }
                },
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
