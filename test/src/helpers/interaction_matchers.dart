import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matchers for interaction-related widgets.
class InteractionMatchers {
  InteractionMatchers._();

  /// Succeeds when the provided Focus widget currently has focus.
  static final Matcher hasFocus = _HasFocusMatcher();
}

class _HasFocusMatcher extends Matcher {
  @override
  Description describe(Description description) =>
      description.add('a Focus widget with focusNode.hasFocus == true');

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! Focus) return false;
    final FocusNode? node = item.focusNode;
    return node?.hasFocus == true;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! Focus) {
      return mismatchDescription.add('is not a Focus widget');
    }
    final node = item.focusNode;
    return mismatchDescription.add(
      'had focusNode.hasFocus == ${node?.hasFocus}, focusNode: ${node?.debugLabel ?? 'unnamed'}',
    );
  }
}

