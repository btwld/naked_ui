import 'package:flutter/material.dart';

// Import all example widgets
import 'api/naked_accordion.0.dart' as accordion_example;
import 'api/naked_button.0.dart' as button_example;
import 'api/naked_checkbox.0.dart' as checkbox_example;
import 'api/naked_menu.0.dart' as menu_example;
import 'api/naked_menu.1.dart' as menu_alt_example;
import 'api/naked_radio.0.dart' as radio_example;
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
          _buildExampleTile(
            context,
            'Button',
            'Interactive button with hover, press, and focus states',
            () => _navigateToExample(
                context, const button_example.ButtonExample()),
          ),
          _buildExampleTile(
            context,
            'Accordion',
            'Expandable accordion component',
            () => _navigateToExample(
                context, const accordion_example.AccordionExample()),
          ),
          _buildExampleTile(
            context,
            'Checkbox',
            'Checkbox with custom styling',
            () => _navigateToExample(
                context, const checkbox_example.CheckboxExample()),
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
            'Radio',
            'Radio button component',
            () =>
                _navigateToExample(context, const radio_example.RadioExample()),
          ),
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
            'Slider',
            'Slider component for value selection',
            () => _navigateToExample(
                context, const slider_example.SliderExample()),
          ),
          _buildExampleTile(
            context,
            'Tabs',
            'Tab navigation component',
            () => _navigateToExample(context, const tabs_example.TabsExample()),
          ),
          _buildExampleTile(
            context,
            'TextField',
            'Text input component',
            () => _navigateToExample(
                context, const textfield_example.TextFieldExample()),
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
