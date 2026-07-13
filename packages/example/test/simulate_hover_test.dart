import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/helpers/simulate_hover.dart';

void main() {
  testWidgets('simulateHover waits for the observable hover state', (
    tester,
  ) async {
    const targetKey = ValueKey('delayed-hover-target');
    var hovered = false;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(key: targetKey, width: 40, height: 40)),
      ),
    );
    Timer(const Duration(milliseconds: 48), () => hovered = true);

    await tester.simulateHover(targetKey, until: () => hovered);
    expect(hovered, isTrue);
  });

  testWidgets('simulateHover propagates pointer cleanup failures', (
    tester,
  ) async {
    const targetKey = ValueKey('hover-target');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(key: targetKey, width: 40, height: 40)),
      ),
    );

    final originalFlutterErrorHandler = FlutterError.onError;
    void failPointerRemoval(PointerEvent event) {
      if (event is PointerRemovedEvent) {
        throw StateError('pointer cleanup failed');
      }
    }

    GestureBinding.instance.pointerRouter.addGlobalRoute(failPointerRemoval);
    FlutterError.onError = (details) => throw details.exception;
    try {
      await expectLater(
        tester.simulateHover(targetKey),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'pointer cleanup failed',
          ),
        ),
      );
    } finally {
      FlutterError.onError = originalFlutterErrorHandler;
      GestureBinding.instance.pointerRouter.removeGlobalRoute(
        failPointerRemoval,
      );
    }
  });

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
