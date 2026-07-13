import 'package:example/api/naked_link.0.dart' as link_example;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/keyboard_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedLink Integration Tests', () {
    testWidgets('Tab and Enter activate once and retain Link focus', (
      tester,
    ) async {
      await tester.pumpWidget(const link_example.MyApp());
      await tester.pump();
      final primary = find.byKey(const ValueKey('link.primary'));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.hasPrimaryFocusOn(primary), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('Result: primary; activations: 1'), findsOneWidget);
      expect(tester.hasPrimaryFocusOn(primary), isTrue);
    });

    testWidgets('Space does not activate and remains available to web scroll', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 320,
                child: link_example.LinkExample(textScale: 2, longText: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final primary = find.byKey(const ValueKey('link.primary'));
      final scrollable = Scrollable.of(tester.element(primary));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.hasPrimaryFocusOn(primary), isTrue);
      final before = scrollable.position.pixels;

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.text('Result: none; activations: 0'), findsOneWidget);
      expect(tester.hasPrimaryFocusOn(primary), isTrue);

      if (kIsWeb) {
        expect(scrollable.position.maxScrollExtent, greaterThan(0));
        await tester.pumpUntil(
          () => scrollable.position.pixels > before,
          timeout: const Duration(seconds: 1),
        );
      }
    });

    testWidgets('pointer hover press and tap expose exact state and result', (
      tester,
    ) async {
      await tester.pumpWidget(const link_example.MyApp());
      await tester.pump();
      final primary = find.byKey(const ValueKey('link.primary'));
      final center = tester.getCenter(primary);

      final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await hover.addPointer(location: Offset.zero);
      addTearDown(hover.removePointer);
      await hover.moveTo(center);
      await tester.pump();
      expect(
        find.text('hovered:true focused:false pressed:false enabled:true'),
        findsOneWidget,
      );

      final press = await tester.startGesture(
        center,
        kind: PointerDeviceKind.mouse,
      );
      var pressIsDown = true;
      addTearDown(() async {
        if (pressIsDown) await press.cancel();
      });
      await tester.pump();
      expect(
        find.text('hovered:true focused:false pressed:true enabled:true'),
        findsOneWidget,
      );
      await press.up();
      pressIsDown = false;
      await tester.pump();
      expect(find.text('Result: primary; activations: 1'), findsOneWidget);
      expect(
        find.text('hovered:true focused:false pressed:false enabled:true'),
        findsOneWidget,
      );
    });

    testWidgets('semantic tap follows the same resolver path', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const link_example.MyApp());
        await tester.pump();
        final node = tester.getSemantics(find.text('Read the documentation'));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pump();
        expect(find.text('Result: primary; activations: 1'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      'disabled Link is skipped and has no pointer or semantic action',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(const link_example.MyApp());
          await tester.pump();
          final primary = find.byKey(const ValueKey('link.primary'));
          final external = find.byKey(const ValueKey('link.external'));
          final next = find.byKey(const ValueKey('link.next-focus'));

          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pump();
          for (final expected in [primary, external, next]) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            expect(tester.hasPrimaryFocusOn(expected), isTrue);
          }

          await tester.tap(find.byKey(const ValueKey('link.disabled')));
          await tester.pump();
          expect(find.text('Result: none; activations: 0'), findsOneWidget);
          final disabled = tester.getSemantics(
            find.text('Unavailable documentation'),
          );
          expect(disabled.getSemanticsData().flagsCollection.isLink, isFalse);
          expect(
            disabled.getSemanticsData().hasAction(SemanticsAction.tap),
            isFalse,
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('disabling while focused blocks later activation', (
      tester,
    ) async {
      await tester.pumpWidget(const link_example.MyApp());
      await tester.pump();
      final primary = find.byKey(const ValueKey('link.primary'));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.hasPrimaryFocusOn(primary), isTrue);

      await tester.tap(find.byKey(const ValueKey('link.disable-primary')));
      await tester.pump();
      await tester.pump();
      expect(
        find.text('hovered:false focused:false pressed:false enabled:false'),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('Result: none; activations: 0'), findsOneWidget);
    });

    testWidgets(
      'secondary click remains free for later Context Menu composition',
      (tester) async {
        await tester.pumpWidget(const link_example.MyApp());
        await tester.pump();

        await tester.tapAt(
          tester.getCenter(find.byKey(const ValueKey('link.primary'))),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await tester.pump();
        expect(find.text('Result: none; activations: 0'), findsOneWidget);
      },
    );

    testWidgets('RTL and 200% long text remain usable without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: link_example.LinkExample(
              textDirection: TextDirection.rtl,
              textScale: 2,
              longText: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('دليل الوصول'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('link.primary')));
      await tester.pump();
      expect(find.text('Result: primary; activations: 1'), findsOneWidget);
    });
  });
}
