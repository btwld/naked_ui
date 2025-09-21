// ignore_for_file: no-empty-block

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/widget_state_snapshot.dart';

/// Immutable view passed to [NakedTab.builder].
class NakedTabState extends NakedWidgetState {
  /// The unique identifier for this tab.
  final String tabId;

  /// The currently selected tab identifier.
  final String selectedTabId;

  NakedTabState({
    required super.states,
    required this.tabId,
    required this.selectedTabId,
  });

  /// Whether this tab is currently active/selected.
  bool get isSelected => tabId == selectedTabId;
}

/// A headless tab group without visuals.
///
/// Selection follows focus. Use [NakedTabList], [NakedTab], and
/// [NakedTabPanel] for custom visuals.
///
/// ```dart
/// NakedTabGroup(
///   selectedTabId: 'tab1',
///   onChanged: (id) => setState(() => selectedTabId = id),
///   child: Column(children: [
///     NakedTabList(child: Row(children: [
///       NakedTab(tabId: 'tab1', child: Text('Tab 1')),
///       NakedTab(tabId: 'tab2', child: Text('Tab 2')),
///     ])),
///     NakedTabPanel(tabId: 'tab1', child: Text('Panel 1')),
///     NakedTabPanel(tabId: 'tab2', child: Text('Panel 2')),
///   ]),
/// )
/// ```
///
/// See also:
/// - [TabBar], the Material-styled tabs widget for typical apps.
/// - [FocusTraversalGroup], for customizing keyboard focus traversal.

class NakedTabGroup extends StatelessWidget {
  const NakedTabGroup({
    super.key,
    required this.child,
    required this.selectedTabId,
    this.onChanged,
    this.orientation = Axis.horizontal,
    this.enabled = true,
    this.onEscapePressed,
  });

  /// The tabs content.
  final Widget child;

  /// The ID of the currently selected tab.
  final String selectedTabId;

  /// Called when the selected tab changes.
  final ValueChanged<String>? onChanged;

  /// The enabled state of the tabs.
  final bool enabled;

  /// The tab list orientation.
  final Axis orientation;

  /// Called when Escape is pressed while a tab has focus.
  final VoidCallback? onEscapePressed;

  bool get _effectiveEnabled => enabled && onChanged != null;

  void _selectTab(String tabId) {
    if (!_effectiveEnabled || tabId == selectedTabId) return;
    assert(tabId.isNotEmpty, 'Tab ID cannot be empty');
    onChanged?.call(tabId);
  }

  @override
  Widget build(BuildContext context) {
    assert(selectedTabId.isNotEmpty, 'selectedTabId cannot be empty');

    // Headless group-level ESC handling using default ESC -> DismissIntent mapping.
    return Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) => onEscapePressed?.call(),
        ),
      },
      child: NakedTabsScope(
        selectedTabId: selectedTabId,
        onChanged: _selectTab,
        orientation: orientation,
        enabled: _effectiveEnabled,
        onEscapePressed: onEscapePressed,
        child: child,
      ),
    );
  }
}

/// Provides tab state to descendant widgets.
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
    final scope = context.dependOnInheritedWidgetOfExactType<NakedTabsScope>();
    if (scope == null) {
      throw FlutterError(
        'NakedTabsScope.of() called outside of NakedTabGroup.\n'
        'Wrap NakedTab and NakedTabPanel widgets in a NakedTabGroup.',
      );
    }

    return scope;
  }

  final String selectedTabId;
  final ValueChanged<String>? onChanged;
  final Axis orientation;
  final bool enabled;
  final VoidCallback? onEscapePressed;

  bool isTabSelected(String tabId) => selectedTabId == tabId;

  void selectTab(String tabId) {
    if (!enabled || tabId == selectedTabId) return;
    assert(tabId.isNotEmpty, 'Tab ID cannot be empty');
    onChanged?.call(tabId);
  }

  @override
  bool updateShouldNotify(NakedTabsScope old) {
    return selectedTabId != old.selectedTabId ||
        orientation != old.orientation ||
        enabled != old.enabled ||
        onEscapePressed != old.onEscapePressed;
  }
}

/// A container for tab triggers without visuals.
///
/// Provides focus traversal for tab navigation.
///
/// See also:
/// - [NakedTab], the individual tab trigger components.
class NakedTabList extends StatelessWidget {
  const NakedTabList({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Default focus traversal will move among focusable children in widget order.
    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: child,
    );
  }
}

/// A headless tab trigger without visuals.
///
/// Selection follows focus for keyboard navigation.
/// Builder receives [NakedTabState] with tab ID, selected tab ID,
/// and interaction states for custom styling.
///
/// See also:
/// - [NakedTabGroup], the container that manages tab state.
class NakedTab extends StatefulWidget {
  const NakedTab({
    super.key,
    this.child,
    required this.tabId,
    this.enabled = true,
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

  /// The tab trigger content when not using [builder].
  final Widget? child;

  /// The unique identifier for this tab.
  final String tabId;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when press state changes.
  final ValueChanged<bool>? onPressChange;

  /// The builder that receives current tab state.
  final NakedStateBuilder<NakedTabState>? builder;

  /// The semantic label for the trigger.
  final String? semanticLabel;

  /// The enabled state of the tab.
  final bool enabled;

  /// The mouse cursor when enabled.
  final MouseCursor mouseCursor;

  /// The haptic feedback enablement flag.
  final bool enableFeedback;

  /// The focus node for the tab.
  final FocusNode? focusNode;

  /// The autofocus flag.
  final bool autofocus;

  @override
  State<NakedTab> createState() => _NakedTabState();
}

class _NakedTabState extends State<NakedTab>
    with WidgetStatesMixin<NakedTab>, FocusNodeMixin<NakedTab> {
  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;

  late bool _isEnabled;
  late NakedTabsScope _scope;

  void _applyFocusability() {
    final node = effectiveFocusNode;
    if (node != null) {
      node
        ..canRequestFocus = _isEnabled
        ..skipTraversal = !_isEnabled;
    }
  }

  void _handleTap() {
    if (!_isEnabled) return;
    if (widget.enableFeedback) HapticFeedback.selectionClick();
    // Selection follows focus anyway; tap still ensures we’re focused.
    if (effectiveFocusNode?.canRequestFocus ?? false) {
      effectiveFocusNode!.requestFocus();
    }
    _scope.selectTab(widget.tabId);
  }

  void _handleDirectionalFocus(TraversalDirection direction) {
    if (!_isEnabled) return;

    final focusScope = FocusScope.of(context);
    final isHorizontal = _scope.orientation == Axis.horizontal;

    switch (direction) {
      case TraversalDirection.left:
        if (isHorizontal) focusScope.previousFocus();
        break;
      case TraversalDirection.right:
        if (isHorizontal) focusScope.nextFocus();
        break;
      case TraversalDirection.up:
        if (!isHorizontal) focusScope.previousFocus();
        break;
      case TraversalDirection.down:
        if (!isHorizontal) focusScope.nextFocus();
        break;
    }
  }

  void _focusFirstTab() {
    // Find the first tab in the current tab group
    final scope = FocusScope.of(context);
    scope.focusInDirection(TraversalDirection.left);
    // Keep moving left until we can't go further (reaching the first tab)
    while (scope.focusInDirection(TraversalDirection.left)) {
      // Keep going until we reach the first tab
    }
  }

  void _focusLastTab() {
    // Find the last tab in the current tab group
    final scope = FocusScope.of(context);
    scope.focusInDirection(TraversalDirection.right);
    // Keep moving right until we can't go further (reaching the last tab)
    while (scope.focusInDirection(TraversalDirection.right)) {
      // Keep going until we reach the last tab
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = NakedTabsScope.of(context);
    _isEnabled = widget.enabled && _scope.enabled;

    // Disabled tabs shouldn’t be focusable or in traversal.
    _applyFocusability();
  }

  @override
  void didUpdateWidget(covariant NakedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newEnabled = widget.enabled && _scope.enabled;
    if (newEnabled != _isEnabled) {
      _isEnabled = newEnabled;
      _applyFocusability();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.tabId.isNotEmpty, 'tabId cannot be empty');

    final isSelected = _scope.isTabSelected(widget.tabId);
    // Keep states synced for builder consumers.
    updateDisabledState(!_isEnabled);
    updateSelectedState(isSelected, null);

    final tabState = NakedTabState(
      states: widgetStates,
      tabId: widget.tabId,
      selectedTabId: _scope.selectedTabId,
    );

    final content = widget.builder != null
        ? widget.builder!(context, tabState, widget.child)
        : widget.child!;

    return NakedFocusableDetector(
      enabled: _isEnabled,
      autofocus: widget.autofocus,
      onFocusChange: (f) {
        updateFocusState(f, widget.onFocusChange);
        if (f && _isEnabled) {
          _scope.selectTab(widget.tabId); // selection follows focus
        }
        setState(() {}); // update focused state for builder
      },
      onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
      focusNode: effectiveFocusNode,
      mouseCursor: _isEnabled ? widget.mouseCursor : SystemMouseCursors.basic,
      // Enter/Space still activate; focus change selects too (below).
      shortcuts: NakedIntentActions.tab.shortcuts,
      actions: NakedIntentActions.tab.actions(
        onActivate: () => _handleTap(),
        onDirectionalFocus: _handleDirectionalFocus,
        onFirstFocus: () => _focusFirstTab(),
        onLastFocus: () => _focusLastTab(),
      ),
      child: Semantics(
        container: true,
        enabled: _isEnabled,
        selected: isSelected,
        button: true,
        label: widget.semanticLabel,
        onTap: _isEnabled ? _handleTap : null,
        child: GestureDetector(
          // semantics provided above
          onTapDown: _isEnabled
              ? (_) => updatePressState(true, widget.onPressChange)
              : null,
          onTapUp: _isEnabled
              ? (_) => updatePressState(false, widget.onPressChange)
              : null,
          onTap: _isEnabled ? _handleTap : null,
          onTapCancel: _isEnabled
              ? () => updatePressState(false, widget.onPressChange)
              : null,
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          child: content,
        ),
      ),
    );
  }
}

/// A headless tab panel without visuals.
///
/// Displays content for a specific tab when selected.
/// Supports state maintenance when hidden.
///
/// See also:
/// - [NakedTabGroup], the container that manages tab selection.
class NakedTabPanel extends StatelessWidget {
  const NakedTabPanel({
    super.key,
    required this.child,
    required this.tabId,
    this.maintainState = true,
  });

  /// The panel content for the associated [tabId].
  final Widget child;

  /// The identifier of the tab this panel corresponds to.
  final String tabId;

  /// The state maintenance flag when hidden.
  final bool maintainState;

  @override
  Widget build(BuildContext context) {
    assert(tabId.isNotEmpty, 'tabId cannot be empty');
    final scope = NakedTabsScope.of(context);
    final isSelected = scope.isTabSelected(tabId);

    if (!isSelected && !maintainState) {
      return const SizedBox.shrink();
    }

    // When hidden: remove from traversal; keep subtree alive if maintainState=true.
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
