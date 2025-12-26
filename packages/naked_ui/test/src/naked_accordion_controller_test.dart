import 'package:flutter_test/flutter_test.dart';
import '../../lib/naked_ui.dart';

void main() {
  group('NakedAccordionController', () {
    group('initialization', () {
      test('starts with empty values', () {
        final controller = NakedAccordionController<String>();
        expect(controller.values, isEmpty);
        expect(controller.min, 0);
        expect(controller.max, isNull);
      });

      test('accepts min and max constraints', () {
        final controller = NakedAccordionController<String>(min: 1, max: 3);
        expect(controller.min, 1);
        expect(controller.max, 3);
      });

      test('throws assertion error when min < 0', () {
        expect(
          () => NakedAccordionController<String>(min: -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error when max < min', () {
        expect(
          () => NakedAccordionController<String>(min: 3, max: 2),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('contains', () {
      test('returns false for non-existent value', () {
        final controller = NakedAccordionController<String>();
        expect(controller.contains('item1'), isFalse);
      });

      test('returns true for existing value', () {
        final controller = NakedAccordionController<String>();
        controller.open('item1');
        expect(controller.contains('item1'), isTrue);
      });
    });

    group('open', () {
      test('adds value to expanded set', () {
        final controller = NakedAccordionController<String>();
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.open('item1');

        expect(controller.contains('item1'), isTrue);
        expect(notifyCount, 1);
      });

      test('is no-op when value already exists', () {
        final controller = NakedAccordionController<String>();
        controller.open('item1');

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.open('item1');

        expect(notifyCount, 0, reason: 'should not notify when no change');
      });

      test('evicts oldest entry when max is reached', () {
        final controller = NakedAccordionController<String>(max: 2);
        controller.open('item1');
        controller.open('item2');

        expect(controller.values.toList(), ['item1', 'item2']);

        controller.open('item3');

        expect(controller.contains('item1'), isFalse, reason: 'oldest evicted');
        expect(controller.contains('item2'), isTrue);
        expect(controller.contains('item3'), isTrue);
        expect(controller.values.length, 2);
      });

      test('does nothing when max is 0', () {
        final controller = NakedAccordionController<String>(max: 0);
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.open('item1');

        expect(controller.values, isEmpty);
        expect(notifyCount, 0);
      });
    });

    group('close', () {
      test('removes value from expanded set', () {
        final controller = NakedAccordionController<String>();
        controller.open('item1');

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.close('item1');

        expect(controller.contains('item1'), isFalse);
        expect(notifyCount, 1);
      });

      test('is no-op when value does not exist', () {
        final controller = NakedAccordionController<String>();

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.close('nonexistent');

        expect(notifyCount, 0);
      });

      test('respects min floor and does not close', () {
        final controller = NakedAccordionController<String>(min: 1);
        controller.open('item1');

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.close('item1');

        expect(controller.contains('item1'), isTrue, reason: 'min floor enforced');
        expect(notifyCount, 0, reason: 'no notification when nothing changes');
      });

      test('allows close when above min floor', () {
        final controller = NakedAccordionController<String>(min: 1);
        controller.open('item1');
        controller.open('item2');

        controller.close('item2');

        expect(controller.contains('item1'), isTrue);
        expect(controller.contains('item2'), isFalse);
        expect(controller.values.length, 1);
      });
    });

    group('toggle', () {
      test('opens when closed', () {
        final controller = NakedAccordionController<String>();
        controller.toggle('item1');

        expect(controller.contains('item1'), isTrue);
      });

      test('closes when open', () {
        final controller = NakedAccordionController<String>();
        controller.open('item1');
        controller.toggle('item1');

        expect(controller.contains('item1'), isFalse);
      });

      test('respects min when closing', () {
        final controller = NakedAccordionController<String>(min: 1);
        controller.open('item1');
        controller.toggle('item1');

        expect(controller.contains('item1'), isTrue, reason: 'toggle respects min');
      });

      test('respects max when opening (evicts oldest)', () {
        final controller = NakedAccordionController<String>(max: 1);
        controller.open('item1');
        controller.toggle('item2');

        expect(controller.contains('item1'), isFalse);
        expect(controller.contains('item2'), isTrue);
      });
    });

    group('clear', () {
      test('removes all items when min is 0', () {
        final controller = NakedAccordionController<String>();
        controller.open('item1');
        controller.open('item2');
        controller.open('item3');

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.clear();

        expect(controller.values, isEmpty);
        expect(notifyCount, 1);
      });

      test('is no-op when already empty', () {
        final controller = NakedAccordionController<String>();

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.clear();

        expect(notifyCount, 0);
      });

      test('preserves first min entries', () {
        final controller = NakedAccordionController<String>(min: 2);
        controller.open('item1');
        controller.open('item2');
        controller.open('item3');
        controller.open('item4');

        controller.clear();

        expect(controller.values.length, 2);
        expect(controller.values.toList(), ['item1', 'item2']);
      });

      test('is no-op when at or below min', () {
        final controller = NakedAccordionController<String>(min: 2);
        controller.open('item1');
        controller.open('item2');

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.clear();

        expect(controller.values.length, 2);
        expect(notifyCount, 0);
      });
    });

    group('openAll', () {
      test('opens multiple items', () {
        final controller = NakedAccordionController<String>();

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.openAll(['item1', 'item2', 'item3']);

        expect(controller.values.toList(), ['item1', 'item2', 'item3']);
        expect(notifyCount, 1, reason: 'single notification for batch');
      });

      test('skips already open items', () {
        final controller = NakedAccordionController<String>();
        controller.open('item1');

        controller.openAll(['item1', 'item2']);

        expect(controller.values.toList(), ['item1', 'item2']);
      });

      test('respects max and evicts oldest', () {
        final controller = NakedAccordionController<String>(max: 2);

        controller.openAll(['item1', 'item2', 'item3']);

        // Only last 2 should remain (evicted item1, then item2 when item3 added)
        expect(controller.values.length, 2);
        expect(controller.contains('item2'), isTrue);
        expect(controller.contains('item3'), isTrue);
      });

      test('does nothing when max is 0', () {
        final controller = NakedAccordionController<String>(max: 0);

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.openAll(['item1', 'item2']);

        expect(controller.values, isEmpty);
        expect(notifyCount, 0);
      });

      test('is no-op when all items already open', () {
        final controller = NakedAccordionController<String>();
        controller.openAll(['item1', 'item2']);

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.openAll(['item1', 'item2']);

        expect(notifyCount, 0);
      });
    });

    group('replaceAll', () {
      test('replaces all values', () {
        final controller = NakedAccordionController<String>();
        controller.open('old1');
        controller.open('old2');

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.replaceAll(['new1', 'new2']);

        expect(controller.contains('old1'), isFalse);
        expect(controller.contains('old2'), isFalse);
        expect(controller.values.toList(), ['new1', 'new2']);
        expect(notifyCount, 1);
      });

      test('respects max constraint', () {
        final controller = NakedAccordionController<String>(max: 2);

        controller.replaceAll(['item1', 'item2', 'item3', 'item4']);

        expect(controller.values.length, 2);
        expect(controller.values.toList(), ['item1', 'item2']);
      });

      test('is no-op when values are identical', () {
        final controller = NakedAccordionController<String>();
        controller.open('item1');
        controller.open('item2');

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.replaceAll(['item1', 'item2']);

        expect(notifyCount, 0, reason: 'no notification when no change');
      });

      test('can produce fewer than min items (programmatic update)', () {
        final controller = NakedAccordionController<String>(min: 2);
        controller.openAll(['item1', 'item2', 'item3']);

        controller.replaceAll(['single']);

        expect(controller.values.length, 1);
        expect(controller.values.toList(), ['single']);
      });
    });

    group('FIFO ordering', () {
      test('maintains insertion order', () {
        final controller = NakedAccordionController<String>();
        controller.open('first');
        controller.open('second');
        controller.open('third');

        expect(controller.values.toList(), ['first', 'second', 'third']);
      });

      test('evicts in FIFO order when at max', () {
        final controller = NakedAccordionController<String>(max: 3);
        controller.open('a');
        controller.open('b');
        controller.open('c');

        controller.open('d');
        expect(controller.values.toList(), ['b', 'c', 'd']);

        controller.open('e');
        expect(controller.values.toList(), ['c', 'd', 'e']);
      });
    });

    group('notification behavior', () {
      test('notifies exactly once per state change', () {
        final controller = NakedAccordionController<String>();
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.open('item1');
        expect(notifyCount, 1);

        controller.open('item2');
        expect(notifyCount, 2);

        controller.close('item1');
        expect(notifyCount, 3);

        controller.toggle('item2');
        expect(notifyCount, 4);
      });

      test('removeListener stops notifications', () {
        final controller = NakedAccordionController<String>();
        var notifyCount = 0;
        void listener() => notifyCount++;

        controller.addListener(listener);
        controller.open('item1');
        expect(notifyCount, 1);

        controller.removeListener(listener);
        controller.open('item2');
        expect(notifyCount, 1, reason: 'listener removed');
      });
    });
  });
}
