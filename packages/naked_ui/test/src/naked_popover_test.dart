import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/naked_ui.dart';

import '../test_helpers.dart';
import 'helpers/builder_state_scope.dart';

Matcher _closeTo(double v, [double eps = 0.5]) =>
    moreOrLessEquals(v, epsilon: eps);

void main() {
  group('NakedPopover', () {
    testWidgets('renders child and is closed by default', (tester) async {
      await tester.pumpMaterialWidget(
        NakedPopover(
          popoverBuilder: (context, info) => const Text('Popover Content'),
          child: const Text('Trigger'),
        ),
      );

      expect(find.text('Trigger'), findsOneWidget);
      expect(find.text('Popover Content'), findsNothing);
    });

    testWidgets('opens on tap and closes on outside tap', (tester) async {
      await tester.pumpMaterialWidget(
        Center(
          child: NakedPopover(
            popoverBuilder: (context, info) => const Text('Popover Content'),
            child: const Text('Trigger'),
          ),
        ),
      );

      expect(find.text('Popover Content'), findsNothing);

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle(); // robust against future animations
      expect(find.text('Popover Content'), findsOneWidget);

      // Tap outside to close
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Popover Content'), findsNothing);
    });

    testWidgets('toggles via trigger (tap again closes)', (tester) async {
      await tester.pumpMaterialWidget(
        Center(
          child: NakedPopover(
            popoverBuilder: (context, info) => const Text('Popover Content'),
            child: const Text('Trigger'),
          ),
        ),
      );

      await tester.tap(find.text('Trigger')); // open
      await tester.pumpAndSettle();
      expect(find.text('Popover Content'), findsOneWidget);

      await tester.tap(find.text('Trigger')); // close
      await tester.pumpAndSettle();
      expect(find.text('Popover Content'), findsNothing);
    });

    testWidgets(
      'closes on Escape key (overlay had focus) and returns focus to trigger',
      (tester) async {
        final triggerFocusNode = FocusNode(debugLabel: 'trigger');

        await tester.pumpMaterialWidget(
          Center(
            child: NakedPopover(
              popoverBuilder: (context, info) => const Text('Popover Content'),
              child: Focus(
                // give the trigger a node we can assert on
                focusNode: triggerFocusNode,
                child: const Text('Trigger'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.text('Popover Content'), findsOneWidget);

        // Press ESC to dismiss
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Popover Content'), findsNothing);

        // Focus should return to trigger (RawMenuAnchor.childFocusNode path)
        expect(triggerFocusNode.hasFocus, isTrue);
      },
    );
    testWidgets('opens via Space key on trigger (internal focus)', (
      tester,
    ) async {
      await tester.pumpMaterialWidget(
        Center(
          child: NakedPopover(
            popoverBuilder: (context, info) => const Text('Popover Content'),
            child: const Text('Trigger'),
          ),
        ),
      );

      // Focus the trigger via TAB (FocusTraversal) then activate with Space
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.text('Popover Content'), findsOneWidget);
    });

    testWidgets('opens via Enter key on trigger (internal focus)', (
      tester,
    ) async {
      await tester.pumpMaterialWidget(
        Center(
          child: NakedPopover(
            popoverBuilder: (context, info) => const Text('Popover Content'),
            child: const Text('Trigger'),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Popover Content'), findsOneWidget);
    });

    testWidgets('positions popover based on anchors', (tester) async {
      const triggerKey = Key('trigger');
      const popoverKey = Key('popover');

      await tester.pumpMaterialWidget(
        Center(
          child: NakedPopover(
            positioning: const OverlayPositionConfig(
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
            ),
            popoverBuilder: (context, info) => const SizedBox(
              key: popoverKey,
              width: 100,
              height: 60,
              child: Text('Popover Content'),
            ),
            child: const SizedBox(
              key: triggerKey,
              width: 80,
              height: 40,
              child: Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      final triggerCenter = tester.getCenter(find.byKey(triggerKey));
      final popoverCenter = tester.getCenter(find.byKey(popoverKey));
      expect(popoverCenter.dx, _closeTo(triggerCenter.dx)); // horizontal align

      // Popover top aligns to trigger bottom (follower top to target bottom)
      final triggerBottom = tester.getBottomLeft(find.byKey(triggerKey)).dy;
      final popoverTop = tester.getTopLeft(find.byKey(popoverKey)).dy;
      expect(popoverTop, _closeTo(triggerBottom));
    });

    testWidgets('outside tap: true swallows, false propagates', (tester) async {
      var backgroundTaps = 0;

      Future<void> mount({required bool consumeOutsideTaps}) async {
        backgroundTaps = 0;
        await tester.pumpMaterialWidget(
          Stack(
            children: [
              // Background tap target to detect propagation
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => backgroundTaps++,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
              Center(
                child: NakedPopover(
                  popoverBuilder: (context, info) => const SizedBox(
                    width: 100,
                    height: 60,
                    child: Text('Popover Content'),
                  ),
                  child: const Text('Trigger'),
                  consumeOutsideTaps: consumeOutsideTaps,
                ),
              ),
            ],
          ),
        );
      }

      // consumeOutsideTaps = true: outside tap closes and does not propagate
      await mount(consumeOutsideTaps: true);
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Popover Content'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Popover Content'), findsNothing);
      expect(backgroundTaps, 0, reason: 'outside tap is swallowed');

      // consumeOutsideTaps = false: outside tap closes and propagates
      await mount(consumeOutsideTaps: false);
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Popover Content'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Popover Content'), findsNothing);
      expect(
        backgroundTaps,
        greaterThan(0),
        reason: 'outside tap propagates when not consumed',
      );
    });

    testWidgets('ESC closes even when no outside space is tappable', (
      tester,
    ) async {
      // Regression test: if the overlay covers the whole screen with hit testing,
      // DismissIntent should still close via ESC.
      await tester.pumpMaterialWidget(
        SizedBox.expand(
          child: Center(
            child: NakedPopover(
              popoverBuilder: (context, info) => const SizedBox(
                width: 120,
                height: 80,
                child: Text('Popover Content'),
              ),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Popover Content'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Popover Content'), findsNothing);
    });

    testStateScopeBuilder<NakedPopoverState>(
      'builder\'s context contains NakedStateScope',
      (builder) => NakedPopover(
        popoverBuilder: (context, info) =>
            const SizedBox(child: Text('Popover Content')),
        builder: builder,
        child: const Text('Trigger'),
      ),
    );
  });
}
