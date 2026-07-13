import 'package:web/web.dart' as web;

bool get supportsLinkDomProbe => true;

Uri get currentBrowserUri => Uri.parse(web.window.location.href);

web.Element? _findLink(String marker) {
  final nativeAnchor = _findAnchor(
    web.document.querySelectorAll('a[rel="noreferrer noopener"]'),
    marker,
  );
  return nativeAnchor ??
      _findAnchor(web.document.querySelectorAll('a'), marker);
}

web.Element? _findAnchor(web.NodeList anchors, String marker) {
  for (var index = 0; index < anchors.length; index++) {
    final anchor = anchors.item(index)! as web.Element;
    if (anchor.getAttribute('href')?.contains(marker) ?? false) {
      return anchor;
    }
  }
  return null;
}

bool hasLinkHrefContaining(String marker) => _findLink(marker) != null;

typedef LinkClickResult = ({bool defaultPrevented, Uri resultingUri});

/// Dispatches a synthetic DOM event to inspect the Link coordinator signal.
///
/// Resulting-location ownership for custom callbacks is verified separately by
/// the WebDriver test because synthetic anchor default actions do not model the
/// coordinator's microtask timing reliably.
Future<LinkClickResult?> dispatchSyntheticLinkClick(String marker) async {
  final anchor = _findLink(marker);
  if (anchor == null) return null;

  final originalUri = currentBrowserUri;
  final event = web.MouseEvent(
    'click',
    web.MouseEventInit(bubbles: true, cancelable: true),
  );
  anchor.dispatchEvent(event);
  await Future<void>.delayed(Duration.zero);
  final resultingUri = currentBrowserUri;
  restoreBrowserUri(originalUri);
  return (defaultPrevented: event.defaultPrevented, resultingUri: resultingUri);
}

void restoreBrowserUri(Uri uri) {
  web.window.history.replaceState(null, '', uri.toString());
}
