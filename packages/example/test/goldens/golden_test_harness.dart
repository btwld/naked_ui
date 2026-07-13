import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const goldenSurfaceSize = Size(800, 600);
const goldenDevicePixelRatio = 1.0;
const goldenFontFamily = 'GoldenRoboto';

/// Loads the pinned text and icon fonts used by every example golden.
Future<void> loadGoldenTestFont() async {
  final packageRelative = File('test/goldens/fonts/Roboto-Regular.ttf');
  final workspaceRelative = File(
    'packages/example/test/goldens/fonts/Roboto-Regular.ttf',
  );
  final fontFile = packageRelative.existsSync()
      ? packageRelative
      : workspaceRelative;
  if (!fontFile.existsSync()) {
    throw StateError('Unable to locate the checked-in golden Roboto font.');
  }
  await _loadFont(goldenFontFamily, fontFile);

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final executableFlutterRoot = File(
    Platform.resolvedExecutable,
  ).parent.parent.parent.parent.parent.path;
  final materialIconsCandidates = [
    if (flutterRoot != null)
      File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf',
      ),
    File(
      '$executableFlutterRoot/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf',
    ),
  ];
  final materialIcons = materialIconsCandidates
      .where((candidate) => candidate.existsSync())
      .firstOrNull;
  if (materialIcons == null) {
    throw StateError(
      'Unable to locate MaterialIcons-Regular.otf in the pinned Flutter SDK.',
    );
  }
  await _loadFont('MaterialIcons', materialIcons);
}

Future<void> _loadFont(String family, File file) async {
  final bytes = await file.readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// Pumps a canonical deterministic surface for component golden tests.
Future<void> pumpGoldenSurface(
  WidgetTester tester, {
  required Widget child,
  Brightness brightness = Brightness.light,
  Key? surfaceKey,
}) async {
  tester.view.physicalSize = goldenSurfaceSize;
  tester.view.devicePixelRatio = goldenDevicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  FocusManager.instance.primaryFocus?.unfocus();
  Widget app = MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en', 'US'),
    theme: ThemeData(
      brightness: brightness,
      fontFamily: goldenFontFamily,
      useMaterial3: true,
    ),
    home: MediaQuery(
      data: MediaQueryData(
        size: goldenSurfaceSize,
        devicePixelRatio: goldenDevicePixelRatio,
        textScaler: TextScaler.noScaling,
        platformBrightness: brightness,
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        systemGestureInsets: EdgeInsets.zero,
        disableAnimations: true,
        accessibleNavigation: false,
        boldText: false,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: TickerMode(
          enabled: false,
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            body: Center(child: child),
          ),
        ),
      ),
    ),
  );
  if (surfaceKey != null) {
    app = RepaintBoundary(key: surfaceKey, child: app);
  }
  await tester.pumpWidget(app);
  await tester.pump();
}
