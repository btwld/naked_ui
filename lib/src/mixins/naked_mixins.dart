import 'package:flutter/gestures.dart';
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
      // ignore: no-empty-block
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

/// Headless press tracker:
/// - onPressChange(true) on primary pointer down
/// - onPressChange(false) when pointer leaves bounds, on up, or on cancel
/// - Re-activates when re-entering while still held (configurable)
class PressDetector extends StatefulWidget {
  const PressDetector({
    super.key,
    required this.child,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
    this.onPressChange,
    this.reactivateOnReenter = true,
    this.buttonsPredicate,
  });

  final Widget child;
  final bool enabled;
  final HitTestBehavior behavior;
  final ValueChanged<bool>? onPressChange;

  /// If true, pressing becomes true again when the active pointer re-enters.
  final bool reactivateOnReenter;

  /// Return true to accept a down event as the press "starter".
  /// Defaults: primary mouse button only; always true for touch/stylus.
  final bool Function(PointerDownEvent event)? buttonsPredicate;

  @override
  State<PressDetector> createState() => _PressDetectorState();
}

class _PressDetectorState extends State<PressDetector> {
  final GlobalKey _listenerKey = GlobalKey();
  int? _activePointer; // tracks the primary pointer id for this press sequence
  bool _pressed = false;

  bool _isInside(Offset localPosition) {
    final renderObject = _listenerKey.currentContext?.findRenderObject();
    final box = renderObject is RenderBox ? renderObject : null;
    if (box == null) return false;
    final size = box.size;

    return localPosition.dx >= 0 &&
        localPosition.dy >= 0 &&
        localPosition.dx <= size.width &&
        localPosition.dy <= size.height;
  }

  bool _defaultButtonsPredicate(PointerDownEvent e) {
    if (e.kind == PointerDeviceKind.mouse) {
      return e.buttons == kPrimaryButton; // primary button only
    }

    return true; // touch, stylus, trackpad
  }

  void _notify(bool value) {
    if (_pressed == value) return; // change-detect
    _pressed = value;
    widget.onPressChange?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final accept = widget.buttonsPredicate ?? _defaultButtonsPredicate;

    return Listener(
      key: _listenerKey,
      onPointerDown: (e) {
        if (!widget.enabled) return;
        if (_activePointer != null) return; // ignore additional touches
        if (!accept(e)) return;
        _activePointer = e.pointer;
        _notify(true);
      },
      onPointerMove: (e) {
        if (!widget.enabled) return;
        if (e.pointer != _activePointer) return;
        final inside = _isInside(e.localPosition);
        if (inside) {
          if (widget.reactivateOnReenter) _notify(true);
        } else {
          _notify(false);
        }
      },
      onPointerUp: (e) {
        if (e.pointer != _activePointer) return;
        _activePointer = null;
        _notify(false);
      },
      onPointerCancel: (e) {
        if (e.pointer != _activePointer) return;
        _activePointer = null;
        _notify(false);
      },
      behavior: widget.behavior,
      child: widget.child,
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
  @protected
  FocusNode? get focusableExternalNode;

  // NEW: optional hook; host can override to receive focus changes.
  @protected
  ValueChanged<bool>? get focusableOnFocusChange => null;

  FocusNode? _internalFocusNode;
  FocusNode? _lastExternalNode;

  @protected
  FocusNode? get effectiveFocusNode =>
      focusableExternalNode ?? _internalFocusNode;

  void _notifyFocusChanged() {
    final focused = effectiveFocusNode?.hasFocus ?? false;
    focusableOnFocusChange?.call(focused);
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    _lastExternalNode = focusableExternalNode;
    if (_lastExternalNode == null) {
      _internalFocusNode = FocusNode(
        debugLabel: '${widget.runtimeType} (internal)',
      );
    }
    effectiveFocusNode?.addListener(_notifyFocusChanged);
  }

  void requestEffectiveFocus() {
    effectiveFocusNode?.requestFocus();
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);

    // BEFORE: snapshot and (later) detach listener safely
    final FocusNode? oldEffective = effectiveFocusNode;
    final FocusNode? newExternal = focusableExternalNode;

    // Nothing changed wrt external node identity → no swap needed
    if (identical(newExternal, _lastExternalNode)) {
      return;
    }

    final bool hadFocus = oldEffective?.hasFocus ?? false;

    // Detach BEFORE we might dispose the old node
    oldEffective?.removeListener(_notifyFocusChanged);

    // Transition handling
    if (_lastExternalNode == null && newExternal != null) {
      // internal -> external
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    } else if (_lastExternalNode != null && newExternal == null) {
      // external -> internal
      _internalFocusNode = FocusNode(
        debugLabel: '${widget.runtimeType} (internal)',
      );
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
    effectiveFocusNode?.removeListener(_notifyFocusChanged);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    _lastExternalNode = null;
    super.dispose();
  }
}
