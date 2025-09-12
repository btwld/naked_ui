import 'dart:ui' as ui show PointerDeviceKind;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/src/naked_switch.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget _harness({
    required bool initialValue,
    bool enabled = true,
    bool autofocus = false,
    TextDirection textDirection = TextDirection.ltr,
    Size size = const Size(80, 40),
    // spies:
    ValueChanged<bool?>? onChangedSpy,
    ValueChanged<bool>? onFocusChangeSpy,
    ValueChanged<bool>? onHoverChangeSpy,
    ValueChanged<bool>? onPressChangeSpy,
    ValueWidgetBuilder<Set<WidgetState>>? builderSpy,
    String? semanticLabel = 'Headless Switch',
    FocusNode? focusNode,
    Key? switchKey,
  }) {
    return WidgetsApp(
      color: const Color(0xFF000000),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, a1, a2) => builder(context),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
      },
      home: Directionality(
        textDirection: textDirection,
        child: StatefulBuilder(
          builder: (context, setState) {
            bool value = initialValue;
            return Center(
              child: NakedSwitch(
                key: switchKey ?? const Key('naked_switch'),
                value: value,
                enabled: enabled,
                autofocus: autofocus,
                focusNode: focusNode,
                semanticLabel: semanticLabel,
                onChanged: (v) {
                  onChangedSpy?.call(v);
                  setState(() => value = v ?? false);
                },
                onFocusChange: onFocusChangeSpy,
                onHoverChange: onHoverChangeSpy,
                onPressChange: onPressChangeSpy,
                builder:
                    builderSpy ??
                    (ctx, states, child) {
                      // Default child box to make hit-testing easy.
                      return ConstrainedBox(
                        constraints: BoxConstraints.tight(size),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
      ),
    );
  }

  Finder _findSwitch([Key? k]) => find.byKey(k ?? const Key('naked_switch'));

  group('Activation: tap & keyboard', () {
    testWidgets('Tap toggles on → off → on', (tester) async {
      final changes = <bool?>[];

      await tester.pumpWidget(
        _harness(initialValue: false, onChangedSpy: changes.add),
      );
      await tester.pumpAndSettle();

      // Tap once: false -> true
      await tester.tap(_findSwitch());
      await tester.pump();
      expect(changes.last, isTrue);

      // Tap again: true -> false
      await tester.tap(_findSwitch());
      await tester.pump();
      expect(changes.last, isFalse);
    });

    testWidgets('Space and Enter toggle when focused', (tester) async {
      final changes = <bool?>[];
      final node = FocusNode(debugLabel: 'switchFocus');

      await tester.pumpWidget(
        _harness(
          initialValue: false,
          autofocus: true,
          focusNode: node,
          onChangedSpy: changes.add,
        ),
      );
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(changes.last, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changes.last, isFalse);
    });
  });

  group('Disabled behavior', () {
    testWidgets('Does not toggle on tap/keys; onChanged not called', (
      tester,
    ) async {
      final changes = <bool?>[];

      await tester.pumpWidget(
        _harness(
          initialValue: true,
          enabled: false, // _effectiveEnabled = false
          onChangedSpy: changes.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_findSwitch());
      await tester.pump();
      expect(changes, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(changes, isEmpty);
    });
  });

  group('Hover & press callbacks', () {
    testWidgets('Hover in/out fires onHoverChange(true/false)', (tester) async {
      final hovers = <bool>[];
      await tester.pumpWidget(
        _harness(initialValue: false, onHoverChangeSpy: hovers.add),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(_findSwitch()));
      await tester.pump();
      await gesture.moveTo(const Offset(0, 0));
      await tester.pump();
      await gesture.removePointer();

      expect(hovers, equals([true, false]));
    });

    testWidgets('Press down/up/cancel drive onPressChange', (tester) async {
      final presses = <bool>[];
      await tester.pumpWidget(
        _harness(initialValue: false, onPressChangeSpy: presses.add),
      );
      await tester.pumpAndSettle();

      final center = tester.getCenter(_findSwitch());

      // Down only
      final g = await tester.startGesture(center);
      await tester.pump();
      expect(presses.last, isTrue);

      // Up
      await g.up();
      await tester.pump();
      expect(presses.last, isFalse);

      // Down then cancel by moving far outside and cancelling pointer
      final g2 = await tester.startGesture(center);
      await tester.pump();
      expect(presses.last, isTrue);
      await g2.cancel();
      await tester.pump();
      expect(presses.last, isFalse);
    });
  });

  group('Builder receives selected/focus/hover/press states', () {
    testWidgets('Selected state mirrors value and flips after toggle', (
      tester,
    ) async {
      final stateSnaps = <Set<WidgetState>>[];

      await tester.pumpWidget(
        _harness(
          initialValue: true,
          builderSpy: (ctx, states, child) {
            stateSnaps.add(Set<WidgetState>.from(states));
            return ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: 80, height: 40),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Initial: should include selected.
      expect(stateSnaps.isNotEmpty, isTrue);
      expect(stateSnaps.last.contains(WidgetState.selected), isTrue);

      // Tap to toggle off.
      await tester.tap(_findSwitch());
      await tester.pump();

      expect(stateSnaps.last.contains(WidgetState.selected), isFalse);
    });

    testWidgets('Focused/hovered/pressed appear in states set', (tester) async {
      final statesSeen = <WidgetState>{};
      final node = FocusNode();

      await tester.pumpWidget(
        _harness(
          initialValue: false,
          focusNode: node,
          builderSpy: (ctx, states, child) {
            statesSeen.addAll(states);
            return ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: 80, height: 40),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Focus it (autofocus false; give it focus manually).
      node.requestFocus();
      await tester.pump();
      expect(statesSeen.contains(WidgetState.focused), isTrue);

      // Hover it.
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(_findSwitch()));
      await tester.pump();
      expect(statesSeen.contains(WidgetState.hovered), isTrue);

      // Press it (down/up).
      final center = tester.getCenter(_findSwitch());
      final p = await tester.startGesture(center);
      await tester.pump();
      expect(statesSeen.contains(WidgetState.pressed), isTrue);
      await p.up();
      await tester.pump();
      // pressed will have toggled off; presence in 'statesSeen' proves it surfaced at some point.
      await mouse.removePointer();
    });
  });

  group('Focus callbacks', () {
    testWidgets('onFocusChange fires for focus gain/loss', (tester) async {
      final focusEvents = <bool>[];
      final node = FocusNode();

      await tester.pumpWidget(
        _harness(
          initialValue: false,
          focusNode: node,
          onFocusChangeSpy: focusEvents.add,
        ),
      );
      await tester.pumpAndSettle();

      node.requestFocus();
      await tester.pump();
      node.unfocus();
      await tester.pump();

      expect(focusEvents, equals([true, false]));
    });
  });
}
