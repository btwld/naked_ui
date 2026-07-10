import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Internal cross-library namespace for Naked UI shortcut and action maps.
///
/// The class is public only because Dart library privacy is file-scoped. It is
/// not exported from `package:naked_ui/naked_ui.dart`.
class NakedIntentActions {
  NakedIntentActions._();

  /// Shortcuts shared by button-like controls.
  static Map<ShortcutActivator, Intent> get buttonShortcuts => _buttonShortcuts;

  /// Creates actions for a button-like activation.
  static Map<Type, Action<Intent>> buttonActions({
    required VoidCallback onPressed,
  }) => _activation(onPressed, includeButtonIntent: true);

  /// Creates actions for checkbox activation.
  static Map<Type, Action<Intent>> checkboxActions({
    required VoidCallback onToggle,
  }) => _activation(onToggle, includeButtonIntent: true);

  /// Creates actions for toggle activation.
  static Map<Type, Action<Intent>> toggleActions({
    required VoidCallback onToggle,
  }) => _activation(onToggle, includeButtonIntent: true);

  /// Creates actions for accordion disclosure activation.
  static Map<Type, Action<Intent>> accordionActions({
    required VoidCallback onToggle,
  }) => _activation(onToggle, includeButtonIntent: true);

  /// Shortcuts for tab activation and navigation.
  static Map<ShortcutActivator, Intent> get tabShortcuts => _tabShortcuts;

  /// Creates actions for tab activation and navigation.
  static Map<Type, Action<Intent>> tabActions({
    required VoidCallback onActivate,
    required ValueChanged<TraversalDirection> onDirectionalFocus,
    VoidCallback? onFirstFocus,
    VoidCallback? onLastFocus,
  }) {
    final map = _activation(onActivate, includeButtonIntent: true);
    map[DirectionalFocusIntent] = CallbackAction<DirectionalFocusIntent>(
      onInvoke: (intent) => onDirectionalFocus(intent.direction),
    );

    if (onFirstFocus != null) {
      map[_FirstFocusIntent] = CallbackAction<_FirstFocusIntent>(
        onInvoke: (_) => onFirstFocus(),
      );
    }

    if (onLastFocus != null) {
      map[_LastFocusIntent] = CallbackAction<_LastFocusIntent>(
        onInvoke: (_) => onLastFocus(),
      );
    }

    return map;
  }

  /// Shortcuts for menu and overlay navigation.
  static Map<ShortcutActivator, Intent> get menuShortcuts => _menuShortcuts;

  /// Creates actions for menu and overlay navigation.
  static Map<Type, Action<Intent>> menuActions({
    required VoidCallback onDismiss,
    VoidCallback? onNextFocus,
    VoidCallback? onPreviousFocus,
    VoidCallback? onFirstFocus,
    VoidCallback? onLastFocus,
  }) {
    final map = <Type, Action<Intent>>{
      DismissIntent: CallbackAction<DismissIntent>(
        onInvoke: (_) => onDismiss(),
      ),
    };

    if (onNextFocus != null) {
      map[NextFocusIntent] = CallbackAction<NextFocusIntent>(
        onInvoke: (_) => onNextFocus(),
      );
    }

    if (onPreviousFocus != null) {
      map[PreviousFocusIntent] = CallbackAction<PreviousFocusIntent>(
        onInvoke: (_) => onPreviousFocus(),
      );
    }

    if (onFirstFocus != null) {
      map[_FirstFocusIntent] = CallbackAction<_FirstFocusIntent>(
        onInvoke: (_) => onFirstFocus(),
      );
    }

    if (onLastFocus != null) {
      map[_LastFocusIntent] = CallbackAction<_LastFocusIntent>(
        onInvoke: (_) => onLastFocus(),
      );
    }

    return map;
  }

  /// Shortcuts for select and combobox navigation.
  static Map<ShortcutActivator, Intent> get selectShortcuts => _selectShortcuts;

  /// Creates actions for select and combobox navigation.
  static Map<Type, Action<Intent>> selectActions({
    required VoidCallback onDismiss,
    VoidCallback? onOpenOverlay,
    VoidCallback? onPageUp,
    VoidCallback? onPageDown,
  }) {
    final map = <Type, Action<Intent>>{
      DismissIntent: CallbackAction<DismissIntent>(
        onInvoke: (_) => onDismiss(),
      ),
    };

    if (onOpenOverlay != null) {
      map[_OpenOverlayIntent] = CallbackAction<_OpenOverlayIntent>(
        onInvoke: (_) => onOpenOverlay(),
      );
    }

    if (onPageUp != null) {
      map[_PageUpIntent] = CallbackAction<_PageUpIntent>(
        onInvoke: (_) => onPageUp(),
      );
    }

    if (onPageDown != null) {
      map[_PageDownIntent] = CallbackAction<_PageDownIntent>(
        onInvoke: (_) => onPageDown(),
      );
    }

    return map;
  }

  /// Returns direction-aware slider shortcuts.
  static Map<ShortcutActivator, Intent> sliderShortcuts({
    required bool isRTL,
  }) => isRTL ? _sliderShortcutsRtl : _sliderShortcutsLtr;

  /// Creates actions for slider adjustment and bounds.
  static Map<Type, Action<Intent>> sliderActions({
    required ValueChanged<double> onChanged,
    required double Function(bool isShift) calculateStep,
    required double Function(double value) normalizeValue,
    required double currentValue,
    required double minValue,
    required double maxValue,
    required bool enableFeedback,
  }) {
    return {
      _SliderIncrementIntent: _SliderAdjustAction<_SliderIncrementIntent>(
        onChanged: onChanged,
        calculateStep: calculateStep,
        normalizeValue: normalizeValue,
        getCurrentValue: () => currentValue,
        enableFeedback: enableFeedback,
        stepMultiplier: 1,
      ),
      _SliderDecrementIntent: _SliderAdjustAction<_SliderDecrementIntent>(
        onChanged: onChanged,
        calculateStep: calculateStep,
        normalizeValue: normalizeValue,
        getCurrentValue: () => currentValue,
        enableFeedback: enableFeedback,
        stepMultiplier: -1,
      ),
      _SliderShiftIncrementIntent:
          _SliderAdjustAction<_SliderShiftIncrementIntent>(
            onChanged: onChanged,
            calculateStep: calculateStep,
            normalizeValue: normalizeValue,
            getCurrentValue: () => currentValue,
            enableFeedback: enableFeedback,
            stepMultiplier: 1,
            isShiftPressed: true,
          ),
      _SliderShiftDecrementIntent:
          _SliderAdjustAction<_SliderShiftDecrementIntent>(
            onChanged: onChanged,
            calculateStep: calculateStep,
            normalizeValue: normalizeValue,
            getCurrentValue: () => currentValue,
            enableFeedback: enableFeedback,
            stepMultiplier: -1,
            isShiftPressed: true,
          ),
      _SliderSetToMinIntent: _SliderSetBoundAction<_SliderSetToMinIntent>(
        onChanged: onChanged,
        getTargetValue: () => minValue,
        getCurrentValue: () => currentValue,
        enableFeedback: enableFeedback,
      ),
      _SliderSetToMaxIntent: _SliderSetBoundAction<_SliderSetToMaxIntent>(
        onChanged: onChanged,
        getTargetValue: () => maxValue,
        getCurrentValue: () => currentValue,
        enableFeedback: enableFeedback,
      ),
    };
  }
}

// Shared shortcut definitions and helper functions

const Map<ShortcutActivator, Intent> _buttonShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.numpadEnter): ButtonActivateIntent(),
    };

const Map<ShortcutActivator, Intent> _tabShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.numpadEnter): ButtonActivateIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(
        TraversalDirection.left,
      ),
      SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(
        TraversalDirection.right,
      ),
      SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
        TraversalDirection.up,
      ),
      SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
        TraversalDirection.down,
      ),
      SingleActivator(LogicalKeyboardKey.home): _FirstFocusIntent(),
      SingleActivator(LogicalKeyboardKey.end): _LastFocusIntent(),
    };

const Map<ShortcutActivator, Intent> _menuShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
      SingleActivator(LogicalKeyboardKey.home): _FirstFocusIntent(),
      SingleActivator(LogicalKeyboardKey.end): _LastFocusIntent(),
    };

const Map<ShortcutActivator, Intent> _selectShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
      SingleActivator(LogicalKeyboardKey.home): _FirstFocusIntent(),
      SingleActivator(LogicalKeyboardKey.end): _LastFocusIntent(),
      SingleActivator(LogicalKeyboardKey.pageUp): _PageUpIntent(),
      SingleActivator(LogicalKeyboardKey.pageDown): _PageDownIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
          _OpenOverlayIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): DismissIntent(),
    };

const Map<ShortcutActivator, Intent> _sliderShortcutsLtr =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.arrowRight): _SliderIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft): _SliderDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
          _SliderShiftDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
          _SliderShiftIncrementIntent(),

      SingleActivator(LogicalKeyboardKey.arrowUp): _SliderIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
          _SliderShiftIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): _SliderDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
          _SliderShiftDecrementIntent(),

      SingleActivator(LogicalKeyboardKey.home): _SliderSetToMinIntent(),
      SingleActivator(LogicalKeyboardKey.end): _SliderSetToMaxIntent(),

      SingleActivator(LogicalKeyboardKey.pageUp): _SliderShiftIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.pageDown):
          _SliderShiftDecrementIntent(),
    };

const Map<ShortcutActivator, Intent> _sliderShortcutsRtl =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.arrowLeft): _SliderIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowRight): _SliderDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
          _SliderShiftDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
          _SliderShiftIncrementIntent(),

      SingleActivator(LogicalKeyboardKey.arrowUp): _SliderIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
          _SliderShiftIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): _SliderDecrementIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
          _SliderShiftDecrementIntent(),

      SingleActivator(LogicalKeyboardKey.home): _SliderSetToMinIntent(),
      SingleActivator(LogicalKeyboardKey.end): _SliderSetToMaxIntent(),

      SingleActivator(LogicalKeyboardKey.pageUp): _SliderShiftIncrementIntent(),
      SingleActivator(LogicalKeyboardKey.pageDown):
          _SliderShiftDecrementIntent(),
    };

Map<Type, Action<Intent>> _activation(
  VoidCallback handler, {
  bool includeButtonIntent = false,
}) {
  final map = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => handler()),
  };

  if (includeButtonIntent) {
    map[ButtonActivateIntent] = CallbackAction<ButtonActivateIntent>(
      onInvoke: (_) => handler(),
    );
  }

  return map;
}

// Custom intent definitions for keyboard navigation and slider actions

/// Intent: Move focus to first item in a collection.
class _FirstFocusIntent extends Intent {
  const _FirstFocusIntent();
}

/// Intent: Move focus to last item in a collection.
class _LastFocusIntent extends Intent {
  const _LastFocusIntent();
}

/// Intent: Move focus by page up (large jump backward).
class _PageUpIntent extends Intent {
  const _PageUpIntent();
}

/// Intent: Move focus by page down (large jump forward).
class _PageDownIntent extends Intent {
  const _PageDownIntent();
}

/// Intent: Open overlay/dropdown.
class _OpenOverlayIntent extends Intent {
  const _OpenOverlayIntent();
}

/// Intent: increment slider value by one step.
class _SliderIncrementIntent extends Intent {
  const _SliderIncrementIntent();
}

/// Intent: decrement slider value by one step.
class _SliderDecrementIntent extends Intent {
  const _SliderDecrementIntent();
}

/// Intent: increment slider value by a large step (Shift + Arrow).
class _SliderShiftIncrementIntent extends _SliderIncrementIntent {
  const _SliderShiftIncrementIntent();
}

/// Intent: decrement slider value by a large step (Shift + Arrow).
class _SliderShiftDecrementIntent extends _SliderDecrementIntent {
  const _SliderShiftDecrementIntent();
}

/// Intent: set slider value to minimum.
class _SliderSetToMinIntent extends Intent {
  const _SliderSetToMinIntent();
}

/// Intent: set slider value to maximum.
class _SliderSetToMaxIntent extends Intent {
  const _SliderSetToMaxIntent();
}

/// Action: handles keyboard increment/decrement intents.
/// Uses [stepMultiplier] to determine direction: 1 for increment, -1 for decrement.
class _SliderAdjustAction<T extends Intent> extends Action<T> {
  final ValueChanged<double> onChanged;
  final double Function(bool isShift) calculateStep;
  final double Function(double value) normalizeValue;
  final double Function() getCurrentValue;
  final bool enableFeedback;
  final bool isShiftPressed;
  final int stepMultiplier;

  _SliderAdjustAction({
    required this.onChanged,
    required this.calculateStep,
    required this.normalizeValue,
    required this.getCurrentValue,
    required this.enableFeedback,
    required this.stepMultiplier,
    this.isShiftPressed = false,
  });

  @override
  void invoke(T intent) {
    final step = calculateStep(isShiftPressed) * stepMultiplier;
    final currentValue = getCurrentValue();
    final newValue = normalizeValue(currentValue + step);
    if (enableFeedback && newValue != currentValue) {
      HapticFeedback.selectionClick();
    }
    onChanged(newValue);
  }
}

/// Action: handles keyboard set-to-min/max intents.
class _SliderSetBoundAction<T extends Intent> extends Action<T> {
  final ValueChanged<double> onChanged;
  final double Function() getTargetValue;
  final double Function() getCurrentValue;
  final bool enableFeedback;

  _SliderSetBoundAction({
    required this.onChanged,
    required this.getTargetValue,
    required this.getCurrentValue,
    required this.enableFeedback,
  });

  @override
  void invoke(T intent) {
    final targetValue = getTargetValue();
    final currentValue = getCurrentValue();
    if (enableFeedback && currentValue != targetValue) {
      HapticFeedback.selectionClick();
    }
    onChanged(targetValue);
  }
}
