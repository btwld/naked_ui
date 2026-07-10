import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('catalog loads', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Naked Kitchen Sink'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('fullscreen action opens a component route', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('Open fullscreen'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('source action confirms that the URL was copied', (tester) async {
    MethodCall? platformCall;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCall = call;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('Copy source URL'));
    await tester.pump();

    expect(platformCall?.method, 'Clipboard.setData');
    expect(find.text('Source URL copied'), findsOneWidget);
  });
}
