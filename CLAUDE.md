# CLAUDE.md

This file provides guidance for AI assistants working with the naked_ui codebase.

## Project Overview

**naked_ui** is a Flutter UI library for headless (unstyled) widgets. It provides behavior-first components that handle interaction states, accessibility, and keyboard navigation—without any visual styling. Developers wrap their custom visuals in these components to get production-ready behavior.

- **Repository**: https://github.com/btwld/naked_ui
- **Documentation**: https://docs.page/btwld/naked_ui
- **Version**: 0.2.0-beta.7 (pre-release)
- **License**: BSD-3-Clause

## Repository Structure

```
naked_ui/
├── packages/
│   ├── naked_ui/           # Main library package (published to pub.dev)
│   │   ├── lib/
│   │   │   ├── naked_ui.dart           # Main export barrel
│   │   │   └── src/
│   │   │       ├── naked_*.dart        # Component implementations
│   │   │       ├── mixins/             # Reusable state/focus mixins
│   │   │       ├── utilities/          # Shared utilities (state, positioning)
│   │   │       └── base/               # Base classes for overlays
│   │   └── test/
│   │       ├── src/                    # Unit tests per component
│   │       ├── semantics/              # Accessibility/semantics tests
│   │       ├── mixins/                 # Mixin tests
│   │       └── utilities/              # Utility tests
│   └── example/            # Demo app ("Kitchen Sink")
│       ├── lib/
│       │   ├── api/                    # Example implementations
│       │   └── shell/                  # Demo app shell
│       └── integration_test/           # Integration tests
├── docs/                   # Documentation (docs.page MDX files)
├── .claude/
│   └── semantics_reference.md          # Comprehensive semantics guide
├── melos.yaml              # Monorepo configuration
└── .fvmrc                  # Flutter version (3.32.0)
```

## Development Environment

### Requirements
- **Flutter**: 3.27.0+ (FVM configured for 3.32.0)
- **Dart SDK**: 3.8.0+
- **Melos**: For monorepo management

### Setup Commands
```bash
# Install melos globally
dart pub global activate melos

# Bootstrap packages
melos bootstrap

# Run in example app
cd packages/example && flutter run
```

### Key Commands
```bash
# Format code
melos run format:check

# Run tests (from packages/naked_ui)
flutter test

# Run integration tests (from packages/example)
flutter test -d flutter-tester integration_test/all_tests.dart

# Analyze code
flutter analyze
```

## Architecture & Core Concepts

### Builder Pattern
Every component uses a builder pattern that provides state to consumers:

```dart
NakedButton(
  onPressed: () {},
  builder: (context, state, child) {
    // state is NakedButtonState with isHovered, isFocused, isPressed, etc.
    return Container(
      color: state.when(
        pressed: Colors.blue.shade900,
        hovered: Colors.blue.shade700,
        orElse: Colors.blue,
      ),
      child: child,
    );
  },
  child: Text('Click me'),
)
```

### State Classes
Each component has a corresponding state class extending `NakedState`:
- `NakedButtonState`, `NakedCheckboxState`, `NakedSliderState`, etc.
- Common properties: `isHovered`, `isFocused`, `isPressed`, `isDisabled`, `isSelected`
- `state.when()` method for conditional styling with priority order

### Mixins (lib/src/mixins/)
- **WidgetStatesMixin**: Manages widget states (hovered, focused, pressed, disabled)
- **FocusNodeMixin**: Handles focus node lifecycle (internal/external swap, focus preservation)

### Component Categories
1. **Simple Controls**: `NakedButton`, `NakedCheckbox`, `NakedRadio`, `NakedToggle`, `NakedSlider`
2. **Text Input**: `NakedTextField`
3. **Selection**: `NakedSelect`, `NakedTabs`
4. **Overlays**: `NakedMenu`, `NakedDialog`, `NakedPopover`, `NakedTooltip`
5. **Layout**: `NakedAccordion`

## Code Conventions

### File Organization
- One primary widget per file (e.g., `naked_button.dart`)
- Related sub-components in same file (e.g., `NakedMenuItem` in `naked_menu.dart`)
- State class defined before widget class
- Exports go through `naked_widgets.dart`

### Naming Conventions
- Components: `Naked{Component}` (e.g., `NakedButton`, `NakedCheckbox`)
- State classes: `Naked{Component}State`
- Callbacks: `on{Action}Change` (e.g., `onHoverChange`, `onFocusChange`, `onPressChange`)
- Builder parameter always named `builder`

### Member Ordering (analysis_options.yaml)
1. public-fields
2. private-fields
3. constructors
4. static-methods
5. private-methods/getters/setters
6. public-getters/setters/methods
7. overridden methods
8. build-method

### Import Style
- Use relative imports within the package (`import '../utilities/state.dart'`)
- Avoid importing from entrypoint exports in src/

## Accessibility & Semantics

**Critical**: This library prioritizes accessibility. See `.claude/semantics_reference.md` for the complete guide.

### Key Rules
1. Always set `excludeFromSemantics: true` on GestureDetector when parent Semantics provides actions
2. Place Semantics inside FocusableActionDetector
3. Use `button: true`, `checked:`, `toggled:` flags appropriately
4. Provide proper `semanticLabel` and `tooltip` parameters
5. Handle focus traversal correctly

### Testing Semantics
Tests verify parity with Material widgets:
```dart
await expectSemanticsParity(
  tester: tester,
  material: ElevatedButton(onPressed: () {}, child: Text('Click')),
  naked: NakedButton(onPressed: () {}, child: Text('Click')),
  control: ControlType.button,
);
```

## Testing Approach

### Test Categories
1. **Unit Tests** (`test/src/`): Component behavior, state management
2. **Semantics Tests** (`test/semantics/`): Accessibility parity with Material
3. **Parity Tests** (`test/src/parity/`): Behavior matches Material widgets
4. **Mixin Tests** (`test/mixins/`): WidgetStatesMixin, FocusNodeMixin
5. **Integration Tests** (`example/integration_test/`): End-to-end on real device

### Test Patterns
```dart
testWidgets('description', (tester) async {
  final handle = tester.ensureSemantics(); // For semantics tests

  await tester.pumpWidget(MaterialApp(home: YourWidget()));

  // Test interactions
  await tester.tap(find.byType(NakedButton));
  await tester.pump();

  // Verify state
  expect(find.text('Clicked'), findsOneWidget);

  handle.dispose(); // Clean up semantics
});
```

## Commit & PR Conventions

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` New features
- `fix:` Bug fixes
- `refactor:` Code changes without feature/fix
- `docs:` Documentation only
- `test:` Adding/updating tests
- `chore:` Maintenance tasks

### PR Title Format
PR titles must follow Conventional Commits format (enforced by CI).

## CI/CD Workflows

- **ci.yml**: Runs on push/PR to main - format check, analyze, test (via melos)
- **pr.yml**: Validates PR title follows Conventional Commits
- **integration-tests.yml**: Runs integration tests on macOS
- **release.yml**: Publishes to pub.dev on version tags (v*)
- **deploy-web.yml**: Deploys example app to web

## Common Tasks

### Adding a New Component
1. Create `lib/src/naked_{component}.dart`
2. Define `Naked{Component}State` extending `NakedState`
3. Define `Naked{Component}` widget with builder pattern
4. Use `WidgetStatesMixin` and `FocusNodeMixin` as needed
5. Export in `naked_widgets.dart`
6. Add semantics tests in `test/semantics/`
7. Add unit tests in `test/src/`
8. Add example in `example/lib/api/`
9. Add integration test in `example/integration_test/components/`
10. Add documentation in `docs/widget/`

### Modifying State Behavior
State updates should:
1. Use `updateState()` or helper methods (`updateHoverState`, etc.)
2. Only trigger callbacks when state actually changes
3. Handle disabled state transitions properly
4. Clean up timers/listeners in dispose

### Working with Overlays
Overlay components (Menu, Select, Dialog, Popover, Tooltip) use:
- `OverlayPortal` for rendering
- `AnchoredOverlayShell` for positioning
- Focus trapping for dialogs
- Proper dismiss handling (click outside, Escape key)

## Important Files to Review

When making changes, review these key files:
- `lib/src/utilities/state.dart` - Base NakedState class
- `lib/src/mixins/naked_mixins.dart` - WidgetStatesMixin, FocusNodeMixin
- `lib/src/utilities/naked_focusable_detector.dart` - Focus/hover handling
- `.claude/semantics_reference.md` - Accessibility patterns
