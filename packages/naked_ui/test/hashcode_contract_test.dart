// ignore_for_file: prefer_const_constructors

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

/// Verification test to ensure hashCode/equals contract is honored.
///
/// The contract states: if a == b, then a.hashCode == b.hashCode
///
/// This test verifies that state objects with the same content (but
/// potentially different Set instances/ordering) have matching hashCodes.
void main() {
  group('hashCode/equals contract verification', () {
    test('NakedButtonState honors contract', () {
      // Create two sets with same content but different insertion order
      final states1 = {WidgetState.hovered, WidgetState.focused};
      final states2 = {WidgetState.focused, WidgetState.hovered};

      final state1 = NakedButtonState(states: states1);
      final state2 = NakedButtonState(states: states2);

      // These should be equal (setEquals compares content)
      expect(
        state1 == state2,
        isTrue,
        reason: 'States with same content should be equal',
      );

      // If equal, hashCodes MUST be equal (the contract)
      expect(
        state1.hashCode == state2.hashCode,
        isTrue,
        reason: 'Equal states must have equal hashCodes',
      );
    });

    test('NakedPopoverState honors contract', () {
      final states1 = {WidgetState.hovered, WidgetState.pressed};
      final states2 = {WidgetState.pressed, WidgetState.hovered};

      final state1 = NakedPopoverState(states: states1, isOpen: true);
      final state2 = NakedPopoverState(states: states2, isOpen: true);

      expect(state1 == state2, isTrue);
      expect(state1.hashCode == state2.hashCode, isTrue);
    });

    test('NakedCheckboxState honors contract', () {
      final states1 = {WidgetState.focused, WidgetState.hovered};
      final states2 = {WidgetState.hovered, WidgetState.focused};

      final state1 = NakedCheckboxState(
        states: states1,
        isChecked: true,
        tristate: false,
      );
      final state2 = NakedCheckboxState(
        states: states2,
        isChecked: true,
        tristate: false,
      );

      expect(state1 == state2, isTrue);
      expect(state1.hashCode == state2.hashCode, isTrue);
    });

    test('NakedToggleState honors contract', () {
      final states1 = {WidgetState.disabled, WidgetState.focused};
      final states2 = {WidgetState.focused, WidgetState.disabled};

      final state1 = NakedToggleState(states: states1, isToggled: true);
      final state2 = NakedToggleState(states: states2, isToggled: true);

      expect(state1 == state2, isTrue);
      expect(state1.hashCode == state2.hashCode, isTrue);
    });

    test('NakedSliderState honors contract', () {
      final states1 = {WidgetState.pressed, WidgetState.focused};
      final states2 = {WidgetState.focused, WidgetState.pressed};

      final state1 = NakedSliderState(
        states: states1,
        value: 0.5,
        min: 0.0,
        max: 1.0,
        isDragging: false,
      );
      final state2 = NakedSliderState(
        states: states2,
        value: 0.5,
        min: 0.0,
        max: 1.0,
        isDragging: false,
      );

      expect(state1 == state2, isTrue);
      expect(state1.hashCode == state2.hashCode, isTrue);
    });

    test('NakedMenuState honors contract', () {
      final states1 = {WidgetState.hovered, WidgetState.selected};
      final states2 = {WidgetState.selected, WidgetState.hovered};

      final state1 = NakedMenuState(states: states1, isOpen: false);
      final state2 = NakedMenuState(states: states2, isOpen: false);

      expect(state1 == state2, isTrue);
      expect(state1.hashCode == state2.hashCode, isTrue);
    });

    test('NakedTabState honors contract', () {
      final states1 = {WidgetState.selected, WidgetState.focused};
      final states2 = {WidgetState.focused, WidgetState.selected};

      final state1 = NakedTabState(states: states1, tabId: 'tab1');
      final state2 = NakedTabState(states: states2, tabId: 'tab1');

      expect(state1 == state2, isTrue);
      expect(state1.hashCode == state2.hashCode, isTrue);
    });

    test('Different states have different equality', () {
      final state1 = NakedButtonState(states: {WidgetState.hovered});
      final state2 = NakedButtonState(states: {WidgetState.focused});

      // Different content = not equal
      expect(state1 == state2, isFalse);
      // hashCodes MAY differ (but don't have to - collisions are allowed)
    });
  });
}
