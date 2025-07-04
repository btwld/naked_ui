# Naked

Zero-styling UI components giving you complete design freedom

## Introduction

The **Naked** library provides UI components that handle only the functionality, behavior, and accessibility aspects of UI elements without imposing any visual styling. This approach gives you complete control over your design system while ensuring all components work correctly and meet accessibility standards.

## Key Features

- **Zero-styling approach**: Components handle behavior only, you control 100% of the visual design
- **Accessibility built-in**: All components implement proper ARIA roles and keyboard navigation
- **Flexible state management**: Callback functions for all component states (hover, focus, pressed, etc.)
- **Customizable**: Simple API with sensible defaults and extensive customization options

## Available Components

The library includes the following components:

- **NakedButton**: Interactive button behavior with state callbacks
- **NakedCheckbox**: Toggle component with customizable states
- **NakedTooltip**: Positioned tooltip behavior with lifecycle management
- **NakedTextField**: Text input with validation and state management
- **NakedSelect**: Dropdown/select implementation with keyboard navigation
- **NakedSlider**: Draggable slider with keyboard support and value constraints
- **NakedTabs**: Tab navigation behavior with accessibility controls
- **NakedRadioGroup**: Radio button group behavior with selection management
- **NakedAccordion**: Expandable/collapsible section behavior
- **NakedMenu**: Menu component with keyboard navigation

## Getting Started

### Installation

Add the Naked UI library to your Flutter project:

```yaml
dependencies:
  naked: ^latest_version  # Check for the latest version at https://pub.dev/packages/naked
```

Then run:

```bash
flutter pub get
```

### Basic Usage Pattern

All Naked components follow a similar pattern:

1. **Create your visual design**: Design your UI components using standard Flutter widgets
2. **Wrap with Naked behavior**: Wrap your design with the appropriate Naked component
3. **Handle state changes**: Use the provided callbacks to update your visual design based on component state

## Example: Creating a Custom Button

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
      onHoverState: (isHovered) => setState(() => _isHovered = isHovered),
      onPressedState: (isPressed) => setState(() => _isPressed = isPressed),
      onFocusState: (isFocused) => setState(() => _isFocused = isFocused),
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
  onHoverState: (isHovered) => handleHover(isHovered),
  onPressedState: (isPressed) => handlePress(isPressed),
  onFocusState: (isFocused) => handleFocus(isFocused),
  // Other properties...
)
```

### Accessibility Options

Components offer accessibility configuration:

```dart
NakedButton(
  semanticLabel: 'Submit form',
  isSemanticButton: true,
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

See each component's documentation for details on all available configuration options.
