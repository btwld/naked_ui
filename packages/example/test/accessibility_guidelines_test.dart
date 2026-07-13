import 'package:example/api/naked_button.0.dart' as button_example;
import 'package:example/api/naked_dialog.0.dart' as dialog_example;
import 'package:example/api/naked_field.0.dart' as field_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'helpers/accessibility_guideline_helpers.dart';

void main() {
  testWidgets('canonical styled alert dialog meets accessibility guidelines', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: dialog_example.AlertDialogExample()),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('alert-dialog.open')));
    await tester.pump();
    await tester.pump();

    await tester.expectMeetsAccessibilityGuidelines();
  });

  testWidgets('canonical styled Field meets accessibility guidelines', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Center(child: field_example.FieldExample()),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.byKey(field_example.fieldEmailSubmitKey));
    await tester.tap(find.byKey(field_example.fieldEmailSubmitKey));
    await tester.pump();

    expect(find.text('Enter an email address.'), findsOneWidget);
    await tester.expectMeetsAccessibilityGuidelines();
  });

  testWidgets('canonical styled button meets accessibility guidelines', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: button_example.ButtonExample())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.expectMeetsAccessibilityGuidelines();
  });

  testWidgets('label guideline fails for an unnamed interactive target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 48,
              child: NakedButton(
                onPressed: () {},
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      () => tester.expectMeetsAccessibilityGuidelines(
        androidTapTarget: false,
        iOSTapTarget: false,
        textContrast: false,
      ),
      throwsA(isA<TestFailure>()),
    );
  });
}
