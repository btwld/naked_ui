import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'naked_button.dart';
import 'utilities/utilities.dart';

/// A fully customizable menu with no default styling.
///
/// NakedMenu provides interaction behavior and accessibility features
/// for a dropdown menu without imposing any visual styling,
/// giving consumers complete control over appearance through direct state callbacks.
///
/// This component uses Flutter's OverlayPortal to render menu content in the app overlay,
/// ensuring proper z-index and maintaining context inheritance across the component tree.
///
/// Example:
/// ```dart
/// final controller = OverlayPortalController();
///
/// NakedMenu(
///   builder: (_) => NakedButton(
///     onPressed: () => controller.show(),
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
///   controller: controller,
///   onClose: () => controller.hide(),
/// )
/// ```
///
/// The menu is controlled through the [controller] and [onClose] callback.
/// When open, the menu content will be positioned relative to the target using [menuAlignment]
/// and any offset specified in the PositionConfig. If the menu doesn't fit in the preferred position,
/// it will try the positions specified in [fallbackAlignments].
///
/// Focus management and keyboard navigation are handled automatically. The menu can be closed
/// by pressing Escape, clicking outside (if [consumeOutsideTaps] is true), or selecting an
/// item (if [closeOnSelect] is true). When opened, focus is automatically moved to the menu
/// content.
///
/// For accessibility, the menu supports screen readers and keyboard navigation.
/// Menu items should use [NakedMenuItem] which provides proper interaction states
/// and accessibility features.
class NakedMenu extends StatelessWidget {
  /// Create a naked menu.
  ///
  /// The [builder] and [overlayBuilder] parameters are required.
  /// The [builder] is the widget that triggers the menu (typically a button).
  /// The [overlayBuilder] is the content to display when open.
  const NakedMenu({
    super.key,
    required this.builder,
    required this.overlayBuilder,
    required this.controller,
    this.onClose,
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.closeOnSelect = true,
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
  /// This is typically a button or other interactive element.
  final WidgetBuilder builder;

  /// The menu widget to display when open.
  /// This is the content displayed in the overlay when the menu is open.
  final WidgetBuilder overlayBuilder;

  /// Called when the menu should close.
  final VoidCallback? onClose;

  /// Whether to close the menu when an item is selected.
  final bool closeOnSelect;

  /// Whether to automatically focus the menu when opened.
  /// Note: This property is included for future implementation but currently has no effect.
  final bool autofocus;

  /// The alignment of the menu relative to its target.
  /// Specifies how the menu should be positioned.
  final NakedMenuPosition menuPosition;

  /// Fallback alignments to try if the menu doesn't fit in the preferred position.
  /// The menu will try each alignment in order until it finds one that fits.
  final List<NakedMenuPosition> fallbackPositions;

  /// The controller that manages the visibility of the menu.
  /// Use this to show, hide, or toggle the menu programmatically.
  final MenuController controller;

  /// Whether to consume outside taps.
  final bool consumeOutsideTaps;

  /// Whether to use the root overlay.
  final bool useRootOverlay;

  @override
  Widget build(BuildContext context) {
    return NakedMenuClose(
      close: closeOnSelect ? onClose : null,
      child: NakedMenuAnchor(
        controller: controller,
        overlayBuilder: overlayBuilder,
        useRootOverlay: useRootOverlay,
        consumeOutsideTaps: consumeOutsideTaps,
        position: menuPosition,
        fallbackPositions: fallbackPositions,
        onClose: onClose,
        child: builder(context),
      ),
    );
  }
}

/// An inherited widget that provides access to the menu's close method.
///
/// This widget allows descendant widgets to access the menu's close functionality
/// without having to pass it down through every level of the widget tree.
class NakedMenuClose extends InheritedWidget {
  /// Creates a naked menu close inherited widget.
  ///
  /// The [close] callback and [child] are required.
  const NakedMenuClose({super.key, required this.close, required super.child});

  /// Returns the closest [NakedMenuClose] widget in the widget tree.
  ///
  /// Throws a [StateError] if no [NakedMenuClose] widget is found.
  static NakedMenuClose of(BuildContext context) {
    final NakedMenuClose? result = context
        .dependOnInheritedWidgetOfExactType<NakedMenuClose>();
    assert(result != null, 'No NakedMenuClose found in context');

    return result!;
  }

  /// The callback to close the menu.
  final VoidCallback? close;

  @override
  bool updateShouldNotify(NakedMenuClose oldWidget) {
    return close != oldWidget.close;
  }
}

/// An individual menu item that can be selected.
///
/// This component provides interaction states (hover, press, focus) and
/// accessibility features for menu items. It handles keyboard navigation
/// and screen reader support.
class NakedMenuItem extends StatelessWidget {
  /// Creates a naked menu item.
  ///
  /// The [child] parameter is required and represents the item's content.
  /// Use [onPressed] to handle selection, and the state callbacks
  /// ([onHoverChange], [onPressChange], [onFocusChange]) to customize appearance.
  const NakedMenuItem({
    super.key,
    required this.child,
    this.onHoverChange,
    this.onPressChange,
    this.onFocusChange,
    this.onPressed,
    this.enabled = true,
    this.semanticLabel,
    this.cursor = SystemMouseCursors.click,
    this.enableHapticFeedback = true,
    this.focusNode,
  });

  /// The content to display in the menu item.
  final Widget child;

  /// Called when the hover state changes.
  /// Can be used to update visual feedback.
  final ValueChanged<bool>? onHoverChange;

  /// Called when the pressed state changes.
  /// Can be used to update visual feedback.
  final ValueChanged<bool>? onPressChange;

  /// Called when the focus state changes.
  /// Can be used to update visual feedback.
  final ValueChanged<bool>? onFocusChange;

  /// Called when the item is selected.
  final VoidCallback? onPressed;

  /// Whether the item is enabled and can be selected.
  final bool enabled;

  /// Optional semantic label for accessibility.
  /// Provides a description of the item's purpose for screen readers.
  final String? semanticLabel;

  /// The cursor to show when hovering over the item.
  final MouseCursor cursor;

  /// Whether to provide haptic feedback when selecting the item.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;


  @override
  Widget build(BuildContext context) {
    final menuState = NakedMenuClose.of(context);

    void onPress() {
      if (!enabled) return;
      if (enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
      onPressed?.call();
      if (menuState.close != null) {
        menuState.close!();
      }
    }

    return NakedButton(
      onPressed: onPressed != null ? onPress : null,
      onHoverChange: onHoverChange,
      onPressChange: onPressChange,
      onFocusChange: onFocusChange,
      enabled: enabled,
      semanticLabel: semanticLabel,
      cursor: cursor,
      enableHapticFeedback: enableHapticFeedback,
      focusNode: focusNode,
      child: child,
    );
  }
}
