/// ARIA Focus Behavior Tests for NakedAccordion
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
/// - Tab: Moves focus between accordion headers (each header is a tab stop)
/// - Enter/Space: Toggles the accordion panel open/closed
/// - Arrow Down: (Optional) Moves focus to next accordion header
/// - Arrow Up: (Optional) Moves focus to previous accordion header
/// - Home: (Optional) Moves focus to first accordion header
/// - End: (Optional) Moves focus to last accordion header
///
/// Focus Behavior:
/// - Each accordion header/trigger is in the tab order
/// - When a panel opens, focus stays on the trigger (does NOT auto-move into panel)
/// - Content inside expanded panels is reachable via Tab
///
/// Notes:
/// - If using optional arrow key navigation, treat headers as a composite widget with roving tabindex
/// - Without arrow keys, each header is simply a normal tab stop
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedAccordion ARIA Focus Behavior', () {
    group('Tab Navigation', () {
      testWidgets('Tab moves focus between accordion headers', (
        WidgetTester tester,
      ) async {
        final focusNodeBefore = FocusNode(debugLabel: 'before');
        final focusNodeAfter = FocusNode(debugLabel: 'after');
        final focusNodeAccordion1 = FocusNode(debugLabel: 'accordion1');
        final focusNodeAccordion2 = FocusNode(debugLabel: 'accordion2');
        final focusNodeAccordion3 = FocusNode(debugLabel: 'accordion3');
        final controller = NakedAccordionController<String>();

        await tester.pumpMaterialWidget(
          Column(
            children: [
              TextField(focusNode: focusNodeBefore),
              NakedAccordionGroup<String>(
                controller: controller,
                child: Column(
                  children: [
                    NakedAccordion<String>(
                      value: 'item1',
                      focusNode: focusNodeAccordion1,
                      builder: (_, state) => const Text('Header 1'),
                      child: const Text('Content 1'),
                    ),
                    NakedAccordion<String>(
                      value: 'item2',
                      focusNode: focusNodeAccordion2,
                      builder: (_, state) => const Text('Header 2'),
                      child: const Text('Content 2'),
                    ),
                    NakedAccordion<String>(
                      value: 'item3',
                      focusNode: focusNodeAccordion3,
                      builder: (_, state) => const Text('Header 3'),
                      child: const Text('Content 3'),
                    ),
                  ],
                ),
              ),
              TextField(focusNode: focusNodeAfter),
            ],
          ),
        );

        // Focus the first element
        focusNodeBefore.requestFocus();
        await tester.pump();
        expect(focusNodeBefore.hasFocus, isTrue);

        // Tab should move to first accordion header
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeBefore.hasFocus, isFalse);
        expect(focusNodeAccordion1.hasFocus, isTrue);

        // Tab should move to second accordion header
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeAccordion2.hasFocus, isTrue);

        // Tab should move to third accordion header
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeAccordion3.hasFocus, isTrue);

        // Tab should move to element after accordion
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNodeAfter.hasFocus, isTrue);

        focusNodeBefore.dispose();
        focusNodeAfter.dispose();
        focusNodeAccordion1.dispose();
        focusNodeAccordion2.dispose();
        focusNodeAccordion3.dispose();
        controller.dispose();
      });

      testWidgets('Each accordion header is an independent tab stop', (
        WidgetTester tester,
      ) async {
        final controller = NakedAccordionController<String>();
        final focusNode1 = FocusNode(debugLabel: 'header1');
        final focusNode2 = FocusNode(debugLabel: 'header2');
        final focusNode3 = FocusNode(debugLabel: 'header3');

        await tester.pumpMaterialWidget(
          NakedAccordionGroup<String>(
            controller: controller,
            child: Column(
              children: [
                NakedAccordion<String>(
                  value: 'item1',
                  focusNode: focusNode1,
                  builder: (_, state) => const Text('Header 1'),
                  child: const Text('Content 1'),
                ),
                NakedAccordion<String>(
                  value: 'item2',
                  focusNode: focusNode2,
                  builder: (_, state) => const Text('Header 2'),
                  child: const Text('Content 2'),
                ),
                NakedAccordion<String>(
                  value: 'item3',
                  focusNode: focusNode3,
                  builder: (_, state) => const Text('Header 3'),
                  child: const Text('Content 3'),
                ),
              ],
            ),
          ),
        );

        // Focus first header
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        // Tab to second header
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode2.hasFocus, isTrue);

        // Tab to third header
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNode2.dispose();
        focusNode3.dispose();
        controller.dispose();
      });
    });

    group('Keyboard Activation', () {
      testWidgets('Enter key toggles accordion panel', (
        WidgetTester tester,
      ) async {
        final controller = NakedAccordionController<String>();
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedAccordionGroup<String>(
            controller: controller,
            child: NakedAccordion<String>(
              value: 'item1',
              focusNode: focusNode,
              autofocus: true,
              builder: (_, state) => const Text('Header 1'),
              child: const Text('Content 1'),
            ),
          ),
        );

        await tester.pump();

        // Initially closed
        expect(controller.contains('item1'), isFalse);
        expect(find.text('Content 1'), findsNothing);

        // Enter should open
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(controller.contains('item1'), isTrue);
        expect(find.text('Content 1'), findsOneWidget);

        // Enter again should close
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(controller.contains('item1'), isFalse);

        focusNode.dispose();
        controller.dispose();
      });

      testWidgets('Space key toggles accordion panel', (
        WidgetTester tester,
      ) async {
        final controller = NakedAccordionController<String>();
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedAccordionGroup<String>(
            controller: controller,
            child: NakedAccordion<String>(
              value: 'item1',
              focusNode: focusNode,
              autofocus: true,
              builder: (_, state) => const Text('Header 1'),
              child: const Text('Content 1'),
            ),
          ),
        );

        await tester.pump();

        // Initially closed
        expect(controller.contains('item1'), isFalse);

        // Space should open
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        expect(controller.contains('item1'), isTrue);

        // Space again should close
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        expect(controller.contains('item1'), isFalse);

        focusNode.dispose();
        controller.dispose();
      });

      testWidgets('Focus stays on trigger when panel opens', (
        WidgetTester tester,
      ) async {
        final controller = NakedAccordionController<String>();
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedAccordionGroup<String>(
            controller: controller,
            child: NakedAccordion<String>(
              value: 'item1',
              focusNode: focusNode,
              autofocus: true,
              builder: (_, state) => const Text('Header 1'),
              child: const TextField(),
            ),
          ),
        );

        await tester.pump();
        expect(focusNode.hasFocus, isTrue);

        // Open the panel
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        // Focus should still be on the trigger, not moved to content
        expect(focusNode.hasFocus, isTrue);

        focusNode.dispose();
        controller.dispose();
      });
    });

    group('Content Accessibility', () {
      testWidgets('Content inside expanded panel is reachable via Tab', (
        WidgetTester tester,
      ) async {
        final controller = NakedAccordionController<String>();
        final headerFocusNode = FocusNode(debugLabel: 'header');
        final contentFocusNode = FocusNode(debugLabel: 'content');

        // Start with panel expanded
        controller.open('item1');

        await tester.pumpMaterialWidget(
          NakedAccordionGroup<String>(
            controller: controller,
            child: NakedAccordion<String>(
              value: 'item1',
              focusNode: headerFocusNode,
              builder: (_, state) => const Text('Header 1'),
              child: TextField(focusNode: contentFocusNode),
            ),
          ),
        );

        // Focus the header
        headerFocusNode.requestFocus();
        await tester.pump();
        expect(headerFocusNode.hasFocus, isTrue);

        // Tab should move to content inside expanded panel
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(contentFocusNode.hasFocus, isTrue);

        headerFocusNode.dispose();
        contentFocusNode.dispose();
        controller.dispose();
      });
    });

    group('Disabled Accordion Behavior', () {
      testWidgets(
        'Disabled accordion header should NOT receive focus via Tab',
        (WidgetTester tester) async {
          final controller = NakedAccordionController<String>();
          final focusNode1 = FocusNode(debugLabel: 'header1');
          final focusNodeDisabled = FocusNode(debugLabel: 'disabled');
          final focusNode3 = FocusNode(debugLabel: 'header3');

          await tester.pumpMaterialWidget(
            NakedAccordionGroup<String>(
              controller: controller,
              child: Column(
                children: [
                  NakedAccordion<String>(
                    value: 'item1',
                    focusNode: focusNode1,
                    builder: (_, state) => const Text('Header 1'),
                    child: const Text('Content 1'),
                  ),
                  NakedAccordion<String>(
                    value: 'item2',
                    focusNode: focusNodeDisabled,
                    enabled: false,
                    builder: (_, state) => const Text('Header 2 (disabled)'),
                    child: const Text('Content 2'),
                  ),
                  NakedAccordion<String>(
                    value: 'item3',
                    focusNode: focusNode3,
                    builder: (_, state) => const Text('Header 3'),
                    child: const Text('Content 3'),
                  ),
                ],
              ),
            ),
          );

          // Focus first header
          focusNode1.requestFocus();
          await tester.pump();
          expect(focusNode1.hasFocus, isTrue);

          // Tab should skip disabled and go to third
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(focusNodeDisabled.hasFocus, isFalse);
          expect(focusNode3.hasFocus, isTrue);

          focusNode1.dispose();
          focusNodeDisabled.dispose();
          focusNode3.dispose();
          controller.dispose();
        },
      );

      testWidgets(
        'Disabled accordion does not respond to keyboard activation',
        (WidgetTester tester) async {
          final controller = NakedAccordionController<String>();
          final focusNode = FocusNode();

          await tester.pumpMaterialWidget(
            NakedAccordionGroup<String>(
              controller: controller,
              child: NakedAccordion<String>(
                value: 'item1',
                focusNode: focusNode,
                enabled: false,
                autofocus: true,
                builder: (_, state) => const Text('Header 1'),
                child: const Text('Content 1'),
              ),
            ),
          );

          await tester.pump();

          // Initially closed
          expect(controller.contains('item1'), isFalse);

          // Enter should NOT open disabled accordion
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();

          expect(controller.contains('item1'), isFalse);

          // Space should NOT open disabled accordion
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pump();

          expect(controller.contains('item1'), isFalse);

          focusNode.dispose();
          controller.dispose();
        },
      );
    });

    group('Focus State Reporting', () {
      testWidgets('onFocusChange is called when header gains focus', (
        WidgetTester tester,
      ) async {
        bool? focusState;
        final controller = NakedAccordionController<String>();
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedAccordionGroup<String>(
            controller: controller,
            child: NakedAccordion<String>(
              value: 'item1',
              focusNode: focusNode,
              onFocusChange: (focused) => focusState = focused,
              builder: (_, state) => const Text('Header 1'),
              child: const Text('Content 1'),
            ),
          ),
        );

        focusNode.requestFocus();
        await tester.pump();

        expect(focusState, isTrue);

        focusNode.dispose();
        controller.dispose();
      });

      testWidgets('onFocusChange is called when header loses focus', (
        WidgetTester tester,
      ) async {
        bool? focusState;
        final controller = NakedAccordionController<String>();
        final focusNode1 = FocusNode();
        final focusNode2 = FocusNode();

        await tester.pumpMaterialWidget(
          NakedAccordionGroup<String>(
            controller: controller,
            child: Column(
              children: [
                NakedAccordion<String>(
                  value: 'item1',
                  focusNode: focusNode1,
                  onFocusChange: (focused) => focusState = focused,
                  builder: (_, state) => const Text('Header 1'),
                  child: const Text('Content 1'),
                ),
                TextField(focusNode: focusNode2),
              ],
            ),
          ),
        );

        // Gain focus
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusState, isTrue);

        // Lose focus
        focusNode2.requestFocus();
        await tester.pump();
        expect(focusState, isFalse);

        focusNode1.dispose();
        focusNode2.dispose();
        controller.dispose();
      });
    });

    group('Autofocus', () {
      testWidgets('Accordion header with autofocus receives initial focus', (
        WidgetTester tester,
      ) async {
        final controller = NakedAccordionController<String>();
        final focusNode = FocusNode();

        await tester.pumpMaterialWidget(
          NakedAccordionGroup<String>(
            controller: controller,
            child: NakedAccordion<String>(
              value: 'item1',
              focusNode: focusNode,
              autofocus: true,
              builder: (_, state) => const Text('Header 1'),
              child: const Text('Content 1'),
            ),
          ),
        );

        await tester.pump();

        expect(focusNode.hasFocus, isTrue);

        focusNode.dispose();
        controller.dispose();
      });
    });
  });
}
