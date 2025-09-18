import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('Basic Functionality', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(
        NakedTooltip(
          tooltipBuilder: (context) => const Text('Tooltip Content'),
          child: const Text('Hover Me'),
        ),
      );

      expect(find.text('Hover Me'), findsOneWidget);
      expect(find.text('Tooltip Content'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets(
      'shows and hides tooltip on hover',
      (WidgetTester tester) async {
        final targetKey = GlobalKey();
        await tester.pumpMaterialWidget(
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: NakedTooltip(
              key: targetKey,
              tooltipBuilder: (context) => const Text('Tooltip Content'),
              waitDuration: Duration.zero,
              showDuration: Duration.zero,
              child: const Text('Hover Me'),
            ),
          ),
        );

        expect(find.text('Tooltip Content'), findsNothing);

        await tester.simulateHover(
          targetKey,
          onHover: () {
            expect(find.text('Tooltip Content'), findsOneWidget);
          },
        );

        expect(find.text('Tooltip Content'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'tooltip appears on long press and dismisses on release',
      (WidgetTester tester) async {
        final targetKey = GlobalKey();
        await tester.pumpMaterialWidget(
          Padding(
            padding: const EdgeInsets.all(10),
            child: NakedTooltip(
              key: targetKey,
              tooltipBuilder: (context) => const Text('Tooltip Content'),
              waitDuration: Duration.zero,
              showDuration: Duration.zero,
              child: const Text('Long Press Me'),
            ),
          ),
        );

        expect(find.text('Tooltip Content'), findsNothing);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(targetKey)),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Tooltip Content'), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('Tooltip Content'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('Callbacks', () {
    testWidgets(
      'onOpen callback is called when tooltip opens',
      (WidgetTester tester) async {
        final targetKey = GlobalKey();
        bool onOpenCalled = false;

        await tester.pumpMaterialWidget(
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: NakedTooltip(
              key: targetKey,
              tooltipBuilder: (context) => const Text('Tooltip Content'),
              waitDuration: Duration.zero,
              showDuration: Duration.zero,
              onOpen: () => onOpenCalled = true,
              child: const Text('Hover Me'),
            ),
          ),
        );

        expect(onOpenCalled, false);

        await tester.simulateHover(
          targetKey,
          onHover: () {
            expect(onOpenCalled, true);
          },
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'onClose callback is called when tooltip closes',
      (WidgetTester tester) async {
        final targetKey = GlobalKey();
        bool onCloseCalled = false;

        await tester.pumpMaterialWidget(
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: NakedTooltip(
              key: targetKey,
              tooltipBuilder: (context) => const Text('Tooltip Content'),
              waitDuration: Duration.zero,
              showDuration: Duration.zero,
              onClose: () => onCloseCalled = true,
              child: const Text('Hover Me'),
            ),
          ),
        );

        expect(onCloseCalled, false);

        await tester.simulateHover(
          targetKey,
          onHover: () {
            expect(onCloseCalled, false);
          },
        );

        expect(onCloseCalled, true);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('Timing', () {
    testWidgets(
      'waitDuration delays tooltip appearance',
      (WidgetTester tester) async {
        final targetKey = GlobalKey();

        await tester.pumpMaterialWidget(
          Center(
            child: NakedTooltip(
              key: targetKey,
              tooltipBuilder: (context) => const Text('Tooltip Content'),
              waitDuration: const Duration(milliseconds: 50),
              showDuration: Duration.zero,
              child: const Text('Hover Me'),
            ),
          ),
        );

        // Create gesture without pumpAndSettle
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // Move to hover but don't settle (to test timing precisely)
        await gesture.moveTo(tester.getCenter(find.byKey(targetKey)));
        await tester.pump();

        // Should not appear immediately
        expect(find.text('Tooltip Content'), findsNothing);

        // Should appear after wait duration
        await tester.pump(const Duration(milliseconds: 60));
        expect(find.text('Tooltip Content'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'showDuration auto-dismisses tooltip',
      (WidgetTester tester) async {
        final targetKey = GlobalKey();

        await tester.pumpMaterialWidget(
          Center(
            child: NakedTooltip(
              key: targetKey,
              tooltipBuilder: (context) => const Text('Tooltip Content'),
              waitDuration: Duration.zero,
              showDuration: const Duration(milliseconds: 50),
              child: const Text('Hover Me'),
            ),
          ),
        );

        // Start hovering
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byKey(targetKey)));
        await tester.pump();

        // Should appear immediately
        expect(find.text('Tooltip Content'), findsOneWidget);

        // Should still be visible before show duration expires
        await tester.pump(const Duration(milliseconds: 25));
        expect(find.text('Tooltip Content'), findsOneWidget);

        // Should disappear after show duration
        await tester.pump(const Duration(milliseconds: 30));
        expect(find.text('Tooltip Content'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('Positioning', () {
    testWidgets(
      'tooltip positioning respects offset',
      (WidgetTester tester) async {
        const tooltipKey = Key('tooltip');
        const childKey = Key('child');

        await tester.pumpMaterialWidget(
          Center(
            child: NakedTooltip(
              positioning: const OverlayPositionConfig(
                alignment: Alignment.topCenter,
                offset: Offset(0, -10),
              ),
              tooltipBuilder: (context) => const SizedBox(
                key: tooltipKey,
                width: 100,
                height: 50,
                child: Text('Tooltip'),
              ),
              waitDuration: Duration.zero,
              showDuration: Duration.zero,
              child: const SizedBox(
                key: childKey,
                width: 50,
                height: 30,
                child: Text('Child'),
              ),
            ),
          ),
        );

        await tester.simulateHover(
          childKey,
          onHover: () {
            final childCenter = tester.getCenter(find.byKey(childKey));
            final tooltipCenter = tester.getCenter(find.byKey(tooltipKey));

            // Tooltip should be centered horizontally above the child
            expect(tooltipCenter.dx, childCenter.dx);
            // Tooltip should be offset by 10 pixels above plus the gap
            expect(tooltipCenter.dy, lessThan(childCenter.dy));
          },
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('Semantics', () {
    testWidgets(
      'tooltip has correct semantics label',
      (WidgetTester tester) async {
        final targetKey = GlobalKey();

        await tester.pumpMaterialWidget(
          NakedTooltip(
            key: targetKey,
            semanticsLabel: 'Custom tooltip label',
            tooltipBuilder: (context) => const Text('Tooltip Content'),
            waitDuration: Duration.zero,
            showDuration: Duration.zero,
            child: const Text('Hover Me'),
          ),
        );

        await tester.simulateHover(
          targetKey,
          onHover: () {
            expect(
              tester.getSemantics(find.text('Tooltip Content')),
              matchesSemantics(
                label: 'Custom tooltip label',
              ),
            );
          },
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}