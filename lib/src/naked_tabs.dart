import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable tabs component with no default styling.
///
/// Provides interaction behavior and keyboard navigation for tabbed interfaces.
/// Includes tab groups, tab lists, individual tabs, and tab panels.
class NakedTabGroup extends StatelessWidget {
  /// Creates a naked tabs component.
  const NakedTabGroup({
    super.key,
    required this.child,
    required this.selectedTabId,
    this.onSelectedTabIdChanged,
    this.orientation = Axis.horizontal,
    this.enabled = true,
    this.semanticLabel,
    this.onEscapePressed,
  });

  final Widget child;

  /// The ID of the currently selected tab.
  final String selectedTabId;

  /// Called when the selected tab ID changes.
  final ValueChanged<String>? onSelectedTabIdChanged;

  /// Whether the tabs component is enabled.
  final bool enabled;

  /// Optional semantic label for accessibility.
  ///
  /// This is used by screen readers to describe the tabs component.
  final String? semanticLabel;

  /// The orientation of the tabs.
  ///
  /// Defaults to horizontal.
  final Axis orientation;

  /// Optional escape key handler.
  ///
  /// This is called when the escape key is pressed while the tabs component has focus.
  final VoidCallback? onEscapePressed;

  void _selectTab(String tabId) {
    if (!enabled) return;
    if (tabId == selectedTabId) return;

    onSelectedTabIdChanged?.call(tabId);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: NakedTabsScope(
        selectedTabId: selectedTabId,
        onSelectedTabIdChanged: _selectTab,
        orientation: orientation,
        enabled: enabled,
        child: child,
      ),
    );
  }
}

/// The scope that provides tabs state to its descendants.
class NakedTabsScope extends InheritedWidget {
  const NakedTabsScope({
    super.key,
    required this.selectedTabId,
    required this.onSelectedTabIdChanged,
    required this.orientation,
    required this.enabled,
    required super.child,
  });

  static NakedTabsScope of(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<NakedTabsScope>() == null) {
      throw FlutterError(
        'NakedTabsScope.of() was called with a context that does not contain a NakedTabsScope widget.\n'
        'No NakedTabsScope ancestor could be found starting from the context that was passed.\n'
        'This can happen when a NakedTab or NakedTabPanel is used outside of a NakedTabGroup.\n'
        'The context used was:\n'
        '  $context',
      );
    }

    return context.dependOnInheritedWidgetOfExactType<NakedTabsScope>()!;
  }

  /// The ID of the currently selected tab.
  final String selectedTabId;

  /// Called when a tab is selected.
  final ValueChanged<String>? onSelectedTabIdChanged;

  /// The orientation of the tabs.
  final Axis orientation;

  /// Whether the tabs component is enabled.
  final bool enabled;

  /// Whether a tab is currently selected.
  bool isTabSelected(String tabId) {
    return selectedTabId == tabId;
  }

  /// Requests that a tab be selected.
  void selectTab(String tabId) {
    if (onSelectedTabIdChanged != null) {
      onSelectedTabIdChanged!(tabId);
    }
  }

  @override
  bool updateShouldNotify(NakedTabsScope oldWidget) {
    return selectedTabId != oldWidget.selectedTabId ||
        orientation != oldWidget.orientation ||
        enabled != oldWidget.enabled;
  }
}

/// A container for tab triggers in a NakedTabs component.
class NakedTabList extends StatelessWidget {
  /// Creates a naked tab list.
  const NakedTabList({super.key, required this.child, this.semanticLabel});

  final Widget child;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel ?? 'Tab list',
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: child,
      ),
    );
  }
}

/// An individual tab trigger in a NakedTabs component.
class NakedTab extends StatefulWidget {
  /// Creates a naked tab.
  const NakedTab({
    super.key,
    required this.child,
    required this.tabId,
    this.onHoveredState,
    this.onPressedState,
    this.onFocusedState,
    this.enabled = true,
    this.semanticLabel,
    this.cursor = SystemMouseCursors.click,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.excludeSemantics = false,
  });

  final Widget child;

  /// The unique ID for this tab.
  final String tabId;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoveredState;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressedState;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusedState;

  /// Whether this tab is enabled.
  final bool enabled;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  /// The cursor to show when hovering over the tab.
  final MouseCursor cursor;

  /// Whether to provide haptic feedback on tab selection.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to exclude child semantics from the semantic tree.
  final bool excludeSemantics;

  @override
  State<NakedTab> createState() => _NakedTabState();
}

class _NakedTabState extends State<NakedTab> {
  FocusNode? _ownedFocusNode;
  
  FocusNode get _focusNode => 
    widget.focusNode ?? (_ownedFocusNode ??= FocusNode());


  void _handleTap() {
    if (!widget.enabled) return;

    final tabsScope = NakedTabsScope.of(context);
    if (!tabsScope.enabled) return;

    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }

    tabsScope.selectTab(widget.tabId);
    if (_focusNode.canRequestFocus) {
      _focusNode.requestFocus();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;

    final tabsScope = NakedTabsScope.of(context);
    if (!tabsScope.enabled) {
      return KeyEventResult.ignored;
    }

    if (event is KeyUpEvent && event.logicalKey.isConfirmationKey) {
      widget.onPressedState?.call(false);
      _handleTap();

      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent) {
      switch (tabsScope.orientation) {
        case Axis.horizontal:
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            FocusTraversalGroup.of(context).previous(_focusNode);

            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            FocusTraversalGroup.of(context).next(_focusNode);

            return KeyEventResult.handled;
          }
          break;
        case Axis.vertical:
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            FocusTraversalGroup.of(context).next(_focusNode);

            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            FocusTraversalGroup.of(context).previous(_focusNode);

            return KeyEventResult.handled;
          }
          break;
      }
      if (event.logicalKey.isConfirmationKey) {
        widget.onPressedState?.call(true);

        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }


  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabsScope = NakedTabsScope.of(context);
    final isSelected = tabsScope.isTabSelected(widget.tabId);
    final isInteractive = widget.enabled && tabsScope.enabled;

    return Semantics(
      container: true,
      excludeSemantics: widget.excludeSemantics,
      enabled: isInteractive,
      selected: isSelected,
      label: widget.semanticLabel ?? 'Tab ${widget.tabId}',
      onTap: isInteractive ? _handleTap : null,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: widget.onFocusedState,
        onKeyEvent: _handleKeyEvent,
        canRequestFocus: isInteractive,
        child: MouseRegion(
          onEnter: isInteractive
              ? (_) => widget.onHoveredState?.call(true)
              : null,
          onExit: isInteractive
              ? (_) => widget.onHoveredState?.call(false)
              : null,
          cursor: isInteractive ? widget.cursor : SystemMouseCursors.forbidden,
          child: GestureDetector(
            onTapDown: isInteractive
                ? (_) => widget.onPressedState?.call(true)
                : null,
            onTapUp: isInteractive
                ? (_) => widget.onPressedState?.call(false)
                : null,
            onTap: isInteractive ? _handleTap : null,
            onTapCancel: isInteractive
                ? () => widget.onPressedState?.call(false)
                : null,
            behavior: HitTestBehavior.opaque,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A panel that displays content for a specific tab in a NakedTabs component.
class NakedTabPanel extends StatelessWidget {
  /// Creates a naked tab panel.
  const NakedTabPanel({
    super.key,
    required this.child,
    required this.tabId,
    this.semanticLabel,
    this.maintainState = true,
  });

  /// Content displayed when this panel is active.
  final Widget child;

  /// The ID of the tab this panel is associated with.
  final String tabId;

  /// Optional semantic label for accessibility.
  ///
  /// This is used by screen readers to describe the tab panel.
  final String? semanticLabel;

  /// Whether to keep the panel in the widget tree when inactive.
  ///
  /// When true, the panel will remain in the widget tree but be invisible when inactive.
  /// When false, the panel will be removed from the widget tree when inactive.
  final bool maintainState;

  @override
  Widget build(BuildContext context) {
    final tabsScope = NakedTabsScope.of(context);
    final isSelected = tabsScope.isTabSelected(tabId);

    if (!isSelected && !maintainState) {
      return const SizedBox();
    }

    return ExcludeFocus(
      excluding: !isSelected,
      child: Visibility(
        visible: isSelected,
        maintainState: maintainState,
        child: child,
      ),
    );
  }
}

extension on LogicalKeyboardKey {
  bool get isConfirmationKey =>
      this == LogicalKeyboardKey.space || this == LogicalKeyboardKey.enter;
}
