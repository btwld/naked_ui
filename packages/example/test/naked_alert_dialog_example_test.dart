import 'package:example/api/naked_dialog.0.dart' as dialog_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  testWidgets(
    'alert fixture exposes stable state and resets deterministically',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: dialog_example.AlertDialogExample()),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('alert-dialog.open')), findsOneWidget);
      expect(find.byKey(const ValueKey('alert-dialog.result')), findsOneWidget);
      expect(find.byKey(const ValueKey('alert-dialog.reset')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('alert-dialog.open')));
      await tester.pump();
      await tester.pump();

      final cancelButton = tester.widget<NakedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('alert-dialog.cancel')),
          matching: find.byType(NakedButton),
        ),
      );
      expect(FocusManager.instance.primaryFocus, same(cancelButton.focusNode));
      expect(find.byKey(const ValueKey('alert-dialog.title')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('alert-dialog.message')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('alert-dialog.confirm')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Result: confirm; confirmations: 1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('alert-dialog.reset')));
      await tester.pump();
      expect(find.text('Result: none; confirmations: 0'), findsOneWidget);
    },
  );

  testWidgets('long message fixture supports 200% text and non-action focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: Center(
            child: dialog_example.AlertDialogExample(longMessage: true),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('alert-dialog.open')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('alert-dialog.message')), findsOneWidget);
    final messageFocus = tester.widget<Focus>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('alert-dialog.message')),
            matching: find.byType(Focus),
          )
          .first,
    );
    expect(FocusManager.instance.primaryFocus, same(messageFocus.focusNode));
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byKey(const ValueKey('alert-dialog.title'))),
      ).scale(10),
      20,
    );
    expect(tester.takeException(), isNull);
  });
}
