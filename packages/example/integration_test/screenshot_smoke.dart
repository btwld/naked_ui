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
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    expect(
      tester.getSize(find.byKey(screenshotSurfaceKey)),
      const Size(800, 600),
    );
    await tester.captureEvidenceScreenshot(
      binding,
      ScreenshotEvidence(
        component: 'dialog',
        scenario: 'open',
        animationMode: 'fixed 400ms transition, settled',
      ),
      surface: find.byKey(screenshotSurfaceKey),
    );
  });
}
