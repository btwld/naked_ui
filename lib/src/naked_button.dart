import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// A fully customizable button with no default styling.
///
/// NakedButton provides interaction behavior and accessibility features
/// without imposing any visual styling, giving consumers complete design freedom.
/// It integrates with [FocusableActionDetector] to provide enhanced keyboard accessibility,
/// hover detection, and focus management.
///
/// This component handles various interaction states (hover, pressed, focused, disabled, loading)
/// and provides direct callbacks to allow consumers to manage their own visual state.
///
/// Example:
/// ```dart
/// class MyButton extends StatefulWidget {
///   @override
///   _MyButtonState createState() => _MyButtonState();
/// }
///
/// class _MyButtonState extends State<MyButton> {
///   bool _isHovered = false;
///   bool _isPressed = false;
///   bool _isFocused = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return NakedButton(
///       onPressed: () {
///         print('Button pressed!');
///       },
///       onHoveredState: (isHovered) => setState(() => _isHovered = isHovered),
///       onPressedState: (isPressed) => setState(() => _isPressed = isPressed),
///       onFocusedState: (isFocused) => setState(() => _isFocused = isFocused),
///       child: Container(
///         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
///         decoration: BoxDecoration(
///           color: _isPressed
///               ? Colors.blue.shade700
///               : _isHovered
///                   ? Colors.blue.shade600
///                   : Colors.blue.shade500,
///           borderRadius: BorderRadius.circular(4),
///           border: Border.all(
///             color: _isFocused ? Colors.white : Colors.transparent,
///             width: 2,
///           ),
///         ),
///         child: Text(
///           'Click Me',
///           style: TextStyle(color: Colors.white),
///         ),
///       ),
///     );
///   }
/// }
/// ```
class NakedButton extends StatefulWidget {
  /// Creates a naked button.
  const NakedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onHoveredState,
    this.onPressedState,
    this.onFocusedState,
    this.onDisabledState,
    this.enabled = true,
    this.isSemanticButton = true,
    this.semanticLabel,
    this.cursor = SystemMouseCursors.click,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// The child widget to display.
  ///
  /// This widget should represent the visual appearance of the button.
  /// You're responsible for styling this widget based on the button's state
  /// using the provided callback properties.
  final Widget child;

  /// Called when the button is tapped or activated via keyboard.
  ///
  /// If null, the button will be considered disabled and will not respond
  /// to user interaction.
  final VoidCallback? onPressed;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoveredState;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressedState;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusedState;

  /// Called when disabled state changes.
  final ValueChanged<bool>? onDisabledState;

  /// Whether the button is enabled.
  final bool enabled;

  /// Whether the button should be treated as a semantic button.
  final bool isSemanticButton;

  /// The semantic label for the button.
  ///
  /// This label will be used to describe the button to users of assistive technologies.
  final String? semanticLabel;

  /// The cursor to show when hovering over the button.
  ///
  /// Defaults to [SystemMouseCursors.click] when enabled,
  /// or [SystemMouseCursors.forbidden] when disabled.
  final MouseCursor cursor;

  /// Whether to provide haptic feedback on press.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  ///
  /// If not provided, the button will create its own focus node.
  final FocusNode? focusNode;

  /// Whether the button should be focused when first built.
  final bool autofocus;

  bool get _isInteractive => enabled && onPressed != null;

  @override
  State<NakedButton> createState() => _NakedButtonState();
}

class _NakedButtonState extends State<NakedButton> {
  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: handleTap),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: handleTap,
    ),
  };

  void handleTap([Intent? intent]) {
    if (!widget._isInteractive) return;
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }

  @override
  void initState() {
    super.initState();
    // Safe to call synchronously in initState
    widget.onDisabledState?.call(!widget._isInteractive);
  }

  @override
  void didUpdateWidget(NakedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._isInteractive != widget._isInteractive) {
      widget.onDisabledState?.call(!widget._isInteractive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      enabled: widget._isInteractive,
      button: widget.isSemanticButton,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: widget._isInteractive,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        actions: _actionMap,
        onShowHoverHighlight: widget.onHoveredState,
        onFocusChange: widget.onFocusedState,
        mouseCursor: widget._isInteractive
            ? widget.cursor
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: widget._isInteractive ? (_) => widget.onPressedState?.call(true) : null,
          onTapUp: widget._isInteractive ? (_) => widget.onPressedState?.call(false) : null,
          onTap: widget._isInteractive ? handleTap : null,
          onTapCancel: widget._isInteractive ? () => widget.onPressedState?.call(false) : null,
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        ),
      ),
    );
  }
}
