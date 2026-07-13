import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'keyboard_test_helpers.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpMaterialWidget(Widget widget) async {
    await pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  }

  /// Simulates hover more robustly by moving a mouse pointer to the center of
  /// the target, ensuring highlight mode is traditional, and giving extra
  /// frames for pointer enter/exit to propagate reliably in integration runs.
  /// When [until] is provided, pumps within a bounded timeout until that
  /// observable hover state is reached while the pointer remains on-target.
  ///
  /// Uses try/finally to ensure proper gesture cleanup even if the test fails.
  Future<void> simulateHover(Key key, {bool Function()? until}) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;

    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      throw FlutterError('simulateHover: No widget found with key $key');
    }

    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    try {
      await gesture.addPointer();

      // Move to center of the target to avoid any edge hit-test ambiguity.
      final center = getCenter(finder);
      await gesture.moveTo(center);
      if (until == null) {
        await pump(const Duration(milliseconds: 32)); // allow onEnter
      } else {
        await pumpUntil(until, timeout: const Duration(seconds: 1));
      }

      // Move well outside the app window to trigger a clean exit.
      await gesture.moveTo(const Offset(-1000, -1000));
      await pump(const Duration(milliseconds: 32)); // allow onExit
    } finally {
      // Cleanup failures must fail the test so pointer state cannot leak.
      await gesture.removePointer();
    }
  }

  Future<void> simulatePress(
    Key key, {
    required VoidCallback? onPressed,
  }) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      throw FlutterError('simulatePress: No widget found with key $key');
    }

    final center = getCenter(finder);
    final gesture = await startGesture(center);

    try {
      // Give UI plenty of time to reflect pressed state in integration env.
      await pump(const Duration(milliseconds: 100));
      await pump(const Duration(milliseconds: 100));

      onPressed?.call();
    } finally {
      // Release exactly once, including when the observation callback fails.
      await gesture.up();
    }
    await pump();
  }

  void expectCursor(SystemMouseCursor cursor, {required Key on}) {
    final region = widget<MouseRegion>(
      find
          .descendant(of: find.byKey(on), matching: find.byType(MouseRegion))
          .first,
    );

    expect(region.cursor, cursor);
  }
}
