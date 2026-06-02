import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedTooltip', () {
    group('Basic Functionality', () {
      testWidgets('renders child widget', (WidgetTester tester) async {
        await tester.pumpMaterialWidget(
          NakedTooltip(
            tooltipBuilder: (context, animation) => const Text('Tooltip'),
            child: const Text('Hover me'),
          ),
        );

        expect(find.text('Hover me'), findsOneWidget);
      });

      testWidgets('does not show tooltip initially', (
        WidgetTester tester,
      ) async {
        await tester.pumpMaterialWidget(
          NakedTooltip(
            tooltipBuilder: (context, animation) => const Text('Tooltip'),
            child: const Text('Hover me'),
          ),
        );

        expect(find.text('Tooltip'), findsNothing);
      });
    });

    group('Timer-based Show/Hide Behavior', () {
      testWidgets('shows tooltip after hoverDelay on mouse enter', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');
        await tester.pumpMaterialWidget(
          NakedTooltip(
            hoverDelay: const Duration(milliseconds: 100),
            dismissDelay: const Duration(seconds: 2),
            tooltipBuilder: (context, animation) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pump();

        expect(find.text('Tooltip'), findsNothing);

        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        expect(find.text('Tooltip'), findsOneWidget);

        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pumpAndSettle();
        await gesture.removePointer();
      });

      testWidgets('hides tooltip after dismissDelay on mouse exit', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');
        await tester.pumpMaterialWidget(
          NakedTooltip(
            hoverDelay: Duration.zero,
            dismissDelay: const Duration(milliseconds: 100),
            tooltipBuilder: (context, animation) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        expect(find.text('Tooltip'), findsOneWidget);

        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pump();

        expect(find.text('Tooltip'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        expect(find.text('Tooltip'), findsNothing);
        await gesture.removePointer();
      });
    });

    group('Rapid Mouse Enter/Exit', () {
      testWidgets('cancels pending show on rapid mouse exit', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');

        await tester.pumpMaterialWidget(
          NakedTooltip(
            hoverDelay: const Duration(milliseconds: 100),
            tooltipBuilder: (context, animation) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));

        await gesture.moveTo(center);
        await tester.pump(const Duration(milliseconds: 50));

        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Tooltip'), findsNothing);
        await gesture.removePointer();
      });

      testWidgets('cancels pending hide on mouse re-enter', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');

        await tester.pumpMaterialWidget(
          NakedTooltip(
            hoverDelay: Duration.zero,
            dismissDelay: const Duration(milliseconds: 100),
            tooltipBuilder: (context, animation) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));

        await gesture.moveTo(center);
        await tester.pumpAndSettle();
        expect(find.text('Tooltip'), findsOneWidget);

        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pump(const Duration(milliseconds: 50));

        await gesture.moveTo(center);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Tooltip'), findsOneWidget);

        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pumpAndSettle();
        await gesture.removePointer();
      });
    });

    group('Widget Disposal', () {
      testWidgets('cleans up when widget is removed', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');

        await tester.pumpMaterialWidget(
          NakedTooltip(
            hoverDelay: const Duration(milliseconds: 100),
            tooltipBuilder: (context, animation) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pump(const Duration(milliseconds: 50));

        await tester.pumpMaterialWidget(const SizedBox.shrink());

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Tooltip'), findsNothing);
        await gesture.removePointer();
      });
    });

    group('Semantics', () {
      testWidgets('includes semantics label when provided', (
        WidgetTester tester,
      ) async {
        final handle = tester.ensureSemantics();

        await tester.pumpMaterialWidget(
          NakedTooltip(
            semanticsLabel: 'Help text',
            tooltipBuilder: (context, animation) => const Text('Tooltip'),
            child: const Text('Hover me'),
          ),
        );

        final semantics = tester.getSemantics(find.text('Hover me'));
        expect(semantics.tooltip, 'Help text');
        handle.dispose();
      });

      testWidgets('excludeSemantics hides tooltip from accessibility', (
        WidgetTester tester,
      ) async {
        final handle = tester.ensureSemantics();

        await tester.pumpMaterialWidget(
          NakedTooltip(
            semanticsLabel: 'Help text',
            excludeSemantics: true,
            tooltipBuilder: (context, animation) => const Text('Tooltip'),
            child: const Text('Hover me'),
          ),
        );

        final semantics = tester.getSemantics(find.text('Hover me'));
        expect(semantics.tooltip, anyOf(isNull, isEmpty));
        handle.dispose();
      });
    });

    group('Positioning', () {
      testWidgets('uses provided positioning config', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');

        await tester.pumpMaterialWidget(
          Center(
            child: NakedTooltip(
              hoverDelay: Duration.zero,
              positioning: const OverlayPositionConfig(
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: Offset(0, 8),
              ),
              tooltipBuilder: (context, animation) => Container(
                key: const Key('tooltip'),
                color: Colors.black,
                child: const Text('Tooltip'),
              ),
              child: const SizedBox(key: testKey, width: 100, height: 50),
            ),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        final childBox = tester.getRect(find.byKey(testKey));
        final tooltipBox = tester.getRect(find.byKey(const Key('tooltip')));

        expect(tooltipBox.top, greaterThanOrEqualTo(childBox.bottom));

        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pumpAndSettle();
        await gesture.removePointer();
      });
    });

    group('Animation', () {
      testWidgets('provides animation to tooltipBuilder', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');
        Animation<double>? receivedAnimation;

        await tester.pumpMaterialWidget(
          NakedTooltip(
            hoverDelay: Duration.zero,
            tooltipBuilder: (context, animation) {
              receivedAnimation = animation;
              return const Text('Tooltip');
            },
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        expect(receivedAnimation, isNotNull);
        expect(receivedAnimation!.value, 1.0);

        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pumpAndSettle();
        await gesture.removePointer();
      });
    });
  });
}
