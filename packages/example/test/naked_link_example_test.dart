import 'package:example/api/naked_link.0.dart' as link_example;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('canonical Link fixture exposes stable deterministic state', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const link_example.LinkExample()));

    for (final key in [
      'link.primary',
      'link.disabled',
      'link.external',
      'link.result',
      'link.state',
      'link.next-focus',
      'link.disable-primary',
      'link.reset',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    expect(find.text('Result: none; activations: 0'), findsOneWidget);
    expect(
      find.text('hovered:false focused:false pressed:false enabled:true'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('link.primary'))).height,
      lessThan(48),
      reason: 'An inline Link must not be forced into a button-sized line box.',
    );
    for (final key in const ['link.external', 'link.disabled']) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(
        size.width,
        lessThan(600),
        reason: '$key should wrap its content, not fill the 680px row.',
      );
    }
    expect(find.text('.'), findsNothing);
  });

  testWidgets('primary and external activation update result exactly once', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const link_example.LinkExample()));

    await tester.tap(find.byKey(const ValueKey('link.primary')));
    await tester.pump();
    expect(find.text('Result: primary; activations: 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('link.external')));
    await tester.pump();
    expect(find.text('Result: external; activations: 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('link.reset')));
    await tester.pump();
    expect(find.text('Result: none; activations: 0'), findsOneWidget);
  });

  testWidgets('disabled Link cannot change the fixture result', (tester) async {
    await tester.pumpWidget(_app(const link_example.LinkExample()));

    await tester.tap(find.byKey(const ValueKey('link.disabled')));
    await tester.pump();
    expect(find.text('Result: none; activations: 0'), findsOneWidget);

    final data = tester
        .getSemantics(find.text('Unavailable documentation'))
        .getSemanticsData();
    expect(data.flagsCollection.isLink, isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);
  });

  testWidgets(
    'focus and dynamic destination state are visible and resettable',
    (tester) async {
      await tester.pumpWidget(_app(const link_example.LinkExample()));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.pump();
      expect(
        find.text('hovered:false focused:true pressed:false enabled:true'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('link.disable-primary')));
      await tester.pump();
      await tester.pump();
      expect(
        find.text('hovered:false focused:false pressed:false enabled:false'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('link.reset')));
      await tester.pump();
      expect(
        find.text('hovered:false focused:false pressed:false enabled:true'),
        findsOneWidget,
      );
    },
  );

  testWidgets('external hint is named once and its icon is decorative', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_app(const link_example.LinkExample()));

      final data = tester
          .getSemantics(find.byKey(const ValueKey('link.external')))
          .getSemanticsData();
      expect(data.label, 'Flutter accessibility documentation');
      expect(data.hint, 'External destination');
      expect(
        find.bySemanticsLabel(RegExp(r'^External link icon$')),
        findsNothing,
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('fixture supports RTL and 200% long text without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const link_example.LinkExample(
          textDirection: TextDirection.rtl,
          textScale: 2,
          longText: true,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final directionality = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('link.primary')),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
    expect(find.textContaining('دليل الوصول'), findsOneWidget);
  });

  testWidgets('styled Links preserve the ambient font family', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'FixtureFont'),
        home: const Scaffold(body: link_example.LinkExample()),
      ),
    );

    final style = DefaultTextStyle.of(
      tester.element(find.text('Read the documentation')),
    ).style;
    expect(style.fontFamily, 'FixtureFont');
  });
}

Widget _app(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}
