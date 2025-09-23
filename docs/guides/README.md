# Naked Components Guide

This guide provides documentation for the Naked component library, focusing on usage patterns, best practices, and technical details.

## Contents

- [State Management Patterns](./state_callbacks.md) - Modern builder pattern vs legacy callbacks
- [Interaction Behaviors](./interaction_behaviors.md) - Understanding the underlying interaction architecture

## About Naked Components

Naked components are unstyled, headless UI components for Flutter that provide behavior without visual styling. They give you complete control over appearance while handling complex interaction patterns, accessibility, and state management.

Key features:
- **Builder pattern** for direct state access (recommended)
- Legacy state callbacks for backward compatibility
- Built-in keyboard accessibility
- Screen reader support
- Flexible composition

## Getting Started

To use the Naked library, add it to your `pubspec.yaml`:

```yaml
dependencies:
  naked_ui: ^latest_version
```

Then import it in your Dart code:

```dart
import 'package:naked_ui/naked_ui.dart';
```

## Usage Examples

### Modern Builder Pattern (Recommended)

```dart
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: () {
        print('Button pressed!');
      },
      builder: (context, state, child) {
        final color = state.when(
          pressed: Colors.blue.shade700,
          hovered: Colors.blue.shade500,
          orElse: Colors.blue.shade400,
        );

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: state.isFocused ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            'Click Me',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}
```

### Legacy Callback Pattern

```dart
class MyLegacyButton extends StatefulWidget {
  @override
  _MyLegacyButtonState createState() => _MyLegacyButtonState();
}

class _MyLegacyButtonState extends State<MyLegacyButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: () {
        print('Button pressed!');
      },
      onHoverChange: (isHovered) => setState(() => _isHovered = isHovered),
      onPressChange: (isPressed) => setState(() => _isPressed = isPressed),
      onFocusChange: (isFocused) => setState(() => _isFocused = isFocused),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isPressed
            ? Colors.blue.shade700
            : _isHovered
              ? Colors.blue.shade500
              : Colors.blue.shade400,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isFocused ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          'Click Me',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
```

The builder pattern is recommended as it eliminates boilerplate, enables stateless widgets, and provides cleaner conditional logic.