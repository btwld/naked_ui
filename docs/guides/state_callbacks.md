# State Management Patterns

## Overview

Naked components provide two approaches for accessing component state: the modern **builder pattern** (recommended) and **legacy state callbacks**. This guide explains both approaches and how to migrate from callbacks to the builder pattern.

## Builder Pattern (Recommended)

The modern approach uses a `builder` function that provides direct access to component state:

```dart
NakedButton(
  onPressed: () => debugPrint('Button pressed!'),
  builder: (context, state, child) {
    // Direct access to state properties
    final isHovered = state.isHovered;
    final isPressed = state.isPressed;
    final isFocused = state.isFocused;

    // Use state.when() for conditional styling
    final color = state.when(
      pressed: Colors.blue.shade800,
      hovered: Colors.blue.shade600,
      orElse: Colors.blue,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: color,
      padding: const EdgeInsets.all(16),
      border: isFocused ? Border.all(color: Colors.white, width: 2) : null,
      child: const Text('Button', style: TextStyle(color: Colors.white)),
    );
  },
)
```

### Benefits of the Builder Pattern

1. **Stateless widgets**: No need for StatefulWidget in most cases
2. **Direct state access**: Use `state.isHovered`, `state.isPressed`, etc.
3. **Conditional styling**: Use `state.when()` for clean conditional logic
4. **Better performance**: Eliminates extra setState calls

## Legacy State Callbacks

The legacy approach uses callback functions that notify you when states change:

```
on{State}Change
```

For example:
- `onHoverChange`: Called when hover state changes (legacy)
- `onPressChange`: Called when pressed state changes (legacy)
- `onFocusChange`: Called when focus state changes (legacy)
- `onDragChange`: Called when drag state changes (NakedSlider)
- `onSelectChange`: Called when selection state changes (NakedSelect/NakedSelectItem)

### Legacy Callback Reference

Most interactive Naked components implement these core state callbacks:

| Callback | Description | Parameter |
|----------|-------------|-----------|
| `onHoverChange` (legacy) | Called when mouse enters or leaves the component | `bool isHovered` |
| `onPressChange` (legacy) | Called when component is pressed or released | `bool isPressed` |
| `onFocusChange` (legacy) | Called when component gains or loses focus | `bool isFocused` |

Some components also implement specialized state callbacks:

| Callback | Description | Used By |
|----------|-------------|---------|
| `onDragChange` | Called when drag state changes | `NakedSlider` |
| `onSelectChange` | Called when selection state changes | `NakedSelect`, `NakedSelectItem` |

### Legacy Usage Example

```dart
class LegacyButton extends StatefulWidget {
  @override
  State<LegacyButton> createState() => _LegacyButtonState();
}

class _LegacyButtonState extends State<LegacyButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: () {
        // Handle button tap
      },
      onHoverChange: (isHovered) {
        setState(() {
          _isHovered = isHovered;
        });
      },
      onPressChange: (isPressed) {
        setState(() {
          _isPressed = isPressed;
        });
      },
      onFocusChange: (isFocused) {
        setState(() {
          _isFocused = isFocused;
        });
      },
      child: AnimatedContainer(
        // Use state variables to control appearance
        duration: const Duration(milliseconds: 150),
        color: _isPressed
            ? Colors.blue.shade700
            : _isHovered
                ? Colors.blue.shade500
                : Colors.blue.shade400,
        padding: const EdgeInsets.all(16),
        child: const Text('Button'),
      ),
    );
  }
}
```

## Migrating from Callbacks to Builder

Here's how to migrate the above example to use the builder pattern:

```dart
class ModernButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: () {
        // Handle button tap
      },
      builder: (context, state, child) {
        final color = state.when(
          pressed: Colors.blue.shade700,
          hovered: Colors.blue.shade500,
          orElse: Colors.blue.shade400,
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: color,
          padding: const EdgeInsets.all(16),
          child: const Text('Button'),
        );
      },
    );
  }
}
```

## State Management

Note on radio buttons: `NakedRadio` does not expose `onSelectChange`. Use the `RadioGroup`'s `onChanged` to observe selection changes, or read selection via `NakedRadio`'s builder using `state.isSelected`.

### State Management Philosophy

Naked components provide state information but do not manage visual state internally. The builder pattern gives you direct access to state, while legacy callbacks inform you when states change.

Both approaches:
1. Give you full control over state persistence
2. Allow for complex state combinations
3. Enable complete styling freedom
4. Support any state management approach

The builder pattern additionally:
- Eliminates boilerplate state management code
- Provides cleaner conditional logic with `state.when()`
- Enables stateless widget patterns

## Migrating from older versions

In previous versions of the library, some components used the pattern `onState{Name}` (e.g., `onStateHover`, `onStateFocus`). 

The naming has been standardized to `on{State}Change` for clarity and consistency. If you're upgrading from a previous version, you'll need to update your callback usage:

| Old Pattern | New Pattern |
|-------------|-------------|
| `onStateHover` | `onHoverChange` |
| `onStatePressed` | `onPressChange` |
| `onStateFocus` | `onFocusChange` |
| `onStateDragging` | `onDragChange` |
| `onStateSelected` | `onSelectChange` |
