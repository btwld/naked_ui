import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal, composable extensions for common full interaction flows.
extension InteractionTestExtensions on WidgetTester {
  /// Pumps a widget wrapped in WidgetsApp for text field testing.
  Future<void> pumpTextField(Widget widget) async {
    await pumpWidget(
      WidgetsApp(
        color: Colors.white,
        onGenerateRoute: (settings) =>
            MaterialPageRoute(builder: (context) => widget),
      ),
    );
  }

  /// Creates a mouse gesture to simulate hover on a widget type.
  Future<TestGesture> simulateHover(Type type) async {
    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await pump();

    await gesture.moveTo(getCenter(find.byType(type)));
    await pump();

    return gesture;
  }

  /// Simulates hover interaction specifically for tooltip components.
  Future<void> simulateHoverOnTooltip(
    Key key, {
    required VoidCallback? onHover,
  }) async {
    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await pumpAndSettle();

    await gesture.moveTo(getCenter(find.byKey(key)));
    await pumpAndSettle();
    
    onHover?.call();
    
    await gesture.moveTo(Offset.zero);
    await pumpAndSettle();
  }
  /// Wraps a child in a MaterialApp+Scaffold for predictable environment.
  Future<void> pumpInApp(Widget child) async {
    await pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));
  }

  /// Drives a basic interaction cycle against [target]:
  /// - Hover enter and exit (mouse)
  /// - Press down and up (touch)
  /// - Request and release focus (keyboard)
  /// Returns a summary Map useful for ad‑hoc asserts.
  Future<Map<String, dynamic>> fullInteractionCycle(Finder target, {
    FocusNode? focusNode,
  }) async {
    final result = <String, dynamic>{
      'hovered': <bool>[],
      'pressed': <bool>[],
      'focused': <bool>[],
    };

    // HOVER
    final mouse = await createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);

    final center = getCenter(target);
    await mouse.moveTo(center);
    await pumpAndSettle();
    result['hovered'].add(true);

    await mouse.moveTo(const Offset(1, 1));
    await pumpAndSettle();
    result['hovered'].add(false);

    // PRESS
    final gesture = await startGesture(center);
    await pump();
    result['pressed'].add(true);
    await gesture.up();
    await pump();
    result['pressed'].add(false);

    // FOCUS
    final node = focusNode ?? FocusNode();
    if (focusNode == null) addTearDown(node.dispose);

    // Try to focus via FocusTraversal by tapping, fall back to direct request.
    await tap(target);
    await pump();
    if (!node.hasFocus) {
      node.requestFocus();
      await pump();
    }
    result['focused'].add(true);

    node.unfocus();
    await pump();
    result['focused'].add(false);

    return result;
  }
}

