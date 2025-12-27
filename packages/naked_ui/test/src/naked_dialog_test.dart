import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  group('NakedDialog', () {
    testWidgets(
      'renders child and returns a value on pop',
      (tester) async {
        String? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showNakedDialog<String>(
                        context: ctx,
                        barrierColor: Colors.black54,
                        builder: (context) => ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop('Success!'),
                          child: const Text('Close Me'),
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Close Me'), findsOneWidget);

        await tester.tap(find.text('Close Me'));
        await tester.pumpAndSettle();

        expect(find.text('Close Me'), findsNothing);
        expect(result, 'Success!');
      },
      timeout: const Timeout(Duration(seconds: 15)),
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
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets('ESC dismisses when barrierDismissible=true', (tester) async {
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

      final fut = showNakedDialog(
        context: ctx!,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        builder: (_) => const Center(child: Text('Dialog Content')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dialog Content'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Dialog Content'), findsNothing);
      await fut;
    });

    testWidgets('ESC does not dismiss when barrierDismissible=false', (
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

      final fut = showNakedDialog(
        context: ctx!,
        barrierColor: Colors.black54,
        barrierDismissible: false,
        builder: (_) => const Center(child: Text('Dialog Content')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dialog Content'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Still visible
      expect(find.text('Dialog Content'), findsOneWidget);

      Navigator.of(ctx!).pop();
      await tester.pumpAndSettle();
      await fut;
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

    testWidgets('Tab traversal stays within dialog (closed loop)', (
      tester,
    ) async {
      BuildContext? ctx;
      final outsideFocus = FocusNode(debugLabel: 'outside');

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    focusNode: outsideFocus,
                    onPressed: () {},
                    child: const Text('Outside Button'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      final fut = showNakedDialog(
        context: ctx!,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        builder: (_) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              // Ensure initial focus is inside the dialog.
              ElevatedButton(
                autofocus: true,
                onPressed: null,
                child: Text('A'),
              ),
              SizedBox(height: 8),
              ElevatedButton(onPressed: null, child: Text('B')),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      // Step focus forward multiple times; it should remain within the dialog.
      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          outsideFocus.hasFocus,
          isFalse,
          reason: 'Focus should remain trapped inside the dialog',
        );
      }

      // Cleanup
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await fut;
    });
  });
}
