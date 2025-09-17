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




