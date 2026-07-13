import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

import '../test_helpers.dart';

void main() {
  group('NakedLink public state contract', () {
    test('requires either a child or builder', () {
      expect(() => NakedLink(onPressed: () {}), throwsAssertionError);
    });

    testWidgets('renders its child without a builder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NakedLink(onPressed: () {}, child: const Text('Documentation')),
        ),
      );

      expect(find.text('Documentation'), findsOneWidget);
    });

    testWidgets('builder and scope receive one immutable state snapshot', (
      tester,
    ) async {
      final linkUrl = Uri.parse('https://example.com/docs');
      NakedLinkState? builderState;
      NakedLinkState? scopedState;
      Widget? receivedChild;

      await tester.pumpWidget(
        MaterialApp(
          home: NakedLink(
            linkUrl: linkUrl,
            onPressed: () {},
            child: const Text('Documentation'),
            builder: (context, state, child) {
              builderState = state;
              scopedState = NakedLinkState.of(context);
              receivedChild = child;
              return child!;
            },
          ),
        ),
      );

      expect(builderState, isNotNull);
      expect(scopedState, same(builderState));
      expect(receivedChild, isA<Text>());
      expect(builderState!.linkUrl, linkUrl);
      expect(builderState!.states, isEmpty);
      expect(
        () => builderState!.states.add(WidgetState.hovered),
        throwsUnsupportedError,
      );
      expect(builderState!.states, isEmpty);
    });

    test('state equality and hash include states and URL metadata', () {
      final first = NakedLinkState(
        states: const {WidgetState.hovered, WidgetState.focused},
        linkUrl: Uri.parse('https://example.com/docs'),
      );
      final reordered = NakedLinkState(
        states: const {WidgetState.focused, WidgetState.hovered},
        linkUrl: Uri.parse('https://example.com/docs'),
      );
      final otherUrl = NakedLinkState(
        states: const {WidgetState.hovered, WidgetState.focused},
        linkUrl: Uri.parse('https://example.com/support'),
      );

      expect(first, reordered);
      expect(first.hashCode, reordered.hashCode);
      expect(first, isNot(otherUrl));
    });
  });

  group('NakedLink activation contract', () {
    testWidgets('primary tap updates press state and activates exactly once', (
      tester,
    ) async {
      const linkKey = ValueKey('link');
      var callbackCount = 0;
      final pressChanges = <bool>[];
      NakedLinkState? state;

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            key: linkKey,
            onPressed: () => callbackCount++,
            onPressChange: pressChanges.add,
            builder: (context, value, child) {
              state = value;
              return const SizedBox(
                width: 160,
                height: 48,
                child: Text('Link'),
              );
            },
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(linkKey)),
      );
      await tester.pump();
      expect(state!.isPressed, isTrue);
      expect(pressChanges, [true]);
      expect(callbackCount, 0);

      await gesture.up();
      await tester.pump();
      expect(state!.isPressed, isFalse);
      expect(pressChanges, [true, false]);
      expect(callbackCount, 1);
    });

    testWidgets('canceled primary gesture clears press without activating', (
      tester,
    ) async {
      const linkKey = ValueKey('link');
      var callbackCount = 0;
      final pressChanges = <bool>[];

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            key: linkKey,
            onPressed: () => callbackCount++,
            onPressChange: pressChanges.add,
            child: const SizedBox(width: 160, height: 48, child: Text('Link')),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(linkKey)),
      );
      await tester.pump();
      await gesture.moveTo(const Offset(-100, -100));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(pressChanges, [true, false]);
      expect(callbackCount, 0);
    });

    testWidgets('secondary click remains unclaimed', (tester) async {
      const linkKey = ValueKey('link');
      var callbackCount = 0;
      final pressChanges = <bool>[];

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            key: linkKey,
            onPressed: () => callbackCount++,
            onPressChange: pressChanges.add,
            child: const SizedBox(width: 160, height: 48, child: Text('Link')),
          ),
        ),
      );

      await tester.tapAt(
        tester.getCenter(find.byKey(linkKey)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();

      expect(callbackCount, 0);
      expect(pressChanges, isEmpty);
    });

    testWidgets('Enter and Numpad Enter activate while Space does not', (
      tester,
    ) async {
      final focusNode = FocusNode(debugLabel: 'link test');
      addTearDown(focusNode.dispose);
      var callbackCount = 0;
      NakedLinkState? state;

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            focusNode: focusNode,
            onPressed: () => callbackCount++,
            builder: (context, value, child) {
              state = value;
              return const SizedBox(
                width: 160,
                height: 48,
                child: Text('Link'),
              );
            },
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(callbackCount, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pump();
      expect(callbackCount, 2);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(callbackCount, 2);
      expect(state!.isPressed, isFalse);
    });

    testWidgets('feedback occurs only for accepted enabled activation', (
      tester,
    ) async {
      final oldPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final platformCalls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        platformCalls.add(call);
        return null;
      });

      try {
        var enabled = true;
        var feedback = true;
        late StateSetter rebuild;
        await tester.pumpWidget(
          _testApp(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return NakedLink(
                  enabled: enabled,
                  enableFeedback: feedback,
                  onPressed: () {},
                  child: const SizedBox(
                    width: 160,
                    height: 48,
                    child: Text('Link'),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Link'));
        await tester.pump();
        expect(
          platformCalls.where((call) => call.method == 'SystemSound.play'),
          hasLength(1),
        );
        rebuild(() => feedback = false);
        await tester.pump();
        await tester.tap(find.text('Link'));
        await tester.pump();
        expect(
          platformCalls.where((call) => call.method == 'SystemSound.play'),
          hasLength(1),
        );

        rebuild(() {
          feedback = true;
          enabled = false;
        });
        await tester.pump();
        await tester.tap(find.text('Link'));
        await tester.pump();
        expect(
          platformCalls.where((call) => call.method == 'SystemSound.play'),
          hasLength(1),
        );
      } finally {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
        debugDefaultTargetPlatformOverride = oldPlatform;
      }
    });
  });

  group('NakedLink interaction state and lifecycle', () {
    testWidgets('hover and focus transitions update callbacks and scope', (
      tester,
    ) async {
      const linkKey = ValueKey('link');
      final focusNode = FocusNode(debugLabel: 'link hover focus');
      addTearDown(focusNode.dispose);
      final hoverChanges = <bool>[];
      final focusChanges = <bool>[];
      NakedLinkState? state;

      await tester.pumpWidget(
        _testApp(
          NakedLink(
            key: linkKey,
            focusNode: focusNode,
            onPressed: () {},
            onHoverChange: hoverChanges.add,
            onFocusChange: focusChanges.add,
            builder: (context, value, child) {
              state = NakedLinkState.of(context);
              expect(state, same(value));
              return const SizedBox(
                width: 160,
                height: 48,
                child: Text('Link'),
              );
            },
          ),
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(linkKey)));
      await tester.pump();
      expect(state!.isHovered, isTrue);
      expect(hoverChanges, [true]);

      focusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(focusChanges, [true]);
      expect(state!.isFocused, isTrue);

      await mouse.moveTo(const Offset(-100, -100));
      await tester.pump();
      expect(state!.isHovered, isFalse);
      expect(hoverChanges, [true, false]);

      focusNode.unfocus();
      await tester.pump();
      await tester.pump();
      expect(state!.isFocused, isFalse);
      expect(focusChanges, [true, false]);
    });

    testWidgets('effective disabled state controls traversal and cursor', (
      tester,
    ) async {
      const enabledKey = ValueKey('enabled');
      const explicitDisabledKey = ValueKey('explicit-disabled');
      const callbackDisabledKey = ValueKey('callback-disabled');
      const customKey = ValueKey('custom');
      final enabledNode = FocusNode(debugLabel: 'enabled link');
      final explicitDisabledNode = FocusNode(debugLabel: 'explicit disabled');
      final callbackDisabledNode = FocusNode(debugLabel: 'callback disabled');
      final nextNode = FocusNode(debugLabel: 'next');
      addTearDown(enabledNode.dispose);
      addTearDown(explicitDisabledNode.dispose);
      addTearDown(callbackDisabledNode.dispose);
      addTearDown(nextNode.dispose);

      await tester.pumpWidget(
        _testApp(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NakedLink(
                key: explicitDisabledKey,
                enabled: false,
                focusNode: explicitDisabledNode,
                onPressed: () {},
                child: const SizedBox(child: Text('Explicit disabled')),
              ),
              NakedLink(
                key: callbackDisabledKey,
                focusNode: callbackDisabledNode,
                child: const SizedBox(child: Text('Callback disabled')),
              ),
              NakedLink(
                key: enabledKey,
                focusNode: enabledNode,
                onPressed: () {},
                child: const SizedBox(child: Text('Enabled')),
              ),
              NakedLink(
                key: customKey,
                mouseCursor: SystemMouseCursors.help,
                onPressed: () {},
                child: const SizedBox(child: Text('Custom')),
              ),
              TextButton(
                focusNode: nextNode,
                onPressed: () {},
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(enabledNode.hasFocus, isTrue);
      expect(explicitDisabledNode.hasFocus, isFalse);
      expect(callbackDisabledNode.hasFocus, isFalse);

      tester.expectCursor(SystemMouseCursors.click, on: enabledKey);
      tester.expectCursor(SystemMouseCursors.basic, on: explicitDisabledKey);
      tester.expectCursor(SystemMouseCursors.basic, on: callbackDisabledKey);
      tester.expectCursor(SystemMouseCursors.help, on: customKey);
    });

    testWidgets('callback removal immediately disables and clears hover', (
      tester,
    ) async {
      const linkKey = ValueKey('link');
      final focusNode = FocusNode(debugLabel: 'dynamic link');
      addTearDown(focusNode.dispose);
      final hoverChanges = <bool>[];
      var callbackCount = 0;
      VoidCallback? callback = () => callbackCount++;
      NakedLinkState? state;
      late StateSetter rebuild;

      await tester.pumpWidget(
        _testApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NakedLink(
                key: linkKey,
                focusNode: focusNode,
                onPressed: callback,
                onHoverChange: hoverChanges.add,
                builder: (context, value, child) {
                  state = value;
                  return const SizedBox(
                    width: 160,
                    height: 48,
                    child: Text('Link'),
                  );
                },
              );
            },
          ),
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(linkKey)));
      await tester.pump();
      expect(state!.isHovered, isTrue);

      focusNode.requestFocus();
      await tester.pump();
      rebuild(() => callback = null);
      await tester.pump();

      expect(state!.isDisabled, isTrue);
      expect(state!.isHovered, isFalse);
      expect(state!.isPressed, isFalse);
      expect(hoverChanges, [true, false]);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.text('Link'));
      await tester.pump();
      expect(callbackCount, 0);
      tester.expectCursor(SystemMouseCursors.basic, on: linkKey);
    });

    testWidgets(
      'autofocus works and focus-node replacement preserves ownership',
      (tester) async {
        final firstNode = FocusNode(debugLabel: 'first external link');
        final secondNode = FocusNode(debugLabel: 'second external link');
        addTearDown(firstNode.dispose);
        addTearDown(secondNode.dispose);
        var currentNode = firstNode;
        late StateSetter rebuild;

        await tester.pumpWidget(
          _testApp(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return NakedLink(
                  autofocus: true,
                  focusNode: currentNode,
                  onPressed: () {},
                  child: const SizedBox(child: Text('Link')),
                );
              },
            ),
          ),
        );
        await tester.pump();
        expect(firstNode.hasFocus, isTrue);

        rebuild(() => currentNode = secondNode);
        await tester.pump();
        await tester.pump();
        expect(firstNode.hasFocus, isFalse);
        expect(secondNode.hasFocus, isTrue);

        await tester.pumpWidget(const SizedBox.shrink());
        final listener = () {};
        expect(() => firstNode.addListener(listener), returnsNormally);
        firstNode.removeListener(listener);
        expect(() => secondNode.addListener(listener), returnsNormally);
        secondNode.removeListener(listener);
      },
    );
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}
