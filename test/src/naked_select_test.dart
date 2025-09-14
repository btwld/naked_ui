import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';



void main() {
  const kMenuKey = Key('menu');

  // Helper function to build select widget
  Widget buildSelect<T>({
    T? selectedValue,
    ValueChanged<T?>? onSelectedValueChanged,
    Set<T>? selectedValues,
    ValueChanged<Set<T>>? onSelectedValuesChanged,
    bool allowMultiple = false,
    bool enabled = true,
    VoidCallback? onMenuClose,
    bool closeOnSelect = true,
    bool autofocus = true,
    bool enableTypeAhead = true,
  }) {
    final menu = Container(
      key: kMenuKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NakedSelectItem<T>(value: 'apple' as T, child: const Text('Apple')),
          NakedSelectItem<T>(value: 'banana' as T, child: const Text('Banana')),
          NakedSelectItem<T>(value: 'orange' as T, child: const Text('Orange')),
        ],
      ),
    );
    const child = NakedSelectTrigger(child: Text('Select option'));
    return Center(
      child: allowMultiple
          ? NakedSelect.multiple(
              selectedValues: selectedValues,
              onSelectedValuesChanged: onSelectedValuesChanged,
              enabled: enabled,
              closeOnSelect: closeOnSelect,
              autofocus: autofocus,
              enableTypeAhead: enableTypeAhead,
              menu: menu,
              child: child,
            )
          : NakedSelect(
              selectedValue: selectedValue,
              onSelectedValueChanged: onSelectedValueChanged,
              enabled: enabled,
              closeOnSelect: closeOnSelect,
              autofocus: autofocus,
              enableTypeAhead: enableTypeAhead,
              menu: menu,
              child: child,
            ),
    );
  }

  group('Core Functionality', () {
    testWidgets('renders trigger and menu when opened', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(buildSelect<String>());

      await tester.tap(find.text('Select option'));
      await tester.pump();

      expect(find.text('Select option'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Orange'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('selects single value correctly', (WidgetTester tester) async {
      String? selectedValue;

      await tester.pumpMaterialWidget(
        buildSelect<String>(
          selectedValue: selectedValue,
          onSelectedValueChanged: (value) => selectedValue = value,
        ),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pump();

      expect(selectedValue, 'banana');
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('supports multiple selection mode', (
      WidgetTester tester,
    ) async {
      final selectedValues = <String>{};

      await tester.pumpMaterialWidget(
        buildSelect<String>(
          allowMultiple: true,
          selectedValues: selectedValues,
          onSelectedValuesChanged: (values) => selectedValues.addAll(values),
          closeOnSelect: false,
        ),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pump();

      await tester.tap(find.text('Apple'));
      await tester.pump();

      await tester.tap(find.text('Banana'));
      await tester.pump();

      expect(selectedValues, contains('apple'));
      expect(selectedValues, contains('banana'));
      expect(selectedValues.length, 2);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('toggle menu visibility', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(buildSelect<String>());

      // Initially menu is closed
      expect(find.text('Apple'), findsNothing);

      // Open menu by tapping trigger
      await tester.tap(find.text('Select option'));
      await tester.pump();

      // Menu items should be visible
      expect(find.text('Apple'), findsOneWidget);

      // Close menu by tapping trigger again
      await tester.tapAt(Offset.zero);
      await tester.pump();

      // Menu should be closed again
      expect(find.text('Apple'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('does not respond when disabled', (WidgetTester tester) async {
      String? selectedValue;

      await tester.pumpMaterialWidget(
        buildSelect<String>(
          selectedValue: selectedValue,
          onSelectedValueChanged: (value) => selectedValue = value,
          enabled: false,
        ),
      );

      // Try to open menu
      await tester.tap(find.text('Select option'));
      await tester.pump();

      // Menu should not open when disabled
      expect(find.text('Apple'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('Keyboard Navigation', () {
    testWidgets('closes menu with Escape key', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(buildSelect<String>());

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Apple'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets(
      'restores focus to trigger after closing with Escape',
      (tester) async {
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          Center(
            child: NakedSelect<String>(
              menu: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  NakedSelectItem<String>(value: 'apple', child: Text('Apple')),
                ],
              ),
              child: NakedSelectTrigger(
                focusNode: triggerFocusNode,
                child: const Text('Select option'),
              ),
            ),
          ),
        );

        // Focus the trigger, then open menu
        triggerFocusNode.requestFocus();
        await tester.pump();
        await tester.tap(find.text('Select option'));
        await tester.pump();

        // Overlay should have focus; now close with Escape
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        // Expect focus to be back on the trigger
        expect(triggerFocusNode.hasFocus, isTrue);
      }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('selects item with Enter key', (WidgetTester tester) async {
      String? selectedValue;

      await tester.pumpMaterialWidget(
        buildSelect<String>(
          selectedValue: selectedValue,
          onSelectedValueChanged: (value) => selectedValue = value,
        ),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // Select with Enter
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selectedValue, 'apple');
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('Type-ahead Selection', () {
    testWidgets(
      'focuses item matching typed character',
      (WidgetTester tester) async {
        String? selectedValue;

        await tester.pumpMaterialWidget(
          buildSelect<String>(
            selectedValue: selectedValue,
            onSelectedValueChanged: (value) => selectedValue = value,
            enableTypeAhead: true,
          ),
        );

        // Open menu
        await tester.tap(find.text('Select option'));
        await tester.pump();

        // Type 'b' to focus 'Banana'
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(selectedValue, 'banana');
      }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets(
      'typeahead non-match does not change focus',
      (tester) async {
        String? selectedValue;

        await tester.pumpMaterialWidget(
          buildSelect<String>(
            selectedValue: selectedValue,
            onSelectedValueChanged: (v) => selectedValue = v,
            enableTypeAhead: true,
          ),
        );

        // Open menu
        await tester.tap(find.text('Select option'));
        await tester.pump();

        // Focus Banana via typeahead 'b'
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
        await tester.pump();

        // Send a non-matching char 'z' — focus should remain on Banana
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.pump();

        // Enter should still select Banana
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(selectedValue, 'banana');
      }, timeout: const Timeout(Duration(seconds: 10)));
  });


  group('Interaction States', () {
    testWidgets('calls onHoverChange when trigger hovered', (
      WidgetTester tester,
    ) async {
      

      bool isHovered = false;
      const key = Key('trigger');

      await tester.pumpMaterialWidget(
        Padding(
          padding: const EdgeInsets.all(1),
          child: NakedSelect<String>(
            menu: const SizedBox(),
            child: NakedSelectTrigger(
              key: key,
              onHoverChange: (hovered) => isHovered = hovered,
              child: const Text('Select option'),
            ),
          ),
        ),
      );

      await tester.simulateHover(
        key,
        onHover: () {
          expect(isHovered, true);
        },
      );

      expect(isHovered, false);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('calls onPressChange when trigger pressed', (
      WidgetTester tester,
    ) async {
      bool isPressed = false;

      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          menu: const SizedBox(),
          child: NakedSelectTrigger(
            onPressChange: (pressed) => isPressed = pressed,
            child: const Text('Select option'),
          ),
        ),
      );

      final gesture = await tester.press(find.byType(NakedSelectTrigger));
      await tester.pump();
      expect(isPressed, true);

      await gesture.up();
      await tester.pump();
      expect(isPressed, false);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('calls onFocusChange when trigger focused', (
      WidgetTester tester,
    ) async {
      bool isFocused = false;
      final focusNode = FocusNode();
      final overlayPortalController = OverlayPortalController();

      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          onClose: () => overlayPortalController.hide(),
          onOpen: () => overlayPortalController.show(),
          menu: const SizedBox(),
          child: NakedSelectTrigger(
            focusNode: focusNode,
            onFocusChange: (focused) => isFocused = focused,
            child: const Text('Select option'),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(isFocused, true);

      focusNode.unfocus();
      await tester.pump();
      expect(isFocused, false);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('calls item states when hovered/pressed', (
      WidgetTester tester,
    ) async {
      bool itemHovered = false;
      bool itemPressed = false;
      const key = Key('item');
      String? selectedValue;

      await tester.pumpMaterialWidget(
        Center(
          child: NakedSelect<String>(
            selectedValue: selectedValue,
            onSelectedValueChanged: (value) => selectedValue = value,
            menu: Container(
              key: kMenuKey,
              child: NakedSelectItem<String>(
                key: key,
                value: 'test',
                onHoverChange: (hovered) => itemHovered = hovered,
                onPressChange: (pressed) => itemPressed = pressed,
                child: const Text('Apple'),
              ),
            ),
            child: const NakedSelectTrigger(child: Text('Select option')),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      await tester.simulateHover(
        key,
        onHover: () {
          expect(itemHovered, true);
        },
      );
      expect(itemHovered, false);

      // Press down and release to verify press state callbacks fire
      final center = tester.getCenter(find.byKey(key));
      final gesture = await tester.startGesture(center);
      await tester.pump();
      expect(itemPressed, isTrue, reason: 'Press should toggle to true on down');
      await gesture.up();
      await tester.pump();
      expect(itemPressed, isFalse, reason: 'Press should toggle back to false on up');

      // Press/release also selects the item; verify selection occurred.
      expect(selectedValue, 'test');
    });
  });

  group('Menu Positioning', () {
    testWidgets('renders menu in overlay', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(buildSelect<String>());

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // Menu should be rendered in the overlay
      expect(find.byType(OverlayPortal), findsOneWidget);
    });

    testWidgets(
      'fallback alignment positions overlay using fallback when primary would overflow',
      (tester) async {
        // Build with the trigger near the bottom so primary (bottomLeft/topLeft) would overflow
        await tester.pumpMaterialWidget(
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: NakedSelect<String>(
                menuPosition: const NakedMenuPosition(
                  target: Alignment.bottomLeft,
                  follower: Alignment.topLeft,
                ),
                fallbackPositions: const [
                  NakedMenuPosition(
                    target: Alignment.topLeft,
                    follower: Alignment.bottomLeft,
                  ),
                ],
                menu: Container(
                  key: kMenuKey,
                  width: 120,
                  height: 160, // big enough to overflow downward
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text('Menu Content')],
                  ),
                ),
                child: const NakedSelectTrigger(child: Text('Select option')),
              ),
            ),
          ),
        );

        // Open menu
        await tester.tap(find.text('Select option'));
        await tester.pump();

        // Get the trigger and menu positions
        final triggerRect = tester.getRect(find.text('Select option'));
        final menuRect = tester.getRect(find.byKey(kMenuKey));

        // Assert the menu is placed above the trigger (fallback used)
        expect(menuRect.bottom <= triggerRect.top, isTrue);
      }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('Selection Behavior', () {
    testWidgets('keeps menu open when closeOnSelect is false', (
      WidgetTester tester,
    ) async {
      String? selectedValue;
      bool menuClosed = false;

      await tester.pumpMaterialWidget(
        buildSelect<String>(
          selectedValue: selectedValue,
          onSelectedValueChanged: (value) => selectedValue = value,
          onMenuClose: () => menuClosed = true,
          closeOnSelect: false,
        ),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

        await tester.tap(find.text('Banana'));
        await tester.pump();

      expect(selectedValue, 'banana');
      expect(menuClosed, false);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('closes menu when closeOnSelect is true', (
      WidgetTester tester,
    ) async {
      String? selectedValue;

      await tester.pumpMaterialWidget(
        buildSelect<String>(
          selectedValue: selectedValue,
          onSelectedValueChanged: (value) => selectedValue = value,
          closeOnSelect: true,
        ),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pump();

      await tester.tap(find.text('Banana'));
      await tester.pump();

      expect(selectedValue, 'banana');
      expect(find.text('Apple'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('outside tap closes menu with removalDelay respected', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          removalDelay: const Duration(milliseconds: 200),
          menu: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedSelectItem<String>(value: 'apple', child: Text('Apple')),
              NakedSelectItem<String>(value: 'banana', child: Text('Banana')),
            ],
          ),
          child: const NakedSelectTrigger(child: Text('Select option')),
        ),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pump();
      expect(find.text('Apple'), findsOneWidget);

      // Tap outside to request close
      await tester.tapAt(Offset.zero);
      await tester.pump();

      // During delay, overlay should still be visible
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Apple'), findsOneWidget);

      // After full delay, overlay should be gone
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('Apple'), findsNothing);
    });
  });

  group('Type-ahead Buffer', () {
    testWidgets('debounce resets buffer between characters', (
      WidgetTester tester,
    ) async {
      String? selectedValue;

      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          selectedValue: selectedValue,
          onSelectedValueChanged: (v) => selectedValue = v,
          enableTypeAhead: true,
          typeAheadDebounceTime: const Duration(milliseconds: 100),
          menu: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedSelectItem<String>(value: 'apple', child: Text('Apple')),
              NakedSelectItem<String>(value: 'banana', child: Text('Banana')),
              NakedSelectItem<String>(value: 'orange', child: Text('Orange')),
            ],
          ),
          child: const NakedSelectTrigger(child: Text('Select option')),
        ),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pump();

      // Type 'b' then wait past debounce so buffer resets
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // Now type 'a' — with buffer reset, should focus Apple (not Banana)
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selectedValue, 'apple');
    });
  });

  group('Cursor', () {
    testWidgets('shows appropriate cursor based on interactive state', (
      WidgetTester tester,
    ) async {
      const keyEnabledTrigger = Key('enabledTrigger');
      const keyDisabledTrigger = Key('disabledTrigger');

      await tester.pumpMaterialWidget(
        const Column(
          children: [
            NakedSelect<String>(
              menu: SizedBox(),
              child: NakedSelectTrigger(
                key: keyEnabledTrigger,
                child: Text('Enabled Trigger'),
              ),
            ),
            NakedSelect<String>(
              enabled: false,
              menu: SizedBox(),
              child: NakedSelectTrigger(
                key: keyDisabledTrigger,
                child: Text('Disabled Trigger'),
              ),
            ),
          ],
        ),
      );

      tester.expectCursor(SystemMouseCursors.click, on: keyEnabledTrigger);

      tester.expectCursor(SystemMouseCursors.basic, on: keyDisabledTrigger);
    });
  });
}
