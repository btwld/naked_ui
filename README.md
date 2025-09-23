The Naked UI library provides headless components that handle functionality, interaction, and accessibility without imposing any visual styling. This approach gives you full control over your design system while ensuring components work correctly and meet accessibility standards.

## Key Features

- Zero‑styling: behavior only — you own presentation
- Accessible: correct semantics and keyboard navigation
- Observable state: hover, focus, press, drag, select
- Composable: small, predictable APIs

## Documentation

📚 **[View Full Documentation](https://docs.page/btwld/naked_ui)**

The complete documentation covers detailed component APIs and examples, guides and best practices, accessibility implementation details, as well as advanced usage patterns and customization.

## Supported Components

- NakedButton — button interactions (hover, press, focus)
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

1. **Create your visual design**: Design your UI components using standard Flutter widgets
2. **Wrap with Naked behavior**: Wrap your design with the appropriate Naked component
3. **Handle state changes**: Use the builder pattern to access component state and update your visual design accordingly

## Example: Creating a Custom Button

```dart
class MyCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const MyCustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: onPressed,
      builder: (context, state, child) => Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: state.when(
            pressed: Colors.blue.shade800,    // Darker when pressed
            hovered: Colors.blue.shade600,    // Slightly darker when hovered
            orElse: Colors.blue.shade500,     // Default color
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: state.isFocused ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white),
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
