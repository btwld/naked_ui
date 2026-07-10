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
}
