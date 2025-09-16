import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Starts a mouse pointer and hovers over the center of [target].
/// Returns the created gesture so callers can move/remove it later.
Future<TestGesture> startHover(WidgetTester tester, Finder target) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  // Start well outside the view to ensure a clean onEnter when moving in.
  await gesture.addPointer(location: const Offset(-1000, -1000));
  await gesture.moveTo(const Offset(-1000, -1000));
  await tester.pump();
  final center = tester.getCenter(target);
  await gesture.moveTo(center);
  await tester.pumpAndSettle();
  // Some environments need an explicit hover tick.
  tester.binding.handlePointerEvent(
    PointerHoverEvent(position: center, kind: PointerDeviceKind.mouse),
  );
  await tester.pump();
  return gesture;
}

/// Moves the existing hover far outside the window and removes it.
Future<void> endHover(WidgetTester tester, TestGesture gesture) async {
  await gesture.moveTo(const Offset(-1000, -1000));
  await tester.pump();
  await gesture.removePointer();
}
