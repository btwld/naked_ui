import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/helpers/keyboard_test_helpers.dart';

/// Proof for plan/phases/00-test-harness.md task A6: pumpUntil must fail
/// (not pass, not hang) when its condition is never met, and must return as
/// soon as the condition holds.
void main() {
  testWidgets('pumpUntil returns once the condition holds', (tester) async {
    var done = false;
    await tester.pumpWidget(const SizedBox());
    Timer(const Duration(milliseconds: 200), () => done = true);

    await tester.pumpUntil(() => done);
    expect(done, isTrue);
  });

  testWidgets('pumpUntil fails when the condition is never met', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());

    await expectLater(
      () => tester.pumpUntil(
        () => false,
        timeout: const Duration(milliseconds: 100),
      ),
      throwsA(isA<TestFailure>()),
    );
  });
}
