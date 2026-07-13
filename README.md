# naked_ui

A Flutter UI library for headless widgets. No styling, just behavior. Build custom UIs with full semantics and observable states like hovered, focused, pressed, dragged, and others.

## Features
- No styling: Completely naked components for total design control.
- Full semantics: Built-in accessibility for screen readers and assistive tools.
- Observable states: Track hover, focus, drag, and more.
- Builder APIs: Composable widgets for custom UI logic.

## Documentation

📚 **[View Full Documentation](https://docs.page/btwld/naked_ui)**

The complete documentation covers detailed component APIs and examples, guides and best practices, accessibility implementation details, as well as advanced usage patterns and customization.

## Supported Components

- NakedButton — button interactions (hover, press, focus)
- NakedLink — native Link navigation, semantics, and Enter-only activation
- NakedCheckbox — toggle behavior and semantics
- NakedRadio — single‑select radio with group management
- NakedSelect — dropdown/select with keyboard navigation
- NakedSlider — value slider with drag + keys
- NakedToggle — toggle button or switch behavior
- NakedTabs — tablist + roving focus
- NakedAccordion — expandable/collapsible sections
- NakedMenu — anchored overlay menu
- NakedDialog — modal dialog behavior + focus trap
- NakedTooltip — anchored tooltip with lifecycle
- NakedPopover — anchored, dismissible popover overlay

## Basic Usage Pattern

1. Build your custom visuals using standard Flutter widgets
2. Wrap the visuals in the corresponding Naked component
3. React to typed state callbacks or use the builder snapshot to style interaction states

## Examples

Below are examples of using `NakedButton`, `NakedCheckbox`, and `NakedMenu`. Each shows how to wrap custom visuals with headless behavior and handle states using the builder pattern. See the [full documentation](https://docs.page/btwld/naked_ui) for all components.

### Custom Button
Create a button with custom styling that responds to interaction states.

```dart
NakedButton(
  onPressed: () => print('Clicked'),
  builder: (context, state, child) => Container(
    padding: const EdgeInsets.all(12),
    color: state.when(
      pressed: Colors.blue.shade900,
      hovered: Colors.blue.shade700,
      focused: Colors.blue.shade600,
      orElse: Colors.blue,
    ),
    child: const Text('Click Me', style: TextStyle(color: Colors.white)),
  ),
)
```

### Custom Link

Use a Link for navigation rather than styling a Button like text. The URL is
the destination and enables the Link. Naked UI delegates default navigation to
Flutter's official `url_launcher.Link`; provide `onPressed` only when custom
routing should replace that default. Enter and Numpad Enter activate, while
Space remains available to the page.

```dart
NakedLink(
  linkUrl: Uri.parse('https://example.com/docs'),
  child: const Text('Documentation'),
  builder: (context, state, child) => DecoratedBox(
    decoration: BoxDecoration(
      color: state.isHovered ? Colors.blue.shade50 : Colors.transparent,
      border: Border.all(
        color: state.isFocused ? Colors.blue : Colors.transparent,
      ),
    ),
    child: child,
  ),
)
```

### Custom Checkbox
Build a checkbox with custom visuals while maintaining proper state management.

```dart
class SimpleCheckbox extends StatefulWidget {
  const SimpleCheckbox({super.key});

  @override
  State<SimpleCheckbox> createState() => _SimpleCheckboxState();
}

class _SimpleCheckboxState extends State<SimpleCheckbox> {
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    return NakedCheckbox(
      value: checked,
      onChanged: (value) => setState(() => checked = value!),
      builder: (context, state, child) => Container(
        width: 24,
        height: 24,
        color: state.when(
          hovered: Colors.grey.shade300,
          focused: Colors.blue.shade100,
          orElse: state.isChecked ? Colors.blue : Colors.grey.shade200,
        ),
        child: state.isChecked ? const Icon(Icons.check, size: 16) : null,
      ),
    );
  }
}
```

### Custom Menu
Create a dropdown menu with custom styling and menu items.

```dart
final menuController = MenuController();

NakedMenu<String>(
  controller: menuController,
  onSelected: (value) => print('Selected: $value'),
  builder: (context, state, child) => Container(
    padding: const EdgeInsets.all(8),
    color: state.when(
      hovered: Colors.grey.shade300,
      pressed: Colors.grey.shade400,
      orElse: state.isOpen ? Colors.grey.shade200 : Colors.white,
    ),
    child: Text(state.isOpen ? 'Close' : 'Menu'),
  ),
  overlayBuilder: (context, info) => Container(
    color: Colors.white,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NakedMenuItem(
          value: 'edit',
          builder: (context, state, child) => Container(
            padding: const EdgeInsets.all(8),
            color: state.isHovered ? Colors.blue.shade100 : Colors.white,
            child: const Text('Edit'),
          ),
        ),
        NakedMenuItem(
          value: 'delete',
          builder: (context, state, child) => Container(
            padding: const EdgeInsets.all(8),
            color: state.isHovered ? Colors.red.shade100 : Colors.white,
            child: const Text('Delete'),
          ),
        ),
      ],
    ),
  ),
)
```

## Builder Pattern

Naked UI components use the builder pattern to give you access to the current interaction state, allowing you to drive your own visual design and behavior:

```dart
NakedButton(
  builder: (context, state, child) {
    // Access state properties directly
    if (state.isPressed) {
      // Handle pressed state
    }
    if (state.isHovered) {
      // Handle hover state
    }
    if (state.isFocused) {
      // Handle focus state
    }

    // Use state.when() for conditional styling
    final color = state.when(
      pressed: Colors.blue.shade800,
      hovered: Colors.blue.shade600,
      orElse: Colors.blue,
    );

    return YourWidget(color: color);
  },
  // Other properties...
)
```
See each component's documentation for details on all available configuration options.
