import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import '../../../lib/naked_ui.dart';

typedef StateScopeWidgetBuilder<T extends NakedState> =
    Widget Function(ValueWidgetBuilder<T> builder);

@isTest
testStateScopeBuilder<T extends NakedState>(
  String description,
  StateScopeWidgetBuilder<T> builder,
) {
  return testWidgets(description, (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: builder((context, state, _) {
          // Verify the scope provides a valid controller with accessible value
          final controller = NakedStateScope.controllerOf(context);
          expect(controller, isA<WidgetStatesController>());
          expect(controller.value, isA<Set<WidgetState>>());
          return SizedBox();
        }),
      ),
    );
  });
}
