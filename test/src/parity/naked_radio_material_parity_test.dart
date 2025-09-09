import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/simulate_hover.dart';

void main() {
  group('Material Parity - Radio', () {
    testWidgets('basic tap response parity (select within group)', (
      tester,
    ) async {
      String? mValue = 'b';
      String? nValue = 'b';

      const mA = Key('m-a');
      const mB = Key('m-b');
      const nA = Key('n-a');
      const nB = Key('n-b');

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 48,
              children: [
                // Material group
                RadioGroup<String>(
                  groupValue: mValue,
                  onChanged: (v) => setState(() => mValue = v),
                  child: Row(
                    key: const Key('material'),
                    mainAxisSize: MainAxisSize.min,
                    spacing: 24,
                    children: [
                      Radio<String>(key: mA, value: 'a'),
                      Radio<String>(key: mB, value: 'b'),
                    ],
                  ),
                ),
                // Naked group
                RadioGroup<String>(
                  groupValue: nValue,
                  onChanged: (v) => setState(() => nValue = v),
                  child: Row(
                    key: const Key('naked'),
                    mainAxisSize: MainAxisSize.min,
                    spacing: 24,
                    children: [
                      NakedRadio<String>(
                        key: nA,
                        value: 'a',
                        child: const SizedBox(width: 20, height: 20),
                      ),
                      NakedRadio<String>(
                        key: nB,
                        value: 'b',
                        child: const SizedBox(width: 20, height: 20),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Initial
      expect(mValue, 'b');
      expect(nValue, 'b');

      // Select 'a' on both
      await tester.tap(find.byKey(mA));
      await tester.pump();
      await tester.tap(find.byKey(nA));
      await tester.pump();
      expect(mValue, 'a');
      expect(nValue, 'a');

      // Select 'b' on both
      await tester.tap(find.byKey(mB));
      await tester.pump();
      await tester.tap(find.byKey(nB));
      await tester.pump();
      expect(mValue, 'b');
      expect(nValue, 'b');
    });

    testWidgets('keyboard activation parity (Space selects; no toggle)', (
      tester,
    ) async {
      String? mValue = 'a';
      String? nValue = 'a';

      final mFocusA = FocusNode();
      final mFocusB = FocusNode();
      final nFocusA = FocusNode();
      final nFocusB = FocusNode();
      addTearDown(() {
        mFocusA.dispose();
        mFocusB.dispose();
        nFocusA.dispose();
        nFocusB.dispose();
      });

      const mA = Key('m-a');
      const mB = Key('m-b');
      const nA = Key('n-a');
      const nB = Key('n-b');

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 48,
              children: [
                RadioGroup<String>(
                  groupValue: mValue,
                  onChanged: (v) => setState(() => mValue = v),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 24,
                    children: [
                      Radio<String>(key: mA, value: 'a', focusNode: mFocusA),
                      Radio<String>(key: mB, value: 'b', focusNode: mFocusB),
                    ],
                  ),
                ),
                RadioGroup<String>(
                  groupValue: nValue,
                  onChanged: (v) => setState(() => nValue = v),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 24,
                    children: [
                      NakedRadio<String>(
                        key: nA,
                        value: 'a',
                        focusNode: nFocusA,
                        child: const SizedBox(width: 20, height: 20),
                      ),
                      NakedRadio<String>(
                        key: nB,
                        value: 'b',
                        focusNode: nFocusB,
                        child: const SizedBox(width: 20, height: 20),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Focus 'b' (unselected) and press Space => select it
      mFocusB.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      nFocusB.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(mValue, 'b');
      expect(nValue, 'b');

      // Press Space again on selected 'b' => no change (non-toggleable)
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(mValue, 'b');
      expect(nValue, 'b');
    });

    testWidgets('disabled blocking parity (tap and keyboard)', (tester) async {
      bool enabledMaterial = false;
      bool enabledNaked = false;
      String? mValue = 'a';
      String? nValue = 'a';

      final mFocusA = FocusNode();
      final nFocusA = FocusNode();
      addTearDown(() {
        mFocusA.dispose();
        nFocusA.dispose();
      });

      const mA = Key('m-a');
      const nA = Key('n-a');

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 48,
              children: [
                RadioGroup<String>(
                  groupValue: mValue,
                  onChanged: (v) => setState(() => mValue = v),
                  child: Radio<String>(
                    key: mA,
                    value: 'a',
                    focusNode: mFocusA,
                    enabled: enabledMaterial,
                  ),
                ),
                RadioGroup<String>(
                  groupValue: nValue,
                  onChanged: (v) => setState(() => nValue = v),
                  child: NakedRadio<String>(
                    key: nA,
                    value: 'a',
                    focusNode: nFocusA,
                    enabled: enabledNaked,
                    child: const SizedBox(width: 20, height: 20),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    enabledMaterial = !enabledMaterial;
                    enabledNaked = !enabledNaked;
                  }),
                  child: const Text('Toggle'),
                ),
              ],
            );
          },
        ),
      );

      // Disabled: no tap or space changes
      await tester.tap(find.byKey(mA));
      await tester.pump();
      await tester.tap(find.byKey(nA));
      await tester.pump();
      expect(mValue, 'a');
      expect(nValue, 'a');

      mFocusA.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      nFocusA.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(mValue, 'a');
      expect(nValue, 'a');

      // Enable and verify interactions (space)
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space); // on nFocusA
      await tester.pump();
      expect(nValue, 'a'); // already selected; no toggle

      mFocusA.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(mValue, 'a'); // already selected; no toggle
    });

    testWidgets('enabled/disabled transitions parity (semantics)', (
      tester,
    ) async {
      bool enabledMaterial = true;
      bool enabledNaked = true;
      String? mValue = 'a';
      String? nValue = 'a';

      const mKey = Key('material');
      const nKey = Key('naked');

      await tester.pumpMaterialWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 48,
              children: [
                RadioGroup<String>(
                  groupValue: mValue,
                  onChanged: (v) => setState(() => mValue = v),
                  child: Radio<String>(
                    key: mKey,
                    value: 'a',
                    enabled: enabledMaterial,
                  ),
                ),
                RadioGroup<String>(
                  groupValue: nValue,
                  onChanged: (v) => setState(() => nValue = v),
                  child: NakedRadio<String>(
                    key: nKey,
                    value: 'a',
                    enabled: enabledNaked,
                    child: const SizedBox(width: 20, height: 20),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    enabledMaterial = !enabledMaterial;
                    enabledNaked = !enabledNaked;
                  }),
                  child: const Text('Toggle'),
                ),
              ],
            );
          },
        ),
      );

      // TEMP: dump semantics tree for debugging NakedRadio
      rendering.debugDumpSemanticsTree();

      // Initially enabled
      expect(
        tester.getSemantics(find.byKey(mKey)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );

      // Naked side: expect same merged semantics as Material
      expect(
        tester.getSemantics(find.byKey(nKey)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );

      // Disable
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(
        tester.getSemantics(find.byKey(nKey)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: false,
          isFocusable: true,
        ),
      );
    });

    testWidgets('hover cursor parity (enabled vs disabled)', (tester) async {
      const mEnabledKey = Key('m-enabled');
      const mDisabledKey = Key('m-disabled');
      const nEnabledKey = Key('n-enabled');
      const nDisabledKey = Key('n-disabled');

      await tester.pumpMaterialWidget(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                RadioGroup<String>(
                  groupValue: 'a',
                  onChanged: (_) {},
                  child: Radio<String>(key: mEnabledKey, value: 'a'),
                ),
                RadioGroup<String>(
                  groupValue: 'a',
                  onChanged: (_) {},
                  child: NakedRadio<String>(
                    key: nEnabledKey,
                    value: 'a',
                    child: const SizedBox(width: 20, height: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                RadioGroup<String>(
                  groupValue: 'a',
                  onChanged: (_) {},
                  child: Radio<String>(
                    key: mDisabledKey,
                    value: 'a',
                    enabled: false,
                  ),
                ),
                RadioGroup<String>(
                  groupValue: 'a',
                  onChanged: (_) {},
                  child: NakedRadio<String>(
                    key: nDisabledKey,
                    value: 'a',
                    enabled: false,
                    child: const SizedBox(width: 20, height: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      tester.expectCursor(SystemMouseCursors.click, on: mEnabledKey);
      tester.expectCursor(SystemMouseCursors.click, on: nEnabledKey);

      final materialDisabledRegion = tester.widget<MouseRegion>(
        find
            .descendant(
              of: find.byKey(mDisabledKey),
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
      tester.expectCursor(SystemMouseCursors.basic, on: nDisabledKey);
    });

    testWidgets('semantics parity (selected/unselected actions)', (
      tester,
    ) async {
      const mA = Key('m-a');
      const mB = Key('m-b');
      const nA = Key('n-a');
      const nB = Key('n-b');

      await tester.pumpMaterialWidget(
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 48,
          children: [
            // Material
            StatefulBuilder(
              builder: (context, setState) {
                String? mValue = 'a';
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 24,
                  children: [
                    RadioGroup<String>(
                      groupValue: mValue,
                      onChanged: (v) => setState(() => mValue = v),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 24,
                        children: [
                          Radio<String>(key: mA, value: 'a'),
                          Radio<String>(key: mB, value: 'b'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            // Naked
            StatefulBuilder(
              builder: (context, setState) {
                String? nValue = 'a';
                return RadioGroup<String>(
                  groupValue: nValue,
                  onChanged: (v) => setState(() => nValue = v),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 24,
                    children: [
                      NakedRadio<String>(
                        key: nA,
                        value: 'a',
                        child: const SizedBox(width: 20, height: 20),
                      ),
                      NakedRadio<String>(
                        key: nB,
                        value: 'b',
                        child: const SizedBox(width: 20, height: 20),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );

      // TEMP: dump semantics tree for debugging NakedRadio (multi-item)
      rendering.debugDumpSemanticsTree();

      expect(
        tester.getSemantics(find.byKey(mA)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );

      expect(
        tester.getSemantics(find.byKey(nA)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );

      expect(
        tester.getSemantics(find.byKey(mB)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );

      expect(
        tester.getSemantics(find.byKey(nB)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
    });
    testWidgets('Material Parity - Radio group-of-one semantics parity', (
      tester,
    ) async {
      final mKey = UniqueKey();
      final nKey = UniqueKey();

      await tester.pumpMaterialWidget(
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            // Material: group of one
            RadioGroup<String>(
              groupValue: 'a',
              onChanged: (_) {},
              child: Radio<String>(key: mKey, value: 'a'),
            ),
            // Naked: group of one
            RadioGroup<String>(
              groupValue: 'a',
              onChanged: (_) {},
              child: NakedRadio<String>(
                key: nKey,
                value: 'a',
                child: const SizedBox(width: 20, height: 20),
              ),
            ),
          ],
        ),
      );
      // TEMP: dump semantics tree for debugging NakedRadio (group of one)
      rendering.debugDumpSemanticsTree();

      expect(
        tester.getSemantics(find.byKey(mKey)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );

      expect(
        tester.getSemantics(find.byKey(nKey)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
    });
  });
}
