import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension FocusTestHelpers on WidgetTester {
  /// Create a managed focus node that gets automatically disposed
  FocusNode createManagedFocusNode() {
    final focusNode = FocusNode();
    addTearDown(() => focusNode.dispose());
    return focusNode;
  }
}