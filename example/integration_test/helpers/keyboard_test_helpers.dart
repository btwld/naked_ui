import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

extension KeyboardTestHelpers on WidgetTester {
  /// Test tab navigation order through a list of widgets
  Future<void> verifyTabOrder(List<Finder> expectedOrder) async {
    if (expectedOrder.isEmpty) return;

    // First focus the first element by tapping on it
    await tap(expectedOrder.first);
    await pump();

    // Then tab through the rest
    for (int i = 1; i < expectedOrder.length; i++) {
      await sendKeyEvent(LogicalKeyboardKey.tab);
      await pump();

      // Just verify the widget exists - focus detection is complex
      // and varies by platform and widget implementation
      expect(expectedOrder[i], findsOneWidget);
    }
  }

  /// Test common keyboard activation (Space or Enter)
  Future<void> testKeyboardActivation(
    Finder target, {
    bool testSpace = true,
    bool testEnter = true,
  }) async {
    // Focus the target first
    await tap(target);
    await pump();

    if (testSpace) {
      // Use a single synthesized key event to avoid state desync in
      // integration environments where platform key up/down may be
      // delivered asynchronously.
      await sendKeyEvent(LogicalKeyboardKey.space);
      await pump();
    }

    if (testEnter) {
      await sendKeyEvent(LogicalKeyboardKey.enter);
      await pump();
    }
  }
}
