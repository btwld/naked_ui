import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Utilities that respect platform differences and `EditableText` internals.
/// NOTE:
/// - Keyboard shortcut helpers are reliable in widget tests, not integration tests.
/// - Prefer Actions/Intents for text editing commands when possible.
extension TextFieldTestHelpers on WidgetTester {
  /// Focus then enter text. Works in widget + integration tests.
  Future<void> typeText(Finder field, String text) async {
    await tap(field);
    await pump();
    // Prefer targeting the inner EditableText to avoid ambiguity.
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    await enterText(editable.evaluate().isNotEmpty ? editable : field, text);
    await pump();
  }

  /// Expect the current text value, using external controller if present,
  /// else falling back to the inner EditableText controller.
  void expectTextValue(Finder field, String expected) {
    // Try to read a Naked-style public controller if this is used with such a widget.
    // Otherwise, read EditableText controller directly.
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    final editableWidget = widget<EditableText>(editable);
    expect(editableWidget.controller.text, expected);
  }

  /// Send a chord like Cmd/Ctrl + Key (widget tests only).
  Future<void> sendShortcut(
    LogicalKeyboardKey modifier,
    LogicalKeyboardKey key,
  ) async {
    await sendKeyDownEvent(modifier);
    await sendKeyEvent(key);
    await sendKeyUpEvent(modifier);
    await pump();
  }

  /// Clear text with a robust strategy:
  /// - In widget tests: use Actions/Intents (SelectAll + Backspace).
  /// - Fallback (and for integration tests): focus and enter empty string.
  Future<void> clearText(Finder field) async {
    await tap(field);
    await pump();

    // Try Actions-based clear (widget tests).
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    if (editable.evaluate().isNotEmpty) {
      final ctx = element(editable);
      // SelectAll via Intent is stable across platforms.
      final didSelectAll = Actions.maybeInvoke(
        ctx,
        const SelectAllTextIntent(SelectionChangedCause.keyboard),
      );
      await pump();

      if (didSelectAll == true) {
        // Backspace deletes the selection.
        await sendKeyEvent(LogicalKeyboardKey.backspace);
        await pump();
        return;
      }
    }

    // Fallback: direct text set (works in integration tests).
    await enterText(editable.evaluate().isNotEmpty ? editable : field, '');
    await pump();
  }

  /// Desktop-style text selection: click-drag with a mouse pointer.
  Future<void> selectWithMouseDrag(
    Finder field, {
    Offset delta = const Offset(120, 0),
  }) async {
    final target = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    final start = getCenter(target.evaluate().isNotEmpty ? target : field);

    final g = await startGesture(
      start,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await g.moveBy(delta);
    await g.up();
    await pump();
  }

  /// Ensure the field is focused (and IME attached for widget tests).
  Future<void> ensureFocused(Finder field) async {
    await tap(field);
    await pump();
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    if (editable.evaluate().isNotEmpty) {
      await showKeyboard(editable);
      await pump();
    }
  }

  /// Create a separate undo step by waiting beyond the coalescing window.
  Future<void> waitForNewUndoGroup() => pump(const Duration(milliseconds: 700));

  /// Trigger framework-level Undo/Redo via Intents (preferred over controller calls).
  Future<void> undoViaIntent(Finder field) async {
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    final ctx = element(editable);
    Actions.maybeInvoke(
      ctx,
      const UndoTextIntent(SelectionChangedCause.keyboard),
    );
    await pump();
  }

  Future<void> redoViaIntent(Finder field) async {
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    final ctx = element(editable);
    Actions.maybeInvoke(
      ctx,
      const RedoTextIntent(SelectionChangedCause.keyboard),
    );
    await pump();
  }
}
