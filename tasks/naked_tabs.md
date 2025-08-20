## NakedTabs (Group/List/Tab/Panel) — API Parity Plan

- Material counterpart: TabBar + TabBarView (keyboard behavior aligned with WAI-ARIA Tabs)
- API completeness: Partial

### Current API Summary
- Group: selectedTabId, onSelectedTabIdChanged, orientation (Axis), enabled, onEscapePressed; provides NakedTabsScope
- List: manages set of registered tabs and arrow key navigation; encloses focus traversal group
- Tab: tabId, child, enabled, semantics (label/hint), cursor, haptic, focusNode/autofocus, excludeSemantics, controller; per-event callbacks; activation selects and requests focus
- Panel: tabId, maintainState; renders only when selected with optional preservation

### Gaps vs Material / WAI-ARIA
- Keyboard: lacks Home/End to jump to first/last; arrow keys should depend on orientation (Left/Right for horizontal; Up/Down for vertical)
- Roving focus model should ensure a single tabbable tab; others should be programmatically focusable via arrows
- Unified onStateChange missing for tabs

### Recommendations
- Add Home/End shortcuts; bind arrow keys conditioned by orientation
- Enforce roving tabindex semantics: only selected (or focused) tab tabbable; others removed from tab chain
- Do not introduce onStateChange; continue with stateController and/or per-event callbacks

### Migration Notes
- Backward compatible; primarily adds keyboard and state callback conveniences

### Test Plan
- Keyboard: arrow keys per orientation; Home/End; Escape handling; correct focus/selection transitions
- Semantics: selected state reflects scope selection; panel visibility/maintainState correctness

### Task Checklist
- [ ] Implement Home/End and orientation-aware arrow shortcuts
- [ ] Adjust focusability to roving tabindex pattern
- [ ] Add tests and docs for ARIA-aligned behavior (no onStateChange)


### State Controller Naming
- Rename controller parameter to stateController on NakedTab
- Type remains WidgetStatesController
- Update NakedInteractable/NakedFocusable to use stateController naming consistently
- Update docs/examples to reference stateController


### Removal Note
- If this component currently exposes an onStateChange callback on NakedTab, remove it from the public API
