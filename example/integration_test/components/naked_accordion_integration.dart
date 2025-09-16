import 'package:example/api/naked_accordion.0.dart' as accordion_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedAccordion Integration Tests', () {
    testWidgets('accordion expands and collapses correctly', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const accordion_example.MyApp());
      await tester.pump(const Duration(milliseconds: 100));

      final accordionFinder = find.byType(NakedAccordion<String>);
      expect(accordionFinder, findsOneWidget);

      // Initially Section 1 should be expanded (from initialExpandedValues)
      expect(
          find.text(
              'This is the content for section 1. You can put anything here!'),
          findsOneWidget);
      expect(
          find.text(
              'This is the content for section 2. You can put anything here!'),
          findsNothing);

      // Tap Section 2 header to expand it
      await tester.tap(find.text('Section 2'));
      await tester
          .pump(const Duration(milliseconds: 250)); // Wait for animation

      // Section 1 should close (max: 1), Section 2 should open
      expect(
          find.text(
              'This is the content for section 1. You can put anything here!'),
          findsNothing);
      expect(
          find.text(
              'This is the content for section 2. You can put anything here!'),
          findsOneWidget);

      // Tap Section 1 header to expand it again
      await tester.tap(find.text('Section 1'));
      await tester
          .pump(const Duration(milliseconds: 250)); // Wait for animation

      // Section 2 should close, Section 1 should open
      expect(
          find.text(
              'This is the content for section 1. You can put anything here!'),
          findsOneWidget);
      expect(
          find.text(
              'This is the content for section 2. You can put anything here!'),
          findsNothing);
    });

    testWidgets('accordion controller manages state correctly', (tester) async {
      final controller = NakedAccordionController<String>();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedAccordion<String>(
              controller: controller,
              children: [
                NakedAccordionItem<String>(
                  value: 'item1',
                  trigger: (context, isExpanded) => GestureDetector(
                    onTap: () => controller.toggle('item1'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? Colors.blue.shade100
                            : Colors.grey.shade100,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Text('Item 1'),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Content 1'),
                  ),
                ),
                NakedAccordionItem<String>(
                  value: 'item2',
                  trigger: (context, isExpanded) => GestureDetector(
                    onTap: () => controller.toggle('item2'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? Colors.blue.shade100
                            : Colors.grey.shade100,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Text('Item 2'),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Content 2'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Initially no items expanded
      expect(find.text('Content 1'), findsNothing);
      expect(find.text('Content 2'), findsNothing);

      // Expand item 1
      controller.open('item1');
      await tester.pump();
      expect(find.text('Content 1'), findsOneWidget);
      expect(controller.contains('item1'), isTrue);

      // Expand item 2
      controller.open('item2');
      await tester.pump();
      expect(find.text('Content 2'), findsOneWidget);
      expect(controller.contains('item2'), isTrue);

      // Close item 1
      controller.close('item1');
      await tester.pump();
      expect(find.text('Content 1'), findsNothing);
      expect(controller.contains('item1'), isFalse);
    });

    testWidgets('accordion respects min/max constraints', (tester) async {
      final controller = NakedAccordionController<String>(min: 1, max: 1);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedAccordion<String>(
              controller: controller,
              initialExpandedValues: const ['item1'], // Start with one expanded
              children: [
                NakedAccordionItem<String>(
                  value: 'item1',
                  trigger: (context, isExpanded) => GestureDetector(
                    onTap: () => controller.toggle('item1'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Text('Item 1'),
                    ),
                  ),
                  child: const Text('Content 1'),
                ),
                NakedAccordionItem<String>(
                  value: 'item2',
                  trigger: (context, isExpanded) => GestureDetector(
                    onTap: () => controller.toggle('item2'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Text('Item 2'),
                    ),
                  ),
                  child: const Text('Content 2'),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Initially item1 expanded (from initialExpandedValues)
      expect(find.text('Content 1'), findsOneWidget);
      expect(controller.values.length, 1);

      // Try to close item1 - should be blocked by min constraint
      controller.close('item1');
      await tester.pump();
      expect(find.text('Content 1'), findsOneWidget); // Still expanded
      expect(controller.values.length, 1); // Min constraint enforced

      // Open item2 - should close item1 due to max constraint
      controller.open('item2');
      await tester.pump();
      expect(find.text('Content 1'), findsNothing); // Closed by max constraint
      expect(find.text('Content 2'), findsOneWidget); // Now expanded
      expect(controller.values.length, 1); // Max constraint enforced
    });

    testWidgets('accordion item state callbacks work correctly',
        (tester) async {
      final controller = NakedAccordionController<String>();
      final itemKey = UniqueKey();
      bool isHovered = false;
      bool isPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedAccordion<String>(
              controller: controller,
              children: [
                NakedAccordionItem<String>(
                  key: itemKey,
                  value: 'test',
                  onHoverChange: (hovered) => isHovered = hovered,
                  onPressChange: (pressed) => isPressed = pressed,
                  onFocusChange: (focused) {},
                  trigger: (context, isExpanded) => Container(
                    padding: const EdgeInsets.all(12),
                    child: const Text('Test Item'),
                  ),
                  child: const Text('Test Content'),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Test hover state
      await tester.simulateHover(itemKey, onHover: () {
        expect(isHovered, isTrue);
      });

      // Test press state
      await tester.simulatePress(itemKey, onPressed: () {
        expect(isPressed, isTrue);
      });
    });

    testWidgets('accordion keyboard navigation works', (tester) async {
      final controller = NakedAccordionController<String>();
      final itemKey = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedAccordion<String>(
              controller: controller,
              children: [
                NakedAccordionItem<String>(
                  key: itemKey,
                  value: 'keyboard',
                  trigger: (context, isExpanded) => Container(
                    padding: const EdgeInsets.all(12),
                    child: const Text('Keyboard Item'),
                  ),
                  child: const Text('Keyboard Content'),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Initially collapsed
      expect(find.text('Keyboard Content'), findsNothing);

      // Test keyboard activation (Enter/Space)
      await tester.testKeyboardActivation(find.byKey(itemKey));
      await tester.pump();

      // Should be expanded now
      expect(find.text('Keyboard Content'), findsOneWidget);
    });

    testWidgets('disabled accordion item blocks interactions', (tester) async {
      final controller = NakedAccordionController<String>();
      final itemKey = UniqueKey();
      bool hoverChanged = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedAccordion<String>(
              controller: controller,
              children: [
                NakedAccordionItem<String>(
                  key: itemKey,
                  value: 'disabled',
                  enabled: false,
                  onHoverChange: (hovered) => hoverChanged = true,
                  trigger: (context, isExpanded) => Container(
                    padding: const EdgeInsets.all(12),
                    child: const Text('Disabled Item'),
                  ),
                  child: const Text('Disabled Content'),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Initially collapsed
      expect(find.text('Disabled Content'), findsNothing);

      // Tap should not expand
      await tester.tap(find.text('Disabled Item'));
      await tester.pump();
      expect(find.text('Disabled Content'), findsNothing);

      // Hover should not trigger callback
      await tester.simulateHover(itemKey);
      expect(hoverChanged, isFalse);

      // Keyboard activation should not work
      await tester.testKeyboardActivation(find.byKey(itemKey));
      await tester.pump();
      expect(find.text('Disabled Content'), findsNothing);
    });

    testWidgets('accordion works with transition animations', (tester) async {
      // Test the full example with transitions
      await tester.pumpWidget(const accordion_example.MyApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Verify transition builder is working by checking for SizeTransition
      final sizeTransitionFinder = find.byType(SizeTransition);
      expect(sizeTransitionFinder, findsWidgets);

      // Test expand/collapse with animation
      await tester.tap(find.text('Section 2'));

      // During animation, both states might be visible briefly
      await tester.pump(const Duration(milliseconds: 100));

      // After animation completes
      await tester.pump(const Duration(milliseconds: 150));
      expect(
          find.text(
              'This is the content for section 2. You can put anything here!'),
          findsOneWidget);
    });
  });
}
