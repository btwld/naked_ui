import 'dart:io';

import 'package:example/api/naked_toggle.0.dart' as toggle_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../golden_test_harness.dart';

void main() {
  setUpAll(loadGoldenTestFont);

  testWidgets(
    'focused option paints its final border when animations are disabled',
    (tester) async {
      await pumpGoldenSurface(
        tester,
        child: const toggle_example.ToggleGroupExample(),
      );

      final italicFinder = find.byKey(const Key('toggle-group.option.italic'));
      final italicOption = tester.widget<NakedToggleOption<String>>(
        italicFinder,
      );
      italicOption.focusNode!.requestFocus();
      await tester.pumpAndSettle();

      expect(italicOption.focusNode!.hasPrimaryFocus, isTrue);
      final paintedDecoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: italicFinder,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(
        paintedDecoration.border,
        Border.all(color: Colors.blue.shade600, width: 2),
      );
    },
  );

  testWidgets(
    'canonical toggle group focus matches its reference golden',
    (tester) async {
      const goldenKey = ValueKey('toggle-group.golden.surface');
      await pumpGoldenSurface(
        tester,
        child: const SizedBox(
          width: 520,
          height: 360,
          child: RepaintBoundary(
            key: goldenKey,
            child: ColoredBox(
              color: Colors.white,
              child: Center(child: toggle_example.ToggleGroupExample()),
            ),
          ),
        ),
      );

      final italicOption = tester.widget<NakedToggleOption<String>>(
        find.byKey(const Key('toggle-group.option.italic')),
      );
      italicOption.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(italicOption.focusNode!.hasPrimaryFocus, isTrue);

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('baselines/naked_toggle_group__focus.png'),
      );
    },
    // Skia text rasterization is host-specific. CI pins this golden to Ubuntu
    // 24.04; macOS must not generate or approve the reference pixels.
    skip: !Platform.isLinux,
  );
}
