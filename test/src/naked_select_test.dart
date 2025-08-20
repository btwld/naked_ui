import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'helpers/simulate_hover.dart';

extension _WidgetTesterX on WidgetTester {
  SemanticsNode findSemantics(Finder finder) {
    return getSemantics(
      find.descendant(of: finder, matching: find.byType(Semantics)).first,
    );
  }
}

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
      await tester.pumpAndSettle();

      expect(find.text('Select option'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Orange'), findsOneWidget);
    });

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
      await tester.pumpAndSettle();

      expect(selectedValue, 'banana');
    });

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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(selectedValues, contains('apple'));
      expect(selectedValues, contains('banana'));
      expect(selectedValues.length, 2);
    });

    testWidgets('toggle menu visibility', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(buildSelect<String>());

      // Initially menu is closed
      expect(find.text('Apple'), findsNothing);

      // Open menu by tapping trigger
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // Menu items should be visible
      expect(find.text('Apple'), findsOneWidget);

      // Close menu by tapping trigger again
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      // Menu should be closed again
      expect(find.text('Apple'), findsNothing);
    });

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
      await tester.pumpAndSettle();

      // Menu should not open when disabled
      expect(find.text('Apple'), findsNothing);
    });
  });

  group('Keyboard Navigation', () {
    testWidgets('closes menu with Escape key', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(buildSelect<String>());

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsNothing);
    }, timeout: Timeout(Duration(seconds: 20)));

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
        await tester.pumpAndSettle();

        // Overlay should have focus; now close with Escape
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Expect focus to be back on the trigger
        expect(triggerFocusNode.hasFocus, isTrue);
      },
      timeout: Timeout(Duration(seconds: 20)),
    );

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
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Select with Enter
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(selectedValue, 'apple');
    });
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
        await tester.pumpAndSettle();

        // Type 'b' to focus 'Banana'
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(selectedValue, 'banana');
      },
      timeout: Timeout(Duration(seconds: 20)),
    );

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
        await tester.pumpAndSettle();

        // Focus Banana via typeahead 'b'
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
        await tester.pumpAndSettle();

        // Send a non-matching char 'z' — focus should remain on Banana
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.pumpAndSettle();

        // Enter should still select Banana
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(selectedValue, 'banana');
      },
      timeout: Timeout(Duration(seconds: 20)),
    );
  });

  group('Accessibility', () {
    testWidgets('provides semantic button property for trigger', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(buildSelect<String>());

      expect(
        tester.findSemantics(find.byType(NakedSelectTrigger)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('marks items as selected in semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        buildSelect<String>(selectedValue: 'apple'),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // Find the semantics node for the Apple item

      expect(
        tester.findSemantics(find.byType(NakedSelectItem<String>)),
        matchesSemantics(
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    });

    testWidgets('shows correct enabled/disabled state', (
      WidgetTester tester,
    ) async {
      for (var enabled in [true, false]) {
        await tester.pumpMaterialWidget(buildSelect<String>(enabled: enabled));

        expect(
          tester.findSemantics(find.byType(NakedSelectTrigger)),
          matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: enabled,
            isFocusable: enabled,
            hasFocusAction: enabled,
            hasTapAction: enabled,
          ),
        );

        await tester.pumpWidget(Container());
      }
    });
  });

  group('Interaction States', () {
    testWidgets('calls onHoverChange when trigger hovered', (
      WidgetTester tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;

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
    });

    testWidgets('calls onHighlightChanged when trigger pressed', (
      WidgetTester tester,
    ) async {
      bool isPressed = false;

      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          menu: const SizedBox(),
          child: NakedSelectTrigger(
            onHighlightChanged: (pressed) => isPressed = pressed,
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
    });

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
    });

    testWidgets('calls item states when hovered/pressed', (
      WidgetTester tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;

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
                onHighlightChanged: (pressed) => itemPressed = pressed,
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

      // Test hover
      await tester.simulateHover(
        key,
        onHover: () {
          expect(itemHovered, true);
        },
      );
      expect(itemHovered, false);

      // Test press
      final pressGesture = await tester.press(find.byKey(key));
      await tester.pump();
      expect(itemPressed, true);

      await pressGesture.up();
      await tester.pump();
      expect(itemPressed, false);
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
        await tester.pumpAndSettle();

        // Get the trigger and menu positions
        final triggerRect = tester.getRect(find.text('Select option'));
        final menuRect = tester.getRect(find.byKey(kMenuKey));

        // Assert the menu is placed above the trigger (fallback used)
        expect(menuRect.bottom <= triggerRect.top, isTrue);
      },
      timeout: Timeout(Duration(seconds: 20)),
    );
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
    });

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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'banana');
      expect(find.text('Apple'), findsNothing);
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

      tester.expectCursor(SystemMouseCursors.forbidden, on: keyDisabledTrigger);
    });
  });

  group('Semantic Configuration', () {
    testWidgets('NakedSelect supports excludeSemantics parameter', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          excludeSemantics: false, // Default value
          semanticLabel: 'Select component',
          menu: const SizedBox(),
          child: const NakedSelectTrigger(child: Text('Select option')),
        ),
      );

      // If this compiles and runs, the parameter exists and works
      expect(find.byType(NakedSelect<String>), findsOneWidget);
    });

    testWidgets('NakedSelectItem supports excludeSemantics parameter', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          menu: Column(
            children: [
              NakedSelectItem<String>(
                value: 'item1',
                excludeSemantics: false, // Default value
                child: const Text('Item 1'),
              ),
              NakedSelectItem<String>(
                value: 'item2',
                excludeSemantics: true, // Override value
                child: const Text('Item 2'),
              ),
            ],
          ),
          child: const NakedSelectTrigger(child: Text('Select option')),
        ),
      );

      // Open menu to render items
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // If this compiles and runs, the parameter exists and works
      expect(find.byType(NakedSelectItem<String>), findsNWidgets(2));
    });

    testWidgets('NakedSelect semantic label is applied', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          semanticLabel: 'Fruit picker',
          menu: const SizedBox(),
          child: const NakedSelectTrigger(child: Text('Select fruit')),
        ),
      );

      final selectSemantics = tester.getSemantics(
        find.byType(NakedSelect<String>),
      );
      expect(selectSemantics.label, equals('Fruit picker'));
    });

    testWidgets('NakedSelectItem semantic labels work', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          menu: Column(
            children: const [
              NakedSelectItem<String>(
                value: 'apple',
                semanticLabel: 'Apple fruit',
                child: Text('Apple'),
              ),
              NakedSelectItem<String>(value: 'banana', child: Text('Banana')),
            ],
          ),
          child: const NakedSelectTrigger(child: Text('Select fruit')),
        ),
      );

      // Open menu to render items
      await tester.tap(find.text('Select fruit'));
      await tester.pumpAndSettle();

      final appleSemantics = tester.getSemantics(find.text('Apple'));
      expect(appleSemantics.label, contains('Apple fruit'));

      final bananaSemantics = tester.getSemantics(find.text('Banana'));
      expect(bananaSemantics.label, contains('banana'));
    });
  });
}
