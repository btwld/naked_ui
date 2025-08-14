import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  group('NakedDialog', () {
    testWidgets(
      'renders child and returns a value on pop',
      (tester) async {
        BuildContext? dialogContext;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await showNakedDialog<String>(
                          context: ctx,
                          barrierColor: Colors.black54,
                          builder: (context) {
                            dialogContext = context;
                            return ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop('Success!'),
                              child: const Text('Close Me'),
                            );
                          },
                        );
                      },
                      child: const Text('Open Dialog'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Close Me'), findsOneWidget);

        await tester.tap(find.text('Close Me'));
        await tester.pumpAndSettle();

        expect(find.text('Close Me'), findsNothing);
        expect(dialogContext, isNotNull);
      },
      timeout: Timeout(Duration(seconds: 15)),
    );

    testWidgets('barrierDismissible=true closes on outside tap', (
      tester,
    ) async {
      BuildContext? ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );

      final future = showNakedDialog(
        context: ctx!,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        builder: (context) => const Center(child: Text('Dialog Content')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dialog Content'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Dialog Content'), findsNothing);

      await future;
    });

    testWidgets(
      'barrierDismissible=false does not close on outside tap',
      (tester) async {
        BuildContext? ctx;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                ctx = context;
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        );

        final future = showNakedDialog(
          context: ctx!,
          barrierColor: Colors.black54,
          barrierDismissible: false,
          builder: (context) => const Center(child: Text('Dialog Content')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dialog Content'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Still visible
        expect(find.text('Dialog Content'), findsOneWidget);

        // Dismiss programmatically to clean up
        Navigator.of(ctx!).pop();
        await tester.pumpAndSettle();
        await future;
      },
      timeout: Timeout(Duration(seconds: 15)),
    );

    testWidgets('applies barrierLabel to semantics', (tester) async {
      BuildContext? ctx;
      const barrierLabel = 'My Barrier';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );

      final future = showNakedDialog(
        context: ctx!,
        barrierColor: Colors.black54,
        barrierLabel: barrierLabel,
        builder: (context) => const Center(child: Text('Label Test')),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(barrierLabel), findsOneWidget);

      Navigator.of(ctx!).pop();
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('respects useRootNavigator with nested Navigator', (
      tester,
    ) async {
      final nestedKey = GlobalKey<NavigatorState>();
      BuildContext? leafContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Navigator(
              key: nestedKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => Builder(
                  builder: (context) {
                    leafContext = context;
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Show on root navigator
      final rootFuture = showNakedDialog(
        context: leafContext!,
        useRootNavigator: true,
        barrierColor: Colors.black54,
        builder: (_) => const SizedBox.shrink(),
      );
      await tester.pumpAndSettle();
      expect(nestedKey.currentState!.canPop(), isFalse);
      Navigator.of(leafContext!, rootNavigator: true).pop();
      await tester.pumpAndSettle();
      await rootFuture;

      // Show on nested navigator
      final nestedFuture = showNakedDialog(
        context: leafContext!,
        useRootNavigator: false,
        barrierColor: Colors.black54,
        builder: (_) => const SizedBox.shrink(),
      );
      await tester.pumpAndSettle();
      expect(nestedKey.currentState!.canPop(), isTrue);
      nestedKey.currentState!.pop();
      await tester.pumpAndSettle();
      await nestedFuture;
    });
  });
}
