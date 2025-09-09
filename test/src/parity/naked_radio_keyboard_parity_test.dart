import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  testWidgets('arrow key navigation updates selection', (tester) async {
    String? groupValue = 'b';
    final nodes = [FocusNode(), FocusNode(), FocusNode()];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return RadioGroup<String>(
                groupValue: groupValue,
                onChanged: (v) => setState(() => groupValue = v),
                child: Row(
                  children: [
                    NakedRadio<String>(
                      value: 'a',
                      focusNode: nodes[0],
                      child: const SizedBox(width: 24, height: 24),
                    ),
                    NakedRadio<String>(
                      value: 'b',
                      focusNode: nodes[1],
                      child: const SizedBox(width: 24, height: 24),
                    ),
                    NakedRadio<String>(
                      value: 'c',
                      focusNode: nodes[2],
                      child: const SizedBox(width: 24, height: 24),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    // Focus the currently-selected radio ('b')
    nodes[1].requestFocus();
    await tester.pump();
    expect(groupValue, 'b');

    // Right arrow should move selection to next ('c')
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(groupValue, 'c');

    // Left arrow should move selection back to previous ('b')
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(groupValue, 'b');
  });
}
