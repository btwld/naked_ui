import 'dart:io';

import 'package:example/api/naked_link.0.dart' as link_example;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden_test_harness.dart';

void main() {
  setUpAll(loadGoldenTestFont);

  testWidgets(
    'canonical Link keyboard focus matches its reference golden',
    (tester) async {
      await pumpGoldenSurface(tester, child: const link_example.LinkExample());

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.pump();
      expect(
        find.text('hovered:false focused:true pressed:false enabled:true'),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(const ValueKey('link.evidence.surface')),
        matchesGoldenFile('baselines/naked_link__keyboard_focus.png'),
      );
    },
    // Skia text rasterization is host-specific. CI pins this golden to Ubuntu
    // 24.04; other platforms skip the incompatible pixel comparison.
    skip: !Platform.isLinux,
  );
}
