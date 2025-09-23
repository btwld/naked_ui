import 'package:flutter/widgets.dart';

// Accordion
import 'api/naked_accordion.0.dart' as accordion_example;
// Button
import 'api/naked_button.0.dart' as button_basic_example;
// Checkbox
import 'api/naked_checkbox.0.dart' as checkbox_basic_example;
// Dialog
import 'api/naked_dialog.0.dart' as dialog_basic_example;
// Menu
import 'api/naked_menu.0.dart' as menu_example;
// Popover
import 'api/naked_popover.0.dart' as popover_example;
// Radio
import 'api/naked_radio.0.dart' as radio_basic_example;
// Select
import 'api/naked_select.0.dart' as select_example;
import 'api/naked_select.1.dart' as select_checkmark_example;
import 'api/naked_select.2.dart' as select_cyberpunk_example;
// Slider
import 'api/naked_slider.0.dart' as slider_example;
// Tabs
import 'api/naked_tabs.0.dart' as tabs_example;
// TextField
import 'api/naked_textfield.0.dart' as textfield_example;
// Toggle
import 'api/naked_toggle.0.dart' as toggle_example;
// Tooltip
import 'api/naked_tooltip.0.dart' as tooltip_example;

class Demo {
  final String id; // slug used in routes
  final String title;
  final String category;
  final WidgetBuilder builder;
  final String? sourceUrl;
  final List<String> tags;

  const Demo({
    required this.id,
    required this.title,
    required this.category,
    required this.builder,
    this.sourceUrl,
    this.tags = const [],
  });
}

class DemoRegistry {
  static final List<Demo> demos = <Demo>[
    Demo(
      id: 'button-basic',
      title: 'Button – Basic',
      category: 'Button',
      builder: (_) => const button_basic_example.ButtonExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_button.0.dart',
      tags: ['button'],
    ),
    Demo(
      id: 'checkbox-basic',
      title: 'Checkbox – Basic',
      category: 'Checkbox',
      builder: (_) => const checkbox_basic_example.CheckboxExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_checkbox.0.dart',
      tags: ['checkbox'],
    ),
    Demo(
      id: 'radio-basic',
      title: 'Radio – Basic',
      category: 'Radio',
      builder: (_) => const radio_basic_example.RadioExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_radio.0.dart',
      tags: ['radio'],
    ),
    Demo(
      id: 'select-basic',
      title: 'Select – Basic',
      category: 'Select',
      builder: (_) => const select_example.SimpleSelectExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_select.0.dart',
      tags: ['select'],
    ),
    Demo(
      id: 'select-checkmark',
      title: 'Select – Checkmark',
      category: 'Select',
      builder: (_) => const select_checkmark_example.CheckmarkSelectExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_select.1.dart',
      tags: ['select', 'checkmark'],
    ),
    Demo(
      id: 'select-cyberpunk',
      title: 'Select – Cyberpunk',
      category: 'Select',
      builder: (_) =>
          const select_cyberpunk_example.CyberpunkSelectExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_select.2.dart',
      tags: ['select', 'cyberpunk', 'glow'],
    ),
    Demo(
      id: 'tabs-basic',
      title: 'Tabs – Basic',
      category: 'Tabs',
      builder: (_) => const tabs_example.TabsExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_tabs.0.dart',
      tags: ['tabs'],
    ),
    Demo(
      id: 'slider-basic',
      title: 'Slider – Basic',
      category: 'Slider',
      builder: (_) => const slider_example.SliderExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_slider.0.dart',
      tags: ['slider'],
    ),
    Demo(
      id: 'textfield-basic',
      title: 'TextField – Basic',
      category: 'TextField',
      builder: (_) => const textfield_example.TextFieldExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_textfield.0.dart',
      tags: ['textfield'],
    ),
    Demo(
      id: 'menu-basic',
      title: 'Menu – Basic',
      category: 'Menu',
      builder: (_) => const menu_example.SimpleMenuExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_menu.0.dart',
      tags: ['menu'],
    ),
    Demo(
      id: 'accordion-basic',
      title: 'Accordion – Basic',
      category: 'Accordion',
      builder: (_) => const accordion_example.AccordionExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_accordion.0.dart',
      tags: ['accordion'],
    ),
    Demo(
      id: 'tooltip-basic',
      title: 'Tooltip – Basic',
      category: 'Tooltip',
      builder: (_) => const tooltip_example.TooltipExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_tooltip.0.dart',
      tags: ['tooltip'],
    ),
    Demo(
      id: 'dialog-basic',
      title: 'Dialog – Basic',
      category: 'Dialog',
      builder: (_) => const dialog_basic_example.DialogExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_dialog.0.dart',
      tags: ['dialog'],
    ),
    Demo(
      id: 'popover-basic',
      title: 'Popover – Basic',
      category: 'Popover',
      builder: (_) => const popover_example.BasicPopoverExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_popover.0.dart',
      tags: ['popover'],
    ),
    Demo(
      id: 'toggle-basic',
      title: 'Toggle – Basic',
      category: 'Toggle',
      builder: (_) => const toggle_example.ToggleButtonExample(),
      sourceUrl:
          'https://github.com/btwld/naked_ui/blob/main/example/lib/api/naked_toggle.0.dart',
      tags: ['toggle'],
    ),
  ];

  static Demo? find(String id) {
    try {
      return demos.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  static Map<String, List<Demo>> byCategory() {
    final map = <String, List<Demo>>{};
    for (final d in demos) {
      map.putIfAbsent(d.category, () => <Demo>[]).add(d);
    }
    return map;
  }
}
