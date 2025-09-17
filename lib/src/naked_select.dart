// naked_select.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'naked_button.dart';
import 'utilities/naked_menu_anchor.dart';

/// Headless select/dropdown that renders menu in an overlay.
///
/// Use default constructor for single-select, or [NakedSelect.multiple]
/// for multi-select. Supports keyboard navigation and type-ahead.
///
/// Example:
/// ```dart
/// NakedSelect<String>(
///   selectedValue: value,
///   onSelectedValueChanged: (v) => setState(() => value = v),
///   child: const NakedSelectTrigger(child: Text('Open')),
///   menu: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       NakedSelectItem(value: 'A', child: Text('A')),
///       NakedSelectItem(value: 'B', child: Text('B')),
///     ],
///   ),
/// )
/// ```
///
/// See also:
/// - [NakedMenuAnchor], which provides the underlying overlay positioning.
/// - [NakedMenu], a simpler headless dropdown built on top of the same anchor.
/// - [NakedButton], which is commonly used by select triggers and items.

class NakedSelect<T> extends StatefulWidget {
  const NakedSelect({
    super.key,
    required this.child,
    required this.menu,
    this.onClose,
    this.onOpen,
    this.onStateChange,
    this.selectedValue,
    this.onSelectedValueChanged,
    this.removalDelay = Duration.zero,
    this.enabled = true,
    this.closeOnSelect = true,
    this.autofocus = false,
    this.enableTypeAhead = true,
    this.typeAheadDebounceTime = const Duration(milliseconds: 500),
    this.menuPosition = const NakedMenuPosition(
      target: Alignment.bottomLeft,
      follower: Alignment.topLeft,
    ),
    this.fallbackPositions = const [
      NakedMenuPosition(
        target: Alignment.topLeft,
        follower: Alignment.bottomLeft,
      ),
    ],
    this.closeOnClickOutside = true,
    this.semanticLabel,
  }) : allowMultiple = false,
       selectedValues = null,
       onSelectedValuesChanged = null;

  const NakedSelect.multiple({
    super.key,
    required this.child,
    required this.menu,
    this.onClose,
    this.onOpen,
    this.onStateChange,
    this.removalDelay = Duration.zero,
    this.selectedValues,
    this.onSelectedValuesChanged,
    this.enabled = true,
    this.closeOnSelect = true,
    this.autofocus = false,
    this.enableTypeAhead = true,
    this.typeAheadDebounceTime = const Duration(milliseconds: 500),
    this.menuPosition = const NakedMenuPosition(
      target: Alignment.bottomLeft,
      follower: Alignment.topLeft,
    ),
    this.fallbackPositions = const [
      NakedMenuPosition(
        target: Alignment.topLeft,
        follower: Alignment.bottomLeft,
      ),
    ],
    this.closeOnClickOutside = true,
    this.semanticLabel,
  }) : allowMultiple = true,
       selectedValue = null,
       onSelectedValueChanged = null;

  /// The trigger widget (inline content).
  final Widget child;

  /// The overlay menu content.
  final Widget menu;

  /// Called when the overlay closes.
  final VoidCallback? onClose;

  /// Called when the overlay opens.
  final VoidCallback? onOpen;

  /// Called when overlay lifecycle changes occur.
  final OverlayChildLifecycleCallback? onStateChange;

  /// The selected value in single-select mode.
  final T? selectedValue;

  /// Called when the selected value changes.
  final ValueChanged<T?>? onSelectedValueChanged;

  /// The selected values in multi-select mode.
  final Set<T>? selectedValues;

  /// Called when selected values change.
  final ValueChanged<Set<T>>? onSelectedValuesChanged;

  /// Whether multiple values can be selected.
  final bool allowMultiple;

  /// Whether the select is enabled.
  final bool enabled;
  bool get _effectiveEnabled => enabled;

  /// Whether selecting an item closes the menu.
  final bool closeOnSelect;

  /// Whether to autofocus the overlay when opened.
  final bool autofocus;

  /// Whether to enable type-ahead navigation.
  final bool enableTypeAhead;

  /// The debounce duration for type-ahead buffering.
  final Duration typeAheadDebounceTime;

  /// The preferred overlay position relative to trigger.
  final NakedMenuPosition menuPosition;

  /// The fallback positions when preferred doesn't fit.
  final List<NakedMenuPosition> fallbackPositions;

  /// Whether clicking outside closes the menu.
  final bool closeOnClickOutside;

  /// The semantic label for the trigger.
  final String? semanticLabel;

  /// The delay before removing overlay after closing.
  final Duration removalDelay;

  @override
  State<NakedSelect<T>> createState() => _NakedSelectState<T>();
}

class _NakedSelectState<T> extends State<NakedSelect<T>> {
  // ignore: dispose-fields
  final _menuController = MenuController();
  final ValueNotifier<bool> _overlayOpen = ValueNotifier(false);
  Timer? _removedTick;

  // Type-ahead
  final List<_SelectItemInfo<T>> _items = <_SelectItemInfo<T>>[];
  String _typeAhead = '';
  Timer? _typeAheadTimer;

  bool get _isOpen => _menuController.isOpen;

  bool get _isMultipleSelection =>
      widget.allowMultiple && widget.selectedValues != null;

  // ——— open/close ———
  void _toggleMenu() =>
      _isOpen ? _menuController.close() : _menuController.open();

  void _handleAnchorOpen() {
    _overlayOpen.value = true;
    widget.onOpen?.call();
    widget.onStateChange?.call(OverlayChildLifecycleState.present);
  }

  void _handleAnchorClose() {
    _overlayOpen.value = false;
    widget.onClose?.call();
    widget.onStateChange?.call(OverlayChildLifecycleState.pendingRemoval);
    _removedTick?.cancel();
    if (widget.removalDelay == Duration.zero) {
      widget.onStateChange?.call(OverlayChildLifecycleState.removed);
    } else {
      _removedTick = Timer(widget.removalDelay, () {
        widget.onStateChange?.call(OverlayChildLifecycleState.removed);
      });
    }
    _items.clear();
    _resetTypeAhead();

    // Hand focus back to the trigger (Raw will also use childFocusNode).
    final child = widget.child;
    if (child is NakedSelectTrigger) {
      child.focusNode?.requestFocus();
    }
  }

  // ——— type-ahead ———
  void _cancelTypeAheadTimer() {
    _typeAheadTimer?.cancel();
    _typeAheadTimer = null;
  }

  void _resetTypeAhead() {
    _cancelTypeAheadTimer();
    _typeAhead = '';
  }

  bool _handleTypeAheadChar(String ch) {
    if (!widget.enableTypeAhead || ch.isEmpty) return false;

    _cancelTypeAheadTimer();
    _typeAhead += ch.toLowerCase();

    // Find first item whose value string starts with the buffer.
    for (final item in _items) {
      final s = item.value.toString().toLowerCase();
      if (s.startsWith(_typeAhead)) {
        if (item.focusNode.canRequestFocus) {
          item.focusNode.requestFocus();
          _typeAheadTimer = Timer(
            widget.typeAheadDebounceTime,
            _resetTypeAhead,
          );

          return true; // consumed
        }
        break;
      }
    }
    _typeAheadTimer = Timer(widget.typeAheadDebounceTime, _resetTypeAhead);

    return false;
  }

  // ——— item registration ———
  void _registerItem(T value, FocusNode node) {
    final i = _items.indexWhere((it) => it.value == value);
    if (i == -1) {
      _items.add(_SelectItemInfo(value: value, focusNode: node));
    } else if (!identical(_items[i].focusNode, node)) {
      _items[i] = _SelectItemInfo(value: value, focusNode: node);
    }
  }

  void _unregisterItem(T value, FocusNode? node) {
    _items.removeWhere(
      (it) =>
          it.value == value || (node != null && identical(it.focusNode, node)),
    );
  }

  // ——— selection ———
  void _selectValue(T value) {
    if (!widget._effectiveEnabled) return;

    if (_isMultipleSelection) {
      final next = Set<T>.of(widget.selectedValues ?? const {});
      next.contains(value) ? next.remove(value) : next.add(value);
      widget.onSelectedValuesChanged?.call(next);
    } else {
      widget.onSelectedValueChanged?.call(value);
    }
    if (widget.closeOnSelect) _menuController.close();
  }

  @override
  void dispose() {
    _cancelTypeAheadTimer();
    _removedTick?.cancel();
    _overlayOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedValueString =
        widget.selectedValue?.toString() ??
        (widget.selectedValues?.isNotEmpty == true
            ? widget.selectedValues!.map((v) => v.toString()).join(', ')
            : null);

    final selectBody = NakedSelectScope<T>(
      selectedValue: widget.selectedValue,
      selectedValues: widget.selectedValues,
      allowMultiple: widget.allowMultiple,
      enabled: widget._effectiveEnabled,
      child: NakedMenuAnchor(
        controller: _menuController,
        overlayBuilder: (_) => widget.menu,
        // Hand Raw a "return-to" node for focus when the menu closes.
        childFocusNode: widget.child is NakedSelectTrigger
            ? (widget.child as NakedSelectTrigger).focusNode
            : null,
        consumeOutsideTaps: true,
        closeOnOutsideTap: widget.closeOnClickOutside,
        removalDelay: widget.removalDelay,
        position: widget.menuPosition,
        fallbackPositions: widget.fallbackPositions,
        onClose: _handleAnchorClose,
        onOpen: _handleAnchorOpen,
        // Let the overlay handle traversal (Shortcuts/Actions).
        // We only bootstrap first focus & type-ahead here.
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              final first = _items.isNotEmpty ? _items.first : null;
              final anyFocused = _items.any((it) => it.focusNode.hasFocus);
              if (!anyFocused &&
                  first != null &&
                  first.focusNode.canRequestFocus) {
                first.focusNode.requestFocus();

                return KeyEventResult.handled;
              }
            }
            final ch = event.character;
            if (ch != null && ch.isNotEmpty) {
              final consumed = _handleTypeAheadChar(ch);
              if (consumed) return KeyEventResult.handled;
            }
          }

          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );

    // Root semantics: announce "button", expanded/collapsed, label/value.
    return ValueListenableBuilder<bool>(
      valueListenable: _overlayOpen,
      child: selectBody,
      builder: (context, expanded, child) {
        return Semantics(
          container: true,
          enabled: widget._effectiveEnabled,
          button: true,
          expanded: expanded,
          label: widget.semanticLabel,
          value: selectedValueString,
          onTap: widget._effectiveEnabled ? _toggleMenu : null,
          child: child!,
        );
      },
    );
  }
}

/// Provides selection state to descendant [NakedSelectItem] widgets.
///
/// Items use [isSelected] to test selection status and register with
/// the parent for type-ahead focus.
class NakedSelectScope<T> extends InheritedWidget {
  const NakedSelectScope({
    super.key,
    required super.child,
    required this.selectedValue,
    required this.selectedValues,
    required this.allowMultiple,
    required this.enabled,
  });

  static NakedSelectScope<T>? maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType();

  static NakedSelectScope<T> of<T>(BuildContext context) {
    final i = maybeOf<T>(context);
    if (i == null) {
      throw StateError('NakedSelectScope<$T> not found in context.');
    }

    return i;
  }

  final T? selectedValue;
  final Set<T>? selectedValues;
  final bool allowMultiple;
  final bool enabled;

  bool isSelected(BuildContext context, T value) {
    final s = NakedSelectScope.of<T>(context);

    return s.allowMultiple
        ? (s.selectedValues?.contains(value) ?? false)
        : s.selectedValue == value;
  }

  @override
  bool updateShouldNotify(NakedSelectScope<T> old) {
    return selectedValue != old.selectedValue ||
        !setEquals(selectedValues, old.selectedValues) ||
        enabled != old.enabled ||
        allowMultiple != old.allowMultiple;
  }
}

/// Trigger button for [NakedSelect] without semantics.
///
/// See also:
/// - [NakedSelect], which renders this trigger and provides overlay semantics.
class NakedSelectTrigger extends StatefulWidget {
  const NakedSelectTrigger({
    super.key,
    required this.child,
    this.mouseCursor = SystemMouseCursors.click,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
  });

  /// The trigger button content.
  final Widget child;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when press state changes.
  final ValueChanged<bool>? onPressChange;

  /// The mouse cursor when interactive.
  final MouseCursor mouseCursor;

  /// Whether to provide haptic feedback on activation.
  final bool enableFeedback;

  /// The focus node for the trigger.
  final FocusNode? focusNode;

  /// Whether to autofocus when built.
  final bool autofocus;

  @override
  State<NakedSelectTrigger> createState() => _NakedSelectTriggerState();
}

class _NakedSelectTriggerState extends State<NakedSelectTrigger>
    with FocusableMixin<NakedSelectTrigger> {
  static const Duration _activationDuration = Duration(milliseconds: 100);
  Timer? _pressFlashTimer;

  @override
  FocusNode? get focusableExternalNode => widget.focusNode;

  @override
  void dispose() {
    _pressFlashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectState = context.findAncestorStateOfType<_NakedSelectState>();
    final bool interactiveEnabled =
        selectState?.widget._effectiveEnabled ?? true;

    void handleTap() {
      if (!interactiveEnabled) return;
      if (widget.enableFeedback) Feedback.forTap(context);
      selectState?._toggleMenu();
    }

    void flashPressed() {
      widget.onPressChange?.call(true);
      _pressFlashTimer?.cancel();
      _pressFlashTimer = Timer(_activationDuration, () {
        widget.onPressChange?.call(false);
      });
    }

    return FocusableActionDetector(
      enabled: interactiveEnabled,
      focusNode: effectiveFocusNode,
      autofocus: widget.autofocus,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          // ignore: body_might_complete_normally_nullable
          onInvoke: (_) {
            flashPressed();
            if (widget.enableFeedback) Feedback.forTap(context);
            handleTap();
          },
        ),
      },
      onShowHoverHighlight: widget.onHoverChange,
      onFocusChange: widget.onFocusChange,
      mouseCursor: interactiveEnabled
          ? widget.mouseCursor
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: interactiveEnabled ? (_) => flashPressed() : null,
        onTapUp: interactiveEnabled
            ? (_) => widget.onPressChange?.call(false)
            : null,
        onTap: interactiveEnabled ? handleTap : null,
        onTapCancel: interactiveEnabled
            ? () => widget.onPressChange?.call(false)
            : null,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        child: widget.child,
      ),
    );
  }
}

/// Selectable item that exposes selection semantics and focus behavior.
///
/// See also:
/// - [NakedSelect], which provides selection state and overlay.
/// - [NakedButton], which implements the activation surface.
class NakedSelectItem<T> extends StatefulWidget {
  const NakedSelectItem({
    super.key,
    required this.child,
    required this.value,
    this.onSelectChange,
    this.enabled = true,
    this.mouseCursor = SystemMouseCursors.click,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
  });

  /// The item content.
  final Widget child;

  /// The value represented by this option.
  final T value;

  /// Called when selection status changes.
  final ValueChanged<bool>? onSelectChange;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when press state changes.
  final ValueChanged<bool>? onPressChange;

  /// Whether the option is enabled.
  final bool enabled;

  /// The mouse cursor when interactive.
  final MouseCursor mouseCursor;

  /// Whether to provide haptic feedback on activation.
  final bool enableFeedback;

  /// The focus node for the option.
  final FocusNode? focusNode;

  /// Whether to autofocus when the menu opens.
  final bool autofocus;

  @override
  State<NakedSelectItem<T>> createState() => _NakedSelectItemState<T>();
}

class _NakedSelectItemState<T> extends State<NakedSelectItem<T>>
    with FocusableMixin<NakedSelectItem<T>> {
  bool _registered = false;
  bool? _lastReportedSelection;
  // cached; avoid ancestor lookup in dispose
  _NakedSelectState<T>? _selectState;

  @override
  FocusNode? get focusableExternalNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerWithParent());
  }

  void _registerWithParent() {
    if (_registered) return;
    final state = context.findAncestorStateOfType<_NakedSelectState<T>>();
    final node = effectiveFocusNode;
    if (state != null && node != null) {
      state._registerItem(widget.value, node);
      _selectState = state;
      _registered = true;
    }
  }

  @override
  void didUpdateWidget(NakedSelectItem<T> old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value || widget.focusNode != old.focusNode) {
      _registered = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _registerWithParent(),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inherited = NakedSelectScope.maybeOf<T>(context);
    if (inherited != null) {
      final isSelected = inherited.isSelected(context, widget.value);
      if (_lastReportedSelection != isSelected) {
        _lastReportedSelection = isSelected;
        widget.onSelectChange?.call(isSelected);
      }
    }
  }

  @override
  void dispose() {
    _selectState?._unregisterItem(widget.value, effectiveFocusNode);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectState = context.findAncestorStateOfType<_NakedSelectState<T>>();
    final bool parentEnabled = selectState?.widget._effectiveEnabled ?? true;
    final bool isEffectivelyEnabled = widget.enabled && parentEnabled;

    final inherited = NakedSelectScope.of<T>(context);
    final isSelected = inherited.isSelected(context, widget.value);

    return MergeSemantics(
      child: Semantics(
        selected: isSelected,
        child: NakedButton(
          onPressed: () => selectState?._selectValue(widget.value),
          enabled: isEffectivelyEnabled,
          mouseCursor: widget.mouseCursor,
          enableFeedback: widget.enableFeedback,
          focusNode: effectiveFocusNode,
          autofocus: widget.autofocus,
          onFocusChange: widget.onFocusChange,
          onHoverChange: widget.onHoverChange,
          onPressChange: widget.onPressChange,
          child: widget.child,
        ),
      ),
    );
  }
}

class _SelectItemInfo<T> {
  final T value;
  final FocusNode focusNode;
  const _SelectItemInfo({required this.value, required this.focusNode});
}
