import 'package:flutter/widgets.dart';

/// Widget states management mixin.
///
/// Purpose:
/// - Manage widget interaction states internally using a Set<WidgetState>
/// - Provide updateState method to change states and trigger rebuilds
/// - Emit individual state change callbacks when states actually change
/// - Offer convenient helper methods for common state updates
/// - Provide readable getter properties for state checking
///
/// How to use:
/// - mixin on a State class: `with WidgetStatesMixin<YourWidget>`
/// - use helper methods like [updateHoverState], [updateFocusState], [updatePressState]
/// - use getter properties like [isFocused], [isHovered], [isPressed] for state checking
/// - override [initializeWidgetStates] to set initial states based on widget properties
///
/// Example:
/// ```dart
/// class _MyWidgetState extends State<MyWidget>
///     with WidgetStatesMixin<MyWidget> {
///
///   @override
///   void initializeWidgetStates() {
///     updateDisabledState(!widget.enabled);
///   }
///
///   Widget build(BuildContext context) {
///     return FocusableActionDetector(
///       enabled: widget.enabled,
///       onHoverChange: (hovered) => updateHoverState(hovered, widget.onHoverChange),
///       onFocusChange: (focused) => updateFocusState(focused, widget.onFocusChange),
///       child: MyChild(isPressed: isPressed),
///     );
///   }
/// }
/// ```
mixin WidgetStatesMixin<T extends StatefulWidget> on State<T> {
  Set<WidgetState> _widgetStates = <WidgetState>{};

  /// Current widget states (copy) for use in builders and semantics.
  @protected
  Set<WidgetState> get widgetStates => {..._widgetStates};

  /// Whether the widget currently has keyboard focus.
  @protected
  bool get isFocused => _widgetStates.contains(WidgetState.focused);

  /// Whether the widget is currently being hovered over by a mouse cursor.
  @protected
  bool get isHovered => _widgetStates.contains(WidgetState.hovered);

  /// Whether the widget is currently being pressed.
  @protected
  bool get isPressed => _widgetStates.contains(WidgetState.pressed);

  /// Whether the widget is disabled and cannot be interacted with.
  @protected
  bool get isDisabled => _widgetStates.contains(WidgetState.disabled);

  /// Whether the widget is currently selected.
  @protected
  bool get isSelected => _widgetStates.contains(WidgetState.selected);

  /// Whether the widget is enabled (not disabled).
  @protected
  bool get isEnabled => !isDisabled;

  /// Hook for widgets to initialize states based on widget properties.
  /// Called during initialization and when widget updates.
  @protected
  // ignore: no-empty-block
  void initializeWidgetStates() {
    // Default implementation does nothing - override in concrete widgets
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    initializeWidgetStates();
  }

  /// Call this method from your widget's didUpdateWidget to sync states.
  @protected
  void syncWidgetStates() {
    // Update states based on current widget properties
    initializeWidgetStates();
  }

  /// Change-detecting state update. Returns true if the value actually changed.
  @protected
  // ignore: prefer-named-boolean-parameters
  bool updateState(WidgetState state, bool value) {
    final before = _widgetStates.contains(state);
    if (before == value) return false;

    if (value) {
      _widgetStates.add(state);
    } else {
      _widgetStates.remove(state);
    }

    if (mounted) {
      // ignore: avoid-empty-setstate, no-empty-block
      setState(() {}); // Trigger rebuild when widget state changes
    }

    return true;
  }

  /// Update hover state and fire callback only if the state actually changed.
  @protected
  // ignore: prefer-named-boolean-parameters
  bool updateHoverState(bool value, ValueChanged<bool>? onHoverChange) {
    if (updateState(WidgetState.hovered, value)) {
      onHoverChange?.call(value);

      return true;
    }

    return false;
  }

  /// Update focus state and fire callback only if the state actually changed.
  @protected
  // ignore: prefer-named-boolean-parameters
  bool updateFocusState(bool value, ValueChanged<bool>? onFocusChange) {
    if (updateState(WidgetState.focused, value)) {
      onFocusChange?.call(value);

      return true;
    }

    return false;
  }

  /// Update press state and fire callback only if the state actually changed.
  @protected
  // ignore: prefer-named-boolean-parameters
  bool updatePressState(bool value, ValueChanged<bool>? onPressChange) {
    if (updateState(WidgetState.pressed, value)) {
      onPressChange?.call(value);

      return true;
    }

    return false;
  }

  /// Update disabled state. Returns true if the state actually changed.
  @protected
  bool updateDisabledState(bool value) {
    return updateState(WidgetState.disabled, value);
  }

  /// Update selected state and fire callback only if the state actually changed.
  @protected
  // ignore: prefer-named-boolean-parameters
  bool updateSelectedState(bool value, ValueChanged<bool>? onSelectedChange) {
    if (updateState(WidgetState.selected, value)) {
      onSelectedChange?.call(value);

      return true;
    }

    return false;
  }
}

/// Press listener mixin: stateless helper that forwards press lifecycle via callbacks.
///
/// Behavior:
///  - Emits onPressChange(true) on pointer down
///  - Emits onPressChange(false) when pointer moves outside, on up, or cancel
///
/// Usage:
///  - mixin on a State class: `with PressListenerMixin<YourWidget>`
///  - call [buildPressListener] to wrap your child
mixin PressListenerMixin<T extends StatefulWidget> on State<T> {
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

/// Reusable focus lifecycle for headless widgets.
///
/// Responsibilities:
/// - Provide an internal FocusNode when the widget doesn't supply one
/// - Swap safely between external <-> internal nodes at runtime
/// - Preserve focus across swaps (post-frame handoff)
/// - Expose the single source of truth: [effectiveFocusNode]
///
/// Host requirements:
/// - The host State must implement [focusableExternalNode] to surface any
///   user-provided FocusNode (typically `widget.focusNode`).
///
/// Mixin order:
/// - Place this mixin to the RIGHT of other mixins so its overrides participate
///   correctly in `super.*` chaining, e.g.:
///   `class _State extends State<W>
///       with SomeMixin<W>, FocusableMixin<W> { ... }`
mixin FocusableMixin<T extends StatefulWidget> on State<T> {
  /// The FocusNode provided by the widget (external). May be null.
  @protected
  FocusNode? get focusableExternalNode;

  FocusNode? _internalFocusNode;
  FocusNode? _lastExternalNode;

  /// The node actually used by the widget: external if provided, otherwise internal.
  @protected
  FocusNode? get effectiveFocusNode =>
      focusableExternalNode ?? _internalFocusNode;

  /// Request focus on whichever node is effective right now.
  @protected
  void requestEffectiveFocus() => effectiveFocusNode?.requestFocus();

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    _lastExternalNode = focusableExternalNode;

    // Create an internal node only if the host didn't provide one.
    if (_lastExternalNode == null) {
      _internalFocusNode = FocusNode(
        debugLabel: '${widget.runtimeType} (internal)',
      );
    }
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);

    final FocusNode? newExternal = focusableExternalNode;
    if (identical(newExternal, _lastExternalNode)) {
      return; // No change in external node presence/identity.
    }

    // Capture whether the previously effective node had focus.
    final bool hadFocus = (effectiveFocusNode?.hasFocus ?? false);

    // Handle transitions:
    // - internal -> external : dispose internal
    // - external -> internal : create internal
    // - external(A) -> external(B) : just switch references
    if (_lastExternalNode == null && newExternal != null) {
      // Adopt external.
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    } else if (_lastExternalNode != null && newExternal == null) {
      // Fall back to a fresh internal node.
      _internalFocusNode = FocusNode(
        debugLabel: '${widget.runtimeType} (internal)',
      );
    } // else: external changed to another external; nothing to allocate/dispose.

    _lastExternalNode = newExternal;

    // Preserve focus across the swap on the next frame.
    if (hadFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          effectiveFocusNode?.requestFocus();
        }
      });
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    _lastExternalNode = null;
    super.dispose();
  }
}
