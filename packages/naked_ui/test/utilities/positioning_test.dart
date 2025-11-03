import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/src/utilities/positioning.dart';

void main() {
  group('OverlayPositionConfig', () {
    testWidgets('creates with default parameters', (tester) async {
      const config = OverlayPositionConfig();

      expect(config.targetAnchor, equals(Alignment.bottomLeft));
      expect(config.followerAnchor, equals(Alignment.topLeft));
      expect(config.offset, equals(Offset.zero));
    });

    testWidgets('creates with custom parameters', (tester) async {
      const config = OverlayPositionConfig(
        targetAnchor: Alignment.topLeft,
        followerAnchor: Alignment.bottomRight,
        offset: Offset(10, 20),
      );

      expect(config.targetAnchor, equals(Alignment.topLeft));
      expect(config.followerAnchor, equals(Alignment.bottomRight));
      expect(config.offset, equals(const Offset(10, 20)));
    });
  });

  group('OverlayPositioner Widget Tests', () {
    const overlayKey = Key('overlay');
    const childKey = Key('child');

    Widget buildTestWidget({
      OverlayPositionConfig positioning = const OverlayPositionConfig(
        targetAnchor: Alignment.bottomCenter,
        followerAnchor: Alignment.topCenter,
        offset: Offset.zero,
      ),
      Rect targetRect = const Rect.fromLTWH(100, 100, 50, 30),
      Widget? child,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: OverlayPositioner(
              key: overlayKey,
              targetRect: targetRect,
              positioning: positioning,
              child:
                  child ??
                  Container(
                    key: childKey,
                    width: 100,
                    height: 60,
                    color: Colors.blue,
                    child: const Text('Overlay Content'),
                  ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders child widget correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byKey(overlayKey), findsOneWidget);
      expect(find.byKey(childKey), findsOneWidget);
      expect(find.text('Overlay Content'), findsOneWidget);
      expect(find.byType(CustomSingleChildLayout), findsOneWidget);
    });

    testWidgets(
      'positions overlay below target with bottom-center to top-center alignment',
      (tester) async {
        const targetRect = Rect.fromLTWH(200, 150, 80, 40);

        await tester.pumpWidget(
          buildTestWidget(
            targetRect: targetRect,
            positioning: const OverlayPositionConfig(
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
            ),
          ),
        );

        final overlayRect = tester.getRect(find.byKey(childKey));

        // Target center X should align with overlay center X
        final targetCenterX = targetRect.left + targetRect.width / 2;
        final overlayCenterX = overlayRect.left + overlayRect.width / 2;
        expect(overlayCenterX, closeTo(targetCenterX, 1.0));

        // Overlay top should be at target bottom
        expect(overlayRect.top, closeTo(targetRect.bottom, 1.0));
      },
    );

    testWidgets(
      'positions overlay above target with top-center to bottom-center alignment',
      (tester) async {
        const targetRect = Rect.fromLTWH(200, 300, 80, 40);

        await tester.pumpWidget(
          buildTestWidget(
            targetRect: targetRect,
            positioning: const OverlayPositionConfig(
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
            ),
          ),
        );

        final overlayRect = tester.getRect(find.byKey(childKey));

        // Target center X should align with overlay center X
        final targetCenterX = targetRect.left + targetRect.width / 2;
        final overlayCenterX = overlayRect.left + overlayRect.width / 2;
        expect(overlayCenterX, closeTo(targetCenterX, 1.0));

        // Overlay bottom should be at target top
        expect(overlayRect.bottom, closeTo(targetRect.top, 1.0));
      },
    );

    testWidgets(
      'positions overlay to the right with center-right to center-left alignment',
      (tester) async {
        const targetRect = Rect.fromLTWH(100, 200, 60, 50);

        await tester.pumpWidget(
          buildTestWidget(
            targetRect: targetRect,
            positioning: const OverlayPositionConfig(
              targetAnchor: Alignment.centerRight,
              followerAnchor: Alignment.centerLeft,
            ),
          ),
        );

        final overlayRect = tester.getRect(find.byKey(childKey));

        // Target center Y should align with overlay center Y
        final targetCenterY = targetRect.top + targetRect.height / 2;
        final overlayCenterY = overlayRect.top + overlayRect.height / 2;
        expect(overlayCenterY, closeTo(targetCenterY, 1.0));

        // Overlay left should be at target right
        expect(overlayRect.left, closeTo(targetRect.right, 1.0));
      },
    );

    testWidgets('applies offset correctly', (tester) async {
      const targetRect = Rect.fromLTWH(200, 150, 80, 40);
      const offset = Offset(20, -10);

      await tester.pumpWidget(
        buildTestWidget(
          targetRect: targetRect,
          positioning: const OverlayPositionConfig(
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: offset,
          ),
        ),
      );

      final overlayRect = tester.getRect(find.byKey(childKey));

      // Calculate expected position with offset
      final targetCenterX = targetRect.left + targetRect.width / 2;
      final expectedX = targetCenterX - overlayRect.width / 2 + offset.dx;
      final expectedY = targetRect.bottom + offset.dy;

      expect(overlayRect.left, closeTo(expectedX, 1.0));
      expect(overlayRect.top, closeTo(expectedY, 1.0));
    });

    testWidgets(
      'clamps overlay to screen bounds when it would overflow right',
      (tester) async {
        // Position target near right edge
        const targetRect = Rect.fromLTWH(750, 150, 40, 30);

        await tester.pumpWidget(
          buildTestWidget(
            targetRect: targetRect,
            positioning: const OverlayPositionConfig(
              targetAnchor: Alignment.centerRight,
              followerAnchor: Alignment.centerLeft,
            ),
          ),
        );

        final overlayRect = tester.getRect(find.byKey(childKey));

        // Overlay should be clamped to not exceed screen width (800)
        expect(overlayRect.right, lessThanOrEqualTo(800.0));
      },
    );

    testWidgets(
      'clamps overlay to screen bounds when it would overflow bottom',
      (tester) async {
        // Position target near bottom edge
        const targetRect = Rect.fromLTWH(200, 570, 80, 20);

        await tester.pumpWidget(
          buildTestWidget(
            targetRect: targetRect,
            positioning: const OverlayPositionConfig(
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
            ),
          ),
        );

        final overlayRect = tester.getRect(find.byKey(childKey));

        // Overlay should be clamped to not exceed screen height (600)
        expect(overlayRect.bottom, lessThanOrEqualTo(600.0));
      },
    );

    testWidgets('clamps overlay to screen bounds when it would overflow left', (
      tester,
    ) async {
      // Position target near left edge
      const targetRect = Rect.fromLTWH(10, 200, 30, 40);

      await tester.pumpWidget(
        buildTestWidget(
          targetRect: targetRect,
          positioning: const OverlayPositionConfig(
            targetAnchor: Alignment.centerLeft,
            followerAnchor: Alignment.centerRight,
          ),
        ),
      );

      final overlayRect = tester.getRect(find.byKey(childKey));

      // Overlay should be clamped to not go below 0
      expect(overlayRect.left, greaterThanOrEqualTo(0.0));
    });

    testWidgets('clamps overlay to screen bounds when it would overflow top', (
      tester,
    ) async {
      // Position target near top edge
      const targetRect = Rect.fromLTWH(200, 10, 80, 20);

      await tester.pumpWidget(
        buildTestWidget(
          targetRect: targetRect,
          positioning: const OverlayPositionConfig(
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
          ),
        ),
      );

      final overlayRect = tester.getRect(find.byKey(childKey));

      // Overlay should be clamped to not go above 0
      expect(overlayRect.top, greaterThanOrEqualTo(0.0));
    });

    testWidgets('handles corner alignments correctly', (tester) async {
      const targetRect = Rect.fromLTWH(200, 200, 60, 40);

      await tester.pumpWidget(
        buildTestWidget(
          targetRect: targetRect,
          positioning: const OverlayPositionConfig(
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topLeft,
          ),
        ),
      );

      final overlayRect = tester.getRect(find.byKey(childKey));

      // Overlay top-left should align with target bottom-right
      expect(overlayRect.left, closeTo(targetRect.right, 1.0));
      expect(overlayRect.top, closeTo(targetRect.bottom, 1.0));
    });
  });

  group('OverlayPositioner Delegate Tests', () {
    testWidgets('delegate provides loosened constraints', (tester) async {
      const targetRect = Rect.fromLTWH(100, 100, 50, 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                return OverlayPositioner(
                  targetRect: targetRect,
                  child: LayoutBuilder(
                    builder: (context, childConstraints) {
                      // Child should receive loosened constraints
                      expect(childConstraints.minWidth, equals(0.0));
                      expect(childConstraints.minHeight, equals(0.0));
                      expect(
                        childConstraints.maxWidth,
                        equals(constraints.maxWidth),
                      );
                      expect(
                        childConstraints.maxHeight,
                        equals(constraints.maxHeight),
                      );

                      return Container(
                        width: 100,
                        height: 60,
                        color: Colors.blue,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
    });

    testWidgets('delegate triggers relayout when target position changes', (
      tester,
    ) async {
      const initialRect = Rect.fromLTWH(100, 100, 50, 30);
      const newRect = Rect.fromLTWH(200, 150, 50, 30);

      Widget buildWithRect(Rect rect) {
        return MaterialApp(
          home: Scaffold(
            body: OverlayPositioner(
              targetRect: rect,
              child: Container(
                key: const Key('child'),
                width: 100,
                height: 60,
                color: Colors.blue,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWithRect(initialRect));
      final initialPosition = tester.getTopLeft(find.byKey(const Key('child')));

      await tester.pumpWidget(buildWithRect(newRect));
      final newPosition = tester.getTopLeft(find.byKey(const Key('child')));

      // Position should have changed
      expect(newPosition, isNot(equals(initialPosition)));
    });

    testWidgets('delegate triggers relayout when target size changes', (
      tester,
    ) async {
      const initialRect = Rect.fromLTWH(100, 100, 50, 30);
      const newRect = Rect.fromLTWH(
        100,
        100,
        80,
        50,
      ); // Same position, different size

      Widget buildWithRect(Rect rect) {
        return MaterialApp(
          home: Scaffold(
            body: OverlayPositioner(
              targetRect: rect,
              positioning: const OverlayPositionConfig(
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
              ),
              child: Container(
                key: const Key('child'),
                width: 100,
                height: 60,
                color: Colors.blue,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWithRect(initialRect));
      final initialPosition = tester.getTopLeft(find.byKey(const Key('child')));

      await tester.pumpWidget(buildWithRect(newRect));
      final newPosition = tester.getTopLeft(find.byKey(const Key('child')));

      // Position should have changed due to different target size affecting center calculation
      expect(newPosition, isNot(equals(initialPosition)));
    });
  });

  group('Edge Case Tests', () {
    testWidgets('works with zero-sized target', (tester) async {
      const targetRect = Rect.fromLTWH(200, 200, 0, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: OverlayPositioner(
                targetRect: targetRect,
                positioning: const OverlayPositionConfig(
                  targetAnchor: Alignment.center,
                  followerAnchor: Alignment.center,
                ),
                child: Container(
                  key: const Key('child'),
                  width: 100,
                  height: 60,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final overlayRect = tester.getRect(find.byKey(const Key('child')));

      // Overlay center should align with target center (which is the point)
      final overlayCenterX = overlayRect.left + overlayRect.width / 2;
      final overlayCenterY = overlayRect.top + overlayRect.height / 2;

      expect(overlayCenterX, closeTo(targetRect.left, 1.0));
      expect(overlayCenterY, closeTo(targetRect.top, 1.0));
    });

    testWidgets('handles extreme negative offset', (tester) async {
      const targetRect = Rect.fromLTWH(400, 300, 80, 40);
      const offset = Offset(-500, -400);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: OverlayPositioner(
                targetRect: targetRect,
                positioning: OverlayPositionConfig(offset: offset),
                child: Container(
                  key: const Key('child'),
                  width: 100,
                  height: 60,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final overlayRect = tester.getRect(find.byKey(const Key('child')));

      // Should be clamped to screen bounds despite extreme offset
      expect(overlayRect.left, greaterThanOrEqualTo(0.0));
      expect(overlayRect.top, greaterThanOrEqualTo(0.0));
    });

    testWidgets('handles large positive offset', (tester) async {
      const targetRect = Rect.fromLTWH(100, 100, 80, 40);
      const offset = Offset(200, 150); // Large but reasonable offset

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: OverlayPositioner(
                targetRect: targetRect,
                positioning: OverlayPositionConfig(offset: offset),
                child: Container(
                  key: const Key('child'),
                  width: 100,
                  height: 60,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final overlayRect = tester.getRect(find.byKey(const Key('child')));

      // Should be clamped to screen bounds when offset pushes it beyond
      expect(overlayRect.right, lessThanOrEqualTo(800.0));
      expect(overlayRect.bottom, lessThanOrEqualTo(600.0));
      expect(overlayRect.left, greaterThanOrEqualTo(0.0));
      expect(overlayRect.top, greaterThanOrEqualTo(0.0));
    });

    testWidgets('handles overlay larger than screen', (tester) async {
      const targetRect = Rect.fromLTWH(100, 100, 50, 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: OverlayPositioner(
                targetRect: targetRect,
                child: Container(
                  key: const Key('large-child'),
                  width: 500, // Larger than screen
                  height: 400, // Larger than screen
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final overlayRect = tester.getRect(find.byKey(const Key('large-child')));

      // Should be positioned at origin when clamped
      expect(overlayRect.left, equals(0.0));
      expect(overlayRect.top, equals(0.0));
    });
  });
}
