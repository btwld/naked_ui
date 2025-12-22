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
    bool scopeVerified = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: builder((context, state, _) {
          // Verify that NakedStateScope provides both state and controller
          expect(state, isNotNull, reason: 'State should be provided via scope');
          expect(
            NakedStateScope.controllerOf(context),
            isNotNull,
            reason: 'Controller should be accessible via scope',
          );
          scopeVerified = true;
          return SizedBox();
        }),
      ),
    );
    expect(scopeVerified, isTrue, reason: 'Builder should have been called');
  });
}
