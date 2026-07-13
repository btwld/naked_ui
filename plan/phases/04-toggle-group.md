# Phase 04 — Toggle Group intent split and composite focus

Authority: **inactive research draft; not approved for implementation**.

Status: **D-01 awaits explicit approval; multiple selection also requires a
named consumer use case.**

Goal: make grouped toggles keyboard-coherent without turning one API into
Tabs, Radio Group, and a toggle toolbar at once. Preserve current single-select
source compatibility and semantics; add a multiple-toggle mode only for a
concrete Remix use case.

Planning baseline: `d341b90` on 2026-07-13. Contract source: briefing
[§14](../briefing.md#14-component-contract-toggle-group). Proposed refinement
is recorded in the approval-pending
[D-01 recommendation](../decisions.md#component-plan-research-recommendations-2026-07-13).
Approved cross-cutting D-19 governs SDK/API use if this phase is activated.

## Choose the semantic primitive first

| Product intent | Component | State semantics |
|---|---|---|
| Switch visible content | `NakedTabs` | tab/selected panel contract |
| Choose one form value | `NakedRadioGroup` | radio group/checked contract |
| Turn one or more commands/options on and off | `NakedToggleGroup` | button with toggle state for new multiple mode |
| Existing single segmented usage | Existing `NakedToggleGroup` | retain button + `selected` for compatibility |

Do not expose both `selected` and `toggled` on one option. Do not migrate the
existing unnamed constructor globally just to make single and multiple modes
look uniform; that would silently change screen-reader announcements.

## Reuse before new machinery

| Need | Reuse | Decision |
|---|---|---|
| Option interaction/state | Existing `NakedToggleGroup` / `NakedToggleOption` | Extend rather than create a second option family. |
| Focus model | `FocusNode`, `FocusTraversalGroup`, `Shortcuts`, `Actions` | Implement roving focus in package code. |
| Selection API reference | Material `SegmentedButton<T>` | Borrow controlled `Set<T>` invariants only; no Material dependency or styling. |
| Content/form semantics | Existing `NakedTabs` / `NakedRadioGroup` | Route consumers to the correct primitive. |
| True exclusive choice | Existing `NakedRadioGroup`, already backed by Flutter `RadioGroup`/`RawRadio` | Reuse for radio intent; `RawRadio` is not a base for toggle-button semantics. |
| [`shadcn_flutter` toggle/button group](../shadcn-flutter-reference.md#component-findings) | Manages individual boolean/visual state and connected borders, but has no composite roving-focus/semantics contract. | Behavior reference for controlled option visuals only; do not reuse group focus. |

The stable, beta, and master audit found no equivalent raw segmented-control
primitive. Cupertino's segmented controls and Material's `SegmentedButton` are
behavior/API references, not headless foundations. The existing radio layering
already uses Flutter's appropriate raw primitive; Toggle Group still owns its
distinct roving-focus/button contract. See the shared
[raw-primitives mapping](../flutter-raw-primitives.md#component-by-component-result).

## Semantics and interaction contract

| Question | Existing single mode | Future multiple mode |
|---|---|---|
| Option role/state | Button + `selected` | Button + `toggled` |
| Group label | Optional, announced once; explicit child nodes | Same |
| Selection | One controlled value; current no-clear behavior retained unless an explicit allow-empty API is approved | Controlled immutable set; activation adds/removes one value |
| Tab order | One group stop after the documented focus migration | One group stop |
| Arrows | Move focus only | Move focus only |
| Enter/Space | Activate focused option once | Toggle focused option once |
| Disabled | Skipped by roving focus, no action; selected state may remain visible | Same; selected input set is never mutated |

Horizontal arrows follow visual direction in RTL; vertical groups use Up/Down.
Home/End choose first/last enabled option. Loop behavior must be explicit.

## Ordered work

### 1. Audit the actual Remix stories

- Classify each proposed segmented/grouped control as content switcher, form
  choice, existing single segmented use, or independent toggle set.
- Migrate Tabs/Radio stories to those existing primitives in the consumer
  plan. Record at least one independent-toggle story before approving
  `NakedToggleGroup.multiple`.
- If no such story exists, complete the single-mode keyboard work only and
  stop; do not add speculative public API.

### 2. Lock compatibility and focus migration tests

- **Where:** `packages/naked_ui/test/src/naked_toggle_test.dart` and
  `packages/naked_ui/test/semantics/naked_toggle_semantics_test.dart`.
- Preserve the unnamed constructor, controlled selection, null-callback
  effective disabling, option callbacks/builders, and `selected` semantics.
- Add failing tests for one Tab stop, selected/last-focused/first-enabled entry
  priority, Tab exit, arrows, Home/End, loop on/off, disabled skip, all-disabled
  state, dynamic reorder/removal/disable, vertical orientation, and RTL.
- Changelog the independent-focus-to-roving-focus behavior change; it is not a
  source break but is observable keyboard behavior.

### 3. Implement one internal roving-focus model

- **Where:** `packages/naked_ui/lib/src/naked_toggle.dart` and, only if truly
  shared, a small utility under `packages/naked_ui/lib/src/utilities/`.
- Keep caller-owned option nodes caller-owned. Track option registration in
  visual order, retain the last valid target, and repair it synchronously after
  dynamic child changes without stealing page focus.
- Arrow navigation changes focus only. Activation emits one proposed value and
  waits for the controlled parent rebuild.
- Avoid depending on Material focus/selection internals.

### 4. Add multiple mode only after the gate

- Use a separate constructor with mutually exclusive value/callback
  invariants. Copy the input set before modification and expose an immutable
  result; equality is by content.
- Reuse the same options, roving model, enabled propagation, and builder state.
  Only the semantic state and controlled selection calculation differ.
- Do not add mixed/range selection, mandatory selection, or toolbar command
  semantics in this phase.

### 5. Prove semantics and real keyboard behavior

- Single mode must continue to announce its prior selected state; multiple
  mode must announce toggled state. Group label appears once and neither mode
  claims radio-group semantics.
- VoiceOver, TalkBack, and Chrome checks cover entry, arrow focus without
  selection, activation, disabled options, and both state vocabularies.
- Compare LTR/RTL visual-direction behavior to the Material reference without
  requiring pixel or internal implementation parity.

### 6. Add fixture, integration, and docs

- **Where:** `packages/example/lib/api/naked_toggle.0.dart`, registry,
  `packages/example/integration_test/components/naked_toggle_integration.dart`,
  aggregate runner, `docs/widget/toggle.mdx`, and changelog.
- Stable keys: `toggle-group.root`, `.option.bold`, `.option.italic`,
  `.option.underline`, `.value`, `.remove-focused`, and `.reset`.
- Include horizontal LTR/RTL, vertical with disabled middle option, dynamic
  removal, and multiple only if approved.
- Add a prominent “use Tabs / Radio / Toggle Group” decision table to docs.

## Planned visual evidence

- Screenshots: `toggle_group__roving_rtl__macos__reference.png` and
  `toggle_group__vertical_disabled__android__reference.png`.
- If multiple mode passes its gate, also capture
  `toggle_group__multiple_selected__android__reference.png`.
- Golden: `packages/example/test/goldens/components/baselines/naked_toggle_group__focus.png`.

## Verification

Run the workspace commands below plus every applicable exact-SDK command in
the [shared SDK matrix](../process.md#executable-sdk-and-local-command-matrix).

```sh
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test packages/naked_ui/test/src/naked_toggle_test.dart
fvm flutter test packages/naked_ui/test/semantics/naked_toggle_semantics_test.dart
fvm flutter test packages/naked_ui/test
fvm flutter test packages/example/test
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/components/naked_toggle_integration.dart
fvm flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```

Run real macOS, Android, pinned Chrome, VoiceOver, TalkBack, and release iOS per
[integration-testing.md](../integration-testing.md).

## Stop conditions

Block the focus migration if the group creates two page Tab stops, loses focus
on dynamic children, or changes selection on arrows. Do not add multiple mode
without a named consumer story. Redirect a story to Tabs or Radio Group if its
meaning requires those roles; API convenience is not a reason to ship the
wrong semantics.

## Acceptance

- [ ] Existing constructor and single-selection behavior remain compatible.
- [ ] The selected/toggled split is documented and never combined on one node.
- [ ] Roving focus passes orientation, RTL, disabled, loop, and dynamic-child cases.
- [ ] Arrows never select; Enter/Space emit once and controlled state remains controlled.
- [ ] Multiple mode has a concrete consumer and immutable-set tests, or is explicitly deferred.
- [ ] Example, docs, changelog, platform/AT evidence, and status board are current.

## Primary references

- [Flutter Material `SegmentedButton`](https://api.flutter.dev/flutter/material/SegmentedButton-class.html)
- [Flutter `FocusTraversalGroup`](https://api.flutter.dev/flutter/widgets/FocusTraversalGroup-class.html)
- [WAI-ARIA Toolbar Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/)
- [WAI-ARIA Tabs Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/)
