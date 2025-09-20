import 'package:flutter/material.dart';

/// Mixin that manages FocusNode lifecycle for widgets.
/// Handles internal node creation/disposal and external node switching.
mixin FocusNodeMixin<T extends StatefulWidget> on State<T> {
  FocusNode? _internalFocusNode;

  /// Get the external focus node from widget.
  FocusNode? get widgetFocusNode;

  /// Get the debug label for internal focus node.
  String get focusNodeDebugLabel => widget.runtimeType.toString();

  /// The effective focus node (external or internal).
  FocusNode get effectiveFocusNode => widgetFocusNode ?? _internalFocusNode!;

  /// Initialize focus node. Call in initState.
  @protected
  void initializeFocusNode() {
    if (widgetFocusNode == null) {
      _internalFocusNode = FocusNode(debugLabel: focusNodeDebugLabel);
    }
  }

  /// Update focus node when widget changes. Call in didUpdateWidget.
  @protected
  void updateFocusNode(covariant T oldWidget);

  /// Handle focus node switching between internal and external.
  @protected
  void handleFocusNodeChange(FocusNode? oldNode, FocusNode? newNode) {
    if (oldNode != newNode) {
      // Switching from internal to external - dispose internal
      if (oldNode == null && newNode != null && _internalFocusNode != null) {
        _internalFocusNode!.dispose();
        _internalFocusNode = null;
      }
      // Switching from external to internal - create internal
      else if (oldNode != null && newNode == null) {
        _internalFocusNode = FocusNode(debugLabel: focusNodeDebugLabel);
      }
    }
  }

  /// Dispose focus node. Call in dispose.
  @protected
  void disposeFocusNode() {
    _internalFocusNode?.dispose();
  }
}

/// Minimal widget that composes MouseRegion, Focus, Shortcuts, and Actions
/// based on what's actually needed. Exposes all Focus parameters for full control.
class NakedFocusableDetector extends StatefulWidget {
  const NakedFocusableDetector({
    super.key,
    required this.child,
    this.enabled = true,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
    this.skipTraversal = false,
    this.includeSemantics = true,
    this.onFocusChange,
    this.onHoverChange,
    this.onEnableChange,
    this.onKeyEvent,

    this.focusNode,
    this.mouseCursor,
    this.shortcuts,
    this.actions,
    this.debugLabel,
  });

  /// Widget to wrap with interaction detection.
  final Widget child;

  /// Whether this widget is enabled for interaction.
  final bool enabled;

  /// Whether to autofocus when first built.
  final bool autofocus;

  /// Whether this node can request focus.
  final bool canRequestFocus;

  /// Whether descendants can receive focus.
  final bool descendantsAreFocusable;

  /// Whether descendants are traversable.
  final bool descendantsAreTraversable;

  /// Whether to skip in traversal order.
  final bool skipTraversal;

  /// Whether to include focus semantics.
  final bool includeSemantics;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover state changes. Adds MouseRegion if provided.
  final ValueChanged<bool>? onHoverChange;

  /// Called when enabled state changes.
  final ValueChanged<bool>? onEnableChange;

  /// Raw keyboard event handler.
  final FocusOnKeyEventCallback? onKeyEvent;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Mouse cursor. Only used if onHoverChange is provided.
  final MouseCursor? mouseCursor;

  /// Keyboard shortcuts. Only applied if provided and enabled.
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// Intent actions. Only applied if provided and enabled.
  final Map<Type, Action<Intent>>? actions;

  /// Debug label for the focus node.
  final String? debugLabel;

  @override
  State<NakedFocusableDetector> createState() => _NakedFocusableDetectorState();
}

class _NakedFocusableDetectorState extends State<NakedFocusableDetector>
    with FocusNodeMixin<NakedFocusableDetector> {
  bool _wasEnabled = true;

  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  String get focusNodeDebugLabel =>
      widget.debugLabel ?? 'NakedFocusableDetector';

  @override
  void initState() {
    super.initState();
    initializeFocusNode();
    _wasEnabled = widget.enabled;
  }

  void _handleEnabledChange() {
    if (widget.onEnableChange != null && widget.enabled != _wasEnabled) {
      widget.onEnableChange!(widget.enabled);
    }
    _wasEnabled = widget.enabled;
  }

  @override
  void updateFocusNode(NakedFocusableDetector oldWidget) {
    handleFocusNodeChange(oldWidget.focusNode, widget.focusNode);
  }

  @override
  void didUpdateWidget(NakedFocusableDetector oldWidget) {
    super.didUpdateWidget(oldWidget);

    updateFocusNode(oldWidget);

    if (widget.enabled != oldWidget.enabled) {
      _handleEnabledChange();
    }
  }

  @override
  void dispose() {
    disposeFocusNode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check navigation mode to determine focus behavior
    final navigationMode =
        MediaQuery.maybeNavigationModeOf(context) ?? NavigationMode.traditional;
    final effectiveCanRequestFocus =
        navigationMode == NavigationMode.directional
        ? widget
              .canRequestFocus // Directional: disabled widgets stay traversable
        : widget.enabled &&
              widget.canRequestFocus; // Traditional: disabled = unfocusable

    // Start with Focus wrapping the child
    Widget result = Focus(
      focusNode: effectiveFocusNode,
      autofocus: widget.autofocus,
      onFocusChange: widget.onFocusChange,
      onKeyEvent: widget.onKeyEvent,

      canRequestFocus: effectiveCanRequestFocus,
      skipTraversal: widget.skipTraversal,
      descendantsAreFocusable: widget.descendantsAreFocusable,
      descendantsAreTraversable: widget.descendantsAreTraversable,
      includeSemantics: widget.includeSemantics,
      child: widget.child,
    );

    // Wrap with MouseRegion if hover detection is needed
    if (widget.onHoverChange != null) {
      result = MouseRegion(
        onEnter: (_) => widget.onHoverChange!(true),
        onExit: (_) => widget.onHoverChange!(false),
        cursor: widget.mouseCursor ?? MouseCursor.defer,
        child: result,
      );
    }

    // Add Actions if provided and enabled
    if (widget.enabled &&
        widget.actions != null &&
        widget.actions!.isNotEmpty) {
      result = Actions(actions: widget.actions!, child: result);
    }

    // Add Shortcuts last (outermost) if provided and enabled
    if (widget.enabled &&
        widget.shortcuts != null &&
        widget.shortcuts!.isNotEmpty) {
      result = Shortcuts(shortcuts: widget.shortcuts!, child: result);
    }

    return result;
  }
}
