import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

extension KeyboardTestHelpers on WidgetTester {
  /// Verifies focus traversal through [expectedOrder].
  Future<void> verifyTabOrder(List<Finder> expectedOrder) async {
    if (expectedOrder.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    await pump();

    final firstContext = element(expectedOrder.first);
    final focusScope = FocusScope.of(firstContext);
    final policy = FocusTraversalGroup.of(firstContext);
    final firstNode = policy.findFirstFocus(
      focusScope,
      ignoreCurrentFocus: true,
    );
    expect(firstNode, isNotNull, reason: 'No focusable target was found.');
    firstNode!.requestFocus();
    await pump();
    expect(
      _containsPrimaryFocus(expectedOrder.first),
      isTrue,
      reason: 'Expected focus within the first listed target.',
    );

    for (final expected in expectedOrder.skip(1)) {
      final moved = focusScope.nextFocus();
      await pump();

      expect(moved, isTrue, reason: 'Focus traversal could not advance.');
      expect(
        _containsPrimaryFocus(expected),
        isTrue,
        reason: 'Expected focus within the next listed target.',
      );
    }
  }

  /// Simulates keyboard activation using raw key down events (Enter/Space).
  /// Uses full press (down+up) via sendKeyEvent to keep pressed set consistent.
  ///
  /// Any event-dispatch failure is allowed to fail the test.
  Future<void> testKeyboardActivation(
    Finder target, {
    bool testSpace = true,
    bool testEnter = true,
  }) async {
    await tap(target);
    await pumpAndSettle();

    if (testEnter) {
      await sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpAndSettle();
    }
    if (testSpace) {
      await sendKeyEvent(LogicalKeyboardKey.space);
      await pumpAndSettle();
    }
  }
}

bool _containsPrimaryFocus(Finder target) {
  final focusedContext = FocusManager.instance.primaryFocus?.context;
  if (focusedContext is! Element) return false;

  final targetElement = target.evaluate().single;
  if (identical(focusedContext, targetElement)) return true;

  var containsFocus = false;
  focusedContext.visitAncestorElements((ancestor) {
    containsFocus = identical(ancestor, targetElement);
    return !containsFocus;
  });
  return containsFocus;
}
