import 'package:example/src/testing/screenshot_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('screenshot evidence uses stable artifact names and full manifest', () {
    final evidence = ScreenshotEvidence(
      component: 'dialog',
      scenario: 'open_focused',
    );

    expect(
      evidence.artifactNameFor('macos'),
      'dialog__open_focused__macos__reference.png',
    );
    expect(evidence.manifestEntryFor('macos'), <String, Object>{
      'component': 'dialog',
      'scenario': 'open_focused',
      'file': 'dialog__open_focused__macos__reference.png',
      'gitCommit': 'local',
      'flutter': 'local',
      'target': 'macos',
      'surface': '800x600 logical pixels',
      'devicePixelRatio': 1.0,
      'locale': 'en-US',
      'direction': 'LTR',
      'textScale': 1.0,
      'animationMode': 'disabled',
      'testResult': 'pass',
      'reviewer': 'unreviewed',
    });
  });

  test('screenshot evidence rejects unstable artifact segments', () {
    expect(
      () => ScreenshotEvidence(component: 'Alert Dialog', scenario: 'open'),
      throwsArgumentError,
    );
  });
}
