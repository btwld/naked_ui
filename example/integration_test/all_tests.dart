import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

// Import all integration test files
import 'components/naked_accordion_integration.dart' as accordion_tests;
import 'components/naked_button_integration.dart' as button_tests;
import 'components/naked_checkbox_integration.dart' as checkbox_tests;
import 'components/naked_dialog_integration.dart' as dialog_tests;
import 'components/naked_menu_integration.dart' as menu_tests;
import 'components/naked_popover_integration.dart' as popover_tests;
import 'components/naked_radio_integration.dart' as radio_tests;
import 'components/naked_select_integration.dart' as select_tests;
import 'components/naked_slider_integration.dart' as slider_tests;
import 'components/naked_tabs_integration.dart' as tabs_tests;
import 'components/naked_textfield_integration.dart' as textfield_tests;
import 'components/naked_toggle_integration.dart' as toggle_tests;
import 'components/naked_tooltip_integration.dart' as tooltip_tests;

void main() {
  // Initialize integration test binding and configure timeout
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout =
      const Timeout(Duration(minutes: 30)); // Long timeout for all tests
  // Ensure hover highlights are enabled across all integration tests
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;

  group('All NakedUI Integration Tests', () {
    // Add teardown to help with process termination
    tearDownAll(() async {
      // All integration tests completed, cleaning up...
      await Future.delayed(const Duration(seconds: 2));
      // This helps ensure the test process terminates properly
    });

    // Run all component integration tests
    group('Accordion Tests', accordion_tests.main);
    group('Button Tests', button_tests.main);
    group('Checkbox Tests', checkbox_tests.main);
    group('Dialog Tests', dialog_tests.main);
    group('Menu Tests', menu_tests.main);
    group('Popover Tests', popover_tests.main);
    group('Radio Tests', radio_tests.main);
    group('Select Tests', select_tests.main);
    group('Slider Tests', slider_tests.main);
    group('Tabs Tests', tabs_tests.main);
    group('TextField Tests', textfield_tests.main);
    group('Toggle Tests', toggle_tests.main);
    group('Tooltip Tests', tooltip_tests.main);
  });
}
