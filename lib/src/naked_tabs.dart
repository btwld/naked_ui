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

    assert(tabId.isNotEmpty, 'Tab ID cannot be empty');

    onSelectedTabIdChanged?.call(tabId);
  }

  @override
  Widget build(BuildContext context) {
    assert(selectedTabId.isNotEmpty, 'selectedTabId cannot be empty');

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: NakedTabsScope(
        selectedTabId: selectedTabId,
        onSelectedTabIdChanged: _selectTab,
        orientation: orientation,
        enabled: enabled,
        onEscapePressed: onEscapePressed,
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
    this.onEscapePressed,
    required super.child,
  });

  static NakedTabsScope of(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<NakedTabsScope>() == null) {
      throw FlutterError(
        'NakedTabsScope.of() called outside of NakedTabGroup.\n'
        'Wrap NakedTab and NakedTabPanel widgets in a NakedTabGroup:\n\n'
        'NakedTabGroup(\n'
        '  selectedTabId: "tab1",\n'
        '  onSelectedTabIdChanged: (id) => updateSelectedTab(id),\n'
        '  child: Column(children: [\n'
        '    NakedTabList(child: Row(children: [\n'
        '      NakedTab(tabId: "tab1", child: Text("Tab 1")),\n'
        '      NakedTab(tabId: "tab2", child: Text("Tab 2")),\n'
        '    ])),\n'
        '    NakedTabPanel(tabId: "tab1", child: YourContent()),\n'
        '    NakedTabPanel(tabId: "tab2", child: YourContent()),\n'
        '  ]),\n'
        ')',
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

  /// Optional escape key handler.
  final VoidCallback? onEscapePressed;

  /// Whether a tab is currently selected.
  bool isTabSelected(String tabId) {
    return selectedTabId == tabId;
  }

  /// Requests that a tab be selected.
  void selectTab(String tabId) {
    if (!enabled) return;
    if (tabId == selectedTabId) return;

    assert(tabId.isNotEmpty, 'Tab ID cannot be empty');

    onSelectedTabIdChanged?.call(tabId);
  }

  @override
  bool updateShouldNotify(NakedTabsScope oldWidget) {
    return selectedTabId != oldWidget.selectedTabId ||
        orientation != oldWidget.orientation ||
        enabled != oldWidget.enabled ||
        onEscapePressed != oldWidget.onEscapePressed;
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
    this.onHoverChange,
    this.onPressChange,
    this.onFocusChange,
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
  final ValueChanged<bool>? onHoverChange;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

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
  late final FocusNode _focusNode;
  late bool _isEnabled;
  late NakedTabsScope _tabsScope;

  @override
  void initState() {
    super.initState();
    _focusNode =
        widget.focusNode ?? FocusNode(debugLabel: 'NakedTab-${widget.tabId}');
  }

  /// Helper method to guard event handlers with enabled check
  void _ifEnabled(VoidCallback callback) {
    if (_isEnabled) {
      callback();
    }
  }

  void _handleTap() {
    _ifEnabled(() {
      if (widget.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }

      _tabsScope.selectTab(widget.tabId);
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _handlePressDown(TapDownDetails details) {
    _ifEnabled(() => widget.onPressChange?.call(true));
  }

  void _handlePressUp(TapUpDetails details) {
    _ifEnabled(() => widget.onPressChange?.call(false));
  }

  void _handlePressCancel() {
    _ifEnabled(() => widget.onPressChange?.call(false));
  }

  void _handleHoverEnter(PointerEnterEvent event) {
    _ifEnabled(() => widget.onHoverChange?.call(true));
  }

  void _handleHoverExit(PointerExitEvent event) {
    _ifEnabled(() => widget.onHoverChange?.call(false));
  }

  void _handleFocusChange(bool focused) {
    widget.onFocusChange?.call(focused);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_isEnabled) return KeyEventResult.ignored;

    if (event is KeyUpEvent && event.logicalKey.isConfirmationKey) {
      widget.onPressChange?.call(false);
      _handleTap();

      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent) {
      switch (_tabsScope.orientation) {
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
        widget.onPressChange?.call(true);

        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _tabsScope.onEscapePressed?.call();

        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabsScope = NakedTabsScope.of(context);
    _isEnabled = widget.enabled && _tabsScope.enabled;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  MouseCursor get _cursor =>
      _isEnabled ? widget.cursor : SystemMouseCursors.forbidden;

  @override
  Widget build(BuildContext context) {
    final isSelected = _tabsScope.isTabSelected(widget.tabId);

    assert(widget.tabId.isNotEmpty, 'tabId cannot be empty');

    return Semantics(
      container: true,
      excludeSemantics: widget.excludeSemantics,
      enabled: _isEnabled,
      selected: isSelected,
      label: widget.semanticLabel ?? 'Tab ${widget.tabId}',
      onTap: _handleTap,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: _handleFocusChange,
        onKeyEvent: _handleKeyEvent,
        canRequestFocus: _isEnabled,
        child: MouseRegion(
          onEnter: _handleHoverEnter,
          onExit: _handleHoverExit,
          cursor: _cursor,
          child: GestureDetector(
            onTapDown: _handlePressDown,
            onTapUp: _handlePressUp,
            onTap: _handleTap,
            onTapCancel: _handlePressCancel,
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

    assert(tabId.isNotEmpty, 'tabId cannot be empty');

    if (!isSelected && !maintainState) {
      return const SizedBox.shrink();
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
