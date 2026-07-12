import 'package:flutter_test/flutter_test.dart';

extension AccessibilityGuidelineHelpers on WidgetTester {
  /// Applies the accessibility guidelines that are meaningful for a canonical
  /// styled interactive fixture (briefing §21.6).
  Future<void> expectMeetsAccessibilityGuidelines({
    bool labeledTapTarget = true,
    bool androidTapTarget = true,
    bool iOSTapTarget = true,
    bool textContrast = true,
  }) async {
    final semantics = ensureSemantics();
    try {
      if (labeledTapTarget) {
        await expectLater(this, meetsGuideline(labeledTapTargetGuideline));
      }
      if (androidTapTarget) {
        await expectLater(this, meetsGuideline(androidTapTargetGuideline));
      }
      if (iOSTapTarget) {
        await expectLater(this, meetsGuideline(iOSTapTargetGuideline));
      }
      if (textContrast) {
        await expectLater(this, meetsGuideline(textContrastGuideline));
      }
    } finally {
      semantics.dispose();
    }
  }
}
