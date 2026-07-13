import 'dart:io';

import 'package:example/api/naked_toggle.0.dart' as toggle_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../golden_test_harness.dart';

void main() {
  setUpAll(loadGoldenTestFont);

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
              child: Center(
                child: TickerMode(
                  enabled: true,
                  child: toggle_example.ToggleGroupExample(),
                ),
              ),
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
