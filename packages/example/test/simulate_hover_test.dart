import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/helpers/simulate_hover.dart';

void main() {
  testWidgets('simulatePress releases its pointer without cleanup errors', (
    tester,
  ) async {
    const targetKey = ValueKey('press-target');
    final cleanupMessages = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message?.startsWith('Gesture cleanup') ?? false) {
        cleanupMessages.add(message!);
      } else {
        originalDebugPrint(message, wrapWidth: wrapWidth);
      }
    };
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox(key: targetKey, width: 40, height: 40)),
        ),
      );

      var observedPressedState = false;
      await tester.simulatePress(
        targetKey,
        onPressed: () => observedPressedState = true,
      );

      expect(observedPressedState, isTrue);
      expect(cleanupMessages, isEmpty);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });
}
