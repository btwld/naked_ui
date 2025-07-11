import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'naked_button.dart';
import 'utilities/utilities.dart';

/// A fully customizable select/dropdown widget with no default styling.
///
/// NakedSelect provides complete control over the appearance and behavior of a dropdown menu
/// while handling all the complex interaction patterns and accessibility requirements.
///
/// Key features:
/// - Full styling control through callbacks for hover, press, and focus states
/// - Support for single and multiple selection modes
/// - Keyboard navigation and type-ahead functionality
/// - Automatic positioning with fallback alignments
/// - ARIA-compliant accessibility support
///
/// The component uses [NakedPortal] to render the dropdown content in the app overlay,
/// ensuring proper z-indexing and maintaining context inheritance.
///
/// Example usage:
/// ```dart
/// NakedSelect<String>(
///   selectedValue: selectedValue,
///   onSelectedValueChanged: (value) => setState(() => selectedValue = value),
///   child: NakedSelectTrigger(
///     child: Text(selectedValue ?? 'Select an option'),
///   ),
///   menu: NakedSelectMenu(
///     child: Column(
///       children: [
///         NakedSelectItem(
///           value: 'apple',
///           child: Text('Apple'),
///         ),
///         NakedSelectItem(
///           value: 'banana',
///           child: Text('Banana'),
///         ),
///         NakedSelectItem(
///           value: 'orange',
///           child: Text('Orange'),
///         ),
///       ],
///     ),
///   ),
///   onMenuClose: () => {},
/// )
/// ```
class NakedSelect<T> extends StatefulWidget implements OverlayChildLifecycle {
  /// Creates a naked select dropdown.
  ///
  /// The [child] and [menu] parameters are required.
  /// When [allowMultiple] is true, [selectedValues] must be provided.
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
    this.semanticLabel,
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
    this.semanticLabel,
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
  }) : allowMultiple = true,
       selectedValue = null,
       onSelectedValueChanged = null;

  /// The target widget that triggers the select dropdown.
  /// This should typically be a [NakedSelectTrigger].
  final Widget child;

  /// The menu widget to display when the dropdown is open.
  /// This should be a [NakedSelectMenu] containing [NakedSelectItem] widgets.
  final Widget menu;

  /// Called when the menu closes, either through selection or external interaction.
  final VoidCallback? onClose;

  /// The currently selected value in single selection mode.
  /// Only used when [allowMultiple] is false.
  final T? selectedValue;

  /// Called when the selected value changes in single selection mode.
  /// Only used when [allowMultiple] is false.
  final ValueChanged<T?>? onSelectedValueChanged;

  /// The set of currently selected values in multiple selection mode.
  /// Required when [allowMultiple] is true.
  final Set<T>? selectedValues;

  /// Called when selected values change in multiple selection mode.
  /// Only used when [allowMultiple] is true.
  final ValueChanged<Set<T>>? onSelectedValuesChanged;

  /// Whether to allow selecting multiple items.
  /// When true, [selectedValues] and [onSelectedValuesChanged] must be provided.
  final bool allowMultiple;

  /// Whether the select is enabled and can be interacted with.
  /// When false, all interaction is disabled and the trigger shows a forbidden cursor.
  final bool enabled;

  /// Semantic label for accessibility.
  /// Used by screen readers to identify the select component.
  final String? semanticLabel;

  /// Whether to automatically close the dropdown when an item is selected.
  /// Set to false to keep the menu open after selection, useful for multiple selection.
  final bool closeOnSelect;

  /// Whether to automatically focus the menu when opened.
  /// When true, enables immediate keyboard navigation.
  final bool autofocus;

  /// Whether to enable type-ahead selection for quick keyboard navigation.
  /// When true, typing characters will focus matching items.
  final bool enableTypeAhead;

  /// Duration before resetting the type-ahead search buffer.
  /// Controls how long to wait between keystrokes when matching items.
  final Duration typeAheadDebounceTime;

  /// The alignment of the menu relative to its trigger.
  /// Specifies how to position the menu when it opens.
  final NakedMenuPosition menuPosition;

  /// Alternative alignments to try if the menu doesn't fit in the preferred position.
  /// The menu will try each alignment in order until finding one that fits.
  final List<NakedMenuPosition> fallbackPositions;

  /// Called when the menu is opened.
  final VoidCallback? onOpen;

  /// Whether to close the menu when clicking outside.
  final bool closeOnClickOutside;

  /// The duration to wait before removing the Widget from the Overlay after the menu is closed.
  @override
  final Duration removalDelay;

  /// The event handler for the menu.
  @override
  final void Function(OverlayChildLifecycleState state)? onStateChange;

  @override
  State<NakedSelect<T>> createState() => _NakedSelectState<T>();
}

class _NakedSelectState<T> extends State<NakedSelect<T>>
    with MenuAnchorChildLifecycleMixin {
  late final _isMultipleSelection =
      widget.allowMultiple && widget.selectedValues != null;
  final List<_SelectItemInfo<T>> _selectableItems = [];

  bool get _isOpen => controller.isOpen;
  // For type-ahead functionality
  String _typeAheadBuffer = '';
  Timer? _typeAheadResetTimer;

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

    // Find the first matching item
    for (final item in _selectableItems) {
      final stringValue = item.value.toString().toLowerCase();
      if (stringValue.startsWith(_typeAheadBuffer)) {
        // Focus this item
        if (item.focusNode.canRequestFocus) {
          item.focusNode.requestFocus();
        }
        break;
      }
    }

    // Reset the buffer after a delay
    _typeAheadResetTimer = Timer(
      widget.typeAheadDebounceTime,
      _resetTypeAheadBuffer,
    );
  }

  void _registerSelectableItem(T value, FocusNode focusNode) {
    final itemExists = _selectableItems.any((item) => item.value == value);
    if (!itemExists) {
      _selectableItems.add(_SelectItemInfo(value: value, focusNode: focusNode));
    }
  }

  void _selectValue(T value) {
    if (!widget.enabled) return;

    if (_isMultipleSelection) {
      final newValues = Set<T>.of(widget.selectedValues!);
      newValues.contains(value)
          ? newValues.remove(value)
          : newValues.add(value);

      widget.onSelectedValuesChanged?.call(newValues);
    } else {
      widget.onSelectedValueChanged?.call(value);
    }

    if (widget.closeOnSelect) {
      closeMenu();
    }
  }

  @override
  void dispose() {
    _typeAheadResetTimer?.cancel();
    _typeAheadResetTimer = null;
    super.dispose();
  }

  void toggleMenu() {
    if (_isOpen) {
      closeMenu();
    } else {
      openMenu();
    }
  }

  void openMenu() {
    widget.onOpen?.call();
    showNotifier.value = true;
  }

  void closeMenu() {
    widget.onClose?.call();
    _selectableItems.clear();
    showNotifier.value = false;
  }

  bool get isOpen => _isOpen;
  bool get isEnabled => widget.enabled;

  @override
  Widget build(BuildContext context) {
    return NakedSelectInherited<T>(
      selectedValue: widget.selectedValue,
      selectedValues: widget.selectedValues,
      allowMultiple: widget.allowMultiple,
      enabled: widget.enabled,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: widget.semanticLabel,
        child: NakedMenuAnchor(
          controller: controller,
          overlayBuilder: (_) => widget.menu,
          consumeOutsideTaps: widget.closeOnClickOutside,
          position: widget.menuPosition,
          fallbackPositions: widget.fallbackPositions,
          onClose: closeMenu,
          onOpen: openMenu,
          onKeyEvent: (event) {
            // Type-ahead with character keys
            final character = event.character;

            if (character != null &&
                character.isNotEmpty &&
                widget.enableTypeAhead) {
              _handleTypeAhead(character);
            }
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// An InheritedWidget that provides access to the selected values in a NakedSelect.
///
/// This allows descendant widgets to efficiently access the current selection state
/// without passing it explicitly through the widget tree.
class NakedSelectInherited<T> extends InheritedWidget {
  const NakedSelectInherited({
    super.key,
    required super.child,
    required this.selectedValue,
    required this.selectedValues,
    required this.allowMultiple,
    required this.enabled,
  });

  /// Gets the nearest NakedSelectInherited ancestor of the given context.
  static NakedSelectInherited<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  static NakedSelectInherited<T> of<T>(BuildContext context) {
    final inherited = maybeOf<T>(context);
    if (inherited == null) {
      throw StateError(
        'NakedSelectInherited<$T> not found in context.\n'
        'Make sure NakedSelectInherited is an ancestor of the current widget.',
      );
    }

    return inherited;
  }

  /// The currently selected value for single selection mode.
  final T? selectedValue;

  /// The currently selected values for multiple selection mode.
  final Set<T>? selectedValues;

  /// Whether multiple selection is enabled.
  final bool allowMultiple;

  /// Whether the select is enabled and can be interacted with.
  final bool enabled;

  bool isSelected(BuildContext context, T value) {
    final inheritedValues = NakedSelectInherited.of<T>(context);

    if (inheritedValues.allowMultiple) {
      return inheritedValues.selectedValues?.contains(value) ?? false;
    }

    return inheritedValues.selectedValue == value;
  }

  @override
  bool updateShouldNotify(NakedSelectInherited<T> oldWidget) {
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

/// A customizable trigger button that controls the select dropdown.
///
/// The trigger handles user interaction through mouse, keyboard, and touch events,
/// providing callbacks for hover, press, and focus states to enable complete styling control.
///
/// Key features:
/// - Customizable cursor and interaction states
/// - Keyboard navigation support (Space, Enter, Arrow keys)
/// - Optional haptic feedback
/// - Accessibility support with ARIA attributes
///
/// Example:
/// ```dart
/// NakedSelectTrigger(
///   onHoverState: (isHovered) => setState(() => _isHovered = isHovered),
///   onPressedState: (isPressed) => setState(() => _isPressed = isPressed),
///   child: Container(
///     color: _isHovered ? Colors.blue[100] : Colors.white,
///     child: Text('Select an option'),
///   ),
/// )
/// ```
class NakedSelectTrigger extends StatelessWidget {
  const NakedSelectTrigger({
    super.key,
    required this.child,
    this.onHoverState,
    this.onPressedState,
    this.onFocusState,
    this.semanticLabel,
    this.cursor = SystemMouseCursors.click,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// The child widget to display.
  /// This widget will be wrapped with interaction handlers.
  final Widget child;

  /// Called when the hover state changes.
  /// Use this to update the visual appearance on hover.
  final ValueChanged<bool>? onHoverState;

  /// Called when the pressed state changes.
  /// Use this to update the visual appearance while pressed.
  final ValueChanged<bool>? onPressedState;

  /// Called when the focus state changes.
  /// Use this to update the visual appearance when focused.
  final ValueChanged<bool>? onFocusState;

  /// Semantic label for accessibility.
  /// Used by screen readers to identify the trigger.
  final String? semanticLabel;

  /// The cursor to show when hovering over the trigger.
  /// Defaults to [SystemMouseCursors.click].
  final MouseCursor cursor;

  /// Whether to provide haptic feedback when tapped.
  /// Defaults to true.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  /// If not provided, a new focus node will be created.
  final FocusNode? focusNode;

  /// Whether to automatically focus the trigger when opened.
  /// When true, enables immediate keyboard navigation.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_NakedSelectState>();

    void handleTap() {
      if (state?.isEnabled == false) return;

      if (enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }

      state?.toggleMenu();
    }

    return NakedButton(
      onPressed: handleTap,
      onHoverState: onHoverState,
      onPressedState: onPressedState,
      onFocusState: onFocusState,
      enabled: state?.isEnabled ?? true,
      isSemanticButton: true,
      semanticLabel: semanticLabel,
      cursor: cursor,
      enableHapticFeedback: enableHapticFeedback,
      focusNode: focusNode,
      autofocus: autofocus,
      child: child,
    );
  }
}

/// A selectable item within the dropdown menu.
///
/// This component handles the interaction and selection state for individual menu items,
/// providing callbacks for hover, press, focus and selection states to enable complete styling control.
///
/// Key features:
/// - Customizable cursor and interaction states
/// - Keyboard selection support
/// - Optional haptic feedback
/// - Accessibility support with ARIA attributes
/// - Selection state tracking
///
/// Example:
/// ```dart
/// NakedSelectItem<int>(
///   value: 1,
///   onHoverState: (isHovered) => setState(() => _isHovered = isHovered),
///   onSelectState: (isSelected) => setState(() => _isSelected = isSelected),
///   child: Container(
///     color: _isSelected ? Colors.blue : (_isHovered ? Colors.blue[100] : Colors.white),
///     child: Text('Option 1'),
///   ),
/// )
/// ```
class NakedSelectItem<T> extends StatefulWidget {
  const NakedSelectItem({
    super.key,
    required this.child,
    required this.value,
    this.onHoverState,
    this.onPressedState,
    this.onFocusState,
    this.onSelectState,
    this.enabled = true,
    this.semanticLabel,
    this.cursor = SystemMouseCursors.click,
    this.enableHapticFeedback = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// The child widget to display.
  /// This widget will be wrapped with interaction handlers.
  final Widget child;

  /// The value associated with this item.
  /// This value will be passed to the select's onChange callback when selected.
  final T value;

  /// Called when the hover state changes.
  /// Use this to update the visual appearance on hover.
  final ValueChanged<bool>? onHoverState;

  /// Called when the pressed state changes.
  /// Use this to update the visual appearance while pressed.
  final ValueChanged<bool>? onPressedState;

  /// Called when the focus state changes.
  /// Use this to update the visual appearance when focused.
  final ValueChanged<bool>? onFocusState;

  /// Called when the select state changes.
  /// Use this to update the visual appearance when selected.
  final ValueChanged<bool>? onSelectState;

  /// Whether this item is enabled and can be selected.
  /// When false, all interaction is disabled.
  final bool enabled;

  /// Semantic label for accessibility.
  /// Used by screen readers to identify the item.
  final String? semanticLabel;

  /// The cursor to show when hovering over this item.
  /// Defaults to [SystemMouseCursors.click].
  final MouseCursor cursor;

  /// Whether to provide haptic feedback when selected.
  /// Defaults to true.
  final bool enableHapticFeedback;

  /// Optional focus node to control focus behavior.
  /// If not provided, a new focus node will be created.
  final FocusNode? focusNode;

  final bool autofocus;

  @override
  State<NakedSelectItem<T>> createState() => _NakedSelectItemState<T>();
}

class _NakedSelectItemState<T> extends State<NakedSelectItem<T>> {
  late FocusNode _focusNode;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerWithSelect();
    });
  }

  void _registerWithSelect() {
    if (_isRegistered) return;

    final state = context.findAncestorStateOfType<_NakedSelectState<T>>();
    if (state != null) {
      state._registerSelectableItem(widget.value, _focusNode);
      _isRegistered = true;
    }
  }

  @override
  void didUpdateWidget(NakedSelectItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }

    if (widget.value != oldWidget.value) {
      _registerWithSelect();
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
    final state = context.findAncestorStateOfType<_NakedSelectState<T>>();
    final isSelectEnabled = state?.isEnabled ?? true;

    final isEffectivelyEnabled = widget.enabled && isSelectEnabled;

    void handleSelect() {
      if (!isEffectivelyEnabled) return;

      if (widget.enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }

      state?._selectValue(widget.value);
    }

    final inherited = NakedSelectInherited.of<T>(context);
    final isSelected = inherited.isSelected(context, widget.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelectState?.call(isSelected);
    });

    return Semantics(
      excludeSemantics: true,
      enabled: isEffectivelyEnabled,
      selected: isSelected,
      child: NakedButton(
        onPressed: handleSelect,
        onHoverState: widget.onHoverState,
        onPressedState: widget.onPressedState,
        onFocusState: widget.onFocusState,
        enabled: isEffectivelyEnabled,
        isSemanticButton: true,
        semanticLabel: widget.semanticLabel ?? widget.value.toString(),
        cursor: widget.cursor,
        enableHapticFeedback: widget.enableHapticFeedback,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        child: widget.child,
      ),
    );
  }
}
