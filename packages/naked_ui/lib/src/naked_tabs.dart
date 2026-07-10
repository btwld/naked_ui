import 'dart:ui' show SemanticsRole;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/state.dart';

/// A controller for managing tab selection state.
///
/// Extends [ChangeNotifier] to notify listeners when the selected tab changes.
class NakedTabController extends ChangeNotifier {
  String _selectedTabId;
  String? _previousTabId;

  /// Creates a [NakedTabController] with the given initial tab.
  NakedTabController({required String selectedTabId})
    : _selectedTabId = _validateTabId(selectedTabId);

  static String _validateTabId(String tabId) {
    if (tabId.isEmpty) {
      throw ArgumentError.value(tabId, 'tabId', 'must not be empty');
    }
    return tabId;
  }

  /// The currently selected tab identifier.
  String get selectedTabId => _selectedTabId;

  /// The previously selected tab identifier, if any.
  String? get previousTabId => _previousTabId;

  /// Selects the tab with the given [tabId].
  void selectTab(String tabId) {
    _validateTabId(tabId);
    if (tabId == _selectedTabId) return;
    _previousTabId = _selectedTabId;
    _selectedTabId = tabId;
    notifyListeners();
  }

  /// Selects the previous tab, if available.
  void selectPrevious() {
    if (_previousTabId != null) {
      selectTab(_previousTabId!);
    }
  }
}

/// Immutable view passed to [NakedTab.builder].
class NakedTabState extends NakedState {
  /// The unique identifier for this tab.
  final String tabId;

  /// Creates a tab state snapshot for [tabId].
  NakedTabState({required super.states, required this.tabId});

  /// Returns the nearest [NakedTabState] from context.
  static NakedTabState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedTabState] if available.
  static NakedTabState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOfType<NakedTabState>(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOfType<NakedTabState>(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedTabState && statesEqual(other) && other.tabId == tabId;
  }

  @override
  int get hashCode => Object.hash(statesHashCode, tabId);
}

/// A headless tab group without visuals.
///
/// Selection follows focus. Use [NakedTabBar], [NakedTab], and
/// [NakedTabView] for custom visuals.
///
/// ```dart
/// NakedTabs(
///   selectedTabId: 'tab1',
///   onChanged: (id) => setState(() => selectedTabId = id),
///   child: Column(children: [
///     NakedTabBar(child: Row(children: [
///       NakedTab(tabId: 'tab1', child: Text('Tab 1')),
///       NakedTab(tabId: 'tab2', child: Text('Tab 2')),
///     ])),
///     NakedTabView(tabId: 'tab1', child: Text('View 1')),
///     NakedTabView(tabId: 'tab2', child: Text('View 2')),
///   ]),
/// )
/// ```
///
/// See also:
/// - `TabBar`, the Material-styled tabs widget for typical apps.
/// - [FocusTraversalGroup], for customizing keyboard focus traversal.
class NakedTabs extends StatelessWidget {
  /// Creates a controlled tab group.
  ///
  /// Provide either [controller] or [selectedTabId]. When using
  /// [selectedTabId], [onChanged] must be non-null for interaction.
  const NakedTabs({
    super.key,
    required this.child,
    this.controller,
    this.selectedTabId,
    this.onChanged,
    this.orientation = Axis.horizontal,
    this.enabled = true,
    this.onEscapePressed,
  }) : assert(
         controller != null || selectedTabId != null,
         'Either controller or selectedTabId must be provided',
       );

  /// The tabs content.
  final Widget child;

  /// Optional controller for managing tab state.
  ///
  /// If not provided, the widget will use [selectedTabId] and [onChanged] for state management.
  final NakedTabController? controller;

  /// The identifier of the currently selected tab.
  ///
  /// Ignored if [controller] is provided.
  final String? selectedTabId;

  /// Called when the selected tab changes.
  ///
  /// Ignored if [controller] is provided.
  final ValueChanged<String>? onChanged;

  /// Whether the tabs are enabled.
  final bool enabled;

  /// The tab list orientation.
  final Axis orientation;

  /// Called when Escape is pressed while a tab has focus.
  final VoidCallback? onEscapePressed;

  String get _effectiveSelectedTabId {
    final id = controller?.selectedTabId ?? selectedTabId;
    if (id == null || id.isEmpty) {
      throw FlutterError(
        'NakedTabs requires a non-empty selectedTabId or a controller.',
      );
    }
    return id;
  }

  bool get _effectiveEnabled =>
      enabled && (controller != null || onChanged != null);

  void _selectTab(String tabId) {
    if (!_effectiveEnabled || tabId == _effectiveSelectedTabId) return;
    if (tabId.isEmpty) {
      throw ArgumentError.value(tabId, 'tabId', 'must not be empty');
    }

    if (controller != null) {
      controller!.selectTab(tabId);
    } else {
      onChanged?.call(tabId);
    }
  }

  Widget _buildTabs() {
    final scope = NakedTabsScope(
      selectedTabId: _effectiveSelectedTabId,
      onChanged: _selectTab,
      orientation: orientation,
      enabled: _effectiveEnabled,
      onEscapePressed: onEscapePressed,
      child: child,
    );

    final escapeHandler = onEscapePressed;
    return escapeHandler == null
        ? scope
        : Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => escapeHandler(),
              ),
            },
            child: scope,
          );
  }

  @override
  Widget build(BuildContext context) {
    final tabController = controller;
    return tabController == null
        ? _buildTabs()
        : ListenableBuilder(
            listenable: tabController,
            builder: (context, child) => _buildTabs(),
          );
  }
}

/// Provides tab state to descendant widgets.
class NakedTabsScope extends InheritedWidget {
  /// Creates tab state inherited by [child].
  const NakedTabsScope({
    super.key,
    required this.selectedTabId,
    required this.onChanged,
    required this.orientation,
    required this.enabled,
    this.onEscapePressed,
    required super.child,
  });

  /// Returns the nearest tab scope.
  ///
  /// Throws a [FlutterError] when called outside [NakedTabs].
  static NakedTabsScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NakedTabsScope>();
    if (scope == null) {
      throw FlutterError(
        'NakedTabsScope.of() called outside of NakedTabs.\n'
        'Wrap NakedTab and NakedTabView widgets in a NakedTabs.',
      );
    }

    return scope;
  }

  /// The currently selected tab identifier.
  final String selectedTabId;

  /// Called to request a selection change.
  final ValueChanged<String>? onChanged;

  /// The direction in which tabs are arranged.
  final Axis orientation;

  /// Whether descendants can change selection.
  final bool enabled;

  /// Called when Escape is pressed within the tab group.
  final VoidCallback? onEscapePressed;

  /// Whether [tabId] identifies the selected tab.
  bool isTabSelected(String tabId) => selectedTabId == tabId;

  /// Requests selection of [tabId] when the scope is enabled.
  void selectTab(String tabId) {
    if (!enabled || tabId == selectedTabId) return;
    if (tabId.isEmpty) {
      throw ArgumentError.value(tabId, 'tabId', 'must not be empty');
    }
    onChanged?.call(tabId);
  }

  @override
  bool updateShouldNotify(NakedTabsScope old) {
    return selectedTabId != old.selectedTabId ||
        orientation != old.orientation ||
        enabled != old.enabled ||
        onChanged != old.onChanged ||
        onEscapePressed != old.onEscapePressed;
  }
}

/// A container for tab triggers without visuals.
///
/// Provides focus traversal for tab navigation.
///
/// See also:
/// - [NakedTab], the individual tab trigger components.
class NakedTabBar extends StatefulWidget {
  /// Creates a semantic tab bar around [child].
  const NakedTabBar({super.key, required this.child});

  /// The tab triggers arranged by the caller.
  final Widget child;

  @override
  State<NakedTabBar> createState() => _NakedTabBarState();
}

class _NakedTabBarState extends State<NakedTabBar> {
  late final FocusScopeNode _focusScopeNode = FocusScopeNode(
    debugLabel: 'NakedTabBar',
    traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
  );

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      role: SemanticsRole.tabBar,
      explicitChildNodes: true,
      child: FocusTraversalGroup(
        policy: _TabTraversalPolicy(),
        child: FocusScope.withExternalFocusNode(
          focusScopeNode: _focusScopeNode,
          includeSemantics: false,
          child: widget.child,
        ),
      ),
    );
  }
}

class _TabTraversalPolicy extends WidgetOrderTraversalPolicy {
  List<FocusNode> orderedNodes(
    Iterable<FocusNode> nodes,
    FocusNode currentNode,
  ) => sortDescendants(nodes, currentNode).toList();
}

/// A headless tab trigger without visuals.
///
/// Selection follows focus for keyboard navigation.
/// The builder receives a [NakedTabState] with the tab ID and interaction
/// states, including [WidgetState.selected], for custom styling.
///
/// See also:
/// - [NakedTabs], the container that manages tab state.
class NakedTab extends StatefulWidget {
  /// Creates a tab trigger identified by [tabId].
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
    this.excludeSemantics = false,
  });

  /// The tab trigger content when not using [builder].
  final Widget? child;

  /// The unique identifier for this tab.
  final String tabId;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when the pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Builds the tab using the current [NakedTabState].
  final ValueWidgetBuilder<NakedTabState>? builder;

  /// Semantic label for the trigger.
  ///
  /// When provided, it replaces the semantics of the tab's content, so a tab
  /// whose content already renders the same text is announced once. When
  /// null, the content's own semantics are used.
  final String? semanticLabel;

  /// Whether the tab is enabled.
  final bool enabled;

  /// The mouse cursor when enabled.
  final MouseCursor mouseCursor;

  /// Whether to provide haptic feedback on interactions.
  final bool enableFeedback;

  /// The focus node for the tab.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  /// Whether to omit the tab semantics contributed by [NakedTab].
  ///
  /// Semantics supplied by [child] or [builder] remain available.
  final bool excludeSemantics;

  @override
  State<NakedTab> createState() => _NakedTabState();
}

class _NakedTabState extends State<NakedTab>
    with WidgetStatesMixin<NakedTab>, FocusNodeMixin<NakedTab> {
  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;

  bool _isEnabled = false;
  late NakedTabsScope _scope;

  void _syncScopeState() {
    final wasEnabled = _isEnabled;
    _isEnabled = widget.enabled && _scope.enabled;
    updateDisabledState(!_isEnabled);
    updateSelectedState(_scope.isTabSelected(widget.tabId), null);

    if (wasEnabled && !_isEnabled) {
      clearInteractionStates(
        onHoverChange: widget.onHoverChange,
        onFocusChange: widget.onFocusChange,
        onPressChange: widget.onPressChange,
      );
      if (effectiveFocusNode.hasFocus) effectiveFocusNode.unfocus();
    }
  }

  /// Whether a focus-gain event caused by this tab's own tap or keyboard
  /// activation is in flight.
  ///
  /// A press would otherwise dispatch selection twice: [_handleTap] selects
  /// directly, and the focus it requests selects again (selection follows
  /// focus). The direct call must stay — a press selects synchronously, even
  /// when focus cannot move — so the focus-driven follow-up is the one
  /// suppressed; the next focus event on this tab consumes the flag either
  /// way. Deliberately not frame- or timer-scoped: a controlled host that
  /// rejects a change schedules no frame, and a frame-scoped guard would
  /// swallow keyboard retries. At worst (requested focus preempted before
  /// landing here) a stale flag suppresses one focus-follow selection and
  /// self-heals; a press's own selection is never lost.
  bool _selectionRequestedByTap = false;

  void _handleTap() {
    if (!_isEnabled) return;
    if (widget.enableFeedback) HapticFeedback.selectionClick();
    if (effectiveFocusNode.canRequestFocus) {
      // requestFocus on an already-focused node emits no focus event and
      // would leave the flag stale; only arm it when an event will consume it.
      _selectionRequestedByTap = !effectiveFocusNode.hasPrimaryFocus;
      effectiveFocusNode.requestFocus();
    }
    _scope.selectTab(widget.tabId);
  }

  void _handleDirectionalFocus(TraversalDirection direction) {
    if (!_isEnabled) return;

    final isHorizontal = _scope.orientation == Axis.horizontal;

    switch (direction) {
      case TraversalDirection.left:
        if (isHorizontal) _focusRelative(-1);
        break;
      case TraversalDirection.right:
        if (isHorizontal) _focusRelative(1);
        break;
      case TraversalDirection.up:
        if (!isHorizontal) _focusRelative(-1);
        break;
      case TraversalDirection.down:
        if (!isHorizontal) _focusRelative(1);
        break;
    }
  }

  List<FocusNode> _orderedTabNodes() {
    final focusScope = FocusScope.of(context, createDependency: false);
    final nodes = focusScope.descendants.where(
      (node) => node is! FocusScopeNode && node.canRequestFocus,
    );
    return _TabTraversalPolicy().orderedNodes(nodes, effectiveFocusNode);
  }

  void _focusRelative(int offset) {
    final nodes = _orderedTabNodes();
    if (nodes.isEmpty) return;

    final currentIndex = nodes.indexOf(effectiveFocusNode);
    if (currentIndex < 0) return;

    final nextIndex = (currentIndex + offset) % nodes.length;
    nodes[nextIndex].requestFocus();
  }

  void _focusFirstTab() {
    final nodes = _orderedTabNodes();
    if (nodes.isNotEmpty) nodes.first.requestFocus();
  }

  void _focusLastTab() {
    final nodes = _orderedTabNodes();
    if (nodes.isNotEmpty) nodes.last.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = NakedTabsScope.of(context);
    _syncScopeState();
  }

  @override
  void didUpdateWidget(covariant NakedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncScopeState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabId.isEmpty) {
      throw ArgumentError.value(widget.tabId, 'tabId', 'must not be empty');
    }

    final isSelected = _scope.isTabSelected(widget.tabId);

    final tabState = NakedTabState(states: widgetStates, tabId: widget.tabId);

    final wrappedContent = NakedStateScopeBuilder(
      value: tabState,
      builder: widget.builder,
      child: widget.child,
    );

    Widget gestureDetector = GestureDetector(
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
      child: wrappedContent,
    );

    final focusContent = widget.semanticLabel == null
        ? gestureDetector
        : ExcludeSemantics(child: gestureDetector);

    final focusable = NakedFocusableDetector(
      enabled: _isEnabled,
      autofocus: widget.autofocus,
      onFocusChange: (f) {
        final selectedByTap = _selectionRequestedByTap;
        _selectionRequestedByTap = false;
        // No setState here: updateFocusState already rebuilds on every real
        // focus transition, and transitions are the only way
        // Focus.onFocusChange fires.
        updateFocusState(f, widget.onFocusChange);
        if (f && _isEnabled && !selectedByTap) {
          _scope.selectTab(widget.tabId);
        }
      },
      onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
      focusNode: effectiveFocusNode,
      skipTraversal: !_isEnabled || !isSelected,
      descendantsAreFocusable: false,
      descendantsAreTraversable: false,
      mouseCursor: _isEnabled ? widget.mouseCursor : SystemMouseCursors.basic,
      shortcuts: NakedIntentActions.tabShortcuts,
      actions: NakedIntentActions.tabActions(
        onActivate: () => _handleTap(),
        onDirectionalFocus: _handleDirectionalFocus,
        onFirstFocus: () => _focusFirstTab(),
        onLastFocus: () => _focusLastTab(),
      ),
      child: focusContent,
    );

    return widget.excludeSemantics
        ? focusable
        : Semantics(
            container: true,
            role: SemanticsRole.tab,
            enabled: _isEnabled,
            selected: isSelected,
            button: true,
            label: widget.semanticLabel,
            onTap: _isEnabled ? _handleTap : null,
            child: focusable,
          );
  }
}

/// A headless tab view without visuals.
///
/// Displays content for a specific tab when selected.
/// Supports state maintenance when hidden.
///
/// See also:
/// - [NakedTabs], the container that manages tab selection.
class NakedTabView extends StatelessWidget {
  /// Creates a panel associated with [tabId].
  const NakedTabView({
    super.key,
    required this.child,
    required this.tabId,
    this.maintainState = true,
  });

  /// The view content for the associated [tabId].
  final Widget child;

  /// The identifier of the tab this view corresponds to.
  final String tabId;

  /// Whether to maintain state when hidden.
  final bool maintainState;

  @override
  Widget build(BuildContext context) {
    if (tabId.isEmpty) {
      throw ArgumentError.value(tabId, 'tabId', 'must not be empty');
    }
    final scope = NakedTabsScope.of(context);
    final isSelected = scope.isTabSelected(tabId);

    if (!isSelected && !maintainState) {
      return const SizedBox.shrink();
    }

    return ExcludeFocus(
      excluding: !isSelected,
      child: Visibility(
        visible: isSelected,
        maintainState: maintainState,
        child: Semantics(role: SemanticsRole.tabPanel, child: child),
      ),
    );
  }
}
