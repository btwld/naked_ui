import 'package:example/src/testing/context_menu_accessibility_spike.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('secondary click selects and closes exactly once', (
    tester,
  ) async {
    final counters = ContextMenuSpikeCounters();
    await _pumpTrigger(tester, counters);

    await tester.tap(
      find.byKey(ContextMenuSpikeKeys.triggerLink),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await tester.tap(find.byKey(ContextMenuSpikeKeys.itemRename));
    await tester.pump();

    expect(counters.openRequests, 1);
    expect(counters.actualOpens, 1);
    expect(counters.closeRequests, 1);
    expect(counters.actualCloses, 1);
    expect(counters.selections, 1);
    expect(counters.childActivations, 0);
  });

  testWidgets('Link semantic and keyboard entries each open once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final counters = ContextMenuSpikeCounters();
      await _pumpTrigger(tester, counters);
      final link = find.byKey(ContextMenuSpikeKeys.triggerLink);
      final node = tester.getSemantics(link);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.longPress),
        isTrue,
      );
      node.owner!.performAction(node.id, SemanticsAction.longPress);
      await tester.pump();
      expect(counters.openRequests, 1);
      expect(counters.actualOpens, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(counters.lastOpenSource, ContextMenuSpikeOpenSource.shiftF10);
      expect(counters.openRequests, 2);
      expect(counters.actualOpens, 2);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('SelectableText V1 records the duplicate semantic action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: ContextMenuSpikeTrigger(
              variant: ContextMenuSpikeVariant.v1SemanticLongPress,
              childKind: ContextMenuSpikeChildKind.selectableText,
              counters: ContextMenuSpikeCounters(),
            ),
          ),
        ),
      );
      await tester.pump();

      final actionNodes = _semanticNodes(tester)
          .where(
            (node) =>
                node.getSemanticsData().hasAction(SemanticsAction.longPress),
          )
          .toList();
      expect(actionNodes, hasLength(2));
      expect(
        actionNodes.where((node) {
          final data = node.getSemanticsData();
          return data.label.isEmpty && data.value.isEmpty;
        }),
        hasLength(1),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('bottom-right point geometry clamps into the viewport', (
    tester,
  ) async {
    final observations = ContextMenuGeometryObservations();
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: ContextMenuGeometryProbe(observations: observations),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final anchor = find.byKey(ContextMenuSpikeKeys.geometryAnchor);
    await tester.tapAt(
      tester.getCenter(anchor),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    final overlay = tester.getRect(
      find.byKey(ContextMenuSpikeKeys.geometryOverlay),
    );
    final view = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(overlay.left, greaterThanOrEqualTo(0));
    expect(overlay.top, greaterThanOrEqualTo(0));
    expect(overlay.right, lessThanOrEqualTo(view.width));
    expect(overlay.bottom, lessThanOrEqualTo(view.height));
    expect(observations.openRequests, 1);
    expect(observations.actualOpens, 1);
  });
}

Future<void> _pumpTrigger(
  WidgetTester tester,
  ContextMenuSpikeCounters counters,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: ContextMenuSpikeTrigger(
          variant: ContextMenuSpikeVariant.v1SemanticLongPress,
          childKind: ContextMenuSpikeChildKind.link,
          counters: counters,
        ),
      ),
    ),
  );
  await tester.pump();
}

Iterable<SemanticsNode> _semanticNodes(WidgetTester tester) sync* {
  // Flutter 3.41.0 attaches test semantics to this child PipelineOwner rather
  // than rootPipelineOwner; the deprecated accessor is required by the spike's
  // declared-minimum matrix only.
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  final pending = <SemanticsNode>[root];
  while (pending.isNotEmpty) {
    final node = pending.removeLast();
    yield node;
    node.visitChildren((child) {
      pending.add(child);
      return true;
    });
  }
}
