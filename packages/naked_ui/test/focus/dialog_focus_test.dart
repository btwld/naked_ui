/// ARIA Focus Behavior Tests for NakedDialog
///
/// Tests compliance with WAI-ARIA Authoring Practices Guide (APG) focus behavior:
///
/// On Open:
/// - Move focus into dialog: Focus should move to the first focusable element,
///   OR a primary action button, OR the dialog title (`tabindex="-1"`) if content is lengthy
/// - Trap focus: Tab/Shift+Tab must cycle within the dialog only
/// - Disable background: Background content should be `aria-hidden="true"` and not receive focus
///
/// While Open:
/// - Tab: Cycles forward through focusable elements in dialog
/// - Shift+Tab: Cycles backward through focusable elements
/// - Escape: Closes dialog (for dismissible dialogs)
///
/// On Close:
/// - Return focus: Focus MUST return to the element that opened the dialog
/// - Fallback: If trigger no longer exists, focus should go to a logical alternative
///
/// Focus Trap Implementation:
/// - First focusable ← Shift+Tab ← Last focusable
/// - Last focusable → Tab → First focusable
///
/// Reference: ARIA_FOCUS_BEHAVIOR.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedDialog ARIA Focus Behavior', () {
    group('Focus on Open', () {
      testWidgets('Focus moves into dialog when opened', (
        WidgetTester tester,
      ) async {
        final triggerFocusNode = FocusNode(debugLabel: 'trigger');

        await tester.pumpMaterialWidget(
          Builder(
            builder: (context) {
              return NakedButton(
                focusNode: triggerFocusNode,
                onPressed: () {
                  showNakedDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (context) => NakedDialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Dialog Content'),
                          NakedButton(
                            autofocus: true,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        );

        // Focus trigger and open dialog
        triggerFocusNode.requestFocus();
        await tester.pump();
        expect(triggerFocusNode.hasFocus, isTrue);

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Dialog should be open
        expect(find.text('Dialog Content'), findsOneWidget);

        // Focus should have moved into the dialog (trigger loses focus)
        expect(triggerFocusNode.hasFocus, isFalse);

        triggerFocusNode.dispose();
      });
    });

    group('Focus Trap', () {
      testWidgets('Tab cycles through focusable elements in dialog', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'input1');
        final focusNode2 = FocusNode(debugLabel: 'input2');
        final focusNode3 = FocusNode(debugLabel: 'button');

        await tester.pumpMaterialWidget(
          Builder(
            builder: (context) {
              return NakedButton(
                onPressed: () {
                  showNakedDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (context) => NakedDialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Focus(child: SizedBox(), focusNode: focusNode1),
                          Focus(child: SizedBox(), focusNode: focusNode2),
                          NakedButton(
                            focusNode: focusNode3,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Button'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        );

        // Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // First element should have focus
        expect(focusNode1.hasFocus, isTrue);

        // Tab to second
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode2.hasFocus, isTrue);

        // Tab to third
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusNode3.hasFocus, isTrue);

        focusNode1.dispose();
        focusNode2.dispose();
        focusNode3.dispose();
      });

      testWidgets('Shift+Tab cycles backward through dialog elements', (
        WidgetTester tester,
      ) async {
        final focusNode1 = FocusNode(debugLabel: 'input1');
        final focusNode2 = FocusNode(debugLabel: 'input2');

        await tester.pumpMaterialWidget(
          Builder(
            builder: (context) {
              return NakedButton(
                onPressed: () {
                  showNakedDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (context) => NakedDialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Focus(focusNode: focusNode1, child: SizedBox()),
                          Focus(focusNode: focusNode2, child: SizedBox()),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        );

        // Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Request focus on second element
        focusNode2.requestFocus();
        await tester.pump();
        expect(focusNode2.hasFocus, isTrue);

        // Shift+Tab to first
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);
        expect(focusNode2.hasFocus, isFalse);

        focusNode1.dispose();
        focusNode2.dispose();
      });
    });

    group('Escape Key', () {
      testWidgets('Escape closes dismissible dialog', (
        WidgetTester tester,
      ) async {
        await tester.pumpMaterialWidget(
          Builder(
            builder: (context) {
              return NakedButton(
                onPressed: () {
                  showNakedDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    barrierDismissible: true,
                    builder: (context) => NakedDialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Dialog Content'),
                          NakedButton(
                            autofocus: true,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        );

        // Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        expect(find.text('Dialog Content'), findsOneWidget);

        // Escape should close dialog
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.text('Dialog Content'), findsNothing);
      });
    });

    group('Focus Return on Close', () {
      testWidgets('Focus returns to trigger when dialog closes', (
        WidgetTester tester,
      ) async {
        final triggerFocusNode = FocusNode(debugLabel: 'trigger');

        await tester.pumpMaterialWidget(
          Builder(
            builder: (context) {
              return NakedButton(
                focusNode: triggerFocusNode,
                onPressed: () {
                  showNakedDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (context) => NakedDialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Dialog Content'),
                          NakedButton(
                            autofocus: true,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        );

        // Focus trigger and open dialog
        triggerFocusNode.requestFocus();
        await tester.pump();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Dialog Content'), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.text('Dialog Content'), findsNothing);
        // Focus should return to trigger
        expect(triggerFocusNode.hasFocus, isTrue);

        triggerFocusNode.dispose();
      });
    });
  });
}
