import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every integration test file under integration_test/components/ must be
/// imported by
/// integration_test/all_tests.dart — a file missing from the aggregate
/// runner silently does not run in CI.
void main() {
  test('all_tests.dart imports every integration component file', () {
    // `flutter test` may run with the repo root or the package root as CWD.
    final packageRoot = Directory('integration_test').existsSync()
        ? '.'
        : 'packages/example';
    final componentsDir = Directory('$packageRoot/integration_test/components');
    final aggregate = File('$packageRoot/integration_test/all_tests.dart');
    expect(
      componentsDir.existsSync(),
      isTrue,
      reason: 'CWD: ${Directory.current.path}',
    );
    expect(aggregate.existsSync(), isTrue);

    final componentFiles = componentsDir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.dart'))
        .toList();
    expect(componentFiles, isNotEmpty);

    // Only genuine import directives count — a commented-out import must
    // still fail this check.
    final importedFiles = aggregate
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.startsWith("import 'components/"))
        .toList();
    final missing = componentFiles
        .where((name) => !importedFiles.any((i) => i.contains("/$name'")))
        .toList();

    expect(
      missing,
      isEmpty,
      reason:
          'These integration test files are not imported by all_tests.dart '
          'and therefore never run in CI: $missing',
    );
  });
}
