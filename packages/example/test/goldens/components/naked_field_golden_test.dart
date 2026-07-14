import 'dart:io';

import 'package:example/api/naked_field.0.dart' as field_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden_test_harness.dart';

void main() {
  setUpAll(loadGoldenTestFont);

  testWidgets(
    'canonical Field invalid state matches its reference golden',
    (tester) async {
      const goldenKey = ValueKey('field.golden.surface');
      await pumpGoldenSurface(
        tester,
        surfaceKey: goldenKey,
        child: const field_example.FieldExample(),
      );

      await tester.tap(find.byKey(field_example.fieldEmailSubmitKey));
      await tester.pump();
      expect(find.text('Enter an email address.'), findsOneWidget);

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('baselines/naked_field__invalid.png'),
      );
    },
    // Skia text rasterization is host-specific. CI generates and compares this
    // candidate only on the authoritative Ubuntu 24.04 host.
    skip: !Platform.isLinux,
  );
}
