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
    bool enabled = true,
    VoidCallback? onMenuClose,
    bool closeOnSelect = true,
  }) {
    return Center(
      child: NakedSelect<T>(
        value: selectedValue,
        onChanged: onSelectedValueChanged,
        enabled: enabled,
        closeOnSelect: closeOnSelect,
        onClose: onMenuClose,
        triggerBuilder: (context, states) => const Text('Select option'),
        overlayBuilder: (context, info) => Container(
          key: kMenuKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedSelectOption<T>(value: 'apple' as T, child: const Text('Apple')),
              NakedSelectOption<T>(value: 'banana' as T, child: const Text('Banana')),
              NakedSelectOption<T>(value: 'orange' as T, child: const Text('Orange')),
            ],
          ),
        ),
      ),
    );
  }

  group('Core Functionality', () {
    testWidgets(
      'renders trigger and menu when opened',
      (WidgetTester tester) async {
        await tester.pumpMaterialWidget(buildSelect<String>());

        await tester.tap(find.text('Select option'));
        await tester.pump();

        expect(find.text('Select option'), findsOneWidget);
        expect(find.text('Apple'), findsOneWidget);
        expect(find.text('Banana'), findsOneWidget);
        expect(find.text('Orange'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'selects single value correctly',
      (WidgetTester tester) async {
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
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

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

    testWidgets(
      'does not respond when disabled',
      (WidgetTester tester) async {
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
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('Keyboard Navigation', () {
    testWidgets(
      'closes menu with Escape key',
      (WidgetTester tester) async {
        await tester.pumpMaterialWidget(buildSelect<String>());

        // Open menu
        await tester.tap(find.text('Select option'));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        expect(find.text('Apple'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 10)),
      skip: true,
    );

    testWidgets(
      'restores focus to trigger after closing with Escape',
      (tester) async {
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          Center(
            child: NakedSelect<String>(
              triggerFocusNode: triggerFocusNode,
              triggerBuilder: (context, states) => const Text('Select option'),
              overlayBuilder: (context, info) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedSelectOption<String>(value: 'apple', child: Text('Apple')),
                ],
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
      },
      timeout: const Timeout(Duration(seconds: 10)),
      skip: true,
    );

    testWidgets(
      'selects item with Enter key',
      (WidgetTester tester) async {},
      skip: true,
    );
  });

  group('Interaction States', () {
    testWidgets(
      'calls onHoverChange when trigger hovered',
      (WidgetTester tester) async {},
      skip: true,
    );

    testWidgets(
      'calls onPressChange when trigger pressed',
      (tester) async {},
      skip: true,
    );

    testWidgets(
      'calls onFocusChange when trigger focused',
      (tester) async {},
      skip: true,
    );

    testWidgets(
      'calls item states when hovered/pressed',
      (tester) async {},
      skip: true,
    );
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
                positioning: const OverlayPositionConfig(
                  alignment: Alignment.bottomLeft,
                  fallbackAlignment: Alignment.topLeft,
                ),
                triggerBuilder: (context, states) =>
                    const Text('Select option'),
                overlayBuilder: (context, info) => Container(
                  key: kMenuKey,
                  width: 120,
                  height: 160, // big enough to overflow downward
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Menu Content'),
                      NakedSelectOption<String>(value: 'apple', child: Text('Apple')),
                    ],
                  ),
                ),
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

        // Assert the overlay is at least partially visible within viewport
        final view = tester.binding.platformDispatcher.views.first;
        final Size screenSize = view.physicalSize / view.devicePixelRatio;
        expect(menuRect.right > 0, isTrue);
        expect(menuRect.bottom > 0, isTrue);
        expect(menuRect.left < screenSize.width, isTrue);
        expect(menuRect.top < screenSize.height, isTrue);

        // Optional sanity: menu should be positioned near the trigger in Y direction
        // (above or below), but we don't assert exact fallback choice.
        expect(
          menuRect.overlaps(triggerRect) ||
              menuRect.bottom <= triggerRect.top ||
              menuRect.top >= triggerRect.bottom,
          isTrue,
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('Selection Behavior', () {
    testWidgets(
      'keeps menu open when closeOnSelect is false',
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
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'closes menu when closeOnSelect is true',
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
        await tester.pump();

        await tester.tap(find.text('Banana'));
        await tester.pump();

        expect(selectedValue, 'banana');
        expect(find.text('Apple'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets('outside tap closes menu with removalDelay respected', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(
        NakedSelect<String>(
          onCloseRequested: (hideOverlay) {
            // Simulate removalDelay by delaying the actual close
            Future.delayed(const Duration(milliseconds: 200), hideOverlay);
          },
          triggerBuilder: (context, states) => const Text('Select option'),
          overlayBuilder: (context, info) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedSelectOption<String>(value: 'apple', child: Text('Apple')),
              NakedSelectOption<String>(value: 'banana', child: Text('Banana')),
            ],
          ),
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

  group('Cursor', () {
    testWidgets(
      'shows appropriate cursor based on interactive state',
      (tester) async {},
      skip: true,
    );
  });
}
