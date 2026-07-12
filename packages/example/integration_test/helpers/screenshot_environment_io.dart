import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

bool _androidSurfacePrepared = false;

String get screenshotTarget {
  if (Platform.isAndroid) return 'android';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isIOS) return 'ios';
  if (Platform.isLinux) return 'linux';
  if (Platform.isWindows) return 'windows';
  return Platform.operatingSystem;
}

bool get screenshotReturnsBytes => true;

Future<void> prepareScreenshotSurface(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  if (!Platform.isAndroid || _androidSurfacePrepared) return;

  await binding.convertFlutterSurfaceToImage();
  _androidSurfacePrepared = true;
  addTearDown(() => _androidSurfacePrepared = false);
  await tester.pump();
}

Future<List<int>> takePlatformScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String screenshotName, {
  Finder? surface,
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    return binding.takeScreenshot(screenshotName);
  }

  if (surface == null) {
    throw ArgumentError(
      'Desktop screenshots require a RepaintBoundary finder.',
    );
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(surface);
  final image = await boundary.toImage(pixelRatio: 1);
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  image.dispose();
  if (byteData == null) {
    throw StateError('Desktop screenshot did not produce PNG bytes.');
  }
  final bytes = byteData.buffer.asUint8List(
    byteData.offsetInBytes,
    byteData.lengthInBytes,
  );

  // Flutter 3.41.2's integration_test package has no macOS platform entry,
  // so its native takeScreenshot method cannot be used on desktop. Preserve
  // the standard binding report protocol so the host driver writes this
  // capture exactly like Android/iOS captures.
  binding.reportData ??= <String, dynamic>{};
  final screenshots =
      binding.reportData!.putIfAbsent(
            'screenshots',
            () => <Map<String, Object>>[],
          )
          as List<dynamic>;
  screenshots.add(<String, Object>{
    'screenshotName': screenshotName,
    'bytes': bytes,
  });
  return bytes;
}
