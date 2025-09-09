import 'package:example/api/naked_tooltip.0.dart' as tooltip_example;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedTooltip Integration Tests', () {
    testWidgets('tooltip shows on hover and hides on exit', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const tooltip_example.MyApp());
      await tester.pump(const Duration(milliseconds: 100));

      final tooltipFinder = find.byType(NakedTooltip);
      expect(tooltipFinder, findsOneWidget);

      final triggerFinder = find.text('Hover me');
      expect(triggerFinder, findsOneWidget);

      // Initially tooltip content should not be visible
      expect(find.text('This is a tooltip'), findsNothing);

      // Simulate hover enter
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(triggerFinder));
      addTearDown(gesture.removePointer);
      await tester.pump(); // Wait for waitDuration (0 seconds in example)

      // Tooltip should be visible now
      expect(find.text('This is a tooltip'), findsOneWidget);

      // Simulate hover exit
      await gesture.moveTo(const Offset(0, 0));
      await tester.pump(
          const Duration(milliseconds: 350)); // Wait for animation + removal

      // Tooltip should be hidden now
      expect(find.text('This is a tooltip'), findsNothing);
    });

    testWidgets('tooltip respects wait duration', (tester) async {
      bool tooltipVisible = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTooltip(
              waitDuration: const Duration(milliseconds: 500),
              showDuration: Duration.zero,
              onStateChange: (state) {
                tooltipVisible = state == OverlayChildLifecycleState.present;
              },
              tooltipBuilder: (context) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Tooltip',
                    style: TextStyle(color: Colors.white)),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Hover Target',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final targetFinder = find.text('Hover Target');

      // Hover over target
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(targetFinder));
      addTearDown(gesture.removePointer);
      await tester.pump(
          const Duration(milliseconds: 200)); // Wait less than waitDuration

      // Tooltip should not be visible yet
      expect(find.text('Tooltip'), findsNothing);
      expect(tooltipVisible, isFalse);

      // Wait for full waitDuration
      await tester.pump(const Duration(milliseconds: 350));

      // Tooltip should now be visible
      expect(find.text('Tooltip'), findsOneWidget);
      expect(tooltipVisible, isTrue);
    });

    testWidgets('tooltip respects show duration', (tester) async {
      bool tooltipVisible = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTooltip(
              waitDuration: Duration.zero,
              showDuration: const Duration(milliseconds: 300),
              onStateChange: (state) {
                tooltipVisible = state == OverlayChildLifecycleState.present;
              },
              tooltipBuilder: (context) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Tooltip',
                    style: TextStyle(color: Colors.white)),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Show Duration Target',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final targetFinder = find.text('Show Duration Target');

      // Hover over target
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(targetFinder));
      addTearDown(gesture.removePointer);
      await tester.pump(); // Tooltip shows immediately (waitDuration: 0)
      expect(find.text('Tooltip'), findsOneWidget);
      expect(tooltipVisible, isTrue);

      // Exit hover
      await gesture.moveTo(const Offset(0, 0));
      await tester.pump(
          const Duration(milliseconds: 100)); // Wait less than showDuration

      // Tooltip should still be visible during showDuration
      expect(find.text('Tooltip'), findsOneWidget);
      expect(tooltipVisible, isTrue);

      // Wait for full showDuration
      await tester.pump(const Duration(milliseconds: 250));

      // Tooltip should now be hidden
      expect(find.text('Tooltip'), findsNothing);
      expect(tooltipVisible, isFalse);
    });

    testWidgets('tooltip positioning works correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTooltip(
              waitDuration: Duration.zero,
              showDuration: Duration.zero,
              position: const NakedMenuPosition(
                target: Alignment.topCenter,
                follower: Alignment.bottomCenter,
              ),
              tooltipBuilder: (context) => Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                    child:
                        Text('Above', style: TextStyle(color: Colors.white))),
              ),
              child: Container(
                width: 80,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                    child:
                        Text('Target', style: TextStyle(color: Colors.white))),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final targetFinder = find.text('Target');

      // Show tooltip
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(targetFinder));
      addTearDown(gesture.removePointer);
      await tester.pump();

      // Verify tooltip is positioned correctly (above the target)
      expect(find.text('Above'), findsOneWidget);

      final targetRect = tester.getRect(targetFinder);
      final tooltipRect = tester.getRect(find.text('Above'));

      // Tooltip should be above the target (smaller y coordinate)
      expect(tooltipRect.center.dy, lessThan(targetRect.center.dy));
    });

    testWidgets('tooltip onStateChange callback works', (tester) async {
      final stateChanges = <OverlayChildLifecycleState>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTooltip(
              waitDuration: Duration.zero,
              showDuration: const Duration(milliseconds: 200),
              onStateChange: (state) => stateChanges.add(state),
              tooltipBuilder: (context) => Container(
                padding: const EdgeInsets.all(8),
                child: const Text('State Test'),
              ),
              child: const Text('Callback Target'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final targetFinder = find.text('Callback Target');

      // Show tooltip
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(targetFinder));
      addTearDown(gesture.removePointer);
      await tester.pump();

      // Should have received 'present' state
      expect(stateChanges, contains(OverlayChildLifecycleState.present));

      // Hide tooltip
      await gesture.moveTo(const Offset(0, 0));
      await tester
          .pump(const Duration(milliseconds: 250)); // Wait for showDuration

      // Should have received 'removed' state
      expect(stateChanges, contains(OverlayChildLifecycleState.removed));
    });

    testWidgets('tooltip handles rapid hover events correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTooltip(
              waitDuration: const Duration(milliseconds: 200),
              showDuration: const Duration(milliseconds: 300),
              tooltipBuilder: (context) => Container(
                padding: const EdgeInsets.all(8),
                child: const Text('Rapid Hover Test'),
              ),
              child: const Text('Rapid Target'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final targetFinder = find.text('Rapid Target');

      // Rapid hover in and out
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(targetFinder));
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(const Offset(0, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(tester.getCenter(targetFinder));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(const Offset(0, 0));

      // Should handle rapid events without errors
      await tester.pump(const Duration(milliseconds: 500));

      // Final hover to show tooltip
      await gesture.moveTo(tester.getCenter(targetFinder));
      await tester
          .pump(const Duration(milliseconds: 250)); // Wait for waitDuration

      expect(find.text('Rapid Hover Test'), findsOneWidget);
    });

    testWidgets('tooltip supports semantic labels', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTooltip(
              waitDuration: Duration.zero,
              showDuration: Duration.zero,
              semanticsLabel: 'This is tooltip information',
              tooltipBuilder: (context) => Container(
                padding: const EdgeInsets.all(8),
                child: const Text('Semantic Tooltip'),
              ),
              child: const Text('Semantic Target'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Verify semantics are properly set
      final targetFinder = find.text('Semantic Target');
      final semantics = tester.getSemantics(targetFinder);

      // Should have tooltip semantic information
      expect(semantics.tooltip, 'This is tooltip information');
    });

    testWidgets('tooltip works with example app animation', (tester) async {
      // Test the full example with animation controller
      await tester.pumpWidget(const tooltip_example.MyApp());
      await tester.pump(const Duration(milliseconds: 100));

      final triggerFinder = find.text('Hover me');

      // Show tooltip (transitions are created inside tooltipBuilder)
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(triggerFinder));
      addTearDown(gesture.removePointer);
      await tester.pump(); // waitDuration: 0

      // Now the animated tooltip should be in the tree
      expect(find.byType(SlideTransition), findsAtLeastNWidgets(1));
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.text('This is a tooltip'), findsOneWidget);

      // Hide tooltip with animation
      await gesture.moveTo(const Offset(0, 0));
      await tester.pump(const Duration(
          milliseconds: 350)); // Wait for removalDelay + animation
      expect(find.text('This is a tooltip'), findsNothing);
    });
  });
}
