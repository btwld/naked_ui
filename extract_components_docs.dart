import 'dart:io';

class ComponentInfo {
  final String name;
  final String description;
  final String filePath;
  final List<String> constructorParams;
  final List<String> examples;
  final List<String> features;

  const ComponentInfo({
    required this.name,
    required this.description,
    required this.filePath,
    this.constructorParams = const [],
    this.examples = const [],
    this.features = const [],
  });
}

class ComponentDocumentationExtractor {
  final String libPath;
  final List<ComponentInfo> components = [];

  ComponentDocumentationExtractor(this.libPath);

  Future<void> _extractComponentFromFile(File file) async {
    final content = await file.readAsString();
    final lines = content.split('\n');

    String? currentDocComment;
    List<String> docLines = [];
    bool inDocComment = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Track documentation comments
      if (line.startsWith('///')) {
        inDocComment = true;
        docLines.add(line.substring(3).trim());
      } else if (inDocComment && line.isEmpty) {
        docLines.add('');
      } else if (inDocComment && !line.startsWith('///')) {
        currentDocComment = docLines.join('\n').trim();
        inDocComment = false;
        docLines.clear();
      }

      // Look for class definitions
      if (line.startsWith('class ') &&
          line.contains('Naked') &&
          !line.contains('_')) {
        final className = _extractClassName(line);
        if (className != null && className.startsWith('Naked')) {
          final component = ComponentInfo(
            name: className,
            description: currentDocComment ?? 'No description available',
            filePath: file.path,
            constructorParams: _extractConstructorParams(
              content,
              className,
            ),
            examples: _extractExamples(currentDocComment ?? ''),
            features: _extractFeatures(currentDocComment ?? ''),
          );
          components.add(component);
          currentDocComment = null;
        }
      }
    }
  }

  String? _extractClassName(String line) {
    final regex = RegExp(r'class\s+(\w+)');
    final match = regex.firstMatch(line);

    return match?.group(1);
  }

  List<String> _extractConstructorParams(String content, String className) {
    final lines = content.split('\n');
    final params = <String>[];
    bool inConstructor = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.contains('$className(') ||
          (line.contains(className) && line.contains('('))) {
        inConstructor = true;
        continue;
      }

      if (inConstructor) {
        if (line.contains(');')) {
          break;
        }

        if (line.contains('this.') ||
            line.contains('required') ||
            line.contains('@')) {
          // Look for parameter documentation in previous lines
          String? paramDoc;
          for (int j = i - 1; j >= 0; j--) {
            final prevLine = lines[j].trim();
            if (prevLine.startsWith('///')) {
              paramDoc = prevLine.substring(3).trim();
              break;
            } else if (prevLine.isEmpty || prevLine.startsWith('//')) {
              continue;
            }
            break;
          }

          String paramInfo = line;
          if (paramDoc != null) {
            paramInfo = '$line // $paramDoc';
          }
          params.add(paramInfo);
        }
      }
    }

    return params;
  }

  List<String> _extractExamples(String docComment) {
    final examples = <String>[];
    final lines = docComment.split('\n');
    bool inCodeBlock = false;
    List<String> currentExample = [];

    for (final line in lines) {
      if (line.trim().startsWith('```dart') || line.trim().startsWith('```')) {
        if (inCodeBlock) {
          if (currentExample.isNotEmpty) {
            examples.add(currentExample.join('\n'));
            currentExample.clear();
          }
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
        }
      } else if (inCodeBlock) {
        currentExample.add(line);
      }
    }

    return examples;
  }

  List<String> _extractFeatures(String docComment) {
    final features = <String>[];
    final lines = docComment.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('*') || trimmed.startsWith('-')) {
        features.add(trimmed.substring(1).trim());
      } else if (trimmed.contains('provides') ||
          trimmed.contains('supports') ||
          trimmed.contains('handles')) {
        features.add(trimmed);
      }
    }

    return features;
  }

  void _writeComponentSection(StringBuffer buffer, ComponentInfo component) {
    // Component Header
    buffer.writeln('## ${component.name}');
    buffer.writeln();

    // Description
    buffer.writeln('### Description');
    buffer.writeln();
    final cleanDescription = component.description
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .replaceAll(RegExp(r'^\s*'), '')
        .trim();
    buffer.writeln(cleanDescription);
    buffer.writeln();

    // Features
    if (component.features.isNotEmpty) {
      buffer.writeln('### Key Features');
      buffer.writeln();
      for (final feature in component.features) {
        buffer.writeln('- $feature');
      }
      buffer.writeln();
    }

    // Constructor Parameters
    if (component.constructorParams.isNotEmpty) {
      buffer.writeln('### Constructor Parameters');
      buffer.writeln();
      buffer.writeln('```dart');
      buffer.writeln('${component.name}(');
      for (final param in component.constructorParams) {
        buffer.writeln('  $param');
      }
      buffer.writeln(')');
      buffer.writeln('```');
      buffer.writeln();
    }

    // Examples
    if (component.examples.isNotEmpty) {
      buffer.writeln('### Usage Examples');
      buffer.writeln();
      for (int i = 0; i < component.examples.length; i++) {
        if (component.examples.length > 1) {
          buffer.writeln('#### Example ${i + 1}');
          buffer.writeln();
        }
        buffer.writeln('```dart');
        buffer.writeln(component.examples[i]);
        buffer.writeln('```');
        buffer.writeln();
      }
    }

    // File Location
    buffer.writeln('### Source');
    buffer.writeln();
    final relativePath = component.filePath.replaceAll(
      RegExp(r'^.*naked_ui/'),
      '',
    );
    buffer.writeln('Location: `$relativePath`');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
  }

  Future<void> extractAllComponents() async {
    final srcDir = Directory('$libPath/src');
    if (!await srcDir.exists()) {
      throw Exception('Source directory not found: ${srcDir.path}');
    }

    await for (final entity in srcDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = entity.path.split('/').last;
        if (fileName.startsWith('naked_') && !fileName.contains('_test.dart')) {
          await _extractComponentFromFile(entity);
        }
      }
    }
  }

  String generateMarkdown() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# Naked UI Components Documentation');
    buffer.writeln();
    buffer.writeln(
      'This document contains comprehensive documentation for all Naked UI components.',
    );
    buffer.writeln('Generated automatically from source code documentation.');
    buffer.writeln();

    // Table of Contents
    buffer.writeln('## Table of Contents');
    buffer.writeln();
    for (final component in components) {
      buffer.writeln(
        '- [${component.name}](#${component.name.toLowerCase().replaceAll('naked', '').trim()})',
      );
    }
    buffer.writeln();

    // Component Details
    for (final component in components) {
      _writeComponentSection(buffer, component);
    }

    return buffer.toString();
  }

  Future<void> saveToFile(String outputPath) async {
    final markdown = generateMarkdown();
    final file = File(outputPath);
    await file.writeAsString(markdown);
    print('Documentation saved to: $outputPath');
  }
}

Future<void> main() async {
  try {
    final extractor = ComponentDocumentationExtractor('lib');

    print('Extracting component documentation...');
    await extractor.extractAllComponents();

    print('Found ${extractor.components.length} components:');
    for (final component in extractor.components) {
      print('- ${component.name}');
    }

    print('\nGenerating markdown documentation...');
    await extractor.saveToFile('naked_ui_components_documentation.md');

    print('✅ Documentation extraction completed successfully!');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
