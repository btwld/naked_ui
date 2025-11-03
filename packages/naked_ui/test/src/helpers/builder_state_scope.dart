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
          NakedStateScope.controllerOf(context).value;
          return SizedBox();
        }),
      ),
    );
  });
}
