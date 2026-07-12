import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

String get screenshotTarget => 'web';

bool get screenshotReturnsBytes => false;

Future<void> prepareScreenshotSurface(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {}

Future<List<int>> takePlatformScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String screenshotName, {
  Finder? surface,
}) async {
  throw UnsupportedError(
    'Flutter 3.41.2 cannot produce stable web screenshot evidence; '
    'run the blocking web behavior aggregate instead.',
  );
}
