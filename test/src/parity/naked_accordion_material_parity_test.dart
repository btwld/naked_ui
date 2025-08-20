import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/semantics_utils.dart' as su;
import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - Accordion', () {
    testWidgets('Expanded/collapsed semantics parity vs ExpansionTile', (
      tester,
    ) async {
      const materialKey = Key('materialAccordion');
      const nakedKey = Key('nakedAccordion');

      await tester.pumpMaterialWidget(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: ExpansionTile(
                key: materialKey,
                title: const Text('Section'),
                children: const [Text('Content')],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 300,
              child: NakedAccordion<String>(
                key: nakedKey,
                controller: NakedAccordionController<String>(),
                children: [
                  NakedAccordionItem<String>(
                    value: 'section',
                    semanticLabel: 'Section',
                    child: const Text('Content'),
                    trigger: (context, isExpanded) => const Text('Section'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      // Collapsed state: header should be tappable (allow optional focus)
      await su.expectAnyOfSemantics(tester, find.byKey(materialKey), [
        matchesSemantics(hasTapAction: true, isFocusable: true),
        matchesSemantics(
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
        matchesSemantics(
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isFocusable: true,
        ),
        matchesSemantics(
          hasTapAction: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isFocusable: true,
        ),
      ]);
      await su.expectAnyOfSemantics(tester, find.byKey(nakedKey), [
        matchesSemantics(hasTapAction: true, isFocusable: true),
        matchesSemantics(
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
        matchesSemantics(
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isFocusable: true,
        ),
        matchesSemantics(
          hasTapAction: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isFocusable: true,
        ),
      ]);

      // Content should not be visible yet
      expect(find.text('Content'), findsNothing);

      // Proceed to expand

      // Expand both
      await tester.tap(find.byKey(materialKey));
      await tester.pumpAndSettle();

      // Expand NakedAccordion by tapping on trigger text
      await tester.tap(find.text('Section').last);
      await tester.pumpAndSettle();

      // Expanded state: content should be visible
      expect(find.text('Content'), findsNWidgets(2));

      // Headers remain tappable
      await su.expectAnyOfSemantics(tester, find.byKey(materialKey), [
        matchesSemantics(hasTapAction: true, isFocusable: true),
        matchesSemantics(
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
        matchesSemantics(
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isFocusable: true,
        ),
        matchesSemantics(
          hasTapAction: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isFocusable: true,
        ),
      ]);
      await su.expectAnyOfSemantics(tester, find.byKey(nakedKey), [
        matchesSemantics(hasTapAction: true, isFocusable: true),
        matchesSemantics(
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
        matchesSemantics(
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isFocusable: true,
        ),
        matchesSemantics(
          hasTapAction: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isFocusable: true,
        ),
      ]);
    });
  });
}
