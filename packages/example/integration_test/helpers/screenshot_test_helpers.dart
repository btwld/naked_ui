import 'package:example/src/testing/screenshot_evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'screenshot_environment.dart';

const bool _screenshotsEnabled = bool.fromEnvironment(
  'NAKED_UI_CAPTURE_SCREENSHOTS',
);

extension ScreenshotTestHelpers on WidgetTester {
  /// Captures a screenshot and registers its manifest entry.
  ///
  /// Capture is opt-in through `NAKED_UI_CAPTURE_SCREENSHOTS=true`, allowing
  /// ordinary behavior runs to remain fast. Call this only after all
  /// deterministic state and focus assertions for the scenario.
  Future<void> captureEvidenceScreenshot(
    IntegrationTestWidgetsFlutterBinding binding,
    ScreenshotEvidence evidence, {
    Finder? surface,
  }) async {
    if (!_screenshotsEnabled) return;

    await prepareScreenshotSurface(binding, this);
    // LiveTestWidgetsFlutterBinding paints test pointers for two post-up
    // frames. Paint once to expire the record, then once more to capture the
    // clean state. These are deterministic zero-duration frames, not timing
    // padding.
    await pump();
    await pump();

    final target = screenshotTarget;
    final artifactName = evidence.artifactNameFor(target);
    final screenshotName = artifactName.substring(
      0,
      artifactName.length - '.png'.length,
    );
    final bytes = await takePlatformScreenshot(
      binding,
      this,
      screenshotName,
      surface: surface,
    );
    if (screenshotReturnsBytes) {
      expect(
        bytes,
        isNotEmpty,
        reason: 'the $target screenshot must contain PNG bytes',
      );
    }

    binding.reportData ??= <String, dynamic>{};
    final manifest =
        binding.reportData!.putIfAbsent(
              'screenshotManifest',
              () => <Map<String, Object>>[],
            )
            as List<dynamic>;
    manifest.add(evidence.manifestEntryFor(target));
  }
}
