import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'naked_button.dart';
import 'utilities/utilities.dart';

/// Headless select/dropdown with keyboard navigation and overlay positioning.
/// No Material widgets or semantics are introduced by this control.
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

  /// Trigger widget (usually a [NakedSelectTrigger]).
  final Widget child;

  /// Menu content when open.
  final Widget menu;

  final VoidCallback? onClose;
  final VoidCallback? onOpen;

  // Single-select.
  final T? selectedValue;
  final ValueChanged<T?>? onSelectedValueChanged;

  // Multi-select.
  final Set<T>? selectedValues;
  final ValueChanged<Set<T>>? onSelectedValuesChanged;

  final bool allowMultiple;
  final bool enabled;

  /// Interactive only if we can emit changes.
  bool get _effectiveEnabled =>
      enabled &&
      (onSelectedValueChanged != null || onSelectedValuesChanged != null);

  final bool closeOnSelect;
  final bool autofocus;

  // Type-ahead.
  final bool enableTypeAhead;
  final Duration typeAheadDebounceTime;

  // Positioning.
  final NakedMenuPosition menuPosition;
  final List<NakedMenuPosition> fallbackPositions;

  // Overlay policy.
  final bool closeOnClickOutside;

  // A11y label/value.
  final String? semanticLabel;

  // Overlay lifecycle.
  @override
  final Duration removalDelay;

  @override
  final void Function(OverlayChildLifecycleState state)? onStateChange;

  @override
  State<NakedSelect<T>> createState() => _NakedSelectState<T>();
}

class _NakedSelectState<T> extends State<NakedSelect<T>>
    with MenuAnchorChildLifecycleMixin {
  // Derived each build so runtime changes to selectedValues are reflected.
  bool get _isMultipleSelection =>
      widget.allowMultiple && widget.selectedValues != null;

  final List<_SelectItemInfo<T>> _selectableItems = [];

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

  void _cancelTypeAheadTimer() {
    _typeAheadResetTimer?.cancel();
    _typeAheadResetTimer = null;
  }

  void _resetTypeAheadBuffer() {
    _cancelTypeAheadTimer();
    _typeAheadBuffer = '';
  }

  void _handleTypeAhead(String character) {
    if (!widget.enableTypeAhead) return;

    _cancelTypeAheadTimer();
    _typeAheadBuffer += character.toLowerCase();

    for (final item in _selectableItems) {
      final stringValue = item.value.toString().toLowerCase();
      if (stringValue.startsWith(_typeAheadBuffer)) {
        if (item.focusNode.canRequestFocus) {
          item.focusNode.requestFocus();
        }
        break;
      }
    }

    _typeAheadResetTimer = Timer(
      widget.typeAheadDebounceTime,
      _resetTypeAheadBuffer,
    );
  }

  /// Register or update a selectable item mapping for focus traversal/type-ahead.
  void _registerSelectableItem(T value, FocusNode focusNode) {
    final index = _selectableItems.indexWhere((it) => it.value == value);
    if (index == -1) {
      _selectableItems.add(_SelectItemInfo(value: value, focusNode: focusNode));
    } else if (!identical(_selectableItems[index].focusNode, focusNode)) {
      _selectableItems[index] = _SelectItemInfo(
        value: value,
        focusNode: focusNode,
      );
    }
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

  void toggleMenu() => _isOpen ? closeMenu() : openMenu();

  void openMenu() {
    widget.onOpen?.call();
    showNotifier.value = true;
  }

  void closeMenu() {
    widget.onClose?.call();
    _selectableItems.clear();
    _resetTypeAheadBuffer();
    showNotifier.value = false;
  }

  @override
  void dispose() {
    _cancelTypeAheadTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = showNotifier.value;
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
        consumeOutsideTaps: widget.closeOnClickOutside,
        position: widget.menuPosition,
        fallbackPositions: widget.fallbackPositions,
        onClose: closeMenu,
        onOpen: openMenu,
        onKeyEvent: (event) {
          // Only react on key-down to avoid double handling on key-up.
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.escape) {
              closeMenu();

              return;
            }
            final character = event.character;
            if (character != null &&
                character.isNotEmpty &&
                widget.enableTypeAhead) {
              _handleTypeAhead(character);
            }
          }
        },
        child: widget.child,
      ),
    );

    // Headless semantics: one "button" with expanded state & current value.
    return Semantics(
      container: true,
      enabled: widget._effectiveEnabled,
      button: true,
      expanded: isExpanded,
      label: widget.semanticLabel,
      value: selectedValueString,
      onTap: widget._effectiveEnabled ? toggleMenu : null,
      child: selectWidget,
    );
  }
}

/// Inherited selection snapshot for descendants.
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
    final inherited = maybeOf<T>(context);
    if (inherited == null) {
      throw StateError(
        'NakedSelectScope<$T> not found in context.\n'
        'Make sure NakedSelectScope is an ancestor of the current widget.',
      );
    }

    return inherited;
  }

  final T? selectedValue;
  final Set<T>? selectedValues;
  final bool allowMultiple;
  final bool enabled;

  bool isSelected(BuildContext context, T value) {
    final inheritedValues = NakedSelectScope.of<T>(context);
    if (inheritedValues.allowMultiple) {
      return inheritedValues.selectedValues?.contains(value) ?? false;
    }

    return inheritedValues.selectedValue == value;
  }

  @override
  bool updateShouldNotify(NakedSelectScope<T> oldWidget) {
    return selectedValue != oldWidget.selectedValue ||
        !setEquals(selectedValues, oldWidget.selectedValues) ||
        enabled != oldWidget.enabled ||
        allowMultiple != oldWidget.allowMultiple;
  }
}

class _SelectItemInfo<T> {
  final T value;
  final FocusNode focusNode;
  const _SelectItemInfo({required this.value, required this.focusNode});
}

/// Trigger that controls the select dropdown.
///
/// Kept headless (no internal Semantics) to avoid duplicating the root
/// NakedSelect's "button + expanded" semantics.
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
      if (widget.enableFeedback) {
        Feedback.forTap(context);
      }
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
          // ignore: body_might_complete_normally_nullable
          onInvoke: (_) {
            flashPressed();
            if (widget.enableFeedback) {
              Feedback.forTap(context);
            }
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
        // semantics come from the NakedSelect root
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

/// A selectable item within the dropdown menu.
///
/// Reuses `NakedButton` for input modality parity and state callbacks,
/// and augments semantics with "selected" using MergeSemantics so screen
/// readers see a single node.
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

  @override
  FocusNode? get focusableExternalNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    // Register after first layout so ancestor state is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerWithSelect());
  }

  void _registerWithSelect() {
    if (_registered) return;
    final state = context.findAncestorStateOfType<_NakedSelectState<T>>();
    final node = effectiveFocusNode;
    if (state != null && node != null) {
      state._registerSelectableItem(widget.value, node);
      _registered = true;
    }
  }

  @override
  void didUpdateWidget(NakedSelectItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If value or external focus node changes, refresh registration post-frame.
    if (widget.value != oldWidget.value ||
        widget.focusNode != oldWidget.focusNode) {
      _registered = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _registerWithSelect(),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Notify consumer only on real selection flips.
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
