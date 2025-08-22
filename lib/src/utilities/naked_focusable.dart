// Type definitions for cleaner API
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef WidgetStateBuilder = Widget Function(WidgetStatesDelta states);

// Extension for cleaner state checks
extension WidgetStateChecks on Set<WidgetState> {
  bool get isPressed => contains(WidgetState.pressed);
  bool get isHovered => contains(WidgetState.hovered);
  bool get isFocused => contains(WidgetState.focused);
  bool get isDisabled => contains(WidgetState.disabled);
  bool get isSelected => contains(WidgetState.selected);
  bool get isError => contains(WidgetState.error);
  bool get isDragged => contains(WidgetState.dragged);
}

/// Base widget for focus/hover states only
class NakedFocusable extends StatefulWidget {
  const NakedFocusable({
    super.key,
    required this.builder,
    this.enabled = true,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
    this.actions,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
    this.onFocusChange,
    this.onHoverChange,
    this.onStateChange,
    this.mouseCursor,
  });

  final WidgetStateBuilder builder;
  final bool enabled;
  final WidgetStatesController? statesController;
  final FocusNode? focusNode;
  final bool autofocus;

  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<WidgetStatesDelta>? onStateChange;
  final MouseCursor? mouseCursor;
  final Map<Type, Action<Intent>>? actions;

  @override
  State<NakedFocusable> createState() => _NakedFocusableState();
}

typedef WidgetStatesDelta = ({
  Set<WidgetState> previous,
  Set<WidgetState> current,
});

extension WidgetStateDeltaExtension on WidgetStatesDelta {
  bool get hasChanged => !setEquals(previous, current);
  bool get isPressed => current.isPressed;
  bool get isHovered => current.isHovered;
  bool get isFocused => current.isFocused;
  bool get isDisabled => current.isDisabled;
  bool get isSelected => current.isSelected;
  bool get hoveredHasChanged => isHovered != previous.isHovered;
  bool get focusedHasChanged => isFocused != previous.isFocused;
  bool get pressedHasChanged => isPressed != previous.isPressed;
  bool get disabledHasChanged => isDisabled != previous.isDisabled;
  bool get selectedHasChanged => isSelected != previous.isSelected;
}

class _NakedFocusableState extends State<NakedFocusable> {
  WidgetStatesController? _internalStateController;
  FocusNode? _internalFocusNode;
  late WidgetStatesDelta _currentDelta;

  /// The state controller (provided or internal)
  WidgetStatesController get stateController =>
      widget.statesController ??
      (_internalStateController ??= WidgetStatesController());

  /// The focus node (provided or internal)
  FocusNode get focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  /// Whether the widget is enabled and can receive focus/hover
  bool get isEnabled => widget.enabled;

  /// Whether the widget should autofocus (only if enabled)
  bool get canAutofocus => widget.autofocus && isEnabled;

  /// Computes the effective mouse cursor based on widget state
  MouseCursor get effectiveCursor {
    // 1. Explicit cursor always takes precedence
    if (widget.mouseCursor != null) return widget.mouseCursor!;

    // 2. Disabled state shows forbidden cursor
    if (!isEnabled) return SystemMouseCursors.forbidden;

    // 3. Default to defer (let parent decide)
    return MouseCursor.defer;
  }

  @override
  void initState() {
    super.initState();
    // Set initial disabled state
    stateController.update(WidgetState.disabled, !isEnabled);
    _currentDelta = (
      previous: <WidgetState>{},
      current: {...stateController.value},
    );
    stateController.addListener(_onStateChange);
  }

  /// Handles state changes and rebuilds only when state actually changes
  void _onStateChange() {
    final newDelta = (
      previous: _currentDelta.current,
      current: {...stateController.value},
    );

    // Only update and rebuild if there's an actual change
    if (!setEquals(newDelta.current, _currentDelta.current)) {
      setState(() {
        _currentDelta = newDelta;
      });

      // Notify listener after setState
      if (widget.onStateChange != null) {
        widget.onStateChange!(newDelta);
      }
    }
  }

  /// Handles focus state changes
  void _handleFocusChange(bool focused) {
    if (!isEnabled) return;
    stateController.update(WidgetState.focused, focused);
    widget.onFocusChange?.call(focused);
  }

  /// Handles hover state changes
  void _handleHoverHighlight(bool value) {
    if (!isEnabled) return;
    stateController.update(WidgetState.hovered, value);
    widget.onHoverChange?.call(value);
  }

  @override
  void didUpdateWidget(NakedFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update disabled state if it actually changed
    if (oldWidget.enabled != widget.enabled) {
      stateController.update(WidgetState.disabled, !isEnabled);
    }
  }

  @override
  void dispose() {
    stateController.removeListener(_onStateChange);
    _internalStateController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: isEnabled,
      focusNode: focusNode,
      autofocus: canAutofocus,
      descendantsAreFocusable: widget.descendantsAreFocusable,
      descendantsAreTraversable: widget.descendantsAreTraversable,
      actions: widget.actions ?? const {},
      onShowFocusHighlight: _handleFocusChange,
      onShowHoverHighlight: _handleHoverHighlight,
      onFocusChange: _handleFocusChange,
      mouseCursor: effectiveCursor,
      child: widget.builder(_currentDelta),
    );
  }
}
