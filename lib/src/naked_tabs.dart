import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utilities/naked_pressable.dart';
import 'utilities/utilities.dart';

/// Provides tab interaction behavior without visual styling.
///
/// Includes keyboard navigation for tabbed interfaces.
/// Components: tab groups, tab lists, individual tabs, and tab panels.
class NakedTabGroup extends StatelessWidget {
  /// Creates a naked tabs component.
  const NakedTabGroup({
    super.key,
    required this.child,
    required this.selectedTabId,
    this.onChanged,
    this.orientation = Axis.horizontal,
    this.enabled = true,
    this.semanticLabel,
    this.onEscapePressed,
  });

  final Widget child;

  /// The ID of the currently selected tab.
  final String selectedTabId;

  /// Called when the selected tab ID changes.
  final ValueChanged<String>? onChanged;

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

    onChanged?.call(tabId);
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
        onChanged: _selectTab,
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
    required this.onChanged,
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
        '  onChanged: (id) => updateSelectedTab(id),\n'
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
  final ValueChanged<String>? onChanged;

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

    onChanged?.call(tabId);
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
class NakedTabList extends StatefulWidget {
  /// Creates a naked tab list.
  const NakedTabList({super.key, required this.child, this.semanticLabel});

  final Widget child;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  @override
  State<NakedTabList> createState() => _NakedTabListState();
}

class _NakedTabListState extends State<NakedTabList> {
  final Set<_NakedTabState> _tabs = {};

  late final Map<ShortcutActivator, Intent> _tabListShortcuts =
      <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): VoidCallbackIntent(
          _selectPreviousTab,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            VoidCallbackIntent(_selectNextTab),
        const SingleActivator(LogicalKeyboardKey.arrowDown): VoidCallbackIntent(
          _selectNextTab,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowUp): VoidCallbackIntent(
          _selectPreviousTab,
        ),
      };

  void _registerTab(_NakedTabState tab) {
    _tabs.add(tab);
  }

  void _unregisterTab(_NakedTabState tab) {
    _tabs.remove(tab);
  }

  void _selectTabInDirection(bool forward) {
    final tabsScope = NakedTabsScope.of(context);
    final enabledTabs = _tabs.where((tab) => tab._isEnabled).toList();

    if (enabledTabs.length <= 1) return;

    // Find currently focused tab
    _NakedTabState? focusedTab;
    for (final tab in enabledTabs) {
      if (tab._focusNode.hasFocus) {
        focusedTab = tab;
        break;
      }
    }

    if (focusedTab == null) return;

    final currentIndex = enabledTabs.indexOf(focusedTab);
    final nextIndex =
        (currentIndex + (forward ? 1 : -1) + enabledTabs.length) %
        enabledTabs.length;
    final nextTab = enabledTabs[nextIndex];

    // Focus and select the next tab
    nextTab._focusNode.requestFocus();
    tabsScope.selectTab(nextTab.widget.tabId);
  }

  void _selectPreviousTab() {
    _selectTabInDirection(false);
  }

  void _selectNextTab() {
    _selectTabInDirection(true);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel ?? 'Tab list',
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Shortcuts(
          shortcuts: _tabListShortcuts,
          child: _NakedTabListScope(state: this, child: widget.child),
        ),
      ),
    );
  }
}

/// Internal InheritedWidget that provides tab list state to child tabs.
class _NakedTabListScope extends InheritedWidget {
  const _NakedTabListScope({required this.state, required super.child});

  static _NakedTabListScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  final _NakedTabListState state;

  @override
  bool updateShouldNotify(_NakedTabListScope oldWidget) {
    return state != oldWidget.state;
  }
}

/// An individual tab trigger in a NakedTabs component.
class NakedTab extends StatefulWidget {
  /// Creates a naked tab.
  const NakedTab({
    super.key,
    this.child,
    required this.tabId,
    this.enabled = true,
    this.semanticLabel,
    this.semanticHint,
    this.mouseCursor = SystemMouseCursors.click,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.excludeSemantics = false,
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

  final Widget? child;

  /// The unique ID for this tab.
  final String tabId;

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

  /// Whether this tab is enabled.
  final bool enabled;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  /// Semantic hint for accessibility.
  final String? semanticHint;

  /// The cursor to show when hovering over the tab.
  final MouseCursor mouseCursor;

  /// Whether to provide haptic feedback on tab selection.
  ///
  /// Note: Tabs use selectionClick haptic feedback for tab changes,
  /// which is consistent across platforms for selection controls.
  final bool enableFeedback;

  /// Optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether to automatically focus when created.
  final bool autofocus;

  /// Whether to exclude child semantics from the semantic tree.
  final bool excludeSemantics;

  @override
  State<NakedTab> createState() => _NakedTabState();
}

class _NakedTabState extends State<NakedTab> {
  late final FocusNode _focusNode;
  late bool _isEnabled;
  late NakedTabsScope _tabsScope;
  _NakedTabListState? _tabListState;

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
      if (widget.enableFeedback) {
        HapticFeedback.selectionClick();
      }

      _tabsScope.selectTab(widget.tabId);
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabsScope = NakedTabsScope.of(context);
    _isEnabled = widget.enabled && _tabsScope.enabled;

    // Register with tab list
    final tabListScope = _NakedTabListScope.maybeOf(context);
    if (tabListScope != null && !identical(_tabListState, tabListScope.state)) {
      _tabListState?._unregisterTab(this);
      _tabListState = tabListScope.state;
      _tabListState!._registerTab(this);
    }
  }

  @override
  void dispose() {
    _tabListState?._unregisterTab(this);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _tabsScope.isTabSelected(widget.tabId);

    assert(widget.tabId.isNotEmpty, 'tabId cannot be empty');

    // Use NakedPressable for consistent gesture and cursor behavior
    return Semantics(
      excludeSemantics: widget.excludeSemantics,
      enabled: _isEnabled,
      selected: isSelected,
      focusable: _isEnabled,
      label: widget.semanticLabel ?? 'Tab ${widget.tabId}',
      hint: widget.semanticHint,
      onTap: _isEnabled ? _handleTap : null,
      // Expose focus action when enabled
      onFocus: _isEnabled ? semanticsFocusNoop : null,
      child: NakedPressable(
        onPressed: _isEnabled ? _handleTap : null,
        enabled: widget.enabled,
        selected: isSelected,
        mouseCursor: widget.mouseCursor,
        disabledMouseCursor: SystemMouseCursors.forbidden,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onStatesChange: widget.onStatesChange,
        onFocusChange: widget.onFocusChange,
        onHoverChange: widget.onHoverChange,
        onPressChange: widget.onPressChange,
        statesController: widget.statesController,
        // We handle our own selectionClick haptic feedback
        enableFeedback: false,
        child: widget.child,
        builder: (context, states, child) {
          if (widget.builder != null) {
            return widget.builder!(context, states, child);
          }

          return widget.child!;
        },
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
