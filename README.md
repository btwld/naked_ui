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
  builder: (context, state, _) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: state.when(
          pressed: Colors.blue.shade700,
          hovered: Colors.blue.shade500,
          orElse: Colors.blue,
        ),
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
  builder: (context, state, _) => Icon(
    state.isChecked == true
        ? Icons.check_box
        : Icons.check_box_outline_blank,
    color: state.when(
      hovered: Colors.blue,
      orElse: Colors.grey.shade700,
    ),
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
        builder: (context, state, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state.isSelected ? Colors.blue : Colors.white,
            border: Border.all(
              color: state.when(
                hovered: Colors.blue,
                orElse: Colors.grey.shade400,
              ),
              width: state.when(
                pressed: 4,
                orElse: 2,
              ),
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
  builder: (context, state, _) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(state.value ?? 'Pick fruit'),
        Icon(state.isOpen ? Icons.expand_less : Icons.expand_more),
      ],
    );
  },
  overlayBuilder: (context, info) => Column(
    mainAxisSize: MainAxisSize.min,
    children: ['Apple', 'Banana', 'Mango']
        .map((label) => NakedSelect.Option<String>(
              value: label.toLowerCase(),
              builder: (context, state, _) => ListTile(
                title: Text(label),
                tileColor: state.when(
                  hovered: Colors.grey.shade100,
                  orElse: Colors.transparent,
                ),
                trailing: state.isSelected
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
  builder: (context, state, _) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 48,
    height: 28,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: state.when(
        hovered: state.isToggled ? Colors.green.shade600 : Colors.grey.shade500,
        orElse: state.isToggled ? Colors.green : Colors.grey.shade400,
      ),
    ),
    alignment:
        state.isToggled ? Alignment.centerRight : Alignment.centerLeft,
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
      NakedTabBar(
        child: Row(
          children: ['preview', 'code'].map((id) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: NakedTab(
                tabId: id,
                builder: (context, state, _) => Chip(
                  label: Text(id),
                  backgroundColor: state.when(
                    selected: Colors.blue,
                    hovered: Colors.grey.shade300,
                    orElse: Colors.grey.shade200,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 12),
      NakedTabView(
        tabId: 'preview',
        child: const Text('Preview content'),
      ),
      NakedTabView(
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
    NakedAccordion<int>(
      value: 0,
      builder: (context, state) => Container(
        decoration: BoxDecoration(
          color: state.when(
            hovered: Colors.grey.shade100,
            orElse: Colors.transparent,
          ),
        ),
        child: ListTile(
          title: const Text('Section 1'),
          trailing: Icon(
            state.isExpanded ? Icons.expand_less : Icons.expand_more,
          ),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Content for section 1'),
      ),
    ),
    NakedAccordion<int>(
      value: 1,
      builder: (context, state) => Container(
        decoration: BoxDecoration(
          color: state.when(
            hovered: Colors.grey.shade100,
            orElse: Colors.transparent,
          ),
        ),
        child: ListTile(
          title: const Text('Section 2'),
          trailing: Icon(
            state.isExpanded ? Icons.expand_less : Icons.expand_more,
          ),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Content for section 2'),
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
  onSelected: (value) => setState(() => action = value),
  builder: (context, state, _) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: state.when(
        hovered: Colors.grey.shade200,
        orElse: Colors.transparent,
      ),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(state.isOpen ? 'Close' : 'Open'),
  ),
  overlayBuilder: (context, info) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      NakedMenu.Item(
        value: 'edit',
        builder: (context, state, _) => Container(
          color: state.when(
            hovered: Colors.grey.shade200,
            orElse: Colors.transparent,
          ),
          child: const ListTile(title: Text('Edit')),
        ),
      ),
      NakedMenu.Item(
        value: 'delete',
        builder: (context, state, _) => Container(
          color: state.when(
            hovered: Colors.grey.shade200,
            orElse: Colors.transparent,
          ),
          child: const ListTile(title: Text('Delete')),
        ),
      ),
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
  overlayBuilder: (context, info) => Container(
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
  popoverBuilder: (context, info) => Card(
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

## Testing

This package includes comprehensive unit and integration tests for all components.

### Quick Start - Running Tests

```bash
# Run unit tests only (default)
dart tool/test.dart

# Run all tests (unit + integration)
dart tool/test.dart --all

# Run integration tests only
dart tool/test.dart --integration

# Run specific component integration tests
dart tool/test.dart --component=button
dart tool/test.dart --component=textfield

# Get detailed output for debugging
dart tool/test.dart --all --verbose
```

### Test Types

#### Unit Tests
- Fast, isolated tests for widget behavior and semantics
- Located in `test/` directory
- Run automatically on every test command

#### Integration Tests
- Full UI automation tests on macOS
- Test real user interactions: hover, click, keyboard navigation
- Located in `example/integration_test/components/`
- Individual component tests available

### Available Integration Test Components

- **button** - NakedButton interactions and states
- **checkbox** - NakedCheckbox toggle and accessibility
- **radio** - NakedRadio selection and groups
- **slider** - NakedSlider dragging and value changes
- **textfield** - NakedTextField input and validation
- **select** - NakedSelect dropdown and selection
- **popover** - NakedPopover positioning and dismissal
- **tooltip** - NakedTooltip display and timing
- **menu** - NakedMenu navigation and actions
- **accordion** - NakedAccordion expand/collapse
- **tabs** - NakedTabs switching and keyboard nav
- **dialog** - NakedDialog modal behavior

### Prerequisites

1. **macOS platform support** (for integration tests):
   ```bash
   flutter create --platforms=macos .
   ```

2. **Flutter dependencies up to date**:
   ```bash
   flutter pub get
   ```

### Troubleshooting

#### Integration Tests Hang or Fail

1. **Check app runs manually first**:
   ```bash
   flutter run -d macos
   ```

2. **Run individual component tests**:
   ```bash
   dart tool/test.dart --component=button
   ```

3. **Use verbose output for details**:
   ```bash
   dart tool/test.dart --integration --verbose
   ```

#### Test Environment

- **Platform**: macOS required for integration tests
- **Timeout**: 5-minute timeout for full integration suite
- **Environment**: `RUN_INTEGRATION=1` set automatically by test script
- **Reporter**: Compact by default, expanded with `--verbose`

---

## Development

### Melos Support

This project uses [Melos](https://melos.invertase.dev/) for monorepo management:

```bash
# Install melos globally
dart pub global activate melos

# Bootstrap the workspace
melos bootstrap

# Run tests via melos
melos run test
melos run test:integration
melos run test:all
```

### CI/CD

The test script is designed for CI environments:

```yaml
# Example GitHub Actions
- name: Run tests
  run: dart tool/test.dart --all
```

---

## Further Reading

- Documentation hub: https://docs.page/btwld/naked_ui
- Example app: `example/lib/main.dart`
- Migration guide: `MIGRATION.md`
- Testing guide: `example/README.md#testing`

Need deeper guidance or have questions? Open an issue on GitHub or reach out in the docs discussions.
