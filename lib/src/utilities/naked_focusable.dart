// ABOUTME: Standalone focus management widget that wraps any child with focus behavior.
// ABOUTME: Handles focus node lifecycle, autofocus, and focus state change callbacks.
import 'package:flutter/widgets.dart';

/// Detects focus state changes for a widget.
///
/// This widget manages the lifecycle of a [FocusNode] and reports
/// focus changes through [onFocusChange].
///
/// If [focusNode] is provided, it will be used and not disposed.
/// If null, an internal [FocusNode] is created and disposed automatically.
///
/// Example:
/// ```dart
/// NakedFocusable(
///   autofocus: true,
///   onFocusChange: (focused) => print('Focus changed: $focused'),
///   child: Container(
///     padding: EdgeInsets.all(16),
///     color: Colors.blue,
///     child: Text('Focusable content'),
///   ),
/// )
/// ```
class NakedFocusable extends StatefulWidget {
  /// Creates a focus management widget.
  const NakedFocusable({
    super.key,
    required this.child,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// An optional focus node to use.
  /// If null, an internal node is created and managed.
  final FocusNode? focusNode;

  /// Whether this widget should be focused initially.
  final bool autofocus;

  /// Called when the focus state changes.
  final ValueChanged<bool>? onFocusChange;

  @override
  State<NakedFocusable> createState() => _NakedFocusableState();
}

class _NakedFocusableState extends State<NakedFocusable> {
  FocusNode? _internalNode;

  FocusNode get _effectiveNode => widget.focusNode ?? _internalNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalNode = FocusNode(debugLabel: 'NakedFocusable');
    }
  }

  @override
  void didUpdateWidget(NakedFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle switch from internal to external node
    if (oldWidget.focusNode == null && widget.focusNode != null) {
      _internalNode?.dispose();
      _internalNode = null;
    }
    // Handle switch from external to internal node
    else if (oldWidget.focusNode != null && widget.focusNode == null) {
      _internalNode = FocusNode(debugLabel: 'NakedFocusable');
    }
  }

  @override
  void dispose() {
    _internalNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _effectiveNode,
      autofocus: widget.autofocus,
      onFocusChange: widget.onFocusChange,
      child: widget.child,
    );
  }
}
