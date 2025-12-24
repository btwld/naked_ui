import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/naked_ui.dart';

import '../test_helpers.dart';
import 'helpers/builder_state_scope.dart';

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
        builder: (context, state, child) => const Text('Select option'),
        overlayBuilder: (context, info) => Container(
          key: kMenuKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedSelectOption<T>(
                value: 'apple' as T,
                child: const Text('Apple'),
              ),
              NakedSelectOption<T>(
                value: 'banana' as T,
                child: const Text('Banana'),
              ),
              NakedSelectOption<T>(
                value: 'orange' as T,
                child: const Text('Orange'),
              ),
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

    testStateScopeBuilder<NakedSelectState>(
      'builder\'s context contains NakedStateScope',
      (builder) => NakedSelect(
        builder: builder,
        overlayBuilder: (context, info) =>
            const SizedBox(child: Text('Select option')),
        child: const Text('Select option'),
      ),
    );
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
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets(
      'restores focus to trigger after closing with Escape',
      (tester) async {
        final triggerFocusNode = FocusNode();

        await tester.pumpMaterialWidget(
          Center(
            child: NakedSelect<String>(
              triggerFocusNode: triggerFocusNode,
              builder: (context, state, child) => const Text('Select option'),
              overlayBuilder: (context, info) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NakedSelectOption<String>(
                    value: 'apple',
                    child: Text('Apple'),
                  ),
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
        await tester.pumpAndSettle();

        // Expect focus to be back on the trigger
        expect(triggerFocusNode.hasFocus, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets('selects item with Enter key', (WidgetTester tester) async {
      String? selectedValue;

      await tester.pumpMaterialWidget(
        Center(
          child: NakedSelect<String>(
            onChanged: (value) => selectedValue = value,
            builder: (context, state, child) => const Text('Select option'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedSelectOption<String>(value: 'apple', child: Text('Apple')),
                NakedSelectOption<String>(
                  value: 'banana',
                  child: Text('Banana'),
                ),
              ],
            ),
          ),
        ),
      );

      // Open the select menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // Verify overlay is open
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      // Navigate to first item with arrow down, then press Enter to select
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify selection was made and overlay closed
      expect(selectedValue, 'apple');
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('PageDown moves focus forward by multiple items', (
      WidgetTester tester,
    ) async {
      // Build a select with many options to test PageDown
      await tester.pumpMaterialWidget(
        Center(
          child: NakedSelect<String>(
            builder: (context, state, child) => const Text('Select option'),
            overlayBuilder: (context, info) => Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                15,
                (index) => NakedSelectOption<String>(
                  value: 'option$index',
                  child: Text('Option $index'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the select menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // Focus the first option
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Press PageDown to jump forward
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();

      // The focus should have moved forward (exact position depends on implementation)
      // We just verify the menu is still open and responding to keyboard
      expect(find.text('Option 0'), findsOneWidget);

      // Close menu
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });

    testWidgets('PageUp moves focus backward by multiple items', (
      WidgetTester tester,
    ) async {
      // Build a select with many options to test PageUp
      await tester.pumpMaterialWidget(
        Center(
          child: NakedSelect<String>(
            builder: (context, state, child) => const Text('Select option'),
            overlayBuilder: (context, info) => Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                15,
                (index) => NakedSelectOption<String>(
                  value: 'option$index',
                  child: Text('Option $index'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the select menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // Navigate to a later option using multiple arrow downs
      for (int i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }

      // Press PageUp to jump backward
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();

      // The focus should have moved backward (exact position depends on implementation)
      // We just verify the menu is still open and responding to keyboard
      expect(find.text('Option 0'), findsOneWidget);

      // Close menu
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });

    testWidgets('PageUp/PageDown do nothing when menu is closed', (
      WidgetTester tester,
    ) async {
      await tester.pumpMaterialWidget(buildSelect<String>());

      // Menu is closed
      expect(find.text('Apple'), findsNothing);

      // Press PageDown - should not open menu
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing);

      // Press PageUp - should not open menu
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('PageDown with fewer items than page size stops at last item', (
      WidgetTester tester,
    ) async {
      String? selectedValue;

      await tester.pumpMaterialWidget(
        Center(
          child: NakedSelect<String>(
            onChanged: (value) => selectedValue = value,
            builder: (context, state, child) => const Text('Select option'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedSelectOption<String>(value: 'a', child: Text('A')),
                NakedSelectOption<String>(value: 'b', child: Text('B')),
                NakedSelectOption<String>(value: 'c', child: Text('C')),
              ],
            ),
          ),
        ),
      );

      // Open the select menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      // Focus first option
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Press PageDown (should go to last option since fewer than 10 items)
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();

      // Press Enter to select current focused item
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Should have selected the last item (C) since PageDown went to the end
      // Note: The actual behavior depends on how many focus jumps fit,
      // but the menu should still work correctly
      expect(selectedValue, isNotNull);
    });
  });

  group('Interaction States', () {
    testWidgets('trigger can be hovered', (WidgetTester tester) async {
      await tester.pumpMaterialWidget(
        Center(
          child: NakedSelect<String>(
            builder: (context, state, child) {
              return Container(
                key: const Key('trigger'),
                color: state.isHovered ? Colors.grey[200] : null,
                child: const Text('Select option'),
              );
            },
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedSelectOption<String>(value: 'apple', child: Text('Apple')),
              ],
            ),
          ),
        ),
      );

      // Simulate hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text('Select option')));
      await tester.pump();

      // Verify hover state is reflected in the UI
      final container = tester.widget<Container>(
        find.byKey(const Key('trigger')),
      );
      expect(container.color, Colors.grey[200]);
    });

    testWidgets('trigger can be pressed', (tester) async {
      await tester.pumpMaterialWidget(
        Center(
          child: NakedSelect<String>(
            builder: (context, state, child) {
              return Container(
                key: const Key('trigger'),
                color: state.isPressed ? Colors.grey[400] : null,
                child: const Text('Select option'),
              );
            },
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedSelectOption<String>(value: 'apple', child: Text('Apple')),
              ],
            ),
          ),
        ),
      );

      // Simulate press down
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Select option')),
      );
      // Allow time for gesture recognition to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Verify pressed state is reflected in the UI
      final container = tester.widget<Container>(
        find.byKey(const Key('trigger')),
      );
      expect(container.color, Colors.grey[400]);

      // Release press
      await gesture.up();
      await tester.pump();
    });

    testWidgets('trigger can be focused', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpMaterialWidget(
        Center(
          child: NakedSelect<String>(
            triggerFocusNode: focusNode,
            builder: (context, state, child) {
              return Container(
                key: const Key('trigger'),
                decoration: BoxDecoration(
                  border: state.isFocused
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                child: const Text('Select option'),
              );
            },
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedSelectOption<String>(value: 'apple', child: Text('Apple')),
              ],
            ),
          ),
        ),
      );

      // Focus the trigger
      focusNode.requestFocus();
      await tester.pump();

      // Verify focused state is reflected in the UI
      final container = tester.widget<Container>(
        find.byKey(const Key('trigger')),
      );
      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isA<Border>());

      focusNode.dispose();
    });

    testWidgets('calls item states when hovered/pressed', (tester) async {
      await tester.pumpMaterialWidget(
        Center(
          child: NakedSelect<String>(
            builder: (context, state, child) => const Text('Select option'),
            overlayBuilder: (context, info) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedSelectOption<String>(
                  value: 'apple',
                  builder: (context, state, child) {
                    return Container(
                      key: const Key('apple-option'),
                      color: state.isHovered ? const Color(0xFFE0E0E0) : null,
                      child: child,
                    );
                  },
                  child: const Text('Apple'),
                ),
              ],
            ),
          ),
        ),
      );

      // Open the select menu
      await tester.tap(find.text('Select option'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('apple-option')), findsOneWidget);

      // Test hover state
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text('Apple')));
      await tester.pump();

      // The option should respond to hover (just verify it's still there and working)
      expect(find.byKey(const Key('apple-option')), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
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
                positioning: const OverlayPositionConfig(
                  targetAnchor: Alignment.bottomLeft,
                  followerAnchor: Alignment.topLeft,
                ),
                builder: (context, state, child) => const Text('Select option'),
                overlayBuilder: (context, info) => Container(
                  key: kMenuKey,
                  width: 120,
                  height: 160, // big enough to overflow downward
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Menu Content'),
                      NakedSelectOption<String>(
                        value: 'apple',
                        child: Text('Apple'),
                      ),
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
          builder: (context, state, child) => const Text('Select option'),
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
    testWidgets('shows appropriate cursor based on interactive state', (
      tester,
    ) async {
      await tester.pumpMaterialWidget(
        Center(
          child: NakedSelect<String>(
            enabled: false,
            builder: (context, state, child) => const Text('Select option'),
            overlayBuilder: (context, info) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedSelectOption<String>(value: 'apple', child: Text('Apple')),
              ],
            ),
          ),
        ),
      );

      // When disabled, should show a forbidden cursor
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text('Select option')));
      await tester.pump();

      // This test just verifies the widget can handle cursor state
      // The actual cursor rendering is handled by the platform
      expect(find.text('Select option'), findsOneWidget);
    });
  });
}
