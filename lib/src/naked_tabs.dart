// ignore_for_file: no-empty-block

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Provides tab interaction behavior without visual styling.
/// Headless, no Material/Cupertino dependencies.
/// Pattern: selection follows focus + optional ActivateIntent (Enter/Space).
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

  final Widget child;

  /// The ID of the currently selected tab.
  final String selectedTabId;

  /// Called when the selected tab ID changes.
  final ValueChanged<String>? onChanged;

  /// Whether the tabs component is enabled.
  final bool enabled;

  /// Orientation (affects traversal expectations for users; we rely on default focus traversal).
  final Axis orientation;

  /// Invoked when ESC is pressed and any tab within the group has focus.
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

/// Inherited scope for tab state and basic API.
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

/// Container for tab triggers (headless).
/// Simplified: rely on default focus traversal; no custom shortcuts needed.
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

/// An individual tab trigger. Headless; selection follows focus.
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

  final Widget? child;
  final String tabId;

  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onPressChange;

  /// Builder receives: {disabled, selected, focused, hovered, pressed}.
  final ValueWidgetBuilder<Set<WidgetState>>? builder;

  final String? semanticLabel;

  final bool enabled;
  final MouseCursor mouseCursor;
  final bool enableFeedback;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<NakedTab> createState() => _NakedTabState();
}

class _NakedTabState extends State<NakedTab> {
  late final FocusNode _focusNode =
      widget.focusNode ?? FocusNode(debugLabel: 'NakedTab-${widget.tabId}');

  bool _hovered = false;
  bool _pressed = false;
  late bool _isEnabled;
  late NakedTabsScope _scope;

  void _handleTap() {
    if (!_isEnabled) return;
    if (widget.enableFeedback) HapticFeedback.selectionClick();
    // Selection follows focus anyway; tap still ensures we’re focused.
    if (_focusNode.canRequestFocus) _focusNode.requestFocus();
    _scope.selectTab(widget.tabId);
  }

  Set<WidgetState> _states(bool isSelected) => {
    if (!_isEnabled) WidgetState.disabled,
    if (isSelected) WidgetState.selected,
    if (_focusNode.hasFocus) WidgetState.focused,
    if (_hovered) WidgetState.hovered,
    if (_pressed) WidgetState.pressed,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = NakedTabsScope.of(context);
    _isEnabled = widget.enabled && _scope.enabled;

    // Disabled tabs shouldn’t be focusable or in traversal.
    _focusNode
      ..canRequestFocus = _isEnabled
      ..skipTraversal = !_isEnabled;
  }

  @override
  void didUpdateWidget(covariant NakedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newEnabled = widget.enabled && _scope.enabled;
    if (newEnabled != _isEnabled) {
      _isEnabled = newEnabled;
      _focusNode
        ..canRequestFocus = _isEnabled
        ..skipTraversal = !_isEnabled;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.tabId.isNotEmpty, 'tabId cannot be empty');

    final isSelected = _scope.isTabSelected(widget.tabId);
    final content = widget.builder != null
        ? widget.builder!(context, _states(isSelected), widget.child)
        : widget.child!;

    return FocusableActionDetector(
      enabled: _isEnabled,
      focusNode: _focusNode,
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
      onShowHoverHighlight: (h) {
        if (_hovered != h) {
          _hovered = h;
          widget.onHoverChange?.call(h);
          setState(() {}); // update builder states
        }
      },
      onFocusChange: (f) {
        widget.onFocusChange?.call(f);
        if (f && _isEnabled) {
          _scope.selectTab(widget.tabId); // selection follows focus
        }
        setState(() {}); // update focused state for builder
      },
      mouseCursor: _isEnabled ? widget.mouseCursor : SystemMouseCursors.basic,
      child: MouseRegion(
        onEnter: (_) {
          if (_isEnabled && !_hovered) {
            _hovered = true;
            widget.onHoverChange?.call(true);
            setState(() {});
          }
        },
        onExit: (_) {
          if (_isEnabled && _hovered) {
            _hovered = false;
            widget.onHoverChange?.call(false);
            setState(() {});
          }
        },
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
                ? (_) {
                    _pressed = true;
                    widget.onPressChange?.call(true);
                    setState(() {});
                  }
                : null,
            onTapUp: _isEnabled
                ? (_) {
                    _pressed = false;
                    widget.onPressChange?.call(false);
                    setState(() {});
                  }
                : null,
            onTap: _isEnabled ? _handleTap : null,
            onTapCancel: _isEnabled
                ? () {
                    _pressed = false;
                    widget.onPressChange?.call(false);
                    setState(() {});
                  }
                : null,
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// A panel that displays content for a specific tab.
class NakedTabPanel extends StatelessWidget {
  const NakedTabPanel({
    super.key,
    required this.child,
    required this.tabId,
    this.maintainState = true,
  });

  final Widget child;
  final String tabId;
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
