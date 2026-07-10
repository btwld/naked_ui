import 'package:example/registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo identifiers and source links are consistent', () {
    final demos = DemoRegistry.demos;
    final ids = demos.map((demo) => demo.id).toSet();

    expect(ids, hasLength(demos.length));
    expect(() => demos.clear(), throwsUnsupportedError);
    expect(ids, contains('tooltip-basic'));
    expect(DemoRegistry.find('missing'), isNull);

    for (final demo in demos) {
      expect(demo.id, isNotEmpty);
      expect(demo.title, isNotEmpty);
      expect(demo.category, isNotEmpty);
      expect(
        demo.sourceUrl,
        contains('/packages/example/lib/api/'),
        reason: 'Stale source link for ${demo.id}',
      );
    }

    expect(
      DemoRegistry.find('select-checkmark')!.sourceUrl,
      endsWith('/naked_select.2.dart'),
    );
    expect(
      DemoRegistry.find('select-cyberpunk')!.sourceUrl,
      endsWith('/naked_select.1.dart'),
    );
  });
}
