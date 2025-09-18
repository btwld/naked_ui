import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'naked_button.dart';
import 'utilities/anchored_overlay_shell.dart';
import 'utilities/positioning.dart';

/// A headless dropdown menu without visuals.
///
/// Renders menu content in overlay with proper z-index and focus management.
/// Positions relative to target with fallback support.
///
/// See also:
/// - [NakedButton], often used to build the trigger and items.
/// - [NakedSelect], for select-style list with type-ahead and multi-select.
/// - [NakedPopover], for non-menu anchored overlays.
class NakedMenu extends StatelessWidget {
  /// Creates a headless menu.
  const NakedMenu({
    super.key,
    required this.builder,
    required this.overlayBuilder,
    required this.controller,
    this.onOpen,
    this.onClose,
    this.onOpenRequested,
    this.onCloseRequested,
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.closeOnClickOutside = true,
    this.triggerFocusNode,
    this.positioning = const OverlayPositionConfig(),
  });

  static void _defaultOnOpenRequested(
    Offset? position,
    VoidCallback showOverlay,
  ) {
    showOverlay();
  }

  static void _defaultOnCloseRequested(VoidCallback hideOverlay) {
    hideOverlay();
  }

  /// The target widget that triggers the menu.
  final WidgetBuilder builder;

  /// The menu content to display when open.
  final WidgetBuilder overlayBuilder;

  /// Called when the menu opens.
  final VoidCallback? onOpen;

  /// Called when the menu closes.
  final VoidCallback? onClose;

  /// Called when a request is made to open the menu.
  ///
  /// This callback allows you to customize the opening behavior, such as
  /// adding animations or delays. Call `showOverlay` to actually show the menu.
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  /// Called when a request is made to close the menu.
  ///
  /// This callback allows you to customize the closing behavior, such as
  /// adding animations or delays. Call `hideOverlay` to actually hide the menu.
  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  /// Whether clicking outside closes the menu.
  final bool closeOnClickOutside;

  /// Focus node for the trigger widget.
  final FocusNode? triggerFocusNode;

  /// Positioning configuration for the overlay.
  final OverlayPositionConfig positioning;

  /// The controller that manages menu visibility.
  final MenuController controller;

  /// The outside tap consumption flag.
  final bool consumeOutsideTaps;

  /// The root overlay usage flag.
  final bool useRootOverlay;

  @override
  Widget build(BuildContext context) {
    return AnchoredOverlayShell(
      controller: controller,
      overlayBuilder: overlayBuilder,
      onOpen: onOpen,
      onClose: onClose,
      onOpenRequested: onOpenRequested ?? _defaultOnOpenRequested,
      onCloseRequested: onCloseRequested ?? _defaultOnCloseRequested,
      consumeOutsideTaps: consumeOutsideTaps,
      useRootOverlay: useRootOverlay,
      closeOnClickOutside: closeOnClickOutside,
      triggerFocusNode: triggerFocusNode,
      // Use only the offset for simple positioning; other fields are ignored
      // by the shell to keep behavior simple and robust.
      offset: positioning.offset,
      child: builder(context),
    );
  }
}

/// A headless menu item without visuals.
///
/// Provides interaction states and accessibility for custom styling.
///
/// Example:
/// ```dart
/// NakedMenu(
///   builder: (context) => Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       NakedMenuItem(child: Text('Item 1'), onPressed: () {}),
///     ],
///   ),
/// )
/// ```
///
/// See also:
/// - [NakedMenu], the container that provides overlay and positioning.
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

  /// The menu close flag when selected.
  final bool closeOnSelect;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when press state changes.
  final ValueChanged<bool>? onPressChange;

  /// Builder that receives current interaction states.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  /// The enabled state of the item.
  final bool enabled;

  /// Whether this menu item is effectively enabled.
  bool get _effectiveEnabled => enabled && onPressed != null;

  /// The mouse cursor for the item.
  final MouseCursor mouseCursor;

  /// The haptic feedback enablement flag.
  final bool enableFeedback;

  /// The focus node for the item.
  final FocusNode? focusNode;

  /// The autofocus flag.
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
      semanticLabel: semanticLabel,
      child: child,
      builder: builder,
    );
  }
}
