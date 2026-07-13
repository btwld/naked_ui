import 'dart:io';

import 'package:example/api/naked_button.0.dart' as button_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden_test_harness.dart';

void main() {
  setUpAll(loadGoldenTestFont);

  testWidgets(
    'canonical button matches its reference golden',
    (tester) async {
      const goldenKey = ValueKey('button.golden.surface');
      await pumpGoldenSurface(
        tester,
        child: const SizedBox(
          width: 240,
          height: 120,
          child: RepaintBoundary(
            key: goldenKey,
            child: ColoredBox(
              color: Colors.white,
              child: Center(child: button_example.ButtonExample()),
            ),
          ),
        ),
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('baselines/naked_button__default.png'),
      );
    },
    // Skia text rasterization is host-specific. CI pins this exact golden to
    // Ubuntu 24.04; other platforms skip the incompatible pixel comparison.
    skip: !Platform.isLinux,
  );
}
