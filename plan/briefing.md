<!--
Verbatim handoff briefing received 2026-07-12. Treat as the frozen reference
contract: do NOT edit component contracts here. Living state belongs in
plan/README.md (status) and plan/decisions.md (decision resolutions).
Factual claims were verified against this repo at commit 0ca0b8b on 2026-07-12
(see plan/README.md "Verification record").
-->

# Naked UI component expansion: engineering briefing and handoff

**Status:** Proposed implementation contract and delivery package  
**Audience:** Naked UI maintainers, Remix maintainers, accessibility reviewers, and QA  
**Prepared:** 2026-07-11  
**Primary consumer:** Remix for Flutter  

## 1. Purpose

This document defines the work Naked UI should complete before Remix adds the next high-value headless primitives. It is intentionally more specific than a component wish list. It describes:

- the behavior Naked UI must own;
- the behavior that must remain in the styled Remix layer;
- proposed public APIs and compatibility constraints;
- the semantics, focus, keyboard, pointer, and localization contract;
- widget, semantics, integration, accessibility-guideline, golden, screenshot, and manual assistive-technology evidence;
- a component-by-component acceptance checklist;
- the CI and handoff package required before Remix consumes a release.

The goal is not merely to make eight widgets render. The goal is to make them dependable primitives that another design system can style without having to repair interaction or accessibility behavior.

## 2. Verification basis

The findings and proposals below were checked against these concrete baselines on 2026-07-11.

| Surface | Verified baseline | Why it matters |
|---|---|---|
| Remix workspace | Local HEAD <code>250178041</code>; target baseline <code>origin/chore/1.0-release@be5c17f3a</code> | Establishes the consumer code inspected for this handoff. |
| Remix dependency | <code>packages/remix/pubspec.yaml</code> declares <code>naked_ui: ^0.2.0-beta.7</code> | Remix is not yet consuming the current Naked UI main API. |
| Remix SDK contract | Dart <code>>=3.12.0</code>, Flutter <code>>=3.44.0</code>; workspace <code>.fvmrc</code> is Flutter 3.44.0 | Consumer verification must use its configured SDK even if Naked UI supports an older minimum. |
| Naked UI upstream | <code>btwld/naked_ui@0ca0b8bc2269ed331345cc705d99a073acdf5f5f</code> | Pins all upstream code and CI observations in this document. |
| Naked UI package | <code>1.0.0-beta.3</code>, Dart <code>>=3.9.0</code>, Flutter <code>>=3.41.0</code> | New APIs should remain compatible with the package minimum unless the maintainers explicitly raise it. |
| Naked UI CI SDK | Flutter 3.41.2 | This is the current pinned CI environment. It does not by itself prove the declared Flutter 3.41.0 minimum. |
| Local Flutter used for API inspection | Flutter 3.41.2 / Dart 3.11.0 | Confirms the named semantics APIs exist at the current Naked UI CI version. |

External behavior was cross-checked with Flutter's official accessibility, focus, semantics, golden, and integration-test documentation; W3C WAI-ARIA Authoring Practices and WCAG 2.2 guidance; and the documented behavior of Radix and Base UI primitives. The source register is in section 25.

### 2.1 Confirmed facts versus proposals

To avoid presenting design choices as existing behavior:

- **Confirmed** means observed in the pinned Remix or Naked UI source, its tests, its CI, the Flutter 3.41.2 SDK, or linked official documentation.
- **Proposed** means the recommended contract for the Naked UI team. Public names can be adjusted during API review, but the observable behavior and acceptance gates should not silently change.
- **Open decision** means the team must explicitly resolve the item before the relevant implementation PR is approved.

## 3. Executive decision

Naked UI should implement or expand these eight items:

1. Alert Dialog support by extending <code>NakedDialog</code>.
2. A context-menu trigger that reuses Naked menu items and overlay infrastructure.
3. A complete Toggle Group with roving focus, orientation, looping, RTL, and multiple selection.
4. Toast controller, viewport, item lifecycle, announcement semantics, and focus behavior.
5. Field composition and validation semantics around controls such as <code>NakedTextField</code>.
6. An editable Combobox, including single and multiple selection foundations.
7. A non-interactive Hover Card / Preview Card.
8. A Link primitive with correct link semantics and keyboard behavior.

These are behavior primitives, not Remix visual components. Naked UI should not absorb Remix tokens, Mix styles, colors, typography, radii, shadows, padding, animation curves chosen for a theme, or product copy.

### 3.1 Items Remix can build without new Naked UI primitives

The following nearby Remix gaps should not be added to Naked UI as new primitives:

| Remix item | Naked UI dependency decision |
|---|---|
| Popover | Current Naked UI main already has <code>NakedPopover</code>. Remix should upgrade and compose it. |
| Basic single-select segmented control | Current main already has <code>NakedToggleGroup</code> and <code>NakedToggleOption</code>. Remix can prototype with them, but production parity needs the enhancements in section 14. |
| Drawer / Sheet | Compose <code>NakedDialog</code> with Remix-owned placement and motion. Only generic dialog behavior belongs in Naked UI. |
| Skeleton | Purely visual loading placeholder. Remix owns it. Decorative skeletons should normally be excluded from semantics while nearby content exposes the loading state. |
| Basic Scroll Area | Use Flutter scrolling primitives. Add Naked UI behavior only if a later scope requires custom scrollbar interaction or a cross-design-system scroll contract. |

### 3.2 Naked UI work map

Complexity is relative and is not a calendar estimate.

| Item | Work type | Remix need | Priority | Relative complexity | Primary dependency/risk |
|---|---|---|---|---|---|
| Alert Dialog | Extend Dialog | Safe destructive/urgent confirmations | P0 | Small | Semantic role, mandatory focus entry, inert default barrier, safe cancellation |
| Link | New primitive | Foundational inline navigation and Hover Card trigger | P0 | Small | Correct link rather than button behavior |
| Field | New composition + TextField integration | Consistent labels, descriptions, required/invalid/error behavior | P0 | Large | Avoiding duplicate semantics and preserving TextField compatibility |
| Toggle Group | Expand existing group | Segmented/content-switcher and grouped formatting controls | P0 | Large | Roving focus, RTL, single/multiple semantics compatibility |
| Context Menu | New trigger over Menu infrastructure | Pointer/touch/keyboard contextual actions | P1 | Large | Point anchoring, non-button trigger semantics, focus restoration |
| Toast | New controller/viewport/item family | Transient status and safe-action feedback | P1 | Extra large | Queue/timers, focus pause, one-time announcements |
| Hover Card | New preview overlay | Rich visual link previews | P1 | Large | Pointer grace, WCAG hover/focus behavior, semantics exclusion |
| Combobox | New editable composite | Searchable single/multiple selection | P2 until spike passes | Extra extra large | Flutter role mapping, active-option announcements, IME/editing integrity |

P0 means a foundational primitive or prerequisite for other work. P1 means high-value follow-on work. Combobox is P2 only because its platform accessibility uncertainty should be resolved before implementation scale grows; its product value remains high.

## 4. Why this work belongs in Naked UI

The eight proposed items contain reusable interaction rules that are easy for styled libraries to implement inconsistently:

- focus entry, containment, restoration, and traversal;
- keyboard activation and composite-widget navigation;
- pointer and touch gesture normalization;
- overlay positioning, collision handling, and dismissal;
- enabled, selected, highlighted, open, invalid, and timed lifecycle state;
- screen-reader role, name, value, state, action, and announcement behavior;
- deterministic timers and app-lifecycle pausing;
- platform and text-direction differences.

If each Remix theme reimplements these rules, semantic and keyboard behavior can drift while screenshots still look correct. Naked UI should centralize those rules and expose observable state so Remix can remain responsible for presentation.

## 5. Definition of the headless boundary

### 5.1 Naked UI owns

- Controlled and uncontrolled behavior only where the API explicitly promises it.
- Focus nodes it creates internally, including disposal and debug labels.
- Focus entry, traversal, escape behavior, and restoration.
- Shortcuts, intents, actions, pointer gestures, and touch gestures.
- Overlay open/close lifecycle and collision-safe anchors.
- Semantics nodes, roles/flags, values, actions, grouping, and announcement priority.
- Enabled-state propagation and suppression of actions when disabled.
- Interaction snapshots exposed to builders and <code>NakedStateScope</code>.
- Timer state, pause/resume behavior, and deterministic disposal.
- Directionality-sensitive keyboard behavior.
- Public documentation of every observable invariant.

### 5.2 Remix or another styled consumer owns

- Color, typography, spacing, size, border, radius, elevation, shadow, and icon choices.
- The visible focus-ring design, while Naked UI exposes focused state.
- Product language and localized user-facing strings.
- Navigation implementation and URL launching.
- Filtering algorithms, remote search, data fetching, caching, and business rules.
- Business validation rules and when a form chooses to reveal an error.
- Responsive layout and component-specific animation styling.
- The final visual target sizes and contrast ratios.

### 5.3 Canonical example app owns test presentation

Naked UI's example application should provide one deterministic reference style for every primitive. That style is test infrastructure, not a package default. It exists so real-device integration tests, accessibility guidelines, goldens, and screenshot review have a stable visible surface.

This distinction is essential:

- core Naked UI tests prove semantics and behavior;
- canonical example tests prove a representative styled integration;
- Remix tests prove Remix's actual styles;
- screenshots never substitute for a semantics assertion or screen-reader check.

## 6. Current upstream strengths and gaps

### 6.1 Confirmed strengths

At the pinned upstream commit:

- Naked UI has 498 widget tests under <code>packages/naked_ui/test</code>.
- It has dedicated semantics tests for all 13 currently integrated components plus semantics utilities.
- Semantics tests use <code>tester.ensureSemantics()</code>, inspect node data, and in several cases compare behavior with Flutter Material widgets.
- There are 89 example integration <code>testWidgets</code> cases across component files.
- Existing components follow a useful builder-first pattern and expose immutable state snapshots.
- Dialog, menu, popover, select, tabs, text field, tooltip, and other primitives already provide reusable foundations for this work.

### 6.2 Confirmed delivery gaps to fix before adding the new suite

| Gap | Evidence at the pinned commit | Required correction |
|---|---|---|
| “macOS integration” does not exercise macOS | The workflow runs on a macOS runner but invokes <code>-d flutter-tester</code>. | Add or generate macOS platform files and run <code>-d macos</code>. Keep a separate flutter-tester smoke job if useful. |
| Android is not a PR gate | Android integration is <code>workflow_dispatch</code> only. | Run affected component tests on PRs or at minimum nightly, with release branches gated on a passing run. |
| No web integration gate | No web integration workflow exists. | Add Chrome/ChromeDriver coverage for semantics DOM and keyboard-critical flows. |
| No screenshot evidence | No <code>takeScreenshot</code> usage was found. | Capture named screenshots for every required component state and upload artifacts. |
| No golden coverage | No <code>matchesGoldenFile</code> usage was found. | Add pinned, deterministic example goldens for layout/state regression. |
| No accessibility-guideline coverage | No <code>meetsGuideline</code> calls were found. | Run label, tap-target, and contrast checks on the canonical styled examples. |
| Keyboard helper can hide failure | <code>testKeyboardActivation</code> catches exceptions and returns false; callers can ignore the result. | Remove catch-and-continue behavior. A failed key event or unmet postcondition must fail the test. |
| Tab-order helper does not prove focus | <code>verifyTabOrder</code> verifies only that widgets exist after advancing focus. | Assert <code>FocusManager.instance.primaryFocus</code> or each managed node's <code>hasFocus</code> after every step. |
| Stale runner path | <code>tool/run_integration_all.sh</code> enters <code>example/</code>, while the app lives at <code>packages/example/</code>. | Repair the runner and add a CI smoke invocation so path drift fails early. |
| Broad settling can hang or conceal timing errors | Existing integration tests use <code>pumpAndSettle()</code> extensively. | Use targeted pumps and observable postconditions for timers and continuing animations, especially Toast and Hover Card. |
| Coverage threshold is advisory | The 80% coverage report has <code>continue-on-error</code> and documents a much lower current value. | Do not use the displayed threshold as proof. Add component-level acceptance coverage and make the agreed gate blocking. |
| Declared minimum is not tested exactly | The package allows Flutter 3.41.0 while CI pins 3.41.2. | Add an exact-minimum analysis/unit/semantics job or raise the package minimum deliberately. |

The infrastructure corrections should be delivered first or in the first component PR. Otherwise the new work could appear green without proving the behavior this handoff requires.

## 7. Delivery sequence and pull-request boundaries

Use small, reviewable PRs with one behavior contract at a time. Recommended order:

| Order | PR | Dependency or reason |
|---:|---|---|
| 0 | Test-harness hardening | Prevents false-positive keyboard and platform integration results for all later work. |
| 1 | Alert Dialog role and helper | Small additive extension that validates the new semantics process. |
| 2 | Naked Link | Small standalone primitive and a dependency for Hover Card examples. |
| 3 | Naked Field plus <code>NakedTextField</code> integration | Establishes validation semantics used by Combobox. |
| 4 | Toggle Group expansion | Exercises composite focus and RTL without an overlay. |
| 5 | Context Menu | Reuses menu item and overlay infrastructure; may require an internal menu-scope refactor. |
| 6 | Toast | Introduces deterministic timers, status announcements, and screenshot lifecycle coverage. |
| 7 | Hover Card | Reuses Link and overlay timing foundations. |
| 8 | Combobox | Highest-risk composite; builds on Field, TextField, overlay, option, and focus patterns. |

Each PR should remain releasable. Internal refactors must preserve current public behavior and keep the existing suite green.

## 8. Required implementation process

The following process applies to every component PR.

### Phase A — contract and threat-model review

1. Copy the relevant component section from this document into the issue or PR.
2. Confirm the public API, controlled state, ownership, disabled behavior, and localization inputs.
3. Write the component semantics matrix before implementation.
4. List every input path: mouse, touch, stylus if relevant, keyboard, switch access/semantics action, and programmatic controller.
5. List focus entry, internal traversal, dismissal, and restoration behavior.
6. Identify continuous animation or timer behavior that makes <code>pumpAndSettle()</code> unsafe.
7. Record any Flutter engine limitation instead of hiding it behind a passing widget test.

### Phase B — write failing tests

Add failing tests in this order:

1. Constructor assertions and controlled-state invariants.
2. Builder snapshot and <code>NakedStateScope</code> behavior.
3. Pointer/touch activation and disabled behavior.
4. Keyboard and focus behavior.
5. Semantics role, name, state, value, actions, grouping, and disabled behavior.
6. Overlay collision and dismissal where applicable.
7. Timer and lifecycle behavior where applicable.
8. Regression cases for disposal, rebuild, and dynamic child changes.

The test must fail for the intended missing behavior, not for a harness or fixture error.

### Phase C — implement the smallest behavior surface

- Follow existing <code>NakedState</code>, builder, scope, and effective-enabled conventions.
- Prefer Flutter <code>Shortcuts</code>, <code>Actions</code>, <code>Focus</code>, and traversal policies over raw key handlers.
- Use long-lived focus nodes in State objects; dispose only nodes the widget owns.
- Make delays and durations injectable.
- Do not hard-code English semantics labels, shortcut labels, or dismissal text.
- Keep styles out of the package implementation.

### Phase D — add a deterministic example fixture

Every fixture must:

- use stable <code>ValueKey</code> identifiers for triggers, controls, options, actions, status labels, and observable state output;
- use local data and no network;
- expose a visible state readout where useful;
- allow animations to be disabled or given fixed durations;
- render inside a fixed, documented viewport for goldens;
- include RTL and large-text variants when required;
- have reset behavior so tests do not depend on execution order.

### Phase E — prove integration and visuals

1. Run the component test on <code>flutter-tester</code> for fast feedback.
2. Run on a real macOS target.
3. Run the mobile-relevant paths on Android.
4. Run keyboard and semantics-DOM paths on web.
5. Capture all screenshots listed in the component section.
6. Compare the pinned widget goldens.
7. Run accessibility guidelines against the canonical example.
8. Perform the manual assistive-technology checks.

### Phase F — prepare the handoff packet

The PR cannot be handed to Remix with only a green checkmark. It must include the evidence package in section 22.

## 9. Cross-component API conventions

### 9.1 Builder and child contract

- Follow the current Naked UI invariant that either <code>child</code> or <code>builder</code> is present when a visual surface is required.
- A builder receives an immutable state snapshot and the optional child.
- The same state snapshot must be available through <code>NakedStateScope</code> inside the built subtree.
- State equality and <code>hashCode</code> must include every public observable field.
- Rebuilding with an equivalent state must not create timer, focus, or overlay churn.

### 9.2 Controlled state

- Selection, query, validity, and open state must be explicitly documented as controlled or controller-owned.
- A callback being null must never mutate an allegedly controlled value.
- Callbacks fire once per accepted user action and do not fire for disabled items, repeated selection when no change occurs, or a canceled gesture.
- Multiple-selection callbacks return an immutable snapshot rather than a mutable set retained internally.

### 9.3 Controller ownership

- External controllers and focus nodes are never disposed by Naked UI.
- Internal controllers, timers, listeners, and focus nodes are always disposed.
- Replacing an external controller detaches all listeners from the old controller.
- Controllers reject or safely ignore calls after disposal according to a documented policy.
- Every internally created focus node has a useful <code>debugLabel</code>.

### 9.4 Effective enabled state

Compute effective enabled state from both the explicit <code>enabled</code> flag and the presence of the callback/controller capability required for activation. When disabled:

- no pointer, keyboard, or semantic action changes state;
- no feedback is emitted;
- the node is removed from normal focus traversal;
- semantics expose disabled state when the control remains discoverable;
- the mouse cursor is not an activation cursor;
- descendants cannot accidentally reactivate behavior.

### 9.5 Localization

Naked UI may accept semantic labels and hints but must not ship English defaults for user-facing phrases such as “Open context menu,” “Notification,” “Dismiss,” “Required,” or “Invalid.” Prefer one of:

- a required caller-provided string;
- an existing Flutter localization string with the correct meaning;
- a localization delegate introduced deliberately for Naked UI.

Tests must use at least one non-English label and an RTL <code>Directionality</code> fixture to catch assumptions.

### 9.6 Stable identifiers

Public semantics identifiers should be optional and documented if exposed. Test keys belong to the example fixture, not the package API. Do not make production behavior depend on a test-only key.

### 9.7 Reduced motion

Naked UI should expose behavior state and timing hooks; it should not force visual animation. Canonical examples and Remix must honor <code>MediaQuery.disableAnimations</code>. Timed behavior such as Toast dismissal remains functional when visual transitions are disabled.

## 10. Universal semantics contract

Every component must document and test all fields below.

| Dimension | Required question |
|---|---|
| Primitive | What user-recognizable control or region is this? |
| Accessible name | Where does the name come from, and what happens if it is absent? |
| Role or flags | Which Flutter role and flags are exposed? |
| State/value | Which open, selected, toggled, required, invalid, expanded, or value fields change? |
| Actions | Which semantic actions exist while enabled, and which disappear while disabled? |
| Focus | Is it focusable, where does focus enter, and where is it restored? |
| Traversal | Is it one tab stop or several, and what is the internal order? |
| Grouping/relations | Which nodes are containers, explicit children, or controlled content? |
| Disabled behavior | Is it discoverable, focusable, actionable, and announced as disabled? |
| Localization | Which labels/hints are caller supplied? |
| Flutter mapping | Which <code>Semantics</code> properties implement the contract? |
| Automated proof | Which exact node properties and transitions are asserted? |
| Manual proof | What must VoiceOver, TalkBack, and web assistive technology announce? |

### 10.1 Aggregate matrix

| Component | Primary semantics mapping | Name/value/state | Actions and focus |
|---|---|---|---|
| Alert Dialog | <code>role: SemanticsRole.alertDialog</code>, container, explicit children, route scope/name, blocked background | Visible title or caller <code>semanticLabel</code>; message remains readable | Focus enters the specified safe target, loops inside, and returns to invoker; default outside barrier is inert, while Escape/platform Back safely cancel |
| Context Menu | Trigger retains its native semantics; popup <code>role: menu</code>; initial-scope action items use <code>menuItem</code> | Trigger label only if supplied; item labels from visible content or explicit label | Secondary tap, long press, keyboard menu shortcut, item tap; focus moves into menu and restores on close |
| Toggle Group | Group semantics container; options are toggle buttons | Each option has a name and <code>toggled</code> state; group can have a label | One tab stop; arrows move roving focus; Enter/Space toggle; disabled options have no action |
| Toast | <code>role: status</code> for normal messages or <code>role: alert</code> for urgent messages | One concise announcement string; visual action remains a separate accessible control | No focus steal; optional user-invoked viewport focus; dismiss/action controls work normally |
| Field | Actual control carries text-field/control semantics, <code>isRequired</code>, and <code>validationResult</code>; error announcement uses <code>role: alert</code> only on a new visible error | Label, current value, description, and current error are associated with the control without duplicate speech | Label requests control focus; disabled/read-only distinctions remain accurate |
| Combobox | Editable text-field semantics plus <code>SemanticsRole.comboBox</code> where verified; <code>expanded</code> and <code>controlsNodes</code>; popup list and selected options | Name, query/value, expanded state, highlighted option, selection | Input stays focused; arrows highlight; Enter accepts; Escape closes; popup is outside page Tab sequence |
| Hover Card | Trigger keeps its original Link semantics; preview overlay is excluded from semantics by default | No duplicate accessible name; preview contains no unique essential information | Hover/focus opens; Escape dismisses; preview does not enter Tab order or steal focus |
| Link | <code>link: true</code>, optional <code>linkUrl</code>, enabled state, tap action | Visible text or explicit label; optional hint such as opening a new window is caller-localized | Enter and semantic tap activate; Space is not intercepted; disabled links are not focusable/actionable |

### 10.2 Important Flutter 3.41.2 caveat

The Flutter 3.41.2 SDK contains <code>SemanticsRole.alertDialog</code>, <code>comboBox</code>, <code>status</code>, and <code>alert</code>; it also contains <code>linkUrl</code>, <code>controlsNodes</code>, <code>isRequired</code>, and <code>SemanticsValidationResult</code>.

However, enum presence is not proof of complete platform mapping. In Flutter 3.41.2, the framework's debug role checker marks <code>SemanticsRole.comboBox</code> as not yet implemented, and the web engine falls back to property-derived behavior for that role. The Flutter source points to [flutter/flutter#159741](https://github.com/flutter/flutter/issues/159741). Therefore:

- include the role only after a focused prototype on every supported target;
- assert the text-field, expanded, value, action, and controlled-node properties independently;
- inspect the actual web accessibility tree;
- record real VoiceOver and TalkBack output;
- do not describe Combobox accessibility as complete based only on a widget semantics-tree assertion.

For <code>SemanticsRole.status</code> and <code>SemanticsRole.alert</code>, Flutter's role checker expects the role to supply live-region meaning. Do not also set <code>liveRegion: true</code> on the same node. Test that no debug semantics exception occurs.

## 11. Universal keyboard and focus rules

### 11.1 Test actual outcomes

A keyboard test is valid only if it proves the result of the key:

- the expected node has primary focus;
- a value changed exactly once;
- an overlay opened or closed;
- the correct item became highlighted;
- focus returned to the correct invoker.

Sending a key without asserting the outcome is not coverage.

### 11.2 Use Flutter's focus system

- Prefer <code>Shortcuts</code> and <code>Actions</code> with component-specific intents.
- Use <code>FocusTraversalGroup</code> for an intentional composite boundary.
- Keep nodes long-lived and dispose owned nodes.
- Account for Flutter focus changes applying after a frame; pump once before asserting.
- Never create a new <code>FocusNode</code> in <code>build</code>.
- Do not intercept standard text-editing keys in editable controls.
- Test both logical keyboard keys and the resulting state, not raw platform key codes.

### 11.3 Directionality

For horizontal composites:

- in LTR, Right moves to the next logical item and Left to the previous;
- in RTL, the visual-direction behavior must be explicitly decided and tested; the recommendation is Right moves visually right and Left visually left;
- Up/Down behavior follows component orientation;
- disabled items are skipped;
- Home and End move to first and last enabled items;
- wrapping occurs only when <code>loop</code> is true.

### 11.4 Focus restoration

Overlay components retain an invoker reference at open time. On close:

- keyboard-opened overlays restore focus to that invoker;
- focus is not restored to a disposed or no-longer-focusable node;
- replacing or removing the trigger while open must not throw;
- nested overlays restore to the immediate parent invoker, not an unrelated earlier node.

## 12. Verification architecture

No single test layer is sufficient. Each layer below answers a different question and is required unless the component-specific section explicitly marks it not applicable.

### 12.1 Required test layers

| Layer | Location | What it proves | What it does not prove |
|---|---|---|---|
| Logic/widget | <code>packages/naked_ui/test/src</code> | State transitions, callbacks, controller ownership, timers, rebuilds, disposal, gestures | Actual platform accessibility output or final styled appearance |
| Semantics | <code>packages/naked_ui/test/semantics</code> | Flutter semantics-tree role, flags, labels, values, actions, grouping, transitions | What a particular screen reader actually speaks |
| Parity where useful | <code>packages/naked_ui/test/src/parity</code> | Intended equivalence with a Flutter control | Correctness when Flutter has no equivalent or when the desired pattern differs |
| Canonical example widget | <code>packages/example/test</code> | Representative styled layout, accessibility guidelines, deterministic goldens | Every possible consumer style |
| Real integration | <code>packages/example/integration_test/components</code> | End-to-end input, focus, overlay, timer, and route behavior on a target | Pixel stability across every machine |
| Raw screenshot artifact | CI artifact per target | Human-reviewable evidence of actual rendered states and collision handling | Semantics or keyboard correctness |
| Manual assistive technology | PR evidence record | Actual announcements and navigation with VoiceOver/TalkBack/web AT | Automated regression coverage |
| Remix consumer tests | Remix repository | Actual theme styling and package integration | Naked UI's standalone minimum-version compatibility |

### 12.2 Proposed file names

Add these source and test files following current project conventions:

| Component | Source | Widget tests | Semantics tests | Integration |
|---|---|---|---|---|
| Alert Dialog | Extend <code>naked_dialog.dart</code> | Extend <code>naked_dialog_test.dart</code> and parity test | Extend <code>naked_dialog_semantics_test.dart</code> | Extend <code>naked_dialog_integration.dart</code> |
| Context Menu | <code>naked_context_menu.dart</code> | <code>naked_context_menu_test.dart</code> | <code>naked_context_menu_semantics_test.dart</code> | <code>naked_context_menu_integration.dart</code> |
| Toggle Group | Extend <code>naked_toggle.dart</code> | Extend <code>naked_toggle_test.dart</code> | Extend <code>naked_toggle_semantics_test.dart</code> | Extend <code>naked_toggle_integration.dart</code> |
| Toast | <code>naked_toast.dart</code> | <code>naked_toast_test.dart</code> | <code>naked_toast_semantics_test.dart</code> | <code>naked_toast_integration.dart</code> |
| Field | <code>naked_field.dart</code>; integrate <code>naked_textfield.dart</code> | <code>naked_field_test.dart</code> plus text-field regressions | <code>naked_field_semantics_test.dart</code> plus text-field regressions | <code>naked_field_integration.dart</code> |
| Combobox | <code>naked_combobox.dart</code> | <code>naked_combobox_test.dart</code> | <code>naked_combobox_semantics_test.dart</code> | <code>naked_combobox_integration.dart</code> |
| Hover Card | <code>naked_hover_card.dart</code> | <code>naked_hover_card_test.dart</code> | <code>naked_hover_card_semantics_test.dart</code> | <code>naked_hover_card_integration.dart</code> |
| Link | <code>naked_link.dart</code> | <code>naked_link_test.dart</code> | <code>naked_link_semantics_test.dart</code> | <code>naked_link_integration.dart</code> |

Export every accepted public API from <code>packages/naked_ui/lib/src/naked_widgets.dart</code>. Add the integration test main to <code>packages/example/integration_test/all_tests.dart</code>. A test file that is not included in the aggregate runner is not delivered.

### 12.3 Semantics test standard

Every semantics test must:

1. Call <code>tester.ensureSemantics()</code> and dispose the handle with teardown-safe cleanup.
2. Locate the intended node by semantics properties or a stable fixture finder, not by fragile tree depth.
3. Assert the exact accessible name, role/flags, value/state, and action set relevant to the case.
4. Assert that disabled controls do not expose activation actions.
5. Assert state changes after pointer, keyboard, and direct semantic actions.
6. Assert there is one authoritative control node and no accidental nested duplicate of the same control.
7. Call <code>tester.takeException()</code> after role-sensitive builds and expect no exception.
8. Test <code>excludeSemantics</code> if the component exposes it.
9. Include a non-English name and an RTL fixture where direction or generated text matters.
10. Avoid dumping a whole semantics tree as the only assertion; a string snapshot can stay green while important flags change.

Use <code>matchesSemantics</code> when exact matching improves clarity, and direct <code>SemanticsData</code> assertions for newer fields such as role, controlled-node identifiers, validation result, or link URL.

### 12.4 Keyboard test standard

Do not retain the current catch-and-return-false helper. Replace it with helpers that throw on failure and assert postconditions. A representative helper should:

1. request focus through a known <code>FocusNode</code>, rather than tapping unless the test is specifically about pointer focus;
2. pump one frame and assert that node is primary focus;
3. send one full logical key event;
4. pump only the duration required by the behavior;
5. assert focus, value, overlay, or callback count;
6. repeat for disabled state and assert no change.

For composite widgets, assert every step in the traversal, including skipped disabled items, Home/End, looping off, looping on, dynamic removal, and RTL.

### 12.5 Accessibility-guideline boundary

Flutter provides automated guidelines for:

- Android 48-by-48 logical-pixel tap targets;
- iOS 44-by-44 logical-pixel tap targets;
- labels on tappable targets;
- text contrast.

Run all applicable guidelines on each canonical styled example. Do not run them only against invisible/headless wrappers and call the package accessible. Naked UI cannot guarantee a consumer's target size or color contrast because it does not own size or color. The release claim should be:

> Naked UI supplies the behavior and semantics contract; the canonical example passes Flutter guidelines; every styled consumer must repeat target-size and contrast checks.

### 12.6 Golden and screenshot standard

- Goldens run in a pinned host environment with fixed surface size, device-pixel ratio, locale, text direction, text scale, fonts, and animation state.
- Real-device screenshots are artifacts, not cross-platform pixel goldens.
- Every screenshot has a deterministic name of the form <code>component__scenario__platform__theme.png</code>.
- CI uploads current images and diffs when a golden fails.
- Updating a golden requires a reviewer to inspect the image, not merely run <code>--update-goldens</code>.
- Screenshots must not contain network images, current times, random IDs, blinking cursors, or in-progress indeterminate animations.

### 12.7 Manual assistive-technology standard

For each PR, test at least:

- macOS VoiceOver on the real macOS example;
- Android TalkBack on the emulator or device used for integration;
- Chrome accessibility tree plus keyboard navigation on web.

Before a release consumed by Remix, also test iOS VoiceOver and one Windows web screen-reader/browser combination when the project claims those targets. Record:

- device/OS/browser and Flutter version;
- screen reader and version;
- exact action taken;
- actual announcement summarized in the tester's own words;
- expected result;
- pass/fail and linked issue for any deviation.

Do not include long verbatim screen-reader transcripts when a concise outcome is sufficient.

## 13. Component contract: Alert Dialog

> **Approved safety correction — 2026-07-13:** Alert dialogs always request
> route focus; the proposed <code>requestFocus</code> opt-out is removed because
> it can leave an active background control focused. The outside barrier remains
> non-dismissible by default, while Escape and platform Back cancel safely with
> a null result. A dismissible barrier requires a non-empty caller-localized
> label. This correction supersedes the earlier wording that grouped Escape
> together with the inert outside barrier.

### 13.1 Why it is needed

Remix can display a general dialog today, but a destructive or urgent confirmation has a distinct accessibility role and safer dismissal defaults. WAI-ARIA treats Alert Dialog as a modal dialog containing an alert message whose content and controls must be identified. Flutter 3.41.2 provides <code>SemanticsRole.alertDialog</code>, and Flutter's own Material and Cupertino alert dialogs use it.

### 13.2 Confirmed reusable foundation

Current <code>NakedDialog</code> already:

- wraps content with dialog semantics;
- scopes and names a modal route;
- blocks background semantics;
- uses a closed-loop traversal edge by default;
- supports a barrier, root navigator selection, transitions, request-focus behavior, and focus restoration through routing;
- installs Escape dismissal only when the route is barrier-dismissible.

The current limitation is that <code>NakedDialog</code> hard-codes <code>SemanticsRole.dialog</code>, while <code>showNakedDialog</code> defaults <code>barrierDismissible</code> to true.

### 13.3 Proposed public API

Keep the existing API source-compatible and add:

~~~dart
const NakedDialog({
  Key? key,
  required Widget child,
  bool modal = true,
  String? semanticLabel,
  bool excludeSemantics = false,
  SemanticsRole semanticsRole = SemanticsRole.dialog,
});
~~~

Assert that <code>semanticsRole</code> is <code>dialog</code> or <code>alertDialog</code>. A generic arbitrary-role escape hatch would weaken the contract.

Add a convenience helper:

~~~dart
Future<T?> showNakedAlertDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required Color barrierColor,
  required String semanticLabel,
  String? barrierLabel,
  bool barrierDismissible = false,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  Duration transitionDuration = const Duration(milliseconds: 400),
  RouteTransitionsBuilder? transitionBuilder,
  FocusNode? initialFocusNode,
});
~~~

The helper wraps the widget returned by <code>builder</code> in one <code>NakedDialog</code> with <code>SemanticsRole.alertDialog</code>, a required non-empty localized <code>semanticLabel</code>, a non-dismissible outside barrier by default, and safe Escape/platform-Back cancellation. Enabling outside-barrier dismissal requires a non-empty localized <code>barrierLabel</code>. The builder returns the visual dialog contents and must not add a second <code>NakedDialog</code>. Public naming is proposed, but the single role node, focus entry, and cancellation behavior are required.

### 13.4 Behavioral contract

- The background is inert to pointer, keyboard, and semantics navigation while modal.
- Focus moves inside after the route opens.
- If <code>initialFocusNode</code> is provided and remains focusable, it receives focus.
- Otherwise, the helper explicitly selects the first traversable descendant; the example must demonstrate an explicit safe target.
- For irreversible actions, the canonical example initially focuses the least destructive action.
- For a long or structurally rich message, the consumer may focus a non-action semantic container at the beginning of the message.
- Focus cannot escape with Tab or Shift+Tab.
- Closing returns focus to the invoking control when it still exists and is focusable.
- Outside tap does not close the default alert helper.
- Escape and platform Back cancel with a null result.
- A consumer that deliberately enables outside-barrier dismissal must provide a localized barrier label, an explicit safe cancel action, and tests for every cancellation result.
- Nested alert dialogs are discouraged; if allowed, restoration follows route stack order.

### 13.5 Semantics contract

| Field | Required behavior |
|---|---|
| Role | <code>SemanticsRole.alertDialog</code> |
| Name | Non-empty caller-localized <code>semanticLabel</code>; visible title/message remain separate useful nodes |
| Message | Readable as content after the dialog name; not collapsed into an unusably long control name |
| Modal state | <code>scopesRoute</code>, <code>namesRoute</code>, and <code>BlockSemantics</code> when modal |
| Children | Explicit child nodes so message and actions remain navigable |
| Actions | Dialog container has no fake tap action; buttons own their actions |
| Exclusion | <code>excludeSemantics</code> removes the dialog subtree and is documented as an advanced escape hatch |

### 13.6 Required widget and semantics tests

- Existing unnamed <code>NakedDialog</code> still defaults to the normal dialog role.
- <code>semanticsRole: alertDialog</code> exposes exactly that role.
- Any other role fails a debug assertion.
- The alert helper defaults to a nondismissible barrier.
- Outside tap does not close the default alert helper.
- Escape and platform Back close once with a null result.
- A dismissible barrier requires a non-empty caller-localized label.
- Explicit action closes with its result.
- Optional dismissible configuration closes exactly once.
- Initial focus enters the supplied safe action after one frame.
- Tab and Shift+Tab loop inside.
- Focus returns to the invoker after every supported close path.
- Removing the invoker before close does not throw.
- Background semantics are blocked while open and restored after close.
- Title, message, Cancel, and destructive action appear as separate useful semantics nodes.
- Large message content can receive initial focus without being exposed as a button.
- The excluded-semantics case has no alert-dialog node.

### 13.7 Integration and screenshot scenarios

Stable fixture keys:

- <code>alert-dialog.open</code>
- <code>alert-dialog.title</code>
- <code>alert-dialog.message</code>
- <code>alert-dialog.cancel</code>
- <code>alert-dialog.confirm</code>
- <code>alert-dialog.result</code>

Integration scenarios:

1. Open by keyboard, verify alert role in semantics, verify Cancel focus, Tab loop, cancel, and invoker restoration.
2. Open by pointer, tap the default barrier and verify it remains open, then press Escape and verify one null cancellation.
3. Open again, invoke platform Back, and verify one null cancellation.
4. Activate destructive action and verify one callback plus visible result.
5. Remove the invoker while open, close programmatically, and verify no exception.
6. Render a long message at 200% text scale and verify content scroll/focus access.

Required screenshots:

- <code>alert_dialog__open_safe_focus__macos__reference.png</code>
- <code>alert_dialog__destructive_action__android__reference.png</code>
- <code>alert_dialog__long_message_200_text__macos__reference.png</code>
- <code>alert_dialog__rtl__web__reference.png</code>

Manual checks must confirm that the dialog is announced as an alert dialog, background content is not reachable, the title/message are discoverable, the initial focus is sensible, and focus returns after close.

### 13.8 Alert Dialog acceptance

- [ ] Existing dialog API remains source-compatible.
- [ ] Default normal dialog semantics do not change.
- [ ] Alert role and the safe cancellation contract are covered.
- [ ] Focus containment/restoration pass on macOS and Android.
- [ ] Long text and RTL screenshots are reviewed.
- [ ] VoiceOver and TalkBack evidence is attached.
- [ ] Example and API docs explain when Alert Dialog is appropriate.

## 14. Component contract: Toggle Group

### 14.1 Why it is needed

Remix needs segmented/content-switcher and grouped-toggle behavior. Current Naked UI main has a useful single-select scope, but it does not own composite keyboard traversal, orientation, looping, multiple selection, a group label, or a group focus policy. Its semantics coverage currently verifies rendering but does not assert a complete group contract.

### 14.2 Confirmed current behavior

The current unnamed <code>NakedToggleGroup</code>:

- is controlled by <code>selectedValue</code> and <code>onChanged</code>;
- is effectively disabled if <code>enabled</code> is false or <code>onChanged</code> is null;
- never clears the selected item by activating it again;
- exposes each option as a semantic button with <code>selected</code> state;
- gives each option independent focusability and Enter/Space activation;
- has no orientation, Home/End, arrow-key, loop, RTL, or multiple-selection contract.

### 14.3 Proposed compatible API

Preserve the current unnamed constructor and defaults, then add composite behavior:

~~~dart
const NakedToggleGroup({
  Key? key,
  required Widget child,
  required T? selectedValue,
  ValueChanged<T?>? onChanged,
  bool enabled = true,
  Axis orientation = Axis.horizontal,
  bool loop = true,
  bool allowEmptySelection = false,
  String? semanticLabel,
  bool excludeSemantics = false,
});

const NakedToggleGroup.multiple({
  Key? key,
  required Widget child,
  required Set<T> selectedValues,
  ValueChanged<Set<T>>? onValuesChanged,
  bool enabled = true,
  Axis orientation = Axis.horizontal,
  bool loop = true,
  String? semanticLabel,
  bool excludeSemantics = false,
});
~~~

The internal representation may differ, but constructor invariants must prevent single and multiple callbacks/values from being mixed.

Keep <code>NakedToggleOption</code> source-compatible. Its existing optional focus node, builder, callbacks, semantic label, enabled state, and exclusion behavior remain.

### 14.4 Selection contract

Single mode:

- Activating an unselected option emits that value once.
- Activating the selected option does nothing when <code>allowEmptySelection</code> is false, preserving current behavior.
- Activating the selected option emits null when <code>allowEmptySelection</code> is true.
- The group does not mutate the controlled value before its parent rebuilds.

Multiple mode:

- Activating an unselected option emits an immutable set containing it.
- Activating a selected option emits an immutable set without it.
- Input sets are never mutated.
- Equality is based on set content, not identity.
- Disabled options remain present in the selected-values view if supplied by the parent but cannot be changed by the user.

### 14.5 Composite focus and keyboard contract

- The group contributes one stop to page Tab order.
- Initial roving target is the most recently focused enabled option, then the selected enabled option in single mode, then the first enabled option.
- Tab enters at the roving target; a second Tab leaves the group.
- Arrow keys move focus without changing selection.
- Horizontal groups use Left/Right; vertical groups use Up/Down.
- Home and End move to first and last enabled options.
- Disabled options are skipped.
- When <code>loop</code> is true, movement wraps; when false, focus stays at the edge.
- Enter and Space toggle the focused option.
- Dynamic insert, remove, disable, or reorder retains a valid roving target without throwing.
- If every option is disabled, the group has no Tab stop.
- RTL horizontal behavior is visual-direction based and explicitly tested.

### 14.6 Semantics decision

**Recommendation:** model options as toggle buttons using <code>button: true</code> plus <code>toggled</code>, not as radio buttons. This matches the Radix/Base Toggle Group model and supports both single and multiple selection. A product requiring radio semantics should use <code>NakedRadioGroup</code>.

Changing current option semantics from <code>selected</code> to <code>toggled</code> can change announcements and is therefore a behavioral compatibility change even though it is not a Dart source break. Resolve it explicitly:

- preferred: migrate to <code>toggled</code>, document in the changelog, and add an announcement-focused release note;
- fallback: retain <code>selected</code> for the existing constructor and use <code>toggled</code> for a new mode, at the cost of inconsistent semantics.

Do not expose both selected and toggled on the same option merely to satisfy old tests.

Group semantics:

- container with explicit child nodes;
- optional caller-provided label;
- no <code>radioGroup</code> role for toggle-button mode;
- group disabled state propagates to every option;
- each option has one accessible name, toggled state, enabled state, focusability, and tap action only when enabled.

### 14.7 Required widget and semantics tests

- All current single-select behavior remains green.
- Single allow-empty false and true paths.
- Multiple add/remove, immutable output, and input non-mutation.
- Null callbacks and disabled group suppress all actions.
- Disabled item suppresses its action without disabling siblings.
- One Tab stop, entry target, exit behavior, arrows, Home, End, loop on/off.
- LTR horizontal, RTL horizontal, and vertical traversal.
- Dynamic addition, reorder, disable, and removal of the current roving item.
- Enter and Space each emit exactly one change.
- Arrow movement emits no selection change.
- Pointer selection updates the controlled value only after the parent rebuild.
- Builder and state scope expose selected/toggled, focused, hovered, pressed, and disabled state accurately.
- Group label and option names are present exactly once.
- Option semantics expose the accepted toggled/selected decision and no action when disabled.
- Group exclusion removes all group semantics.
- No debug role or merged-semantics exception occurs.

### 14.8 Integration and screenshot scenarios

Stable fixture keys:

- <code>toggle-group.root</code>
- <code>toggle-group.option.bold</code>
- <code>toggle-group.option.italic</code>
- <code>toggle-group.option.underline</code>
- <code>toggle-group.value</code>

Integration scenarios:

1. Tab into a horizontal group, traverse with arrows, toggle with Space, and Tab out.
2. Repeat with RTL and assert visual-direction focus.
3. Traverse a vertical group with a disabled middle item and loop disabled.
4. Use multiple mode and verify two independent selections.
5. Remove the focused option during rebuild and verify a valid neighbor receives the roving target.
6. Invoke the semantic tap action and verify the same callback contract.

Required screenshots:

- <code>toggle_group__single_selected_focus__macos__reference.png</code>
- <code>toggle_group__multiple_selected__android__reference.png</code>
- <code>toggle_group__disabled_option__macos__reference.png</code>
- <code>toggle_group__vertical__web__reference.png</code>
- <code>toggle_group__rtl_focus__web__reference.png</code>
- <code>toggle_group__200_text__macos__reference.png</code>

Manual checks confirm that the group label is announced once, each option is identified as a toggle button with correct state, only one page Tab stop is used, and arrows do not unexpectedly toggle values.

### 14.9 Toggle Group acceptance

- [ ] Current unnamed constructor compiles unchanged.
- [ ] Single and multiple modes have explicit invariants.
- [ ] Roving focus passes LTR, RTL, vertical, disabled, and dynamic-child cases.
- [ ] The semantics compatibility decision is recorded in the changelog.
- [ ] Canonical example passes label and target-size guidelines.
- [ ] All six screenshot states are reviewed.
- [ ] VoiceOver, TalkBack, and web keyboard results are attached.

## 15. Component contract: Context Menu

### 15.1 Why it is needed

A context menu is not merely a menu placed under a different icon. It opens from a secondary pointer action, touch long press, or keyboard context-menu command and is positioned at either the invocation point or the focused trigger. Keyboard users must receive the same actions and focus behavior as pointer users.

### 15.2 Confirmed reusable foundation

Current <code>NakedMenu</code> already supplies:

- <code>MenuController</code> lifecycle;
- menu and menu-item semantics roles;
- enabled and disabled item behavior;
- anchored overlay plumbing and outside-click close;
- selection callbacks and close-on-activate behavior;
- trigger focus restoration;
- item builders and state scopes.

Current <code>NakedMenu</code> is trigger-button oriented. It always builds a <code>NakedButton</code> trigger and does not expose secondary-tap, long-press, Shift+F10, Context Menu key, or point-anchor behavior. A new trigger primitive should reuse its items and internal menu scope rather than copy the item implementation.

### 15.3 Proposed public API

~~~dart
enum NakedContextMenuTriggerKind {
  mouse,
  touch,
  keyboard,
  programmatic,
}

class NakedContextMenuState extends NakedState {
  NakedContextMenuState({
    required super.states,
    required this.isOpen,
    required this.anchorPosition,
    required this.triggerKind,
  });

  final bool isOpen;

  // Local to the trigger coordinate space used by MenuController.open.
  final Offset? anchorPosition;
  final NakedContextMenuTriggerKind? triggerKind;
}

const NakedContextMenu<T>({
  Key? key,
  Widget? child,
  ValueWidgetBuilder<NakedContextMenuState>? builder,
  required RawMenuAnchorOverlayBuilder overlayBuilder,
  required MenuController controller,
  ValueChanged<T>? onSelected,
  VoidCallback? onOpen,
  VoidCallback? onClose,
  VoidCallback? onCanceled,
  RawMenuAnchorOpenRequestedCallback? onOpenRequested,
  RawMenuAnchorCloseRequestedCallback? onCloseRequested,
  bool enabled = true,
  bool openOnSecondaryTap = true,
  bool openOnLongPress = true,
  bool openOnKeyboard = true,
  bool consumeOutsideTaps = true,
  bool useRootOverlay = false,
  bool closeOnClickOutside = true,
  bool loopFocus = true,
  FocusNode? triggerFocusNode,
  OverlayPositionConfig positioning = const OverlayPositionConfig(),
  String? semanticLabel,
  bool excludeSemantics = false,
});
~~~

Retain <code>NakedMenuItem<T></code> as the item type for both normal and context menus. Achieve this by extracting the current private menu scope into shared internal infrastructure. Avoid a second public item class with subtly different semantics.

Programmatic opening can use <code>MenuController.open(position: ...)</code>. If the team decides a typed controller is necessary to expose trigger kind, add it before release rather than leaking mutable state through globals.

### 15.4 Trigger and positioning behavior

- Secondary tap records the local invocation point and opens there.
- Touch long press opens at the press point using Flutter's platform gesture timing.
- Shift+F10 and <code>LogicalKeyboardKey.contextMenu</code> open from the focused trigger.
- A keyboard anchor uses the trigger's lower logical start edge and respects RTL.
- Programmatic open may supply a point; without one it uses the trigger anchor.
- The overlay clamps or flips so the full menu remains in the safe visible bounds when possible.
- Opening from one method must not also fire primary tap behavior on the child.
- Repeated open requests while already open do not duplicate callbacks or overlays.
- If <code>enabled</code> is false, no gesture, shortcut, or semantic action opens the menu.
- Pointer position is cleared after close so the next keyboard open does not reuse stale coordinates.

### 15.5 Focus and keyboard behavior

- The trigger can participate in focus traversal without being forced to expose button semantics.
- On open, focus moves to the first enabled menu item.
- Down/Right behavior for nested submenus is out of initial scope; do not imply submenu support.
- Up/Down move through enabled items.
- Home/End move to first/last enabled items.
- Enter/Space activate the focused item.
- Escape closes without selection and restores trigger focus.
- Tab closes the menu and continues normal page traversal; it does not make every menu item a page Tab stop.
- When <code>loopFocus</code> is true, arrows wrap; otherwise focus remains at the edge.
- Removing the active item moves focus to a valid neighbor or the menu container.

### 15.6 Semantics contract

Trigger:

- preserve the child's native role; a text-editing region, image, link, or custom surface must not become a fake button automatically;
- expose caller <code>semanticLabel</code> only when provided;
- provide an enabled long-press semantic action when long-press opening is enabled;
- do not expose any opening action when disabled;
- do not duplicate the child's label when <code>semanticLabel</code> overrides it.

Popup:

- one <code>SemanticsRole.menu</code> container with explicit child nodes;
- initial-scope action items use <code>SemanticsRole.menuItem</code>;
- disabled items remain discoverable but have no tap action;
- do not simulate checked/radio behavior with a plain action item because it would expose the wrong role;
- separators and decorative icons are excluded from semantics.

### 15.7 Required widget and semantics tests

- Secondary mouse tap opens once at the captured point.
- Primary tap does not open unless the child itself owns that behavior.
- Touch long press opens once and does not invoke primary tap.
- Shift+F10 and Context Menu key open from focus.
- Each disabled/open-method flag suppresses only its corresponding path.
- Builder state exposes open, trigger kind, anchor point, hover, focus, and disabled accurately.
- Opening near all four viewport edges stays in bounds.
- RTL keyboard anchor is at logical start.
- Focus enters first enabled item, skips disabled items, supports Home/End and loop setting.
- Escape, outside pointer, item activation, and programmatic close each emit correct close/cancel/selection callbacks exactly once.
- Focus restoration survives trigger rebuild and safely handles trigger removal.
- Existing <code>NakedMenuItem</code> works under both menu scopes.
- Trigger does not gain button semantics.
- Popup and item roles are exact; disabled item action is absent.
- Semantic long press opens the menu.
- <code>excludeSemantics</code> behavior is explicit and tested.

### 15.8 Integration and screenshot scenarios

Stable fixture keys:

- <code>context-menu.trigger</code>
- <code>context-menu.item.copy</code>
- <code>context-menu.item.rename</code>
- <code>context-menu.item.delete</code>
- <code>context-menu.item.disabled</code>
- <code>context-menu.selection</code>

Integration scenarios:

1. Right-click the center, assert open point, focus first item, select, and verify callback.
2. Open near each corner and assert the overlay rectangle remains in the visible surface.
3. Long-press on Android, navigate to an action, and dismiss outside.
4. Focus the trigger, press Shift+F10 and Context Menu key in separate tests, navigate with arrows, Escape, and verify restoration.
5. Verify a disabled context menu never opens by pointer, keyboard, or semantic action.
6. Verify a disabled item is announced but skipped by focus and cannot activate.

Required screenshots:

- <code>context_menu__pointer_center__macos__reference.png</code>
- <code>context_menu__collision_top_left__macos__reference.png</code>
- <code>context_menu__collision_bottom_right__web__reference.png</code>
- <code>context_menu__long_press__android__reference.png</code>
- <code>context_menu__keyboard_focus__macos__reference.png</code>
- <code>context_menu__rtl_anchor__web__reference.png</code>

Manual checks confirm that keyboard and touch users can discover and open the same menu, menu role and item states are announced, focus enters and returns predictably, and the trigger retains its original role.

### 15.9 Context Menu non-goals

- Nested submenus and menubars.
- Checkbox and radio menu-item variants in the first Context Menu release. Add shared <code>menuItemCheckbox</code>/<code>menuItemRadio</code> APIs deliberately before exposing those behaviors.
- OS-native process menus outside Flutter's semantics/focus tree.
- Arbitrary business commands or clipboard behavior.
- Product-specific icons, separators, destructive styling, or shortcut labels.

### 15.10 Context Menu acceptance

- [ ] Existing Menu behavior and item API remain compatible.
- [ ] All four open paths have direct tests.
- [ ] Point anchoring and four-edge collision behavior pass.
- [ ] Trigger semantics are not coerced to button.
- [ ] Focus entry, navigation, close, and restoration pass on real macOS.
- [ ] Long press passes on Android.
- [ ] All screenshot states and AT evidence are attached.

## 16. Component contract: Toast

### 16.1 Why it is needed

Remix's inline Callout cannot replace transient application feedback. Toast must coordinate a queue, visible limit, automatic dismissal, pause/resume, announcements, optional actions, focus access, and app lifecycle. These behaviors are cross-theme and should not be reimplemented by every styled package.

Toast is appropriate for a status update that does not require an immediate response. If the user must respond before continuing, use Alert Dialog. A toast action must be safe to ignore because the message may time out.

### 16.2 Proposed public model

The final names may be refined, but the recommended separation is:

~~~dart
enum NakedToastPriority {
  polite,
  assertive,
}

enum NakedToastDismissReason {
  timeout,
  action,
  close,
  swipe,
  programmatic,
  overflow,
}

@immutable
class NakedToastEntry<T> {
  const NakedToastEntry({
    required this.id,
    required this.payload,
    required this.semanticLabel,
    this.duration,
    this.priority = NakedToastPriority.polite,
  });

  final Object id;
  final T payload;
  final String semanticLabel;
  final Duration? duration;
  final NakedToastPriority priority;
}

class NakedToastState<T> extends NakedState {
  NakedToastState({
    required super.states,
    required this.entry,
    required this.isVisible,
    required this.isPaused,
    required this.remainingDuration,
  });

  final NakedToastEntry<T> entry;
  final bool isVisible;
  final bool isPaused;
  final Duration? remainingDuration;
}

@immutable
class NakedToastDismissed<T> {
  const NakedToastDismissed({
    required this.entry,
    required this.reason,
  });

  final NakedToastEntry<T> entry;
  final NakedToastDismissReason reason;
}

abstract interface class NakedToastHandle {
  Object get id;
  bool get isActive;
  void dismiss({
    NakedToastDismissReason reason = NakedToastDismissReason.programmatic,
  });
}

typedef NakedToastItemBuilder<T> =
    Widget Function(BuildContext context, NakedToastState<T> state);

class NakedToastController<T> extends ChangeNotifier {
  NakedToastHandle show(NakedToastEntry<T> entry);
  void dismiss(
    Object id, {
    NakedToastDismissReason reason = NakedToastDismissReason.programmatic,
  });
  void clear({
    NakedToastDismissReason reason = NakedToastDismissReason.programmatic,
  });
}

const NakedToastViewport<T>({
  Key? key,
  required NakedToastController<T> controller,
  required NakedToastItemBuilder<T> itemBuilder,
  Duration defaultDuration = const Duration(seconds: 5),
  int maxVisible = 3,
  int? maxQueued,
  bool pauseOnHover = true,
  bool pauseOnFocus = true,
  bool pauseWhenAppInactive = true,
  SingleActivator? focusShortcut,
  FocusNode? focusNode,
  ValueChanged<NakedToastDismissed<T>>? onDismissed,
  bool excludeSemantics = false,
});
~~~

Also provide scoped item helpers, or an equivalent structure, so consumers can mark:

- the visible title/description that duplicates <code>semanticLabel</code>;
- an optional safe action;
- an explicit close control.

The implementation must be able to exclude duplicate message text while retaining action and close semantics. A single <code>ExcludeSemantics</code> around the entire visual toast is not acceptable because it would hide the controls.

### 16.3 Controller and queue invariants

- IDs are unique among active and queued entries. Duplicate IDs either replace atomically through a documented API or throw a debug assertion; silent duplication is forbidden.
- <code>show</code> returns a handle tied to one entry.
- A handle dismisses at most once and becomes inert after removal.
- Visible entries are ordered deterministically. Recommended default: oldest visible first and new entries appended at the logical end.
- Entries beyond <code>maxVisible</code> wait in FIFO order and have no semantics node yet.
- A queued entry's timeout starts only when it becomes visible.
- <code>maxVisible</code> must be greater than zero.
- If <code>maxQueued</code> is supplied, overflow behavior and dismissal reason are deterministic and documented.
- Controller listeners are detached on viewport disposal; externally owned controllers are not disposed.
- Multiple viewports attached to the same controller are either explicitly supported with defined semantics or rejected. Recommendation: reject to prevent duplicate announcements.

### 16.4 Timer and lifecycle contract

- Null duration means persistent until action, close, or programmatic dismissal.
- Otherwise, auto-dismiss uses the entry duration or viewport default.
- Hover anywhere within the viewport pauses all visible timers when enabled.
- Keyboard focus anywhere within the viewport pauses all visible timers when enabled.
- App lifecycle states other than resumed pause timers when enabled.
- Pause stores remaining time; resume does not restart the full duration.
- Nested pause reasons are reference-safe: leaving hover does not resume while focus or app lifecycle is still paused.
- Removing an entry cancels its timer.
- Disposal cancels every timer and observer.
- A duration that expires during a visual exit transition produces one dismissal callback, not two.
- Tests use targeted <code>pump</code> durations; they never wait in real time.

### 16.5 Focus and keyboard contract

- Showing a toast never moves keyboard focus.
- Normal page Tab traversal does not unexpectedly jump to a newly inserted toast.
- If the application supplies <code>focusShortcut</code>, invoking it stores current focus and moves focus to the newest visible toast or its first actionable control.
- Within the viewport, Tab reaches action and close controls in visual order.
- Escape while focus is in the viewport dismisses the current toast when that behavior is documented, then returns focus to the stored prior node.
- If no prior node remains focusable, normal traversal continues without throwing.
- An auto-dismiss that occurs while one of its controls has focus is prevented by the focus pause.
- The canonical example may use F8, following common web primitive behavior, but the package must not reserve a global key without caller opt-in.

### 16.6 Announcement semantics

Normal status:

- <code>role: SemanticsRole.status</code>;
- concise caller-provided <code>semanticLabel</code>;
- no <code>liveRegion: true</code> on the same node;
- no focus steal.

Urgent status:

- <code>role: SemanticsRole.alert</code>;
- reserved for important, time-sensitive information;
- no <code>liveRegion: true</code> on the same node;
- still does not steal keyboard focus.

All messages:

- are added to the semantics tree only when visible;
- are announced once per appearance, not on every timer tick or hover rebuild;
- do not concatenate every stacked toast into one changing announcement node;
- keep action and close controls as explicit accessible children;
- avoid duplicating title/description speech after the root semantic label;
- remove their status/alert node after dismissal;
- do not announce queued hidden entries;
- expose no swipe-only requirement because swipe is inaccessible to many users.

### 16.7 Swipe dismissal

Swipe is valuable but should not block the first reliable release if it would compromise semantics or deterministic timers. Recommended phasing:

- initial release: action, close, timeout, and programmatic dismissal are required;
- follow-up: optional direction-aware swipe dismissal with observable drag state, threshold/velocity tests, cancel animation, and an equivalent close action.

If swipe ships initially, include <code>swipe</code> dismissal reason and test touch, mouse drag if supported, RTL direction, below-threshold cancellation, and focused-control protection.

### 16.8 Required widget and semantics tests

- Show, queue, visible limit, FIFO promotion, dismiss, clear, and unique ID behavior.
- Per-entry duration, default duration, persistent duration, and zero/invalid assertions.
- Remaining-time preservation for hover, focus, lifecycle, and combined pause reasons.
- Exactly one callback and reason for every dismissal path.
- Controller replacement, viewport disposal, and post-dispose handle behavior.
- No focus movement when a toast appears.
- Opt-in shortcut focus and focus restoration.
- Auto-dismiss does not remove a focused toast.
- Status and alert roles are exact, with no live-region role conflict.
- Each semantic label appears once.
- Queued entries have no semantics.
- Action and close controls remain discoverable and actionable.
- Disabled actions have no tap action.
- Rebuilding visual state does not reannounce unchanged content.
- <code>excludeSemantics</code> has a documented use and does not accidentally leave unlabeled actions.

### 16.9 Integration and screenshot scenarios

Stable fixture keys:

- <code>toast.show.polite</code>
- <code>toast.show.assertive</code>
- <code>toast.show.action</code>
- <code>toast.viewport</code>
- <code>toast.item.first</code>
- <code>toast.action.undo</code>
- <code>toast.close</code>
- <code>toast.count</code>

Integration scenarios:

1. Show a polite toast while a text field is focused; verify focus stays in the field and the status node appears once.
2. Advance exact time to just before and at expiry; verify one timeout dismissal.
3. Hover, advance beyond duration, verify retained; leave hover, advance remaining duration, verify dismissed.
4. Focus the action through the opt-in shortcut, verify timer pause, activate action, and restore prior focus.
5. Add more than <code>maxVisible</code>, verify only visible semantics, dismiss one, and verify queued promotion starts its timer.
6. Background/resume the app where the target permits lifecycle simulation and verify remaining time.
7. Show an assertive toast and verify alert role without focus movement.

Required screenshots:

- <code>toast__single_polite__macos__reference.png</code>
- <code>toast__stacked_limit__macos__reference.png</code>
- <code>toast__action_focused_paused__web__reference.png</code>
- <code>toast__assertive__android__reference.png</code>
- <code>toast__safe_area__android__reference.png</code>
- <code>toast__200_text_wrap__macos__reference.png</code>
- <code>toast__rtl_stack__web__reference.png</code>

Manual checks confirm one announcement per visible toast, polite versus urgent priority as supported by the platform, no focus steal, discoverable action/close controls, and understandable behavior when several toasts arrive.

### 16.10 Toast non-goals

- Styling, placement tokens, icons, colors, elevation, and transition design.
- Required-response workflows.
- Persistence across application restarts.
- Network retries or business action semantics.
- Notification-center history.

### 16.11 Toast acceptance

- [ ] Queue, limit, timers, and all pause reasons are deterministic.
- [ ] Status and alert semantics pass without role-check exceptions.
- [ ] No show path steals focus.
- [ ] Action and close remain accessible without duplicate message speech.
- [ ] Real macOS and Android timing scenarios pass.
- [ ] All screenshot states are reviewed.
- [ ] VoiceOver/TalkBack evidence includes stacked and actionable cases.

## 17. Component contract: Field

### 17.1 Why it is needed

A field is more than a decorated text input. It coordinates a visible label, description, control, required/read-only/disabled state, validation state, error visibility, label-to-control focus behavior, and error announcements. Without a headless field scope, each Remix input variant can concatenate and announce these pieces differently.

### 17.2 Confirmed reusable foundation and gap

Current <code>NakedTextField</code> already exposes:

- editable text, focus, hover, press, read-only, disabled, and error state;
- <code>semanticLabel</code>, <code>semanticHint</code>, and <code>semanticErrorText</code>;
- an enabled, focused, read-only, obscured, multiline, length-aware semantics node;
- a live-region flag when <code>error</code> and <code>semanticErrorText</code> are set.

It does not currently expose <code>isRequired</code> or <code>SemanticsValidationResult</code>. It also requires every consumer to manually keep the visible label/description/error synchronized with semantics. The proposed Field should integrate with <code>NakedTextField</code> without breaking standalone text-field behavior.

### 17.3 Proposed composition API

The recommended first release supports one primary control per field:

~~~dart
enum NakedFieldErrorAnnouncement {
  none,
  whenChanged,
}

class NakedFieldState extends NakedState {
  NakedFieldState({
    required super.states,
    required this.label,
    required this.description,
    required this.errorText,
    required this.isRequired,
    required this.isEnabled,
    required this.isReadOnly,
    required this.isTouched,
    required this.isDirty,
    required this.isFocused,
    required this.isFilled,
    required this.validationResult,
  });

  final String label;
  final String? description;
  final String? errorText;
  final bool isRequired;
  final bool isEnabled;
  final bool isReadOnly;
  final bool isTouched;
  final bool isDirty;
  final bool isFocused;
  final bool isFilled;
  final SemanticsValidationResult validationResult;
}

const NakedField({
  Key? key,
  required String label,
  String? description,
  String? errorText,
  bool isRequired = false,
  bool enabled = true,
  bool readOnly = false,
  bool touched = false,
  bool dirty = false,
  SemanticsValidationResult validationResult =
      SemanticsValidationResult.none,
  NakedFieldErrorAnnouncement errorAnnouncement =
      NakedFieldErrorAnnouncement.whenChanged,
  Widget? child,
  ValueWidgetBuilder<NakedFieldState>? builder,
  bool excludeSemantics = false,
});

const NakedFieldLabel({required Widget child});
const NakedFieldDescription({required Widget child});
const NakedFieldError({required Widget child});

const NakedFieldControl({
  Key? key,
  required Widget child,
  FocusNode? focusNode,
  bool hasValue = false,
  bool readOnly = false,
});
~~~

Public names are proposed. Required behavior:

- <code>NakedField</code> is the single source of semantic label, description, error, required state, and validation result.
- <code>NakedFieldControl</code> registers the primary focus target and applies field metadata to a non-text control.
- <code>NakedTextField</code> automatically reads the nearest field scope and registers itself, so consumers do not double-wrap it.
- label, description, and error visual helpers receive state through the scope and prevent unintended duplicate semantics.
- debug mode reports multiple registered primary controls in one field unless a future group mode explicitly supports them.

### 17.4 State ownership

- The application controls <code>touched</code>, <code>dirty</code>, <code>validationResult</code>, and when <code>errorText</code> becomes visible. Naked UI does not invent business validation timing.
- The primary control reports focused and filled state to the scope.
- Explicit control-level disabled and read-only state must not contradict the field. Effective disabled is the stricter state.
- The field builder receives a new immutable snapshot only when an observable state changes.
- Empty error text is normalized to no visible error.
- <code>validationResult.invalid</code> without an error message is allowed for semantics but documented as poor user experience.
- A non-null visible error with <code>validationResult.valid</code> is a debug assertion because the states conflict.

### 17.5 Label, description, and error behavior

- Tapping the visible label requests focus on the registered enabled control.
- Label tap does not open a keyboard for a disabled or non-focusable control.
- The label text is the control's accessible name exactly once.
- Description text is included in the control hint/description exactly once.
- Current error text is associated with the control so it is discoverable whenever the user returns to the field.
- When a mounted field transitions to a new non-empty visible error and announcement policy is <code>whenChanged</code>, the error is exposed as <code>SemanticsRole.alert</code> without also setting <code>liveRegion: true</code>.
- An unchanged error does not reannounce on unrelated rebuilds.
- Clearing and later reintroducing the same error is a new transition and may announce again.
- Initial invalid content is discoverable on control focus; whether it announces immediately must be consistent and documented. Recommendation: do not produce a surprise assertive announcement on first build.
- Error color or icon is never the only validation indicator; the canonical example includes text.

### 17.6 NakedTextField integration and compatibility

Inside a field scope, the text field applies:

- field label as the effective semantic label;
- description plus current error as effective semantic hint;
- <code>isRequired</code> from the field;
- <code>validationResult</code> from the field;
- effective disabled/read-only state;
- field-managed error announcement rather than its existing live-region path.

Outside a field scope, all current <code>NakedTextField</code> parameters and semantics remain unchanged.

If a consumer supplies both field metadata and explicit text-field semantic label/hint/error:

- recommended behavior is a debug assertion when values conflict;
- identical values may be accepted;
- do not concatenate two labels or two copies of the error.

This precedence rule must be decided and covered before implementation.

### 17.7 Semantics contract

Primary control:

- retains its native role and actions;
- accessible name equals field label;
- hint includes description and current error in a stable order;
- <code>isRequired</code> is true/false when the field declares required state;
- <code>validationResult</code> is none, valid, or invalid as controlled;
- enabled, read-only, focused, value, and actions remain accurate;
- disabled controls expose no focus/tap/edit action that can change the value.

Visual helpers:

- label is not a second unrelated text node if it would duplicate the control name;
- description is not duplicated after being associated with the control;
- error remains readable and can become a single alert transition;
- required and error icons are decorative unless they add nonduplicative meaning.

### 17.8 Required widget and semantics tests

- Child and builder invariants plus state-scope lookup.
- Label tap focuses enabled control; disabled/missing control is safe.
- One-primary-control registration and dynamic control replacement.
- Focused and filled state updates.
- Controlled touched/dirty/validity changes and state equality/hash code.
- Effective enabled and read-only propagation.
- Required state true, false, and absent/default semantics.
- Validation result none, valid, and invalid semantics.
- Label, description, and error appear in the control semantics exactly once.
- New error announces once; unchanged rebuild does not; clear/re-add announces again.
- Initial invalid policy is exact and tested.
- Error alert role is never combined with <code>liveRegion: true</code>.
- Standalone <code>NakedTextField</code> retains existing semantics.
- Conflicting field/text-field semantic inputs follow the chosen assertion/precedence rule.
- Non-text controls through <code>NakedFieldControl</code> retain their role.
- Dynamic localization updates accessible text without losing focus.
- Exclusion behavior is documented and tested.

### 17.9 Integration and screenshot scenarios

Stable fixture keys:

- <code>field.email</code>
- <code>field.email.label</code>
- <code>field.email.control</code>
- <code>field.email.description</code>
- <code>field.email.error</code>
- <code>field.email.submit</code>
- <code>field.email.state</code>

Integration scenarios:

1. Tap label, type a value, and verify focus, filled, touched/dirty output, and semantics value.
2. Submit invalid data, verify validation state and one error announcement node.
3. Rebuild without changing error and verify no duplicate announcement transition.
4. Correct the value, clear error, and verify valid state.
5. Verify disabled and read-only fields have distinct behavior and semantics.
6. Change locale and direction while focused; verify label/hint update without focus loss.
7. Use a non-text control fixture to prove the composition is not text-field-only.

Required screenshots:

- <code>field__empty_required__macos__reference.png</code>
- <code>field__focused_filled__web__reference.png</code>
- <code>field__invalid_error__android__reference.png</code>
- <code>field__disabled_and_readonly__macos__reference.png</code>
- <code>field__long_error_200_text__macos__reference.png</code>
- <code>field__rtl__web__reference.png</code>

Manual checks confirm label/name, required state, value, hint, invalid state, error announcement timing, label activation, and the distinction between disabled and read-only.

### 17.10 Field non-goals

- Business validation rules or schema libraries.
- Form submission orchestration.
- Input formatting already owned by the control.
- Visual required markers, success icons, or error styling.
- Multi-control fieldsets in the first release; add a deliberate group contract later.

### 17.11 Field acceptance

- [ ] Standalone TextField behavior remains compatible.
- [ ] Field metadata reaches the primary control without duplicate speech.
- [ ] Required and validation semantics are asserted.
- [ ] Error transition policy is deterministic.
- [ ] Label focus works for text and non-text controls.
- [ ] Canonical styled examples pass label, target, and contrast guidelines.
- [ ] All screenshot and assistive-technology evidence is attached.

## 18. Component contract: Combobox

### 18.1 Why it is needed

Combobox combines editable text, suggestions, selection, an anchored popup, dynamic filtering, keyboard highlight, focus retention, and assistive-technology announcements. It is not an editable skin over <code>NakedSelect</code>. Treating it as a Select would produce incorrect focus and text-editing behavior.

This is the highest-risk item in the handoff. It should not ship until actual assistive-technology behavior is proven on the supported platforms.

### 18.2 Confirmed reusable foundation

- <code>NakedTextField</code> provides native editing, selection, IME, focus, and semantics foundations.
- <code>NakedSelect</code> and overlay utilities provide controller, positioning, collision, outside-dismissal, and option-state patterns.
- <code>NakedStateScope</code> provides builder state.
- The proposed Field supplies label, description, required, invalid, and error semantics.

Do not subclass or silently change <code>NakedSelect</code>. Share private overlay/option infrastructure where behavior is truly common.

### 18.3 Accessibility spike required before final API

Before the full PR:

1. Build a minimal editable input, popup list, and three options.
2. Test <code>SemanticsRole.comboBox</code>, text-field semantics, <code>expanded</code>, <code>controlsNodes</code>, and option nodes on Flutter 3.41.2.
3. Inspect the Chrome accessibility tree.
4. Exercise VoiceOver on macOS and TalkBack on Android while typing and moving the active option.
5. Compare strategies for announcing active-option changes:
   - property/role mapping alone;
   - a dedicated <code>SemanticsRole.status</code> announcer whose label changes;
   - another platform-supported approach that does not move keyboard focus.
6. Record exact results and select the least duplicative strategy.

If no strategy makes the active option, selection, expanded state, and errors understandable, block the component and link the Flutter engine limitation. Do not downgrade this to a documentation note after release.

### 18.4 Proposed public API

~~~dart
class NakedComboboxState<T> extends NakedState {
  NakedComboboxState({
    required super.states,
    required this.isOpen,
    required this.query,
    required this.value,
    required this.values,
    required this.highlightedValue,
    required this.enabledOptionCount,
    required this.hasResults,
  });

  final bool isOpen;
  final String query;
  final T? value;
  final Set<T> values;
  final T? highlightedValue;
  final int enabledOptionCount;
  final bool hasResults;
}

class NakedComboboxOptionState<T> extends NakedState {
  NakedComboboxOptionState({
    required super.states,
    required this.value,
    required this.textValue,
    required this.isSelected,
    required this.isHighlighted,
  });

  final T value;
  final String textValue;
  final bool isSelected;
  final bool isHighlighted;
}

typedef NakedComboboxBuilder<T> =
    Widget Function(
      BuildContext context,
      NakedComboboxState<T> state,
      Widget editableText,
    );

const NakedCombobox<T>({
  Key? key,
  required TextEditingController textController,
  required MenuController menuController,
  required String Function(T value) displayStringForOption,
  required RawMenuAnchorOverlayBuilder overlayBuilder,
  T? value,
  ValueChanged<T?>? onChanged,
  ValueChanged<String>? onQueryChanged,
  ValueChanged<String>? onSubmitted,
  FocusNode? focusNode,
  bool enabled = true,
  bool readOnly = false,
  bool openOnInput = true,
  bool openOnFocus = false,
  bool closeOnSelect = true,
  bool loopFocus = true,
  OverlayPositionConfig positioning = const OverlayPositionConfig(),
  required NakedComboboxBuilder<T> builder,
  String? semanticLabel,
  String? semanticHint,
  String? semanticErrorText,
  bool excludeSemantics = false,
});

const NakedCombobox.multiple({
  Key? key,
  required TextEditingController textController,
  required MenuController menuController,
  required String Function(T value) displayStringForOption,
  required RawMenuAnchorOverlayBuilder overlayBuilder,
  required Set<T> values,
  ValueChanged<Set<T>>? onValuesChanged,
  ValueChanged<String>? onQueryChanged,
  FocusNode? focusNode,
  bool enabled = true,
  bool readOnly = false,
  bool openOnInput = true,
  bool openOnFocus = false,
  bool clearQueryOnSelect = true,
  bool loopFocus = true,
  OverlayPositionConfig positioning = const OverlayPositionConfig(),
  required NakedComboboxBuilder<T> builder,
  String? semanticLabel,
  String? semanticHint,
  String? semanticErrorText,
  bool excludeSemantics = false,
});

const NakedComboboxOption<T>({
  Key? key,
  required T value,
  required String textValue,
  bool enabled = true,
  Widget? child,
  ValueWidgetBuilder<NakedComboboxOptionState<T>>? builder,
  String? semanticLabel,
  bool excludeSemantics = false,
});
~~~

The exact builder type may be specialized instead of reusing <code>RawMenuAnchorOverlayBuilder</code>. The behavior below is the binding contract.

### 18.5 Query, filtering, and selection ownership

- Naked UI owns query observation and emits <code>onQueryChanged</code>.
- The consumer owns filtering, sorting, async data, empty text, loading text, and which option widgets are built.
- Option <code>textValue</code> is required for type/display semantics and active-option announcements; it is not assumed from arbitrary widget text.
- In single mode, selecting an option emits the value. The callback alone does not mutate accepted display state.
- The text controller updates to <code>displayStringForOption(value)</code> only when a later widget configuration supplies the accepted value, so a parent that rejects the request never flashes an unaccepted value.
- In multiple mode, selecting toggles membership without mutating the input set.
- Multiple mode clears the query on selection only when configured.
- The core exposes selected values; Remix owns chip layout. Every remove control in the canonical example has an explicit localized label.
- Custom/free-form value creation is owned through <code>onSubmitted</code>; the core does not invent a <code>T</code> from text.
- Dynamic option changes preserve highlight by value when possible; otherwise choose the nearest enabled option or clear it.

### 18.6 Focus and keyboard contract

The editable input retains real keyboard focus while the popup is open.

| Key | Closed | Open |
|---|---|---|
| Down Arrow | Open and highlight first enabled result | Highlight next enabled result |
| Up Arrow | Open and optionally highlight last enabled result | Highlight previous enabled result |
| Enter | Submit free text when no result is active and IME is not composing | Select active result when IME is not composing |
| Escape | No component action | Close popup, clear highlight, retain input value and focus |
| Tab / Shift+Tab | Normal page traversal | Close without silently selecting highlight; continue page traversal |
| Left / Right | Native text editing | Native text editing; never option navigation |
| Home / End | Native text editing | Native text editing in editable mode |
| Alt+Down | Optional open | Keep open |
| Alt+Up | No action | Close and keep focus |

Additional rules:

- Space inserts text; it never acts like a select trigger while editing.
- Enter during an active IME composing range is left to the IME.
- Pointer selection returns/retains input focus according to platform convention.
- Popup options are not page Tab stops.
- Disabled options are skipped and cannot select through pointer or semantics.
- Highlight and selected are separate states.
- Outside pointer closes without changing the accepted selection.
- Opening or closing does not move the text caret unexpectedly.

### 18.7 Popup and overlay contract

- Popup width is consumer-controlled but can read target size from overlay information.
- Collision keeps the active option and input visible when practical.
- The popup repositions on viewport/keyboard inset changes.
- Results update without closing on each keystroke.
- Empty results can remain open with a caller-rendered message.
- Async loading does not clear an accepted selection.
- A stale async result cannot reset highlight to an option no longer represented by the latest query; the consumer should key result sets and Naked UI should react safely to registry changes.
- Outside click, Escape, selection, controller close, and trigger removal each have one deterministic close callback.

### 18.8 Semantics contract

Input:

- native text-field semantics remain intact;
- accessible name comes from Field or explicit semantic label;
- current text/query is the value;
- <code>expanded</code> reflects popup state;
- <code>controlsNodes</code> references a stable popup semantics identifier;
- <code>SemanticsRole.comboBox</code> is used only after the spike proves it does not degrade supported targets;
- required, invalid, description, and error state come from Field integration;
- editing, selection, focus, and submit actions remain available.

Popup:

- one <code>SemanticsRole.list</code> container with a stable identifier;
- options use <code>SemanticsRole.listItem</code> plus selected/enabled/tap properties because Flutter 3.41.2 lacks a dedicated option role;
- actual selection is not conflated with keyboard highlight;
- empty/loading status has a concise status node if it changes while the input is focused;
- decorative checkmarks/icons are excluded.

Active option:

- must be announced when changed by keyboard without moving real focus out of the input;
- announcement uses the required option text value and avoids hard-coded English position phrases;
- unchanged highlight does not reannounce;
- rapid repeats do not create an unintelligible backlog;
- actual screen-reader behavior is a manual release gate.

### 18.9 Required widget and semantics tests

- Child/builder and controller ownership invariants.
- Query callback for typing, paste, cut, programmatic controller update policy, and clear.
- Single controlled selection, parent rejection, display string, and close-on-select.
- Multiple add/remove, immutable sets, clear-query setting, and selected-state rebuild.
- Dynamic option add/remove/reorder/disable while highlighted.
- Open-on-input, open-on-focus, controller open, outside close, and disabled/read-only paths.
- Exact keyboard table, including Tab, Escape, text-editing keys, and Alt variants if supported.
- IME composing Enter is not intercepted.
- Input focus and caret survive popup navigation and result updates.
- Disabled options skipped for pointer, keyboard, and semantics.
- Collision and inset change.
- Input semantics label/value/expanded/controlled relation.
- Popup/list-item roles and selected/enabled states.
- Required/invalid/error Field integration.
- Active-option announcement strategy changes once per highlight and not on unrelated rebuild.
- No debug semantics exception on the minimum SDK.
- Exclusion and localization/RTL cases.

### 18.10 Integration and screenshot scenarios

Stable fixture keys:

- <code>combobox.input</code>
- <code>combobox.popup</code>
- <code>combobox.option.apple</code>
- <code>combobox.option.banana</code>
- <code>combobox.option.disabled</code>
- <code>combobox.query</code>
- <code>combobox.selection</code>
- <code>combobox.no-results</code>

Integration scenarios:

1. Focus input, type to filter, arrow through results, Enter select, and verify focus/value/callback.
2. Escape closes without changing query or accepted selection.
3. Tab closes and moves to the next page control without accepting highlight.
4. Left/Right/Home/End edit or move the caret rather than navigate options.
5. Exercise an IME composition where target automation supports it; at minimum unit-test the composing-range branch.
6. Dynamically remove the highlighted result and verify safe next state.
7. Run multiple selection, remove a selected chip with its labeled control, and keep input usable.
8. Show no results, loading, disabled option, invalid Field, RTL, and mobile keyboard-inset cases.
9. Inspect web accessibility tree for name, value, expanded state, controlled popup, list, and options.

Required screenshots:

- <code>combobox__closed_value__macos__reference.png</code>
- <code>combobox__open_highlight__macos__reference.png</code>
- <code>combobox__filtered_results__web__reference.png</code>
- <code>combobox__no_results__web__reference.png</code>
- <code>combobox__multiple_values__macos__reference.png</code>
- <code>combobox__invalid_field__android__reference.png</code>
- <code>combobox__keyboard_inset_collision__android__reference.png</code>
- <code>combobox__rtl__web__reference.png</code>
- <code>combobox__200_text__macos__reference.png</code>

Manual checks must cover typing, active-option announcements, selection, expanded/collapsed state, no results, invalid state, multiple values, Escape, and leaving with Tab. A result of “the semantics tree looks correct” is insufficient.

### 18.11 Combobox non-goals

- Filtering, fuzzy scoring, remote search, paging, caching, or result virtualization policy.
- Product-specific empty/loading content.
- Automatic creation of domain values from free text.
- Styled chips or chip overflow.
- Date, tree, grid, or command-palette popup variants in the first release.

### 18.12 Combobox acceptance

- [ ] The accessibility spike is attached and names every tested target.
- [ ] Input retains focus and native editing keys.
- [ ] Active option is understandable with real assistive technology.
- [ ] Single and multiple controlled state cannot mutate caller inputs.
- [ ] Field semantics integrate without duplicate label/error output.
- [ ] Real macOS, Android, and web integration scenarios pass.
- [ ] All nine screenshot states are reviewed.
- [ ] Known Flutter engine limitations are documented without overstating support.

## 19. Component contract: Hover Card / Preview Card

### 19.1 Why it is needed

Hover Card shows a visual preview of a link destination while the pointer hovers or the link has keyboard focus. It differs from Tooltip:

- the content is richer and larger;
- the pointer must be able to move onto it without dismissal;
- it previews information already available at the destination;
- it is normally ignored by screen readers to avoid duplicating the link destination;
- it must satisfy WCAG behavior for content appearing on hover or focus.

It also differs from Popover: Hover Card is non-interactive preview content and does not enter the Tab sequence. Interactive or essential content belongs in Popover.

### 19.2 Confirmed reusable foundation and gap

Current <code>NakedTooltip</code> uses Flutter <code>RawTooltip</code>, hover/touch delays, dismissal delay, trigger modes, positioning, and optional tooltip semantics. It does not promise hoverable rich content, a pointer grace corridor, focus-triggered preview behavior, or screen-reader-excluded destination preview.

Current <code>NakedPopover</code> supplies overlay and focus-restoration foundations but is click-oriented and intended for interactive content.

Hover Card should reuse private overlay positioning and lifecycle utilities, not overload Tooltip with contradictory semantics.

### 19.3 Proposed public API

~~~dart
enum NakedHoverCardOpenReason {
  hover,
  focus,
  programmatic,
}

class NakedHoverCardState extends NakedState {
  NakedHoverCardState({
    required super.states,
    required this.isOpen,
    required this.openReason,
  });

  final bool isOpen;
  final NakedHoverCardOpenReason? openReason;
}

const NakedHoverCard({
  Key? key,
  Widget? child,
  ValueWidgetBuilder<NakedHoverCardState>? builder,
  required RawMenuAnchorOverlayBuilder previewBuilder,
  MenuController? controller,
  Duration openDelay = const Duration(milliseconds: 700),
  Duration closeDelay = const Duration(milliseconds: 300),
  bool openOnHover = true,
  bool openOnFocus = true,
  bool useRootOverlay = false,
  OverlayPositionConfig positioning = const OverlayPositionConfig(),
  FocusNode? triggerFocusNode,
  VoidCallback? onOpen,
  VoidCallback? onClose,
  bool excludePreviewSemantics = true,
});
~~~

The controller can be optional because an internal controller is reasonable; ownership rules remain explicit. The exact builder type may be specialized.

### 19.4 Behavioral contract

- Pointer entry starts the open delay.
- Leaving before the delay cancels opening.
- Focus entry starts the open delay or opens immediately if the team chooses a separate focus delay; the choice is public and tested. Recommendation: use the same default to avoid surprise flashing during keyboard traversal.
- Once open, moving the pointer from trigger to preview through the geometric gap does not close it.
- Pointer over the preview keeps it open.
- Leaving both trigger and preview starts the close delay.
- Re-entering either before close cancels the pending close without restarting the open animation.
- Focus remaining on the trigger keeps the preview open even when the pointer leaves.
- Escape closes immediately while the trigger has focus.
- Clicking the trigger continues to activate the underlying Link; Hover Card does not consume or toggle on primary click.
- The preview never requests keyboard focus and contains no focusable descendants.
- Page Tab traversal moves from the Link to the next page control, not into the preview.
- Programmatic close cancels all timers.
- App lifecycle pause/dispose cannot leave an orphan overlay or live timer.
- Viewport collision keeps the preview visible without covering the trigger when another side is available.

### 19.5 WCAG hover/focus requirements

WCAG 2.2 Success Criterion 1.4.13 requires additional content triggered by hover or focus to be:

- **dismissible:** Escape closes the preview without moving focus;
- **hoverable:** the pointer can move over the preview;
- **persistent:** it remains until hover/focus is removed, the user dismisses it, or the information becomes invalid.

Timer-only dismissal while the pointer or trigger focus remains is forbidden.

### 19.6 Semantics contract

- The trigger retains its native Link semantics, name, URL, actions, and focus.
- The Hover Card wrapper adds no second button, tooltip, or link node.
- Preview content is excluded from semantics by default.
- The preview must not contain unique instructions, status, controls, or information needed to understand or operate the page.
- If a team believes preview content must be accessible, it should use Popover or render the information in normal page content rather than set an escape-hatch flag casually.
- Decorative preview images have no semantics.
- Escape dismissal is keyboard behavior; it is not represented as a fake semantic action on the Link.

### 19.7 Pointer-grace implementation requirement

A simple close timer alone is not sufficient when a visible gap separates trigger and preview. Implement and test either:

- a pointer grace polygon/corridor between the exit point and preview bounds; or
- a hit-testable safe region that does not block unrelated controls.

The grace region must update when the overlay flips sides and must not keep the card open after the pointer moves away from both surfaces.

### 19.8 Required widget and semantics tests

- Hover open delay, pre-open cancellation, close delay, and re-entry cancellation.
- Focus open/close behavior and Escape.
- Combined hover plus focus reasons; removing one reason does not close while the other remains.
- Pointer movement across the trigger-preview gap on all four placement sides.
- Pointer departure outside the grace corridor closes.
- Underlying Link primary activation still fires exactly once.
- Preview has no focusable descendants in the canonical contract.
- Tab skips the preview.
- Controller open/close, replacement, disposal, and pending timer cancellation.
- Collision and RTL placement.
- Every relevant trigger semantics field is identical with and without the Hover Card wrapper.
- Preview nodes are absent from the semantics tree by default.
- Exclusion cannot hide the trigger.
- No unchanged rebuild reopens, recloses, or restarts timers.

### 19.9 Integration and screenshot scenarios

Stable fixture keys:

- <code>hover-card.link</code>
- <code>hover-card.preview</code>
- <code>hover-card.next-focus</code>
- <code>hover-card.open-state</code>

Integration scenarios:

1. Hover shorter than delay and verify no preview.
2. Hover through delay, move across the gap onto preview, wait beyond close delay, and verify still open.
3. Move outside both, wait exact close delay, and verify closed.
4. Keyboard-focus the Link, verify preview, press Escape, verify closed and focus unchanged.
5. Reopen and Tab; verify next page control receives focus.
6. Activate the Link while preview is open and verify the Link callback once.
7. Open near each edge and verify collision-safe placement.

Required screenshots:

- <code>hover_card__hover_open__macos__reference.png</code>
- <code>hover_card__keyboard_focus__web__reference.png</code>
- <code>hover_card__pointer_grace__macos__reference.png</code>
- <code>hover_card__collision_edge__web__reference.png</code>
- <code>hover_card__200_text__macos__reference.png</code>
- <code>hover_card__rtl__web__reference.png</code>

Manual checks confirm the Link is announced normally, no duplicate preview text appears in screen-reader navigation, Escape works, keyboard focus does not enter the card, and essential information is available at the destination.

### 19.10 Touch behavior and non-goals

Hover Card has no required touch-only trigger. Long press is already used by system text/link behavior and Context Menu, and a hidden preview is a poor place for essential mobile information. Consumers needing touch access should use Popover.

Other non-goals:

- interactive buttons, links, text fields, or scrolling inside the preview;
- product data fetching and caching;
- destination navigation;
- preview styling or animation design.

### 19.11 Hover Card acceptance

- [ ] Dismissible, hoverable, and persistent behavior is automated.
- [ ] Pointer grace passes all placement sides.
- [ ] Link activation and semantics remain unchanged.
- [ ] Preview is absent from semantics and Tab traversal.
- [ ] Timers are deterministic and disposed.
- [ ] All screenshot and manual accessibility evidence is attached.

## 20. Component contract: Link

### 20.1 Why it is needed

Remix needs a reusable inline navigation primitive. A Link is not a text-styled Button: assistive technologies identify it as navigation, keyboard users activate it with Enter, and Space should remain available for page scrolling rather than triggering it.

### 20.2 Proposed public API

~~~dart
class NakedLinkState extends NakedState {
  NakedLinkState({
    required super.states,
    required this.linkUrl,
  });

  final Uri? linkUrl;
}

const NakedLink({
  Key? key,
  Widget? child,
  ValueWidgetBuilder<NakedLinkState>? builder,
  VoidCallback? onPressed,
  Uri? linkUrl,
  bool enabled = true,
  FocusNode? focusNode,
  bool autofocus = false,
  MouseCursor? mouseCursor,
  bool enableFeedback = true,
  ValueChanged<bool>? onFocusChange,
  ValueChanged<bool>? onHoverChange,
  ValueChanged<bool>? onPressChange,
  String? semanticLabel,
  String? semanticHint,
  bool excludeSemantics = false,
});
~~~

Naked UI does not depend on URL launching or a router. <code>linkUrl</code> is semantics metadata; <code>onPressed</code> performs application navigation. Effective enabled state is <code>enabled && onPressed != null</code>.

### 20.3 Interaction contract

- Primary pointer tap activates once.
- A canceled pointer sequence clears pressed state and does not activate.
- Enter and Numpad Enter activate while focused.
- Space is not intercepted and does not activate the Link.
- Semantic tap activates through the same callback path.
- Disabled links do not activate, focus through normal traversal, emit feedback, or show an activation cursor.
- Hover, focus, press, and disabled state are visible to the builder and scope.
- The default enabled cursor is <code>SystemMouseCursors.click</code>; the disabled default is basic.
- Callback removal while focused immediately makes the Link effectively disabled and removes activation.
- Rebuild, focus-node replacement, and disposal do not leak listeners.
- The package does not invent visited state because it does not own navigation history.

### 20.4 Semantics contract

Flutter represents links with properties rather than <code>SemanticsRole.link</code>. Use:

- <code>link: true</code>;
- <code>linkUrl: linkUrl</code> when supplied;
- enabled state;
- accessible name from visible text or <code>semanticLabel</code>;
- caller-localized <code>semanticHint</code> for behavior such as opening a new window;
- tap action only when effectively enabled;
- focused/focusable state consistent with keyboard focus.

Additional rules:

- Do not also expose button semantics.
- If <code>linkUrl</code> is non-null, the Link flag must be true; Flutter asserts this invariant.
- A decorative external-link icon is excluded from semantics when the hint already conveys the behavior.
- Disabled Link remains a discoverable disabled link when included in semantics, but has no action.
- <code>excludeSemantics</code> hides the Link subtree and is documented as an advanced escape hatch.

### 20.5 Text and gesture considerations

- Wrapping rich or selectable text must not break text selection outside the actual activation surface.
- Secondary click remains available for a surrounding Context Menu where the consumer composes one.
- Modifier-click behavior such as opening a new browser tab is router/platform policy and not synthesized in the first API.
- The hit target comes from the styled child. The canonical example and Remix must meet platform target-size guidance where the Link is presented as a standalone control; inline text links should preserve readable line layout and a discoverable focus indication.

### 20.6 Required widget and semantics tests

- Child/builder assertion and state-scope behavior.
- Pointer tap, canceled gesture, Enter, Numpad Enter, semantic tap, and callback count.
- Space does not activate.
- Enabled, explicit disabled, and null-callback effective disabled cases.
- Hover/focus/press callback transitions.
- Focus-node ownership, replacement, and disposal.
- Dynamic callback removal while focused.
- Link flag, URL, name, hint, enabled, focus, and tap action.
- No button flag.
- Disabled action absent.
- Visible child semantics versus overriding semantic label has no duplicate name.
- External-icon exclusion.
- Non-English label/hint and RTL fixture.
- <code>excludeSemantics</code> removes the node.

### 20.7 Integration and screenshot scenarios

Stable fixture keys:

- <code>link.primary</code>
- <code>link.disabled</code>
- <code>link.external</code>
- <code>link.result</code>
- <code>link.next-focus</code>

Integration scenarios:

1. Tab to Link, press Enter, and verify one navigation callback plus retained predictable focus.
2. Focus Link, press Space, and verify no callback.
3. Pointer hover/press/tap and verify state readout.
4. Invoke semantic tap and verify the same callback.
5. Verify disabled Link is skipped by Tab and has no pointer or semantics action.
6. Compose Hover Card and Context Menu around Link and verify primary, secondary, hover, and keyboard paths do not conflict.

Required screenshots:

- <code>link__default_inline__macos__reference.png</code>
- <code>link__hover__web__reference.png</code>
- <code>link__keyboard_focus__macos__reference.png</code>
- <code>link__disabled__android__reference.png</code>
- <code>link__external_hint__web__reference.png</code>
- <code>link__long_text_200__macos__reference.png</code>
- <code>link__rtl__web__reference.png</code>

Manual checks confirm “link” rather than “button,” URL exposure where supported, correct label/hint, Enter activation, no Space activation, visible focus, and disabled behavior.

### 20.8 Link non-goals

- Router integration or URL launching.
- Visited-history storage.
- Browser download behavior.
- Modifier-click/window management in the first release.
- Link color, underline, icon, or typography.

### 20.9 Link acceptance

- [ ] Link semantics and URL metadata are exact.
- [ ] Button semantics are absent.
- [ ] Enter activates and Space does not.
- [ ] Disabled state has no focus/action.
- [ ] Hover Card and Context Menu composition has integration proof.
- [ ] All screenshot and assistive-technology evidence is attached.

## 21. Integration, screenshot, golden, and CI implementation

### 21.1 First repair the aggregate harness

Before relying on new component results:

1. Change <code>tool/run_integration_all.sh</code> to enter <code>packages/example</code>, not <code>example</code>.
2. Ensure <code>all_tests.dart</code> imports Tooltip and every new component; the current pinned aggregate omits the existing Tooltip integration file.
3. Remove the two-second real delay in <code>tearDownAll</code> unless a documented runner bug requires it.
4. Replace cleanup <code>pumpAndSettle()</code> with bounded, component-aware cleanup.
5. Replace helpers that swallow keyboard exceptions.
6. Make tab-order helpers assert the actual focus node after each move.
7. Give each integration group a normal bounded timeout instead of a blanket 30-minute default that conceals hangs.
8. Run the shell runner in CI so stale paths and missing aggregate imports are caught.

### 21.2 Deterministic pumping

Use exact pumps for known transitions:

~~~dart
await tester.pump(); // apply state/focus change
await tester.pump(const Duration(milliseconds: 200)); // fixed transition
~~~

For an asynchronous condition whose duration is not a public invariant, use a bounded helper:

~~~dart
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxFrames = 30,
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var frame = 0; frame < maxFrames; frame += 1) {
    if (condition()) return;
    await tester.pump(step);
  }
  fail('Condition was not reached within the bounded frame budget.');
}
~~~

Do not use <code>pumpAndSettle()</code> for:

- a Toast viewport with active dismissal timers;
- a Hover Card with pending open/close delay;
- a repeating or indeterminate animation;
- a cursor blink;
- an overlay intentionally holding a scheduled frame.

A bounded helper must fail with a useful state diagnostic rather than silently continue.

### 21.3 Screenshot helper

Initialize one integration binding:

~~~dart
final binding =
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
~~~

Before an Android screenshot, convert the Flutter surface once in setup:

~~~dart
await binding.convertFlutterSurfaceToImage();
await tester.pump();
~~~

Capture after all deterministic state and focus assertions:

~~~dart
await binding.takeScreenshot(
  'toast__action_focused_paused__android__reference',
);
~~~

Use conditional imports for platform setup. A helper imported by web tests must not import <code>dart:io</code>. Keep:

- a shared screenshot interface;
- an IO implementation for Android/macOS setup;
- a web-safe implementation;
- artifact naming and metadata shared across targets.

The screenshot is taken only after assertions pass, so an image never masks a failed state transition.

### 21.4 Screenshot manifest

Every CI artifact bundle includes a machine-readable or Markdown manifest:

The component contracts enumerate 51 distinct required screenshot names across macOS, Android, and web. Treat that list as the minimum review set; do not replace it with one generic gallery image per component.

| Field | Example |
|---|---|
| Component | Toast |
| Scenario | action focused and timer paused |
| File | <code>toast__action_focused_paused__web__reference.png</code> |
| Git commit | Full Naked UI SHA |
| Flutter | 3.41.2 |
| Target | Chrome on Ubuntu runner |
| Surface | 800 by 600 logical pixels |
| DPR | 1.0 |
| Locale/direction | en-US / LTR |
| Text scale | 1.0 |
| Animation mode | disabled or fixed-duration |
| Test result | pass |
| Reviewer | name/date |

Screenshots produced on a different SDK or surface are not silently compared as the same baseline.

### 21.5 Golden harness

Add canonical example golden tests under:

<code>packages/example/test/goldens/components</code>

The harness fixes:

- Flutter SDK and host OS image;
- physical size and device-pixel ratio;
- locale and direction;
- text scale;
- brightness;
- font files loaded with <code>FontLoader</code>;
- animation state and clock;
- safe-area padding;
- scroll position and pointer/focus state.

Use focused component finders with <code>matchesGoldenFile</code>. Include enough surrounding surface to verify overlay placement when that is the subject of the test.

The only approved baseline update flow is:

~~~sh
cd packages/example
flutter test test/goldens --update-goldens
flutter test test/goldens
~~~

The update commit includes an explanation of the intended visual change and reviewed image diffs.

### 21.6 Accessibility-guideline fixture

For every canonical styled component state with interactive controls:

~~~dart
final semantics = tester.ensureSemantics();
addTearDown(semantics.dispose);

await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
await expectLater(tester, meetsGuideline(textContrastGuideline));
~~~

Apply only meaningful guidelines to a given fixture. For example, a purely decorative excluded Hover Card preview does not need a label itself, but its Link trigger does. Inline Link target-size interpretation needs product review because enlarging a target can distort text layout; label, keyboard focus, and contrast still remain mandatory.

### 21.7 Exact local commands

From the Naked UI repository root:

~~~sh
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test packages/naked_ui/test
flutter test packages/example/test
~~~

Target one component while developing:

~~~sh
flutter test packages/naked_ui/test/src/naked_toast_test.dart
flutter test packages/naked_ui/test/semantics/naked_toast_semantics_test.dart
flutter test packages/example/test/goldens/components/naked_toast_golden_test.dart
~~~

Fast integration smoke:

~~~sh
cd packages/example
flutter test -r compact -d flutter-tester integration_test/components/naked_toast_integration.dart
~~~

Real macOS target:

~~~sh
cd packages/example
flutter config --enable-macos-desktop
flutter test -r compact -d macos integration_test/components/naked_toast_integration.dart
flutter test -r compact -d macos integration_test/all_tests.dart
~~~

The pinned upstream example does not contain a committed macOS directory. The team must deliberately choose to commit generated platform files or generate them reproducibly in CI before the real-target command. Do not fall back to <code>flutter-tester</code> while retaining a “macOS” job name.

Android emulator:

~~~sh
cd packages/example
flutter create --platforms android .
flutter test -r compact -d emulator-5554 integration_test/components/naked_toast_integration.dart
~~~

Web requires a web-safe integration driver. A standard driver entry is:

~~~dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
~~~

Generate the platform files if the project has chosen CI generation:

~~~sh
cd packages/example
flutter create --platforms web .
~~~

Start ChromeDriver in terminal A:

~~~sh
chromedriver --port=4444
~~~

While it remains running, execute the test in terminal B:

~~~sh
cd packages/example
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/all_tests.dart -d chrome
~~~

Stop terminal A after the test. Keep ChromeDriver lifecycle in its own CI step. Do not use an unbounded background process locally without arranging cleanup.

### 21.8 Proposed blocking CI matrix

| Job | SDK/target | Trigger | Blocking proof |
|---|---|---|---|
| Exact-minimum analyze/unit/semantics | Flutter 3.41.0, Ubuntu | Every PR | Declared package minimum compatibility |
| Primary format/analyze/unit/semantics | Flutter 3.41.2, Ubuntu | Every PR | Current pinned SDK behavior and semantics tree |
| Canonical example/goldens/guidelines | Flutter 3.41.2, pinned Ubuntu image | Every affected PR | Stable visual fixture, labels, targets, contrast |
| Integration smoke | <code>flutter-tester</code> | Every affected PR | Fast aggregate wiring and behavior |
| Real macOS integration | Flutter 3.41.2, <code>-d macos</code> | Every affected PR | Desktop focus, pointer, keyboard, overlays, screenshots |
| Android integration | API 34 emulator, Flutter 3.41.2 | Affected PRs or merge queue; always before release | Touch, long press, TalkBack-oriented semantics, safe areas, screenshots |
| Web integration | Pinned Chrome/ChromeDriver, Flutter 3.41.2 | Affected PRs or merge queue; always before release | Keyboard, accessibility DOM, screenshots |
| Remix consumer | Remix FVM Flutter 3.44.0 | Release candidate | Package/API compatibility with actual consumer floor |
| iOS manual release check | Remix-supported iOS target | Before tagged release | VoiceOver and platform focus/gesture behavior |

If cost prevents Android/web on every PR, use path filtering and a merge queue. A release must not proceed from a manual workflow that nobody ran.

### 21.9 CI artifact retention

Upload:

- screenshot manifest and all named screenshots;
- golden failure current/expected/diff images;
- <code>flutter doctor -v</code>;
- test machine target list;
- integration result JSON where available;
- semantics/accessibility spike notes for Combobox;
- manual AT checklist as a PR attachment or linked document.

Keep failed-run artifacts long enough for reviewers to inspect them. Do not upload secrets, home-directory dumps, or unrelated logs.

### 21.10 Flake policy

- A retry may gather evidence but must not turn a flaky first failure green without recording it.
- No blanket <code>continue-on-error</code> on required component checks.
- No catch-and-log around keyboard, screenshot, or semantics operations.
- No arbitrary real sleep used as a stability fix.
- A quarantined test has an issue, owner, reason, and removal date; the affected component cannot be declared fully validated.
- Timer tests use fake frame time.
- Pointer coordinates derive from finder geometry rather than hard-coded global pixels except when testing viewport edges.

### 21.11 Leak and disposal checks

Every overlay/timer component test suite includes:

- dispose while closed;
- dispose while open;
- dispose with a pending open timer;
- dispose with a pending close timer;
- replace external controller while open;
- remove trigger while open;
- route change while open;
- no exception from stale callback;
- no remaining overlay entry;
- no active timer or focus listener owned by the component.

Where Flutter exposes useful debug assertions for transient callbacks, scheduled frames, or overlay state, assert them after deterministic cleanup.

## 22. Required handoff package for the Naked UI team

The implementation handoff is a reviewable evidence set, not just a package version.

### 22.1 Per-component PR contents

Each PR includes:

1. **Contract summary:** public API and observable behavior delivered.
2. **Compatibility statement:** source, semantic, keyboard, and focus changes to existing APIs.
3. **Implementation notes:** state ownership, controller ownership, focus nodes, overlays, timers, and localization.
4. **Test map:** requirement-to-test-file and test-name mapping.
5. **Screenshot manifest:** links to every required state.
6. **Accessibility evidence:** semantics assertions, guidelines, and manual AT results.
7. **Platform evidence:** exact commands/CI runs for flutter-tester, macOS, Android, and web as applicable.
8. **Known limitations:** Flutter issues, target deviations, and explicit non-goals.
9. **Documentation:** API docs, example, migration note, and changelog.
10. **Consumer note:** how Remix should adopt the API and what it must still test.

### 22.2 Requirement traceability table template

| Requirement ID | Requirement | Automated test | Platform run | Screenshot | Manual AT | Result |
|---|---|---|---|---|---|---|
| TOAST-FOCUS-01 | Showing a toast does not move focus | <code>naked_toast_test.dart</code>: named test | macOS + web | N/A | VoiceOver | Pass |
| TOAST-TIMER-02 | Hover preserves remaining duration | named test | macOS | paused screenshot | N/A | Pass |
| TOAST-SEM-03 | Polite toast uses status role once | named semantics test | web | N/A | VoiceOver + Chrome tree | Pass |

Use stable IDs in the PR description or component issue. Do not leave rows with “covered generally.”

### 22.3 Manual accessibility result template

~~~markdown
#### Manual AT check

- Component/scenario:
- Naked UI commit:
- Flutter version:
- Device/OS:
- Browser, if web:
- Assistive technology/version:
- Starting focus:
- Actions performed:
- Expected announcement/behavior:
- Actual result:
- Pass/fail:
- Evidence or linked issue:
- Tester/date:
~~~

### 22.4 Screenshot review template

~~~markdown
#### Visual review

- Manifest/artifact link:
- Expected surface, DPR, locale, direction, text scale:
- States reviewed:
- Overlay collision checked:
- Focus indicator visible:
- Text clipping/overflow checked:
- Safe area checked:
- Diff expected:
- Reviewer/date:
~~~

### 22.5 API review questions

Before approval, reviewers answer:

- Can the behavior be styled without forking it?
- Is any product/business rule accidentally in Naked UI?
- Is state truly controlled or controller-owned as documented?
- Can a disabled path still activate through semantics or keyboard?
- Does every focus node have clear ownership?
- Can a timer or overlay survive disposal?
- Are semantic name, role, state, value, and actions all represented?
- Does the API require hard-coded English from the package?
- Does a screenshot cover only appearance, while semantics and keyboard have separate proof?
- Is an existing consumer likely to experience a semantic behavior change even if code still compiles?

## 23. Release, rollout, and Remix consumption

### 23.1 Package-level definition of done

No component is done until:

- [ ] Public API and doc comments are complete.
- [ ] Source formatting and analysis pass.
- [ ] Widget, semantics, and relevant parity tests pass.
- [ ] Aggregate integration imports and runner pass.
- [ ] Real macOS integration passes.
- [ ] Android and web required scenarios pass before release.
- [ ] Canonical goldens and accessibility guidelines pass.
- [ ] Required screenshots are reviewed.
- [ ] Manual VoiceOver, TalkBack, and web results are recorded.
- [ ] Disposal/leak cases pass.
- [ ] Compatibility and migration notes are written.
- [ ] Changelog names semantic or keyboard behavior changes.
- [ ] Open decisions for the component are resolved.
- [ ] No required check is ignored, swallowed, or advisory-only.

### 23.2 Recommended release grouping

Prefer incremental prereleases rather than one large release:

1. Dialog role + Link + Field.
2. Toggle Group + Context Menu.
3. Toast + Hover Card.
4. Combobox only after the accessibility spike and cross-platform proof.

Combobox should not delay stable, lower-risk primitives if its engine mapping remains blocked.

### 23.3 Remix adoption steps

Remix currently consumes <code>naked_ui ^0.2.0-beta.7</code>, while the audited upstream main reports <code>1.0.0-beta.3</code>. Treat this as a migration, not a routine patch bump:

1. Create a dedicated Remix dependency-upgrade PR.
2. Review Naked UI changelogs and public API differences between the pinned version and release candidate.
3. Update one existing Remix component at a time and keep its tests green.
4. Add new Remix components only after the base upgrade is stable.
5. Run Remix with its configured Flutter 3.44.0 FVM SDK.
6. Repeat accessibility guidelines and goldens using Remix's actual styles.
7. Keep a temporary compatibility table mapping each Remix component to the Naked API version it requires.
8. Do not use a broad dependency override in the release branch without pinning a reviewed commit.

### 23.4 Proposed Remix implementation order

After Naked releases:

1. Popover from existing <code>NakedPopover</code>.
2. Link.
3. Field integration for TextField and Select validation.
4. Segmented/Toggle Group.
5. Alert Dialog variant.
6. Context Menu.
7. Toast.
8. Hover Card.
9. Combobox after the separate accessibility gate.

Skeleton, Drawer/Sheet, and basic Scroll Area can proceed independently in Remix using the boundary decisions in section 3.1.

### 23.5 Rollback strategy

- New components are additive and can be withheld from Remix exports without reverting the Naked dependency.
- Existing Dialog and Toggle behavior changes require feature-level migration notes and targeted regression tests.
- If a platform semantics regression is found, prefer disabling the affected new semantic mapping behind an explicit compatibility option only as a short-lived patch with an issue and removal plan.
- Never solve a screen-reader regression by excluding the entire component from semantics.
- Keep the previously working package lock available for a Remix rollback until the upgrade PR has passed release validation.

## 24. Open decisions and risk register

No item in this section should be decided silently during implementation. Record the resolution in the relevant issue/PR and update public documentation.

### 24.1 Decision log

| ID | Decision | Recommendation | Owner | Must resolve by |
|---|---|---|---|---|
| D-01 | Toggle option semantics migration | Use button + toggled for all Toggle Group modes; document the announcement change. Keep Radio Group for radio semantics. | Naked API + accessibility reviewers | Before Toggle Group implementation |
| D-02 | Alert Dialog initial focus API | Keep optional <code>initialFocusNode</code>, document safe-target heuristics, and make canonical examples explicit. | Naked API reviewer | Before Alert Dialog PR approval |
| D-03 | Context Menu trigger semantic action | Preserve child role and expose long-press semantics; avoid a fake button. Prototype discoverability with VoiceOver/TalkBack. | Accessibility reviewer | During Context Menu spike |
| D-04 | Toast composition API | Use structured message/action/close helpers so duplicate message semantics can be excluded without hiding controls. | Naked API reviewer | Before Toast tests are written |
| D-05 | Toast global shortcut | Caller opt-in; canonical example may use F8. Do not reserve a key globally by default. | Naked maintainer | Before Toast PR approval |
| D-06 | Toast queue overflow | Default unlimited pending queue or add explicit nullable <code>maxQueued</code>; never silently drop without a dismissal reason. | Naked API reviewer | Before controller implementation |
| D-07 | Toast swipe in first release | Defer unless all alternate dismissal and deterministic drag tests fit the PR. | Product + maintainer | At Toast scoping |
| D-08 | Field/TextField duplicate metadata | Debug-assert conflicting values; allow identical explicit values; field scope is semantic source of truth. | Naked API reviewer | Before Field implementation |
| D-09 | Initial Field error announcement | Make initial error discoverable but not automatically assertive; announce later error transitions once. | Accessibility reviewer | Before Field semantics tests |
| D-10 | Combobox active-option strategy | Select only after the required macOS/Android/web spike; a status announcer is the leading fallback if role mapping alone is insufficient. | Accessibility + Flutter platform reviewer | Before Combobox public API freeze |
| D-11 | Combobox role on Flutter 3.41 | Use only if prototype has no regression; otherwise document fallback and upstream issue without claiming complete mapping. | Flutter platform reviewer | During Combobox spike |
| D-12 | Naked UI minimum Flutter | Keep <code>>=3.41.0</code> only if an exact 3.41.0 job passes; otherwise raise the minimum deliberately. | Package maintainer | Before first release candidate |
| D-13 | Example platform directories | Commit reviewed minimal platform files or generate them reproducibly in CI; real target job names must match actual devices. | CI maintainer | Test-harness PR |
| D-14 | Golden host/font | Pin one Ubuntu image, Flutter 3.41.2, surface configuration, and checked-in licensed test font. | CI + design reviewer | Test-harness PR |
| D-15 | Android/web PR frequency | Prefer affected-path PR/merge-queue jobs; release is blocked unless both have passed the exact release commit. | CI maintainer | Test-harness PR |

### 24.2 Risk register

| Risk | Likelihood/impact | Detection | Mitigation | Exit condition |
|---|---|---|---|---|
| Flutter semantics enum is not fully mapped on a target | High for Combobox / high impact | Real AT spike and web accessibility tree | Keep properties correct, prototype fallback announcement, track upstream issue | Active option, expanded state, selection, and errors are understandable on supported targets |
| Duplicate screen-reader announcements | Medium / high | Manual AT plus one-node semantics assertions | Single semantic source, structured Toast/Field helpers, avoid role + liveRegion conflict | One intended announcement per transition |
| Focus trap or restoration regression | Medium / high | Real-target keyboard integration | Managed nodes, explicit invoker tracking, remove-trigger tests | All open/close paths restore or safely fall back |
| Timer flakiness | High / medium | Repeated CI and pending-timer disposal tests | Injectable durations, fake frame time, bounded pumps | Repeated suite has no retry-dependent pass |
| Overlay collision differs by platform | Medium / medium | Four-edge screenshots on macOS/web/Android | Shared positioning utility, geometry assertions | Overlay bounds pass on required surfaces |
| Headless package overclaims contrast/target accessibility | Medium / high | Review of test layer and docs | Keep guidelines in canonical example and Remix, document boundary | Release notes state exact scope of guarantees |
| Existing semantic behavior changes without source break | Medium / high for Toggle/Dialog | Changelog review and old/new semantics tests | Explicit compatibility note and migration tests | Consumer review signs off |
| Hidden integration file is not run | Medium / high | Aggregate import audit and shell runner CI | Import every component; compare file inventory to aggregate | Inventory check passes |
| Text editing shortcuts are stolen by Combobox | Medium / high | Keyboard table and IME tests | Input retains focus; handle only permitted keys; composing guard | Editing/caret/IME tests pass |
| Hover Card contains essential or interactive content | Medium / medium | Example/content review and focus scan | Strong non-goal; use Popover instead | Preview has no focusables/unique required information |
| Controller/timer listener leaks | Medium / medium | Dispose-open/pending tests | Clear ownership and listener replacement | No stale callback/overlay/timer after disposal |
| Remix dependency migration is larger than expected | High / medium | Dedicated upgrade PR and changelog audit | Separate upgrade from new components; pin reviewed release | Existing Remix suite passes on Flutter 3.44.0 |

### 24.3 Escalation rule

Block the relevant component when:

- actual screen-reader behavior contradicts the semantics contract;
- a supported target cannot perform a required keyboard or touch path;
- focus can escape or is lost after a standard close path;
- a required test is flaky without retries;
- the implementation needs product styling or business logic to make the base behavior work;
- an unresolved Flutter limitation would make the release claim misleading.

A blocked component does not block independent components from shipping.

## 25. Source register

### 25.1 Audited Remix and Naked UI sources

Local Remix:

- [Remix package dependency and SDK contract](packages/remix/pubspec.yaml)
- [Workspace Flutter version](.fvmrc)
- [Workspace package and SDK configuration](pubspec.yaml)

Pinned Naked UI upstream at <code>0ca0b8bc2269ed331345cc705d99a073acdf5f5f</code>:

- [Package version and minimum SDK](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/pubspec.yaml)
- [Public widget exports](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/lib/src/naked_widgets.dart)
- [Dialog implementation](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/lib/src/naked_dialog.dart)
- [Toggle and Toggle Group implementation](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/lib/src/naked_toggle.dart)
- [Menu implementation](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/lib/src/naked_menu.dart)
- [Popover implementation](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/lib/src/naked_popover.dart)
- [Select implementation](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/lib/src/naked_select.dart)
- [TextField implementation](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/lib/src/naked_textfield.dart)
- [Tooltip implementation](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/lib/src/naked_tooltip.dart)
- [Dialog semantics tests](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/test/semantics/naked_dialog_semantics_test.dart)
- [Menu semantics tests](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/test/semantics/naked_menu_semantics_test.dart)
- [Toggle semantics tests](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/naked_ui/test/semantics/naked_toggle_semantics_test.dart)
- [Integration aggregate](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/example/integration_test/all_tests.dart)
- [Keyboard integration helpers](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/packages/example/integration_test/helpers/keyboard_test_helpers.dart)
- [Unit-test CI](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/.github/workflows/ci.yml)
- [Current desktop integration workflow](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/.github/workflows/integration-tests.yml)
- [Current Android integration workflow](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/.github/workflows/integration-android.yml)
- [Current shell integration runner](https://github.com/btwld/naked_ui/blob/0ca0b8bc2269ed331345cc705d99a073acdf5f5f/tool/run_integration_all.sh)
- [Latest published Naked UI API index](https://pub.dev/documentation/naked_ui/latest/naked_ui/)

### 25.2 Official Flutter references

- [Accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing) — semantics tests, guideline checks, and platform accessibility tools.
- [Accessibility overview and release checklist](https://docs.flutter.dev/ui/accessibility) — Flutter's overall accessibility expectations.
- [Web accessibility](https://docs.flutter.dev/ui/accessibility/web-accessibility) — semantics-to-accessibility-DOM behavior and web considerations.
- [Assistive technologies](https://docs.flutter.dev/ui/accessibility/assistive-technologies) — screen-reader testing context.
- [Accessible UI design and styling](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling) — contrast, target size, text scale, and visual considerations.
- [Testing overview](https://docs.flutter.dev/testing/overview) — unit, widget, and integration test boundaries.
- [Focus and focus traversal](https://docs.flutter.dev/ui/interactivity/focus) — focus-node lifecycle and traversal.
- [Actions and Shortcuts](https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts) — intent/action keyboard architecture.
- [SemanticsRole API](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html) — available complex semantics roles.
- [matchesSemantics](https://api.flutter.dev/flutter/flutter_test/matchesSemantics.html) — exact semantics matcher.
- [AccessibilityGuideline](https://api.flutter.dev/flutter/flutter_test/AccessibilityGuideline-class.html) and [meetsGuideline](https://api.flutter.dev/flutter/flutter_test/meetsGuideline.html) — automated accessibility checks.
- [matchesGoldenFile](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html) — golden comparison.
- [Integration screenshot API](https://api.flutter.dev/flutter/package-integration_test_integration_test/IntegrationTestWidgetsFlutterBinding/takeScreenshot.html) — screenshot capture.
- [FocusTraversalGroup](https://api.flutter.dev/flutter/widgets/FocusTraversalGroup-class.html) — composite traversal boundaries.
- [Shortcuts](https://api.flutter.dev/flutter/widgets/Shortcuts-class.html) — logical-key mapping.
- [Flutter issue 159741](https://github.com/flutter/flutter/issues/159741) — framework role-check implementation gap referenced by the Flutter 3.41.2 source.

### 25.3 W3C WAI-ARIA and WCAG references

- [Alert Dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/)
- [Modal Dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
- [Menu Button pattern](https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/)
- [Menu and Menubar pattern, including context-menu keyboard behavior](https://www.w3.org/WAI/ARIA/apg/patterns/menubar/)
- [Combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/)
- [Button and toggle-button pattern](https://www.w3.org/WAI/ARIA/apg/patterns/button/)
- [Link pattern](https://www.w3.org/WAI/ARIA/apg/patterns/link/)
- [Toolbar composite pattern](https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/)
- [Radio Group pattern](https://www.w3.org/WAI/ARIA/apg/patterns/radio/)
- [Keyboard interface practice](https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/)
- [WCAG 2.2: Content on Hover or Focus](https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html)
- [WCAG 2.2: Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages)
- [Forms tutorial](https://www.w3.org/WAI/tutorials/forms/)
- [Form labels](https://www.w3.org/WAI/tutorials/forms/labels/)
- [Form validation](https://www.w3.org/WAI/tutorials/forms/validation/)
- [Form notifications](https://www.w3.org/WAI/tutorials/forms/notifications/)

### 25.4 Comparable headless primitive references

These are behavior references, not APIs to copy mechanically:

- [Base UI Toast](https://base-ui.com/react/components/toast)
- [Base UI Field](https://base-ui.com/react/components/field)
- [Base UI Preview Card](https://base-ui.com/react/components/preview-card)
- [Base UI Context Menu](https://base-ui.com/react/components/context-menu)
- [Base UI Toggle Group](https://base-ui.com/react/components/toggle-group)
- [Base UI Combobox](https://base-ui.com/react/components/combobox)
- [Radix Toast](https://www.radix-ui.com/primitives/docs/components/toast)
- [Radix Hover Card](https://www.radix-ui.com/primitives/docs/components/hover-card)
- [Radix accessibility overview](https://www.radix-ui.com/primitives/docs/overview/accessibility)

## 26. Final handoff summary

The Naked UI team should treat this work as a behavior and evidence program:

1. harden the integration harness so failures cannot be swallowed;
2. implement each primitive with a written semantics and focus contract;
3. prove state and semantics in widget tests;
4. prove input, overlays, focus, and timers on real targets;
5. prove a deterministic reference appearance with goldens and screenshots;
6. test actual assistive technology, especially Combobox;
7. package the evidence and compatibility notes for Remix;
8. let Remix own and revalidate the final visual system.

The release is ready when a reviewer can trace every important behavior to an automated test, a target run, a screenshot where appearance matters, and a manual assistive-technology result where platform output matters.
