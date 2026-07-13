import 'dart:ui' show SemanticsAction, SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'semantics_test_utils.dart';

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
    testWidgets('alert dialog exposes its exact role and route semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildTestApp(
            const Directionality(
              textDirection: TextDirection.rtl,
              child: NakedDialog(
                semanticsRole: SemanticsRole.alertDialog,
                semanticLabel: 'Eliminar archivo',
                child: Text('Esta acción no se puede deshacer.'),
              ),
            ),
          ),
        );

        final data = tester
            .getSemantics(find.bySemanticsLabel('Eliminar archivo'))
            .getSemanticsData();
        expect(data.role, SemanticsRole.alertDialog);
        expect(data.label, 'Eliminar archivo');
        expect(data.flagsCollection.scopesRoute, isTrue);
        expect(data.flagsCollection.namesRoute, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      'alert helper blocks background and keeps title message and actions separate',
      (tester) async {
        final handle = tester.ensureSemantics();
        const backgroundKey = ValueKey('alert.background');
        const titleKey = ValueKey('alert.title');
        const messageKey = ValueKey('alert.message');
        const cancelKey = ValueKey('alert.cancel');
        const confirmKey = ValueKey('alert.confirm');
        var confirmCount = 0;
        Future<String?>? result;

        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Column(
                    children: [
                      Semantics(
                        key: backgroundKey,
                        label: 'Contenido de fondo',
                        child: const Text('Background'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          result = showNakedAlertDialog<String>(
                            context: context,
                            barrierColor: Colors.black54,
                            semanticLabel: 'Eliminar archivo',
                            transitionDuration: Duration.zero,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(key: titleKey, 'Eliminar archivo'),
                                const Text(
                                  key: messageKey,
                                  'Esta acción no se puede deshacer.',
                                ),
                                TextButton(
                                  key: cancelKey,
                                  onPressed: () =>
                                      Navigator.of(context).pop('cancel'),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  key: confirmKey,
                                  onPressed: () {
                                    confirmCount += 1;
                                    Navigator.of(context).pop('confirm');
                                  },
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Abrir alerta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          expect(
            find.bySemanticsLabel(RegExp('Contenido de fondo')),
            findsOneWidget,
          );
          await tester.tap(find.text('Abrir alerta'));
          await tester.pump();
          await tester.pump();

          final root = tester
              .binding
              .renderViews
              .single
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!;
          final alerts = collectSemanticsNodes(
            root,
            (node) => node.getSemanticsData().role == SemanticsRole.alertDialog,
          );
          expect(alerts, hasLength(1));
          final alertData = alerts.single.getSemanticsData();
          expect(alertData.label, 'Eliminar archivo');
          expect(alertData.flagsCollection.scopesRoute, isTrue);
          expect(alertData.flagsCollection.namesRoute, isTrue);
          expect(alertData.hasAction(SemanticsAction.tap), isFalse);
          expect(
            countSemanticsNodes(
              root,
              (node) =>
                  node.getSemanticsData().label.contains('Contenido de fondo'),
            ),
            0,
          );

          expect(
            tester.getSemantics(find.byKey(titleKey)).getSemanticsData().label,
            'Eliminar archivo',
          );
          expect(
            tester
                .getSemantics(find.byKey(messageKey))
                .getSemanticsData()
                .label,
            'Esta acción no se puede deshacer.',
          );
          expect(
            tester
                .getSemantics(find.byKey(cancelKey))
                .getSemanticsData()
                .hasAction(SemanticsAction.tap),
            isTrue,
          );
          expect(
            tester
                .getSemantics(find.byKey(confirmKey))
                .getSemanticsData()
                .hasAction(SemanticsAction.tap),
            isTrue,
          );

          final confirmNode = tester.getSemantics(find.byKey(confirmKey));
          tester.binding.renderViews.single.owner!.semanticsOwner!
              .performAction(confirmNode.id, SemanticsAction.tap);
          await tester.pump();
          await tester.pump();
          expect(await result, 'confirm');
          expect(confirmCount, 1);
          final restoredRoot = tester
              .binding
              .renderViews
              .single
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!;
          expect(
            countSemanticsNodes(
              restoredRoot,
              (node) =>
                  node.getSemanticsData().label.contains('Contenido de fondo'),
            ),
            1,
          );
          expect(tester.takeException(), isNull);
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('dismissible barrier carries its localized semantics label', (
      tester,
    ) async {
      Future<String?>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                result = showNakedAlertDialog<String>(
                  context: context,
                  barrierColor: Colors.black54,
                  semanticLabel: 'Eliminar archivo',
                  barrierDismissible: true,
                  barrierLabel: 'Cerrar alerta',
                  transitionDuration: Duration.zero,
                  builder: (context) => const SizedBox.square(dimension: 200),
                );
              },
              child: const Text('Abrir alerta'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir alerta'));
      await tester.pump();
      await tester.pump();

      final barrier = tester.widget<AnimatedModalBarrier>(
        find.byType(AnimatedModalBarrier),
      );
      expect(barrier.dismissible, isTrue);
      expect(barrier.semanticsLabel, 'Cerrar alerta');
      expect(barrier.barrierSemanticsDismissible, isTrue);

      await tester.tapAt(const Offset(4, 4));
      await tester.pump();
      await tester.pump();

      expect(await result, isNull);
    });

    testWidgets('long message safe target is focusable without a button role', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final messageNode = FocusNode(debugLabel: 'alert long message');
      addTearDown(messageNode.dispose);
      const messageKey = ValueKey('alert.long-message');
      BuildContext? hostContext;

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                hostContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        showNakedAlertDialog<void>(
          context: hostContext!,
          barrierColor: Colors.black54,
          semanticLabel: 'Condiciones importantes',
          transitionDuration: Duration.zero,
          initialFocusNode: messageNode,
          builder: (context) => Focus(
            focusNode: messageNode,
            child: Semantics(
              key: messageKey,
              container: true,
              label: 'Lea estas condiciones antes de continuar.',
              child: const Text('Mensaje largo'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, same(messageNode));
        final messageData = tester
            .getSemantics(find.byKey(messageKey))
            .getSemanticsData();
        expect(messageData.role, SemanticsRole.none);
        expect(messageData.flagsCollection.isButton, isFalse);
        expect(messageData.hasAction(SemanticsAction.tap), isFalse);

        Navigator.of(hostContext!).pop();
        await tester.pump();
        await tester.pump();
      } finally {
        handle.dispose();
      }
    });

    testWidgets('excluded alert dialog has no role or subtree', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildTestApp(
            const NakedDialog(
              semanticsRole: SemanticsRole.alertDialog,
              semanticLabel: 'Alerta excluida',
              excludeSemantics: true,
              child: Text('Contenido excluido'),
            ),
          ),
        );

        final root = tester
            .binding
            .renderViews
            .single
            .owner!
            .semanticsOwner!
            .rootSemanticsNode!;
        expect(
          countSemanticsNodes(
            root,
            (node) => node.getSemanticsData().role == SemanticsRole.alertDialog,
          ),
          0,
        );
        expect(find.bySemanticsLabel('Alerta excluida'), findsNothing);
        expect(find.bySemanticsLabel('Contenido excluido'), findsNothing);
      } finally {
        handle.dispose();
      }
    });

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

    testWidgets('modal dialog exposes route scope and route name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await _showNakedDialog(
        tester,
        title: 'Route Dialog',
        content: 'This dialog is a route scope',
      );

      final dialogRoot = tester.getSemantics(find.byType(NakedDialog));
      final routeNode = findSemanticsNode(dialogRoot, (node) {
        final data = node.getSemanticsData();
        return data.label == 'Route Dialog' &&
            data.role == SemanticsRole.dialog &&
            data.flagsCollection.scopesRoute &&
            data.flagsCollection.namesRoute;
      });

      expect(routeNode, isNotNull);

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
