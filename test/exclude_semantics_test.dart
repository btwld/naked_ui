import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  group('excludeSemantics', () {
    testWidgets('NakedButton respects excludeSemantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();

      // Test with excludeSemantics: false (default)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedButton(
              onPressed: () {},
              semanticLabel: 'Test Button',
              child: const Text('Button'),
            ),
          ),
        ),
      );

      // The semantic label includes both the label and the child text
      expect(find.bySemanticsLabel(RegExp(r'Test Button')), findsOneWidget);

      // Test with excludeSemantics: true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedButton(
              onPressed: () {},
              semanticLabel: 'Test Button',
              excludeSemantics: true,
              child: const Text('Button'),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test Button')), findsNothing);

      semanticsHandle.dispose();
    });

    testWidgets('NakedCheckbox respects excludeSemantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      bool? value = false;

      // Test with excludeSemantics: false (default)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NakedCheckbox(
                value: value,
                onChanged: (v) => setState(() => value = v),
                semanticLabel: 'Test Checkbox',
                child: const Text('Checkbox'),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test Checkbox')), findsOneWidget);

      // Test with excludeSemantics: true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NakedCheckbox(
                value: value,
                onChanged: (v) => setState(() => value = v),
                semanticLabel: 'Test Checkbox',
                excludeSemantics: true,
                child: const Text('Checkbox'),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test Checkbox')), findsNothing);

      semanticsHandle.dispose();
    });

    testWidgets('NakedToggle respects excludeSemantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      bool value = false;

      // Test with excludeSemantics: false (default)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NakedToggle(
                value: value,
                onChanged: (v) => setState(() => value = v),
                semanticLabel: 'Test Toggle',
                child: const Text('Toggle'),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test Toggle')),findsOneWidget);

      // Test with excludeSemantics: true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NakedToggle(
                value: value,
                onChanged: (v) => setState(() => value = v),
                semanticLabel: 'Test Toggle',
                excludeSemantics: true,
                child: const Text('Toggle'),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test Toggle')),findsNothing);

      semanticsHandle.dispose();
    });

    testWidgets('NakedSlider respects excludeSemantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      double value = 0.5;

      // Test with excludeSemantics: false (default)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NakedSlider(
                value: value,
                onChanged: (v) => setState(() => value = v),
                semanticLabel: 'Test Slider',
                child: Container(height: 50, color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test Slider')),findsOneWidget);

      // Test with excludeSemantics: true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NakedSlider(
                value: value,
                onChanged: (v) => setState(() => value = v),
                semanticLabel: 'Test Slider',
                excludeSemantics: true,
                child: Container(height: 50, color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test Slider')),findsNothing);

      semanticsHandle.dispose();
    });

    testWidgets('NakedTextField respects excludeSemantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      final controller = TextEditingController();

      // Test with excludeSemantics: false (default)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedTextField(
              controller: controller,
              semanticLabel: 'Test TextField',
              builder: (context, state, child) => child,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test TextField')),findsOneWidget);

      // Test with excludeSemantics: true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedTextField(
              controller: controller,
              semanticLabel: 'Test TextField',
              excludeSemantics: true,
              builder: (context, state, child) => child,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test TextField')),findsNothing);

      controller.dispose();
      semanticsHandle.dispose();
    });

    testWidgets('NakedDialog respects excludeSemantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();

      // Test with excludeSemantics: false (default)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedDialog(
              semanticLabel: 'Test Dialog',
              child: const Text('Dialog Content'),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test Dialog')),findsOneWidget);

      // Test with excludeSemantics: true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NakedDialog(
              semanticLabel: 'Test Dialog',
              excludeSemantics: true,
              child: const Text('Dialog Content'),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Test Dialog')),findsNothing);

      semanticsHandle.dispose();
    });
  });
}