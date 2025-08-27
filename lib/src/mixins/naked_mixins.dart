// ignore_for_file: no-empty-block

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Mixin for widgets that support focus management.
/// Provides a contract for focus node and autofocus properties.
mixin NakedFocusable on StatefulWidget {
  /// Optional external focus node.
  /// If null, the widget will create and manage its own focus node.
  FocusNode? get focusNode;

  /// Whether this widget should be focused on initial build.
  bool get autofocus;

  ValueChanged<bool>? get onFocusChange;
}

/// State mixin that handles focus node lifecycle management.
///
/// This mixin only manages the lifecycle of focus nodes.
/// Widgets decide how to react to focus changes by overriding onFocusChange.
///
/// NOTE: This is the legacy focus mixin. For widgets using WidgetStatesController,
/// use NakedFocusableWithStatesMixin instead.
mixin NakedFocusableStateMixin<T extends NakedFocusable> on State<T> {
  FocusNode? _internalNode;
  late FocusNode effectiveFocusNode;

  @override
  void initState() {
    super.initState();

    // Create internal node if no external node provided
    if (widget.focusNode == null) {
      _internalNode = FocusNode();
    }

    // Set the effective node
    effectiveFocusNode = widget.focusNode ?? _internalNode!;

    // Listen for focus changes
    effectiveFocusNode.addListener(onFocusChange);

    // Handle autofocus if requested
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && effectiveFocusNode.canRequestFocus) {
          effectiveFocusNode.requestFocus();
        }
      });
    }
  }

  /// Override this to handle focus changes.
  @protected
  void onFocusChange() {
    widget.onFocusChange?.call(effectiveFocusNode.hasFocus);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only process if node actually changed (using identical for performance)
    if (!identical(oldWidget.focusNode, widget.focusNode)) {
      assert(() {
        debugPrint(
          '⚠️ FocusNode changed at runtime. '
          'Focus: ${effectiveFocusNode.hasFocus} → ${widget.focusNode?.hasFocus ?? false}',
        );

        return true;
      }());

      // Remove listener from old node
      effectiveFocusNode.removeListener(onFocusChange);

      // Handle internal node lifecycle
      if (widget.focusNode != null && _internalNode != null) {
        // Switching from internal to external - dispose internal
        _internalNode!.dispose();
        _internalNode = null;
      } else if (widget.focusNode == null && _internalNode == null) {
        // Switching from external to internal - create internal
        _internalNode = FocusNode();
      }

      // Set new effective node
      effectiveFocusNode = widget.focusNode ?? _internalNode!;

      // Add listener to new node
      effectiveFocusNode.addListener(onFocusChange);
    }
  }

  @override
  void dispose() {
    effectiveFocusNode.removeListener(onFocusChange);
    _internalNode?.dispose();
    super.dispose();
  }
}

// ==================== Widget States Controller Mixins ====================

/// Mixin for widgets that support WidgetStatesController management.
/// Provides a contract for states controller and change notifications.
mixin NakedWidgetStates on StatefulWidget {
  /// Optional external states controller.
  /// If null, the widget will create and manage its own controller.
  WidgetStatesController? get statesController;

  /// Called whenever the widget state set changes.
  ValueChanged<Set<WidgetState>>? get onStatesChange;
}

/// State mixin that handles WidgetStatesController lifecycle management.
///
/// Provides the base controller management that other state mixins depend on.
/// Handles listener management, external/internal controller switching, and
/// proper setState scheduling to avoid build-time setState calls.
mixin NakedWidgetStatesStateMixin<T extends NakedWidgetStates> on State<T> {
  WidgetStatesController? _internalController;

  WidgetStatesController get effectiveController =>
      widget.statesController ??
      (_internalController ??= createInternalController());

  /// Creates an internal controller with initial states.
  /// Override in mixins to provide specific initial states.
  @protected
  WidgetStatesController createInternalController() {
    return WidgetStatesController();
  }

  @override
  void initState() {
    super.initState();
    effectiveController.addListener(_handleStateChange);
  }

  /// Handles state controller changes and triggers rebuilds.
  void _handleStateChange() {
    widget.onStatesChange?.call({...effectiveController.value});
    if (mounted) {
      // ignore: avoid-empty-setstate
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (oldWidget.statesController != widget.statesController) {
      _handleControllerChange(oldWidget);
    }
  }

  /// Handles state controller changes between external and internal.
  void _handleControllerChange(T oldWidget) {
    // Remove listener from old controller
    final oldEffective = oldWidget.statesController ?? _internalController;
    oldEffective?.removeListener(_handleStateChange);

    // Handle internal controller lifecycle
    if (widget.statesController == null) {
      // Switching to internal controller
      _internalController ??= WidgetStatesController(
        oldWidget.statesController?.value ?? {},
      );
    } else {
      // Switching to external controller
      _internalController?.dispose();
      _internalController = null;
    }

    // Add listener to new controller
    effectiveController.addListener(_handleStateChange);
  }

  @override
  void dispose() {
    effectiveController.removeListener(_handleStateChange);
    _internalController?.dispose();
    super.dispose();
  }
}

/// Mixin for widgets that support selection state.
mixin NakedSelectable on StatefulWidget {
  /// Whether this widget is in a selected state.
  bool get selected;
}

/// State mixin that handles selected state management.
/// T must implement both NakedSelectable and NakedWidgetStates.
mixin NakedSelectableStateMixin<T extends NakedWidgetStates>
    on NakedWidgetStatesStateMixin<T> {
  @override
  WidgetStatesController createInternalController() {
    final controller = super.createInternalController();
    final selectable = widget as NakedSelectable;
    if (selectable.selected) {
      controller.value.add(WidgetState.selected);
    }

    return controller;
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSelectable = oldWidget as NakedSelectable;
    final newSelectable = widget as NakedSelectable;
    if (oldSelectable.selected != newSelectable.selected) {
      effectiveController.update(WidgetState.selected, newSelectable.selected);
    }
  }
}

/// Mixin for widgets that support error state.
mixin NakedErrorable on StatefulWidget {
  /// Whether this widget has an error state.
  bool get error;
}

/// State mixin that handles error state management.
/// T must implement both NakedErrorable and NakedWidgetStates.
mixin NakedErrorableStateMixin<T extends NakedWidgetStates>
    on NakedWidgetStatesStateMixin<T> {
  @override
  WidgetStatesController createInternalController() {
    final controller = super.createInternalController();
    final errorable = widget as NakedErrorable;
    if (errorable.error) {
      controller.value.add(WidgetState.error);
    }

    return controller;
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldErrorable = oldWidget as NakedErrorable;
    final newErrorable = widget as NakedErrorable;
    if (oldErrorable.error != newErrorable.error) {
      effectiveController.update(WidgetState.error, newErrorable.error);
    }
  }
}

/// Mixin for widgets that support enabled/disabled state.
mixin NakedEnableable on StatefulWidget {
  /// Whether this widget responds to input.
  bool get enabled;
}

/// State mixin that handles enabled/disabled state management.
/// Also clears transient states when becoming disabled.
/// T must implement both NakedEnableable and NakedWidgetStates.
mixin NakedEnableableStateMixin<T extends NakedWidgetStates>
    on NakedWidgetStatesStateMixin<T> {
  @override
  WidgetStatesController createInternalController() {
    final controller = super.createInternalController();
    final enableable = widget as NakedEnableable;
    if (!enableable.enabled) {
      controller.value.add(WidgetState.disabled);
    }

    return controller;
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldEnableable = oldWidget as NakedEnableable;
    final newEnableable = widget as NakedEnableable;

    if (oldEnableable.enabled != newEnableable.enabled) {
      effectiveController.update(WidgetState.disabled, !newEnableable.enabled);

      if (!newEnableable.enabled) {
        // Clear transient states when becoming disabled
        _clearTransientStates();
      }
    }
  }

  /// Clears transient states (hover, pressed, focused).
  void _clearTransientStates() {
    effectiveController
      ..update(WidgetState.hovered, false)
      ..update(WidgetState.pressed, false)
      ..update(WidgetState.focused, false);
  }
}

/// Mixin for widgets that support interactive states (hover, press).
mixin NakedInteractive on StatefulWidget {
  /// Called when the hover state changes.
  ValueChanged<bool>? get onHoverChange;

  /// Called when the pressed state changes.
  ValueChanged<bool>? get onPressChange;
}

/// State mixin that handles interactive states (hover, press) management.
/// Provides methods for handling pointer events and state updates.
/// T must implement both NakedInteractive and NakedWidgetStates.
mixin NakedInteractiveStateMixin<T extends NakedWidgetStates>
    on NakedWidgetStatesStateMixin<T> {
  bool _isPointerInside = false;

  /// Updates the hovered state and notifies listeners.
  void setHovered(bool value) {
    if (effectiveController.value.contains(WidgetState.disabled)) return;
    final interactive = widget as NakedInteractive;
    effectiveController.update(WidgetState.hovered, value);
    interactive.onHoverChange?.call(value);
  }

  /// Updates the pressed state and notifies listeners.
  void setPressed(bool value) {
    if (effectiveController.value.contains(WidgetState.disabled)) return;
    final interactive = widget as NakedInteractive;
    effectiveController.update(WidgetState.pressed, value);
    interactive.onPressChange?.call(value);
  }

  /// Clears the pressed state if it's currently active.
  void clearPressedState() {
    if (!effectiveController.value.contains(WidgetState.pressed)) return;
    final interactive = widget as NakedInteractive;
    effectiveController.update(WidgetState.pressed, false);
    interactive.onPressChange?.call(false);
  }

  // ==================== Pointer Event Handlers ====================

  /// Handles pointer entering the widget bounds.
  void handlePointerEnter(PointerEnterEvent _) {
    _isPointerInside = true;
    setHovered(true);
  }

  /// Handles pointer exiting the widget bounds.
  void handlePointerExit(PointerExitEvent _) {
    _isPointerInside = false;
    setHovered(false);
    clearPressedState();
  }

  /// Handles pointer down events.
  void handlePointerDown(PointerDownEvent _) {
    setPressed(true);
  }

  /// Handles pointer up events.
  void handlePointerUp(PointerUpEvent _) {
    clearPressedState();
  }

  /// Handles pointer cancel events.
  void handlePointerCancel(PointerCancelEvent _) {
    clearPressedState();
  }

  /// Handles pointer move events to track boundary crossings.
  void handlePointerMove(PointerMoveEvent event) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final isInside = box.size.contains(event.localPosition);
    if (isInside != _isPointerInside) {
      _isPointerInside = isInside;
    }

    // Clear pressed state when moving outside
    if (!isInside) {
      clearPressedState();
    }
  }
}

/// Enhanced focus mixin that integrates with WidgetStatesController.
/// Use this instead of NakedFocusableStateMixin for widgets with states controller.
/// T must implement both NakedFocusable and NakedWidgetStates.
mixin NakedFocusableWithStatesMixin<T extends NakedWidgetStates>
    on NakedWidgetStatesStateMixin<T> {
  FocusNode? _internalNode;
  late FocusNode effectiveFocusNode;

  @override
  void initState() {
    super.initState();

    final focusable = widget as NakedFocusable;
    // Create internal node if no external node provided
    if (focusable.focusNode == null) {
      _internalNode = FocusNode();
    }

    // Set the effective node
    effectiveFocusNode = focusable.focusNode ?? _internalNode!;

    // Listen for focus changes
    effectiveFocusNode.addListener(_onFocusChange);

    // Handle autofocus if requested
    if (focusable.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && effectiveFocusNode.canRequestFocus) {
          effectiveFocusNode.requestFocus();
        }
      });
    }
  }

  /// Handles focus state changes and updates the controller.
  void _onFocusChange() {
    final focused = effectiveFocusNode.hasFocus;
    final focusable = widget as NakedFocusable;
    effectiveController.update(WidgetState.focused, focused);
    focusable.onFocusChange?.call(focused);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldFocusable = oldWidget as NakedFocusable;
    final newFocusable = widget as NakedFocusable;
    // Only process if node actually changed (using identical for performance)
    if (!identical(oldFocusable.focusNode, newFocusable.focusNode)) {
      assert(() {
        debugPrint(
          '⚠️ FocusNode changed at runtime. '
          'Focus: ${effectiveFocusNode.hasFocus} → ${newFocusable.focusNode?.hasFocus ?? false}',
        );

        return true;
      }());

      // Remove listener from old node
      effectiveFocusNode.removeListener(_onFocusChange);

      // Handle internal node lifecycle
      if (newFocusable.focusNode != null && _internalNode != null) {
        // Switching from internal to external - dispose internal
        _internalNode!.dispose();
        _internalNode = null;
      } else if (newFocusable.focusNode == null && _internalNode == null) {
        // Switching from external to internal - create internal
        _internalNode = FocusNode();
      }

      // Set new effective node
      effectiveFocusNode = newFocusable.focusNode ?? _internalNode!;

      // Add listener to new node
      effectiveFocusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    effectiveFocusNode.removeListener(_onFocusChange);
    _internalNode?.dispose();
    super.dispose();
  }
}
