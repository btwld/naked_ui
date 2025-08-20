import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - Checkbox', () {
    testWidgets(
      'NakedCheckbox semantics match Material Checkbox when enabled',
      (tester) async {
        const materialKey = Key('materialCheckbox');
        const nakedKey = Key('nakedCheckbox');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              Checkbox(key: materialKey, value: true, onChanged: (_) {}),
              NakedCheckbox(
                key: nakedKey,
                value: true,
                onChanged: (_) {},
                child: const SizedBox(width: 24, height: 24),
              ),
            ],
          ),
        );

        final expectation = matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        );

        expect(tester.getSemantics(find.byKey(materialKey)), expectation);
        expect(tester.getSemantics(find.byKey(nakedKey)), expectation);
      },
    );

    testWidgets(
      'NakedCheckbox semantics match Material Checkbox when disabled',
      (tester) async {
        const materialKey = Key('materialCheckboxDisabled');
        const nakedKey = Key('nakedCheckboxDisabled');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              const Checkbox(key: materialKey, value: true, onChanged: null),
              NakedCheckbox(
                key: nakedKey,
                value: true,
                onChanged: null,
                child: const SizedBox(width: 24, height: 24),
              ),
            ],
          ),
        );

        final expectation = matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: false,
          hasTapAction: false,
        );

        expect(tester.getSemantics(find.byKey(materialKey)), expectation);
        expect(tester.getSemantics(find.byKey(nakedKey)), expectation);
      },
    );

    testWidgets(
      'NakedCheckbox semantics match Material Checkbox in tristate mixed',
      (tester) async {
        const materialKey = Key('materialCheckboxMixed');
        const nakedKey = Key('nakedCheckboxMixed');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              Checkbox(
                key: materialKey,
                value: null,
                tristate: true,
                onChanged: (_) {},
              ),
              NakedCheckbox(
                key: nakedKey,
                value: null,
                tristate: true,
                onChanged: (_) {},
                child: const SizedBox(width: 24, height: 24),
              ),
            ],
          ),
        );

        final expectation = matchesSemantics(
          hasCheckedState: true,
          isCheckStateMixed: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        );

        expect(tester.getSemantics(find.byKey(materialKey)), expectation);
        expect(tester.getSemantics(find.byKey(nakedKey)), expectation);
      },
    );
  });
}
