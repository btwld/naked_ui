import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension StateTestHelpers on WidgetTester {
  /// Helper to verify widget interaction states for Set<WidgetState> snapshots.
  void expectWidgetStates(
    Set<WidgetState> actualStates, {
    bool? expectHovered,
    bool? expectFocused,
    bool? expectPressed,
    bool? expectDisabled,
    bool? expectSelected,
  }) {
    if (expectHovered != null) {
      expect(
        actualStates.contains(WidgetState.hovered),
        expectHovered,
        reason: 'Hover state mismatch',
      );
    }
    if (expectFocused != null) {
      expect(
        actualStates.contains(WidgetState.focused),
        expectFocused,
        reason: 'Focus state mismatch',
      );
    }
    if (expectPressed != null) {
      expect(
        actualStates.contains(WidgetState.pressed),
        expectPressed,
        reason: 'Press state mismatch',
      );
    }
    if (expectDisabled != null) {
      expect(
        actualStates.contains(WidgetState.disabled),
        expectDisabled,
        reason: 'Disabled state mismatch',
      );
    }
    if (expectSelected != null) {
      expect(
        actualStates.contains(WidgetState.selected),
        expectSelected,
        reason: 'Selected state mismatch',
      );
    }
  }
}
