import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

String get screenshotTarget => 'unsupported';

bool get screenshotReturnsBytes => false;

Future<void> prepareScreenshotSurface(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  throw UnsupportedError('Screenshots are unsupported on this platform.');
}

Future<List<int>> takePlatformScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String screenshotName, {
  Finder? surface,
}) async {
  throw UnsupportedError('Screenshots are unsupported on this platform.');
}
