import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'naked_button.dart';
import 'utilities/utilities.dart';

/// A headless dropdown menu without default styling.
///
/// Uses Flutter's RawMenuAnchor to render menu content in the app overlay,
/// ensuring proper z-index and context inheritance.
///
/// Example:
/// ```dart
/// final controller = MenuController();
///
/// NakedMenu(
///   controller: controller,
///   builder: (_) => NakedButton(
///     onPressed: () => controller.open(),
///     child: const Text('Open Menu'),
///   ),
///   overlayBuilder: (_) => Container(
///     decoration: BoxDecoration(
///       color: Colors.white,
///       borderRadius: BorderRadius.circular(8),
///       border: Border.all(color: Colors.grey),
///     ),
///     constraints: const BoxConstraints(
///       minWidth: 100,
///     ),
///     child: Column(
///       mainAxisSize: MainAxisSize.min,
///       children: [
///         NakedMenuItem(
///           onPressed: () => print('Item 1'),
///           child: const Text('Item 1'),
///         ),
///         NakedMenuItem(
///           onPressed: () => print('Item 2'),
///           child: const Text('Item 2'),
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
///
/// Controlled through [controller]. Positions relative to target,
/// trying fallback positions if needed. Handles focus management and keyboard navigation
/// automatically. Supports screen readers and accessibility.
///
/// Menu items use [NakedMenuItem] and automatically close the menu when selected
/// unless [NakedMenuItem.closeOnSelect] is set to false.
///
/// See also:
/// - [NakedMenuAnchor], which handles overlay placement, focus, and keyboard
///   traversal for this menu.
/// - [NakedButton], often used to build the trigger and items.
class NakedMenu extends StatelessWidget {
  /// Creates a naked menu.
  ///
  /// The [builder] triggers the menu, [overlayBuilder] provides the menu content.
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

  /// Target widget that triggers the menu.
  final WidgetBuilder builder;

  /// Menu widget to display when open.
  final WidgetBuilder overlayBuilder;

  /// Called when the menu should close.
  final VoidCallback? onClose;

  /// Whether to automatically focus the menu when opened.
  final bool autofocus;

  /// Alignment of the menu relative to its target.
  final NakedMenuPosition menuPosition;

  /// Fallback alignments if the preferred position doesn't fit.
  final List<NakedMenuPosition> fallbackPositions;

  /// Controller that manages menu visibility.
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

/// Individual menu item that can be selected.
///
/// Provides interaction states and accessibility features.
/// Handles keyboard navigation and screen reader support.
///
/// See also:
/// - [NakedMenu], the container that provides the overlay and positioning.
/// - [NakedButton], the headless activator used to implement this item.
class NakedMenuItem extends StatelessWidget {
  /// Creates a naked menu item.
  ///
  /// Use [onPressed] for selection and state callbacks for appearance customization.
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

  /// Content to display in the menu item.
  final Widget? child;

  /// Called when the item is selected.
  final VoidCallback? onPressed;

  /// Whether to automatically close the menu when this item is selected.
  /// Defaults to true for typical menu behavior.
  final bool closeOnSelect;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when highlight (pressed) state changes.
  final ValueChanged<bool>? onPressChange;

  /// Optional builder that receives the current states for visuals.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Whether the item can be selected.
  final bool enabled;

  /// Whether this menu item is effectively enabled (has enabled=true AND has onPressed callback).
  bool get _effectiveEnabled => enabled && onPressed != null;

  /// Cursor when hovering over the item.
  final MouseCursor mouseCursor;

  /// Whether to provide haptic feedback on selection.
  final bool enableFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to automatically focus when created.
  final bool autofocus;

  /// Semantic label for accessibility (forwarded as a tooltip on the trigger).
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
