# Phase 2 — Link

Status: **PR #65 reviewer corrections pass every available local publication
gate. Exact-head hosted verification (including Android) is pending publication;
closure remains blocked by required web screenshots, manual assistive-technology
sessions, and real Context Menu/Hover Card composition**.

Goal: add a headless inline navigation primitive that exposes Link rather than
Button semantics, activates once through primary pointer, Enter, Numpad Enter,
or semantic tap, leaves Space and secondary click available to their normal
page/composition behavior, reports immutable interaction state, and delegates
default navigation and native web-anchor coordination to Flutter's official
Link implementation. Consumers may replace default navigation with a custom
callback and continue to own styling, localized copy, and visited history.

Contract: briefing [§20](../briefing.md#20-component-contract-link) (binding),
plus the cross-component rules in §§5 and 8–12, as corrected by resolved
[D-16](../decisions.md#phase-2-decision-evidence-2026-07-13). D-16 supersedes
the metadata-only, callback-required clauses after real-browser review proved
they permit duplicate or disabled navigation. No open decision blocks Link.
Baseline commit: `d341b90e7b09e13f83da299b4ed17ae0eaa9ddee` (all current-code
findings below re-verified on 2026-07-13).

## Reviewer correction addendum — 2026-07-13

- `linkUrl` is the destination and availability source. Effective enabled state
  is `enabled && linkUrl != null`; removing `onPressed` switches to default
  navigation, while removing `linkUrl` makes the Link unavailable.
- Default navigation is delegated to `url_launcher.Link`. A supplied
  `onPressed` replaces its `FollowLink` callback, so one activation cannot run
  both custom routing and browser navigation.
- An unavailable Link has no Link flag, URL, tap action, focus path, or web
  `href`. Flutter's web delegate retains Link semantics for a null URI, so the
  unavailable path omits that wrapper. A keyed inner detector preserves the
  consumer's stateful subtree as the wrapper enters or leaves the tree. The
  content remains discoverable as ordinary unavailable text because HTML has no
  disabled-anchor contract.
- Interaction state is synchronized during `didUpdateWidget` without invoking
  consumer callbacks during build; ended hover, press, and focus callbacks are
  delivered after the frame. Re-enabling beneath a stationary pointer restores
  hover after layout.
- Added regressions cover native DOM ownership, dynamic parent `setState`,
  stationary hover, held Enter/Numpad Enter, directional disabled focus,
  selectable text, and rich text. Real Context Menu/Hover Card composition
  remains deferred to Phases 5 and 7 as originally required.

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
  Real-browser review showed that combining an application callback with this
  live web `href` does not coordinate navigation ownership. Flutter's official
  [`url_launcher.Link`](https://pub.dev/documentation/url_launcher/latest/link/Link-class.html)
  provides that missing native/web coordination while a destination exists.
  Its web delegate still contributes Link semantics for a null URI, so Naked UI
  bypasses the wrapper while unavailable.
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
| State | enabled is `enabled && linkUrl != null`; focus/focusable follows effective focus | widget + semantics transitions | macOS/Android/web |
| Value/URL | non-null `linkUrl` is the destination; default navigation uses official Link; unavailable state removes URL/href | state, semantics, and pinned-Chrome DOM tests | Chrome tree/href inspection |
| Actions | semantic tap only while effectively enabled | semantics action/callback tests | VoiceOver/TalkBack |
| Hint | optional caller-localized `semanticHint`, once | semantics test | all AT sessions |
| Children | visible label preserved unless an explicit label overrides it; decorative icon excluded by consumer | semantics/example tests | Chrome tree |
| Exclusion | `excludeSemantics` removes the Link semantics subtree and focus semantics | semantics test | N/A |
| Ownership | external focus nodes are borrowed and never disposed | lifecycle tests | aggregate teardown |

### Input, state, and lifecycle matrix

| Path | Enabled result | Disabled/null-destination result | Required assertion |
|---|---|---|---|
| Primary tap | custom callback once, or default navigation once, plus optional feedback | no recognizer/callback/feedback | callback, DOM location, and state transitions |
| Canceled primary sequence | press true → false; no callback | no state transition | pointer cancel test |
| Secondary click | unclaimed; no callback | unclaimed | gesture test and later Context Menu composition |
| Enter/Numpad Enter | one activation per physical key sequence | no activation | known focus node + key-down/repeat/up sequence |
| Space | no Link callback and no Link press state | no callback | widget test; web scroll outcome |
| Semantic tap | same activation path once | action absent | semantics action test |
| Hover | state/callback true then false | no hover callback | mouse gesture test |
| Focus/Tab | state/callback and normal traversal | skipped in traditional traversal | focus and next-target assertions |
| Callback removal | remains enabled and switches to default navigation | already default | rebuild test |
| Destination removal | immediately unavailable; transient press/hover/focus clear after safe notification | already unavailable | parent-`setState` lifecycle tests |
| Stationary re-enable | hover restores after layout when the pointer remains inside | N/A | detector and Link hover regression |
| Focus-node replacement | listener moves; focused state handed off; neither external node disposed | same ownership | lifecycle test |
| Disposal | internal detector node/listeners removed; external node remains usable | same | teardown/no exception |

## Requirement-to-test map

| ID | Requirement | Cheapest automated owner | Required real proof |
|---|---|---|---|
| LINK-API-01 | Child/builder invariant; immutable state/scope includes URL and all widget states | `naked_link_test.dart` + hash contract | N/A |
| LINK-ACT-01 | Primary tap once; cancellation and secondary click do not activate | widget gesture tests | macOS/web hover+pointer; Android touch |
| LINK-KEY-01 | Enter and Numpad Enter activate; Space is unclaimed | widget shortcut tests | macOS and pinned web scroll/result |
| LINK-STATE-01 | Destination-owned effective enabled state controls activation, traversal, feedback, cursor, and disabled state | widget transitions + platform-channel feedback test | all behavior targets |
| LINK-STATE-02 | Hover/focus/press callbacks and builder/scope snapshots are exact | widget state tests | macOS/web fixture readout |
| LINK-LIFE-01 | Focus ownership/replacement/disposal, safe destination removal, and stationary hover restoration do not leak | lifecycle + detector tests | aggregate teardown on macOS/web |
| LINK-NAV-01 | Official default navigation, custom override, and unavailable DOM paths have one owner | widget + pinned-Chrome DOM click tests | pinned Chrome location/href |
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
  and destination removal; parent-`setState` lifecycle safety; stationary
  hover restoration; held-key repeats; directional disabled focus; selectable
  and rich text; external focus ownership, replacement, and disposal.
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
  `enabled && linkUrl != null`. Delegate default navigation and native web
  anchors to `url_launcher.Link`; when `onPressed` is present, route activation
  only to that override. Compose the existing state mixin, state scope,
  focusable detector, primary-only gesture path, and one effective Link
  semantics node. Map only Enter/Numpad Enter without repeat events; do not bind
  Space. When the destination becomes unavailable, synchronize transient state
  without rebuilding or invoking consumers during `didUpdateWidget`, then
  deliver ended-state callbacks after the frame. Borrow external focus nodes
  and never dispose them. Remove URL, Link flag, focus, and actions while
  unavailable; preserve the advanced semantics-exclusion escape hatch.
- **Avoid:** direct `launchUrl` calls, hand-rolled DOM anchors or event
  coordination, router dependencies, visited state, modifier-click synthesis,
  long-press ownership, raw key handlers, timers, styles, English defaults,
  changes to Button, or a speculative generic pressable base class.
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
  200% long-text assertions, destination removal while focused, secondary click
  remaining unclaimed, and pinned-Chrome DOM cases for destination-only native
  navigation, custom override, and unavailable href removal.
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
- **How:** document Link-versus-Button use, destination/default/override
  ownership, effective enabled state, Enter/Numpad/Space behavior, state and
  focus ownership, semantics override/icon rules, secondary/modifier-click
  boundaries, styling and router non-goals, and Remix responsibilities. Build
  the §22 ten-item packet with the stable requirement table, platform
  commands/runs, screenshot review, manual AT rows, limitations, and exact
  SHAs.
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

## Reviewer-correction local evidence — 2026-07-13

The correction candidate was verified from parent `2614555` before publication.
The implementation commit is recorded in the follow-up evidence commit. No push,
PR update, merge, or hosted exact-head run is claimed here.

### Available local publication gates

- Flutter 3.41.2 format and analyze pass with no findings.
- Package suite: 609 pass; three documented external-integration skips.
- Example suite: 24 pass; two host-specific golden comparison skips on macOS.
- Focused Link, semantics, detector, and hash proof: 66 pass.
- Aggregate: 99 pass and one documented Tooltip skip on both `flutter-tester`
  and the real macOS runner.
- Matched Chrome/ChromeDriver 150.0.7871.115 aggregate passes. Exact disabled
  semantics and DOM assertions prove no Link role, URL, action, anchor, or
  `href` remains.
- A separate W3C WebDriver proof performs a trusted primary click, proves the
  custom override runs exactly once without navigation, and proves dynamic
  disable removes the native anchor and cannot activate. The aggregate's
  in-app coordinator separately proves the default destination outcome.
- Flutter 3.41.0 exact-minimum dependency resolution, analyze, and the full
  609-test package suite pass with the same three documented skips.

### Correction-specific pending gates

- The correction has not been pushed, so prior hosted checks do not validate
  this candidate. Exact-head Ubuntu, macOS, pinned-web, and API 34 Android jobs
  must be rerun after publication.
- No Android emulator or device is attached locally; API 34 remains a hosted
  gate.
- Required web screenshots, human assistive-technology sessions, and real
  Phase 5/7 composition remain closure blockers below.

## Original PR execution evidence — 2026-07-13 (superseded)

Review-ready PR: [#65](https://github.com/btwld/naked_ui/pull/65). The fully
tested implementation/evidence head is
`24460f0a94b657854c95d5dc900e5ef7215d9604`; its GitHub test merge ref is
`09e62c8dc29b424a1d00e5e7de8cfc4a99cd124f`. The PR remains unmerged.
These checks establish the original implementation's evidence but do not
validate the unpublished D-16 reviewer correction above.

### Test-first and failure-triage record

- The first API tests failed to compile because `NakedLink` and
  `NakedLinkState` did not exist. The first semantics tests failed because no
  Link node, URL, or Link action existed.
- Targeted restored mutations proved the tests reject Space activation
  (callback count 3 instead of 2), secondary activation (1 instead of 0), and
  Button semantics (Button true instead of false). A contrast mutation failed
  at ratio 1.00 before the approved link color was restored.
- Fixture review produced intentional red proofs before each correction:
  inline height was 48px instead of less than 48px; a standalone target filled
  680px; the standalone guideline fixture was absent; ambient font family was
  null; and a synthetic safe-inset surface was 800×600 instead of 800×560.
- The first hosted golden candidate was rejected at 800×397. The second fixed
  the surface but exposed fallback-glyph blocks and a missing Material icon.
  The third candidate fixed both by preserving the ambient font and loading
  Material Icons from the pinned Flutter SDK. Only that reviewed 800×600 PNG
  was checked in unchanged.
- The first API 34 screenshot was rejected because content overlapped the top
  system inset. The synthetic-inset regression failed for the same reason;
  `SafeArea` fixed the root condition, and the replacement hosted image was
  reviewed.

### Local verification on Flutter 3.41.2

- Format, analyze, and dartdoc dry run: pass with no findings.
- Package suite: 597 pass; three documented external-integration skips.
- Example suite after the reviewed golden: 24 pass; two host-specific pixel
  comparison skips on macOS.
- Focused Link package/semantics/hash proof: 39 pass.
- Focused Link integration: 8/8 on `flutter-tester` and real macOS.
- Aggregate: 96 pass and one documented Tooltip skip on both
  `flutter-tester` and real macOS.
- Screenshot smoke: six behavior scenarios pass; the exact-head real-macOS
  driver captures the four Link states plus the inherited Dialog state and
  records a complete manifest.

### Hosted verification

All seven checks passed for head `24460f0` / merge ref `09e62c8`:

- [Flutter CI run 29229092269](https://github.com/btwld/naked_ui/actions/runs/29229092269):
  primary Ubuntu 24.04 tests, format/analyze/DCM, reviewed golden comparison,
  guidelines, and exact-minimum Flutter 3.41.0 all pass.
- [Integration run 29229092358](https://github.com/btwld/naked_ui/actions/runs/29229092358):
  aggregate `flutter-tester` and real macOS behavior pass; macOS screenshot
  capture, exact file assertions, and artifact transport pass.
- [Web run 29229092255](https://github.com/btwld/naked_ui/actions/runs/29229092255):
  matched Chrome/ChromeDriver 150.0.7871.115 behavior passes, including the
  observable Space-scroll postcondition; the behavior log is retained as an
  artifact but is not substituted for missing screenshots.
- [Android run 29229092250](https://github.com/btwld/naked_ui/actions/runs/29229092250):
  API 34 Pixel 6 behavior and screenshot transport pass.
- [PR-title run 29229091554](https://github.com/btwld/naked_ui/actions/runs/29229091554):
  pass.

### Reviewed visual evidence

- Ubuntu golden `naked_link__keyboard_focus.png`: 800×600, DPR 1, pinned
  Roboto/Material Icons, en-US/LTR, SHA-256
  `88f39adcc2a5916f370d2ed5fdd8ff897e9c6cc4f00a5e3a9d71152ccf22086e`.
  The same hosted job subsequently compared the checked-in file unchanged.
- macOS default inline:
  `02f2565b397780d8ea50d2a8c98c754fcab85464d13abe76c8b962097fd3a6a7`.
- macOS keyboard focus:
  `18683fbc41e260fa54622db65893c164bd4bdb29b06cbdea32754a098c9d9095`.
- macOS 200% long text:
  `4bf12ea4007dadc972a74bb71fa9a376f85dc823aca53658d381a70a68085cda`.
  All three are 800×600/DPR 1, and hosted bytes match the reviewed local files.
- Android disabled:
  `db651e38a3e4b5f53e4ae07cd059e02a235b29563ea222806ce96795b5636b75`;
  1080×2274 physical pixels, DPR 2.625, safe content surface approximately
  411.43×817.52 logical pixels. The manifest records merge ref `09e62c8`.

### Required closure blockers

- `link__hover__web__reference.png`,
  `link__external_hint__web__reference.png`, and
  `link__rtl__web__reference.png` remain unsupported on Flutter 3.41.2.
- VoiceOver, TalkBack, Chrome accessibility-tree, and release-level iOS
  VoiceOver sessions require human operators and are not available here.
- LINK-COMP-01 requires real Phase 5 Context Menu and Phase 7 Hover Card
  implementations around Link; placeholders do not satisfy the contract.
- Maintainer merge authorization and post-merge `main` verification have not
  been provided. These blockers prevent closure but do not invalidate the
  review-ready PR.

## Acceptance and stop conditions

- [x] Every A1/A2 test was observed failing for the intended missing behavior
      before implementation and the red evidence is recorded.
- [x] Link public API, state equality/scope, and effective-enabled behavior
      match the binding contract without router, styling, or visited state.
- [x] Primary/canceled/secondary pointer, Enter/Numpad/Space, semantic tap,
      feedback, cursor, callbacks, and dynamic removal pass focused tests.
- [x] Link/URL/name/hint/enabled/focus/action semantics are exact; Button and
      duplicate naming are absent; disabled/excluded behavior passes.
- [x] Focus-node ownership/replacement/disposal and aggregate teardown pass.
- [x] Canonical fixture, stable result/reset/readout, Arabic RTL, 200% text,
      external-icon exclusion, golden, and accessibility guidelines pass.
- [ ] Correction integration, inventory, fast aggregate, and real macOS
      aggregate pass locally; exact-head hosted API 34 and pinned-web reruns
      remain pending publication.
- [x] All seven screenshot names have reviewed evidence, or Phase 2 is
      explicitly blocked; unsupported web screenshots are not marked passed.
- [ ] VoiceOver, TalkBack, Chrome accessibility-tree, and release-level iOS
      records are attached; missing human evidence blocks closure.
- [ ] Real Context Menu and Hover Card composition proof is attached after
      those components exist; placeholder wrappers do not satisfy it.
- [ ] Full local publication commands and Flutter 3.41.0 pass; hosted
      correction-head verification remains pending publication.
- [x] Docs, changelog, compatibility statement, traceability, manifests,
      visual review, and ten-item handoff packet are ready.
- [ ] Entire correction diff is locally reviewed and committed; PR #65 still
      needs the correction push and exact-head checks. It remains unmerged
      without explicit maintainer authorization.

Block Phase 2 closure (not independent program work) if Link maps as a Button,
Space activates or is swallowed on web, disabled paths retain activation or
focus, linkUrl lacks the required Link flag/href mapping, accessible naming is
duplicated, focus ownership leaks, any required target is retry-dependent, the
real composition scenario is unavailable, required web screenshots remain
unsupported, or manual AT evidence is unavailable.
