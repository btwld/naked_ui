import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

extension StateTestHelpers on WidgetTester {
  /// Helper to verify widget state extensions work correctly
  void expectWidgetStates(
    Set<WidgetState> actualStates, {
    bool? expectHovered,
    bool? expectFocused,
    bool? expectPressed,
    bool? expectDisabled,
    bool? expectSelected,
  }) {
    if (expectHovered != null) {
      expect(actualStates.isHovered, expectHovered,
          reason: 'Hover state mismatch');
    }
    if (expectFocused != null) {
      expect(actualStates.isFocused, expectFocused,
          reason: 'Focus state mismatch');
    }
    if (expectPressed != null) {
      expect(actualStates.isPressed, expectPressed,
          reason: 'Press state mismatch');
    }
    if (expectDisabled != null) {
      expect(actualStates.isDisabled, expectDisabled,
          reason: 'Disabled state mismatch');
    }
    if (expectSelected != null) {
      expect(actualStates.isSelected, expectSelected,
          reason: 'Selected state mismatch');
    }
  }
}
