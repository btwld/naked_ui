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
  var _customActivations = 0;
  var _dynamicActivations = 0;
  var _dynamicEnabled = true;

  Uri _destination(String fragment) => Uri.base.replace(fragment: fragment);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedLink(
                linkUrl: _destination('naked-link-browser-default'),
                child: const Text('Default navigation'),
              ),
              NakedLink(
                linkUrl: _destination('naked-link-browser-custom'),
                onPressed: () {
                  setState(() => _customActivations++);
                },
                child: const Text('Custom navigation'),
              ),
              NakedLink(
                enabled: _dynamicEnabled,
                linkUrl: _destination('naked-link-browser-dynamic'),
                onPressed: () {
                  setState(() => _dynamicActivations++);
                },
                child: const Text('Dynamic navigation'),
              ),
              Text(
                'custom:$_customActivations',
                key: const ValueKey('browser-link.custom-result'),
              ),
              Text(
                'dynamic:$_dynamicActivations; enabled:$_dynamicEnabled',
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
    );
  }
}
