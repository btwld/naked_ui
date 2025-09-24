# naked_ui

**Unstyled Flutter components that you design.**

Build buttons, inputs, menus, and dialogs that look exactly how you want them. Naked UI handles all the complex behavior—keyboard navigation, accessibility, focus management—while you control every pixel of the design.

## Why Naked UI?

**Complete design control.** Every component is completely unstyled—no theme overrides or framework limitations.

**Built-in accessibility.** All components include keyboard navigation, screen reader support, and touch interactions.

**Consistent API.** Every component follows the same pattern: wrap your design, receive state updates, customize appearance.

## Quick example

```dart
NakedButton(
  onPressed: () => print('Hello!'),
  builder: (context, state, child) {
    return Container(
      padding: EdgeInsets.all(12),
      color: state.isPressed ? Colors.blue : Colors.grey,
      child: Text('Press me!'),
    );
  },
)
```

This creates a fully accessible button with press state handling. The component also supports hover and focus states. Customize appearance with borders, animations, gradients, or any styling.

## Available components

Button • Checkbox • Radio • Select • Slider • Toggle • Tabs • Accordion • Menu • Dialog • Tooltip • Popover

## Get started

📚 **[Full Documentation & Examples](https://docs.page/btwld/naked_ui)**

```yaml
dependencies:
  naked_ui: ^latest_version
```

```dart
import 'package:naked_ui/naked_ui.dart';
```

View the [Getting Started guide](https://docs.page/btwld/naked_ui) for detailed examples and implementation patterns.
