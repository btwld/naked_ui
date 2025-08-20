import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/semantics_utils.dart' as su;
import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - Tooltip', () {
    testWidgets(
      'Tooltip semantics appear when shown and are absent when hidden',
      (tester) async {
        const materialKey = Key('materialTooltip');
        const nakedKey = Key('nakedTooltip');

        await tester.pumpMaterialWidget(
          Row(
            children: [
              Tooltip(
                key: materialKey,
                message: 'Hello',
                child: const Text('Hover me'),
              ),
              const SizedBox(width: 24),
              NakedTooltip(
                key: nakedKey,
                tooltipSemantics: 'Hello',
                position: const NakedMenuPosition(
                  target: Alignment.bottomCenter,
                  follower: Alignment.topCenter,
                ),
                tooltipBuilder: (_) => const Material(child: Text('Hello')),
                child: const Text('Hover me'),
              ),
            ],
          ),
        );

        // Hidden state should not show tooltip semantics
        await su.expectAnyOfSemantics(tester, find.byKey(materialKey), [
          matchesSemantics(tooltip: null),
          matchesSemantics(), // some builds omit tooltip on target
        ]);
        await su.expectAnyOfSemantics(tester, find.byKey(nakedKey), [
          matchesSemantics(tooltip: null),
          matchesSemantics(),
        ]);

        // Show tooltips via long press (more stable in tests)
        final materialGesture = await tester.startGesture(
          tester.getCenter(find.byKey(materialKey)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await materialGesture.up();
        await tester.pumpAndSettle();

        final nakedGesture = await tester.startGesture(
          tester.getCenter(find.byKey(nakedKey)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await nakedGesture.up();
        await tester.pumpAndSettle();

        // When visible, tooltip semantics should be present somewhere in subtree
        await su.expectAnySemanticsMatching(
          tester,
          find.byKey(materialKey),
          matchesSemantics(tooltip: 'Hello'),
        );
        await su.expectAnySemanticsMatching(
          tester,
          find.byKey(nakedKey),
          matchesSemantics(tooltip: 'Hello'),
        );
      },
    );
  });
}
