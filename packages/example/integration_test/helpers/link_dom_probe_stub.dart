bool get supportsLinkDomProbe => false;

Uri? get currentBrowserUri => null;

bool hasLinkHrefContaining(String marker) => false;

typedef LinkClickResult = ({bool defaultPrevented, Uri resultingUri});

Future<LinkClickResult?> dispatchSyntheticLinkClick(String marker) async =>
    null;

void restoreBrowserUri(Uri uri) {}
