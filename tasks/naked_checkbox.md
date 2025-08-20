## NakedCheckbox — API Parity Plan

- Material counterpart: Checkbox
- API completeness: Partial (nearly complete behavior)

### Current API Summary
- Props: child (visual), value bool?, tristate, onChanged(bool?), enabled, semanticLabel/hint, cursor, enableHapticFeedback, focusNode, autofocus, excludeSemantics, controller
- Interaction callbacks: onFocusChange, onHoverChange, onHighlightChanged
- Semantics: NakedSemantics.checkbox (checked/mixed/focusable mapping)
- Press behavior: cycles among false → true → (null if tristate) → false

### Gaps vs Material
- Test coverage for keyboard activation and semantics completeness

### Recommendations
- Do not introduce onStateChange; continue using stateController and/or per-event callbacks
- Confirm and document keyboard activation (ActivateIntent) parity; verify semantics for tristate including mixed state

### Migration Notes
- Keep existing per-event callbacks/stateController usage; no onStateChange

### Test Plan
- Toggle cycles for tristate and non-tristate
- Keyboard Space/Enter activate toggle when enabled; no action when disabled
- Semantics: checked/null/mixed mapping, focusable when enabled

### Task Checklist
- [ ] Add tests for keyboard activation and semantics
- [ ] Update docs/examples for stateController usage


### State Controller Naming
- Rename controller parameter to stateController
- Ensure type remains WidgetStatesController
- Update NakedInteractable/NakedFocusable references accordingly
- Update docs/examples to reference stateController


### Removal Note
- If this component currently exposes an onStateChange callback, remove it from the public API
