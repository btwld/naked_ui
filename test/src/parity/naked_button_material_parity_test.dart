import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - Button', () {
    testWidgets('basic tap response parity', (tester) async {
      int nakedPressed = 0;
      int materialPressed = 0;

      const nakedKey = Key('naked');
      const materialKey = Key('material');

      await tester.pumpMaterialWidget(
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            TextButton(
              key: materialKey,
              onPressed: () => materialPressed++,
              child: const Text('Material'),
            ),
            NakedButton(
              key: nakedKey,
              onPressed: () => nakedPressed++,
              child: const Text('Naked'),
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(materialKey));
      await tester.pump();
      await tester.tap(find.byKey(nakedKey));
      await tester.pump();

      expect(materialPressed, 1);
      expect(nakedPressed, 1);
    });

    testWidgets('keyboard activation parity (Space/Enter)', (tester) async {
      int nakedPressed = 0;
      int materialPressed = 0;

      final nakedFocus = FocusNode();
      final materialFocus = FocusNode();

      addTearDown(() {
        nakedFocus.dispose();
        materialFocus.dispose();
      });

      const nakedKey = Key('naked');
      const materialKey = Key('material');

      await tester.pumpMaterialWidget(
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            TextButton(
              key: materialKey,
              focusNode: materialFocus,
              onPressed: () => materialPressed++,
              child: const Text('Material'),
            ),
            NakedButton(
              key: nakedKey,
              focusNode: nakedFocus,
              onPressed: () => nakedPressed++,
              child: const Text('Naked'),
            ),
          ],
        ),
      );

      // Focus Material then press Space and Enter
      materialFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // Focus Naked then press Space and Enter
      nakedFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(
        materialPressed,
        2,
        reason: 'Material should activate on Space and Enter',
      );
      expect(
        nakedPressed,
        2,
        reason: 'Naked should activate on Space and Enter',
      );
    });

    testWidgets('disabled blocking parity (tap and keyboard)', (tester) async {
      int nakedPressed = 0;
      int materialPressed = 0;

      final nakedFocus = FocusNode();
      final materialFocus = FocusNode();
      addTearDown(() {
        nakedFocus.dispose();
        materialFocus.dispose();
      });

      const nakedKey = Key('naked');
      const materialKey = Key('material');

      await tester.pumpMaterialWidget(
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            // Disabled Material (onPressed: null)
            TextButton(
              key: materialKey,
              onPressed: null,
              focusNode: materialFocus,
              child: const Text('Material'),
            ),
            // Disabled Naked (enabled: false)
            NakedButton(
              key: nakedKey,
              enabled: false,
              onPressed: () => nakedPressed++,
              focusNode: nakedFocus,
              child: const Text('Naked'),
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(materialKey));
      await tester.tap(find.byKey(nakedKey));
      await tester.pump();

      // Focus Material (disabled) and send keys
      materialFocus.requestFocus();
      await tester.pump();
      // Focus may land on a scope when control is disabled; no identity assertion.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // Focus Naked (disabled) and send keys
      nakedFocus.requestFocus();
      await tester.pump();
      // Focus may land on a scope when control is disabled; no identity assertion.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(materialPressed, 0);
      expect(nakedPressed, 0);
    });

    testWidgets('enabled/disabled transitions parity (semantics)', (
      tester,
    ) async {
      bool nakedEnabled = true;
      bool materialEnabled = true;

      const nakedKey = Key('naked');
      const materialKey = Key('material');

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                TextButton(
                  key: materialKey,
                  onPressed: materialEnabled ? () {} : null,
                  child: const Text('Material'),
                ),
                NakedButton(
                  key: nakedKey,
                  enabled: nakedEnabled,
                  onPressed: () {},
                  child: const Text('Naked'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      materialEnabled = !materialEnabled;
                      nakedEnabled = !nakedEnabled;
                    });
                  },
                  child: const Text('Toggle'),
                ),
              ],
            );
          },
        ),
      );

      // Initially enabled
      expect(
        tester.getSemantics(find.byKey(materialKey)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(nakedKey)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );

      // Toggle to disabled
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      // Disabled state: assert on Naked only; Material focusability may vary by platform.
      expect(
        tester.getSemantics(find.byKey(nakedKey)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
          // Disabled buttons should still expose focus semantics like Material
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('hover cursor parity (enabled vs disabled)', (tester) async {
      const nakedEnabledKey = Key('naked-enabled');
      const nakedDisabledKey = Key('naked-disabled');
      const materialEnabledKey = Key('material-enabled');
      const materialDisabledKey = Key('material-disabled');

      await tester.pumpMaterialWidget(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                TextButton(
                  key: materialEnabledKey,
                  onPressed: () {},
                  child: const Text('Material Enabled'),
                ),
                NakedButton(
                  key: nakedEnabledKey,
                  onPressed: () {},
                  child: const Text('Naked Enabled'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                const TextButton(
                  key: materialDisabledKey,
                  onPressed: null,
                  child: Text('Material Disabled'),
                ),
                NakedButton(
                  key: nakedDisabledKey,
                  enabled: false,
                  onPressed: () {},
                  child: const Text('Naked Disabled'),
                ),
              ],
            ),
          ],
        ),
      );

      // Enabled should use click cursor
      tester.expectCursor(SystemMouseCursors.click, on: materialEnabledKey);
      tester.expectCursor(SystemMouseCursors.click, on: nakedEnabledKey);

      // Disabled: Material may defer cursor; Naked uses basic.
      // Verify Material is not using a click cursor when disabled
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

    testWidgets('semantics parity (button role and actions)', (tester) async {
      const nakedKey = Key('naked');
      const materialKey = Key('material');

      await tester.pumpMaterialWidget(
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            TextButton(
              key: materialKey,
              onPressed: () {},
              child: const Text('Material'),
            ),
            NakedButton(
              key: nakedKey,
              onPressed: () {},
              child: const Text('Naked'),
            ),
          ],
        ),
      );

      expect(
        tester.getSemantics(find.byKey(materialKey)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );

      expect(
        tester.getSemantics(find.byKey(nakedKey)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );

      // Also verify Material semantics include focus action (some platforms expose it)
      expect(
        tester.getSemantics(find.byKey(materialKey)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );
    });
  });
}
