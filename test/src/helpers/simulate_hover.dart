import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpMaterialWidget(Widget widget) async {
    await pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  }

  /// Simulates hover by moving mouse gesture and waiting for Flutter to process hover events
  Future<void> simulateHover(Key key, {VoidCallback? onHover}) async {
    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await pump();

    // Move to widget and wait for hover to be processed
    await gesture.moveTo(getCenter(find.byKey(key)));
    await pumpAndSettle(); // Wait for all hover events to propagate

    // Call onHover callback if provided
    onHover?.call();

    // Move away and wait for hover exit to be processed
    await gesture.moveTo(Offset.zero);
    await pumpAndSettle(); // Wait for all hover exit events to propagate
  }

  Future<void> simulatePress(
    Key key, {
    required VoidCallback? onPressed,
  }) async {
    final pressGesture = await press(find.byKey(key));
    await pump();

    onPressed?.call();

    await pressGesture.up();
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
