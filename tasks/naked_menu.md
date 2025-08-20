## NakedMenu (+ Item) — API Parity Plan

- Material counterpart: MenuAnchor/MenuItemButton/SubmenuButton
- API completeness: Partial

### Current API Summary
- Menu: builder (trigger), overlayBuilder (content), controller (MenuController), onClose, consumeOutsideTaps, useRootOverlay, closeOnSelect, autofocus (commented as no effect), menuPosition + fallback, keyboard shortcuts routed by NakedMenuAnchor
- Item: child, onPressed, enabled, semanticLabel/hint, excludeSemantics, cursor, haptic, focusNode/autofocus, per-event callbacks, controller

### Gaps vs Material
- Submenus not supported; keyboard routing for nested menus absent
- Accelerators/shortcut labels not exposed; checkable/selected helper semantics missing
- autofocus flag currently “no effect”
- Optional: type-ahead inside menu

### Recommendations
- Implement submenu support: nested NakedMenuAnchor and directional positioning; manage keyboard traversal with arrow-left/right semantics
- Add accelerator label and checkable helpers on NakedMenuItem (semantics: checked/role)
- Make autofocus effective: focus first item when opened; ensure Escape closes
- Consider type-ahead within menu list to jump items
- Do not introduce onStateChange; continue with stateController and/or per-event callbacks

### Migration Notes
- Additive features; no breaking changes if defaults preserved

### Test Plan
- Outside tap consumption; Escape to close; fallback positions; keyboard traversal including nested submenus
- Item semantics for checked/accelerators

### Task Checklist
- [ ] Submenu implementation with keyboard routing
- [ ] Accelerator/checkable hooks
- [ ] Effective autofocus + Escape closing
- [ ] Tests and docs for composition patterns (no onStateChange)


### State Controller Naming
- Rename controller parameter to stateController on NakedMenuItem (and any interactive wrappers)
- Type remains WidgetStatesController
- Update NakedInteractable/NakedFocusable code paths and examples


### Removal Note
- If this component currently exposes an onStateChange callback on NakedMenuItem, remove it from the public API
