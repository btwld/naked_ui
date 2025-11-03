import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/naked_ui.dart';

import '../../test_helpers.dart';

void main() {
  group('Material Parity - Dialog', () {
    testWidgets('Barrier label and content visibility parity', (tester) async {
      const materialOpenKey = Key('materialOpen');
      const nakedOpenKey = Key('nakedOpen');
      const barrierLabel = 'Parity Barrier';

      await tester.pumpMaterialWidget(
        Row(
          children: [
            Builder(
              builder: (ctx) => ElevatedButton(
                key: materialOpenKey,
                onPressed: () {
                  showDialog<void>(
                    context: ctx,
                    barrierLabel: barrierLabel,
                    barrierDismissible: true,
                    builder: (_) => const AlertDialog(
                      content: Text('Material Dialog Content'),
                    ),
                  );
                },
                child: const Text('Open Material Dialog'),
              ),
            ),
            const SizedBox(width: 24),
            Builder(
              builder: (ctx) => ElevatedButton(
                key: nakedOpenKey,
                onPressed: () {
                  showNakedDialog<void>(
                    context: ctx,
                    barrierColor: Colors.black54,
                    barrierLabel: barrierLabel,
                    barrierDismissible: true,
                    builder: (_) => const Center(
                      child: Material(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Naked Dialog Content'),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open Naked Dialog'),
              ),
            ),
          ],
        ),
      );

      // Open Material dialog
      await tester.tap(find.byKey(materialOpenKey));
      await tester.pumpAndSettle();
      expect(find.text('Material Dialog Content'), findsOneWidget);

      // Close by tapping barrier
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Material Dialog Content'), findsNothing);

      // Open Naked dialog
      await tester.tap(find.byKey(nakedOpenKey));
      await tester.pumpAndSettle();
      expect(find.text('Naked Dialog Content'), findsOneWidget);

      // Close by tapping barrier
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Naked Dialog Content'), findsNothing);
    });
  });
}
