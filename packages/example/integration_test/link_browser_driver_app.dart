import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  enableFlutterDriverExtension();
  SemanticsBinding.instance.ensureSemantics();
  runApp(const _LinkBrowserDriverApp());
}

class _LinkBrowserDriverApp extends StatefulWidget {
  const _LinkBrowserDriverApp();

  @override
  State<_LinkBrowserDriverApp> createState() => _LinkBrowserDriverAppState();
}

class _LinkBrowserDriverAppState extends State<_LinkBrowserDriverApp> {
  var _customObserverCalls = 0;
  var _customResolverCalls = 0;
  var _dynamicObserverCalls = 0;
  var _dynamicResolverCalls = 0;
  var _dynamicEnabled = true;

  Uri _destination(String marker) => Uri.base.replace(
    queryParameters: {'link-destination': marker},
    fragment: '',
  );

  NakedLinkResolution _resolveLink(BuildContext context, Uri linkUrl) {
    switch (linkUrl.queryParameters['link-destination']) {
      case 'naked-link-browser-custom':
        setState(() => _customResolverCalls++);
        return NakedLinkResolution.handled;
      case 'naked-link-browser-dynamic':
        setState(() => _dynamicResolverCalls++);
        return NakedLinkResolution.handled;
      default:
        return NakedLinkResolution.platformDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: NakedLinkResolver(
            resolve: _resolveLink,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedLink(
                  linkUrl: _destination('naked-link-browser-default'),
                  child: const Text('Default navigation'),
                ),
                NakedLink(
                  linkUrl: _destination('naked-link-browser-custom'),
                  onActivated: (_) {
                    setState(() => _customObserverCalls++);
                  },
                  child: const Text('Custom navigation'),
                ),
                NakedLink(
                  enabled: _dynamicEnabled,
                  linkUrl: _destination('naked-link-browser-dynamic'),
                  onActivated: (_) {
                    setState(() => _dynamicObserverCalls++);
                  },
                  child: const Text('Dynamic navigation'),
                ),
                Text(
                  'custom:observer=$_customObserverCalls;'
                  'resolver=$_customResolverCalls',
                  key: const ValueKey('browser-link.custom-result'),
                ),
                Text(
                  'dynamic:observer=$_dynamicObserverCalls;'
                  'resolver=$_dynamicResolverCalls;enabled=$_dynamicEnabled',
                  key: const ValueKey('browser-link.dynamic-result'),
                ),
                TextButton(
                  key: const ValueKey('browser-link.disable-dynamic'),
                  onPressed: _dynamicEnabled
                      ? () => setState(() => _dynamicEnabled = false)
                      : null,
                  child: const Text('Disable dynamic Link'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
