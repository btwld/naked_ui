import 'package:flutter/material.dart';

// Import all example widgets

// Dialog Examples
import 'api/naked_dialog.0.dart' as dialog_basic_example;
import 'api/naked_dialog.1.dart' as dialog_animated_example;

// Button Examples
import 'api/naked_button.0.dart' as button_basic_example;
import 'api/naked_button.1.dart' as button_advanced_example;
import 'api/naked_button.2.dart' as button_disabled_example;
import 'api/naked_button.3.dart' as button_builder_example;

// Checkbox Examples
import 'api/naked_checkbox.0.dart' as checkbox_basic_example;
import 'api/naked_checkbox.1.dart' as checkbox_tristate_example;
import 'api/naked_checkbox.2.dart' as checkbox_builder_example;

// Radio Examples
import 'api/naked_radio.0.dart' as radio_basic_example;
import 'api/naked_radio.1.dart' as radio_group_example;

// TextField Examples
import 'api/naked_textfield.1.dart' as textfield_password_example;
import 'api/naked_textfield.2.dart' as textfield_validation_example;
import 'api/naked_textfield.3.dart' as textfield_readonly_example;

// Select Examples
import 'api/naked_select.3.dart' as select_searchable_example;

// Other Components
import 'api/naked_accordion.0.dart' as accordion_example;
import 'api/naked_menu.0.dart' as menu_example;
import 'api/naked_menu.1.dart' as menu_alt_example;
import 'api/naked_select.0.dart' as select_example;
import 'api/naked_select.1.dart' as select_alt1_example;
import 'api/naked_select.2.dart' as select_alt2_example;
import 'api/naked_slider.0.dart' as slider_example;
import 'api/naked_tabs.0.dart' as tabs_example;
import 'api/naked_textfield.0.dart' as textfield_example;
import 'api/naked_tooltip.0.dart' as tooltip_example;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naked UI Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ExampleMenu(),
    );
  }
}

class ExampleMenu extends StatelessWidget {
  const ExampleMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Naked UI Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dialog Section
          _buildSectionHeader('Dialog'),
          _buildExampleTile(
            context,
            'Basic Dialog',
            'Custom styled dialogs with different layouts',
            () => _navigateToExample(
                context, const dialog_basic_example.DialogExample()),
          ),
          _buildExampleTile(
            context,
            'Animated Dialog',
            'Dialogs with custom animations and transitions',
            () => _navigateToExample(
                context, const dialog_animated_example.AnimatedDialogExample()),
          ),
          
          // Button Section
          _buildSectionHeader('Button'),
          _buildExampleTile(
            context,
            'Basic Button',
            'Interactive button with hover, press, and focus states',
            () => _navigateToExample(
                context, const button_basic_example.ButtonExample()),
          ),
          _buildExampleTile(
            context,
            'Advanced Interactions',
            'Long press, double tap, and gesture feedback',
            () => _navigateToExample(
                context, const button_advanced_example.AdvancedButtonExample()),
          ),
          _buildExampleTile(
            context,
            'Disabled States',
            'Accessibility features and disabled state handling',
            () => _navigateToExample(
                context, const button_disabled_example.DisabledButtonExample()),
          ),
          _buildExampleTile(
            context,
            'Builder Pattern',
            'Dynamic styling with custom themes and animations',
            () => _navigateToExample(
                context, const button_builder_example.BuilderPatternExample()),
          ),
          
          // Checkbox Section
          _buildSectionHeader('Checkbox'),
          _buildExampleTile(
            context,
            'Basic Checkbox',
            'Checkbox with custom styling',
            () => _navigateToExample(
                context, const checkbox_basic_example.CheckboxExample()),
          ),
          _buildExampleTile(
            context,
            'Tristate Checkbox',
            'Checkboxes with true, false, and indeterminate states',
            () => _navigateToExample(
                context, const checkbox_tristate_example.TristateCheckboxExample()),
          ),
          _buildExampleTile(
            context,
            'Builder Pattern',
            'Custom styled checkboxes with builder pattern',
            () => _navigateToExample(
                context, const checkbox_builder_example.CheckboxBuilderExample()),
          ),
          
          // Radio Section
          _buildSectionHeader('Radio'),
          _buildExampleTile(
            context,
            'Basic Radio',
            'Radio button component',
            () => _navigateToExample(
                context, const radio_basic_example.RadioExample()),
          ),
          _buildExampleTile(
            context,
            'Radio Groups',
            'Multiple radio groups with validation',
            () => _navigateToExample(
                context, const radio_group_example.RadioGroupExample()),
          ),
          
          // Other Components
          _buildSectionHeader('Other Components'),
          _buildExampleTile(
            context,
            'Select',
            'Select dropdown component',
            () => _navigateToExample(
                context, const select_example.SelectExample()),
          ),
          _buildExampleTile(
            context,
            'Select (Alternative 1)',
            'Alternative select implementation',
            () => _navigateToExample(
                context, const select_alt1_example.AnimatedSelectExample()),
          ),
          _buildExampleTile(
            context,
            'Select (Alternative 2)',
            'Another select implementation',
            () => _navigateToExample(context,
                const select_alt2_example.AnimatedMultiSelectExample()),
          ),
          _buildExampleTile(
            context,
            'Searchable Select',
            'Select with search functionality and highlighting',
            () => _navigateToExample(
                context, const select_searchable_example.SearchableSelectExample()),
          ),
          // Tabs Section
          _buildSectionHeader('Tabs'),
          _buildExampleTile(
            context,
            'Basic Tabs',
            'Simple tab navigation component',
            () => _navigateToExample(context, const tabs_example.TabsExample()),
          ),
          // Slider Section
          _buildSectionHeader('Slider'),
          _buildExampleTile(
            context,
            'Slider',
            'Slider component for value selection',
            () => _navigateToExample(
                context, const slider_example.SliderExample()),
          ),

          // TextField Section
          _buildSectionHeader('TextField'),
          _buildExampleTile(
            context,
            'Basic TextField',
            'Text input component with basic styling',
            () => _navigateToExample(
                context, const textfield_example.TextFieldExample()),
          ),
          _buildExampleTile(
            context,
            'Password Fields',
            'Password input with visibility toggle and multi-line text',
            () => _navigateToExample(
                context, const textfield_password_example.PasswordAndMultiLineExample()),
          ),
          _buildExampleTile(
            context,
            'Form Validation',
            'Input validation with custom formatters and error states',
            () => _navigateToExample(
                context, const textfield_validation_example.ValidationExample()),
          ),
          _buildExampleTile(
            context,
            'Read-Only & Submission',
            'Read-only modes and form submission handling',
            () => _navigateToExample(
                context, const textfield_readonly_example.ReadOnlySubmissionExample()),
          ),
          
          // Other Components
          _buildSectionHeader('Other Components'),
          _buildExampleTile(
            context,
            'Accordion',
            'Expandable accordion component',
            () => _navigateToExample(
                context, const accordion_example.AccordionExample()),
          ),
          _buildExampleTile(
            context,
            'Menu',
            'Dropdown menu component',
            () => _navigateToExample(context, const menu_example.MenuExample()),
          ),
          _buildExampleTile(
            context,
            'Menu (Alternative)',
            'Alternative menu implementation',
            () => _navigateToExample(
                context, const menu_alt_example.AnimatedMenuExample()),
          ),
          _buildExampleTile(
            context,
            'Tooltip',
            'Tooltip component for additional information',
            () => _navigateToExample(
                context, const tooltip_example.TooltipExample()),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildExampleTile(
    BuildContext context,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _navigateToExample(BuildContext context, Widget example) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Example'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Center(child: example),
        ),
      ),
    );
  }
}
