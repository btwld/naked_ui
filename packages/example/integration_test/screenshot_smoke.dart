import 'dart:io';

import 'package:example/api/naked_dialog.0.dart' as dialog_example;
import 'package:example/api/naked_link.0.dart' as link_example;
import 'package:example/src/testing/screenshot_evidence.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
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

  testWidgets('Link default inline screenshot evidence', (tester) async {
    final screenshotSurface = await _pumpLinkSurface(
      tester,
      const link_example.LinkExample(),
    );
    expect(find.byKey(const ValueKey('link.primary')), findsOneWidget);

    await _captureLinkEvidence(
      tester,
      binding,
      screenshotSurface,
      scenario: 'default_inline',
    );
  });

  testWidgets('Link screenshot surface respects safe insets', (tester) async {
    const viewPadding = FakeViewPadding(top: 24, bottom: 16);
    tester.view.padding = viewPadding;
    tester.view.viewPadding = viewPadding;
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final screenshotSurface = await _pumpLinkSurface(
      tester,
      const link_example.LinkExample(),
    );
    final logicalPadding = EdgeInsets.fromViewPadding(
      tester.view.padding,
      tester.view.devicePixelRatio,
    );
    final logicalViewSize =
        tester.view.physicalSize / tester.view.devicePixelRatio;

    expect(tester.getTopLeft(screenshotSurface).dy, logicalPadding.top);
    expect(
      tester.getBottomRight(screenshotSurface).dy,
      logicalViewSize.height - logicalPadding.bottom,
    );
  });

  testWidgets('Link keyboard focus screenshot evidence', (tester) async {
    final screenshotSurface = await _pumpLinkSurface(
      tester,
      const link_example.LinkExample(),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump();
    expect(
      find.text('hovered:false focused:true pressed:false enabled:true'),
      findsOneWidget,
    );

    await _captureLinkEvidence(
      tester,
      binding,
      screenshotSurface,
      scenario: 'keyboard_focus',
    );
  });

  testWidgets('Link disabled screenshot evidence', (tester) async {
    final screenshotSurface = await _pumpLinkSurface(
      tester,
      const link_example.LinkExample(),
    );
    final semantics = tester.ensureSemantics();
    try {
      final disabled = tester
          .getSemantics(find.text('Unavailable documentation'))
          .getSemanticsData();
      expect(disabled.flagsCollection.isLink, isTrue);
      expect(disabled.hasAction(SemanticsAction.tap), isFalse);
    } finally {
      semantics.dispose();
    }

    await _captureLinkEvidence(
      tester,
      binding,
      screenshotSurface,
      scenario: 'disabled',
    );
  });

  testWidgets('Link 200% long text screenshot evidence', (tester) async {
    final screenshotSurface = await _pumpLinkSurface(
      tester,
      const link_example.LinkExample(textScale: 2, longText: true),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('complete accessibility guide'), findsOneWidget);

    await _captureLinkEvidence(
      tester,
      binding,
      screenshotSurface,
      scenario: 'long_text_200',
      textScale: 2,
    );
  });
}

Future<Finder> _pumpLinkSurface(WidgetTester tester, Widget child) async {
  final usesNativeSurface = Platform.isAndroid || Platform.isIOS;
  if (!usesNativeSurface) {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(child: SizedBox.expand(child: child)),
      ),
    ),
  );
  await tester.pump();
  final screenshotSurface = find.byKey(const ValueKey('link.evidence.surface'));
  expect(screenshotSurface, findsOneWidget);
  if (!usesNativeSurface) {
    final logicalPadding = EdgeInsets.fromViewPadding(
      tester.view.padding,
      tester.view.devicePixelRatio,
    );
    final logicalViewSize =
        tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(
      tester.getSize(screenshotSurface),
      Size(
        logicalViewSize.width - logicalPadding.horizontal,
        logicalViewSize.height - logicalPadding.vertical,
      ),
    );
  }
  return screenshotSurface;
}

Future<void> _captureLinkEvidence(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Finder screenshotSurface, {
  required String scenario,
  double textScale = 1,
}) async {
  final logicalSize = tester.getSize(screenshotSurface);
  await tester.captureEvidenceScreenshot(
    binding,
    ScreenshotEvidence(
      component: 'link',
      scenario: scenario,
      surface: '${logicalSize.width}x${logicalSize.height} logical pixels',
      devicePixelRatio: tester.view.devicePixelRatio,
      textScale: textScale,
      animationMode: 'disabled',
    ),
    surface: screenshotSurface,
  );
}
