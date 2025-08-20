import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - Button', () {
    testWidgets('NakedButton semantics match TextButton when enabled', (tester) async {
      const materialKey = Key('materialButton');
      const nakedKey = Key('nakedButton');

      await tester.pumpMaterialWidget(
        Column(
          children: [
            TextButton(
              key: materialKey,
              onPressed: () {},
              child: const SizedBox(width: 24, height: 24),
            ),
            NakedButton(
              key: nakedKey,
              onPressed: () {},
              child: const SizedBox(width: 24, height: 24),
            ),
          ],
        ),
      );

      final expectation = matchesSemantics(
        hasEnabledState: true,
        isEnabled: true,
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      );

      expect(tester.getSemantics(find.byKey(materialKey)), expectation);
      expect(tester.getSemantics(find.byKey(nakedKey)), expectation);
    });

    testWidgets('NakedButton semantics match TextButton when disabled', (tester) async {
      const materialKey = Key('materialButtonDisabled');
      const nakedKey = Key('nakedButtonDisabled');

      await tester.pumpMaterialWidget(
        Column(
          children: [
            const TextButton(
              key: materialKey,
              onPressed: null,
              child: SizedBox(width: 24, height: 24),
            ),
            const NakedButton(
              key: nakedKey,
              onPressed: null,
              child: SizedBox(width: 24, height: 24),
            ),
          ],
        ),
      );

      final expectation = matchesSemantics(
        hasEnabledState: true,
        isEnabled: false,
        isButton: true,
        isFocusable: false,
        hasTapAction: false,
        hasFocusAction: false,
      );

      expect(tester.getSemantics(find.byKey(materialKey)), expectation);
      expect(tester.getSemantics(find.byKey(nakedKey)), expectation);
    });
  });
}

