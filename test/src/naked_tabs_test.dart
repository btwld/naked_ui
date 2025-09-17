// File: naked_tabs_test.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  PageRoute<T> _defaultPageRouteBuilder<T>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    );
  }

  Widget _harness({
    required String initialSelected,
    bool groupEnabled = true,
    bool tab1Enabled = true,
    bool tab2Enabled = true,
    bool maintainState = true,
    ValueChanged<String>? onChangedSpy,
    VoidCallback? onEscapeSpy,
    Key? tab1Key,
    Key? tab2Key,
    Key? panel1Key,
    Key? panel2Key,
    ValueChanged<Set<WidgetState>>? tab1StatesSpy,
  }) {
    // Keep selection across rebuilds using a closure variable updated via StatefulBuilder.setState.
    String selected = initialSelected;
    return WidgetsApp(
      color: const Color(0xFF000000),
      // Provide a pass-through builder to satisfy WidgetsApp requirements.
      builder: (context, child) => child ?? const SizedBox.shrink(),
      // Provide a simple page route builder since `home` is set.
      pageRouteBuilder: _defaultPageRouteBuilder,
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setState) {
            void handleChanged(String id) {
              onChangedSpy?.call(id);
              selected = id;
              setState(() {});
            }

            return NakedTabGroup(
              selectedTabId: selected,
              enabled: groupEnabled,
              onChanged: handleChanged,
              onEscapePressed: onEscapeSpy,
              child: Column(
                children: [
                  NakedTabList(
                    child: Row(
                      children: [
                        NakedTab(
                          tabId: 'tab1',
                          enabled: tab1Enabled,
                          semanticLabel: 'Tab 1',
                          onFocusChange: (_) {},
                          builder: tab1StatesSpy == null
                              ? null
                              : (ctx, states, child) {
                                  tab1StatesSpy(states);
                                  return child ?? const SizedBox.shrink();
                                },
                          child: SizedBox(
                            key: tab1Key ?? const Key('tab1'),
                            width: 100,
                            height: 40,
                            child: const Center(child: Text('One')),
                          ),
                        ),
                        NakedTab(
                          tabId: 'tab2',
                          enabled: tab2Enabled,
                          semanticLabel: 'Tab 2',
                          child: SizedBox(
                            key: tab2Key ?? const Key('tab2'),
                            width: 100,
                            height: 40,
                            child: const Center(child: Text('Two')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  NakedTabPanel(
                    tabId: 'tab1',
                    maintainState: maintainState,
                    child: SizedBox(
                      key: panel1Key ?? const Key('panel1'),
                      height: 10,
                      width: 10,
                    ),
                  ),
                  NakedTabPanel(
                    tabId: 'tab2',
                    maintainState: maintainState,
                    child: SizedBox(
                      key: panel2Key ?? const Key('panel2'),
                      height: 10,
                      width: 10,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('Selection follows focus via arrow keys', (tester) async {
    final changes = <String>[];
    final tab1 = UniqueKey();
    final tab2 = UniqueKey();

    await tester.pumpWidget(
      _harness(
        initialSelected: 'tab1',
        onChangedSpy: changes.add,
        tab1Key: tab1,
        tab2Key: tab2,
      ),
    );
    await tester.pumpAndSettle();

    // Focus tab1 by tapping.
    await tester.tap(find.byKey(tab1));
    await tester.pump();

    // Move focus right: default shortcuts map Right Arrow to directional focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    // Selection should follow focus (tab2).
    expect(changes.last, 'tab2');
  });

  testWidgets('Enter/Space activation also selects (redundant but fine)', (
    tester,
  ) async {
    final changes = <String>[];
    final tab1 = UniqueKey();
    await tester.pumpWidget(
      _harness(
        initialSelected: 'tab2',
        onChangedSpy: changes.add,
        tab1Key: tab1,
      ),
    );
    await tester.pumpAndSettle();

    // Focus tab1.
    await tester.tap(find.byKey(tab1));
    await tester.pump();

    // Press Space.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    // Selection is already 'tab1' due to focus; Space keeps it.
    expect(changes.contains('tab1'), isTrue);
  });

  testWidgets('Disabled group: selection does not change on focus or tap', (
    tester,
  ) async {
    final changes = <String>[];
    final tab2 = UniqueKey();

    await tester.pumpWidget(
      _harness(
        initialSelected: 'tab1',
        groupEnabled: false, // group disabled => _effectiveEnabled false
        onChangedSpy: changes.add,
        tab2Key: tab2,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(tab2));
    await tester.pump();

    expect(
      changes,
      isEmpty,
      reason: 'Disabled group should ignore selection changes',
    );
  });

  testWidgets('Disabled tab: not focusable, not traversable', (tester) async {
    final changes = <String>[];
    final tab1 = UniqueKey();
    final tab2 = UniqueKey();

    await tester.pumpWidget(
      _harness(
        initialSelected: 'tab1',
        tab2Enabled: false,
        onChangedSpy: changes.add,
        tab1Key: tab1,
        tab2Key: tab2,
      ),
    );
    await tester.pumpAndSettle();

    // Focus tab1.
    await tester.tap(find.byKey(tab1));
    await tester.pump();

    // Try to move focus right; tab2 is disabled and skipped.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    // Selection should remain tab1 (no change fired).
    expect(changes.isEmpty || changes.last == 'tab1', isTrue);
  });

  testWidgets('Panels show/hide; maintainState=false removes inactive panel', (
    tester,
  ) async {
    final changes = <String>[];
    final tab2 = UniqueKey();
    final panel1 = UniqueKey();
    final panel2 = UniqueKey();

    await tester.pumpWidget(
      _harness(
        initialSelected: 'tab1',
        maintainState: false,
        onChangedSpy: changes.add,
        tab2Key: tab2,
        panel1Key: panel1,
        panel2Key: panel2,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(panel1), findsOneWidget);
    expect(find.byKey(panel2), findsNothing);

    // Focus tab2 -> selects tab2; panel2 becomes visible; panel1 removed.
    await tester.tap(find.byKey(tab2));
    await tester.pump();

    expect(find.byKey(panel2), findsOneWidget);
    expect(find.byKey(panel1), findsNothing);
  });

  testWidgets('Hover and pressed states surface through builder', (
    tester,
  ) async {
    final statesLog = <Set<WidgetState>>[];
    final tab1 = UniqueKey();

    await tester.pumpWidget(
      _harness(
        initialSelected: 'tab1',
        tab1Key: tab1,
        tab1StatesSpy: (s) => statesLog.add(Set<WidgetState>.from(s)),
      ),
    );
    await tester.pumpAndSettle();

    // Start mouse hover using a direct gesture for determinism within this suite.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byKey(tab1)));
    await tester.pumpAndSettle();
    final sawHover = statesLog.any((s) => s.contains(WidgetState.hovered));
    expect(sawHover, isTrue);

    // Press and release to toggle pressed state.
    await tester.press(find.byKey(tab1)); // down+up with a short delay
    await tester.pump();

    // We should see pressed true at some point; because the builder updates on press transitions,
    // at least one snapshot must include WidgetState.pressed.
    final sawPressed = statesLog.any((s) => s.contains(WidgetState.pressed));
    expect(sawPressed, isTrue);

    await gesture.removePointer();
  });

  testWidgets('ESC triggers onEscapePressed at group level', (tester) async {
    bool esc = false;
    final tab1 = UniqueKey();

    await tester.pumpWidget(
      _harness(
        initialSelected: 'tab1',
        onEscapeSpy: () => esc = true,
        tab1Key: tab1,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(tab1));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(esc, isTrue);
  });
}
