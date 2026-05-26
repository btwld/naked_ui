import 'package:example/main.dart';
import 'package:example/registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('semantics playground is registered and renders labels', (
    WidgetTester tester,
  ) async {
    final demo = DemoRegistry.find('semantics-playground');

    expect(demo, isNotNull);

    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextField), 'semantics');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semantics - Playground'));
    await tester.pumpAndSettle();

    expect(find.text('Default semantics'), findsWidgets);
    expect(find.text('Override semantics'), findsWidgets);
    expect(find.text('Default menu'), findsOneWidget);
    expect(find.text('Visual menu'), findsOneWidget);
    expect(find.text('Default accordion'), findsOneWidget);
    expect(find.text('Visual accordion'), findsOneWidget);
  });
}
