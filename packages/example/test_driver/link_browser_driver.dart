import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:webdriver/async_io.dart';

const _semanticsAnchorSelector = By.cssSelector(
  'flt-semantics-host a:not([aria-hidden="true"])',
);
const _nativeAnchorSelector = By.cssSelector(
  'a[rel="noreferrer noopener"][aria-hidden="true"]',
);
const _w3cElementKey = 'element-6066-11e4-a52e-4f735466cecf';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  try {
    await driver.waitFor(
      find.byValueKey('browser-link.custom-result'),
      timeout: const Duration(seconds: 10),
    );

    final webDriver = driver.webDriver;
    final originalWindow = await webDriver.window;
    final originalWindowIds = await _windowIds(webDriver);
    final originalUrl = Uri.parse(await webDriver.currentUrl);
    await _expectNativeHrefs(webDriver, const [
      'naked-link-browser-default',
      'naked-link-browser-custom',
      'naked-link-browser-dynamic',
    ]);

    var semanticsAnchors = await _waitForSemanticsAnchors(webDriver);
    var customAnchor = await _anchorFor(
      semanticsAnchors,
      'naked-link-browser-custom',
    );

    await _captureNextClickTrust(webDriver);
    await _click(webDriver, customAnchor);
    await driver.waitFor(
      find.text('custom:observer=1;resolver=1'),
      timeout: const Duration(seconds: 5),
    );
    await _expectNoNavigation(
      webDriver,
      originalWindow,
      originalWindowIds,
      originalUrl,
      'A resolver-handled activation must suppress native browser navigation.',
    );
    await _expectTrustedClick(webDriver, 'resolver-handled Link');

    semanticsAnchors = await _waitForSemanticsAnchors(webDriver);
    final dynamicAnchor = await _anchorFor(
      semanticsAnchors,
      'naked-link-browser-dynamic',
    );
    await _captureNextClickTrust(webDriver);
    await _click(webDriver, dynamicAnchor);
    await driver.waitFor(
      find.text('dynamic:observer=1;resolver=1;enabled=true'),
      timeout: const Duration(seconds: 5),
    );
    await _expectNoNavigation(
      webDriver,
      originalWindow,
      originalWindowIds,
      originalUrl,
      'A dynamic resolver-handled activation must not navigate.',
    );
    await _expectTrustedClick(webDriver, 'dynamic resolver-handled Link');

    semanticsAnchors = await _waitForSemanticsAnchors(webDriver);
    customAnchor = await _anchorFor(
      semanticsAnchors,
      'naked-link-browser-custom',
    );
    await _captureNextAuxiliaryClickTrust(webDriver);
    await _auxiliaryClick(webDriver, customAnchor);
    await _expectTrustedAuxiliaryClick(webDriver, 'middle-click Link');
    await _expectAuxiliaryNavigation(
      webDriver,
      originalWindow,
      originalWindowIds,
      'naked-link-browser-custom',
    );
    await driver.waitFor(
      find.text('custom:observer=1;resolver=1'),
      timeout: const Duration(seconds: 5),
    );

    semanticsAnchors = await _waitForSemanticsAnchors(webDriver);
    customAnchor = await _anchorFor(
      semanticsAnchors,
      'naked-link-browser-custom',
    );
    await _captureNextClickTrust(webDriver);
    await _modifiedPrimaryClick(webDriver, customAnchor);
    await _expectTrustedClick(webDriver, 'modified primary Link');
    await _expectAuxiliaryNavigation(
      webDriver,
      originalWindow,
      originalWindowIds,
      'naked-link-browser-custom',
    );
    await driver.waitFor(
      find.text('custom:observer=1;resolver=1'),
      timeout: const Duration(seconds: 5),
    );

    await driver.tap(find.byValueKey('browser-link.disable-dynamic'));
    await driver.waitFor(
      find.text('dynamic:observer=1;resolver=1;enabled=false'),
      timeout: const Duration(seconds: 5),
    );
    await _waitForLinkRemoval(webDriver, 'naked-link-browser-dynamic');

    semanticsAnchors = await _waitForSemanticsAnchors(webDriver, count: 2);
    final defaultAnchor = await _anchorFor(
      semanticsAnchors,
      'naked-link-browser-default',
    );
    await _captureNextClickTrust(webDriver);
    await _click(webDriver, defaultAnchor);
    await _expectCurrentTabNavigation(
      webDriver,
      originalWindow,
      originalWindowIds,
      'naked-link-browser-default',
      'An unmodified default Link must navigate the current tab exactly once.',
    );

    await webDriver.get(originalUrl);
    semanticsAnchors = await _waitForSemanticsAnchors(webDriver);
    final keyboardAnchor = await _anchorFor(
      semanticsAnchors,
      'naked-link-browser-default',
    );
    await webDriver.execute('arguments[0].focus();', [keyboardAnchor]);
    await _captureNextKeyTrust(webDriver);
    await webDriver.keyboard.sendKeys(Keyboard.enter);
    await _expectCurrentTabNavigation(
      webDriver,
      originalWindow,
      originalWindowIds,
      'naked-link-browser-default',
      'Enter must navigate the default Link in the current tab exactly once.',
    );
    await _expectTrustedKey(webDriver, 'keyboard Enter Link');

    stdout.writeln('Trusted browser Link ownership checks passed.');
  } finally {
    await driver.close();
  }
}

Future<List<WebElement>> _waitForSemanticsAnchors(
  WebDriver driver, {
  int count = 3,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    final anchors = await driver
        .findElements(_semanticsAnchorSelector)
        .toList();
    if (anchors.length == count) {
      final hrefs = await Future.wait(
        anchors.map((anchor) => anchor.attributes['href']),
      );
      if (hrefs.every((href) => href != null)) return anchors;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  final domSnapshot = await driver.execute(r'''
    return JSON.stringify({
      anchors: Array.from(document.querySelectorAll('a')).map(
        (element) => element.outerHTML,
      ),
      linkRoles: Array.from(document.querySelectorAll('[role="link"]')).map(
        (element) => element.outerHTML,
      ),
      semanticsHosts: Array.from(
        document.querySelectorAll('flt-semantics-host'),
      ).map((element) => element.innerHTML),
    });
  ''', const []);
  throw StateError(
    'Timed out waiting for $count visible semantics Link anchors. '
    'DOM snapshot: $domSnapshot',
  );
}

Future<WebElement> _anchorFor(List<WebElement> anchors, String marker) async {
  for (final anchor in anchors) {
    final href = await anchor.attributes['href'];
    if (href?.contains(marker) ?? false) return anchor;
  }
  throw StateError('No visible semantics Link anchor contained $marker.');
}

Future<void> _expectNativeHrefs(WebDriver driver, List<String> markers) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    final anchors = await driver.findElements(_nativeAnchorSelector).toList();
    final hrefs = await Future.wait(
      anchors.map((anchor) => anchor.attributes['href']),
    );
    if (markers.every(
      (marker) => hrefs.any((href) => href?.contains(marker) ?? false),
    )) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('Timed out waiting for native Link hrefs: $markers.');
}

Future<void> _click(WebDriver driver, WebElement anchor) async {
  await driver.mouse.moveToElementCenter(anchor);
  await driver.mouse.click();
}

Future<void> _modifiedPrimaryClick(WebDriver driver, WebElement anchor) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      driver.uri.resolve('session/${driver.id}/actions'),
    );
    request.headers.contentType = ContentType.json;
    final body = utf8.encode(
      jsonEncode({
        'actions': [
          {
            'type': 'key',
            'id': 'modifier-keys',
            'actions': [
              {'type': 'keyDown', 'value': Keyboard.control},
              {'type': 'pause'},
              {'type': 'pause'},
              {'type': 'keyUp', 'value': Keyboard.control},
            ],
          },
          {
            'type': 'pointer',
            'id': 'modified-primary-pointer',
            'parameters': {'pointerType': 'mouse'},
            'actions': [
              {
                'type': 'pointerMove',
                'duration': 0,
                'origin': {_w3cElementKey: anchor.id},
                'x': 0,
                'y': 0,
              },
              {'type': 'pointerDown', 'button': MouseButton.primary.value},
              {'type': 'pointerUp', 'button': MouseButton.primary.value},
              {'type': 'pause'},
            ],
          },
        ],
      }),
    );
    request.contentLength = body.length;
    request.add(body);
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Modified primary action failed (${response.statusCode}): '
        '$responseBody',
      );
    }
  } finally {
    client.close(force: true);
  }
}

Future<void> _auxiliaryClick(WebDriver driver, WebElement anchor) async {
  final centerJson = await driver.execute(
    r'''
    const rect = arguments[0].getBoundingClientRect();
    return JSON.stringify({
      x: rect.left + rect.width / 2,
      y: rect.top + rect.height / 2,
    });
  ''',
    [anchor],
  );
  final center = jsonDecode(centerJson! as String) as Map<String, dynamic>;

  await _dispatchCdpMouseEvent(
    driver,
    type: 'mousePressed',
    x: center['x']! as num,
    y: center['y']! as num,
    buttons: 4,
  );
  await _dispatchCdpMouseEvent(
    driver,
    type: 'mouseReleased',
    x: center['x']! as num,
    y: center['y']! as num,
    buttons: 0,
  );
}

Future<void> _dispatchCdpMouseEvent(
  WebDriver driver, {
  required String type,
  required num x,
  required num y,
  required int buttons,
}) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      driver.uri.resolve('session/${driver.id}/goog/cdp/execute'),
    );
    request.headers.contentType = ContentType.json;
    final body = utf8.encode(
      jsonEncode({
        'cmd': 'Input.dispatchMouseEvent',
        'params': {
          'type': type,
          'x': x,
          'y': y,
          'button': 'middle',
          'buttons': buttons,
          'clickCount': 1,
          'pointerType': 'mouse',
        },
      }),
    );
    request.contentLength = body.length;
    request.add(body);
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'CDP $type failed (${response.statusCode}): $responseBody',
      );
    }
  } finally {
    client.close(force: true);
  }
}

Future<void> _captureNextClickTrust(WebDriver driver) {
  return driver.execute(
    'sessionStorage.setItem("__nakedLinkClickTrusted", "pending"); '
    'window.addEventListener("click", function(event) { '
    'sessionStorage.setItem("__nakedLinkClickTrusted", String(event.isTrusted)); '
    '}, {capture: true, once: true});',
    const [],
  );
}

Future<void> _captureNextAuxiliaryClickTrust(WebDriver driver) {
  return driver.execute(
    'sessionStorage.setItem("__nakedLinkAuxClickTrusted", "pending"); '
    'window.addEventListener("auxclick", function(event) { '
    'sessionStorage.setItem("__nakedLinkAuxClickTrusted", '
    'String(event.isTrusted && event.button === 1)); '
    '}, {capture: true, once: true});',
    const [],
  );
}

Future<void> _captureNextKeyTrust(WebDriver driver) {
  return driver.execute(
    'sessionStorage.setItem("__nakedLinkKeyTrusted", "pending"); '
    'window.addEventListener("keydown", function(event) { '
    'if (event.key === "Enter") { '
    'sessionStorage.setItem("__nakedLinkKeyTrusted", String(event.isTrusted)); '
    '} '
    '}, {capture: true, once: true});',
    const [],
  );
}

Future<void> _expectTrustedClick(WebDriver driver, String description) async {
  final isTrusted = await driver.execute(
    'return sessionStorage.getItem("__nakedLinkClickTrusted");',
    const [],
  );
  if (isTrusted != 'true') {
    throw StateError('The $description click was not a trusted browser event.');
  }
}

Future<void> _expectTrustedAuxiliaryClick(
  WebDriver driver,
  String description,
) async {
  final isTrusted = await driver.execute(
    'return sessionStorage.getItem("__nakedLinkAuxClickTrusted");',
    const [],
  );
  if (isTrusted != 'true') {
    throw StateError(
      'The $description did not emit a trusted middle-button auxclick.',
    );
  }
}

Future<void> _expectTrustedKey(WebDriver driver, String description) async {
  final isTrusted = await driver.execute(
    'return sessionStorage.getItem("__nakedLinkKeyTrusted");',
    const [],
  );
  if (isTrusted != 'true') {
    throw StateError('The $description key event was not trusted.');
  }
}

Future<void> _waitForLinkRemoval(WebDriver driver, String marker) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    final visible = await driver
        .findElements(_semanticsAnchorSelector)
        .toList();
    final native = await driver.findElements(_nativeAnchorSelector).toList();
    final anchors = [...visible, ...native];
    final hrefs = await Future.wait(
      anchors.map((anchor) => anchor.attributes['href']),
    );
    if (hrefs.every((href) => !(href?.contains(marker) ?? false))) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('The disabled Link retained a visible or native anchor.');
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

Future<void> _expectAuxiliaryNavigation(
  WebDriver driver,
  Window originalWindow,
  Set<String> originalWindowIds,
  String marker,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    final windows = await driver.windows.toList();
    final secondary = windows.where(
      (window) => !originalWindowIds.contains(window.id),
    );
    if (secondary.isNotEmpty) {
      final secondaryWindow = secondary.single;
      await secondaryWindow.setAsActive();
      final destination = Uri.parse(await driver.currentUrl);
      if (!destination.toString().contains(marker)) {
        throw StateError(
          'Auxiliary navigation opened $destination, not $marker.',
        );
      }
      await secondaryWindow.close();
      await originalWindow.setAsActive();
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('An auxiliary Link activation did not open a new context.');
}

Future<void> _expectCurrentTabNavigation(
  WebDriver driver,
  Window originalWindow,
  Set<String> expectedWindowIds,
  String marker,
  String message,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    final actualWindowIds = await _windowIds(driver);
    if (actualWindowIds.length == expectedWindowIds.length &&
        actualWindowIds.containsAll(expectedWindowIds)) {
      await originalWindow.setAsActive();
      final destination = Uri.parse(await driver.currentUrl);
      if (destination.toString().contains(marker)) return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  final windows = await driver.windows.toList();
  final destinations = <String, String>{};
  for (final window in windows) {
    await window.setAsActive();
    destinations[window.id] = await driver.currentUrl;
  }
  if (windows.any((window) => window.id == originalWindow.id)) {
    await originalWindow.setAsActive();
  }
  throw StateError(
    '$message Expected windows $expectedWindowIds and marker $marker; '
    'actual destinations: $destinations.',
  );
}
