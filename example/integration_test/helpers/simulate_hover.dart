import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpMaterialWidget(Widget widget) async {
    await pumpWidget(
      MaterialApp(
        home: Scaffold(body: widget),
      ),
    );
  }

  /// Simulates hover by moving a mouse pointer slightly inside the widget's rect
  /// and giving the framework a couple of frames to dispatch onEnter/onExit.
  Future<void> simulateHover(Key key, {VoidCallback? onHover}) async {
    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(1, 1));
    addTearDown(gesture.removePointer);
    await pump(const Duration(milliseconds: 16));

    // Move to a position clearly inside the target to avoid edge hit-test flakiness
    final rect = getRect(find.byKey(key));
    final inside = Offset(rect.left + 2, rect.top + 2);
    await gesture.moveTo(inside);
    // Give at least one frame for MouseRegion.onEnter to fire
    await pump(const Duration(milliseconds: 16));

    // Call onHover callback if provided
    onHover?.call();

    // Move away far outside and allow onExit to fire
    await gesture.moveTo(const Offset(0, 0));
    await pump(const Duration(milliseconds: 16));
  }

  Future<void> simulatePress(
    Key key, {
    required VoidCallback? onPressed,
  }) async {
    // Use a precise inside point like simulateHover to avoid hit-test flakiness
    final rect = getRect(find.byKey(key));
    final inside = Offset(rect.left + 2, rect.top + 2);

    final gesture = await startGesture(inside);
    addTearDown(() async {
      try {
        await gesture.up();
      } catch (_) {}
    });

    // Wait for pressed state to become true (with timeout)
    const maxWaitMs = 250;
    const incrementMs = 10;
    var waitedMs = 0;

    while (waitedMs < maxWaitMs) {
      await pump(const Duration(milliseconds: incrementMs));
      waitedMs += incrementMs;
      // We intentionally wait up to maxWaitMs to allow onTapDown/press callbacks to propagate
    }

    onPressed?.call();
    await gesture.up();
    await pump();
  }

  void expectCursor(SystemMouseCursor cursor, {required Key on}) async {
    final region = widget<MouseRegion>(find
        .descendant(of: find.byKey(on), matching: find.byType(MouseRegion))
        .first);

    expect(region.cursor, cursor);
  }
}
