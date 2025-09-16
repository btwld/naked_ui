# Naked UI

Behavior‑first, zero‑styling Flutter components that give you complete design freedom.

## Introduction

The Naked UI library provides headless components that handle functionality, interaction, and accessibility without imposing visual styles. You keep full control of your design system while the components take care of correct behavior and a11y.

## Key Features

- **Zero‑styling**: Behavior only — you own 100% of presentation
- **Accessible**: Correct semantics and keyboard navigation
- **Composable**: Small, predictable APIs with sensible defaults
- **Observable state**: Callbacks for hover, focus, press, drag, select

## Components

- **NakedButton** — button interactions (hover, press, focus)
- **NakedCheckbox** — toggle behavior and semantics
- **NakedRadio** — single‑select radio with group management
- **NakedSelect** — dropdown/select with keyboard nav
- **NakedSlider** — value slider with drag + keys
- **NakedToggle** — toggle button or switch behavior
- **NakedTabs** — tablist + roving focus
- **NakedAccordion** — expandable/collapsible sections
- **NakedMenu** — anchored overlay menu
- **NakedDialog** — modal dialog behavior + focus trap
- **NakedTooltip** — anchored tooltip with lifecycle
- **NakedPopover** — anchored, dismissible popover overlay

## Getting Started

### Installation

Add the package to your Flutter project:

```yaml
dependencies:
  naked_ui: ^latest_version  # See https://pub.dev/packages/naked_ui
```

Then:

```bash
flutter pub get
```

Import:

```dart
import 'package:naked_ui/naked_ui.dart';
```

### Basic Usage Pattern

All Naked components follow a similar pattern:

1. **Create your visual design**: Design your UI components using standard Flutter widgets
2. **Wrap with Naked behavior**: Wrap your design with the appropriate Naked component
3. **Handle state changes**: Use the provided callbacks to update your visual design based on component state

## Quick Example: Custom Button

```dart
class MyCustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  
  const MyCustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  _MyCustomButtonState createState() => _MyCustomButtonState();
}

class _MyCustomButtonState extends State<MyCustomButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: widget.onPressed,
      onHoverChange: (isHovered) => setState(() => _isHovered = isHovered),
      onPressChange: (isPressed) => setState(() => _isPressed = isPressed),
      onFocusChange: (isFocused) => setState(() => _isFocused = isFocused),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.blue.shade800  // Darker when pressed
              : _isHovered
                  ? Colors.blue.shade600  // Slightly darker when hovered
                  : Colors.blue.shade500, // Default color
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isFocused ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          widget.text,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
```

## Configuration

Each component has its own set of configuration options. Here are some common patterns:

### State Callbacks

Most components provide state callbacks that notify you when the component's state changes:

```dart
NakedButton(
  onHoverChange: (isHovered) => handleHover(isHovered),
  onPressChange: (isPressed) => handlePress(isPressed),
  onFocusChange: (isFocused) => handleFocus(isFocused),
  // Other properties...
)
```



### Custom Focus Handling

You can provide your own focus nodes for advanced focus management:

```dart
final FocusNode _myFocusNode = FocusNode();

// In your widget build method:
NakedButton(
  focusNode: _myFocusNode,
  autofocus: true,
  // Other properties...
)
```

## Docs & Examples

- Documentation: https://docs.page/btwld/naked_ui
- Example app: example/lib/main.dart
- Migration guide: MIGRATION.md

Supported Flutter: `>= 3.27.0` (see `pubspec.yaml`).
