import 'dart:async';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:webdriver/async_io.dart';

const _anchorSelector = By.cssSelector('a[rel="noreferrer noopener"]');

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  try {
    await driver.waitFor(
      find.byValueKey('browser-link.custom-result'),
      timeout: const Duration(seconds: 10),
    );

    final webDriver = driver.webDriver;
    final anchors = await _waitForAnchors(webDriver);
    await _anchorFor(anchors, 'naked-link-browser-default');
    final customAnchor = await _anchorFor(anchors, 'naked-link-browser-custom');
    await _anchorFor(anchors, 'naked-link-browser-dynamic');
    final originalWindow = await webDriver.window;
    final originalWindowIds = await _windowIds(webDriver);
    final originalUrl = Uri.parse(await webDriver.currentUrl);
    stdout.writeln(
      'Native Link hrefs: ${await Future.wait(anchors.map((anchor) => anchor.attributes['href']))}',
    );

    await _captureNextClickTrust(webDriver);
    await _click(webDriver, customAnchor);
    await driver.waitFor(
      find.text('custom:1'),
      timeout: const Duration(seconds: 5),
    );
    await _expectNoNavigation(
      webDriver,
      originalWindow,
      originalWindowIds,
      originalUrl,
      'A custom callback must suppress native browser navigation.',
    );
    await _expectTrustedClick(webDriver, 'custom Link');

    await driver.tap(find.byValueKey('browser-link.disable-dynamic'));
    await driver.waitFor(
      find.text('dynamic:0; enabled:false'),
      timeout: const Duration(seconds: 5),
    );
    await _waitForAnchorRemoval(webDriver, 'naked-link-browser-dynamic');
    await driver.tap(find.text('Dynamic navigation'));
    await driver.waitFor(
      find.text('dynamic:0; enabled:false'),
      timeout: const Duration(seconds: 5),
    );
    await _expectNoNavigation(
      webDriver,
      originalWindow,
      originalWindowIds,
      originalUrl,
      'A disabled Link must not navigate.',
    );

    stdout.writeln('Trusted browser Link ownership checks passed.');
  } finally {
    await driver.close();
  }
}

Future<List<WebElement>> _waitForAnchors(WebDriver driver) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    final anchors = await driver.findElements(_anchorSelector).toList();
    if (anchors.length == 3) {
      final hrefs = await Future.wait(
        anchors.map((anchor) => anchor.attributes['href']),
      );
      if (hrefs.every((href) => href != null)) return anchors;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('Timed out waiting for the three native Link anchors.');
}

Future<WebElement> _anchorFor(List<WebElement> anchors, String marker) async {
  for (final anchor in anchors) {
    final href = await anchor.attributes['href'];
    if (href?.contains(marker) ?? false) return anchor;
  }
  throw StateError('No native Link anchor contained $marker.');
}

Future<void> _click(WebDriver driver, WebElement anchor) async {
  await driver.mouse.moveToElementCenter(anchor);
  await driver.mouse.click();
}

Future<void> _captureNextClickTrust(WebDriver driver) {
  return driver.execute(
    'window.__nakedLinkClickTrusted = null; '
    'window.addEventListener("click", function(event) { '
    'window.__nakedLinkClickTrusted = event.isTrusted; '
    '}, {capture: true, once: true});',
    const [],
  );
}

Future<void> _expectTrustedClick(WebDriver driver, String description) async {
  final isTrusted = await driver.execute(
    'return window.__nakedLinkClickTrusted;',
    const [],
  );
  if (isTrusted != true) {
    throw StateError('The $description click was not a trusted browser event.');
  }
}

Future<void> _waitForAnchorRemoval(WebDriver driver, String marker) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    final anchors = await driver.findElements(_anchorSelector).toList();
    var markerFound = false;
    for (final anchor in anchors) {
      final href = await anchor.attributes['href'];
      if (href?.contains(marker) ?? false) markerFound = true;
    }
    if (!markerFound && anchors.length == 2) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('The disabled native Link anchor was not removed.');
}

Future<Set<String>> _windowIds(WebDriver driver) async =>
    (await driver.windows.toList()).map((window) => window.id).toSet();

Future<void> _expectNoNavigation(
  WebDriver driver,
  Window originalWindow,
  Set<String> expectedWindowIds,
  Uri expectedUrl,
  String message,
) async {
  final actualWindowIds = await _windowIds(driver);
  if (actualWindowIds.length != expectedWindowIds.length ||
      !actualWindowIds.containsAll(expectedWindowIds)) {
    throw StateError(
      '$message Expected windows $expectedWindowIds, got $actualWindowIds.',
    );
  }
  await originalWindow.setAsActive();
  final actualUrl = Uri.parse(await driver.currentUrl);
  if (actualUrl != expectedUrl) {
    throw StateError('$message Expected $expectedUrl, got $actualUrl.');
  }
}
