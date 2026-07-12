import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  final screenshotDirectory = Directory(
    '$testOutputsDirectory/integration_test_screenshots',
  );

  await integrationDriver(
    responseDataCallback: (data) async {
      await writeResponseData(data);

      final screenshots = data?['screenshots'] as List<dynamic>?;
      if (screenshots != null) {
        await screenshotDirectory.create(recursive: true);
        for (final screenshot in screenshots) {
          final entry = screenshot as Map<String, dynamic>;
          final name = entry['screenshotName'] as String;
          final bytes = (entry['bytes'] as List<dynamic>).cast<int>();
          await _writeScreenshot(screenshotDirectory, name, bytes);
        }
      }

      final manifest = data?['screenshotManifest'];
      if (manifest != null) {
        await screenshotDirectory.create(recursive: true);
        final encoder = JsonEncoder.withIndent('  ');
        await File(
          '${screenshotDirectory.path}/manifest.json',
        ).writeAsString('${encoder.convert(manifest)}\n');
      }
    },
    writeResponseOnFailure: true,
  );
}

Future<void> _writeScreenshot(
  Directory directory,
  String name,
  List<int> bytes,
) async {
  if (!RegExp(
    r'^[a-z0-9_]+__[a-z0-9_]+__[a-z0-9_]+__[a-z0-9_]+$',
  ).hasMatch(name)) {
    throw StateError('Invalid screenshot artifact name: $name');
  }
  if (bytes.isEmpty) {
    throw StateError('Screenshot $name did not contain PNG bytes.');
  }
  await File('${directory.path}/$name.png').writeAsBytes(bytes);
}
