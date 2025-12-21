# CLAUDE.md

## Project Overview

**naked_ui** is a Flutter library for headless (unstyled) widgets. Components provide behavior, accessibility, and keyboard navigation without visual styling.

- **Docs**: https://docs.page/btwld/naked_ui
- **Version**: 0.2.0-beta.7

## Repository Structure

```
packages/
├── naked_ui/          # Main library (pub.dev)
│   ├── lib/src/       # Component implementations (naked_*.dart)
│   └── test/          # Unit + semantics tests
└── example/           # Demo app + integration tests
docs/                  # docs.page MDX files
.claude/semantics_reference.md  # IMPORTANT: Accessibility patterns
```

## Essential Commands

```bash
# Setup
dart pub global activate melos && melos bootstrap

# Development
cd packages/example && flutter run

# Testing
cd packages/naked_ui && flutter test
cd packages/example && flutter test -d flutter-tester integration_test/all_tests.dart

# CI checks
melos run format:check
flutter analyze
```

## Architecture

**Builder Pattern**: Every component provides state via builder:
```dart
NakedButton(
  onPressed: () {},
  builder: (context, state, child) => Container(
    color: state.when(pressed: Colors.blue.shade900, hovered: Colors.blue.shade700, orElse: Colors.blue),
    child: child,
  ),
  child: Text('Click'),
)
```

**State Classes**: `Naked{Component}State` extends `NakedState` with `isHovered`, `isFocused`, `isPressed`, `isDisabled`, `isSelected` and `state.when()` helper.

**Mixins**: `WidgetStatesMixin` (state management), `FocusNodeMixin` (focus lifecycle)

**Components**: Button, Checkbox, Radio, Toggle, Slider, TextField, Select, Tabs, Menu, Dialog, Popover, Tooltip, Accordion

## Naming Conventions

- Components: `Naked{Component}` (e.g., `NakedButton`)
- State: `Naked{Component}State`
- Callbacks: `on{Action}Change` (e.g., `onHoverChange`, `onFocusChange`)
- One widget per file, state class before widget class
- Exports via `naked_widgets.dart`

## Accessibility (CRITICAL)

**IMPORTANT**: This library prioritizes accessibility. See `.claude/semantics_reference.md` for full guide.

Key rules:
1. Set `excludeFromSemantics: true` on GestureDetector when parent Semantics provides actions
2. Place Semantics inside FocusableActionDetector
3. Use proper semantic flags (`button: true`, `checked:`, `toggled:`)
4. Test semantics parity with Material widgets

## Testing

- **Unit tests**: `test/src/` - component behavior
- **Semantics tests**: `test/semantics/` - accessibility parity with Material
- **Integration tests**: `example/integration_test/` - end-to-end

Always use `tester.ensureSemantics()` for semantics tests and dispose the handle.

## Commits & PRs

Follow [Conventional Commits](https://www.conventionalcommits.org/) (enforced by CI):
- `feat:` / `fix:` / `refactor:` / `docs:` / `test:` / `chore:`

## Adding a New Component

1. Create `lib/src/naked_{component}.dart` with `Naked{Component}State` + `Naked{Component}`
2. Use `WidgetStatesMixin` and `FocusNodeMixin`
3. Export in `naked_widgets.dart`
4. Add tests: `test/src/`, `test/semantics/`, `example/integration_test/components/`
5. Add example in `example/lib/api/`
6. Add docs in `docs/widget/`

## Key Files

- `lib/src/utilities/state.dart` - Base NakedState class
- `lib/src/mixins/naked_mixins.dart` - WidgetStatesMixin, FocusNodeMixin
- `.claude/semantics_reference.md` - Comprehensive accessibility guide
