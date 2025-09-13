import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'naked_button.dart';
import 'utilities/naked_menu_anchor.dart';

class NakedSelect<T> extends StatefulWidget implements OverlayChildLifecycle {
  const NakedSelect({
    super.key,
    required this.child,
    required this.menu,
    this.onClose,
    this.onOpen,
    this.selectedValue,
    this.onStateChange,
    this.removalDelay = Duration.zero,
    this.onSelectedValueChanged,
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

  final Widget child;
  final Widget menu;

  final VoidCallback? onClose;
  final VoidCallback? onOpen;

  final T? selectedValue;
  final ValueChanged<T?>? onSelectedValueChanged;

  final Set<T>? selectedValues;
  final ValueChanged<Set<T>>? onSelectedValuesChanged;

  final bool allowMultiple;
  final bool enabled;

  // Select should be interactable if `enabled` is true, regardless of
  // whether selection callbacks are provided.
  bool get _effectiveEnabled => enabled;

  final bool closeOnSelect;
  final bool autofocus;

  final bool enableTypeAhead;
  final Duration typeAheadDebounceTime;

  final NakedMenuPosition menuPosition;
  final List<NakedMenuPosition> fallbackPositions;

  /// Should clicking outside close the menu? (propagation controlled by anchor)
  final bool closeOnClickOutside;

  final String? semanticLabel;

  @override
  final Duration removalDelay;

  @override
  final void Function(OverlayChildLifecycleState state)? onStateChange;

  @override
  State<NakedSelect<T>> createState() => _NakedSelectState<T>();
}

class _NakedSelectState<T> extends State<NakedSelect<T>>
    with MenuAnchorChildLifecycleMixin {
  bool get _isMultipleSelection =>
      widget.allowMultiple && widget.selectedValues != null;

  final List<_SelectItemInfo<T>> _selectableItems = [];

  // Tracks actual overlay visibility (driven by onOpen/onClose) for Semantics.expanded
  final _overlayOpen = ValueNotifier(false);

  bool get _isOpen => controller.isOpen;
  bool get isOpen => _isOpen;
  bool get isEnabled => widget.enabled;

  // Type-ahead tracking.
  String _typeAheadBuffer = '';
  Timer? _typeAheadResetTimer;

  void _handleTriggerTap() {
    if (!widget._effectiveEnabled) return;
    toggleMenu();
  }

  void toggleMenu() => _isOpen ? closeMenu() : openMenu();

  void openMenu() {
    showNotifier.value = true;
  }

  void closeMenu() {
    showNotifier.value = false;
  }

  void _handleAnchorOpen() {
    widget.onOpen?.call();
    // Reflect actual overlay visibility for semantics without rebuilding the whole widget.
    _overlayOpen.value = true;
  }

  void _handleAnchorClose() {
    widget.onClose?.call();
    _selectableItems.clear();
    _resetTypeAheadBuffer();
    // Return focus to the trigger if it provided a FocusNode.
    final child = widget.child;
    if (child is NakedSelectTrigger) {
      child.focusNode?.requestFocus();
    }
    // Reflect actual overlay visibility for semantics without rebuilding the whole widget.
    _overlayOpen.value = false;
  }

  void _cancelTypeAheadTimer() {
    _typeAheadResetTimer?.cancel();
    _typeAheadResetTimer = null;
  }

  void _resetTypeAheadBuffer() {
    _cancelTypeAheadTimer();
    _typeAheadBuffer = '';
  }

  void _handleTypeAhead(String ch) {
    if (!widget.enableTypeAhead) return;

    _cancelTypeAheadTimer();
    _typeAheadBuffer += ch.toLowerCase();

    for (final item in _selectableItems) {
      final s = item.value.toString().toLowerCase();
      if (s.startsWith(_typeAheadBuffer)) {
        if (item.focusNode.canRequestFocus) item.focusNode.requestFocus();
        break;
      }
    }

    _typeAheadResetTimer = Timer(
      widget.typeAheadDebounceTime,
      _resetTypeAheadBuffer,
    );
  }

  /// Register/update a selectable item mapping for focus traversal/type-ahead.
  void _registerSelectableItem(T value, FocusNode focusNode) {
    final i = _selectableItems.indexWhere((it) => it.value == value);
    if (i == -1) {
      _selectableItems.add(_SelectItemInfo(value: value, focusNode: focusNode));
    } else if (!identical(_selectableItems[i].focusNode, focusNode)) {
      _selectableItems[i] = _SelectItemInfo(value: value, focusNode: focusNode);
    }
  }

  /// Remove a selectable item mapping when its widget is disposed or replaced.
  void _unregisterSelectableItem(T value, FocusNode? focusNode) {
    _selectableItems.removeWhere(
      (it) =>
          it.value == value ||
          (focusNode != null && identical(it.focusNode, focusNode)),
    );
  }

  void _handleSelectValue(T value) {
    if (!widget._effectiveEnabled) return;

    if (_isMultipleSelection) {
      final newValues = Set<T>.of(widget.selectedValues!);
      newValues.contains(value)
          ? newValues.remove(value)
          : newValues.add(value);
      widget.onSelectedValuesChanged?.call(newValues);
    } else {
      widget.onSelectedValueChanged?.call(value);
    }

    if (widget.closeOnSelect) closeMenu();
  }

  @override
  void dispose() {
    _cancelTypeAheadTimer();
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

    final selectWidget = NakedSelectScope<T>(
      selectedValue: widget.selectedValue,
      selectedValues: widget.selectedValues,
      allowMultiple: widget.allowMultiple,
      enabled: widget._effectiveEnabled,
      child: NakedMenuAnchor(
        controller: controller,
        overlayBuilder: (_) => widget.menu,
        consumeOutsideTaps: true,
        // Headless policy:
        closeOnOutsideTap: widget.closeOnClickOutside,
        removalDelay: widget.removalDelay,
        position: widget.menuPosition,
        fallbackPositions: widget.fallbackPositions,
        onClose: _handleAnchorClose,
        onOpen: _handleAnchorOpen,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.arrowDown) {
              // If no item is focused yet, focus the first selectable item.
              final first = _selectableItems.isNotEmpty
                  ? _selectableItems.first
                  : null;
              final anyFocused = _selectableItems.any(
                (it) => it.focusNode.hasFocus,
              );
              if (!anyFocused &&
                  first != null &&
                  first.focusNode.canRequestFocus) {
                first.focusNode.requestFocus();

                return KeyEventResult.handled;
              }
            }

            final ch = event.character;
            if (ch != null && ch.isNotEmpty && widget.enableTypeAhead) {
              _handleTypeAhead(ch);
            }
          }

          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: _overlayOpen,
      child: selectWidget,
      builder: (context, expanded, child) {
        return Semantics(
          container: true,
          enabled: widget._effectiveEnabled,
          button: true,
          expanded: expanded,
          label: widget.semanticLabel,
          value: selectedValueString,
          onTap: widget._effectiveEnabled ? toggleMenu : null,
          child: child,
        );
      },
    );
  }
}

class NakedSelectScope<T> extends InheritedWidget {
  const NakedSelectScope({
    super.key,
    required super.child,
    required this.selectedValue,
    required this.selectedValues,
    required this.allowMultiple,
    required this.enabled,
  });

  static NakedSelectScope<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  static NakedSelectScope<T> of<T>(BuildContext context) {
    final i = maybeOf<T>(context);
    if (i == null) {
      throw StateError(
        'NakedSelectScope<$T> not found in context.\n'
        'Make sure NakedSelectScope is an ancestor of the current widget.',
      );
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

class _SelectItemInfo<T> {
  final T value;
  final FocusNode focusNode;
  const _SelectItemInfo({required this.value, required this.focusNode});
}

/// Trigger: no semantics (root provides button + expanded).
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

  final Widget child;

  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onPressChange;

  final MouseCursor mouseCursor;
  final bool enableFeedback;

  final FocusNode? focusNode;
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
      selectState?._handleTriggerTap();
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
          // ignore:  body_might_complete_normally_nullable
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

/// Item: reuse NakedButton; add `selected` semantics; manage focus via mixin.
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

  final Widget child;
  final T value;

  final ValueChanged<bool>? onSelectChange;

  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onPressChange;

  final bool enabled;
  final MouseCursor mouseCursor;
  final bool enableFeedback;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<NakedSelectItem<T>> createState() => _NakedSelectItemState<T>();
}

class _NakedSelectItemState<T> extends State<NakedSelectItem<T>>
    with FocusableMixin<NakedSelectItem<T>> {
  bool _registered = false;
  bool? _lastReportedSelection;
  _NakedSelectState<T>?
  _selectState; // cache parent state to avoid context lookup in dispose

  @override
  FocusNode? get focusableExternalNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerWithSelect());
  }

  void _registerWithSelect() {
    if (_registered) return;
    final state = context.findAncestorStateOfType<_NakedSelectState<T>>();
    final node = effectiveFocusNode;
    if (state != null && node != null) {
      state._registerSelectableItem(widget.value, node);
      _selectState = state;
      _registered = true;
    }
  }

  @override
  void dispose() {
    // Use cached reference; avoid ancestor lookups in dispose.
    _selectState?._unregisterSelectableItem(widget.value, effectiveFocusNode);
    super.dispose();
  }

  @override
  void didUpdateWidget(NakedSelectItem<T> old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value || widget.focusNode != old.focusNode) {
      _registered = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _registerWithSelect(),
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
          onPressed: () => selectState?._handleSelectValue(widget.value),
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
