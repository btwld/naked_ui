import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

/// Benchmark to measure accordion rebuild performance
///
/// This tests the ACTUAL cost of rebuilds in a real-world scenario.
///
/// Test scenarios:
/// 1. Small accordion (5 items) - typical use case from examples
/// 2. Medium accordion (20 items)
/// 3. Large accordion (100 items) - stress test
///
/// What we measure:
/// - Time to toggle one item
/// - Number of build() calls across all items
/// - Whether the optimization is worth the complexity

void main() {
  /// Tracks how many times build() is called
  int buildCounter = 0;

  Widget createAccordion(int itemCount, NakedAccordionController<int> controller) {
    buildCounter = 0;

    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: NakedAccordionGroup<int>(
            controller: controller,
            child: Column(
              children: List.generate(itemCount, (index) {
                return NakedAccordion<int>(
                  value: index,
                  builder: (context, state) {
                    buildCounter++; // Count rebuilds
                    return Text('Item $index: ${state.isExpanded ? "Open" : "Closed"}');
                  },
                  child: Text('Content $index'),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Benchmark: 5 items (typical example usage)', (tester) async {
    final controller = NakedAccordionController<int>();
    await tester.pumpWidget(createAccordion(5, controller));

    final initialBuilds = buildCounter;
    print('Initial builds for 5 items: $initialBuilds');

    // Toggle item 0
    buildCounter = 0;

    final stopwatch = Stopwatch()..start();
    controller.toggle(0);
    await tester.pump();
    stopwatch.stop();

    print('Toggle time for 5 items: ${stopwatch.elapsedMicroseconds}μs');
    print('Rebuild count: $buildCounter / 5 items');
    print('---');
  });

  testWidgets('Benchmark: 20 items (medium list)', (tester) async {
    final controller = NakedAccordionController<int>();
    await tester.pumpWidget(createAccordion(20, controller));

    final initialBuilds = buildCounter;
    print('Initial builds for 20 items: $initialBuilds');

    buildCounter = 0;

    final stopwatch = Stopwatch()..start();
    controller.toggle(0);
    await tester.pump();
    stopwatch.stop();

    print('Toggle time for 20 items: ${stopwatch.elapsedMicroseconds}μs');
    print('Rebuild count: $buildCounter / 20 items');
    print('---');
  });

  testWidgets('Benchmark: 100 items (stress test)', (tester) async {
    final controller = NakedAccordionController<int>();
    await tester.pumpWidget(createAccordion(100, controller));

    final initialBuilds = buildCounter;
    print('Initial builds for 100 items: $initialBuilds');

    buildCounter = 0;

    final stopwatch = Stopwatch()..start();
    controller.toggle(0);
    await tester.pump();
    stopwatch.stop();

    print('Toggle time for 100 items: ${stopwatch.elapsedMicroseconds}μs');
    print('Rebuild count: $buildCounter / 100 items');
    print('---');
  });
}
