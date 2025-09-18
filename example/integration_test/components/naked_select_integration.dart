import 'package:example/api/naked_select.0.dart' as select_example;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NakedSelect Integration Tests', () {
    testWidgets('select opens and closes correctly', (tester) async {
      // Use the actual example app
      await tester.pumpWidget(const select_example.MyApp());
      await tester.pump(const Duration(milliseconds: 100));

      final selectFinder = find.byType(NakedSelect<String>);
      expect(selectFinder, findsOneWidget);

      // Initially dropdown should be closed
      expect(find.text('Option 1'), findsNothing);

      // Tap to open dropdown
      await tester.tap(selectFinder);
      await tester.pump();

      // Dropdown should be open now
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);
    });

    testWidgets('single selection mode works correctly', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return NakedSelect<String>(
                  selectedValue: selectedValue,
                  onSelectedValueChanged: (value) =>
                      setState(() => selectedValue = value),
                  overlay: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NakedSelectItem<String>(
                          value: 'Apple',
                          child: Text('Apple'),
                        ),
                        NakedSelectItem<String>(
                          value: 'Banana',
                          child: Text('Banana'),
                        ),
                      ],
                    ),
                  ),
                  child: NakedSelectTrigger(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(selectedValue ?? 'Select an option'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(NakedSelectTrigger));
      await tester.pumpAndSettle();

      // Select an item (use item finder to avoid text ambiguity)
      final itemFinder = find.byType(NakedSelectItem<String>).first;
      expect(itemFinder, findsWidgets);
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      // Verify selection
      expect(selectedValue, 'Apple');
      expect(find.text('Apple'), findsOneWidget); // Should show selected value

      // Dropdown should be closed
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('multiple selection mode works correctly', (tester) async {
      Set<String> selectedValues = {};

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return NakedSelect<String>.multiple(
                  selectedValues: selectedValues,
                  onSelectedValuesChanged: (values) =>
                      setState(() => selectedValues = values),
                  closeOnSelect: false,
                  overlay: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NakedSelectItem<String>(
                          value: 'Apple',
                          child: Text('Apple'),
                        ),
                        NakedSelectItem<String>(
                          value: 'Banana',
                          child: Text('Banana'),
                        ),
                        NakedSelectItem<String>(
                          value: 'Cherry',
                          child: Text('Cherry'),
                        ),
                      ],
                    ),
                  ), // Keep open for multiple selections
                  child: NakedSelectTrigger(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Selected: ${selectedValues.join(', ')}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(NakedSelectTrigger));
      await tester.pumpAndSettle();

      // Select multiple items
      final appleItem = find
          .descendant(
            of: find.byType(NakedSelectItem<String>),
            matching: find.text('Apple'),
          )
          .first;
      await tester.tap(appleItem);
      await tester.pumpAndSettle();
      expect(selectedValues, contains('Apple'));

      final cherryItem = find
          .descendant(
            of: find.byType(NakedSelectItem<String>),
            matching: find.text('Cherry'),
          )
          .first;
      await tester.tap(cherryItem);
      await tester.pumpAndSettle();
      expect(selectedValues, contains('Cherry'));
      expect(selectedValues.length, 2);

      // Dropdown should still be open (closeOnSelect: false)
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('onSelectedValueChanged callback works', (tester) async {
      String? lastSelectedValue;
      int callbackCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedSelect<String>(
              selectedValue: null,
              onSelectedValueChanged: (value) {
                lastSelectedValue = value;
                callbackCount++;
              },
              overlay: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NakedSelectItem<String>(
                      value: 'Test Value',
                      child: Text('Test Value'),
                    ),
                  ],
                ),
              ),
              child: const NakedSelectTrigger(child: Text('Select')),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open and select
      await tester.tap(find.text('Select'));
      await tester.pump();
      await tester.tap(find.text('Test Value'));
      await tester.pump();

      // Verify callback
      expect(lastSelectedValue, 'Test Value');
      expect(callbackCount, 1);
    });

    testWidgets('closeOnSelect behavior works correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedSelect<String>(
              selectedValue: null,
              closeOnSelect: true,
              onSelectedValueChanged: (value) {},
              overlay: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NakedSelectItem<String>(
                      value: 'Option 1',
                      child: Text('Option 1'),
                    ),
                    NakedSelectItem<String>(
                      value: 'Option 2',
                      child: Text('Option 2'),
                    ),
                  ],
                ),
              ),
              child: const NakedSelectTrigger(child: Text('Select')),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.text('Select'));
      await tester.pump();
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);

      // Select an item
      await tester.tap(find.text('Option 1'));
      await tester.pump();

      // Dropdown should be closed (closeOnSelect: true)
      expect(find.text('Option 2'), findsNothing);
    });

    testWidgets('disabled select blocks interactions', (tester) async {
      bool wasCallbackCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: NakedSelect<String>(
              selectedValue: null,
              enabled: false,
              onSelectedValueChanged: (value) => wasCallbackCalled = true,
              overlay: Container(
                padding: const EdgeInsets.all(8),
                child: const Text('Menu Content'),
              ),
              child: const NakedSelectTrigger(child: Text('Disabled Select')),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Try to tap - should not open
      await tester.tap(find.text('Disabled Select'));
      await tester.pump();

      // Menu should not be open
      expect(find.text('Menu Content'), findsNothing);
      expect(wasCallbackCalled, isFalse);
    });

    testWidgets('works with example app interaction', (tester) async {
      // Test the full example with hover states and complex styling
      await tester.pumpWidget(const select_example.MyApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Open dropdown via the trigger
      await tester.tap(find.byType(NakedSelectTrigger));
      await tester.pumpAndSettle();

      // Select an option (disambiguate by selecting the menu item text under NakedSelectItem)
      final option2Item = find
          .descendant(
            of: find.byType(NakedSelectItem<String>),
            matching: find.text('Option 2'),
          )
          .first;
      await tester.tap(option2Item);
      await tester.pumpAndSettle();

      // Dropdown should close and show selected value
      expect(find.text('Option 1'), findsNothing); // Menu closed

      // Test that we can open again and see the selection reflected
      await tester.tap(find.byType(NakedSelectTrigger));
      await tester.pumpAndSettle();

      // Should see all options again (scope to menu items to avoid trigger label)
      expect(
          find.descendant(
              of: find.byType(NakedSelectItem<String>),
              matching: find.text('Option 1')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(NakedSelectItem<String>),
              matching: find.text('Option 2')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(NakedSelectItem<String>),
              matching: find.text('Option 3')),
          findsOneWidget);
    });
  });
}
