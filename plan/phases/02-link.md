# Phase 2 — Link

Status: **Active — core implementation and deterministic fixture complete;
publication and real-platform evidence gates are in progress**.

Goal: add a headless inline navigation primitive that exposes Link rather than
Button semantics, activates once through primary pointer, Enter, Numpad Enter,
or semantic tap, leaves Space and secondary click available to their normal
page/composition behavior, reports immutable interaction state, and delegates
routing, URL launching, styling, localized copy, and visited history to the
consumer.

Contract: briefing [§20](../briefing.md#20-component-contract-link) (binding),
plus the cross-component rules in §§5 and 8–12. No open decision blocks Link.
Baseline commit: `d341b90e7b09e13f83da299b4ed17ae0eaa9ddee` (all current-code
findings below re-verified on 2026-07-13).

## Research and readiness

- No repository or ancestor `AGENTS.md` exists. The phase follows
  `plan/process.md`, `plan/integration-testing.md`, `plan/decisions.md`, and the
  binding briefing.
- The phase worktree is `.context/worktrees/phase-02-link` on branch
  `feat/naked-link`, created directly from the approved baseline. It does not
  stack on the unmerged Alert Dialog branch.
- There is no Link primitive, export, package test, example, registry entry,
  integration group, golden, screenshot scenario, README entry, or changelog
  entry in the baseline.
- The baseline Flutter 3.41.2 package suite passes 574 tests with three
  intentional external-integration launcher skips. This is the pre-change
  regression reference.
- Pinned Flutter 3.41.0 and 3.41.2 both expose `Semantics.link` and
  `Semantics.linkUrl`. Both assert that a non-null URL requires the Link flag.
  The pinned semantics source documents that `linkUrl` becomes the web DOM
  `href`; the callback still remains application-owned.
- Flutter has no `SemanticsRole.link` in the pinned API. The binding contract's
  `link: true` flag is the supported representation; adding Button semantics as
  a fallback would be incorrect.
- Flutter's ambient `ActivateIntent` is bound to Space on every platform. On
  web, Enter/Numpad Enter use `ButtonActivateIntent`, while Space uses a
  prioritized Activate-then-scroll path. Reusing
  `NakedIntentActions.button` or registering an `ActivateIntent` action would
  let Space activate the Link. Link therefore needs a private Link-specific
  intent mapped only from Enter and Numpad Enter; Space must remain absent from
  its local shortcuts/actions. This follows the
  [Flutter ActivateIntent contract](https://api.flutter.dev/flutter/widgets/ActivateIntent-class.html),
  [WidgetsApp shortcut contract](https://api.flutter.dev/flutter/widgets/WidgetsApp/defaultShortcuts.html),
  and [WAI-ARIA Link Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/link/).
- `NakedFocusableDetector` already owns internal focus nodes, borrows external
  nodes, swaps them without disposing caller resources, preserves focus across
  replacement, disables traditional traversal, exposes hover/focus callbacks,
  and composes `Shortcuts`/`Actions`. `WidgetStatesMixin`,
  `NakedStateScopeBuilder`, and `NakedState` provide the existing immutable
  builder/scope pattern.
- `NakedButton` is useful only as a structural reference. Its Button semantics,
  Space shortcut, long-press API, non-null click cursor default, and timer-based
  keyboard press feedback do not satisfy the Link contract and will not be
  generalized in this phase.
- A Link-specific `GestureDetector` can reserve only primary tap and leave
  secondary click unhandled. It must exclude its gesture semantics so the
  single outer Link node owns the semantic tap action.
- When `semanticLabel` overrides visible content, the semantics wrapper must
  exclude descendant naming semantics so the accessible name appears once.
  Without an override, visible text supplies the name. Decorative external-link
  icons remain explicitly excluded in the canonical consumer fixture.
- Context Menu and Hover Card do not exist at this baseline. The Link PR can
  prove that secondary click is unclaimed and hover/primary/keyboard paths are
  independent, but binding scenario 6 and acceptance cannot close until the
  later component PRs compose their real implementations around Link.
- Flutter 3.41.2 still cannot produce stable web screenshot evidence in this
  repository. The three required Link web screenshots are explicit closure
  blockers unless a stable pinned capture is established or a maintainer
  approves alternate evidence. A passing web behavior log is not substituted.
- VoiceOver, TalkBack, Chrome accessibility-tree, and release-iOS VoiceOver
  sessions require human operators. Automated semantics will not fill them.

## Contract matrices

### Universal semantics matrix

| Dimension | Link answer | Automated owner | Real/manual proof |
|---|---|---|---|
| Primitive | Discoverable Link, never Button | exact semantics test | VoiceOver, TalkBack, Chrome tree |
| Name | visible child text, or one caller-localized `semanticLabel` override | semantics tests including Arabic | all AT sessions |
| Role/flags | `link: true`; `button` absent | exact flags test | all AT sessions |
| State | enabled is `enabled && onPressed != null`; focus/focusable follows effective focus | widget + semantics transitions | macOS/Android/web |
| Value/URL | optional `linkUrl` metadata; never launches by itself | state equality + semantics URL test | Chrome tree/href inspection |
| Actions | semantic tap only while effectively enabled | semantics action/callback tests | VoiceOver/TalkBack |
| Hint | optional caller-localized `semanticHint`, once | semantics test | all AT sessions |
| Children | visible label preserved unless an explicit label overrides it; decorative icon excluded by consumer | semantics/example tests | Chrome tree |
| Exclusion | `excludeSemantics` removes the Link semantics subtree and focus semantics | semantics test | N/A |
| Ownership | external focus nodes are borrowed and never disposed | lifecycle tests | aggregate teardown |

### Input, state, and lifecycle matrix

| Path | Enabled result | Disabled/null-callback result | Required assertion |
|---|---|---|---|
| Primary tap | one callback + optional feedback | no recognizer/callback/feedback | count and state transitions |
| Canceled primary sequence | press true → false; no callback | no state transition | pointer cancel test |
| Secondary click | unclaimed; no callback | unclaimed | gesture test and later Context Menu composition |
| Enter/Numpad Enter | one callback | no callback | known focus node + complete key event |
| Space | no Link callback and no Link press state | no callback | widget test; web scroll outcome |
| Semantic tap | same activation path once | action absent | semantics action test |
| Hover | state/callback true then false | no hover callback | mouse gesture test |
| Focus/Tab | state/callback and normal traversal | skipped in traditional traversal | focus and next-target assertions |
| Callback removal | immediately disabled, activation removed, transient press/hover cleared | already disabled | rebuild test |
| Focus-node replacement | listener moves; focused state handed off; neither external node disposed | same ownership | lifecycle test |
| Disposal | internal detector node/listeners removed; external node remains usable | same | teardown/no exception |

## Requirement-to-test map

| ID | Requirement | Cheapest automated owner | Required real proof |
|---|---|---|---|
| LINK-API-01 | Child/builder invariant; immutable state/scope includes URL and all widget states | `naked_link_test.dart` + hash contract | N/A |
| LINK-ACT-01 | Primary tap once; cancellation and secondary click do not activate | widget gesture tests | macOS/web hover+pointer; Android touch |
| LINK-KEY-01 | Enter and Numpad Enter activate; Space is unclaimed | widget shortcut tests | macOS and pinned web scroll/result |
| LINK-STATE-01 | Effective enabled controls activation, traversal, feedback, cursor, and disabled state | widget transitions + platform-channel feedback test | all behavior targets |
| LINK-STATE-02 | Hover/focus/press callbacks and builder/scope snapshots are exact | widget state tests | macOS/web fixture readout |
| LINK-LIFE-01 | Focus ownership/replacement/disposal and callback removal do not leak | lifecycle tests | aggregate teardown on macOS/web |
| LINK-SEM-01 | Link flag, URL, name, hint, enabled/focus/action exact; Button absent | `naked_link_semantics_test.dart` | VoiceOver/TalkBack/Chrome tree |
| LINK-SEM-02 | Disabled action absent; label override not duplicated; icon/exclusion correct; Arabic/RTL | semantics + example tests | all AT sessions |
| LINK-COMP-01 | Primary, secondary, hover, and keyboard paths compose without conflict | Link secondary-path test now; future Context Menu/Hover Card integration | later Phase 5/7 real targets |
| LINK-VIS-01 | Inline, hover, focus, disabled, external hint, 200% text, and RTL appearance | pinned golden + screenshot scenarios | reviewed macOS/Android/web artifacts |

## Tasks

### A1. Add failing public API, state, interaction, and lifecycle tests

- **Where:** add `packages/naked_ui/test/src/naked_link_test.dart`; extend
  `packages/naked_ui/test/hashcode_contract_test.dart` only for the new public
  state type.
- **How:** first reference the binding API so the focused test fails to compile
  because `NakedLink`/`NakedLinkState` do not exist. Then, before production
  behavior, cover the constructor invariant; builder child and identical scope
  snapshot; URL equality/hash; primary tap exactly once; canceled primary and
  secondary gestures; Enter/Numpad Enter; Space with no callback or pressed
  state; explicit and effective disabled paths; default/custom/basic cursors;
  hover/focus/press callbacks; feedback only while enabled; dynamic callback
  removal; autofocus/traversal; external focus ownership, replacement, and
  disposal.
- **Red proof:** observe the missing API, then use the smallest targeted
  assertions/mutations if several behaviors become green through shared
  infrastructure. Record the first failing expectation for every group.
- **Verify:** `fvm flutter test packages/naked_ui/test/src/naked_link_test.dart`
  and the focused hash test.

### A2. Add failing exact semantics tests

- **Where:** add
  `packages/naked_ui/test/semantics/naked_link_semantics_test.dart`.
- **How:** use `ensureSemantics` with teardown-safe disposal and assert the full
  node, not only a label finder: Link true; Button absent; URI; name; hint;
  enabled; focusable/focused transitions; tap action enabled only; visible text
  naming; explicit label replacing rather than concatenating child semantics;
  disabled discoverability; Arabic label/hint in RTL; external icon excluded;
  entire semantics subtree absent under `excludeSemantics`. Invoke the semantic
  tap and assert the same callback count.
- **Red proof:** each group must fail because the Link node/metadata/action does
  not exist, not because the finder is wrong.
- **Verify:**
  `fvm flutter test packages/naked_ui/test/semantics/naked_link_semantics_test.dart`.

### B1. Implement the smallest Link behavior surface

- **Where:** add `packages/naked_ui/lib/src/naked_link.dart`; export it from
  `packages/naked_ui/lib/src/naked_widgets.dart`; add a Link namespace/private
  intent to `packages/naked_ui/lib/src/utilities/intents.dart`.
- **How:** implement `NakedLinkState` with state helpers, equality/hash, and
  `linkUrl`. Implement the binding constructor exactly, including a nullable
  `mouseCursor`, the child/builder assertion, and effective enabled
  `enabled && onPressed != null`. Compose the existing state mixin, state scope,
  focusable detector, primary-only gesture path, and one Link semantics node.
  Route pointer, key, and semantic activation through one guarded method with
  feedback. Map only Enter/Numpad Enter to a private Link intent; do not expose
  an Activate/Button action and do not bind Space. Clear transient state when
  effective enabled becomes false. Borrow the external focus node through the
  detector and never dispose it. Use `Semantics(excludeSemantics: true)` only
  when an explicit semantic label replaces child naming; use outer exclusion
  plus disabled focus semantics for the advanced escape hatch.
- **Avoid:** router/launcher dependencies, visited state, modifier-click
  synthesis, long-press ownership, raw key handlers, timers, styles, English
  defaults, changes to Button, or a speculative generic pressable base class.
- **Verify:** focused A1/A2 tests, then
  `fvm dart format --set-exit-if-changed packages/naked_ui/lib/src/naked_link.dart packages/naked_ui/lib/src/naked_widgets.dart packages/naked_ui/lib/src/utilities/intents.dart packages/naked_ui/test/src/naked_link_test.dart packages/naked_ui/test/semantics/naked_link_semantics_test.dart packages/naked_ui/test/hashcode_contract_test.dart`
  and `fvm flutter analyze packages/naked_ui`.

### C1. Add the deterministic styled fixture, guideline, and golden proof

- **Where:** add `packages/example/lib/api/naked_link.0.dart` and
  `packages/example/test/naked_link_example_test.dart`; register it in
  `packages/example/lib/registry.dart`; extend
  `packages/example/test/accessibility_guidelines_test.dart`; add
  `packages/example/test/goldens/components/naked_link_golden_test.dart` and a
  reviewed Ubuntu baseline under `.../baselines/`.
- **How:** create one resettable, locally controlled fixture containing inline
  primary, disabled, external-hint, and next-focus targets plus visible result,
  callback count, and hover/focus/press readout. Style only in the example with
  visible focus, hover, pressed, and disabled treatments; preserve inline text
  layout; exclude the decorative external icon; provide Arabic/RTL and 200%
  text configurations; disable/fix animation for evidence. Use no network or
  router.
- **Stable keys:** `link.primary`, `link.disabled`, `link.external`,
  `link.result`, `link.next-focus`, plus `link.state`,
  `link.disable-primary`, `link.reset`, and a fixed evidence surface key.
- **Golden:** default inline/focus-capable canonical surface at 800×600, DPR 1,
  pinned Roboto, locale/direction/text scale/brightness fixed. Generate only
  through the approved Ubuntu update-then-verify diagnostic, inspect the PNG,
  and check it in unchanged with its SHA-256.
- **Guidelines:** prove label, standalone Android/iOS target size, and contrast
  on the styled fixture without forcing inline links into a button-sized line
  box.
- **Verify:** focused example, guideline, and golden commands, then all example
  tests.

### D1. Add component integration behavior and aggregate inventory

- **Where:** add
  `packages/example/integration_test/components/naked_link_integration.dart`;
  import/group it in `packages/example/integration_test/all_tests.dart`; rerun
  `packages/example/test/integration_inventory_test.dart`.
- **How:** drive only stable keys. Add five presently executable binding
  scenarios: Tab → known Link focus → Enter → one result with retained focus;
  focused Space → no callback (and observable page scroll on web); hover/down/up
  → exact state readout and one result; semantic tap → same callback path;
  disabled skipped by Tab with no pointer/semantic action. Add Arabic/RTL and
  200% long-text assertions, callback removal while focused, secondary click
  remaining unclaimed, and teardown-safe external focus-node disposal.
- **Deferred composition:** do not create fake Hover Card/Context Menu
  implementations. Record LINK-COMP-01 as a closure blocker and require Phase 5
  and Phase 7 integration suites to wrap the real `NakedLink` and prove the
  sixth scenario.
- **Pumps/cleanup:** use one event-delivery frame plus one focus-callback rebuild
  frame for traversal, one frame for other synchronous state transitions, and
  bounded observable waits only for web scrolling or platform attachment.
  Restore view, DPR, direction, text scale, scroll controller, semantics handle,
  mouse gesture, focus nodes, and fixture state. No `pumpAndSettle`, sleeps,
  retries, swallowed key/gesture errors, or blanket timeout change.
- **Verify:** focused Link integration on `flutter-tester`, inventory, then the
  aggregate.

### D2. Capture required visual evidence without weakening behavior gates

- **Where:** extend `packages/example/integration_test/screenshot_smoke.dart`,
  `packages/example/test/screenshot_evidence_test.dart`, the exact artifact
  assertions in `.github/workflows/integration-tests.yml`, and
  `tool/run_android_integration.sh`; extend the Ubuntu golden diagnostic in
  `.github/workflows/ci.yml` only as required for a genuinely absent baseline.
- **How:** assert scenario behavior before every capture. Produce and review
  `link__default_inline__macos__reference.png`,
  `link__keyboard_focus__macos__reference.png`,
  `link__disabled__android__reference.png`, and
  `link__long_text_200__macos__reference.png` with complete manifests. Keep the
  three binding web names (`hover`, `external_hint`, `rtl`) explicitly blocked
  by the documented Flutter 3.41.2 limitation; do not manufacture a widget
  golden or behavior log as a substitute.
- **Verify:** behavior suites first; dedicated local macOS screenshot driver;
  hosted API 34 behavior plus transport; exact file-name/size/manifest checks;
  human visual review of every required PNG produced. Record exact head and
  GitHub merge-ref separately.

### E1. Complete docs, review, evidence, and PR handoff

- **Where:** dartdoc in `naked_link.dart`; root and package READMEs; package
  changelog; registry; this plan and `plan/README.md`; PR description.
- **How:** document Link-versus-Button use, callback/URL separation, effective
  enabled, Enter/Numpad/Space behavior, state and focus ownership, semantics
  override/icon rules, secondary/modifier-click boundaries, styling and router
  non-goals, and Remix responsibilities. Build the §22 ten-item packet with the
  stable requirement table, platform commands/runs, screenshot review, manual
  AT rows, limitations, and exact SHAs.
- **Review:** inspect the entire diff for API drift, accidental Button/Space
  behavior, duplicate semantics/names/actions, disabled descendants,
  feedback/cursor/focus leaks, selection interference, router or styling scope,
  duplicated helpers, speculative abstraction, timer use, and unrelated files.
- **Delivery:** stage only Phase 2 files, commit intentionally, push
  `feat/naked-link`, and open one ready-for-review PR targeting `main`. Monitor
  every applicable check on the exact PR head, manually dispatch affected-path
  workflows if a documentation-only final commit would otherwise lack an exact
  run, and do not merge without explicit maintainer authorization.

## Integration proof plan

### Scenario-to-platform matrix

| Scenario | flutter-tester | real macOS | API 34 Android | pinned Chrome/web |
|---|---:|---:|---:|---:|
| Tab, Enter, one callback, retained focus | Yes | Required | Required focus path | Required |
| Space no activation | Yes | Required | Required | Required + scroll outcome |
| Pointer hover/press/tap state | Yes | Required | Touch/press required; hover N/A | Required hover |
| Semantic tap same callback | Yes | Required | Required | Required tree/action |
| Disabled skipped/no action/cursor | Yes | Required | Required + screenshot | Required |
| Arabic RTL + 200% long text | Yes | Required + screenshots | Required behavior | Required behavior; RTL screenshot blocked |
| Secondary click unclaimed | Yes | Required | N/A | Required |
| Real Context Menu/Hover Card composition | Not available | Deferred | Deferred | Deferred to Phase 5/7 |

### Evidence and manual sessions

- Pinned Linux golden: canonical Link surface, fixed 800×600/DPR 1/Roboto,
  reviewed with SHA-256 and mutation/compare proof.
- macOS screenshots: default inline, keyboard focus, and 200% long text.
- Android screenshot: disabled state. Hosted API 34 is authoritative because
  the local SDK is incomplete and no emulator/device is attached.
- Web screenshots: hover, external hint, and RTL are required but currently
  unsupported. Pinned behavior log and Chrome-tree record remain separate.
- Manual sessions: macOS VoiceOver, API 34 TalkBack, pinned Chrome
  accessibility tree/keyboard, and release-level iOS VoiceOver. Record exact
  target/version/actions/expected/actual/tester/date; never infer them.

## Verification and publication gates

Focused development:

```sh
fvm flutter test packages/naked_ui/test/src/naked_link_test.dart
fvm flutter test packages/naked_ui/test/semantics/naked_link_semantics_test.dart
fvm flutter test packages/naked_ui/test/hashcode_contract_test.dart
fvm flutter test packages/example/test/naked_link_example_test.dart
fvm flutter test packages/example/test/accessibility_guidelines_test.dart
fvm flutter test packages/example/test/goldens/components/naked_link_golden_test.dart
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/components/naked_link_integration.dart
```

Required local publication gate from the repository root:

```sh
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test packages/naked_ui/test
fvm flutter test packages/example/test
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```

Additional exact proof:

```sh
fvm flutter test packages/example/test/integration_inventory_test.dart
cd packages/example
fvm flutter test -r compact -d macos integration_test/components/naked_link_integration.dart
fvm flutter test -r compact -d macos integration_test/all_tests.dart
fvm flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshot_smoke.dart -d macos --dart-define=NAKED_UI_CAPTURE_SCREENSHOTS=true --dart-define=NAKED_UI_GIT_SHA=<full-sha> --dart-define=NAKED_UI_FLUTTER_VERSION=3.41.2
```

Hosted gates: primary and exact-minimum suites; canonical golden/guidelines;
`flutter-tester`; real macOS; API 34 Android behavior plus screenshot transport;
pinned Chrome/ChromeDriver behavior log; PR-title policy. Every result must be
green on the exact PR head or an identified GitHub merge ref.

## Acceptance and stop conditions

- [ ] Every A1/A2 test was observed failing for the intended missing behavior
      before implementation and the red evidence is recorded.
- [ ] Link public API, state equality/scope, and effective-enabled behavior
      match the binding contract without router, styling, or visited state.
- [ ] Primary/canceled/secondary pointer, Enter/Numpad/Space, semantic tap,
      feedback, cursor, callbacks, and dynamic removal pass focused tests.
- [ ] Link/URL/name/hint/enabled/focus/action semantics are exact; Button and
      duplicate naming are absent; disabled/excluded behavior passes.
- [ ] Focus-node ownership/replacement/disposal and aggregate teardown pass.
- [ ] Canonical fixture, stable result/reset/readout, Arabic RTL, 200% text,
      external-icon exclusion, golden, and accessibility guidelines pass.
- [ ] Integration component, inventory, fast aggregate, real macOS aggregate,
      hosted API 34, and pinned web behavior pass on the exact PR head.
- [ ] All seven screenshot names have reviewed evidence, or Phase 2 is
      explicitly blocked; unsupported web screenshots are not marked passed.
- [ ] VoiceOver, TalkBack, Chrome accessibility-tree, and release-level iOS
      records are attached; missing human evidence blocks closure.
- [ ] Real Context Menu and Hover Card composition proof is attached after
      those components exist; placeholder wrappers do not satisfy it.
- [ ] Full publication commands and hosted Flutter 3.41.0 pass.
- [ ] Docs, changelog, compatibility statement, traceability, manifests,
      visual review, and ten-item handoff packet are ready.
- [ ] Entire diff reviewed; ready-for-review PR open; exact-head checks green;
      plan/status board contain final evidence; PR remains unmerged without
      explicit maintainer authorization.

Block Phase 2 closure (not independent program work) if Link maps as a Button,
Space activates or is swallowed on web, disabled paths retain activation or
focus, linkUrl lacks the required Link flag/href mapping, accessible naming is
duplicated, focus ownership leaks, any required target is retry-dependent, the
real composition scenario is unavailable, required web screenshots remain
unsupported, or manual AT evidence is unavailable.
