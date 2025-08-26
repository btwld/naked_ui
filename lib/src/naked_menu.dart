import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'naked_button.dart';
import 'utilities/utilities.dart';

/// Provides dropdown menu behavior without visual styling.
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
    this.semanticLabel,
    this.semanticHint,
    this.excludeSemantics = false,
    this.mouseCursor = SystemMouseCursors.click,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
    this.onStatesChange,
    this.statesController,
    this.builder,
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

  /// Called when any widget state changes.
  final ValueChanged<Set<WidgetState>>? onStatesChange;

  /// Optional external controller for interaction states.
  final WidgetStatesController? statesController;

  /// Optional builder that receives the current states for visuals.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// Whether the item can be selected.
  final bool enabled;

  /// Semantic label for screen readers.
  final String? semanticLabel;

  /// Semantic hint for screen readers.
  final String? semanticHint;

  /// Whether to exclude child semantics from the semantic tree.
  final bool excludeSemantics;

  /// Cursor when hovering over the item.
  final MouseCursor mouseCursor;

  /// Whether to provide haptic feedback on selection.
  final bool enableFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to automatically focus when created.
  final bool autofocus;

  void _handlePress(MenuController? controller) {
    if (!enabled) return;
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
      onPressed: onPressed != null ? onPress : null,
      enabled: enabled,
      isSemanticButton: true,
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      mouseCursor: mouseCursor,
      enableFeedback: enableFeedback,
      focusNode: focusNode,
      autofocus: autofocus,
      excludeSemantics: excludeSemantics,
      onFocusChange: onFocusChange,
      onHoverChange: onHoverChange,
      onPressChange: onPressChange,
      onStatesChange: onStatesChange,
      statesController: statesController,
      child: child,
      builder: builder != null
          ? (context, states, child) => builder!(context, states, child)
          : null,
    );
  }
}
