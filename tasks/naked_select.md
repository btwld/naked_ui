## NakedSelect (+ Trigger/Item/Scope) — API Parity Plan

- Material counterpart: MenuAnchor/MenuItemButton (M3) and DropdownMenu patterns; web Material select patterns include type-ahead
- API completeness: Partial

### Current API Summary
- Select: single/multi modes, child trigger, menu (overlay), onOpen/onClose, selectedValue/selectedValues with callbacks, allowMultiple, enableTypeAhead with debounce, positioning + fallbacks, closeOnSelect, closeOnClickOutside, autofocus, excludeSemantics; overlay lifecycle callbacks
- Trigger: wraps NakedButton; per-event callbacks; cursor/focus/haptic; semantic label
- Item: value, onSelectChange(bool), per-event callbacks, enabled, focusNode/autofocus, semantics
- Scope: Inherited selection helpers (isSelected, selectedValue/s)

### Gaps vs Material
- Trigger keyboard behavior: Enter/Space/ArrowDown should open; currently handled mostly in overlay with type-ahead
- Menu: accelerators/shortcut labels not exposed; checkable roles require manual semantics
- Type-ahead: implemented in select state; consider applying to menu as well for parity where select is menu-based
- Unified onStateChange missing for Trigger/Item

### Recommendations
- Trigger: wire Shortcuts to open on Enter/Space/Down; ensure Escape closes when menu is open
- Menu focus: when opened with autofocus=true, move focus into first item; ensure closeOnClickOutside and Escape close
- Items: add optional accelerator label hook and checkable semantics helpers (selected, role)
- Do not introduce onStateChange; continue with stateController and/or per-event callbacks

### Migration Notes
- Backward compatible; adds keyboard affordances and optional hooks

### Test Plan
- Single vs multi selection flows; type-ahead selection
- Keyboard: opening/closing behavior, focus placement, Escape close
- Semantics: item selected, enabled/disabled; trigger announces label

### Task Checklist
- [ ] Add trigger keyboard bindings and Escape handling
- [ ] Autofocus menu content on open when configured
- [ ] Add accelerator/checkable hooks to items
- [ ] Add unit tests and docs for single/multi + type-ahead


### State Controller Naming
- Rename controller to stateController on Trigger and Item (and any internal usage)
- Ensure type is WidgetStatesController
- Update NakedInteractable/NakedFocusable signatures and calls to use stateController
- Update docs/examples to reference stateController


### Removal Note
- If this component currently exposes an onStateChange callback (Trigger or Item), remove it from the public API
