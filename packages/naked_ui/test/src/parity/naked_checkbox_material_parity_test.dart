import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/naked_ui.dart';

import '../../test_helpers.dart';

void main() {
  group('Material Parity - Checkbox', () {
    testWidgets('basic tap response parity (checked/unchecked)', (
      tester,
    ) async {
      bool? materialValue = false;
      bool? nakedValue = false;

      const materialKey = Key('material');
      const nakedKey = Key('naked');

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                Checkbox(
                  key: materialKey,
                  value: materialValue,
                  onChanged: (v) => setState(() => materialValue = v),
                ),
                NakedCheckbox(
                  key: nakedKey,
                  value: nakedValue,
                  onChanged: (v) => setState(() => nakedValue = v),
                  child: const SizedBox(width: 24, height: 24),
                ),
              ],
            );
          },
        ),
      );

      await tester.tap(find.byKey(materialKey));
      await tester.pump();
      await tester.tap(find.byKey(nakedKey));
      await tester.pump();

      expect(materialValue, isTrue);
      expect(nakedValue, isTrue);
    });

    testWidgets('keyboard activation parity (Space toggles)', (tester) async {
      bool? materialValue = false;
      bool? nakedValue = false;

      final materialFocus = FocusNode();
      final nakedFocus = FocusNode();
      addTearDown(() {
        materialFocus.dispose();
        nakedFocus.dispose();
      });

      const materialKey = Key('material');
      const nakedKey = Key('naked');

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                Checkbox(
                  key: materialKey,
                  focusNode: materialFocus,
                  value: materialValue,
                  onChanged: (v) => setState(() => materialValue = v),
                ),
                NakedCheckbox(
                  key: nakedKey,
                  focusNode: nakedFocus,
                  value: nakedValue,
                  onChanged: (v) => setState(() => nakedValue = v),
                  child: const SizedBox(width: 24, height: 24),
                ),
              ],
            );
          },
        ),
      );

      materialFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      nakedFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(materialValue, isTrue);
      expect(nakedValue, isTrue);
    });

    testWidgets('disabled blocking parity (tap and keyboard)', (tester) async {
      bool? materialValue = false;
      bool? nakedValue = false;

      final materialFocus = FocusNode();
      final nakedFocus = FocusNode();
      addTearDown(() {
        materialFocus.dispose();
        nakedFocus.dispose();
      });

      const materialKey = Key('material-disabled');
      const nakedKey = Key('naked-disabled');

      await tester.pumpMaterialWidget(
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            Checkbox(
              key: materialKey,
              value: materialValue,
              onChanged: null, // disabled
              focusNode: materialFocus,
            ),
            NakedCheckbox(
              key: nakedKey,
              value: nakedValue,
              enabled: false, // disabled
              onChanged: (v) => nakedValue = v,
              focusNode: nakedFocus,
              child: const SizedBox(width: 24, height: 24),
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(materialKey));
      await tester.tap(find.byKey(nakedKey));
      await tester.pump();

      materialFocus.requestFocus();
      await tester.pump();
      // Focus may land on a scope when control is disabled; no identity assertion.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      nakedFocus.requestFocus();
      await tester.pump();
      // Focus may land on a scope when control is disabled; no identity assertion.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(materialValue, isFalse);
      expect(nakedValue, isFalse);
    });

    testWidgets('hover cursor parity (enabled vs disabled)', (tester) async {
      const materialEnabledKey = Key('material-enabled');
      const materialDisabledKey = Key('material-disabled');
      const nakedEnabledKey = Key('naked-enabled');
      const nakedDisabledKey = Key('naked-disabled');

      await tester.pumpMaterialWidget(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                Checkbox(
                  key: materialEnabledKey,
                  value: false,
                  onChanged: (_) {},
                ),
                NakedCheckbox(
                  key: nakedEnabledKey,
                  value: false,
                  onChanged: (_) {},
                  child: const SizedBox(width: 24, height: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                Checkbox(
                  key: materialDisabledKey,
                  value: false,
                  onChanged: null,
                ),
                NakedCheckbox(
                  key: nakedDisabledKey,
                  value: false,
                  enabled: false,
                  onChanged: (_) {},
                  child: const SizedBox(width: 24, height: 24),
                ),
              ],
            ),
          ],
        ),
      );

      tester.expectCursor(SystemMouseCursors.click, on: materialEnabledKey);
      tester.expectCursor(SystemMouseCursors.click, on: nakedEnabledKey);

      final materialDisabledRegion = tester.widget<MouseRegion>(
        find
            .descendant(
              of: find.byKey(materialDisabledKey),
              matching: find.byType(MouseRegion),
            )
            .first,
      );
      expect(
        materialDisabledRegion.cursor == SystemMouseCursors.basic ||
            materialDisabledRegion.cursor == MouseCursor.defer,
        isTrue,
        reason: 'Material disabled cursor should be basic or defer',
      );
      tester.expectCursor(SystemMouseCursors.basic, on: nakedDisabledKey);
    });

    testWidgets(
      'tristate behavior parity: activation parity starting from null',
      (tester) async {
        bool? materialValue = null;
        bool? nakedValue = null;

        final materialFocus = FocusNode();
        final nakedFocus = FocusNode();
        addTearDown(() {
          materialFocus.dispose();
          nakedFocus.dispose();
        });

        const materialKey = Key('material');
        const nakedKey = Key('naked');

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 24,
                children: [
                  Checkbox(
                    key: materialKey,
                    value: materialValue,
                    tristate: true,
                    focusNode: materialFocus,
                    onChanged: (v) => setState(() => materialValue = v),
                  ),
                  NakedCheckbox(
                    key: nakedKey,
                    value: nakedValue,
                    tristate: true,
                    focusNode: nakedFocus,
                    onChanged: (v) => setState(() => nakedValue = v),
                    child: const SizedBox(width: 24, height: 24),
                  ),
                ],
              );
            },
          ),
        );

        // Use keyboard for deterministic tristate parity checks
        // First tap: null → false
        materialFocus.requestFocus();
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(materialFocus));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(
          materialValue,
          equals(false),
          reason: 'Material checkbox should go null → false',
        );

        nakedFocus.requestFocus();
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(nakedFocus));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(
          nakedValue,
          equals(false),
          reason: 'Naked checkbox should go null → false',
        );

        // Second tap: false → true
        materialFocus.requestFocus();
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(materialFocus));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(
          materialValue,
          equals(true),
          reason: 'Material checkbox should go false → true',
        );

        nakedFocus.requestFocus();
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(nakedFocus));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(
          nakedValue,
          equals(true),
          reason: 'Naked checkbox should go false → true',
        );

        // Third tap: true → null (complete the cycle)
        materialFocus.requestFocus();
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(materialFocus));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(
          materialValue,
          equals(null),
          reason: 'Material checkbox should go true → null',
        );

        nakedFocus.requestFocus();
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(nakedFocus));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(
          nakedValue,
          equals(null),
          reason: 'Naked checkbox should go true → null',
        );
      },
    );
  });
}
