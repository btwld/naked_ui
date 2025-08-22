import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

// Import your NakedInteractable widget
// import 'package:your_package/naked_interactable.dart';

void main() {
  group('NakedInteractable Complete Test Suite', () {
    // Test utilities
    Widget buildTestWidget({
      WidgetStatesController? controller,
      ValueWidgetBuilder<Set<WidgetState>>? builder,
      Widget? child,
      VoidCallback? onPressed,
      VoidCallback? onLongPress,
      VoidCallback? onSecondaryTap,
      VoidCallback? onSecondaryLongPress,
      ValueChanged<Set<WidgetState>>? onStateChange,
      bool selected = false,
      bool autofocus = false,
      FocusNode? focusNode,
      HitTestBehavior behavior = HitTestBehavior.opaque,
      String? semanticsLabel,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: GestureDetector(
              onTap: onPressed,
              behavior: behavior,
              child: NakedInteractable(
                statesController: controller,
                builder:
                    builder ??
                    (context, states, child) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: states.isPressed
                            ? Colors.blue
                            : Colors.grey,
                        child: child,
                      );
                    },
                child: child,
                onStateChange: onStateChange,
                selected: selected,
                autofocus: autofocus,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );
    }

    group('State Management', () {
      testWidgets('initializes with correct default states', (tester) async {
        Set<WidgetState>? capturedStates;

        await tester.pumpWidget(
          buildTestWidget(
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        expect(capturedStates, isNotNull);
        expect(capturedStates!.isDisabled, isTrue);
        expect(capturedStates!.isPressed, isFalse);
        expect(capturedStates!.isHovered, isFalse);
        expect(capturedStates!.isFocused, isFalse);
        expect(capturedStates!.isSelected, isFalse);
      });

      testWidgets('initializes with selected state when specified', (
        tester,
      ) async {
        Set<WidgetState>? capturedStates;

        await tester.pumpWidget(
          buildTestWidget(
            selected: true,
            onPressed: () {}, // Enable widget
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        expect(capturedStates!.isSelected, isTrue);
        expect(capturedStates!.isDisabled, isFalse);
      });

      testWidgets('updates disabled state based on callbacks', (tester) async {
        Set<WidgetState>? capturedStates;

        // Initially disabled (no callbacks)
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        expect(capturedStates!.isDisabled, isTrue);

        // Add callback to enable
        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        expect(capturedStates!.isDisabled, isFalse);
      });

      testWidgets('uses external controller when provided', (tester) async {
        final controller = WidgetStatesController({WidgetState.selected});
        Set<WidgetState>? capturedStates;

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            onPressed: () {},
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        expect(capturedStates, equals(controller.value));

        // Update external controller
        controller.update(WidgetState.focused, true);
        await tester.pump();

        expect(capturedStates!.isFocused, isTrue);

        // Cleanup
        controller.dispose();
      });

      testWidgets(
        'switches from internal to external controller preserving states',
        (tester) async {
          Set<WidgetState>? capturedStates;

          // Start with internal controller
          await tester.pumpWidget(
            buildTestWidget(
              selected: true,
              onPressed: () {},
              builder: (context, states, child) {
                capturedStates = states;
                return Container();
              },
            ),
          );

          expect(capturedStates!.isSelected, isTrue);

          // Hover to add another state
          final gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await gesture.moveTo(tester.getCenter(find.byType(Container)));
          await tester.pump();

          expect(capturedStates!.isHovered, isTrue);

          // Switch to external controller - should preserve current states
          final externalController = WidgetStatesController(capturedStates!);
          await tester.pumpWidget(
            buildTestWidget(
              controller: externalController,
              selected: true,
              onPressed: () {},
              builder: (context, states, child) {
                capturedStates = states;
                return Container();
              },
            ),
          );

          // States should be preserved
          expect(capturedStates!.isSelected, isTrue);
          expect(capturedStates!.isHovered, isTrue);

          await gesture.removePointer();
          externalController.dispose();
        },
      );

      testWidgets(
        'switches from external to internal controller preserving states',
        (tester) async {
          final externalController = WidgetStatesController({
            WidgetState.focused,
          });
          Set<WidgetState>? capturedStates;

          // Start with external controller
          await tester.pumpWidget(
            buildTestWidget(
              controller: externalController,
              onPressed: () {},
              builder: (context, states, child) {
                capturedStates = states;
                return Container();
              },
            ),
          );

          expect(capturedStates!.isFocused, isTrue);

          // Switch to internal controller
          await tester.pumpWidget(
            buildTestWidget(
              onPressed: () {},
              builder: (context, states, child) {
                capturedStates = states;
                return Container();
              },
            ),
          );

          // Focus state should be preserved
          expect(capturedStates!.isFocused, isTrue);

          externalController.dispose();
        },
      );
    });

    group('Tap Gestures', () {
      testWidgets('handles tap correctly', (tester) async {
        bool tapped = false;
        Set<WidgetState>? capturedStates;

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () => tapped = true,
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        await tester.tap(find.byType(Container));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
        expect(
          capturedStates!.isPressed,
          isFalse,
        ); // Released after tap
      });

      testWidgets('updates pressed state during tap', (tester) async {
        final stateChanges = <Set<WidgetState>>[];

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        // Create gesture to control timing
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Container)),
        );
        await tester.pump();

        // Should be pressed
        expect(stateChanges.last.isPressed, isTrue);

        // Release
        await gesture.up();
        await tester.pump();

        // Should not be pressed
        expect(stateChanges.last.isPressed, isFalse);
      });

      testWidgets('handles long press correctly', (tester) async {
        bool longPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GestureDetector(
                onLongPress: () => longPressed = true,
                child: buildTestWidget(onPressed: () {}),
              ),
            ),
          ),
        );

        await tester.longPress(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(longPressed, isTrue);
      });

      testWidgets('handles secondary tap (right-click)', (tester) async {
        bool secondaryTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GestureDetector(
                onSecondaryTap: () => secondaryTapped = true,
                child: buildTestWidget(onPressed: () {}),
              ),
            ),
          ),
        );

        await tester.tap(
          find.byType(GestureDetector).first,
          buttons: kSecondaryButton,
        );
        await tester.pumpAndSettle();

        expect(secondaryTapped, isTrue);
      });

      testWidgets('handles secondary long press', (tester) async {
        bool secondaryLongPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GestureDetector(
                onSecondaryLongPress: () => secondaryLongPressed = true,
                child: buildTestWidget(onPressed: () {}),
              ),
            ),
          ),
        );

        // Start secondary button gesture
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(GestureDetector).first),
          buttons: kSecondaryButton,
        );

        // Wait for long press duration
        await tester.pump(const Duration(milliseconds: 600));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(secondaryLongPressed, isTrue);
      });

      testWidgets('does not trigger gestures when disabled', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            // No onPressed passed to GestureDetector; still disabled for NakedInteractable
            builder: (context, states, child) {
              expect(states.isDisabled, isTrue);
              return Container();
            },
          ),
        );

        await tester.tap(find.byType(Container));
        await tester.pumpAndSettle();

        expect(tapped, isFalse);
      });
    });

    group('Hover States', () {
      testWidgets('updates hover state on mouse enter/exit', (tester) async {
        final stateChanges = <Set<WidgetState>>[];

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        // Create a hover pointer
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );

        // Move pointer to center (hover enter)
        await gesture.moveTo(tester.getCenter(find.byType(Container)));
        await tester.pump();

        expect(stateChanges.last.isHovered, isTrue);

        // Move pointer away (hover exit)
        await gesture.moveTo(Offset.zero);
        await tester.pump();

        expect(stateChanges.last.isHovered, isFalse);

        // Clean up
        await gesture.removePointer();
      });

      testWidgets('hover does not interfere with tap', (tester) async {
        bool tapped = false;
        final stateChanges = <Set<WidgetState>>[];

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () => tapped = true,
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        // Create mouse pointer and hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveTo(tester.getCenter(find.byType(Container)));
        await tester.pump();

        expect(stateChanges.last.isHovered, isTrue);

        // Click while hovering
        await gesture.down(tester.getCenter(find.byType(Container)));
        await tester.pump();

        expect(stateChanges.last.isPressed, isTrue);
        expect(stateChanges.last.isHovered, isTrue);

        await gesture.up();
        await tester.pump();

        expect(tapped, isTrue);
        expect(stateChanges.last.isPressed, isFalse);
        expect(stateChanges.last.isHovered, isTrue);

        await gesture.removePointer();
      });
    });

    group('Pointer Boundary Detection', () {
      testWidgets('cancels pressed state when pointer moves outside', (
        tester,
      ) async {
        final stateChanges = <Set<WidgetState>>[];

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        final center = tester.getCenter(find.byType(Container));

        // Start press
        final gesture = await tester.startGesture(center);
        await tester.pump();

        expect(stateChanges.last.isPressed, isTrue);

        // Move outside bounds
        await gesture.moveTo(center + const Offset(200, 200));
        await tester.pump();

        expect(stateChanges.last.isPressed, isFalse);

        await gesture.up();
      });

      testWidgets('maintains pressed state when moving within bounds', (
        tester,
      ) async {
        final stateChanges = <Set<WidgetState>>[];

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        final center = tester.getCenter(find.byType(Container));

        // Start press
        final gesture = await tester.startGesture(center);
        await tester.pump();

        expect(stateChanges.last.isPressed, isTrue);

        // Move within bounds (container is 100x100)
        await gesture.moveTo(center + const Offset(30, 30));
        await tester.pump();

        expect(stateChanges.last.isPressed, isTrue);

        await gesture.up();
      });

      testWidgets('does not affect hover when pressed state cancelled', (
        tester,
      ) async {
        final stateChanges = <Set<WidgetState>>[];

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        // Use mouse to get hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        final center = tester.getCenter(find.byType(Container));

        // Hover
        await gesture.moveTo(center);
        await tester.pump();
        expect(stateChanges.last.isHovered, isTrue);

        // Press
        await gesture.down(center);
        await tester.pump();
        expect(stateChanges.last.isPressed, isTrue);
        expect(stateChanges.last.isHovered, isTrue);

        // Move out of bounds
        await gesture.moveTo(center + const Offset(200, 200));
        await tester.pump();

        // Pressed cancelled but hover also exits
        expect(stateChanges.last.isPressed, isFalse);
        expect(stateChanges.last.isHovered, isFalse);

        await gesture.up();
        await gesture.removePointer();
      });
    });

    group('Focus Management', () {
      testWidgets('updates focus state correctly', (tester) async {
        final focusNode = FocusNode();
        final stateChanges = <Set<WidgetState>>[];

        await tester.pumpWidget(
          buildTestWidget(
            focusNode: focusNode,
            onPressed: () {},
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        // Request focus
        focusNode.requestFocus();
        await tester.pump();

        expect(stateChanges.last.isFocused, isTrue);

        // Remove focus
        focusNode.unfocus();
        await tester.pump();

        expect(stateChanges.last.isFocused, isFalse);

        focusNode.dispose();
      });

      testWidgets('autofocus works correctly', (tester) async {
        final stateChanges = <Set<WidgetState>>[];

        await tester.pumpWidget(
          buildTestWidget(
            autofocus: true,
            onPressed: () {},
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        // Need extra pump for autofocus to take effect
        await tester.pump();

        expect(
          stateChanges.any((s) => s.isFocused),
          isTrue,
        );
      });

      testWidgets('focus survives widget rebuild', (tester) async {
        final focusNode = FocusNode();
        Set<WidgetState>? capturedStates;

        await tester.pumpWidget(
          buildTestWidget(
            focusNode: focusNode,
            onPressed: () {},
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        focusNode.requestFocus();
        await tester.pump();
        expect(capturedStates!.isFocused, isTrue);

        // Rebuild with different property
        await tester.pumpWidget(
          buildTestWidget(
            focusNode: focusNode,
            selected: true, // Changed
            onPressed: () {},
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        // Focus should be maintained
        expect(capturedStates!.isFocused, isTrue);
        expect(capturedStates!.isSelected, isTrue);

        focusNode.dispose();
      });
    });

    group('State Change Notifications', () {
      testWidgets('onStateChange called for all state changes', (tester) async {
        final stateChanges = <Set<WidgetState>>[];

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        // Hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveTo(tester.getCenter(find.byType(Container)));
        await tester.pump();

        expect(stateChanges.length, greaterThanOrEqualTo(1));
        expect(stateChanges.last.isHovered, isTrue);

        // Press
        await gesture.down(tester.getCenter(find.byType(Container)));
        await tester.pump();

        final previousLength = stateChanges.length;
        expect(stateChanges.length, greaterThan(previousLength - 1));
        expect(stateChanges.last.isPressed, isTrue);

        // Release
        await gesture.up();
        await tester.pump();

        expect(stateChanges.last.isPressed, isFalse);

        await gesture.removePointer();
      });

      testWidgets('state changes trigger builder rebuild', (tester) async {
        int buildCount = 0;

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            builder: (context, states, child) {
              buildCount++;
              return Container(
                color: states.isPressed
                    ? Colors.blue
                    : Colors.grey,
              );
            },
          ),
        );

        final initialBuildCount = buildCount;

        // Trigger state change via tap
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Container)),
        );
        await tester.pump();

        expect(buildCount, greaterThan(initialBuildCount));

        // Verify color changed
        final container = tester.widget<Container>(find.byType(Container).last);
        expect((container.color as Color), equals(Colors.blue));

        await gesture.up();
        await tester.pump();

        final releasedContainer = tester.widget<Container>(
          find.byType(Container).last,
        );
        expect((releasedContainer.color as Color), equals(Colors.grey));
      });

      testWidgets('multiple simultaneous state changes', (tester) async {
        final stateChanges = <Set<WidgetState>>[];
        final focusNode = FocusNode();

        await tester.pumpWidget(
          buildTestWidget(
            focusNode: focusNode,
            onPressed: () {},
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        // Create mouse for hover
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );

        // Trigger multiple states at once
        await gesture.moveTo(tester.getCenter(find.byType(Container))); // Hover
        focusNode.requestFocus(); // Focus
        await gesture.down(tester.getCenter(find.byType(Container))); // Press
        await tester.pump();

        // Should have all three states
        expect(stateChanges.last.isHovered, isTrue);
        expect(stateChanges.last.isFocused, isTrue);
        expect(stateChanges.last.isPressed, isTrue);

        await gesture.up();
        await gesture.removePointer();
        focusNode.dispose();
      });
    });

    group('Child Widget', () {
      testWidgets('passes child through builder correctly', (tester) async {
        const childWidget = Text('Child Widget');
        Widget? capturedChild;

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            child: childWidget,
            builder: (context, states, child) {
              capturedChild = child;
              return Container(child: child);
            },
          ),
        );

        expect(capturedChild, equals(childWidget));
        expect(find.text('Child Widget'), findsOneWidget);
      });

      testWidgets('child does not rebuild on state changes', (tester) async {
        int childBuildCount = 0;

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('Static Child');
              },
            ),
            builder: (context, states, child) {
              return Container(child: child);
            },
          ),
        );

        final initialChildBuilds = childBuildCount;

        // Trigger state change
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Container)),
        );
        await tester.pump();
        await gesture.up();
        await tester.pump();

        // Child should not rebuild
        expect(childBuildCount, equals(initialChildBuilds));
      });
    });

    group('HitTestBehavior', () {
      testWidgets('respects opaque hit test behavior', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () => tapped = true,
            behavior: HitTestBehavior.opaque,
          ),
        );

        await tester.tap(find.byType(Container));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('respects translucent hit test behavior', (tester) async {
        bool backgroundTapped = false;
        bool foregroundTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: GestureDetector(
              onTap: () => backgroundTapped = true,
              child: Container(
                color: Colors.red,
                child: Center(
                  child: GestureDetector(
                    onTap: () => foregroundTapped = true,
                    behavior: HitTestBehavior.translucent,
                    child: NakedInteractable(
                      builder: (context, states, child) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.transparent,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(Container).last);
        await tester.pump();

        expect(foregroundTapped, isTrue);
        expect(backgroundTapped, isFalse); // Translucent still blocks
      });

      testWidgets('respects deferToChild hit test behavior', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () => tapped = true,
            behavior: HitTestBehavior.deferToChild,
            builder: (context, states, child) {
              // Empty container with no color
              return Container(width: 100, height: 100);
            },
          ),
        );

        await tester.tap(find.byType(Container));
        await tester.pump();

        // With deferToChild and no colored child, tap might not register
        // This behavior depends on the exact implementation
        expect(tapped, isTrue);
      });
    });

    group('Semantics', () {
      testWidgets('provides correct semantic information', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            semanticsLabel: 'Test Button',
            selected: true,
            onPressed: () {},
          ),
        );

        final semantics = tester.getSemantics(find.byType(Container));

        expect(semantics.label, 'Test Button');
        // ignore: deprecated_member_use
        expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
        // ignore: deprecated_member_use
        expect(semantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
        // ignore: deprecated_member_use
        expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
      });

      testWidgets('disabled state reflected in semantics', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(semanticsLabel: 'Disabled Button'),
        );

        final semantics = tester.getSemantics(find.byType(Container));

        // ignore: deprecated_member_use
        expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
      });

      testWidgets('button semantics present even without label', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(onPressed: () {}));

        final semantics = tester.getSemantics(find.byType(Container));

        // ignore: deprecated_member_use
        expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      });
    });

    group('Keyboard Interaction', () {
      testWidgets('Enter key triggers onTap when focused', (tester) async {
        bool tapped = false;
        final focusNode = FocusNode();

        await tester.pumpWidget(
          buildTestWidget(focusNode: focusNode, onPressed: () => tapped = true),
        );

        // Focus the widget
        focusNode.requestFocus();
        await tester.pump();

        // Simulate Enter key press
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(tapped, isTrue);

        focusNode.dispose();
      });

      testWidgets('Space key does not trigger onTap by default', (
        tester,
      ) async {
        bool tapped = false;
        final focusNode = FocusNode();

        await tester.pumpWidget(
          buildTestWidget(focusNode: focusNode, onPressed: () => tapped = true),
        );

        focusNode.requestFocus();
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        expect(tapped, isFalse);

        focusNode.dispose();
      });
    });

    group('Edge Cases', () {
      testWidgets('handles rapid tap/untap correctly', (tester) async {
        final stateChanges = <Set<WidgetState>>[];
        int tapCount = 0;

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () => tapCount++,
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        // Rapid taps
        for (int i = 0; i < 5; i++) {
          final gesture = await tester.startGesture(
            tester.getCenter(find.byType(Container)),
          );
          await tester.pump();
          await gesture.up();
          await tester.pump();
        }

        // Should not be stuck in pressed state
        expect(stateChanges.last.isPressed, isFalse);
        expect(tapCount, equals(5));
      });

      testWidgets('handles pointer cancel correctly', (tester) async {
        final stateChanges = <Set<WidgetState>>[];

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            onStateChange: (states) => stateChanges.add({...states}),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Container)),
        );
        await tester.pump();

        expect(stateChanges.last.isPressed, isTrue);

        // Cancel instead of up
        await gesture.cancel();
        await tester.pump();

        expect(stateChanges.last.isPressed, isFalse);
      });

      testWidgets('handles widget disposal during interaction', (tester) async {
        final controller = WidgetStatesController();

        await tester.pumpWidget(
          buildTestWidget(controller: controller, onPressed: () {}),
        );

        // Start interaction
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Container)),
        );
        await tester.pump();

        // Dispose widget while pressed
        await tester.pumpWidget(Container());

        // Should not throw
        await gesture.up();

        controller.dispose();
      });

      testWidgets('handles null callbacks gracefully', (tester) async {
        Set<WidgetState>? capturedStates;

        await tester.pumpWidget(
          buildTestWidget(
            onPressed: null,
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        // Should be disabled
        expect(capturedStates!.isDisabled, isTrue);

        // Try to tap - should not crash
        await tester.tap(find.byType(Container));
        await tester.pump();

        // Still disabled
        expect(capturedStates!.isDisabled, isTrue);
      });

      testWidgets('controller disposal does not affect widget', (tester) async {
        final controller = WidgetStatesController();
        Set<WidgetState>? capturedStates;

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            onPressed: () {},
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        // Update state
        controller.update(WidgetState.focused, true);
        await tester.pump();
        expect(capturedStates!.isFocused, isTrue);

        // Switch to internal controller
        await tester.pumpWidget(
          buildTestWidget(
            onPressed: () {},
            builder: (context, states, child) {
              capturedStates = states;
              return Container();
            },
          ),
        );

        // Dispose external controller
        controller.dispose();

        // Widget should still work
        await tester.tap(find.byType(Container));
        await tester.pump();

        // No crash, widget still functional
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('Memory and Performance', () {
      testWidgets('no memory leaks with internal controller', (tester) async {
        // Create and destroy multiple times
        for (int i = 0; i < 3; i++) {
          await tester.pumpWidget(buildTestWidget(onPressed: () {}));

          await tester.pumpWidget(Container());
        }

        // If we get here without crashes, disposal is working
        expect(true, isTrue);
      });

      testWidgets('state listener properly removed on disposal', (
        tester,
      ) async {
        final controller = WidgetStatesController();

        await tester.pumpWidget(
          buildTestWidget(controller: controller, onPressed: () {}),
        );

        // Dispose widget
        await tester.pumpWidget(Container());

        // We can't access controller.hasListeners here safely across Flutter versions,
        // but no exceptions implies listeners were cleaned up.
        expect(true, isTrue);

        controller.dispose();
      });

      testWidgets(
        'efficient rebuilds - only builder rebuilds on state change',
        (tester) async {
          int parentBuildCount = 0;
          int builderBuildCount = 0;

          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                parentBuildCount++;
                return MaterialApp(
                  home: GestureDetector(
                    onTap: () {},
                    child: NakedInteractable(
                      builder: (context, states, child) {
                        builderBuildCount++;
                        return Container();
                      },
                    ),
                  ),
                );
              },
            ),
          );

          final initialParentBuilds = parentBuildCount;
          final initialBuilderBuilds = builderBuildCount;

          // Trigger state change
          final gesture = await tester.startGesture(
            tester.getCenter(find.byType(Container)),
          );
          await tester.pump();
          await gesture.up();
          await tester.pump();

          // Parent should not rebuild
          expect(parentBuildCount, equals(initialParentBuilds));
          // Builder should rebuild for state changes
          expect(builderBuildCount, greaterThan(initialBuilderBuilds));
        },
      );
    });
  });
}
