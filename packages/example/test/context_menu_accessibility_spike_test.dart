import 'package:example/src/testing/context_menu_accessibility_spike.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'V1 adds exactly one longPress action without changing the Link node',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final counters = ContextMenuSpikeCounters();

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

      final trigger = find.byKey(ContextMenuSpikeKeys.triggerLink);
      expect(trigger, findsOneWidget);
      final data = tester.getSemantics(trigger).getSemanticsData();
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.label, 'Naked UI documentation');
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.longPress), isTrue);

      final longPressNodes = _semanticNodes(tester)
          .where(
            (node) =>
                node.getSemanticsData().hasAction(SemanticsAction.longPress),
          )
          .toList();
      expect(longPressNodes, hasLength(1));

      final node = tester.getSemantics(trigger);
      node.owner!.performAction(node.id, SemanticsAction.longPress);
      await tester.pump();

      expect(counters.openRequests, 1);
      expect(counters.actualOpens, 1);
      expect(find.byKey(ContextMenuSpikeKeys.menu), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('V0 to V1 records exact node-level contract failures', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final childKind in ContextMenuSpikeChildKind.values) {
      await _pumpTrigger(
        tester,
        counters: ContextMenuSpikeCounters(),
        childKind: childKind,
        variant: ContextMenuSpikeVariant.v0PhysicalAndKeyboard,
      );
      final v0 = _treeSnapshot(tester);
      final v0LongPressCount = _semanticNodes(tester)
          .where(
            (node) =>
                node.getSemanticsData().hasAction(SemanticsAction.longPress),
          )
          .length;

      await _pumpTrigger(
        tester,
        counters: ContextMenuSpikeCounters(),
        childKind: childKind,
        variant: ContextMenuSpikeVariant.v1SemanticLongPress,
      );
      final actionNodes = _semanticNodes(tester)
          .where(
            (node) =>
                node.getSemanticsData().hasAction(SemanticsAction.longPress),
          )
          .toList();

      final v1 = _treeSnapshot(tester);
      if (childKind == ContextMenuSpikeChildKind.link) {
        expect(v0LongPressCount, 0);
        expect(actionNodes, hasLength(1));
        expect(v1, v0, reason: 'Link must keep its single native node');
        expect(
          actionNodes.single.getSemanticsData().label,
          'Naked UI documentation',
        );
      } else {
        final expectedNativeActions =
            childKind == ContextMenuSpikeChildKind.selectableText ? 1 : 0;
        expect(v0LongPressCount, expectedNativeActions);
        expect(actionNodes, hasLength(expectedNativeActions + 1));
        final unlabeledActionNodes = actionNodes.where((node) {
          final data = node.getSemanticsData();
          return data.label.isEmpty && data.value.isEmpty;
        }).toList();
        expect(unlabeledActionNodes, hasLength(1));
        final actionData = unlabeledActionNodes.single.getSemanticsData();
        expect(actionData.label, isEmpty);
        expect(actionData.role, SemanticsRole.none);
        expect(actionData.flagsCollection.isButton, isFalse);
        if (childKind == ContextMenuSpikeChildKind.selectableText) {
          expect(v1, hasLength(v0.length + 1));
          expect(
            _treeSnapshot(tester, omitUnlabeledLongPressNode: true),
            v0,
            reason: 'SelectableText native node must otherwise stay intact',
          );
        } else {
          expect(
            v1,
            v0,
            reason: 'row must keep its existing focus and label nodes',
          );
        }
      }
    }
    semantics.dispose();
  });

  testWidgets(
    'secondary click opens once and primary Link tap passes through',
    (tester) async {
      final counters = ContextMenuSpikeCounters();
      await _pumpTrigger(tester, counters: counters);
      final trigger = find.byKey(ContextMenuSpikeKeys.triggerLink);

      await tester.tap(trigger);
      await tester.pump();
      expect(counters.childActivations, 1);
      expect(counters.openRequests, 0);

      final secondary = await tester.createGesture(
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      final center = tester.getCenter(trigger);
      await secondary.addPointer(location: center);
      await secondary.down(center);
      await tester.pump();
      expect(counters.openRequests, 0);
      expect(counters.actualOpens, 0);

      await secondary.up();
      await tester.pump();
      await secondary.removePointer();
      expect(counters.openRequests, 1);
      expect(counters.actualOpens, 1);
      expect(counters.childActivations, 1);
      expect(
        counters.lastOpenSource,
        ContextMenuSpikeOpenSource.secondaryPointer,
      );
      expect(counters.lastLocalInvocation, isNotNull);
    },
  );

  testWidgets(
    'physical long press opens, while a pre-threshold scroll cancels',
    (tester) async {
      final counters = ContextMenuSpikeCounters();
      await _pumpTrigger(
        tester,
        counters: counters,
        childKind: ContextMenuSpikeChildKind.row,
      );
      await tester.longPress(find.byKey(ContextMenuSpikeKeys.triggerRow));
      await tester.pump();
      expect(counters.openRequests, 1);
      expect(counters.actualOpens, 1);
      expect(
        counters.lastOpenSource,
        ContextMenuSpikeOpenSource.physicalLongPress,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      final scrollCounters = ContextMenuSpikeCounters();
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            key: ContextMenuSpikeKeys.scroll,
            children: [
              ContextMenuSpikeTrigger(
                variant: ContextMenuSpikeVariant.v1SemanticLongPress,
                childKind: ContextMenuSpikeChildKind.row,
                counters: scrollCounters,
              ),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      );
      await tester.pump();
      final row = find.byKey(ContextMenuSpikeKeys.triggerRow);
      final scrollable = Scrollable.of(tester.element(row));
      await tester.timedDrag(
        row,
        const Offset(0, -300),
        kLongPressTimeout ~/ 4,
      );
      await tester.pump(kLongPressTimeout);

      expect(scrollable.position.pixels, greaterThan(0));
      expect(scrollCounters.openRequests, 0);
      expect(scrollCounters.actualOpens, 0);
    },
  );

  testWidgets('same long-press gesture cannot activate an inserted item', (
    tester,
  ) async {
    final counters = ContextMenuSpikeCounters();
    await _pumpTrigger(
      tester,
      counters: counters,
      childKind: ContextMenuSpikeChildKind.row,
    );
    final row = find.byKey(ContextMenuSpikeKeys.triggerRow);
    final gesture = await tester.startGesture(
      tester.getCenter(row),
      kind: PointerDeviceKind.touch,
    );

    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    expect(counters.openRequests, 1);
    expect(counters.actualOpens, 1);
    final item = find.byKey(ContextMenuSpikeKeys.itemRename);
    expect(item, findsOneWidget);

    await gesture.moveTo(tester.getCenter(item));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(counters.selections, 0);
    expect(counters.closeRequests, 0);
    expect(counters.actualCloses, 0);
    expect(find.byKey(ContextMenuSpikeKeys.menu), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(counters.closeRequests, 1);
    expect(counters.actualCloses, 1);
  });

  testWidgets('primary selectable-text drag remains non-destructive', (
    tester,
  ) async {
    final counters = ContextMenuSpikeCounters();
    await _pumpTrigger(
      tester,
      counters: counters,
      childKind: ContextMenuSpikeChildKind.selectableText,
    );
    final selectable = find.byKey(ContextMenuSpikeKeys.triggerSelectable);

    await tester.drag(
      selectable,
      const Offset(120, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    expect(counters.openRequests, 0);
    expect(counters.textSelectionChanges, greaterThan(0));
    expect(counters.lastTextSelection!.isCollapsed, isFalse);
  });

  testWidgets(
    'Shift+F10 and Context Menu key clear stale pointer coordinates',
    (tester) async {
      final counters = ContextMenuSpikeCounters();
      await _pumpTrigger(tester, counters: counters);
      final trigger = find.byKey(ContextMenuSpikeKeys.triggerLink);
      await _focusFirst(tester);

      await tester.tap(
        trigger,
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(counters.lastLocalInvocation, isNotNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      await _sendShiftF10(tester);
      await tester.pump();
      expect(counters.lastOpenSource, ContextMenuSpikeOpenSource.shiftF10);
      expect(counters.lastLocalInvocation, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(
        counters.lastOpenSource,
        ContextMenuSpikeOpenSource.contextMenuKey,
      );
      expect(counters.lastLocalInvocation, isNull);
      expect(counters.openRequests, 3);
      expect(counters.actualOpens, 3);
      expect(counters.closeRequests, 2);
      expect(counters.actualCloses, 2);
    },
  );

  testWidgets('selection and close lifecycle callbacks are exactly once', (
    tester,
  ) async {
    final counters = ContextMenuSpikeCounters();
    await _pumpTrigger(tester, counters: counters);
    final trigger = find.byKey(ContextMenuSpikeKeys.triggerLink);
    await tester.tap(
      trigger,
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
    expect(counters.lastSelection, 'rename');
    expect(counters.events, [
      'open-request:secondaryPointer',
      'actual-open',
      'selection:rename',
      'close-request',
      'actual-close',
    ]);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(counters.closeRequests, 1);
    expect(counters.actualCloses, 1);
  });

  testWidgets('outside close and rapid reopen remain idempotent', (
    tester,
  ) async {
    final counters = ContextMenuSpikeCounters();
    await _pumpTrigger(tester, counters: counters);
    final trigger = find.byKey(ContextMenuSpikeKeys.triggerLink);

    await tester.tap(
      trigger,
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await tester.tapAt(const Offset(12, 12));
    await tester.pump();
    expect(counters.closeRequests, 1);
    expect(counters.actualCloses, 1);

    await tester.tap(
      trigger,
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await tester.tap(
      trigger,
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(counters.openRequests, 3);
    expect(counters.actualOpens, 3);
    expect(counters.closeRequests, 2);
    expect(counters.actualCloses, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(counters.closeRequests, 3);
    expect(counters.actualCloses, 3);
    expect(counters.events, [
      'open-request:secondaryPointer',
      'actual-open',
      'close-request',
      'actual-close',
      'open-request:secondaryPointer',
      'actual-open',
      'close-request',
      'actual-close',
      'open-request:secondaryPointer',
      'actual-open',
      'close-request',
      'actual-close',
    ]);
  });

  testWidgets('boundary and first-enabled initial-focus axes stay separate', (
    tester,
  ) async {
    final boundary = ContextMenuSpikeCounters();
    await _pumpTrigger(tester, counters: boundary);
    await _focusFirst(tester);
    await _sendShiftF10(tester);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(boundary.initialFocusObservation, 'boundary');
    expect(boundary.focusedItem, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'context-menu-spike.link',
    );

    final firstEnabled = ContextMenuSpikeCounters();
    await _pumpTrigger(
      tester,
      counters: firstEnabled,
      initialFocus: ContextMenuSpikeInitialFocus.firstEnabledItem,
      disableFirstItem: true,
    );
    await _focusFirst(tester);
    await _sendShiftF10(tester);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(firstEnabled.initialFocusObservation, 'delete');
    expect(firstEnabled.focusedItem, 'delete');
  });

  testWidgets('disabled wrapper has no trigger action but Link stays native', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final counters = ContextMenuSpikeCounters();
    await _pumpTrigger(tester, counters: counters, enabled: false);
    final trigger = find.byKey(ContextMenuSpikeKeys.triggerLink);
    final data = tester.getSemantics(trigger).getSemanticsData();
    expect(data.flagsCollection.isLink, isTrue);
    expect(data.hasAction(SemanticsAction.longPress), isFalse);

    await tester.tap(
      trigger,
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(counters.openRequests, 0);
    await tester.tap(trigger);
    await tester.pump();
    expect(counters.childActivations, 1);
    semantics.dispose();
  });

  testWidgets('open trigger can be removed without stale focus or callbacks', (
    tester,
  ) async {
    final counters = ContextMenuSpikeCounters();
    var show = true;
    late StateSetter setState;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, update) {
            setState = update;
            return show
                ? ContextMenuSpikeTrigger(
                    variant: ContextMenuSpikeVariant.v1SemanticLongPress,
                    childKind: ContextMenuSpikeChildKind.link,
                    counters: counters,
                  )
                : const SizedBox();
          },
        ),
      ),
    );
    await tester.tap(
      find.byKey(ContextMenuSpikeKeys.triggerLink),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    setState(() => show = false);
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(ContextMenuSpikeKeys.menu), findsNothing);
    expect(counters.actualCloses, lessThanOrEqualTo(1));
  });

  testWidgets('geometry stays in bounds at all four viewport edges', (
    tester,
  ) async {
    const anchorSize = Size(80, 48);
    const overlaySize = Size(184, 88);
    const viewport = Size(800, 600);
    final cases = <Offset>[
      Offset.zero,
      Offset(viewport.width - anchorSize.width, 0),
      Offset(0, viewport.height - anchorSize.height),
      Offset(
        viewport.width - anchorSize.width,
        viewport.height - anchorSize.height,
      ),
    ];

    for (final anchorOffset in cases) {
      final observations = ContextMenuGeometryObservations();
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Positioned(
                left: anchorOffset.dx,
                top: anchorOffset.dy,
                child: ContextMenuGeometryProbe(
                  observations: observations,
                  anchorSize: anchorSize,
                  overlaySize: overlaySize,
                ),
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
      final rect = tester.getRect(
        find.byKey(ContextMenuSpikeKeys.geometryOverlay),
      );
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(viewport.width));
      expect(rect.bottom, lessThanOrEqualTo(viewport.height));
      expect(observations.openRequests, 1);
      expect(observations.actualOpens, 1);
    }
  });

  testWidgets('geometry converts transformed local input to overlay space', (
    tester,
  ) async {
    final observations = ContextMenuGeometryObservations();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Transform.scale(
            scale: 1.5,
            alignment: Alignment.topLeft,
            child: ContextMenuGeometryProbe(observations: observations),
          ),
        ),
      ),
    );
    await tester.pump();
    final anchor = find.byKey(ContextMenuSpikeKeys.geometryAnchor);
    final point = tester.getTopLeft(anchor) + const Offset(75, 30);
    await tester.tapAt(
      point,
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    final overlay = tester.getTopLeft(
      find.byKey(ContextMenuSpikeKeys.geometryOverlay),
    );
    expect(observations.rawMenuPosition, observations.requestedLocalPosition);
    expect(overlay, offsetMoreOrLessEquals(point, epsilon: 0.01));
    expect(
      observations.naiveAnchorPlusLocalPoint,
      isNot(offsetMoreOrLessEquals(point, epsilon: 1)),
    );
  });

  testWidgets('geometry survives scroll, translation, RTL, and 200% text', (
    tester,
  ) async {
    final observations = ContextMenuGeometryObservations();
    final scrollController = ScrollController(initialScrollOffset: 120);
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                controller: scrollController,
                child: SizedBox(
                  height: 1000,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 240),
                      child: Transform.translate(
                        offset: const Offset(36, 24),
                        child: ContextMenuGeometryProbe(
                          observations: observations,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final anchor = find.byKey(ContextMenuSpikeKeys.geometryAnchor);
    final point = tester.getCenter(anchor);
    await tester.tapAt(
      point,
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    expect(scrollController.offset, 120);
    expect(
      tester.getTopLeft(find.byKey(ContextMenuSpikeKeys.geometryOverlay)),
      offsetMoreOrLessEquals(point, epsilon: 0.01),
    );
    expect(observations.rawMenuPosition, observations.requestedLocalPosition);
  });
}

Future<void> _pumpTrigger(
  WidgetTester tester, {
  required ContextMenuSpikeCounters counters,
  ContextMenuSpikeVariant variant = ContextMenuSpikeVariant.v1SemanticLongPress,
  ContextMenuSpikeChildKind childKind = ContextMenuSpikeChildKind.link,
  ContextMenuSpikeInitialFocus initialFocus =
      ContextMenuSpikeInitialFocus.boundary,
  bool enabled = true,
  bool disableFirstItem = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: ContextMenuSpikeTrigger(
          variant: variant,
          childKind: childKind,
          counters: counters,
          initialFocus: initialFocus,
          enabled: enabled,
          disableFirstItem: disableFirstItem,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _focusFirst(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

Future<void> _sendShiftF10(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.f10);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
}

List<String> _treeSnapshot(
  WidgetTester tester, {
  bool omitUnlabeledLongPressNode = false,
}) => _semanticNodes(tester)
    .where((node) {
      final data = node.getSemanticsData();
      return !omitUnlabeledLongPressNode ||
          data.label.isNotEmpty ||
          data.value.isNotEmpty ||
          !data.hasAction(SemanticsAction.longPress);
    })
    .map((node) {
      final data = node.getSemanticsData();
      final actionsWithoutLongPress =
          data.actions & ~SemanticsAction.longPress.index;
      return <Object?>[
        data.role,
        data.flagsCollection.toString(),
        actionsWithoutLongPress,
        data.label,
        data.value,
        data.hint,
        data.tooltip,
        data.textDirection,
        node.rect,
      ].join('|');
    })
    .toList();

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
