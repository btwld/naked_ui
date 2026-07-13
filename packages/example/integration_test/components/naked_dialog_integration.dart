import 'package:example/api/naked_dialog.0.dart' as dialog_example;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../helpers/test_helpers.dart';

const _basicOpenKey = ValueKey('dialog.open.basic');
const _basicSurfaceKey = ValueKey('dialog.basic.surface');
const _basicCancelKey = ValueKey('dialog.basic.cancel');
const _openKey = ValueKey('alert-dialog.open');
const _removeInvokerKey = ValueKey('alert-dialog.remove-invoker');
const _titleKey = ValueKey('alert-dialog.title');
const _messageKey = ValueKey('alert-dialog.message');
const _messageFocusKey = ValueKey('alert-dialog.message-focus');
const _surfaceKey = ValueKey('alert-dialog.surface');
const _cancelKey = ValueKey('alert-dialog.cancel');
const _confirmKey = ValueKey('alert-dialog.confirm');

Widget _buildAlertApp({
  bool longMessage = false,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: Directionality(textDirection: textDirection, child: child!),
    ),
    home: Scaffold(
      body: Center(
        child: dialog_example.AlertDialogExample(longMessage: longMessage),
      ),
    ),
  );
}

NakedButton _buttonForKey(WidgetTester tester, Key key) {
  return tester.widget<NakedButton>(
    find.descendant(of: find.byKey(key), matching: find.byType(NakedButton)),
  );
}

SemanticsNode? _findSemanticsRole(SemanticsNode root, SemanticsRole role) {
  if (root.getSemanticsData().role == role) return root;
  SemanticsNode? result;
  bool visit(SemanticsNode node) {
    if (node.getSemanticsData().role == role) {
      result = node;
      return false;
    }
    node.visitChildren(visit);
    return result == null;
  }

  root.visitChildren(visit);
  return result;
}

Future<void> _openAlert(
  WidgetTester tester, {
  Widget? app,
  Key readyKey = _titleKey,
}) async {
  await tester.pumpWidget(app ?? _buildAlertApp());
  await tester.pump();
  await tester.tap(find.byKey(_openKey));
  await tester.pumpUntil(
    () => find.byKey(readyKey).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 2),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedDialog Integration Tests', () {
    testWidgets('basic dialog opens and closes through Cancel', (tester) async {
      await tester.pumpWidget(const dialog_example.MyApp());
      await tester.pumpAndSettle();

      expect(find.byKey(_basicSurfaceKey), findsNothing);
      await tester.tap(find.byKey(_basicOpenKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_basicSurfaceKey), findsOneWidget);
      await tester.tap(find.byKey(_basicCancelKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_basicSurfaceKey), findsNothing);
    });

    testWidgets('basic dialog preserves opt-outside dismissal', (tester) async {
      await tester.pumpWidget(const dialog_example.MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_basicOpenKey));
      await tester.pumpAndSettle();
      expect(find.byKey(_basicSurfaceKey), findsOneWidget);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(find.byKey(_basicSurfaceKey), findsNothing);
    });

    testWidgets(
      'keyboard open focuses Cancel, loops, closes, and restores the invoker',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(_buildAlertApp());
          await tester.pump();

          final invokerNode = _buttonForKey(tester, _openKey).focusNode!;
          await tester.pressKeyOn(invokerNode, LogicalKeyboardKey.enter);
          await tester.pumpUntil(
            () => find.byKey(_titleKey).evaluate().isNotEmpty,
            timeout: const Duration(seconds: 2),
          );

          final cancelNode = _buttonForKey(tester, _cancelKey).focusNode!;
          final confirmNode = _buttonForKey(tester, _confirmKey).focusNode!;
          await tester.pumpUntil(
            () => FocusManager.instance.primaryFocus == cancelNode,
            timeout: const Duration(seconds: 2),
          );
          expect(FocusManager.instance.primaryFocus, same(cancelNode));

          final alertNode = _findSemanticsRole(
            tester.getSemantics(find.byType(NakedDialog)),
            SemanticsRole.alertDialog,
          );
          expect(alertNode, isNotNull);
          final alertData = alertNode!.getSemanticsData();
          expect(alertData.role, SemanticsRole.alertDialog);
          expect(alertData.label, 'Delete project');

          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.pump();
          expect(FocusManager.instance.primaryFocus, same(confirmNode));

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(FocusManager.instance.primaryFocus, same(cancelNode));

          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpUntil(
            () => find.byKey(_titleKey).evaluate().isEmpty,
            timeout: const Duration(seconds: 2),
          );
          expect(find.text('Result: cancel; confirmations: 0'), findsOneWidget);
          expect(FocusManager.instance.primaryFocus, same(invokerNode));
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('default barrier stays inert and Escape safely cancels', (
      tester,
    ) async {
      await _openAlert(tester);

      final surfaceRect = tester.getRect(find.byKey(_surfaceKey));
      await tester.tapAt(surfaceRect.topLeft - const Offset(8, 8));
      await tester.pump();
      expect(find.byKey(_titleKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpUntil(
        () => find.byKey(_titleKey).evaluate().isEmpty,
        timeout: const Duration(seconds: 2),
      );
      expect(find.text('Result: dismissed; confirmations: 0'), findsOneWidget);
    });

    testWidgets('platform back safely cancels the alert', (tester) async {
      await _openAlert(tester);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpUntil(
        () => find.byKey(_titleKey).evaluate().isEmpty,
        timeout: const Duration(seconds: 2),
      );

      expect(find.text('Result: dismissed; confirmations: 0'), findsOneWidget);
    });

    testWidgets('destructive action records one callback and visible result', (
      tester,
    ) async {
      await _openAlert(tester, readyKey: _confirmKey);
      await tester.tap(find.byKey(_confirmKey));
      await tester.pumpUntil(
        () => find
            .text('Result: confirm; confirmations: 1')
            .evaluate()
            .isNotEmpty,
        timeout: const Duration(seconds: 2),
      );

      expect(find.byKey(_titleKey), findsNothing);
      expect(find.text('Result: confirm; confirmations: 1'), findsOneWidget);
    });

    testWidgets('removing the invoker before programmatic close is safe', (
      tester,
    ) async {
      await tester.pumpWidget(_buildAlertApp());
      await tester.pump();

      await tester.tap(find.byKey(_removeInvokerKey));
      await tester.pumpUntil(
        () => find.byKey(_titleKey).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 2),
      );
      expect(find.byKey(_removeInvokerKey), findsNothing);

      Navigator.of(tester.element(find.byKey(_titleKey))).pop();
      await tester.pumpUntil(
        () => find.byKey(_titleKey).evaluate().isEmpty,
        timeout: const Duration(seconds: 2),
      );

      expect(find.text('Result: dismissed; confirmations: 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('200% long message starts on readable non-action content', (
      tester,
    ) async {
      await _openAlert(
        tester,
        app: _buildAlertApp(
          longMessage: true,
          textScaler: const TextScaler.linear(2),
        ),
        readyKey: _messageFocusKey,
      );

      final messageFocus = tester.widget<Focus>(find.byKey(_messageFocusKey));
      await tester.pumpUntil(
        () => FocusManager.instance.primaryFocus == messageFocus.focusNode,
        timeout: const Duration(seconds: 2),
      );
      expect(FocusManager.instance.primaryFocus, same(messageFocus.focusNode));
      expect(find.byKey(_messageKey), findsOneWidget);
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byKey(_titleKey)),
        ).scale(10),
        20,
      );

      await tester.ensureVisible(find.byKey(_confirmKey));
      await tester.pump();
      expect(find.byKey(_confirmKey).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      Navigator.of(tester.element(find.byKey(_titleKey))).pop();
      await tester.pumpUntil(
        () => find.byKey(_titleKey).evaluate().isEmpty,
        timeout: const Duration(seconds: 2),
      );
    });

    testWidgets('RTL fixture preserves alert behavior and direction', (
      tester,
    ) async {
      await _openAlert(
        tester,
        app: _buildAlertApp(textDirection: TextDirection.rtl),
      );
      expect(
        Directionality.of(tester.element(find.byKey(_titleKey))),
        TextDirection.rtl,
      );

      await tester.tap(find.byKey(_cancelKey));
      await tester.pumpUntil(
        () => find.byKey(_titleKey).evaluate().isEmpty,
        timeout: const Duration(seconds: 2),
      );
      expect(find.text('Result: cancel; confirmations: 0'), findsOneWidget);
    });
  });
}
