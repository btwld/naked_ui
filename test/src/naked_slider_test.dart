import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';
import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Harness that hosts a single NakedSlider and wires state so tests can
  /// observe changes via spies while the slider remains a controlled widget.
  Widget _harness({
    required double initial,
    double min = 0,
    double max = 100,
    Axis direction = Axis.horizontal,
    int? divisions,
    bool enabled = true,
    bool autofocus = false,
    TextDirection textDirection = TextDirection.ltr,
    Size? size,
    // Spies:
    ValueChanged<double>? onChangedSpy,
    VoidCallback? onDragStartSpy,
    ValueChanged<double>? onDragEndSpy,
    ValueChanged<bool>? onHoverChangeSpy,
    ValueChanged<bool>? onDragChangeSpy,
    ValueChanged<bool>? onFocusChangeSpy,
    String? semanticLabel = 'Headless slider',
    FocusNode? focusNode,
    double keyboardStep = 5,
    double largeKeyboardStep = 20,
    Key? sliderKey,
  }) {
    double value = initial;
    return WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => Directionality(
        textDirection: textDirection,
        child: StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: NakedSlider(
                key: sliderKey ?? const Key('slider'),
                value: value,
                min: min.toDouble(),
                max: max.toDouble(),
                onChanged: (v) {
                  onChangedSpy?.call(v);
                  setState(() => value = v);
                },
                onDragStart: onDragStartSpy,
                onDragEnd: onDragEndSpy,
                onHoverChange: onHoverChangeSpy,
                onDragChange: onDragChangeSpy,
                onFocusChange: onFocusChangeSpy,
                enabled: enabled,
                focusNode: focusNode,
                autofocus: autofocus,
                direction: direction,
                divisions: divisions,
                keyboardStep: keyboardStep.toDouble(),
                largeKeyboardStep: largeKeyboardStep.toDouble(),
                semanticLabel: semanticLabel,
                child: ConstrainedBox(
                  constraints: BoxConstraints.tight(
                    size ??
                        (direction == Axis.horizontal
                            ? const Size(200, 24)
                            : const Size(24, 200)),
                  ),
                  child: const SizedBox.expand(), // bare, headless surface
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Finder _findSlider([Key? k]) => find.byKey(k ?? const Key('slider'));

  group('Keyboard (LTR, horizontal)', () {
    testWidgets(
      'Right increments, Left decrements; Shift = large step; Home/End',
      (tester) async {
        final changes = <double>[];
        await tester.pumpWidget(
          _harness(
            initial: 50,
            min: 0,
            max: 100,
            autofocus: true,
            textDirection: TextDirection.ltr,
            onChangedSpy: changes.add,
            keyboardStep: 5,
            largeKeyboardStep: 20,
          ),
        );
        await tester.pumpAndSettle();

        // Arrow Right → +5
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(changes.last, 55);

        // Arrow Left → -5
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(changes.last, 50);

        // Shift + Right → +20
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(changes.last, 70);

        // Home → min (0)
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        expect(changes.last, 0);

        // End → max (100)
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        expect(changes.last, 100);
      },
    );
  });

  group('Keyboard (RTL, horizontal)', () {
    testWidgets('Left increments, Right decrements (reversed)', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _harness(
          initial: 40,
          min: 0,
          max: 100,
          autofocus: true,
          textDirection: TextDirection.rtl,
          onChangedSpy: changes.add,
          keyboardStep: 10,
        ),
      );
      await tester.pumpAndSettle();

      // In RTL, Left increments
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(changes.last, 50);

      // Right decrements
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(changes.last, 40);
    });
  });

  group('Keyboard (vertical)', () {
    testWidgets('Up increments, Down decrements', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _harness(
          initial: 0,
          min: 0,
          max: 100,
          direction: Axis.vertical,
          autofocus: true,
          onChangedSpy: changes.add,
          keyboardStep: 10,
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(changes.last, 10);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(changes.last, 0);
    });
  });

  group('Pointer dragging', () {
    testWidgets(
      'Horizontal drag updates value; onDragStart/End emit; focus requested',
      (tester) async {
        final changes = <double>[];
        bool dragStart = false;
        double? dragEndValue;
        final focusNode = FocusNode(debugLabel: 'sliderFocus');

        await tester.pumpWidget(
          _harness(
            initial: 0,
            min: 0,
            max: 100,
            onChangedSpy: changes.add,
            onDragStartSpy: () => dragStart = true,
            onDragEndSpy: (v) => dragEndValue = v,
            focusNode: focusNode,
            sliderKey: const Key('slider'),
            size: const Size(200, 24),
          ),
        );
        await tester.pumpAndSettle();

        final start = tester.getCenter(_findSlider());
        // Drag ~120 px to the right. With width=200 and range=0..100 => ~60
        await tester.drag(_findSlider(), const Offset(120, 0));
        await tester.pump();

        expect(dragStart, isTrue, reason: 'onDragStart should fire');
        expect(
          changes.last,
          closeTo(60, 1),
          reason: 'value should scale with width',
        );
        expect(
          dragEndValue,
          closeTo(changes.last, 1),
          reason: 'onDragEnd returns last emitted',
        );

        // Focus should have been requested at drag start
        expect(focusNode.hasFocus, isTrue);
      },
    );

    testWidgets('Vertical drag: up increases, down decreases', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _harness(
          initial: 50,
          min: 0,
          max: 100,
          direction: Axis.vertical,
          onChangedSpy: changes.add,
          size: const Size(24, 200),
        ),
      );
      await tester.pumpAndSettle();

      // Drag up by 40 px => increase roughly by 20 (since 200px = 100 units)
      await tester.drag(_findSlider(), const Offset(0, -40));
      await tester.pump();
      expect(changes.last, greaterThan(50));

      // Drag down by 100 px => decrease
      await tester.drag(_findSlider(), const Offset(0, 100));
      await tester.pump();
      expect(changes.last, lessThan(50));
    });

    testWidgets('Horizontal RTL drag: left -> toward max', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _harness(
          initial: 50,
          min: 0,
          max: 100,
          textDirection: TextDirection.rtl,
          onChangedSpy: changes.add,
          size: const Size(200, 24),
        ),
      );
      await tester.pumpAndSettle();

      // In RTL, leftwards drag increases value (because left = max).
      await tester.drag(_findSlider(), const Offset(-60, 0));
      await tester.pump();

      expect(changes.last, greaterThan(50));
    });
  });

  group('Divisions snapping', () {
    testWidgets('Keyboard respects divisions', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _harness(
          initial: 3,
          min: 0,
          max: 10,
          divisions: 10, // step = 1
          autofocus: true,
          onChangedSpy: changes.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(changes.last, 4);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(changes.last, 3);
    });

    testWidgets('Drag snaps to nearest tick', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _harness(
          initial: 0,
          min: 0,
          max: 10,
          divisions: 10, // 1-unit steps
          onChangedSpy: changes.add,
          size: const Size(200, 24),
        ),
      );
      await tester.pumpAndSettle();

      // Drag ~55 px (200px = 10 units -> 1 unit per 20px) => ~2.75 -> snaps to 3
      await tester.drag(_findSlider(), const Offset(55, 0));
      await tester.pump();

      expect(changes.last, 3);
    });
  });

  group('Enable/disable behavior', () {
    testWidgets('Disabled slider ignores keyboard', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _harness(
          initial: 50,
          enabled: false, // _effectiveEnabled = false
          autofocus: true,
          onChangedSpy: changes.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('Disabled slider not focusable or hoverable', (tester) async {
      bool hovered = false;
      await tester.pumpWidget(
        _harness(
          initial: 50,
          enabled: false,
          onHoverChangeSpy: (h) => hovered = h,
        ),
      );
      await tester.pumpAndSettle();

      // Move mouse over and out; since disabled, onShowHoverHighlight shouldn't fire.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(_findSlider()));
      await tester.pump();
      await gesture.moveTo(const Offset(0, 0)); // outside
      await tester.pump();
      await gesture.removePointer();

      expect(hovered, isFalse);
    });
  });

  group('Cursor', () {
    testWidgets('shows appropriate cursor based on interactive state', (tester) async {
      const enabledKey = Key('enabled');
      const disabledKey = Key('disabled');

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, _) => Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedSlider(
                    key: enabledKey,
                    value: 50,
                    min: 0,
                    max: 100,
                    onChanged: (_) {},
                    child: const SizedBox(width: 200, height: 24),
                  ),
                  NakedSlider(
                    key: disabledKey,
                    value: 50,
                    min: 0,
                    max: 100,
                    enabled: false,
                    onChanged: (_) {},
                    child: const SizedBox(width: 200, height: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      tester.expectCursor(SystemMouseCursors.click, on: enabledKey);
      tester.expectCursor(SystemMouseCursors.basic, on: disabledKey);
    });

    testWidgets('uses custom cursor when provided', (tester) async {
      const key = Key('cursor');
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, _) => Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: NakedSlider(
                key: key,
                value: 50,
                min: 0,
                max: 100,
                mouseCursor: SystemMouseCursors.precise,
                onChanged: (_) {},
                child: const SizedBox(width: 200, height: 24),
              ),
            ),
          ),
        ),
      );

      tester.expectCursor(SystemMouseCursors.precise, on: key);
    });
  });

  group('Additional Features', () {
    testWidgets('works with custom min/max range', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _harness(
          initial: 0,
          min: -100,
          max: 100,
          onChangedSpy: changes.add,
          size: const Size(200, 24),
        ),
      );
      await tester.pumpAndSettle();

      // Drag to the right
      await tester.drag(_findSlider(), const Offset(50.0, 0.0));
      await tester.pumpAndSettle();

      expect(changes, isNotEmpty);
      expect(changes.last, greaterThan(0));
      expect(changes.last, lessThanOrEqualTo(100));
    });
  });

  group('Hover, focus, and press states', () {
    testWidgets('Hover callbacks toggle appropriately', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      final hovers = <bool>[];
      const k = Key('slider');
      await tester.pumpWidget(
        _harness(initial: 0, onHoverChangeSpy: hovers.add, sliderKey: k),
      );
      await tester.pumpAndSettle();

      await tester.simulateHover(k, onHover: () {
        // inside hover callback, we expect true was pushed
        expect(hovers.isNotEmpty && hovers.last == true, isTrue);
      });

      expect(hovers, equals([true, false]));
    });

    testWidgets('Focus is requested on drag start', (tester) async {
      final focusNode = FocusNode(debugLabel: 'sliderFocus');
      await tester.pumpWidget(
        _harness(initial: 10, focusNode: focusNode, size: const Size(200, 24)),
      );
      await tester.pumpAndSettle();

      // Start a drag; the slider should request focus.
      await tester.drag(_findSlider(), const Offset(1, 0));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });
  });

  group('Pointer cancellation', () {
    testWidgets('cancel ends drag and clears state', (tester) async {
      final dragStates = <bool>[];
      double? endValue;

      await tester.pumpWidget(
        _harness(
          initial: 50,
          min: 0,
          max: 100,
          onDragChangeSpy: dragStates.add,
          onDragEndSpy: (v) => endValue = v,
          size: const Size(200, 24),
        ),
      );
      await tester.pumpAndSettle();

      final center = tester.getCenter(_findSlider());
      final gesture = await tester.startGesture(center);
      await tester.pump();

      // Drag started -> onDragChange(true)
      expect(dragStates, isNotEmpty);
      expect(dragStates.last, isTrue);

      // Cancel the gesture -> should call onDragChange(false) and onDragEnd
      await gesture.cancel();
      await tester.pump();

      expect(dragStates.last, isFalse);
      expect(endValue, 50); // last emitted or current value when no move
    });
  });
}
