import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

extension StateTestHelpers on WidgetTester {
  /// Helper to verify widget state extensions work correctly
  void expectWidgetStates(
    Set<WidgetState> actualStates, {
    bool expectHovered = false,
    bool expectFocused = false,
    bool expectPressed = false,
    bool expectDisabled = false,
    bool expectSelected = false,
  }) {
    expect(actualStates.isHovered, expectHovered, reason: 'Hover state mismatch');
    expect(actualStates.isFocused, expectFocused, reason: 'Focus state mismatch');
    expect(actualStates.isPressed, expectPressed, reason: 'Press state mismatch');
    expect(actualStates.isDisabled, expectDisabled, reason: 'Disabled state mismatch');
    expect(actualStates.isSelected, expectSelected, reason: 'Selected state mismatch');
  }
}