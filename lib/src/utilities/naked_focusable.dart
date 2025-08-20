// Type definitions for cleaner API
import 'package:flutter/widgets.dart';

typedef WidgetStateBuilder =
    Widget Function(BuildContext context, Set<WidgetState> states);

// Extension for cleaner state checks
extension WidgetStateChecks on Set<WidgetState> {
  bool get isPressed => contains(WidgetState.pressed);
  bool get isHovered => contains(WidgetState.hovered);
  bool get isFocused => contains(WidgetState.focused);
  bool get isDisabled => contains(WidgetState.disabled);
}

/// Base widget for focus/hover states only
class NakedFocusable extends StatefulWidget {
  const NakedFocusable({
    super.key,
    required this.builder,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.actions,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
    this.onFocusChange,
    this.onHoverChange,
    this.mouseCursor,
  });

  final WidgetStateBuilder builder;
  final bool enabled;
  final WidgetStatesController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final MouseCursor? mouseCursor;
  final Map<Type, Action<Intent>>? actions;

  @override
  State<NakedFocusable> createState() => _NakedFocusableState();
}

class _NakedFocusableState extends State<NakedFocusable> {
  WidgetStatesController? _internalController;
  FocusNode? _internalFocusNode;

  WidgetStatesController get controller =>
      widget.controller ?? (_internalController ??= WidgetStatesController());

  FocusNode get focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool get isEnabled => widget.enabled;

  bool get canAutofocus => widget.autofocus && isEnabled;

  MouseCursor get effectiveCursor {
    if (widget.mouseCursor != null) return widget.mouseCursor!;
    if (!isEnabled) return SystemMouseCursors.forbidden;

    return MouseCursor.defer;
  }

  @override
  void initState() {
    super.initState();
    // Sync disabled state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncDisabledState();
    });
  }

  void _syncDisabledState() {
    controller.update(WidgetState.disabled, !isEnabled);
  }

  void _handleFocusHighlight(bool value) {
    if (!isEnabled) return;
    controller.update(WidgetState.focused, value);
    widget.onFocusChange?.call(value);
  }

  void _handleHoverHighlight(bool value) {
    if (!isEnabled) return;
    controller.update(WidgetState.hovered, value);
    widget.onHoverChange?.call(value);
  }

  @override
  void didUpdateWidget(NakedFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      _syncDisabledState();
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder handles rebuild optimization automatically
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => FocusableActionDetector(
        enabled: isEnabled,
        focusNode: focusNode,
        autofocus: canAutofocus,
        actions: widget.actions ?? const {},
        descendantsAreFocusable: widget.descendantsAreFocusable,
        descendantsAreTraversable: widget.descendantsAreTraversable,
        onShowFocusHighlight: _handleFocusHighlight,
        onShowHoverHighlight: _handleHoverHighlight,
        mouseCursor: effectiveCursor,
        child: widget.builder(context, controller.value),
      ),
    );
  }
}
