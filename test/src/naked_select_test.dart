import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'helpers/simulate_hover.dart';

extension _WidgetTesterX on WidgetTester {
  SemanticsNode findSemantics(Finder finder) {
    return getSemantics(
      find
          .descendant(
            of: finder,
            matching: find.byType(Semantics),
          )
          .first,
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
          NakedSelectItem<T>(
            value: 'apple' as T,
            child: const Text('Apple'),
          ),
          NakedSelectItem<T>(
            value: 'banana' as T,
            child: const Text('Banana'),
          ),
          NakedSelectItem<T>(
            value: 'orange' as T,
            child: const Text('Orange'),
          ),
        ],
      ),
    );
    const child = NakedSelectTrigger(
      child: Text('Select option'),
    );
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
    testWidgets('renders trigger and menu when opened',
        (WidgetTester tester) async {
      await tester.pumpMaterialWidget(
        buildSelect<String>(),
      );

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

    testWidgets('supports multiple selection mode',
        (WidgetTester tester) async {
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
      await tester.pumpMaterialWidget(
        buildSelect<String>(),
      );

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
      await tester.pumpMaterialWidget(
        buildSelect<String>(),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsNothing);
    });

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
    testWidgets('focuses item matching typed character',
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
    });
  });

  group('Accessibility', () {
    testWidgets('provides semantic button property for trigger',
        (WidgetTester tester) async {
      await tester.pumpMaterialWidget(
        buildSelect<String>(),
      );

      final semantics = tester.findSemantics(
        find.byType(NakedSelectTrigger),
      );

      expect(semantics.hasFlag(SemanticsFlag.isButton), true);
    });

    testWidgets('marks items as selected in semantics',
        (WidgetTester tester) async {
      await tester.pumpMaterialWidget(
        buildSelect<String>(
          selectedValue: 'apple',
        ),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // Find the semantics node for the Apple item
      final semantics = tester.findSemantics(
        find.byType(NakedSelectItem<String>),
      );

      expect(semantics.hasFlag(SemanticsFlag.isSelected), true);
    });

    testWidgets('shows correct enabled/disabled state',
        (WidgetTester tester) async {
      for (var enabled in [true, false]) {
        await tester.pumpMaterialWidget(
          buildSelect<String>(
            enabled: enabled,
          ),
        );

        final semantics = tester.findSemantics(
          find.byType(NakedSelectTrigger),
        );

        expect(semantics.hasFlag(SemanticsFlag.isEnabled), enabled);

        await tester.pumpWidget(Container());
      }
    });
  });

  group('Interaction States', () {
    testWidgets('calls onHoverState when trigger hovered',
        (WidgetTester tester) async {
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
              onHoverState: (value) => isHovered = value,
              child: const Text('Select option'),
            ),
          ),
        ),
      );

      await tester.simulateHover(key, onHover: () {
        expect(isHovered, true);
      });

      expect(isHovered, false);
    });

    testWidgets('calls onPressedState when trigger pressed',
        (WidgetTester tester) async {
      bool isPressed = false;

      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          menu: const SizedBox(),
          child: NakedSelectTrigger(
            onPressedState: (value) => isPressed = value,
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

    testWidgets('calls onFocusState when trigger focused',
        (WidgetTester tester) async {
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
            onFocusState: (value) => isFocused = value,
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

    testWidgets('calls item states when hovered/pressed',
        (WidgetTester tester) async {
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
                onHoverState: (value) => itemHovered = value,
                onPressedState: (value) => itemPressed = value,
                child: const Text('Apple'),
              ),
            ),
            child: const NakedSelectTrigger(
              child: Text('Select option'),
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // Test hover
      await tester.simulateHover(key, onHover: () {
        expect(itemHovered, true);
      });
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
      await tester.pumpMaterialWidget(
        buildSelect<String>(),
      );

      // Open menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // Menu should be rendered in the overlay
      expect(find.byType(OverlayPortal), findsOneWidget);
    });
  });

  group('Selection Behavior', () {
    testWidgets('keeps menu open when closeOnSelect is false',
        (WidgetTester tester) async {
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

    testWidgets('closes menu when closeOnSelect is true',
        (WidgetTester tester) async {
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
    testWidgets('shows appropriate cursor based on interactive state',
        (WidgetTester tester) async {
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

      tester.expectCursor(
        SystemMouseCursors.click,
        on: keyEnabledTrigger,
      );

      tester.expectCursor(
        SystemMouseCursors.forbidden,
        on: keyDisabledTrigger,
      );
    });
  });
}
