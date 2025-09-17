// ignore_for_file: no-empty-block

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'mixins/naked_mixins.dart';

/// A headless tab group without visuals.
///
/// Selection follows focus. Use [NakedTabList], [NakedTab], and
/// [NakedTabPanel] for custom visuals.
///
/// See also:
/// - [TabBar], the Material-styled tabs widget for typical apps.
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
/// Exposes interaction states for custom styling.
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

  /// The builder that receives interaction states.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

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
    with WidgetStatesMixin<NakedTab>, FocusableMixin<NakedTab> {
  @override
  FocusNode? get focusableExternalNode => widget.focusNode;

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

    final content = widget.builder != null
        ? widget.builder!(context, widgetStates, widget.child)
        : widget.child!;

    return FocusableActionDetector(
      enabled: _isEnabled,
      focusNode: effectiveFocusNode,
      autofocus: widget.autofocus,
      // Enter/Space still activate; focus change selects too (below).
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => _handleTap(),
        ),
      },
      onShowHoverHighlight: (h) => updateHoverState(h, widget.onHoverChange),
      onFocusChange: (f) {
        updateFocusState(f, widget.onFocusChange);
        if (f && _isEnabled) {
          _scope.selectTab(widget.tabId); // selection follows focus
        }
        setState(() {}); // update focused state for builder
      },
      mouseCursor: _isEnabled ? widget.mouseCursor : SystemMouseCursors.basic,
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
