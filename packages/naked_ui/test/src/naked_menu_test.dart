import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';
import 'helpers/builder_state_scope.dart';

extension _NakedMenuTester on WidgetTester {
  Future<void> pressEsc() async {
    await sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpAndSettle();
  }

  Future<void> tapOutsideMenu() async {
    await tapAt(const Offset(10, 10));
    await pump();
  }
}

void main() {
  group('NakedMenu', () {
    group('Basic Functionality', () {
      NakedMenu<String> buildBasicMenu(MenuController controller) {
        return NakedMenu<String>(
          controller: controller,
          builder: (context, state, child) => const Text('child'),
          overlayBuilder: (context, info) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedMenuItem<String>(value: 'menu', child: Text('Menu Content')),
            ],
          ),
        );
      }

      testWidgets('Renders child widget', (WidgetTester tester) async {
        final controller = MenuController();
        await tester.pumpMaterialWidget(buildBasicMenu(controller));

        expect(find.text('child'), findsOneWidget);
        expect(find.text('Menu Content'), findsNothing);
      });

      testWidgets('Renders menu content when open', (
        WidgetTester tester,
      ) async {
        final controller = MenuController();
        await tester.pumpMaterialWidget(buildBasicMenu(controller));
        controller.open();
        await tester.pump();

        expect(find.text('child'), findsOneWidget);
        expect(find.text('Menu Content'), findsOneWidget);
      });

      testWidgets('Opens when controller.show() is called', (
        WidgetTester tester,
      ) async {
        final controller = MenuController();

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  NakedButton(
                    onPressed: () => controller.open(),
                    child: const Text('Open Menu'),
                  ),
                  NakedMenu<String>(
                    controller: controller,
                    builder: (context, state, child) => const Text('child'),
                    overlayBuilder: (context, info) => const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NakedMenuItem<String>(
                          value: 'menu',
                          child: Text('Menu Content'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );

        expect(find.text('Menu Content'), findsNothing);
        await tester.tap(find.text('Open Menu'));
        await tester.pumpAndSettle();
        expect(find.text('Menu Content'), findsOneWidget);
      });

      testWidgets('Places menu according to menuAlignment parameter', (
        WidgetTester tester,
      ) async {
        final controller = MenuController();
        const trigger = Key('trigger');
        const menu = Key('menu');
        await tester.pumpMaterialWidget(
          Center(
            child: NakedMenu<String>(
              controller: controller,
              builder: (context, state, child) => Container(
                key: trigger,
                width: 100,
                height: 40,
                color: Colors.blue,
                child: const Center(child: Text('child')),
              ),
              overlayBuilder: (context, info) => Column(
                key: menu,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  NakedMenuItem<String>(
                    value: 'menu',
                    child: SizedBox(
                      width: 200,
                      height: 100,
                      child: Center(child: Text('Menu Content')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        controller.open();

        await tester.pump();
        expect(find.byKey(menu), findsOneWidget);

        // Get the positions of the trigger and menu
        final triggerBottomLeft = tester.getBottomLeft(find.byKey(trigger));
        final menuTopLeft = tester.getTopLeft(find.byKey(menu));

        // Menu should be positioned below the trigger (or above if near bottom)
        expect(menuTopLeft.dy, triggerBottomLeft.dy);

        // Get the positions of the trigger and menu
        final triggerLeft = tester.getTopLeft(find.byKey(trigger));
        final menuLeft = tester.getTopLeft(find.byKey(menu));

        // Menu should be left-aligned with trigger (current behavior)
        expect(menuLeft.dx, triggerLeft.dx);
      });

      testStateScopeBuilder<NakedMenuState>(
        'builder\'s context contains NakedStateScope',
        (builder) => NakedMenu<String>(
          controller: MenuController(),
          builder: builder,
          overlayBuilder: (BuildContext context, RawMenuOverlayInfo info) =>
              SizedBox(),
        ),
      );
    });

    group('State Management', () {
      testWidgets('calls onMenuClose when Escape key pressed', (
        WidgetTester tester,
      ) async {
        bool onMenuCloseCalled = false;

        final controller = MenuController();
        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return NakedMenu<String>(
                onClose: () => onMenuCloseCalled = true,
                controller: controller,
                builder: (context, state, child) => const Text('child'),
                overlayBuilder: (context, info) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NakedMenuItem<String>(
                      value: 'menu',
                      child: Text('Menu Content'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
        controller.open();

        await tester.pumpAndSettle();
        expect(find.text('Menu Content'), findsOneWidget);

        await tester.pressEsc();
        await tester.pumpAndSettle();
        expect(onMenuCloseCalled, true);
      });

      testWidgets(
        'calls onMenuClose when menu item is selected (default behavior)',
        (WidgetTester tester) async {
          bool onMenuCloseCalled = false;
          final controller = MenuController();
          String? selectedValue;

          await tester.pumpMaterialWidget(
            NakedMenu<String>(
              controller: controller,
              onClose: () => onMenuCloseCalled = true,
              onSelected: (value) => selectedValue = value,
              builder: (context, state, child) => const Text('Menu trigger'),
              overlayBuilder: (context, info) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedMenuItem<String>(value: 'item1', child: Text('Item 1')),
                  NakedMenuItem<String>(value: 'item2', child: Text('Item 2')),
                ],
              ),
            ),
          );

          // Open menu
          controller.open();
          await tester.pumpAndSettle();

          expect(find.text('Item 1'), findsOneWidget);
          expect(onMenuCloseCalled, false);

          // Select an item - should close menu by default
          await tester.tap(find.text('Item 1'));
          await tester.pumpAndSettle();

          expect(onMenuCloseCalled, true);
          expect(selectedValue, 'item1');
          expect(find.text('Item 1'), findsNothing); // Menu should be closed
        },
      );
      testWidgets(
        'keeps menu open when closeOnActivate is false on menu item',
        (WidgetTester tester) async {
          bool onMenuCloseCalled = false;
          const menuKey = Key('menu');
          const item1Key = Key('item1');
          final controller = MenuController();

          await tester.pumpMaterialWidget(
            NakedMenu(
              controller: controller,
              onClose: () => onMenuCloseCalled = true,
              overlayBuilder: (context, info) => Container(
                key: menuKey,
                constraints: const BoxConstraints(
                  maxWidth: 100,
                  maxHeight: 100,
                ),
                child: const NakedMenuItem<String>(
                  key: item1Key,
                  value: 'item1',
                  closeOnActivate: false,
                  child: Text('Item 1'),
                ),
              ),
              builder: (context, state, child) => const Text('child'),
            ),
          );

          controller.open();

          await tester.pump();
          expect(find.byKey(menuKey), findsOneWidget);

          await tester.tap(find.text('Item 1'));
          await tester.pumpAndSettle();

          // Menu should still be open since closeOnActivate is false
          expect(onMenuCloseCalled, false);
          expect(find.byKey(menuKey), findsOneWidget);
        },
      );
    });
    group('Keyboard Interaction', () {
      testWidgets('Traps focus within menu when opens', (
        WidgetTester tester,
      ) async {
        // Remove unused variables
        final controller = MenuController();
        await tester.pumpMaterialWidget(
          Center(
            child: NakedMenu(
              controller: controller,
              overlayBuilder: (context, info) => const Column(
                children: [
                  NakedMenuItem<String>(value: 'item1', child: Text('Item 1')),
                  NakedMenuItem<String>(value: 'item2', child: Text('Item 2')),
                ],
              ),
              builder: (context, state, child) => const Text('child'),
            ),
          ),
        );

        controller.open();

        await tester.pump();
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Menu items should still be visible after tab navigation
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
      });
    });
  });

  group('NakedMenuContent', () {
    testWidgets('Renders child widget(s)', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(const Text('Menu Content'));

      expect(find.text('Menu Content'), findsOneWidget);
    });

    testWidgets(
      'calls onMenuClose when clicking outside (if consumeOutsideTaps is true)',
      (WidgetTester tester) async {
        bool onMenuCloseCalled = false;

        final controller = MenuController();

        await tester.pumpMaterialWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: () {},
                      child: const SizedBox(
                        width: 50,
                        height: 50,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: 100,
                    child: NakedMenu(
                      controller: controller,
                      onClose: () => onMenuCloseCalled = true,
                      consumeOutsideTaps: true,
                      overlayBuilder: (context, info) => const SizedBox(
                        width: 100,
                        height: 50,
                        child: Center(child: Text('Menu Content')),
                      ),
                      builder: (context, state, child) => const Text('child'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
        controller.open();

        await tester.pump();
        expect(find.text('Menu Content'), findsOneWidget);

        // Tap outside the menu
        await tester.tapOutsideMenu();
        expect(onMenuCloseCalled, true);
      },
    );
  });

  // NakedMenuItem functionality is tested as part of NakedMenu tests above
  // since NakedMenuItem requires the menu scope to function properly.
  // See tests like "calls onMenuClose when menu item is selected" and
  // "keeps menu open when closeOnActivate is false on menu item".
}
