import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/semantics_utils.dart' as su;
import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - TextField', () {
    testWidgets('NakedTextField semantics match TextField when enabled', (
      tester,
    ) async {
      const materialKey = Key('materialTextField');
      const nakedKey = Key('nakedTextField');

      final controller1 = TextEditingController();
      final controller2 = TextEditingController();

      await tester.pumpMaterialWidget(
        Column(
          children: [
            TextField(key: materialKey, controller: controller1),
            NakedTextField(
              key: nakedKey,
              controller: controller2,
              builder: (context, child) =>
                  SizedBox(width: 200, height: 40, child: child),
            ),
          ],
        ),
      );

      final expectation = matchesSemantics(
        isTextField: true,
        hasEnabledState: true,
        isEnabled: true,
      );

      await su.expectAnyOfSemantics(tester, find.byKey(materialKey), [
        expectation,
        matchesSemantics(
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
        matchesSemantics(
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      ]);

      await su.expectAnyOfSemantics(tester, find.byKey(nakedKey), [
        expectation,
        matchesSemantics(
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
        matchesSemantics(
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      ]);
    });

    testWidgets('NakedTextField semantics match TextField when disabled', (
      tester,
    ) async {
      const materialKey = Key('materialTextFieldDisabled');
      const nakedKey = Key('nakedTextFieldDisabled');

      await tester.pumpMaterialWidget(
        Column(
          children: [
            const TextField(key: materialKey, enabled: false),
            NakedTextField(
              key: nakedKey,
              enabled: false,
              builder: (context, child) =>
                  SizedBox(width: 200, height: 40, child: child),
            ),
          ],
        ),
      );

      final expectation = matchesSemantics(
        isTextField: true,
        hasEnabledState: true,
        isReadOnly: true,
      );

      await su.expectAnyOfSemantics(tester, find.byKey(materialKey), [
        expectation,
        matchesSemantics(
          isTextField: true,
          hasEnabledState: true,
          isReadOnly: true,
          hasTapAction: true,
        ),
      ]);
      // Material may expose a tap action even when readOnly; don't enforce absence.

      await su.expectAnyOfSemantics(tester, find.byKey(nakedKey), [
        expectation,
        matchesSemantics(
          isTextField: true,
          hasEnabledState: true,
          isReadOnly: true,
          hasTapAction: true,
        ),
      ]);
    });
  });
}
