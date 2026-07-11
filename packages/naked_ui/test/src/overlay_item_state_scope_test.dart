import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

/// Regression coverage for the public invariant that every
/// `ValueWidgetBuilder<S>` supplied to an overlay item receives a
/// `BuildContext` containing a matching `NakedStateScope<S>`.
///
/// Before this was fixed, `NakedMenuItem`/`NakedSelectOption` builders only had
/// access to the internal `NakedButtonState` scope, so `S.of(context)` and
/// `S.controllerOf(context)` threw and downstream libraries had to reach for
/// `NakedButtonState` — leaking the fact that items are built on `NakedButton`.
const _itemKey = Key('overlay-item');

Future<TestGesture> _hoverOver(WidgetTester tester, Key key) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(find.byKey(key)));
  await tester.pump();

  return gesture;
}

void main() {
  group('NakedMenuItem provides its NakedMenuItemState scope to builders', () {
    Future<void> pumpMenu(
      WidgetTester tester,
      MenuController controller,
      ValueWidgetBuilder<NakedMenuItemState<String>> itemBuilder, {
      bool enabled = true,
      bool closeOnActivate = true,
    }) async {
      await tester.pumpMaterialWidget(
        NakedMenu<String>(
          controller: controller,
          builder: (context, state, child) => const Text('trigger'),
          overlayBuilder: (context, info) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedMenuItem<String>(
                value: 'copy',
                enabled: enabled,
                closeOnActivate: closeOnActivate,
                builder: itemBuilder,
              ),
            ],
          ),
        ),
      );
      controller.open();
      await tester.pump();
      await tester.pump();
    }

    testWidgets('of<T>() returns the state passed to the builder', (
      tester,
    ) async {
      final controller = MenuController();
      NakedMenuItemState<String>? fromBuilder;
      NakedMenuItemState<String>? fromOf;

      await pumpMenu(tester, controller, (context, state, child) {
        fromBuilder = state;
        fromOf = NakedMenuItemState.of<String>(context);

        return const SizedBox(key: _itemKey, width: 200, height: 44);
      });

      expect(fromOf, isNotNull);
      expect(fromOf, equals(fromBuilder));
      expect(fromOf!.value, 'copy');
    });

    testWidgets('controllerOf<T>() updates for hover, focus, and press', (
      tester,
    ) async {
      final controller = MenuController();
      WidgetStatesController? itemController;
      var controllerValue = <WidgetState>{};
      var builderStates = <WidgetState>{};
      FocusNode? itemFocus;

      await pumpMenu(tester, controller, (context, state, child) {
        itemController = NakedMenuItemState.controllerOf<String>(context);
        controllerValue = {...itemController!.value};
        builderStates = state.states;
        itemFocus = Focus.of(context);

        return const SizedBox(key: _itemKey, width: 200, height: 44);
      }, closeOnActivate: false);

      // The scope's controller starts idle and mirrors the builder state.
      expect(itemController, isNotNull);
      expect(controllerValue, isEmpty);
      expect(controllerValue, equals(builderStates));

      // Hover.
      final hover = await _hoverOver(tester, _itemKey);
      expect(controllerValue, contains(WidgetState.hovered));
      expect(controllerValue, equals(builderStates));
      await hover.moveTo(Offset.zero);
      await tester.pump();
      expect(controllerValue, isNot(contains(WidgetState.hovered)));

      // Focus. FocusManager applies focus post-frame, so the `focused`
      // widget-state lands on the following pump.
      itemFocus!.requestFocus();
      await tester.pumpAndSettle();
      expect(controllerValue, contains(WidgetState.focused));
      expect(controllerValue, equals(builderStates));
      itemFocus!.unfocus();
      await tester.pumpAndSettle();
      expect(controllerValue, isNot(contains(WidgetState.focused)));

      // Press.
      final press = await tester.startGesture(
        tester.getCenter(find.byKey(_itemKey)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(controllerValue, contains(WidgetState.pressed));
      expect(controllerValue, equals(builderStates));
      await press.up();
      await tester.pump();
      expect(controllerValue, isNot(contains(WidgetState.pressed)));
    });

    testWidgets('controllerOf<T>() reflects the disabled state', (
      tester,
    ) async {
      final controller = MenuController();
      var controllerValue = <WidgetState>{};
      var builderStates = <WidgetState>{};

      await pumpMenu(tester, controller, (context, state, child) {
        controllerValue = {
          ...NakedMenuItemState.controllerOf<String>(context).value,
        };
        builderStates = state.states;

        return const SizedBox(key: _itemKey, width: 200, height: 44);
      }, enabled: false);

      expect(controllerValue, contains(WidgetState.disabled));
      expect(builderStates, contains(WidgetState.disabled));
    });

    testWidgets('downstream binds to the item controller reactively without '
        'NakedButtonState', (tester) async {
      final controller = MenuController();
      final observedHover = <bool>[];

      await pumpMenu(tester, controller, (context, _, child) {
        // Realistic downstream usage: subscribe ONLY to the component-specific
        // controller — the exact API that previously forced callers to reach
        // for NakedButtonState — and rebuild from its notifications.
        final itemController = NakedMenuItemState.controllerOf<String>(context);

        return SizedBox(
          key: _itemKey,
          width: 200,
          height: 44,
          child: ListenableBuilder(
            listenable: itemController,
            builder: (context, _) {
              observedHover.add(
                itemController.value.contains(WidgetState.hovered),
              );

              return const SizedBox.shrink();
            },
          ),
        );
      }, closeOnActivate: false);

      expect(observedHover.last, isFalse);

      // The item controller notifies the downstream listener directly.
      final hover = await _hoverOver(tester, _itemKey);
      expect(observedHover.last, isTrue);

      await hover.moveTo(Offset.zero);
      await tester.pump();
      expect(observedHover.last, isFalse);
    });

    testWidgets('sibling items each expose their own scoped state', (
      tester,
    ) async {
      final controller = MenuController();
      final resolved = <String, String>{};

      await tester.pumpMaterialWidget(
        NakedMenu<String>(
          controller: controller,
          builder: (context, state, child) => const Text('trigger'),
          overlayBuilder: (context, info) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in const ['copy', 'paste'])
                NakedMenuItem<String>(
                  value: value,
                  builder: (context, state, child) {
                    // Each item resolves its OWN value through the shared
                    // NakedMenuItemState<String> type — scopes don't bleed
                    // across siblings.
                    resolved[value] = NakedMenuItemState.of<String>(
                      context,
                    ).value;

                    return SizedBox(key: Key('item-$value'), height: 44);
                  },
                ),
            ],
          ),
        ),
      );
      controller.open();
      await tester.pump();
      await tester.pump();

      expect(resolved['copy'], 'copy');
      expect(resolved['paste'], 'paste');
    });
  });

  group('NakedSelectOption provides its NakedSelectOptionState scope to '
      'builders', () {
    Future<void> pumpSelect(
      WidgetTester tester, {
      String? value,
      bool optionEnabled = true,
      bool closeOnSelect = true,
      required ValueWidgetBuilder<NakedSelectOptionState<String>> optionBuilder,
    }) async {
      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          value: value,
          onChanged: (_) {},
          closeOnSelect: closeOnSelect,
          builder: (context, state, child) => const Text('trigger'),
          overlayBuilder: (context, info) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedSelectOption<String>(
                value: 'apple',
                enabled: optionEnabled,
                builder: optionBuilder,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('trigger'));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('of<T>() returns the state passed to the builder', (
      tester,
    ) async {
      NakedSelectOptionState<String>? fromBuilder;
      NakedSelectOptionState<String>? fromOf;

      await pumpSelect(
        tester,
        optionBuilder: (context, state, child) {
          fromBuilder = state;
          fromOf = NakedSelectOptionState.of<String>(context);

          return const SizedBox(key: _itemKey, width: 200, height: 44);
        },
      );

      expect(fromOf, isNotNull);
      expect(fromOf, equals(fromBuilder));
      expect(fromOf!.value, 'apple');
    });

    testWidgets('controllerOf<T>() updates for hover, focus, and press', (
      tester,
    ) async {
      WidgetStatesController? optionController;
      var controllerValue = <WidgetState>{};
      var builderStates = <WidgetState>{};
      FocusNode? optionFocus;

      await pumpSelect(
        tester,
        closeOnSelect: false,
        optionBuilder: (context, state, child) {
          optionController = NakedSelectOptionState.controllerOf<String>(
            context,
          );
          controllerValue = {...optionController!.value};
          builderStates = state.states;
          optionFocus = Focus.of(context);

          return const SizedBox(key: _itemKey, width: 200, height: 44);
        },
      );

      expect(optionController, isNotNull);
      expect(controllerValue, equals(builderStates));

      // Hover.
      final hover = await _hoverOver(tester, _itemKey);
      expect(controllerValue, contains(WidgetState.hovered));
      expect(controllerValue, equals(builderStates));
      await hover.moveTo(Offset.zero);
      await tester.pump();
      expect(controllerValue, isNot(contains(WidgetState.hovered)));

      // Focus. FocusManager applies focus post-frame, so the `focused`
      // widget-state lands on the following pump.
      optionFocus!.requestFocus();
      await tester.pumpAndSettle();
      expect(controllerValue, contains(WidgetState.focused));
      expect(controllerValue, equals(builderStates));
      optionFocus!.unfocus();
      await tester.pumpAndSettle();
      expect(controllerValue, isNot(contains(WidgetState.focused)));

      // Press.
      final press = await tester.startGesture(
        tester.getCenter(find.byKey(_itemKey)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(controllerValue, contains(WidgetState.pressed));
      expect(controllerValue, equals(builderStates));
      await press.up();
      await tester.pump();
      expect(controllerValue, isNot(contains(WidgetState.pressed)));
    });

    testWidgets('controllerOf<T>() reflects the selected state', (
      tester,
    ) async {
      var controllerValue = <WidgetState>{};
      NakedSelectOptionState<String>? state;

      await pumpSelect(
        tester,
        value: 'apple',
        closeOnSelect: false,
        optionBuilder: (context, s, child) {
          state = s;
          controllerValue = {
            ...NakedSelectOptionState.controllerOf<String>(context).value,
          };

          return const SizedBox(key: _itemKey, width: 200, height: 44);
        },
      );

      expect(state!.isSelected, isTrue);
      expect(controllerValue, contains(WidgetState.selected));
    });

    testWidgets('controllerOf<T>() reflects the disabled state', (
      tester,
    ) async {
      var controllerValue = <WidgetState>{};
      var builderStates = <WidgetState>{};

      await pumpSelect(
        tester,
        optionEnabled: false,
        optionBuilder: (context, state, child) {
          controllerValue = {
            ...NakedSelectOptionState.controllerOf<String>(context).value,
          };
          builderStates = state.states;

          return const SizedBox(key: _itemKey, width: 200, height: 44);
        },
      );

      expect(controllerValue, contains(WidgetState.disabled));
      expect(builderStates, contains(WidgetState.disabled));
    });

    testWidgets('downstream binds to the option controller reactively without '
        'NakedButtonState', (tester) async {
      final observedHover = <bool>[];

      await pumpSelect(
        tester,
        closeOnSelect: false,
        optionBuilder: (context, _, child) {
          // Subscribe ONLY to the component-specific controller.
          final optionController = NakedSelectOptionState.controllerOf<String>(
            context,
          );

          return SizedBox(
            key: _itemKey,
            width: 200,
            height: 44,
            child: ListenableBuilder(
              listenable: optionController,
              builder: (context, _) {
                observedHover.add(
                  optionController.value.contains(WidgetState.hovered),
                );

                return const SizedBox.shrink();
              },
            ),
          );
        },
      );

      expect(observedHover.last, isFalse);

      final hover = await _hoverOver(tester, _itemKey);
      expect(observedHover.last, isTrue);

      await hover.moveTo(Offset.zero);
      await tester.pump();
      expect(observedHover.last, isFalse);
    });
  });
}
