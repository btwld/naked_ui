#!/usr/bin/env dart
// Dart script for running tests with proper configuration
// Usage: fvm dart tool/test.dart [options]

import 'dart:async';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final stopwatch = Stopwatch()..start();

  // Parse arguments
  final showHelp = arguments.contains('--help') || arguments.contains('-h');
  final runAll = arguments.contains('--all');
  final runUnit = arguments.contains('--unit') || runAll || arguments.isEmpty;
  final runIntegration = arguments.contains('--integration') || runAll;
  final runSpecific = arguments.firstWhere(
    (arg) => arg.startsWith('--component='),
    orElse: () => '',
  );
  final verbose = arguments.contains('--verbose') || arguments.contains('-v');

  if (showHelp) {
    printHelp();
    exit(0);
  }

  print('🚀 NakedUI Test Runner\n');

  try {
    // Run unit tests
    if (runUnit) {
      print('📦 Running unit tests...');
      final unitResult = await runFlutter([
        'test',
        'packages/naked_ui/test',
        'packages/example/test',
        '--reporter=${verbose ? "expanded" : "compact"}',
      ], workingDirectory: Directory.current.path);

      if (unitResult != 0) {
        print('❌ Unit tests failed');
        exit(unitResult);
      }
      print('✅ Unit tests passed\n');
    }

    // Run integration tests
    if (runIntegration) {
      print('🧪 Running integration tests...');

      final integrationResult = await runFlutter([
        'test',
        'integration_test/all_tests.dart',
        '-d',
        'flutter-tester',
        '--reporter=${verbose ? "expanded" : "compact"}',
        '--timeout=300s',
      ], workingDirectory: Directory('packages/example').absolute.path);

      if (integrationResult != 0) {
        print('❌ Integration tests failed');
        exit(integrationResult);
      }
      print('✅ Integration tests passed\n');
    }

    // Run specific component test
    if (runSpecific.isNotEmpty) {
      final component = runSpecific.split('=')[1];
      print('🔧 Running $component integration tests...');

      final componentPath =
          'integration_test/components/naked_${component}_integration.dart';
      final componentFile = File('packages/example/$componentPath');

      if (!componentFile.existsSync()) {
        print('❌ Component test file not found: $componentPath');
        print(
          'Available components: button, checkbox, radio, slider, textfield, select, etc.',
        );
        exit(1);
      }

      final componentResult = await runFlutter([
        'test',
        componentPath,
        '-d',
        'flutter-tester',
        '--reporter=${verbose ? "expanded" : "compact"}',
      ], workingDirectory: Directory('packages/example').absolute.path);

      if (componentResult != 0) {
        print('❌ $component tests failed');
        exit(componentResult);
      }
      print('✅ $component tests passed\n');
    }

    stopwatch.stop();
    final duration = stopwatch.elapsed;
    print('⏱️  Total time: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
    print('✨ All tests completed successfully!');
  } catch (error, stackTrace) {
    stderr.writeln('💥 Test runner error: $error');
    stderr.writeln(stackTrace);
    exit(1);
  }
}

Future<int> runCommand(
  String command,
  List<String> args, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async {
  final process = await Process.start(
    command,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
    mode: ProcessStartMode.inheritStdio,
  );

  return await process.exitCode;
}

Future<int> runFlutter(
  List<String> args, {
  String? workingDirectory,
  Map<String, String>? environment,
}) {
  return runCommand(
    'fvm',
    ['flutter', ...args],
    workingDirectory: workingDirectory,
    environment: environment,
  );
}

void printHelp() {
  print('''
🚀 NakedUI Test Runner

Usage: fvm dart tool/test.dart [options]

Options:
  --help, -h        Show this help message
  --unit            Run unit tests (default if no options)
  --integration     Run integration tests
  --all             Run both unit and integration tests
  --component=NAME  Run specific component integration test
                    (e.g., --component=button)
  --verbose, -v     Use expanded reporter for detailed output

Examples:
  fvm dart tool/test.dart                    # Run unit tests
  fvm dart tool/test.dart --all              # Run all tests
  fvm dart tool/test.dart --integration      # Run integration tests only
  fvm dart tool/test.dart --component=button # Run button integration tests

Available components:
  button, checkbox, radio, slider, textfield, select,
  popover, tooltip, menu, accordion, tabs, dialog
''');
}
