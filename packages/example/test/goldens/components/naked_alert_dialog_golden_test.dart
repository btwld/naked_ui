import 'dart:io';

import 'package:example/api/naked_dialog.0.dart' as dialog_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../golden_test_harness.dart';

void main() {
  setUpAll(loadGoldenTestFont);

  testWidgets(
    'canonical alert dialog open state matches its reference golden',
    (tester) async {
      const goldenKey = ValueKey('alert-dialog.golden.surface');
      await pumpGoldenSurface(
        tester,
        surfaceKey: goldenKey,
        child: const dialog_example.AlertDialogExample(),
      );

      await tester.tap(find.byKey(const ValueKey('alert-dialog.open')));
      await tester.pump();
      await tester.pump();

      final cancelButton = tester.widget<NakedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('alert-dialog.cancel')),
          matching: find.byType(NakedButton),
        ),
      );
      expect(FocusManager.instance.primaryFocus, same(cancelButton.focusNode));

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('baselines/naked_alert_dialog__open_safe_focus.png'),
      );
    },
    // Skia text rasterization is host-specific. CI pins this golden to Ubuntu
    // 24.04; other platforms skip the incompatible pixel comparison.
    skip: !Platform.isLinux,
  );
}
