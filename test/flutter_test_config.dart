import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global Flutter test configuration.
///
/// Force traditional highlight so FocusableActionDetector emits
/// onShowHoverHighlight for mouse hover in all widget tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  await testMain();
}

