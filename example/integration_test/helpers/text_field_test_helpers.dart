import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

extension TextFieldTestHelpers on WidgetTester {
  /// Type text with realistic interaction pattern
  Future<void> typeText(Finder finder, String text) async {
    // Focus first by tapping
    await tap(finder);
    await pump();
    
    // Enter text
    await enterText(finder, text);
    await pump();
  }

  /// Verify text field value
  void expectTextValue(Finder finder, String expected) {
    final field = widget<NakedTextField>(finder);
    final controller = field.controller;
    if (controller != null) {
      expect(controller.text, expected);
    } else {
      // For fields without controller, check the EditableText
      final editableText = find.descendant(
        of: finder,
        matching: find.byType(EditableText),
      );
      final editableWidget = widget<EditableText>(editableText);
      expect(editableWidget.controller.text, expected);
    }
  }

  /// Simulate keyboard shortcut (Ctrl+Key or Cmd+Key)
  Future<void> sendShortcut(
    LogicalKeyboardKey modifier,
    LogicalKeyboardKey key,
  ) async {
    await sendKeyDownEvent(modifier);
    await sendKeyEvent(key);
    await sendKeyUpEvent(modifier);
    await pump();
  }

  /// Clear text field content
  Future<void> clearText(Finder finder) async {
    await tap(finder);
    await pump();
    
    // Select all and delete
    await sendShortcut(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyA);
    await sendKeyEvent(LogicalKeyboardKey.delete);
    await pump();
  }
}