/// Metadata for one reviewed real-target screenshot.
///
/// Artifact names follow `component__scenario__target__theme.png`.
class ScreenshotEvidence {
  ScreenshotEvidence({
    required this.component,
    required this.scenario,
    this.theme = 'reference',
    this.surface = '800x600 logical pixels',
    this.devicePixelRatio = 1,
    this.locale = 'en-US',
    this.direction = 'LTR',
    this.textScale = 1,
    this.animationMode = 'disabled',
  }) {
    _validateSegment('component', component);
    _validateSegment('scenario', scenario);
    _validateSegment('theme', theme);
  }

  final String component;
  final String scenario;
  final String theme;
  final String surface;
  final double devicePixelRatio;
  final String locale;
  final String direction;
  final double textScale;
  final String animationMode;

  String artifactNameFor(String target) {
    _validateSegment('target', target);
    return '${component}__${scenario}__${target}__$theme.png';
  }

  Map<String, Object> manifestEntryFor(String target) => <String, Object>{
    'component': component,
    'scenario': scenario,
    'file': artifactNameFor(target),
    'gitCommit': const String.fromEnvironment(
      'NAKED_UI_GIT_SHA',
      defaultValue: 'local',
    ),
    'flutter': const String.fromEnvironment(
      'NAKED_UI_FLUTTER_VERSION',
      defaultValue: 'local',
    ),
    'target': target,
    'surface': surface,
    'devicePixelRatio': devicePixelRatio,
    'locale': locale,
    'direction': direction,
    'textScale': textScale,
    'animationMode': animationMode,
    // This helper is called only after the scenario assertions pass.
    'testResult': 'pass',
    'reviewer': const String.fromEnvironment(
      'NAKED_UI_SCREENSHOT_REVIEWER',
      defaultValue: 'unreviewed',
    ),
  };

  static void _validateSegment(String field, String value) {
    if (!RegExp(r'^[a-z0-9]+(?:_[a-z0-9]+)*$').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        field,
        'must use lowercase snake_case for stable artifact names',
      );
    }
  }
}
