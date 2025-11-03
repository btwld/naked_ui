import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/src/utilities/hit_testable_container.dart';

void main() {
  group('HitTestableContainer', () {
    testWidgets('creates render object correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HitTestableContainer(child: Container(width: 100, height: 100)),
        ),
      );

      final renderObject = tester.renderObject(
        find.byType(HitTestableContainer),
      );
      expect(renderObject, isA<RenderProxyBox>());
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HitTestableContainer(
            child: Container(
              width: 100,
              height: 100,
              color: Colors.red,
              child: const Text('Test'),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('is hit testable within bounds', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: GestureDetector(
              onTap: () => wasPressed = true,
              child: HitTestableContainer(
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      // Tap within the bounds
      await tester.tap(find.byType(HitTestableContainer));
      expect(wasPressed, isTrue);
    });

    testWidgets('hit test passes through to children', (tester) async {
      bool childPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: HitTestableContainer(
              child: GestureDetector(
                onTap: () => childPressed = true,
                child: Container(width: 100, height: 100, color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Container));

      // Child should receive the tap
      expect(childPressed, isTrue);
    });

    testWidgets('debug properties are hidden from inspector', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HitTestableContainer(child: Container(width: 100, height: 100)),
        ),
      );

      final widget = tester.widget<HitTestableContainer>(
        find.byType(HitTestableContainer),
      );
      final properties = DiagnosticPropertiesBuilder();
      widget.debugFillProperties(properties);

      // Should have added the hidden property
      final hiddenProperty = properties.properties.firstWhere(
        (prop) =>
            prop.name == 'inspector' && prop.level == DiagnosticLevel.hidden,
      );
      expect(hiddenProperty.value, equals('hidden'));
    });

    testWidgets('hit test rejects taps outside bounds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: HitTestableContainer(
              child: Container(width: 50, height: 50, color: Colors.green),
            ),
          ),
        ),
      );

      final renderObject = tester.renderObject<RenderBox>(
        find.byType(HitTestableContainer),
      );
      final result = BoxHitTestResult();

      // Test hit outside bounds
      final outsidePosition = Offset(
        renderObject.size.width + 10,
        renderObject.size.height + 10,
      );
      final hitOutside = renderObject.hitTest(
        result,
        position: outsidePosition,
      );

      expect(hitOutside, isFalse);
    });

    testWidgets('paint method works with and without child', (tester) async {
      // Test with child
      await tester.pumpWidget(
        MaterialApp(
          home: HitTestableContainer(
            child: Container(width: 100, height: 100, color: Colors.red),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      // Test without child (empty SizedBox)
      await tester.pumpWidget(
        MaterialApp(home: HitTestableContainer(child: const SizedBox.shrink())),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('debugPaintSize works in debug mode', (tester) async {
      // Test with child
      await tester.pumpWidget(
        MaterialApp(
          home: HitTestableContainer(
            child: Container(width: 100, height: 100, color: Colors.red),
          ),
        ),
      );

      // Enable debug painting to trigger debugPaintSize
      final originalDebugPaintSizeEnabled = debugPaintSizeEnabled;
      debugPaintSizeEnabled = true;

      try {
        // Force a repaint to trigger debugPaintSize method
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Test without child (empty SizedBox)
        await tester.pumpWidget(
          MaterialApp(
            home: HitTestableContainer(child: const SizedBox.shrink()),
          ),
        );

        await tester.pump();
        expect(tester.takeException(), isNull);
      } finally {
        // Always restore original debug state
        debugPaintSizeEnabled = originalDebugPaintSizeEnabled;
      }
    });
  });
}
