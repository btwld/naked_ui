import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - Switch', () {
    testWidgets('basic tap response parity (on/off)', (tester) async {
      bool materialValue = false;
      bool nakedValue = false;

      const materialKey = Key('material');
      const nakedKey = Key('naked');

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                Switch(
                  key: materialKey,
                  value: materialValue,
                  onChanged: (v) => setState(() => materialValue = v),
                ),
                NakedSwitch(
                  key: nakedKey,
                  value: nakedValue,
                  onChanged: (v) => setState(() => nakedValue = v ?? false),
                  child: const SizedBox(width: 48, height: 24),
                ),
              ],
            );
          },
        ),
      );

      // Tap both
      await tester.tap(find.byKey(materialKey));
      await tester.pump();
      await tester.tap(find.byKey(nakedKey));
      await tester.pump();

      expect(materialValue, isTrue);
      expect(nakedValue, isTrue);

      await tester.tap(find.byKey(materialKey));
      await tester.pump();
      await tester.tap(find.byKey(nakedKey));
      await tester.pump();

      expect(materialValue, isFalse);
      expect(nakedValue, isFalse);
    });

    testWidgets('keyboard activation parity (Space toggles)', (tester) async {
      bool materialValue = false;
      bool nakedValue = false;

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
                Switch(
                  key: materialKey,
                  value: materialValue,
                  focusNode: materialFocus,
                  onChanged: (v) => setState(() => materialValue = v),
                ),
                NakedSwitch(
                  key: nakedKey,
                  value: nakedValue,
                  focusNode: nakedFocus,
                  onChanged: (v) => setState(() => nakedValue = v ?? false),
                  child: const SizedBox(width: 48, height: 24),
                ),
              ],
            );
          },
        ),
      );

      // Space toggles both
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

      materialFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      nakedFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(materialValue, isFalse);
      expect(nakedValue, isFalse);
    });

    testWidgets('disabled blocking parity (tap and keyboard)', (tester) async {
      bool materialEnabled = false;
      bool nakedEnabled = false;

      bool materialValue = false;
      bool nakedValue = false;

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
                Switch(
                  key: materialKey,
                  value: materialValue,
                  focusNode: materialFocus,
                  onChanged: materialEnabled
                      ? (v) => setState(() => materialValue = v)
                      : null,
                ),
                NakedSwitch(
                  key: nakedKey,
                  value: nakedValue,
                  enabled: nakedEnabled,
                  focusNode: nakedFocus,
                  onChanged: (v) => setState(() => nakedValue = v ?? false),
                  child: const SizedBox(width: 48, height: 24),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    materialEnabled = !materialEnabled;
                    nakedEnabled = !nakedEnabled;
                  }),
                  child: const Text('Toggle'),
                ),
              ],
            );
          },
        ),
      );

      // Initially disabled
      await tester.tap(find.byKey(materialKey));
      await tester.pump();
      await tester.tap(find.byKey(nakedKey));
      await tester.pump();
      expect(materialValue, isFalse);
      expect(nakedValue, isFalse);

      materialFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      nakedFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(materialValue, isFalse);
      expect(nakedValue, isFalse);

      // Enable both and verify interactions
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      await tester.tap(find.byKey(materialKey));
      await tester.pump();
      await tester.tap(find.byKey(nakedKey));
      await tester.pump();

      expect(materialValue, isTrue);
      expect(nakedValue, isTrue);

      materialFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      nakedFocus.requestFocus();
      await tester.pump();
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
                Switch(
                  key: materialEnabledKey,
                  value: false,
                  onChanged: (_) {},
                ),
                NakedSwitch(
                  key: nakedEnabledKey,
                  value: false,
                  onChanged: (_) {},
                  child: const SizedBox(width: 48, height: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                Switch(key: materialDisabledKey, value: false, onChanged: null),
                NakedSwitch(
                  key: nakedDisabledKey,
                  value: false,
                  enabled: false,
                  onChanged: (_) {},
                  child: const SizedBox(width: 48, height: 24),
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

  });
}
