import 'package:flutter/widgets.dart';

/// Widget states management mixin.
///
/// Purpose:
/// - Manage widget interaction states internally using a `Set<WidgetState>`
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
///     return NakedFocusableDetector(
///       enabled: widget.enabled,
///       onHoverChange: (hovered) =>
///           updateHoverState(hovered, widget.onHoverChange),
///       onFocusChange: (focused) =>
///           updateFocusState(focused, widget.onFocusChange),
///       child: MyChild(isPressed: isPressed),
///     );
///   }
/// }
/// ```
mixin WidgetStatesMixin<T extends StatefulWidget> on State<T> {
  final Set<WidgetState> _widgetStates = <WidgetState>{};

  /// Current widget states (copy) for use in builders and semantics.
  Set<WidgetState> get widgetStates => {..._widgetStates};

  /// Whether the widget currently has keyboard focus.
  bool get isFocused => _widgetStates.contains(WidgetState.focused);

  /// Whether the widget is currently being hovered over by a mouse cursor.
  bool get isHovered => _widgetStates.contains(WidgetState.hovered);

  /// Whether the widget is currently being pressed.
  bool get isPressed => _widgetStates.contains(WidgetState.pressed);

  /// Whether the widget is disabled and cannot be interacted with.
  bool get isDisabled => _widgetStates.contains(WidgetState.disabled);

  /// Whether the widget is currently selected.
  bool get isSelected => _widgetStates.contains(WidgetState.selected);

  /// Whether the widget is enabled (not disabled).
  bool get isEnabled => !isDisabled;

  /// Hook for widgets to initialize states based on widget properties.
  ///
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
  bool updateState(WidgetState state, bool value) {
    final before = _widgetStates.contains(state);
    if (before == value) return false;

    if (value) {
      _widgetStates.add(state);
    } else {
      _widgetStates.remove(state);
    }

    if (mounted) {
      // ignore: no-empty-block
      setState(() {}); // Trigger rebuild when widget state changes
    }

    return true;
  }

  /// Update hover state and fire callback only if the state actually changed.
  @protected
  bool updateHoverState(bool value, ValueChanged<bool>? onHoverChange) {
    if (updateState(WidgetState.hovered, value)) {
      onHoverChange?.call(value);

      return true;
    }

    return false;
  }

  /// Update focus state and fire callback only if the state actually changed.
  @protected
  bool updateFocusState(bool value, ValueChanged<bool>? onFocusChange) {
    if (updateState(WidgetState.focused, value)) {
      onFocusChange?.call(value);

      return true;
    }

    return false;
  }

  /// Update press state and fire callback only if the state actually changed.
  @protected
  bool updatePressState(bool value, ValueChanged<bool>? onPressChange) {
    if (updateState(WidgetState.pressed, value)) {
      onPressChange?.call(value);

      return true;
    }

    return false;
  }

  /// Clears transient interaction states after a control becomes disabled.
  ///
  /// Observer callbacks run after the current build so a callback that updates
  /// the parent cannot mark an ancestor dirty while that ancestor is building.
  @protected
  void clearInteractionStates({
    ValueChanged<bool>? onHoverChange,
    ValueChanged<bool>? onFocusChange,
    ValueChanged<bool>? onPressChange,
    VoidCallback? onPressCleared,
  }) {
    final clearedHover = _widgetStates.remove(WidgetState.hovered);
    final clearedFocus = _widgetStates.remove(WidgetState.focused);
    final clearedPress = _widgetStates.remove(WidgetState.pressed);
    if (!clearedHover && !clearedFocus && !clearedPress) return;

    if (mounted) {
      // ignore: no-empty-block
      setState(() {});
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (clearedHover && !isHovered) onHoverChange?.call(false);
      if (clearedFocus && !isFocused) onFocusChange?.call(false);
      if (clearedPress && !isPressed) {
        onPressChange?.call(false);
        onPressCleared?.call();
      }
    });
  }

  /// Update disabled state. Returns true if the state actually changed.
  @protected
  bool updateDisabledState(bool value) {
    return updateState(WidgetState.disabled, value);
  }

  /// Update error state. Returns true if the state actually changed.
  @protected
  bool updateErrorState(bool value) {
    return updateState(WidgetState.error, value);
  }

  /// Update selected state and fire callback only if the state actually changed.
  @protected
  bool updateSelectedState(bool value, ValueChanged<bool>? onSelectedChange) {
    if (updateState(WidgetState.selected, value)) {
      onSelectedChange?.call(value);

      return true;
    }

    return false;
  }
}

/// Reusable focus lifecycle for headless widgets.
///
/// Responsibilities:
/// - Provide an internal FocusNode when the widget doesn't supply one
/// - Swap safely between external and internal nodes at runtime
/// - Preserve focus across swaps (post-frame handoff)
/// - Expose the single source of truth: [effectiveFocusNode]
///
/// Host requirements:
/// - The host State must implement [widgetProvidedNode] to surface any
///   user-provided FocusNode (typically `widget.focusNode`).
///
/// Mixin order:
/// - Place this mixin to the right of other mixins so its overrides participate
///   correctly in `super.*` chaining. The focus-node mixin should be the final
///   mixin applied to the widget's [State].
mixin FocusNodeMixin<T extends StatefulWidget> on State<T> {
  /// The caller-owned focus node, or null to use an internal node.
  @protected
  FocusNode? get widgetProvidedNode;

  /// Optional hook for subclasses to react to focus changes.
  @protected
  ValueChanged<bool>? get onFocusChange => null;

  /// Debug label used when creating an internal focus node.
  @protected
  String get focusNodeDebugLabel => '${widget.runtimeType} (internal)';

  FocusNode? _internalFocusNode;
  FocusNode? _lastExternalNode;

  /// The active focus node, whether caller-owned or internally managed.
  FocusNode get effectiveFocusNode => widgetProvidedNode ?? _internalFocusNode!;

  void _notifyFocusChanged() {
    final focused = effectiveFocusNode.hasFocus;
    onFocusChange?.call(focused);
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    _lastExternalNode = widgetProvidedNode;
    if (_lastExternalNode == null) {
      _internalFocusNode = FocusNode(debugLabel: focusNodeDebugLabel);
    }
    effectiveFocusNode.addListener(_notifyFocusChanged);
  }

  /// Requests focus for [effectiveFocusNode].
  void requestEffectiveFocus() {
    effectiveFocusNode.requestFocus();
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);

    // BEFORE: snapshot and (later) detach listener safely
    // [widgetProvidedNode] already reflects the new widget here. Read the old
    // node from the mixin's snapshot so external → internal swaps do not try
    // to dereference an internal node before it has been created.
    final FocusNode oldEffective = _lastExternalNode ?? _internalFocusNode!;
    final FocusNode? newExternal = widgetProvidedNode;

    // Nothing changed wrt external node identity → no swap needed
    if (identical(newExternal, _lastExternalNode)) {
      return;
    }

    final bool hadFocus = oldEffective.hasFocus;

    // Detach BEFORE we might dispose the old node
    oldEffective.removeListener(_notifyFocusChanged);

    // Transition handling
    if (_lastExternalNode == null && newExternal != null) {
      // internal -> external
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    } else if (_lastExternalNode != null && newExternal == null) {
      // external -> internal
      _internalFocusNode = FocusNode(debugLabel: focusNodeDebugLabel);
    }
    _lastExternalNode = newExternal;

    // AFTER: recompute from the updated fields using a different initializer
    final FocusNode? newEffective = _lastExternalNode ?? _internalFocusNode;

    // Reattach listener to the current effective node
    newEffective?.addListener(_notifyFocusChanged);

    // Preserve focus across the swap
    if (hadFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) newEffective?.requestFocus();
      });
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    effectiveFocusNode.removeListener(_notifyFocusChanged);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    _lastExternalNode = null;
    super.dispose();
  }
}
