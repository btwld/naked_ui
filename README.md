# naked_ui

Behavior-first Flutter components with no visual styling. `naked_ui` supplies interaction, focus, keyboard, overlay, and accessibility behavior while your builder supplies the design.

## Requirements

- Flutter 3.41 or newer
- Dart 3.11 or newer

Install and import the package:

```sh
flutter pub add naked_ui
```

```dart
import 'package:naked_ui/naked_ui.dart';
```

## Components

| Component | Behavior provided |
| --- | --- |
| `NakedButton` | Tap, long press, hover, focus, keyboard activation |
| `NakedCheckbox` | Boolean or tristate selection |
| `NakedRadio` | Radio selection through Flutter's `RadioGroup` |
| `NakedToggle` | Toggle-button or switch behavior |
| `NakedToggleGroup` | Single-selection option group |
| `NakedSlider` | Continuous or discrete drag and keyboard input |
| `NakedTextField` | Builder-first text editing on `EditableText` |
| `NakedTabs` | Tab roles, roving focus, and panel visibility |
| `NakedAccordion` | Constrained expandable sections |
| `NakedMenu` | Anchored action menu |
| `NakedSelect` | Anchored single-selection menu |
| `NakedPopover` | Anchored dismissible overlay |
| `NakedTooltip` | Hover and long-press tooltip lifecycle |
| `NakedDialog` | Modal route, focus traversal, and dialog semantics |

## Builder pattern

Builders receive an immutable state snapshot. Use it to style interaction states without coupling behavior to a design system.

```dart
NakedButton(
  onPressed: save,
  semanticLabel: 'Save',
  builder: (context, state, child) {
    final color = state.when(
      disabled: Colors.grey,
      pressed: Colors.blue.shade900,
      hovered: Colors.blue.shade700,
      focused: Colors.blue.shade600,
      orElse: Colors.blue,
    );

    return ColoredBox(
      color: color,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Save'),
      ),
    );
  },
)
```

Every component state extends `NakedState` and exposes the raw `WidgetState` set plus helpers such as `isHovered`, `isFocused`, `isPressed`, `isSelected`, and `when`.

## Controlled values

Selection components are controlled: pass the current value and commit changes in the callback.

```dart
NakedCheckbox(
  value: checked,
  onChanged: (value) => setState(() => checked = value ?? false),
  builder: (context, state, child) => MyCheckboxVisual(
    checked: state.isChecked,
    focused: state.isFocused,
  ),
)
```

Overlays use Flutter's `MenuController` where programmatic control is part of the contract:

```dart
final menuController = MenuController();

NakedMenu<String>(
  controller: menuController,
  onSelected: handleMenuAction,
  builder: (context, state, child) => Text(
    state.isOpen ? 'Close actions' : 'Open actions',
  ),
  overlayBuilder: (context, info) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      NakedMenuItem<String>(value: 'edit', child: Text('Edit')),
      NakedMenuItem<String>(value: 'delete', child: Text('Delete')),
    ],
  ),
)
```

`NakedMenuItem` and `NakedSelectOption` must be built inside their owner's overlay builder. Misplaced items fail with a descriptive `FlutterError`.

## Accessibility contract

Components expose roles, state, values, and actions through Flutter semantics by default.

- When `semanticLabel` is null, visible child semantics provide the accessible name.
- A non-null `semanticLabel` replaces descendant naming semantics to avoid duplicate announcements.
- `excludeSemantics: true` omits semantics contributed by the Naked component while preserving semantics supplied by your child or builder.
- Disabled controls expose disabled state and no activation action.
- Menus, options, tabs, panels, dialogs, sliders, text fields, toggles, and disclosure controls expose component-appropriate roles and states.

If you use `excludeSemantics`, your custom subtree is responsible for a complete accessible contract.

## Development

The repository pins Flutter with FVM:

```sh
fvm flutter pub get
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze --fatal-infos --fatal-warnings
fvm flutter test packages/naked_ui/test
fvm flutter test packages/example/test
```

Run the integration suite from the example package with:

```sh
cd packages/example
fvm flutter test integration_test/all_tests.dart -d flutter-tester
```

API guides and additional examples are available at [docs.page/btwld/naked_ui](https://docs.page/btwld/naked_ui).
