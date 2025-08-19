import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'naked_button.dart';
import 'utilities/utilities.dart';

/// Provides dropdown menu behavior without visual styling.
///
/// Uses Flutter's OverlayPortal to render menu content in the app overlay,
/// ensuring proper z-index and context inheritance.
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
/// Controlled through [controller] and [onClose] callback. Positions relative to target,
/// trying fallback positions if needed. Handles focus management and keyboard navigation
/// automatically. Supports screen readers and accessibility.
///
/// Menu items should use [NakedMenuItem] for proper interaction states.
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

  /// Target widget that triggers the menu.
  final WidgetBuilder builder;

  /// Menu widget to display when open.
  final WidgetBuilder overlayBuilder;

  /// Called when the menu should close.
  final VoidCallback? onClose;

  /// Whether to close the menu when an item is selected.
  final bool closeOnSelect;

  /// Whether to automatically focus the menu when opened.
  /// Currently has no effect.
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

/// Provides access to the menu's close method.
///
/// Allows descendant widgets to access close functionality without prop drilling.
class NakedMenuClose extends InheritedWidget {
  /// Creates a naked menu close widget.
  const NakedMenuClose({super.key, required this.close, required super.child});

  /// Returns the closest [NakedMenuClose] widget.
  ///
  /// Throws [StateError] if none found.
  static NakedMenuClose of(BuildContext context) {
    final NakedMenuClose? result = context
        .dependOnInheritedWidgetOfExactType<NakedMenuClose>();
    assert(result != null, 'No NakedMenuClose found in context');

    return result!;
  }

  /// Callback to close the menu.
  final VoidCallback? close;

  @override
  bool updateShouldNotify(NakedMenuClose oldWidget) {
    return close != oldWidget.close;
  }
}

/// Individual menu item that can be selected.
///
/// Provides interaction states and accessibility features.
/// Handles keyboard navigation and screen reader support.
class NakedMenuItem extends StatelessWidget {
  /// Creates a naked menu item.
  ///
  /// Use [onPressed] for selection and state callbacks for appearance customization.
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

  /// Content to display in the menu item.
  final Widget child;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when the item is selected.
  final VoidCallback? onPressed;

  /// Whether the item can be selected.
  final bool enabled;

  /// Semantic label for screen readers.
  final String? semanticLabel;

  /// Cursor when hovering over the item.
  final MouseCursor cursor;

  /// Whether to provide haptic feedback on selection.
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
