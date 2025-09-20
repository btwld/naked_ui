/// Material Widget Intents & Actions Reference
/// Complete list of ACTUAL Intent classes available in Flutter's public API
///
/// Note: Many intents are internal to Material widgets and not publicly exposed.
/// This reference includes only the Intent classes you can actually use.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// =============================================================================
// CORE ACTIVATION INTENTS (Available in Flutter)
// =============================================================================

class CoreIntents {
  // These are the primary intents available in Flutter's public API

  // Activation & Selection
  static const activateIntent = ActivateIntent();
  static const buttonActivateIntent = ButtonActivateIntent();
  static const selectIntent = SelectIntent();

  // Dismissal
  static const dismissIntent = DismissIntent();

  // Focus traversal
  static const nextFocusIntent = NextFocusIntent();
  static const previousFocusIntent = PreviousFocusIntent();

  // Directional focus (with required direction parameter)
  static const upIntent = DirectionalFocusIntent(TraversalDirection.up);
  static const downIntent = DirectionalFocusIntent(TraversalDirection.down);
  static const leftIntent = DirectionalFocusIntent(TraversalDirection.left);
  static const rightIntent = DirectionalFocusIntent(TraversalDirection.right);

  // Request focus (requires FocusNode parameter)
  // RequestFocusIntent requires a FocusNode, so it can't be const
  // Example: RequestFocusIntent(myFocusNode)

  // Scrolling intents
  static const scrollUpLine = ScrollIntent(
    direction: AxisDirection.up,
    type: ScrollIncrementType.line,
  );
  static const scrollDownLine = ScrollIntent(
    direction: AxisDirection.down,
    type: ScrollIncrementType.line,
  );
  static const scrollUpPage = ScrollIntent(
    direction: AxisDirection.up,
    type: ScrollIncrementType.page,
  );
  static const scrollDownPage = ScrollIntent(
    direction: AxisDirection.down,
    type: ScrollIncrementType.page,
  );

  // Document boundaries (available in newer Flutter versions)
  // Note: ScrollToDocumentBoundaryIntent may not be available in all Flutter versions
  // static const scrollToTop = ScrollToDocumentBoundaryIntent(forward: false);
  // static const scrollToBottom = ScrollToDocumentBoundaryIntent(forward: true);
}

// =============================================================================
// TEXT EDITING INTENTS (Available in Flutter)
// =============================================================================

class TextEditingIntents {
  // These text editing intents are available but require parameters

  // Selection (all require SelectionChangedCause parameter, can't be const)
  // SelectAllTextIntent(SelectionChangedCause cause)
  // CopySelectionTextIntent(SelectionChangedCause cause)
  // PasteTextIntent(SelectionChangedCause cause)

  // Deletion (require forward parameter)
  static const deleteForwardIntent = DeleteCharacterIntent(forward: true);
  static const deleteBackwardIntent = DeleteCharacterIntent(forward: false);

  // Word boundary deletion
  static const deleteWordForwardIntent = DeleteToNextWordBoundaryIntent(
    forward: true,
  );
  static const deleteWordBackwardIntent = DeleteToNextWordBoundaryIntent(
    forward: false,
  );

  // Line deletion
  static const deleteLineForwardIntent = DeleteToLineBreakIntent(forward: true);
  static const deleteLineBackwardIntent = DeleteToLineBreakIntent(
    forward: false,
  );

  // Undo/Redo (require SelectionChangedCause parameter, can't be const)
  // UndoTextIntent(SelectionChangedCause cause)
  // RedoTextIntent(SelectionChangedCause cause)

  // Selection extension (all require parameters)
  // ExtendSelectionByCharacterIntent(forward: bool, collapseSelection: bool)
  // ExtendSelectionToNextWordBoundaryIntent(forward: bool, collapseSelection: bool)
  // ExtendSelectionToLineBreakIntent(forward: bool, collapseSelection: bool, collapseAtReversal: bool)
  // ExtendSelectionVerticallyToAdjacentLineIntent(forward: bool, collapseSelection: bool)

  // Expand selection
  // ExpandSelectionToLineBreakIntent(forward: bool)

  // Transpose
  static const transposeIntent = TransposeCharactersIntent();

  // Update selection (requires complex parameters)
  // UpdateSelectionIntent(TextEditingValue currentTextEditingValue, TextSelection newSelection, SelectionChangedCause cause)
}

// =============================================================================
// WIDGET-SPECIFIC SHORTCUTS (How widgets typically use intents)
// =============================================================================

/// Button widget keyboard shortcuts
class ButtonShortcuts {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.numpadEnter):
        const ButtonActivateIntent(),
  };
}

/// Checkbox widget keyboard shortcuts
class CheckboxShortcuts {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
  };
}

/// Radio button keyboard shortcuts
class RadioShortcuts {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.enter): const SelectIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const DirectionalFocusIntent(TraversalDirection.up),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const DirectionalFocusIntent(TraversalDirection.down),
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const DirectionalFocusIntent(TraversalDirection.left),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const DirectionalFocusIntent(TraversalDirection.right),
  };
}

/// Switch widget keyboard shortcuts
class SwitchShortcuts {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
  };
}

/// Dropdown/Select keyboard shortcuts
class DropdownShortcuts {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const DirectionalFocusIntent(TraversalDirection.up),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const DirectionalFocusIntent(TraversalDirection.down),
  };
}

/// Dialog keyboard shortcuts
class DialogShortcuts {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
    const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.tab): const NextFocusIntent(),
    const SingleActivator(LogicalKeyboardKey.tab, shift: true):
        const PreviousFocusIntent(),
  };
}

/// Tab navigation keyboard shortcuts
class TabShortcuts {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const DirectionalFocusIntent(TraversalDirection.left),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const DirectionalFocusIntent(TraversalDirection.right),
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const DirectionalFocusIntent(TraversalDirection.up),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const DirectionalFocusIntent(TraversalDirection.down),
    const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
  };
}

/// Text field keyboard shortcuts (partial - many require parameters)
class TextFieldShortcuts {
  static Map<ShortcutActivator, Intent> getShortcuts() {
    return {
      // Simple deletion shortcuts
      const SingleActivator(LogicalKeyboardKey.delete):
          const DeleteCharacterIntent(forward: true),
      const SingleActivator(LogicalKeyboardKey.backspace):
          const DeleteCharacterIntent(forward: false),
      const SingleActivator(LogicalKeyboardKey.delete, control: true):
          const DeleteToNextWordBoundaryIntent(forward: true),
      const SingleActivator(LogicalKeyboardKey.backspace, control: true):
          const DeleteToNextWordBoundaryIntent(forward: false),

      // Transpose
      const SingleActivator(LogicalKeyboardKey.keyT, control: true):
          const TransposeCharactersIntent(),

      // Note: Most text editing intents require runtime parameters and can't be const
      // They're typically created dynamically in EditableText's action handlers
    };
  }

  // Example of how to create text editing intents with parameters:
  static Intent createSelectAllIntent() =>
      const SelectAllTextIntent(SelectionChangedCause.keyboard);

  static Intent createCopyIntent() => CopySelectionTextIntent.copy;

  static Intent createPasteIntent() =>
      const PasteTextIntent(SelectionChangedCause.keyboard);

  static Intent createUndoIntent() =>
      const UndoTextIntent(SelectionChangedCause.keyboard);

  static Intent createRedoIntent() =>
      const RedoTextIntent(SelectionChangedCause.keyboard);
}

// =============================================================================
// SLIDER KEYBOARD BEHAVIOR (Using DirectionalFocusIntent)
// =============================================================================

/// Slider uses DirectionalFocusIntent for arrow key handling
class SliderShortcuts {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const DirectionalFocusIntent(TraversalDirection.up),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const DirectionalFocusIntent(TraversalDirection.down),
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const DirectionalFocusIntent(TraversalDirection.left),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const DirectionalFocusIntent(TraversalDirection.right),
    // Page up/down typically handled via ScrollIntent
    const SingleActivator(LogicalKeyboardKey.pageUp): const ScrollIntent(
      direction: AxisDirection.up,
      type: ScrollIncrementType.page,
    ),
    const SingleActivator(LogicalKeyboardKey.pageDown): const ScrollIntent(
      direction: AxisDirection.down,
      type: ScrollIncrementType.page,
    ),
  };
}

// =============================================================================
// GLOBAL NAVIGATION SHORTCUTS
// =============================================================================

class GlobalNavigationShortcuts {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    const SingleActivator(LogicalKeyboardKey.tab): const NextFocusIntent(),
    const SingleActivator(LogicalKeyboardKey.tab, shift: true):
        const PreviousFocusIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const DirectionalFocusIntent(TraversalDirection.up),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const DirectionalFocusIntent(TraversalDirection.down),
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const DirectionalFocusIntent(TraversalDirection.left),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const DirectionalFocusIntent(TraversalDirection.right),
  };
}
