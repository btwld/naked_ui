// ignore_for_file: no-empty-block

import 'package:flutter/foundation.dart';
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
    : _selectedTabId = selectedTabId;

  /// The currently selected tab identifier.
  String get selectedTabId => _selectedTabId;

  /// The previously selected tab identifier, if any.
  String? get previousTabId => _previousTabId;

  /// Selects the tab with the given [tabId].
  void selectTab(String tabId) {
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

  @override
  void dispose() {
    super.dispose();
  }
}

/// Immutable view passed to [NakedTab.builder].
class NakedTabState extends NakedState {
  /// The unique identifier for this tab.
  final String tabId;

  NakedTabState({required super.states, required this.tabId});

  /// Returns the nearest [NakedTabState] from context.
  static NakedTabState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedTabState] if available.
  static NakedTabState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedTabState &&
        setEquals(other.states, states) &&
        other.tabId == tabId;
  }

  @override
  int get hashCode => Object.hash(states, tabId);
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
/// - [TabBar], the Material-styled tabs widget for typical apps.
/// - [FocusTraversalGroup], for customizing keyboard focus traversal.

class NakedTabs extends StatelessWidget {
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

  String get _effectiveSelectedTabId =>
      controller?.selectedTabId ?? selectedTabId!;

  bool get _effectiveEnabled =>
      enabled && (controller != null || onChanged != null);

  void _selectTab(String tabId) {
    if (!_effectiveEnabled || tabId == _effectiveSelectedTabId) return;
    assert(tabId.isNotEmpty, 'Tab ID cannot be empty');

    if (controller != null) {
      controller!.selectTab(tabId);
    } else {
      onChanged?.call(tabId);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_effectiveSelectedTabId.isNotEmpty, 'selectedTabId cannot be empty');

    return Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) => onEscapePressed?.call(),
        ),
      },
      child: NakedTabsScope(
        selectedTabId: _effectiveSelectedTabId,
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
        'NakedTabsScope.of() called outside of NakedTabs.\n'
        'Wrap NakedTab and NakedTabView widgets in a NakedTabs.',
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
class NakedTabBar extends StatelessWidget {
  const NakedTabBar({super.key, required this.child});
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
/// The builder receives a [NakedTabState] with the tab ID, selected tab ID,
/// and interaction states for custom styling.
///
/// See also:
/// - [NakedTabs], the container that manages tab state.
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

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, the widget and its children are hidden from accessibility services.
  final bool excludeSemantics;

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
    node
      ..canRequestFocus = _isEnabled
      ..skipTraversal = !_isEnabled;
  }

  void _handleTap() {
    if (!_isEnabled) return;
    if (widget.enableFeedback) HapticFeedback.selectionClick();
    if (effectiveFocusNode.canRequestFocus) {
      effectiveFocusNode.requestFocus();
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
    // Move left until we cannot go further (reaching the first tab).
    while (scope.focusInDirection(TraversalDirection.left)) {
      // Continue until we reach the first tab.
    }
  }

  void _focusLastTab() {
    // Find the last tab in the current tab group
    final scope = FocusScope.of(context);
    scope.focusInDirection(TraversalDirection.right);
    // Move right until we cannot go further (reaching the last tab).
    while (scope.focusInDirection(TraversalDirection.right)) {
      // Continue until we reach the last tab.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = NakedTabsScope.of(context);
    _isEnabled = widget.enabled && _scope.enabled;
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
    updateDisabledState(!_isEnabled);
    updateSelectedState(isSelected, null);

    final tabState = NakedTabState(states: widgetStates, tabId: widget.tabId);

    final wrappedContent = NakedStateScopeBuilder(
      value: tabState,
      child: widget.child,
      builder: widget.builder,
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

    Widget tabChild = widget.excludeSemantics
        ? gestureDetector
        : Semantics(
            container: true,
            enabled: _isEnabled,
            selected: isSelected,
            button: true,
            label: widget.semanticLabel,
            onTap: _isEnabled ? _handleTap : null,
            child: gestureDetector,
          );

    return NakedFocusableDetector(
      enabled: _isEnabled,
      autofocus: widget.autofocus,
      onFocusChange: (f) {
        updateFocusState(f, widget.onFocusChange);
        if (f && _isEnabled) {
          _scope.selectTab(widget.tabId);
        }
        setState(() {});
      },
      onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
      focusNode: effectiveFocusNode,
      mouseCursor: _isEnabled ? widget.mouseCursor : SystemMouseCursors.basic,
      shortcuts: NakedIntentActions.tab.shortcuts,
      actions: NakedIntentActions.tab.actions(
        onActivate: () => _handleTap(),
        onDirectionalFocus: _handleDirectionalFocus,
        onFirstFocus: () => _focusFirstTab(),
        onLastFocus: () => _focusLastTab(),
      ),
      child: tabChild,
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
    assert(tabId.isNotEmpty, 'tabId cannot be empty');
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
        child: child,
      ),
    );
  }
}
