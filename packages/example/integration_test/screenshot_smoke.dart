import 'dart:io';

import 'package:example/api/naked_dialog.0.dart' as dialog_example;
import 'package:example/src/testing/screenshot_evidence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/screenshot_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 2));

  testWidgets('dialog open screenshot evidence', (tester) async {
    const screenshotSurfaceKey = ValueKey('dialog.screenshot.surface');
    final usesNativeSurface = Platform.isAndroid || Platform.isIOS;
    if (!usesNativeSurface) {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    await tester.pumpWidget(
      const RepaintBoundary(
        key: screenshotSurfaceKey,
        child: dialog_example.MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Basic Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Action'), findsOneWidget);
    final screenshotSurface = find.byKey(screenshotSurfaceKey);
    final logicalSize = tester.getSize(screenshotSurface);
    if (!usesNativeSurface) {
      expect(logicalSize, const Size(800, 600));
    }
    await tester.captureEvidenceScreenshot(
      binding,
      ScreenshotEvidence(
        component: 'dialog',
        scenario: 'open',
        surface: '${logicalSize.width}x${logicalSize.height} logical pixels',
        devicePixelRatio: tester.view.devicePixelRatio,
        animationMode: 'fixed 400ms transition, settled',
      ),
      surface: screenshotSurface,
    );
  });
}
