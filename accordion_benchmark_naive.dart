import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Benchmark WITHOUT optimization - simulates naive rebuild behavior
/// (similar to Material's ExpansionPanelList or the old accordion implementation)
///
/// This rebuilds ALL items when ANY item is toggled.

void main() {
  int buildCounter = 0;

  Widget createNaiveAccordion(
    int itemCount,
    ValueNotifier<Set<int>> expandedNotifier,
  ) {
    buildCounter = 0;

    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ValueListenableBuilder<Set<int>>(
            valueListenable: expandedNotifier,
            builder: (context, expandedValues, _) {
              // ALL items rebuild when any state changes
              return Column(
                children: List.generate(itemCount, (index) {
                  buildCounter++; // Count rebuilds
                  final isExpanded = expandedValues.contains(index);
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final newSet = Set<int>.from(expandedValues);
                          if (isExpanded) {
                            newSet.remove(index);
                          } else {
                            newSet.add(index);
                          }
                          expandedNotifier.value = newSet;
                        },
                        child: Text('Item $index: ${isExpanded ? "Open" : "Closed"}'),
                      ),
                      if (isExpanded) Text('Content $index'),
                    ],
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('Naive: 5 items (typical example usage)', (tester) async {
    final expandedNotifier = ValueNotifier<Set<int>>({});
    await tester.pumpWidget(createNaiveAccordion(5, expandedNotifier));

    final initialBuilds = buildCounter;
    print('Initial builds for 5 items: $initialBuilds');

    buildCounter = 0;

    final stopwatch = Stopwatch()..start();
    final newSet = Set<int>.from(expandedNotifier.value);
    newSet.add(0);
    expandedNotifier.value = newSet;
    await tester.pump();
    stopwatch.stop();

    print('Toggle time for 5 items: ${stopwatch.elapsedMicroseconds}μs');
    print('Rebuild count: $buildCounter / 5 items');
    print('---');
  });

  testWidgets('Naive: 20 items (medium list)', (tester) async {
    final expandedNotifier = ValueNotifier<Set<int>>({});
    await tester.pumpWidget(createNaiveAccordion(20, expandedNotifier));

    final initialBuilds = buildCounter;
    print('Initial builds for 20 items: $initialBuilds');

    buildCounter = 0;

    final stopwatch = Stopwatch()..start();
    final newSet = Set<int>.from(expandedNotifier.value);
    newSet.add(0);
    expandedNotifier.value = newSet;
    await tester.pump();
    stopwatch.stop();

    print('Toggle time for 20 items: ${stopwatch.elapsedMicroseconds}μs');
    print('Rebuild count: $buildCounter / 20 items');
    print('---');
  });

  testWidgets('Naive: 100 items (stress test)', (tester) async {
    final expandedNotifier = ValueNotifier<Set<int>>({});
    await tester.pumpWidget(createNaiveAccordion(100, expandedNotifier));

    final initialBuilds = buildCounter;
    print('Initial builds for 100 items: $initialBuilds');

    buildCounter = 0;

    final stopwatch = Stopwatch()..start();
    final newSet = Set<int>.from(expandedNotifier.value);
    newSet.add(0);
    expandedNotifier.value = newSet;
    await tester.pump();
    stopwatch.stop();

    print('Toggle time for 100 items: ${stopwatch.elapsedMicroseconds}μs');
    print('Rebuild count: $buildCounter / 100 items');
    print('---');
  });
}
