import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - Slider', () {
    testWidgets('NakedSlider semantics match Material Slider when enabled', (
      tester,
    ) async {
      const materialKey = Key('materialSlider');
      const nakedKey = Key('nakedSlider');

      double materialValue = 0.5;
      double nakedValue = 0.5;

      await tester.pumpMaterialWidget(
        Column(
          children: [
            Slider(key: materialKey, value: materialValue, onChanged: (_) {}),
            NakedSlider(
              key: nakedKey,
              value: nakedValue,
              onChanged: (_) {},
              child: const SizedBox(width: 100, height: 20),
            ),
          ],
        ),
      );

      final expectation = matchesSemantics(
        hasEnabledState: true,
        isEnabled: true,
        isSlider: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        isFocusable: true,
        hasFocusAction: true,
        value: '50%',
      );

      expect(tester.getSemantics(find.byKey(materialKey)), expectation);
      expect(tester.getSemantics(find.byKey(nakedKey)), expectation);
    });

    testWidgets('NakedSlider semantics match Material Slider when disabled', (
      tester,
    ) async {
      const materialKey = Key('materialSliderDisabled');
      const nakedKey = Key('nakedSliderDisabled');

      await tester.pumpMaterialWidget(
        Column(
          children: [
            const Slider(key: materialKey, value: 0.5, onChanged: null),
            NakedSlider(
              key: nakedKey,
              value: 0.5,
              onChanged: null,
              child: const SizedBox(width: 100, height: 20),
            ),
          ],
        ),
      );

      final expectation = matchesSemantics(
        hasEnabledState: true,
        isEnabled: false,
        isSlider: true,
        hasIncreaseAction: false,
        hasDecreaseAction: false,
        isFocusable: false,
        hasFocusAction: false,
      );

      expect(tester.getSemantics(find.byKey(materialKey)), expectation);
      expect(tester.getSemantics(find.byKey(nakedKey)), expectation);
    });
  });
}
