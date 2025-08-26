import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tries to find any Semantics node under [scope] that matches [expectation].
/// This avoids brittleness due to wrapper nodes (e.g., routes/containers).
Future<void> expectAnySemanticsMatching(
  WidgetTester tester,
  Finder scope,
  Matcher expectation,
) async {
  final candidates = _collectSemanticsCandidates(scope);

  TestFailure? lastFailure;
  for (final e in candidates) {
    try {
      expect(
        tester.getSemantics(find.byElementPredicate((el) => el == e)),
        expectation,
      );
      return; // Success on first match
    } on TestFailure catch (err) {
      lastFailure = err;
      continue;
    }
  }

  if (lastFailure != null) {
    // ignore: only_throw_errors
    throw TestFailure(
      '${lastFailure.message}\nNo Semantics under scope matched. Candidates: ${candidates.length}',
    );
  } else {
    // ignore: only_throw_errors
    throw TestFailure('No candidates found under scope to evaluate semantics.');
  }
}

List<Element> _collectSemanticsCandidates(Finder scope) {
  final possibilities = <Finder>[
    scope,
    find.descendant(of: scope, matching: find.byType(Semantics)),
  ];
  final List<Element> candidates = <Element>[];
  for (final f in possibilities) {
    candidates.addAll(f.evaluate());
  }
  return candidates;
}

/// Succeeds if any of [expectations] matches at least one Semantics node
/// under [scope]. Throws a TestFailure if none match.
Future<void> expectAnyOfSemantics(
  WidgetTester tester,
  Finder scope,
  List<Matcher> expectations,
) async {
  TestFailure? last;
  for (final m in expectations) {
    try {
      await expectAnySemanticsMatching(tester, scope, m);
      return;
    } on TestFailure catch (e) {
      last = e;
      continue;
    }
  }
  // ignore: only_throw_errors
  throw TestFailure(
    'None of the expectations matched. Last error: ${last?.message}',
  );
}