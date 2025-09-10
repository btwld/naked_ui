import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Focus mixin: manages FocusNode lifecycle and provides a builder.
///
/// Usage:
///   - mixin on a State class: `with NakedFocusableMixin<YourWidget>`
///   - implement [providedFocusNode] to supply an external FocusNode (or return null)
///   - call [buildFocus] to wrap your child
mixin NakedFocusableMixin<T extends StatefulWidget> on State<T> {
  FocusNode? _internalNode;
  bool _usingExternal = false;
  FocusNode? _observedFocusNode;

  @protected
  FocusNode? get providedFocusNode;

  @protected
  String get focusDebugLabel => 'NakedFocusableMixin<$T>';

  @protected
  FocusNode get effectiveFocusNode => providedFocusNode ?? _internalNode!;

  @mustCallSuper
  @override
  void initState() {
    super.initState();
    _usingExternal = providedFocusNode != null;
    if (!_usingExternal) {
      _internalNode = FocusNode(debugLabel: focusDebugLabel);
    }
    // Observe focus changes to trigger rebuilds (for semantics parity, etc.)
    _rebindFocusListener();
  }

  @mustCallSuper
  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newUsingExternal = providedFocusNode != null;
    if (_usingExternal && !newUsingExternal) {
      _internalNode = FocusNode(debugLabel: focusDebugLabel);
    } else if (!_usingExternal && newUsingExternal) {
      _internalNode?.dispose();
      _internalNode = null;
    }
    _usingExternal = newUsingExternal;
    _rebindFocusListener();
  }

  @mustCallSuper
  @override
  void dispose() {
    _observedFocusNode?.removeListener(_onFocusChanged);
    _observedFocusNode = null;
    _internalNode?.dispose();
    _internalNode = null;
    super.dispose();
  }

  @protected
  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _rebindFocusListener() {
    final node = effectiveFocusNode;
    if (!identical(node, _observedFocusNode)) {
      _observedFocusNode?.removeListener(_onFocusChanged);
      _observedFocusNode = node..addListener(_onFocusChanged);
    }
  }

  Widget buildFocus({
    Key? key,
    required Widget child,
    bool autofocus = false,
    ValueChanged<bool>? onFocusChange,
    bool canRequestFocus = true,
    bool descendantsAreFocusable = true,
    bool skipTraversal = false,
    bool includeSemantics = true,
  }) {
    return Focus(
      key: key,
      focusNode: effectiveFocusNode,
      autofocus: autofocus,
      onFocusChange: onFocusChange,
      canRequestFocus: canRequestFocus,
      skipTraversal: skipTraversal,
      descendantsAreFocusable: descendantsAreFocusable,
      includeSemantics: includeSemantics,
      child: child,
    );
  }
}

/// Hover mixin: tracks isHovered and provides a MouseRegion builder.
///
/// Usage:
///   - mixin on a State class: `with NakedHoverableMixin<YourWidget>`
///   - call [buildHoverRegion] to wrap your child
mixin NakedHoverableMixin<T extends StatefulWidget> on State<T> {
  @protected
  Widget buildHoverRegion({
    Key? key,
    required Widget child,
    MouseCursor cursor = MouseCursor.defer,
    bool opaque = false,
    ValueChanged<bool>? onHoverChange,
    void Function(PointerHoverEvent)? onHover,
  }) {
    return MouseRegion(
      key: key,
      onEnter: (_) => onHoverChange?.call(true),
      onExit: (_) => onHoverChange?.call(false),
      onHover: onHover,
      cursor: cursor,
      opaque: opaque,
      child: child,
    );
  }
}

/// Simplified helper for managing a WidgetStatesController lifecycle.
///
/// Purpose:
/// - Provide an "effective" controller (external when provided, otherwise internal)
/// - Handle listener attach/detach and controller swapping
/// - Sync widget properties to controller states via syncWidgetStates hook
///
/// How to use:
/// - mixin on a State class: `with WidgetStatesControllerMixin<YourWidget>`
/// - implement the protected getters:
///   * `WidgetStatesController? get providedStatesController`
///   * `ValueChanged<Set<WidgetState>>? get onStatesChange` (optional)
/// - implement `syncWidgetStates()` to sync widget props to controller
/// - use [updateState] to update interaction flags like focused/hovered/pressed
mixin WidgetStatesControllerMixin<T extends StatefulWidget> on State<T> {
  WidgetStatesController? _internalStatesController;
  WidgetStatesController? _currentController;
  Set<WidgetState> _lastStates = <WidgetState>{};

  @protected
  WidgetStatesController? get providedStatesController;

  /// Optional callback to notify consumers when the state set changes.
  @protected
  ValueChanged<Set<WidgetState>>? get onStatesChange;

  @protected
  WidgetStatesController get effectiveStatesController {
    return providedStatesController ??
        (_internalStatesController ??= WidgetStatesController());
  }

  /// Hook for widgets to synchronize widget properties to controller states.
  /// Called automatically during initialization and after controller swaps.
  @protected
  void syncWidgetStates(WidgetStatesController controller);

  void _handleControllerChanged() {
    final statesCopy = {...effectiveStatesController.value};
    onStatesChange?.call(statesCopy);
    // Update last snapshot after notifying
    _lastStates = statesCopy;
    if (mounted) {
      // ignore: avoid-empty-setstate, no-empty-block
      setState(() {});
    }
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    _currentController = effectiveStatesController;
    _currentController!.addListener(_handleControllerChanged);
    // Initialize last snapshot BEFORE first sync so deltas are computed correctly
    _lastStates = {..._currentController!.value};
    syncWidgetStates(_currentController!);
  }

  /// Call this method from your widget's didUpdateWidget to handle controller changes
  /// and sync states when needed.
  @protected
  void syncStatesController() {
    final newController = effectiveStatesController;
    if (!identical(_currentController, newController)) {
      // Controller changed - swap listeners
      _currentController?.removeListener(_handleControllerChanged);
      _currentController = newController;
      _currentController!.addListener(_handleControllerChanged);
    }
    // Reset last snapshot to current before syncing props
    _lastStates = {...?_currentController?.value};
    // Always sync widget states after potential swaps
    syncWidgetStates(_currentController!);
  }

  /// Change-detecting state update. Returns true if the value actually changed.
  @protected
  // ignore: prefer-named-boolean-parameters
  bool updateState(WidgetState state, bool value) {
    final ctrl = effectiveStatesController;
    final before = ctrl.value.contains(state);
    if (before == value) return false;
    ctrl.update(state, value);

    return true;
  }

  /// Helper method to emit both unified and individual state change callbacks.
  /// Only emits individual callbacks when their value actually changed.
  @protected
  void emitStateCallbacks({
    required Set<WidgetState> states,
    ValueChanged<Set<WidgetState>>? onStatesChange,
    ValueChanged<bool>? onFocusChange,
    ValueChanged<bool>? onHoverChange,
    ValueChanged<bool>? onPressChange,
  }) {
    // Call unified callback first
    onStatesChange?.call(states);

    // Delta-based emission for individual callbacks
    final prev = _lastStates;
    final focusedNow = states.contains(WidgetState.focused);
    final focusedBefore = prev.contains(WidgetState.focused);
    if (focusedNow != focusedBefore) {
      onFocusChange?.call(focusedNow);
    }

    final hoveredNow = states.contains(WidgetState.hovered);
    final hoveredBefore = prev.contains(WidgetState.hovered);
    if (hoveredNow != hoveredBefore) {
      onHoverChange?.call(hoveredNow);
    }

    final pressedNow = states.contains(WidgetState.pressed);
    final pressedBefore = prev.contains(WidgetState.pressed);
    if (pressedNow != pressedBefore) {
      onPressChange?.call(pressedNow);
    }
  }

  /// Current states snapshot (copy) for convenience.
  @protected
  Set<WidgetState> get currentStates => {...effectiveStatesController.value};

  @override
  @mustCallSuper
  void dispose() {
    _currentController?.removeListener(_handleControllerChanged);
    _internalStatesController?.dispose();
    super.dispose();
  }
}

/// Press listener mixin: stateless helper that forwards press lifecycle via callbacks.
///
/// Behavior:
///  - Emits onPressChange(true) on pointer down
///  - Emits onPressChange(false) when pointer moves outside, on up, or cancel
///
/// Usage:
///  - mixin on a State class: `with NakedPressableListenerMixin<YourWidget>`
///  - call [buildPressListener] to wrap your child
mixin NakedPressableListenerMixin<T extends StatefulWidget> on State<T> {
  @protected
  bool _isPointerWithinBounds(Offset localPosition) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;

    return box != null && box.size.contains(localPosition);
  }

  @protected
  Widget buildPressListener({
    Key? key,
    required Widget child,
    bool enabled = true,
    HitTestBehavior behavior = HitTestBehavior.opaque,
    ValueChanged<bool>? onPressChange,
  }) {
    if (!enabled) {
      // Clear pressed when disabled
      onPressChange?.call(false);

      return Listener(behavior: behavior, child: child);
    }

    return Listener(
      key: key,
      onPointerDown: (event) {
        onPressChange?.call(true);
      },
      onPointerMove: (event) {
        if (!_isPointerWithinBounds(event.localPosition)) {
          onPressChange?.call(false);
        }
      },
      onPointerUp: (event) {
        onPressChange?.call(false);
      },
      onPointerCancel: (event) {
        onPressChange?.call(false);
      },
      behavior: behavior,
      child: child,
    );
  }
}

/// Press mixin (GestureDetector): stateless helper that forwards press lifecycle.
///
/// Behavior:
///  - Emits onPressChange(true) on tap down
///  - Emits onPressChange(false) on tap up or cancel
///  - Does not track out-of-bounds drag; use the Listener-based mixin if needed
///
/// Usage:
///  - mixin on a State class: `with NakedPressableMixin<YourWidget>`
///  - call [buildPressDetector] to wrap your child
mixin NakedPressableMixin<T extends StatefulWidget> on State<T> {
  @protected
  Widget buildPressDetector({
    Key? key,
    required Widget child,
    bool enabled = true,
    HitTestBehavior behavior = HitTestBehavior.opaque,
    bool excludeFromSemantics = false,
    ValueChanged<bool>? onPressChange,
    VoidCallback? onTap,
    GestureTapDownCallback? onTapDown,
    GestureTapUpCallback? onTapUp,
    GestureTapCancelCallback? onTapCancel,
    VoidCallback? onDoubleTap,
    GestureLongPressCallback? onLongPress,
  }) {
    if (!enabled) {
      onPressChange?.call(false);

      return Listener(behavior: behavior, child: child);
    }

    return GestureDetector(
      key: key,
      onTapDown: (details) {
        onPressChange?.call(true);
        onTapDown?.call(details);
      },
      onTapUp: (details) {
        onPressChange?.call(false);
        onTapUp?.call(details);
      },
      onTap: onTap,
      onTapCancel: () {
        onPressChange?.call(false);
        onTapCancel?.call();
      },
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      behavior: behavior,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }
}

// Selectable mixin: helps compute next selected value and activation behavior.
// Intended for checkbox/radio/switch-like controls.
mixin NakedSelectableMixin<T extends StatefulWidget> on State<T> {
  /// Computes the next selection state based on current [selected] and [tristate].
  ///
  /// Tristate cycle (Material-compatible): null → false → true → null
  /// Binary toggle: treat null as false, then toggle.
  @protected
  bool? computeNextSelected({required bool? selected, required bool tristate}) {
    if (tristate) {
      if (selected == null) return false;
      if (selected == false) return true;

      return null; // true → null
    }
    final current = selected ?? false;

    return !current;
  }

  /// Handles activation (e.g., tap/keyboard) by emitting selectionClick
  /// feedback and calling [onChanged] with the computed next value.
  @protected
  void handleSelectableActivation({
    required bool? selected,
    required bool tristate,
    required ValueChanged<bool?>? onChanged,
    bool enableFeedback = true,
  }) {
    if (onChanged == null) return;
    if (enableFeedback) {
      HapticFeedback.selectionClick();
    }
    final nextValue = computeNextSelected(
      selected: selected,
      tristate: tristate,
    );
    onChanged(nextValue);
  }
}
