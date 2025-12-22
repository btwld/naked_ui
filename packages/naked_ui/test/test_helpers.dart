import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpMaterialWidget(Widget widget) async {
    await pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  }

  /// Simulates hover more robustly by moving a mouse pointer to the center of
  /// the target, ensuring highlight mode is traditional, and giving extra
  /// frames for pointer enter/exit to propagate reliably in integration runs.
  Future<void> simulateHover(Key key, {VoidCallback? onHover}) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;

    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);

    // Move to center of the target to avoid any edge hit-test ambiguity.
    final center = getCenter(find.byKey(key));
    await gesture.moveTo(center);
    await pump(const Duration(milliseconds: 32)); // allow onEnter

    onHover?.call();

    // Move well outside the app window to trigger a clean exit.
    await gesture.moveTo(const Offset(-1000, -1000));
    await pump(const Duration(milliseconds: 32)); // allow onExit
  }

  Future<void> simulatePress(Key key, {VoidCallback? onPressed}) async {
    final center = getCenter(find.byKey(key));

    final gesture = await startGesture(center);
    addTearDown(() async {
      try {
        await gesture.up();
      } on AssertionError {
        // gesture.up() asserts _pointer._isDown, so calling it twice throws
        // AssertionError. This is expected when the test completed normally.
        // We catch to prevent teardown failures from masking actual test failures.
      }
    });

    // Give UI plenty of time to reflect pressed state in integration env.
    await pump(const Duration(milliseconds: 100));
    await pump(const Duration(milliseconds: 100));

    onPressed?.call();
    await gesture.up();
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
