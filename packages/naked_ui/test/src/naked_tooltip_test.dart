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
            overlayBuilder: (context, info) => const Text('Tooltip'),
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
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const Text('Hover me'),
          ),
        );

        expect(find.text('Tooltip'), findsNothing);
      });
    });

    group('Timer-based Show/Hide Behavior', () {
      testWidgets('shows tooltip after waitDuration on mouse enter', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');
        await tester.pumpMaterialWidget(
          NakedTooltip(
            waitDuration: const Duration(milliseconds: 100),
            showDuration: const Duration(seconds: 2),
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        // Create mouse pointer and hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pump();

        // Tooltip should not appear immediately
        expect(find.text('Tooltip'), findsNothing);

        // Advance past waitDuration
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        // Tooltip should now be visible
        expect(find.text('Tooltip'), findsOneWidget);

        // Clean up
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pumpAndSettle();
        await gesture.removePointer();
      });

      testWidgets('hides tooltip after showDuration on mouse exit', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');
        await tester.pumpMaterialWidget(
          NakedTooltip(
            waitDuration: Duration.zero,
            showDuration: const Duration(milliseconds: 100),
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        // Create mouse pointer and hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        // Tooltip should be visible
        expect(find.text('Tooltip'), findsOneWidget);

        // Move pointer outside
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pump();

        // Tooltip should still be visible (before showDuration)
        expect(find.text('Tooltip'), findsOneWidget);

        // Advance past showDuration
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        // Tooltip should now be hidden
        expect(find.text('Tooltip'), findsNothing);
        await gesture.removePointer();
      });
    });

    group('Callback Invocations', () {
      testWidgets('calls onOpen when tooltip becomes visible', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');
        bool onOpenCalled = false;

        await tester.pumpMaterialWidget(
          NakedTooltip(
            waitDuration: Duration.zero,
            onOpen: () => onOpenCalled = true,
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        expect(onOpenCalled, isFalse);

        // Create mouse pointer and hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        expect(onOpenCalled, isTrue);

        // Clean up
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pumpAndSettle();
        await gesture.removePointer();
      });

      testWidgets('calls onClose when tooltip is hidden', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');
        bool onCloseCalled = false;

        await tester.pumpMaterialWidget(
          NakedTooltip(
            waitDuration: Duration.zero,
            showDuration: const Duration(milliseconds: 50),
            onClose: () => onCloseCalled = true,
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        // Create mouse pointer and hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        expect(onCloseCalled, isFalse);

        // Move pointer outside and wait for close
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(onCloseCalled, isTrue);
        await gesture.removePointer();
      });

      testWidgets('onOpenRequested can control show behavior', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');
        bool customShowCalled = false;

        await tester.pumpMaterialWidget(
          NakedTooltip(
            waitDuration: Duration.zero,
            onOpenRequested: (info, show) {
              customShowCalled = true;
              // Intentionally not calling show() to prevent tooltip from appearing
            },
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        // Create mouse pointer and hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        expect(customShowCalled, isTrue);
        // Tooltip should NOT appear because we didn't call show()
        expect(find.text('Tooltip'), findsNothing);

        // Clean up
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pumpAndSettle();
        await gesture.removePointer();
      });

      testWidgets('onCloseRequested can delay hide behavior', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');
        bool customHideCalled = false;
        VoidCallback? storedHide;

        await tester.pumpMaterialWidget(
          NakedTooltip(
            waitDuration: Duration.zero,
            showDuration: Duration.zero,
            onCloseRequested: (hide) {
              customHideCalled = true;
              storedHide = hide;
              // Intentionally not calling hide() immediately
            },
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        // Create mouse pointer and hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        expect(find.text('Tooltip'), findsOneWidget);

        // Move pointer outside
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        expect(customHideCalled, isTrue);
        // Tooltip should still be visible because we didn't call hide()
        expect(find.text('Tooltip'), findsOneWidget);

        // Now call hide
        storedHide?.call();
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
            waitDuration: const Duration(milliseconds: 100),
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        // Create mouse pointer
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));

        // Move in
        await gesture.moveTo(center);
        await tester.pump(const Duration(milliseconds: 50));

        // Move out before waitDuration completes
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Tooltip should NOT appear because we exited before waitDuration
        expect(find.text('Tooltip'), findsNothing);
        await gesture.removePointer();
      });

      testWidgets('cancels pending hide on mouse re-enter', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');

        await tester.pumpMaterialWidget(
          NakedTooltip(
            waitDuration: Duration.zero,
            showDuration: const Duration(milliseconds: 100),
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        // Create mouse pointer
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));

        // Hover to show tooltip
        await gesture.moveTo(center);
        await tester.pumpAndSettle();
        expect(find.text('Tooltip'), findsOneWidget);

        // Move out briefly
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pump(const Duration(milliseconds: 50));

        // Move back in before showDuration completes
        await gesture.moveTo(center);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Tooltip should still be visible because we re-entered
        expect(find.text('Tooltip'), findsOneWidget);

        // Clean up
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pumpAndSettle();
        await gesture.removePointer();
      });
    });

    group('Widget Disposal', () {
      testWidgets('disposes timers when widget is removed', (
        WidgetTester tester,
      ) async {
        const testKey = Key('test');
        bool onOpenCalled = false;

        await tester.pumpMaterialWidget(
          NakedTooltip(
            waitDuration: const Duration(milliseconds: 100),
            onOpen: () => onOpenCalled = true,
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const SizedBox(key: testKey, width: 100, height: 100),
          ),
        );

        // Create mouse pointer and hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pump(const Duration(milliseconds: 50));

        // Replace widget before waitDuration completes
        await tester.pumpMaterialWidget(const SizedBox.shrink());

        // Advance timer past original waitDuration
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // onOpen should NOT be called because widget was disposed
        expect(onOpenCalled, isFalse);
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
            overlayBuilder: (context, info) => const Text('Tooltip'),
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
            overlayBuilder: (context, info) => const Text('Tooltip'),
            child: const Text('Hover me'),
          ),
        );

        final semantics = tester.getSemantics(find.text('Hover me'));
        // When excludeSemantics is true, tooltip should be empty or null
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
              waitDuration: Duration.zero,
              positioning: const OverlayPositionConfig(
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: Offset(0, 8),
              ),
              overlayBuilder: (context, info) => Container(
                key: const Key('tooltip'),
                color: Colors.black,
                child: const Text('Tooltip'),
              ),
              child: const SizedBox(key: testKey, width: 100, height: 50),
            ),
          ),
        );

        // Create mouse pointer and hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();

        final center = tester.getCenter(find.byKey(testKey));
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        // Tooltip should appear below the child
        final childBox = tester.getRect(find.byKey(testKey));
        final tooltipBox = tester.getRect(find.byKey(const Key('tooltip')));

        // Tooltip top should be below child bottom (accounting for offset)
        expect(tooltipBox.top, greaterThanOrEqualTo(childBox.bottom));

        // Clean up
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pumpAndSettle();
        await gesture.removePointer();
      });
    });
  });
}
