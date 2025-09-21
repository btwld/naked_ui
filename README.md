# Naked UI

Headless Flutter components that focus on behaviour, accessibility, and interaction states while leaving every pixel of design to you.

## Key Features

- **Zero styling** – bring your own widgets, animations, and design system
- **Accessible by default** – correct semantics, keyboard navigation, and focus management
- **Typed builder state** – snapshot objects surface hover/focus/pressed/selected flags without manual bookkeeping
- **Composable** – each component is a tiny primitive you can mix and match

## Supported Components

- NakedButton – interaction surface with hover/focus/press callbacks
- NakedCheckbox – boolean/tristate checkboxes
- NakedRadio + RadioGroup – exclusive selection sets
- NakedSelect – dropdown/select menus with overlay positioning
- NakedSlider – value slider with drag + keyboard support
- NakedToggle + NakedToggleGroup – toggle buttons and switches
- NakedTabs – tab triggers + panels with roving focus
- NakedAccordion – expandable sections managed by a controller
- NakedMenu – anchored action menus
- NakedDialog + showNakedDialog – modal routes without visuals
- NakedTooltip – hover/focus tooltips with timers
- NakedPopover – anchored overlays you control entirely
- NakedTextField – builder-first EditableText wrapper

## Getting Started

### Installation

```yaml
dependencies:
  naked_ui: ^latest_version  # https://pub.dev/packages/naked_ui
```

```bash
flutter pub get
```

### Import

```dart
import 'package:naked_ui/naked_ui.dart';
```

### Usage Pattern

1. Build your custom visuals using standard Flutter widgets
2. Wrap the visuals in the corresponding Naked component
3. React to typed state callbacks or use the builder snapshot to style interaction states

---

## Component Cheat Sheet

Each snippet shows the essence of using a component inside a `StatefulWidget`. Replace the state fields with whatever fits your architecture.

### NakedButton

```dart
NakedButton(
  onPressed: () => debugPrint('Pressed'),
  builder: (context, states, _) {
    final bool pressed = states.contains(WidgetState.pressed);
    final bool hovered = states.contains(WidgetState.hovered);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: pressed
            ? Colors.blue.shade700
            : hovered
                ? Colors.blue.shade500
                : Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Button', style: TextStyle(color: Colors.white)),
    );
  },
);
```

### NakedCheckbox

```dart
bool checked = false;

NakedCheckbox(
  value: checked,
  onChanged: (next) => setState(() => checked = next ?? false),
  builder: (context, checkboxState, _) => Icon(
    checkboxState.isChecked == true
        ? Icons.check_box
        : Icons.check_box_outline_blank,
    color: checkboxState.isHovered ? Colors.blue : Colors.grey.shade700,
  ),
);
```

### NakedRadio + RadioGroup

```dart
RadioGroup<String>(
  groupValue: selected,
  onChanged: (next) => setState(() => selected = next!),
  child: Row(
    children: ['A', 'B'].map((label) {
      return NakedRadio<String>(
        value: label,
        builder: (context, radioState, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: radioState.isSelected ? Colors.blue : Colors.white,
            border: Border.all(
              color: radioState.isHovered ? Colors.blue : Colors.grey.shade400,
              width: radioState.isPressed ? 4 : 2,
            ),
          ),
        ),
      );
    }).toList(),
  ),
);
```

### NakedSelect

```dart
NakedSelect<String>(
  value: fruit,
  onChanged: (value) => setState(() => fruit = value),
  triggerBuilder: (context, selectState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(selectState.value ?? 'Pick fruit'),
        Icon(selectState.isOpen ? Icons.expand_less : Icons.expand_more),
      ],
    );
  },
  overlayBuilder: (context, info) => Column(
    mainAxisSize: MainAxisSize.min,
    children: ['Apple', 'Banana', 'Mango']
        .map((label) => NakedSelect.Option<String>(
              value: label.toLowerCase(),
              builder: (context, optionState, _) => ListTile(
                title: Text(label),
                trailing: optionState.isCurrentSelection
                    ? const Icon(Icons.check)
                    : null,
              ),
            ))
        .toList(),
  ),
);
```

### NakedSlider

```dart
NakedSlider(
  value: sliderValue,
  onChanged: (value) => setState(() => sliderValue = value),
  child: LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        Container(
          width: double.infinity,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Positioned(
          left: sliderValue * constraints.maxWidth - 12,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    ),
  ),
);
```

### NakedToggle & switch semantics

```dart
NakedToggle(
  value: isOn,
  asSwitch: true,
  onChanged: (value) => setState(() => isOn = value),
  builder: (context, toggleState, _) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 48,
    height: 28,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: toggleState.isToggled ? Colors.green : Colors.grey.shade400,
    ),
    alignment:
        toggleState.isToggled ? Alignment.centerRight : Alignment.centerLeft,
    padding: const EdgeInsets.all(3),
    child: const DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
    ),
  ),
);
```

### NakedTabs

```dart
NakedTabs(
  selectedTabId: tab,
  onChanged: (id) => setState(() => tab = id),
  child: Column(
    children: [
      NakedTabList(
        child: Row(
          children: ['preview', 'code'].map((id) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: NakedTab(
                tabId: id,
                builder: (context, tabState, _) => Chip(
                  label: Text(id),
                  backgroundColor:
                      tabState.isSelected ? Colors.blue : Colors.grey.shade200,
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 12),
      NakedTabPanel(
        tabId: 'preview',
        child: const Text('Preview content'),
      ),
      NakedTabPanel(
        tabId: 'code',
        child: const Text('Source code'),
      ),
    ],
  ),
);
```

### NakedAccordion

```dart
final controller = NakedAccordionController<int>(min: 1, max: 2);

NakedAccordionGroup<int>(
  controller: controller,
  initialExpandedValues: const [0],
  children: [
    NakedAccordionGroup<int>(
      value: 0,
      triggerBuilder: (context, itemState, _) => ListTile(
        title: const Text('Section 1'),
        trailing: Icon(itemState.isExpanded
            ? Icons.expand_less
            : Icons.expand_more),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Content for section 1'),
      ),
    ),
  ],
);
```

### NakedMenu

```dart
final menuController = MenuController();

NakedMenu<String>(
  controller: menuController,
  selectedValue: action,
  onSelected: (value) => setState(() => action = value),
  triggerBuilder: (context, menuState) => Text(menuState.isOpen ? 'Close' : 'Open'),
  overlayBuilder: (context, info) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      NakedMenu.Item(value: 'edit', child: const Text('Edit')),
      NakedMenu.Item(value: 'delete', child: const Text('Delete')),
    ],
  ),
);
```

### NakedDialog

```dart
final result = await showNakedDialog<String>(
  context: context,
  barrierColor: Colors.black54,
  builder: (context) => NakedDialog(
    semanticLabel: 'Confirm action',
    child: Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Are you sure?'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  ),
);
```

### NakedTooltip

```dart
NakedTooltip(
  semanticsLabel: 'Copy to clipboard',
  tooltipBuilder: (context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text('Copied!', style: TextStyle(color: Colors.white)),
  ),
  child: const Icon(Icons.copy),
);
```

### NakedPopover

```dart
NakedPopover(
  popoverBuilder: (context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: const Text('Popover content'),
    ),
  ),
  child: const Icon(Icons.more_horiz),
);
```

### NakedTextField

```dart
final controller = TextEditingController();

NakedTextField(
  controller: controller,
  onChanged: (value) => debugPrint(value),
  builder: (context, editable) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade400),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: editable,
    ),
  ),
);
```

---

## Further Reading

- Documentation hub: https://docs.page/btwld/naked_ui
- Example app: `example/lib/main.dart`
- Migration guide: `MIGRATION.md`

Need deeper guidance or have questions? Open an issue on GitHub or reach out in the docs discussions.
