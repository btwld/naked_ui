## NakedAccordion (+ Item/Controller) — API Parity Plan

- Material counterpart: ExpansionTile/ExpansionPanelList
- API completeness: Partial

### Current API Summary
- Controller: min/max constraints; open/close/toggle/openAll/replaceAll/clear; values Set<T>
- Accordion: children (items), initialExpandedValues sync to controller
- Item: trigger builder(context, isExpanded), child, transitionBuilder, semantics, enabled, focus/hover/pressed callbacks, controller, haptic, cursor, focusNode/autofocus

### Gaps vs Material/WAI-ARIA Disclosure
- Keyboard: no Home/End between items; activation present via NakedInteractable
- Unified onStateChange missing for items
- Tests for controller constraints/semantics coverage

### Recommendations
- Add optional Home/End navigation; ensure ActivateIntent toggles
- Do not introduce onStateChange; continue with stateController and/or per-event callbacks
- Expand tests for min/max constraints and semantics.expandable states/hints

### Migration Notes
- Backward compatible additions

### Test Plan
- Keyboard nav (Home/End), activation toggling
- Controller min/max behavior edge cases
- Semantics: expanded state and hints update correctly

### Task Checklist
- [ ] Implement Home/End navigation
- [ ] Add tests for constraints and semantics
- [ ] Update docs (usage/transitionBuilder/controller)


### State Controller Naming
- Rename controller parameter to stateController on NakedAccordionItem
- Type remains WidgetStatesController
- Update NakedInteractable/NakedFocusable to use stateController naming; update docs/examples


### Removal Note
- If this component currently exposes an onStateChange callback on NakedAccordionItem, remove it from the public API
