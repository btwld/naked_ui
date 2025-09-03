import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'registry.dart';
import 'shell/shell.dart';

void main() {
  if (kIsWeb) {
    setUrlStrategy(const HashUrlStrategy());
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naked Kitchen Sink',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        // Expecting hash URLs on web (/#/component/<id>)
        final path = name.startsWith('/#/') ? name.substring(3) : name;
        final parts = path.split('/').where((p) => p.isNotEmpty).toList();

        if (parts.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const KitchenShell(),
          );
        }

        if (parts.length >= 2 &&
            (parts[0] == 'component' || parts[0] == 'embed')) {
          final id = parts[1];
          final demo = DemoRegistry.find(id);
          if (demo != null) {
            return MaterialPageRoute(
              builder: (_) => KitchenShell(
                initialDemoId: id,
                embed: parts[0] == 'embed',
              ),
            );
          }
        }

        // Fallback to index shell
        return MaterialPageRoute(
          builder: (_) => const KitchenShell(),
        );
      },
      home: const KitchenShell(),
    );
  }
}
