import 'dart:ui' show Offset, PointerDeviceKind;

import 'package:flutter/material.dart'
    show MaterialApp, Scaffold; // only for pumpMaterialWidget
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterExtension on WidgetTester {
  /// Pump using a WidgetsApp (headless). Great for non‑Material tests.
  Future<void> pumpHeadlessWidget(
    Widget widget, {
    TextDirection textDirection = TextDirection.ltr,
    Color fallbackColor = const Color(0xFF000000),
  }) async {
    await pumpWidget(
      WidgetsApp(
        color: fallbackColor,
        builder: (context, _) =>
            Directionality(textDirection: textDirection, child: widget),
      ),
    );
  }

  /// Pump using a MaterialApp (when you explicitly need Material scaffolding).
  Future<void> pumpMaterialWidget(Widget widget) async {
    await pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  }

  /// Simulates hover by moving a mouse pointer to the center of [key],
  /// ensuring highlight mode is traditional, and then moving off‑screen.
  Future<void> simulateHover(Key key, {VoidCallback? onHover}) async {
    final previous = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      // Restore the global highlight strategy after the test.
      FocusManager.instance.highlightStrategy = previous;
    });

    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(() async {
      try {
        await gesture.removePointer();
      } catch (_) {}
    });

    // Enter
    final center = getCenter(find.byKey(key));
    await gesture.moveTo(center);
    await pump(
      const Duration(milliseconds: 16),
    ); // allow onEnter and hover updates

    onHover?.call();

    // Exit: move beyond the current render view bounds.
    final Size viewSize = binding.renderViews.first.size;
    final Offset farAway = Offset(viewSize.width + 100, viewSize.height + 100);
    await gesture.moveTo(farAway);
    await pump(const Duration(milliseconds: 16)); // allow onExit
  }

  /// Simulate a press gesture on [key].
  /// If [hold] is non‑zero, keeps the pointer down for that duration before releasing.
  Future<void> simulatePress(
    Key key, {
    Duration hold = const Duration(milliseconds: 0),
  }) async {
    final center = getCenter(find.byKey(key));
    final gesture = await startGesture(center);
    addTearDown(() async {
      try {
        await gesture.up();
      } catch (_) {}
    });

    // Pointer down frame
    await pump(const Duration(milliseconds: 16));

    if (hold > Duration.zero) {
      await pump(hold);
    }

    await gesture.up();
    await pump(const Duration(milliseconds: 16)); // settle after up
  }

  /// Assert that a MouseRegion under [on] declares the given [cursor].
  /// Note: this checks the declared cursor, not global MouseTracker resolution.
  void expectCursor(SystemMouseCursor cursor, {required Key on}) {
    final regionFinder = find
        .descendant(of: find.byKey(on), matching: find.byType(MouseRegion))
        .first;
    final region = widget<MouseRegion>(regionFinder);
    expect(region.cursor, cursor);
  }
}
