import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'naked_button.dart';
import 'utilities/utilities.dart';

/// Headless dropdown menu without default styling.
///
/// Renders menu content in overlay with proper z-index and focus management.
/// Positions relative to target with fallback support.
///
/// ```dart
/// final controller = MenuController();
///
/// NakedMenu(
///   controller: controller,
///   builder: (_) => NakedButton(
///     onPressed: controller.open,
///     child: Text('Open Menu'),
///   ),
///   overlayBuilder: (_) => YourMenuContent(),
/// )
/// ```
///
/// See also:
/// - [NakedMenuAnchor], which handles overlay placement, focus, and keyboard
///   traversal for this menu.
/// - [NakedButton], often used to build the trigger and items.
class NakedMenu extends StatelessWidget {
  /// Creates a headless menu.
  const NakedMenu({
    super.key,
    required this.builder,
    required this.overlayBuilder,
    required this.controller,
    this.onClose,
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.autofocus = false,
    this.menuPosition = const NakedMenuPosition(),
    this.fallbackPositions = const [
      NakedMenuPosition(
        target: Alignment.topLeft,
        follower: Alignment.bottomLeft,
      ),
    ],
  });

  /// The target widget that triggers the menu.
  final WidgetBuilder builder;

  /// The menu content to display when open.
  final WidgetBuilder overlayBuilder;

  /// Called when the menu closes.
  final VoidCallback? onClose;

  /// Whether to automatically focus the menu when opened.
  final bool autofocus;

  /// The menu position relative to its target.
  final NakedMenuPosition menuPosition;

  /// The fallback positions if preferred doesn't fit.
  final List<NakedMenuPosition> fallbackPositions;

  /// The controller that manages menu visibility.
  final MenuController controller;

  /// Whether to consume outside taps.
  final bool consumeOutsideTaps;

  /// Whether to use the root overlay.
  final bool useRootOverlay;

  @override
  Widget build(BuildContext context) {
    return NakedMenuAnchor(
      controller: controller,
      overlayBuilder: overlayBuilder,
      useRootOverlay: useRootOverlay,
      consumeOutsideTaps: consumeOutsideTaps,
      position: menuPosition,
      fallbackPositions: fallbackPositions,
      onClose: onClose,
      child: builder(context),
    );
  }
}

/// Selectable menu item with interaction states and accessibility.
///
/// See also:
/// - [NakedMenu], the container that provides the overlay and positioning.
/// - [NakedButton], the headless activator used to implement this item.
class NakedMenuItem extends StatelessWidget {
  /// Creates a menu item.
  const NakedMenuItem({
    super.key,
    this.child,
    this.onPressed,
    this.enabled = true,
    this.closeOnSelect = true,
    this.mouseCursor = SystemMouseCursors.click,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
    this.builder,
    this.semanticLabel,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// The item content.
  final Widget? child;

  /// Called when the item is selected.
  final VoidCallback? onPressed;

  /// Whether to close the menu when selected.
  final bool closeOnSelect;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when press state changes.
  final ValueChanged<bool>? onPressChange;

  /// Builder that receives current interaction states.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Whether the item is enabled.
  final bool enabled;

  /// Whether this menu item is effectively enabled.
  bool get _effectiveEnabled => enabled && onPressed != null;

  /// The cursor when hovering over the item.
  final MouseCursor mouseCursor;

  /// Whether to provide haptic feedback on selection.
  final bool enableFeedback;

  /// The focus node for the item.
  final FocusNode? focusNode;

  /// Whether to autofocus when created.
  final bool autofocus;

  /// The semantic label for accessibility.
  final String? semanticLabel;

  void _handlePress(MenuController? controller) {
    if (!_effectiveEnabled) return;
    if (enableFeedback) {
      HapticFeedback.lightImpact();
    }
    onPressed?.call();
    if (closeOnSelect) {
      controller?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = MenuController.maybeOf(context);

    void onPress() => _handlePress(controller);

    return NakedButton(
      onPressed: _effectiveEnabled ? onPress : null,
      enabled: _effectiveEnabled,
      mouseCursor: mouseCursor,
      enableFeedback: enableFeedback,
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: onFocusChange,
      onHoverChange: onHoverChange,
      onPressChange: onPressChange,
      tooltip: semanticLabel,
      child: child,
      builder: builder != null
          ? (context, states, child) => builder!(context, states, child)
          : null,
    );
  }
}
