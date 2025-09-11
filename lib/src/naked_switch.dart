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
    this.semanticLabel,
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

  /// Semantic label for accessibility.
  final String? semanticLabel;

  bool get _effectiveEnabled => enabled && onChanged != null;

  @override
  State<NakedSwitch> createState() => _NakedSwitchState();
}

class _NakedSwitchState extends State<NakedSwitch>
    with WidgetStatesMixin<NakedSwitch>, PressListenerMixin<NakedSwitch> {
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

    final current = widget.value ?? false;
    widget.onChanged!(!(current));
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
  }

  @override
  void didUpdateWidget(covariant NakedSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncWidgetStates();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
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
        // Let semantics merge into the FocusableActionDetector node so the
        // control exposes a single node with both focus and toggle semantics.
        enabled: widget._effectiveEnabled,
        toggled: widget.value,
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
    );
  }
}
