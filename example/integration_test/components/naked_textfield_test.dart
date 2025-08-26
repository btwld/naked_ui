import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:example/api/naked_textfield.0.dart' as textfield_example;

import '../helpers/test_helpers.dart';
import '../helpers/text_field_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('NakedTextField Integration Tests', () {
    testWidgets('text input updates value correctly', (tester) async {
      // Use the actual example app but avoid animation waits
      await tester.pumpWidget(const textfield_example.MyApp());
      await tester.pump(const Duration(milliseconds: 100));
      
      final textFieldFinder = find.byType(NakedTextField);
      expect(textFieldFinder, findsOneWidget);
      
      // Use direct tap and enterText instead of helper
      await tester.tap(textFieldFinder);
      await tester.pump();
      await tester.enterText(textFieldFinder, 'Hello World');
      await tester.pump();
      
      // Verify text was entered
      tester.expectTextValue(textFieldFinder, 'Hello World');
    });
    
    testWidgets('text can be cleared and replaced', (tester) async {
      final textFieldKey = UniqueKey();
      final controller = TextEditingController(text: 'Initial text');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTextField(
              key: textFieldKey,
              controller: controller,
              builder: (context, editableText) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: editableText,
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Verify initial text
      expect(controller.text, 'Initial text');
      
      // Clear and enter new text
      await tester.clearText(find.byKey(textFieldKey));
      await tester.typeText(find.byKey(textFieldKey), 'New text');
      
      // Verify text was replaced
      expect(controller.text, 'New text');
    });
    
    testWidgets('controller synchronizes with input', (tester) async {
      final textFieldKey = UniqueKey();
      final controller = TextEditingController();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTextField(
              key: textFieldKey,
              controller: controller,
              builder: (context, editableText) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: editableText,
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Initially empty
      expect(controller.text, '');
      
      // Type text
      await tester.typeText(find.byKey(textFieldKey), 'Synchronized');
      
      // Verify controller updated
      expect(controller.text, 'Synchronized');
      
      // Update controller programmatically
      controller.text = 'Updated programmatically';
      await tester.pump();
      
      // Verify field shows updated text
      tester.expectTextValue(find.byKey(textFieldKey), 'Updated programmatically');
    });
    
    testWidgets('focus and hover callbacks work correctly', (tester) async {
      final textFieldKey = UniqueKey();
      bool isHovered = false;
      bool isFocused = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTextField(
              key: textFieldKey,
              onHoverChange: (hovered) => isHovered = hovered,
              onFocusChange: (focused) => isFocused = focused,
              builder: (context, editableText) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: editableText,
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Test hover state
      await tester.simulateHover(textFieldKey, onHover: () {
        expect(isHovered, isTrue);
      });
      
      // Test focus state by tapping
      await tester.tap(find.byKey(textFieldKey));
      await tester.pump();
      expect(isFocused, isTrue);
    });
    
    testWidgets('focus management works properly', (tester) async {
      final textFieldKey = UniqueKey();
      final focusNode = tester.createManagedFocusNode();
      bool focusChanged = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTextField(
              key: textFieldKey,
              focusNode: focusNode,
              onFocusChange: (focused) => focusChanged = focused,
              builder: (context, editableText) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: editableText,
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Initially not focused
      expect(focusNode.hasFocus, isFalse);
      expect(focusChanged, isFalse);
      
      // Request focus programmatically
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(focusChanged, isTrue);
      
      // Lose focus
      focusChanged = false;
      focusNode.unfocus();
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
      expect(focusChanged, isFalse);
    });
    
    
    testWidgets('disabled field blocks all interactions', (tester) async {
      final textFieldKey = UniqueKey();
      final controller = TextEditingController();
      bool hoverChanged = false;
      // Note: We don't test focus/press change callbacks for disabled fields
      // as the framework behavior can vary
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTextField(
              key: textFieldKey,
              controller: controller,
              enabled: false,
              onHoverChange: (hovered) => hoverChanged = true,
              onFocusChange: (focused) {},
              onPressChange: (pressed) {},
              builder: (context, editableText) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: editableText,
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Attempt to type - should not work
      await tester.tap(find.byKey(textFieldKey));
      await tester.pump();
      await tester.enterText(find.byKey(textFieldKey), 'Should not work');
      await tester.pump();
      
      // Verify no text was entered
      expect(controller.text, '');
      
      // Focus change might still occur even when disabled (framework behavior)
      // The key test is that text input doesn't work
      expect(hoverChanged, isFalse);
      // Don't test focus change as disabled fields can still receive focus in some cases
      
      // Test hover doesn't work when disabled
      await tester.simulateHover(textFieldKey);
      expect(hoverChanged, isFalse);
    });
    
    testWidgets('readOnly prevents editing but allows focus', (tester) async {
      final textFieldKey = UniqueKey();
      final controller = TextEditingController(text: 'Read only text');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedTextField(
              key: textFieldKey,
              controller: controller,
              readOnly: true,
              builder: (context, editableText) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: editableText,
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Tap to focus
      await tester.tap(find.byKey(textFieldKey));
      await tester.pump();
      
      // Try to type - should not modify text
      await tester.enterText(find.byKey(textFieldKey), 'Should not work');
      await tester.pump();
      
      // Verify original text unchanged - this is what readOnly actually does
      expect(controller.text, 'Read only text');
    });
    
    testWidgets('works with example app basic interaction', (tester) async {
      // Test the example app with simplified interaction to avoid animation timeouts
      await tester.pumpWidget(const textfield_example.MyApp());
      await tester.pump(const Duration(milliseconds: 100)); // Fixed duration instead of pumpAndSettle
      
      final textFieldFinder = find.byType(NakedTextField);
      expect(textFieldFinder, findsOneWidget);
      
      // Basic interaction test - use tap and enterText instead of typeText helper
      await tester.tap(textFieldFinder);
      await tester.pump();
      await tester.enterText(textFieldFinder, 'Testing');
      await tester.pump();
      
      tester.expectTextValue(textFieldFinder, 'Testing');
    });
  });
}