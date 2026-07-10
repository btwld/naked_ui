import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/src/utilities/hit_testable_container.dart';

void main() {
  group('HitTestableContainer', () {
    testWidgets('renders its child without changing its size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: HitTestableContainer(
              child: SizedBox(width: 80, height: 40, child: Text('Test')),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(
        tester.getSize(find.byType(HitTestableContainer)),
        const Size(80, 40),
      );
    });

    testWidgets('makes a layout-only child opaque to hit testing', (
      tester,
    ) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: GestureDetector(
              onTap: () => tapCount++,
              child: const HitTestableContainer(
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HitTestableContainer));

      expect(tapCount, 1);
    });

    testWidgets('preserves child gesture handling', (tester) async {
      var childTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: HitTestableContainer(
              child: GestureDetector(
                onTap: () => childTapCount++,
                child: Container(width: 100, height: 100, color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));

      expect(childTapCount, 1);
    });

    testWidgets('does not accept hits outside its bounds', (tester) async {
      var backgroundTapCount = 0;
      var foregroundTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => backgroundTapCount++,
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () => foregroundTapCount++,
                  child: const HitTestableContainer(
                    child: SizedBox(width: 50, height: 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tapAt(const Offset(10, 10));

      expect(backgroundTapCount, 1);
      expect(foregroundTapCount, 0);
    });
  });
}
