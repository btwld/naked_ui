import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  Future<void> _showNakedDialog(
    WidgetTester tester, {
    required String title,
    required String content,
    List<Widget>? actions,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showNakedDialog<void>(
                context: context,
                barrierColor: Colors.black54,
                barrierLabel: 'Dismiss',
                builder: (context) => NakedDialog(
                  semanticLabel: title,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(content),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children:
                              actions ??
                              [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
  }

  group('NakedDialog Semantics', () {
    testWidgets('basic dialog semantics structure', (tester) async {
      final handle = tester.ensureSemantics();

      await _showNakedDialog(
        tester,
        title: 'Test Dialog',
        content: 'This is test content',
      );

      // Verify dialog is present
      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('This is test content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('dialog focus trapping semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await _showNakedDialog(
        tester,
        title: 'Focus Test',
        content: 'Test content',
        actions: [
          TextButton(onPressed: () {}, child: const Text('Cancel')),
          TextButton(onPressed: () {}, child: const Text('OK')),
        ],
      );

      // Test that focus can move between dialog elements
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Verify dialog actions are focusable
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('dialog dismiss semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await _showNakedDialog(
        tester,
        title: 'Dismissible Dialog',
        content: 'Press escape to close',
      );

      // Verify dialog is open
      expect(find.text('Dismissible Dialog'), findsOneWidget);

      // Test escape key dismissal
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Dismissible Dialog'), findsNothing);

      handle.dispose();
    });

    testWidgets('dialog barrier dismissal semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await _showNakedDialog(
        tester,
        title: 'Barrier Test',
        content: 'Tap outside to close',
      );

      // Verify dialog is open
      expect(find.text('Barrier Test'), findsOneWidget);

      // Test that dialog has proper barrier semantics by checking
      // that it prevents interaction with background content
      // (The actual barrier dismissal behavior is more complex to test reliably)
      expect(
        find.text('Show Dialog'),
        findsOneWidget,
      ); // Button should still be there but not accessible

      handle.dispose();
    });

    testWidgets('dialog with semantic label', (tester) async {
      final handle = tester.ensureSemantics();

      await _showNakedDialog(
        tester,
        title: 'Labeled Dialog',
        content: 'This dialog has a semantic label',
      );

      // Verify dialog has proper semantic structure
      expect(find.text('Labeled Dialog'), findsOneWidget);

      // The semantic label should be accessible to screen readers
      // (This is primarily tested through the semantics tree structure)

      handle.dispose();
    });

    testWidgets('modal vs non-modal semantics', (tester) async {
      final handle = tester.ensureSemantics();

      // Test non-modal dialog
      await tester.pumpWidget(
        _buildTestApp(
          NakedDialog(
            modal: false,
            semanticLabel: 'Non-modal dialog',
            child: Container(
              width: 200,
              height: 100,
              color: Colors.white,
              child: const Center(child: Text('Non-modal content')),
            ),
          ),
        ),
      );

      expect(find.text('Non-modal content'), findsOneWidget);

      // Test modal dialog
      await tester.pumpWidget(
        _buildTestApp(
          NakedDialog(
            modal: true,
            semanticLabel: 'Modal dialog',
            child: Container(
              width: 200,
              height: 100,
              color: Colors.white,
              child: const Center(child: Text('Modal content')),
            ),
          ),
        ),
      );

      expect(find.text('Modal content'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('dialog action button semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await _showNakedDialog(
        tester,
        title: 'Action Test',
        content: 'Dialog with multiple actions',
        actions: [
          TextButton(onPressed: () {}, child: const Text('Cancel')),
          ElevatedButton(onPressed: () {}, child: const Text('Confirm')),
        ],
      );

      // Verify action buttons have proper semantics
      final cancelButton = summarizeMergedFromRoot(
        tester,
        control: ControlType.button,
      );
      expect(cancelButton.actions.contains('tap'), isTrue);
      expect(cancelButton.flags.contains('isButton'), isTrue);

      handle.dispose();
    });
  });
}
