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
    this.stateController,
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
  final WidgetStatesController? stateController;
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
  WidgetStatesController? _internalStateController;
  FocusNode? _internalFocusNode;

  WidgetStatesController get stateController =>
      widget.stateController ?? (_internalStateController ??= WidgetStatesController());

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

  void _handleFocusChange(bool focused) {
    if (!isEnabled) return;
    stateController.update(WidgetState.focused, focused);
    widget.onFocusChange?.call(focused);
  }

  void _syncDisabledState() {
    stateController.update(WidgetState.disabled, !isEnabled);
  }

  void _handleFocusHighlight(bool value) {
    if (!isEnabled) return;
    stateController.update(WidgetState.focused, value);
    widget.onFocusChange?.call(value);
  }

  void _handleHoverHighlight(bool value) {
    if (!isEnabled) return;
    stateController.update(WidgetState.hovered, value);
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
    _internalStateController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder handles rebuild optimization automatically
    return ListenableBuilder(
      listenable: stateController,
      builder: (context, _) => FocusableActionDetector(
        enabled: isEnabled,
        focusNode: focusNode,
        autofocus: canAutofocus,
        descendantsAreFocusable: widget.descendantsAreFocusable,
        descendantsAreTraversable: widget.descendantsAreTraversable,
        actions: widget.actions ?? const {},
        onShowFocusHighlight: _handleFocusHighlight,
        onShowHoverHighlight: _handleHoverHighlight,
        onFocusChange: _handleFocusChange,
        mouseCursor: effectiveCursor,
        child: widget.builder(context, stateController.value),
      ),
    );
  }
}
