import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keyboard/focus helpers for integration tests.
///
/// Keyboard tests must fail loudly. Helpers here never catch-and-continue;
/// they assert focus preconditions and leave the outcome assertion (value
/// change, overlay visibility, callback count) to the caller.
extension KeyboardTestHelpers on WidgetTester {
  /// Performs cleanup between tests to prevent gesture and focus state
  /// leakage. Call this in tearDown() to ensure proper test isolation.
  ///
  /// Uses a bounded pump, not pumpAndSettle: components with live timers or
  /// repeating animations would hang pumpAndSettle.
  Future<void> cleanupBetweenTests() async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    await pump(const Duration(milliseconds: 100));
  }

  /// Pumps frames until [condition] holds, failing after [timeout].
  ///
  /// Deterministic replacement for pumpAndSettle on widgets with live timers
  /// or repeating animations.
  Future<void> pumpUntil(
    bool Function() condition, {
    Duration step = const Duration(milliseconds: 16),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    var elapsed = Duration.zero;
    while (!condition()) {
      if (elapsed >= timeout) {
        fail('pumpUntil: condition not met within $timeout');
      }
      await pump(step);
      elapsed += step;
    }
  }

  /// Whether the primary focus node is attached at or beneath the widget
  /// matched by [target].
  bool hasPrimaryFocusOn(Finder target) {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    final targetElement = element(target);
    if (focusContext == targetElement) return true;
    var found = false;
    focusContext.visitAncestorElements((ancestor) {
      if (ancestor == targetElement) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  /// Focuses [node], proves it holds primary focus, then sends a full key
  /// press (down+up) of [key] and pumps one frame.
  ///
  /// Naked components do not focus on tap by default, so keyboard tests must
  /// focus through a known [FocusNode]. A keyboard test that cannot focus its
  /// target fails here instead of silently passing.
  Future<void> pressKeyOn(FocusNode node, LogicalKeyboardKey key) async {
    node.requestFocus();
    await pump();
    expect(
      node.hasPrimaryFocus,
      isTrue,
      reason: 'target must hold primary focus before receiving ${key.keyLabel}',
    );
    await sendKeyEvent(key);
    await pump();
  }

  /// Proves a disabled control neither takes focus nor activates: requests
  /// focus on [node], asserts focus is refused, then sends Enter and Space
  /// anyway. Callers assert that no state changed afterwards.
  Future<void> expectRefusesKeyboardActivation(FocusNode node) async {
    node.requestFocus();
    await pump();
    expect(
      node.hasPrimaryFocus,
      isFalse,
      reason: 'a disabled control must not accept focus',
    );
    await sendKeyEvent(LogicalKeyboardKey.enter);
    await pump();
    await sendKeyEvent(LogicalKeyboardKey.space);
    await pump();
  }

  /// Walks focus traversal and asserts focus actually lands on each element
  /// of [expectedOrder], in order.
  Future<void> verifyTabOrder(List<Finder> expectedOrder) async {
    if (expectedOrder.isEmpty) return;

    // Start from a clean slate so the first nextFocus() lands on the first
    // focusable in scope.
    FocusManager.instance.primaryFocus?.unfocus();
    await pump();

    for (final expected in expectedOrder) {
      FocusScope.of(element(expected)).nextFocus();
      await pump();
      expect(
        hasPrimaryFocusOn(expected),
        isTrue,
        reason: 'focus traversal should reach $expected next',
      );
    }
  }
}
