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
