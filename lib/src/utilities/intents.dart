import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Central namespace for Naked UI intent helpers. Access widget-specific helpers
/// via namespaces such as `NakedIntentActions.button.shortcuts` and
/// `NakedIntentActions.button.actions(...)`. Each helper returns the concrete
/// types expected for that widget to keep usage strongly typed and predictable.
///
/// This class is not intended to be instantiated or extended; use the static
/// members to access the helpers.
class NakedIntentActions {
  static const _ButtonIntentActions button = _ButtonIntentActions();
  static const _CheckboxIntentActions checkbox = _CheckboxIntentActions();
  static const _ToggleIntentActions toggle = _ToggleIntentActions();
  static const _AccordionIntentActions accordion = _AccordionIntentActions();
  static const _TabIntentActions tab = _TabIntentActions();
  static const _MenuIntentActions menu = _MenuIntentActions();
  static const _SelectIntentActions select = _SelectIntentActions();
  static const _DialogIntentActions dialog = _DialogIntentActions();
}

// =============================================================================
// BUTTON / ACTIVATION-LIKE WIDGETS
// =============================================================================

class _ButtonIntentActions {
  const _ButtonIntentActions();

  Map<ShortcutActivator, Intent> get shortcuts => _buttonShortcuts;

  Map<Type, Action<Intent>> actions({required VoidCallback onPressed}) =>
      _activation(onPressed, includeButtonIntent: true);
}

class _CheckboxIntentActions {
  const _CheckboxIntentActions();

  Map<ShortcutActivator, Intent> get shortcuts => _buttonShortcuts;

  Map<Type, Action<Intent>> actions({required VoidCallback onToggle}) =>
      _activation(onToggle, includeButtonIntent: true);
}

class _ToggleIntentActions {
  const _ToggleIntentActions();

  Map<ShortcutActivator, Intent> get shortcuts => _buttonShortcuts;

  Map<Type, Action<Intent>> actions({required VoidCallback onToggle}) =>
      _activation(onToggle, includeButtonIntent: true);
}

class _AccordionIntentActions {
  const _AccordionIntentActions();

  Map<ShortcutActivator, Intent> get shortcuts => _buttonShortcuts;

  Map<Type, Action<Intent>> actions({required VoidCallback onToggle}) =>
      _activation(onToggle, includeButtonIntent: true);
}

// =============================================================================
// TAB
// =============================================================================

class _TabIntentActions {
  const _TabIntentActions();

  Map<ShortcutActivator, Intent> get shortcuts => _tabShortcuts;

  Map<Type, Action<Intent>> actions({
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
}

// =============================================================================
// MENU / OVERLAY COLLECTIONS
// =============================================================================

class _MenuIntentActions {
  const _MenuIntentActions();

  Map<ShortcutActivator, Intent> get shortcuts => _menuShortcuts;

  Map<Type, Action<Intent>> actions({
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
}

// =============================================================================
// SELECT / COMBOBOX
// =============================================================================

class _SelectIntentActions {
  const _SelectIntentActions();

  Map<ShortcutActivator, Intent> get shortcuts => _selectShortcuts;

  Map<Type, Action<Intent>> actions({
    required VoidCallback onDismiss,
    VoidCallback? onOpenOverlay,
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

    return map;
  }
}

// =============================================================================
// DIALOG
// =============================================================================

class _DialogIntentActions {
  const _DialogIntentActions();

  Map<ShortcutActivator, Intent> get shortcuts => _dialogShortcuts;

  Map<Type, Action<Intent>> actions({required VoidCallback onDismiss}) => {
    DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => onDismiss()),
  };
}

// =============================================================================
// SHARED IMPLEMENTATION DETAILS
// =============================================================================

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
      SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): _OpenOverlayIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): DismissIntent(),
    };

const Map<ShortcutActivator, Intent> _dialogShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
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

// =============================================================================
// CUSTOM INTENTS FOR NAVIGATION
// =============================================================================

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
