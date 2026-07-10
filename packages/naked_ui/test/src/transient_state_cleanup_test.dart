import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

Future<void> _expectDisablingClearsHover<T extends NakedState>(
  WidgetTester tester, {
  required Widget Function(bool enabled, ValueChanged<T> onState, Key targetKey)
  build,
}) async {
  var enabled = true;
  late StateSetter updateHost;
  T? state;
  const targetKey = Key('hover target');

  await tester.pumpMaterialWidget(
    StatefulBuilder(
      builder: (context, setState) {
        updateHost = setState;
        return build(enabled, (value) => state = value, targetKey);
      },
    ),
  );

  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  try {
    await mouse.moveTo(tester.getCenter(find.byKey(targetKey)));
    await tester.pump();
    expect(state?.isHovered, isTrue);

    updateHost(() => enabled = false);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(state?.isDisabled, isTrue);
    expect(state?.isHovered, isFalse);
  } finally {
    await mouse.removePointer();
  }
}

void main() {
  testWidgets('button clears hover when it becomes disabled', (tester) async {
    await _expectDisablingClearsHover<NakedButtonState>(
      tester,
      build: (enabled, onState, targetKey) => NakedButton(
        enabled: enabled,
        onPressed: () {},
        builder: (context, state, child) {
          onState(state);
          return child!;
        },
        child: SizedBox(key: targetKey, width: 100, height: 40),
      ),
    );
  });

  testWidgets('checkbox clears hover when it becomes disabled', (tester) async {
    await _expectDisablingClearsHover<NakedCheckboxState>(
      tester,
      build: (enabled, onState, targetKey) => NakedCheckbox(
        value: false,
        enabled: enabled,
        onChanged: (_) {},
        builder: (context, state, child) {
          onState(state);
          return child!;
        },
        child: SizedBox(key: targetKey, width: 100, height: 40),
      ),
    );
  });

  testWidgets('accordion clears hover when it becomes disabled', (
    tester,
  ) async {
    final controller = NakedAccordionController<String>();
    addTearDown(controller.dispose);

    await _expectDisablingClearsHover<NakedAccordionItemState<String>>(
      tester,
      build: (enabled, onState, targetKey) => NakedAccordionGroup<String>(
        controller: controller,
        child: NakedAccordion<String>(
          value: 'item',
          enabled: enabled,
          builder: (context, state) {
            onState(state);
            return SizedBox(key: targetKey, width: 100, height: 40);
          },
          child: const SizedBox(),
        ),
      ),
    );
  });

  testWidgets('tab clears hover when its group becomes disabled', (
    tester,
  ) async {
    await _expectDisablingClearsHover<NakedTabState>(
      tester,
      build: (enabled, onState, targetKey) => NakedTabs(
        selectedTabId: 'tab',
        onChanged: (_) {},
        enabled: enabled,
        child: NakedTabBar(
          child: NakedTab(
            tabId: 'tab',
            builder: (context, state, child) {
              onState(state);
              return child!;
            },
            child: SizedBox(key: targetKey, width: 100, height: 40),
          ),
        ),
      ),
    );
  });

  testWidgets('text field defers cleanup callbacks until after rebuild', (
    tester,
  ) async {
    await _expectDisablingClearsHover<NakedTextFieldState>(
      tester,
      build: (enabled, onState, targetKey) => StatefulBuilder(
        builder: (context, setState) => NakedTextField(
          enabled: enabled,
          onHoverChange: (_) => setState(() {}),
          builder: (context, state, editableText) {
            onState(state);
            return SizedBox(
              key: targetKey,
              width: 100,
              height: 40,
              child: editableText,
            );
          },
        ),
      ),
    );
  });

  testWidgets('slider defers drag cleanup callbacks until after rebuild', (
    tester,
  ) async {
    var enabled = true;
    var dragEndCount = 0;
    late StateSetter updateHost;
    NakedSliderState? state;
    const sliderKey = Key('slider');

    await tester.pumpMaterialWidget(
      StatefulBuilder(
        builder: (context, setState) {
          updateHost = setState;
          return NakedSlider(
            value: 0.5,
            enabled: enabled,
            onChanged: (_) {},
            onDragEnd: (_) => updateHost(() => dragEndCount++),
            builder: (context, value, child) {
              state = value;
              return child!;
            },
            child: const SizedBox(key: sliderKey, width: 200, height: 40),
          );
        },
      ),
    );

    final drag = await tester.startGesture(
      tester.getCenter(find.byKey(sliderKey)),
    );
    await drag.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(state?.isDragging, isTrue);

    updateHost(() => enabled = false);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(state?.isDragging, isFalse);
    expect(dragEndCount, 1);
    await drag.cancel();
  });
}
