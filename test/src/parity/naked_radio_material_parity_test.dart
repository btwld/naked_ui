import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - Radio', () {
    testWidgets(
      'NakedRadio semantics match Material Radio when enabled and selected',
      (tester) async {
        const materialKey = Key('materialRadio');
        const nakedKey = Key('nakedRadio');

        await tester.pumpMaterialWidget(
          Column(
            children: [
              // Material Radio - selected and enabled via RadioGroup
              RadioGroup<String>(
                groupValue: 'a',
                onChanged: (_) {},
                child: Radio<String>(key: materialKey, value: 'a'),
              ),
              // Naked Radio - selected and enabled
              NakedRadioGroup<String>(
                groupValue: 'a',
                onChanged: (_) {},
                child: const NakedRadio<String>(
                  key: nakedKey,
                  value: 'a',
                  child: SizedBox(width: 24, height: 24),
                ),
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
          isInMutuallyExclusiveGroup: true,
        );

        expect(tester.getSemantics(find.byKey(materialKey)), expectation);
        expect(tester.getSemantics(find.byKey(nakedKey)), expectation);
      },
    );

    testWidgets('NakedRadio semantics match Material Radio when disabled', (
      tester,
    ) async {
      const materialKey = Key('materialRadioDisabled');
      const nakedKey = Key('nakedRadioDisabled');

      await tester.pumpMaterialWidget(
        Column(
          children: [
            // Material Radio - selected and disabled via RadioGroup
            RadioGroup<String>(
              groupValue: 'a',
              onChanged: (_) {},
              child: Radio<String>(
                key: materialKey,
                value: 'a',
                enabled: false,
              ),
            ),
            // Naked Radio - selected and disabled (group onChanged null)
            NakedRadioGroup<String>(
              groupValue: 'a',
              onChanged: (_) {},
              child: const NakedRadio<String>(
                key: nakedKey,
                value: 'a',
                child: SizedBox(width: 24, height: 24),
              ),
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
        hasFocusAction: false,
        isInMutuallyExclusiveGroup: true,
      );

      expect(tester.getSemantics(find.byKey(materialKey)), expectation);
      expect(tester.getSemantics(find.byKey(nakedKey)), expectation);
    });
  });
}
