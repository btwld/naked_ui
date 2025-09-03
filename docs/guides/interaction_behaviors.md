## Interaction architecture refactor

### Goals

- **Simplicity**: Move low-level event wiring into tiny, atomic detectors and keep one behavior layer per pattern.
- **Composability**: Use detectors as building blocks; keep selection/error at component level.
- **Maintainability**: Centralize keyboard, haptics, and semantics in behavior wrappers instead of per component.

---

## Atomic behaviors

### FocusBehavior
- **Purpose**: Manage `FocusNode` lifecycle and report focus changes.
- **API**:
  - `child: Widget`
  - `focusNode?: FocusNode`
  - `autofocus: bool`
  - `onFocusChange?: ValueChanged<bool>`

### HoverBehavior
- **Purpose**: Emit hover enter/exit via `MouseRegion` (mouse/stylus only).
- **API**:
  - `child: Widget`
  - `cursor: MouseCursor = MouseCursor.defer`
  - `onHoverChange?: ValueChanged<bool>`

### PressBehavior
- **Purpose**: Track pressed state changes with proper drag-out clearing.
- **API**:
  - `child: Widget`
  - `behavior: HitTestBehavior = HitTestBehavior.opaque`
  - `onPressChange?: ValueChanged<bool>`

Notes:
- Touch does not trigger hover; `PressBehavior` must not rely on hover for down detection.
- Composition order for consistent hit testing inside composites: Press (inner) → Hover → Focus (outer).

---

## InteractiveBehavior

InteractiveBehavior composes the three atomic behaviors and manages enabled/disabled propagation. It is headless and does not expose a `{states}` builder or an aggregated `onStateChange`.

### API
- `child: Widget`
- `enabled: bool = true`
- `focusNode?: FocusNode`
- `autofocus: bool = false`
- `cursor: MouseCursor = MouseCursor.defer`
- `behavior: HitTestBehavior = HitTestBehavior.opaque`
- `onFocusChange?: ValueChanged<bool>`
- `onHoverChange?: ValueChanged<bool>`
- `onPressChange?: ValueChanged<bool>`

### Behavior
- Hierarchy: `IgnorePointer(ignoring: !enabled)` → `FocusBehavior` → `HoverBehavior` → `PressBehavior` → `child`.
- When disabled, callbacks are not invoked; transient states should be considered cleared by the behavior wrappers that own state.

---

## InteractionController

An optional controller for programmatic state changes, primarily to support keyboard activation "press flash" without pointer events.

### API (proposal)
```dart
class InteractionController {
  void setFocused(bool value);
  void setHovered(bool value);
  void setPressed(bool value);
  Future<void> pressFlash(Duration duration = const Duration(milliseconds: 100));
  void clearTransient(); // focused, hovered, pressed → false
  void dispose();
}
```

Usage: Owned by behavior wrappers; not required by `InteractiveDetector` directly.

---

## Behavior layer

Single-responsibility wrappers that own the `Set<WidgetState>` and provide a builder. They consume `InteractiveDetector` and wire keyboard, haptics, cursor, and semantics.

### Common patterns

- Maintain an internal `Set<WidgetState>` and expose it only via the behavior builder.
- Update `WidgetState.focused/hovered/pressed` from detector callbacks.
- Clear transient states on disable.
- Provide Shortcuts/Actions for keyboard activation where relevant.
- Centralize haptic feedback policy.
- Provide semantics roles/attributes consistently.

### ButtonBehavior

Purpose: Headless button behavior used by `NakedButton`, `NakedMenuItem`, etc.

API:
```dart
class ButtonBehavior extends StatelessWidget {
  const ButtonBehavior({
    required this.enabled,
    this.onPressed,
    this.onDoubleTap,
    this.onLongPress,
    this.onPressChange,
    this.onFocusChange,
    this.onHoverChange,
    this.mouseCursor,
    this.disabledMouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.enableFeedback = true,
    required this.builder, // ValueWidgetBuilder<Set<WidgetState>>
    this.child,
    this.focusOnPress = false,
  });
}
```

Responsibilities:
- Keyboard activation via Shortcuts/Actions (Enter/Space):
  - Use `InteractionController.pressFlash(100ms)` for visual feedback.
  - Call `_handleOnSelect()` after setting pressed true; then clear, which in turn calls `onPressed`.
- Gesture activation via `GestureDetector`:
  - `onTap` → `_handleOnSelect()` → `onPressed`
  - `onLongPress` → callback + platform haptic
  - `onDoubleTap` → callback
- Cursor selection based on `enabled`.
- Semantics: `button: true`, `enabled: enabled`, `focusable: enabled`, `onTap: onPressed`.
- Optional `focusOnPress`: request focus on tap if provided.

Internal naming: use `_handleOnSelect()` for the central activation path (called by both keyboard and pointer flows).

### ToggleBehavior

Purpose: Centralize toggle semantics/keyboard/haptics for checkbox/radio/switch.

API:
```dart
enum ToggleRole { checkbox, radio, switchRole }

class ToggleBehavior<T> extends StatelessWidget {
  const ToggleBehavior({
    required this.enabled,
    required this.role,
    required this.isSelected, // bool for checkbox/switch; radio computes from group
    this.tristate = false, // checkbox only
    this.toggleable = false, // radio optional
    this.onSelect, // void Function() – computes next value in parent
    this.onChanged, // optional value-carrying callback
    this.onPressChange,
    this.onFocusChange,
    this.onHoverChange,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.enableFeedback = true,
    required this.builder,
    this.child,
  });
}
```

Responsibilities:
- Central activation path `_handleOnSelect()` used by keyboard and pointer.
- Keyboard Shortcuts/Actions (Enter/Space) trigger `_handleOnSelect()` with pressed flash.
- Semantics mapping:
  - Checkbox: `checked`, `mixed` (when tristate and null), `onTap` toggles.
  - Radio: `checked`, `inMutuallyExclusiveGroup: true`, `onTap` selects/deselects per `toggleable`.
  - Switch: `checked`, `onTap` toggles.
- Haptics: use selection-click on state changes.
- Cursor: clickable when `enabled`, forbidden when disabled.

Value flow options:
- Simple mode: parent computes next value (esp. for radio/checkbox tri-state) and calls `onChanged(next)`; `ToggleBehavior` invokes `onSelect()` only.
- Enhanced mode: pass `onChanged` to let behavior emit values; still prefer letting the component compute group/tri-state rules to avoid duplication.

### Composition details

- Both behaviors wrap visuals with `InteractiveBehavior` and a `Shortcuts`/`Actions` scope.
- They own an `InteractionController` for pressed flash.
- They expose `builder(context, states, child)`; only behaviors expose state sets.
- `InteractiveBehavior` stays headless and does not expose a states builder.

---

## Component mapping

- `NakedButton`: implemented with `ButtonBehavior`.
- `NakedMenuItem`: implemented with `ButtonBehavior`.
- `NakedCheckbox`: implemented with `ToggleBehavior` (use tri-state rules in component; call `_handleOnSelect()` which computes next value and calls `onChanged`).
- `NakedRadio`: implemented with `ToggleBehavior`:
  - Determine `isSelected` from group registry; `_handleOnSelect()` applies `toggleable` logic and calls group `onChanged` appropriately.
- `NakedSlider`: keep specialized drag/keyboard/semantics; optionally use `FocusDetector`/`HoverDetector` only.
- `NakedTextField`: keep existing implementation; do not wrap `EditableText` with `PressDetector`.

---

## Event flow and edge cases

- Pointer down inside → pressed true → drag out clears pressed on boundary exit.
- Hover only on hover-capable devices; touch never sets hover.
- Keyboard activation:
  - On Enter/Space: set pressed true (flash), call activation, then clear pressed after ~100ms.
  - Focus remains unchanged unless `focusOnPress` is true.
- Disabled transitions:
  - On disable: clear focused/hovered/pressed; optionally unfocus via `focusNode?.unfocus()` at behavior wrapper level.

---

## API naming notes

- Use `_handleOnSelect()` internally for the central activation path in both `ButtonBehavior` and `ToggleBehavior`.
- Public callbacks:
  - Button: `onPressed`, `onPressChange`, `onFocusChange`, `onHoverChange`.
  - Toggle: `onSelect` (no-arg) and/or `onChanged(value)` depending on component preference; plus state-change callbacks.

---

## Migration checklist

- Create primitives: `FocusDetector`, `HoverDetector`, `PressDetector`.
- Replace `NakedInteractable` usages in `NakedPressable` internals with `InteractiveDetector` (or replace `NakedPressable` with `ButtonBehavior`).
- Implement `InteractionController` and use it inside behaviors.
- Implement `ButtonBehavior`; migrate `NakedButton` and `NakedMenuItem`.
- Implement `ToggleBehavior`; migrate `NakedCheckbox` and `NakedRadio`.
- Keep `NakedSlider` and `NakedTextField` logic as-is; optionally adopt `FocusDetector`/`HoverDetector` where appropriate.
- Remove `onStateChange` and builder from `InteractiveDetector`; keep only granular callbacks.
- Ensure semantics parity and keyboard shortcuts in behaviors.
- Add unit/integration tests for pressed flash, hover, focus, keyboard activation, tristate cycling, radio toggleable behavior.

---

## Future considerations

- Add `pressFlash` duration customization on behaviors for theme parity.
- Consider exposing a public `InteractionController` for advanced composition use cases.
- Explore RTL-specific shortcut mapping centralization where needed.


