# Phase 1 — Alert Dialog

Status: **Active — implementation complete; publication and hosted evidence in progress**.

Goal: extend the existing dialog primitive without changing current callers by
adding a constrained alert-dialog semantics role and a convenience helper with
safe, nondismissible defaults. The helper must put focus on the caller's safe
target (or the first traversable descendant), trap focus, restore it safely,
keep title/message/actions as separate semantics nodes, and leave all styling
and localized copy to the consumer.

Contract: briefing [§13](../briefing.md#13-component-contract-alert-dialog)
(binding), plus the cross-component rules in §§5 and 8–12. Decision
[D-02](../decisions.md#phase-1-decision-evidence-2026-07-12) is resolved to an
optional caller-owned `initialFocusNode` and documented safe-target heuristics.
Baseline commit: d341b90e7b09e13f83da299b4ed17ae0eaa9ddee (all current-code
findings below re-verified on 2026-07-12).

## Research and readiness

- No repository or ancestor AGENTS.md exists; repository instructions are
  therefore the plan documents named above.
- The phase worktree is .context/worktrees/phase-01-alert-dialog on branch
  `feat/naked-alert-dialog`, created from the approved baseline SHA.
- `packages/naked_ui/lib/src/naked_dialog.dart:30-87` already owns route,
  barrier, Escape, transition, navigator, request-focus, and closed-loop
  traversal behavior. `NakedDialog` at lines 96-139 hard-codes
  `SemanticsRole.dialog`.
- The current widget, semantics, and Material-parity tests pass on pinned FVM
  Flutter 3.41.2, but several assert only visibility. In particular,
  `naked_dialog_test.dart:239-304` checks only that outside focus is absent,
  while `naked_dialog_semantics_test.dart:85-279` does not fully assert the
  dialog node's name/role/actions or blocked background transitions.
- A disposable Flutter 3.41.2 probe proved that a newly opened
  `RawDialogRoute` initially gives primary focus to its modal route focus
  focus scope, not either focusable action. The alert helper must explicitly
  choose the first traversable descendant when no usable supplied node exists;
  route focus alone is insufficient. Flutter's pinned
  `FocusTraversalPolicy.findFirstFocus` is the platform-supported selection
  mechanism. The probe was removed and the worktree returned to clean state.
- Flutter's own Material `AlertDialog` and Cupertino alert dialog use
  `SemanticsRole.alertDialog` in the pinned 3.41.2 framework source. No role
  prototype decision remains for Alert Dialog.
- `packages/example/lib/api/naked_dialog.0.dart:48-173` contains two styled
  general-dialog examples but no alert helper, stable fixture keys, result
  readout, alert role wrapper, or explicit safe focus target.
- `packages/example/integration_test/components/naked_dialog_integration.dart`
  is already registered by `all_tests.dart`, but its current focus test at
  lines 91-108 does not assert primary focus. Phase 1 extends this file rather
  than adding an unregistered parallel test.
- Phase 0 provides the inventory guard, real-macOS/Android/web workflows,
  screenshot manifest helper, pinned golden harness, and accessibility
  guideline helper. Web screenshots are explicitly unsupported on Flutter
  3.41.2; pinned web behavior remains required but cannot satisfy the binding
  RTL web screenshot until a stable capture path or explicit maintainer
  decision exists.
- Toolchain: `.fvmrc` pins Flutter 3.41.2 and CI separately proves 3.41.0.
  The shell-global Flutter is 3.38.6, so local commands run through FVM
  unless PATH is explicitly pointed at the pinned SDK. macOS is available;
  `adb devices` lists no Android target; local Chrome is 150.0.7871.115 and no
  local ChromeDriver is installed, so Android and matched web evidence are
  authoritative hosted jobs.

## Contract review

### Compatibility and ownership

- Additive/source-compatible: existing `showNakedDialog` defaults and
  `NakedDialog` constructor calls retain normal-dialog semantics and
  dismissible behavior.
- `NakedDialog.semanticsRole` accepts only `SemanticsRole.dialog` or
  `SemanticsRole.alertDialog`; no arbitrary-role escape hatch.
- `showNakedAlertDialog` requires a caller-localized `semanticLabel`, defaults
  to a nondismissible barrier, and wraps the builder's visual contents in
  exactly one `NakedDialog`. It adds no styles or English copy.
- `initialFocusNode` remains caller-owned. Naked UI may request it but never
  disposes or reparents it outside the route's normal focus tree.
- The helper owns no persistent controller or timer. Its finite transition is
  injectable; tests use zero or exact-duration pumps rather than timing
  padding.

### Semantics matrix

| Dimension | Alert Dialog contract and proof |
|---|---|
| Primitive | Modal urgent/destructive confirmation region. |
| Name | Required caller-localized `semanticLabel`; title/message remain separate child nodes. |
| Role/flags | One `SemanticsRole.alertDialog` node with container, explicit children, `scopesRoute`, and `namesRoute`; no fake tap action. |
| State/value | Modal route state is observable through route flags and blocked background; no synthetic value. |
| Actions | Dialog container exposes no activation action; child actions own tap/keyboard/semantic activation. Default barrier and Escape expose no dismissal path. |
| Focus | Supplied attached/focusable safe node wins; otherwise first traversable descendant; closed-loop Tab/Shift+Tab; restoration to a surviving invoker. |
| Traversal | Message and actions remain separately discoverable; background is unreachable while modal. |
| Grouping/relations | `BlockSemantics` around one explicit-child route container; exclusion hides the complete dialog subtree. |
| Disabled behavior | The dialog region has no enabled state. Disabled child actions remain consumer controls and cannot become a dismissal path. An unavailable initial node triggers the traversal fallback. |
| Localization | `semanticLabel` is required by the alert helper; `barrierLabel` remains caller supplied. Tests include a non-English name and RTL fixture. |
| Flutter mapping | `Semantics.role`, `container`, `explicitChildNodes`, `scopesRoute`, `namesRoute`, `label`, `BlockSemantics`, `ExcludeSemantics`. |
| Automated proof | Exact node data/action set, separate child nodes, blocked/restored background, pointer/key/semantic outcomes, focus entry/loop/restoration/removal, and no role-sensitive exception. |
| Manual proof | VoiceOver and TalkBack announce an alert dialog once, expose title/message/actions, keep background unreachable, start at a sensible target, and restore focus. Chrome accessibility tree and keyboard are recorded separately. |

### Input, focus, lifecycle, and platform paths

- Open: programmatic helper call reached by pointer, Enter, or Space on the
  canonical invoker.
- Act/close: pointer, Enter, and direct semantics tap on Cancel/Confirm;
  explicit `Navigator.pop(result)`; deliberate optional barrier/Escape
  dismissal when enabled.
- Refused paths: outside pointer and Escape on the default helper leave the
  dialog open and do not emit a result/callback.
- Focus: supplied Cancel node, missing/unattached/unfocusable-node fallback,
  forward and reverse loop, each supported close path, removed invoker, and a
  focusable non-button message container for long structured content.
- Lifecycle: rebuild while open, caller node still usable after route removal,
  removal of the invoker while open, and no exception or stale focus callback
  after close.
- Platforms: common behavior on `flutter-tester`; focus, keyboard, and
  VoiceOver on real macOS; touch, restoration, and TalkBack on API 34 Android;
  keyboard plus actual accessibility tree on pinned Chrome. Screenshot capture
  is a separate result on each supported target.

## Tasks

### A1. Write failing API, dismissal, focus, and lifecycle tests

- **Where:** extend
  `packages/naked_ui/test/src/naked_dialog_test.dart:7-305` and
  `packages/naked_ui/test/src/parity/naked_dialog_material_parity_test.dart`.
- **How:** add named tests for the constrained role assertion; alert helper
  nondismissible defaults; rejected outside/Escape paths; action result and
  exactly-once callback; opt-in dismissal; supplied-node focus after one
  application frame; first-traversable fallback; Tab and Shift+Tab loop with
  known enabled nodes; focus restoration for action and opt-in dismissal;
  safe removed-invoker close; and proof that the external node remains usable
  after close. Add alert-role parity with Flutter Material where useful.
- **Red gate:** run the focused files before implementation and record the
  first assertion showing the missing constructor/helper/focus behavior. A
  compile failure is acceptable only for the first missing public API test;
  after a minimal test-only shim, behavioral tests must fail on their intended
  postcondition.
- **Verify:** `fvm flutter test packages/naked_ui/test/src/naked_dialog_test.dart packages/naked_ui/test/src/parity/naked_dialog_material_parity_test.dart`.

### A2. Write failing exact semantics tests

- **Where:** extend
  `packages/naked_ui/test/semantics/naked_dialog_semantics_test.dart:85-279`
  and consolidate the directly related exclusion case currently at
  `packages/naked_ui/test/exclude_semantics_test.dart:221-254` only if doing so
  removes duplicate setup without weakening global exclusion coverage.
- **How:** assert the default dialog role remains unchanged; alert role and
  route flags; exact Spanish accessible name; no container tap action; title,
  message, Cancel, and destructive action as useful separate nodes; background
  absent while open and restored after close; semantic action produces one
  result; long-message focus node is not a button; exclusion removes the alert
  node/subtree; invalid roles assert; and `tester.takeException()` is null
  after valid role-sensitive builds. Every semantics handle uses teardown-safe
  disposal.
- **Red gate:** each new role/background/action test must fail for the intended
  missing behavior against the baseline, not because a finder addresses the
  wrong merged node.
- **Verify:** `fvm flutter test packages/naked_ui/test/semantics/naked_dialog_semantics_test.dart packages/naked_ui/test/exclude_semantics_test.dart`.

- **Checkpoint A:** preserve the focused red logs, confirm baseline existing
  dialog tests are still green, and do not implement until every binding §13.6
  requirement has an owning test or an explicit integration-only mapping.

### B1. Implement the smallest alert-dialog API and focus coordinator

- **Where:** `packages/naked_ui/lib/src/naked_dialog.dart:30-139`; the existing
  `naked_widgets.dart` export already exposes this library and needs no new
  export.
- **How:** add the constrained `semanticsRole` property/assertion to
  `NakedDialog`; add `showNakedAlertDialog<T>` with the binding signature,
  required localized label, nondismissible default, and one automatic alert
  wrapper. Add one private stateful focus coordinator that schedules a single
  post-frame request: choose the supplied node only when attached and
  `canRequestFocus`, otherwise ask Flutter's active focus traversal policy for the
  first traversable descendant and request it. Handle node replacement/removal
  without disposing caller resources or firing stale post-frame work.
- **Guardrails:** keep `showNakedDialog` behavior untouched, retain closed-loop
  route traversal, do not add style/copy/business rules, and do not add a
  speculative public controller or focus abstraction.
- **Verify:** focused A1/A2 tests, then
  `fvm flutter analyze packages/naked_ui` and
  `fvm dart format --set-exit-if-changed packages/naked_ui/lib/src/naked_dialog.dart packages/naked_ui/test/src/naked_dialog_test.dart packages/naked_ui/test/semantics/naked_dialog_semantics_test.dart packages/naked_ui/test/src/parity/naked_dialog_material_parity_test.dart`.

### C1. Add the deterministic canonical alert fixture and styled proof

- **Where:** extend `packages/example/lib/api/naked_dialog.0.dart`; add dialog
  cases to `packages/example/test/accessibility_guidelines_test.dart`; add
  a new golden test at
  packages/example/test/goldens/components/naked_alert_dialog_golden_test.dart
  and its reviewed Linux baseline under `.../baselines/`.
- **How:** keep the existing normal-dialog examples and add one reusable alert
  fixture with local data, a visible result/callback count, resettable state,
  a caller-owned Cancel focus node, least-destructive initial focus, long
  message/non-action focus variant, RTL variant, 200% text variant, fixed
  viewport, and disabled/fixed animation based on fixture configuration. Pass
  styles only in the example. Exercise all meaningful accessibility guidelines
  on the styled open state.
- **Stable keys:** `alert-dialog.open`, `alert-dialog.title`,
  `alert-dialog.message`, `alert-dialog.cancel`, `alert-dialog.confirm`, and
  `alert-dialog.result`; add `alert-dialog.remove-invoker` and
  `alert-dialog.reset` for deterministic removal/order-independent scenarios.
- **Golden:** prove open safe focus at 800×600, DPR 1, pinned Roboto, fixed
  locale/direction/text scale/animation. Update only through the approved
  update-then-verify flow and inspect the PNG.
- **Verify:** `fvm flutter test packages/example/test/accessibility_guidelines_test.dart`
  plus the focused golden and complete golden commands in the verification
  section after the new test exists.

### D1. Replace weak dialog integration assertions with contract outcomes

- **Where:** extend
  `packages/example/integration_test/components/naked_dialog_integration.dart`
  (already imported as `Dialog Tests` by
  `packages/example/integration_test/all_tests.dart:9` and
  `packages/example/integration_test/all_tests.dart:35`) and rerun
  `packages/example/test/integration_inventory_test.dart`.
- **How:** drive only stable keys and deterministic local state. Add the five
  §13.7 scenarios: keyboard open → exact Cancel focus → forward/reverse loop →
  cancel → invoker restoration; pointer open with rejected barrier/Escape;
  destructive action with exactly one callback/result; removed invoker plus
  programmatic close/no exception; 200% long-message scroll/focus access.
  Add RTL layout/keyboard coverage and a direct semantics-action result where
  the widget layer cannot prove the real target. Replace visibility-only focus
  checks and `UniqueKey` usage. Use zero/fixed transition pumps and bounded
  observable `pumpUntil`; cleanup focus, viewport, semantics, route, and
  caller-owned nodes in teardown-safe paths. `pumpAndSettle()` is not needed
  for these finite, contractually configured fixtures.
- **Why real targets:** route focus/restoration and keyboard differ on desktop
  and web; barrier/touch and TalkBack-oriented paths need Android; platform AT
  mappings cannot be inferred from widget semantics.
- **Verify:**
  `cd packages/example && fvm flutter test -r compact -d flutter-tester integration_test/components/naked_dialog_integration.dart`,
  then the aggregate and inventory commands in the verification section.

### D2. Capture the required visual states without weakening behavior gates

- **Where:** extend `packages/example/integration_test/screenshot_smoke.dart`,
  `packages/example/test/screenshot_evidence_test.dart`, and the exact
  artifact assertions in `.github/workflows/integration-tests.yml` and
  `tool/run_android_integration.sh`.
- **How:** capture only after scenario assertions. Produce
  `alert_dialog__open_safe_focus__macos__reference.png`,
  `alert_dialog__destructive_action__android__reference.png`, and
  `alert_dialog__long_message_200_text__macos__reference.png` with full
  manifests. Record the required
  `alert_dialog__rtl__web__reference.png` as blocked by the already-proven
  Flutter 3.41.2 web capture limitation; do not manufacture a widget golden or
  behavior log as a substitute. The phase cannot close until a stable pinned
  capture exists or the maintainer explicitly approves alternate evidence.
- **Verify:** dedicated local macOS screenshot driver, hosted API 34 artifact
  job, manifest unit test, file-size checks, and human review of every produced
  PNG. Behavior aggregate and screenshot transport remain independent blocking
  results.

- **Checkpoint D:** focused integration passes on `flutter-tester` and real
  macOS; aggregate inventory passes; produced screenshot manifests match exact
  tested SHA/toolchain/viewport/DPR/locale/direction/text scale. If focus is
  lost, a target cannot execute a path, a test flakes, or web evidence is
  misleading, stop Phase 1 and continue only an independent ready phase.

### E1. Complete documentation, traceability, review, and PR handoff

- **Where:** API dartdoc in `naked_dialog.dart`; dialog bullet/usage in
  `packages/naked_ui/README.md`; entry in `packages/naked_ui/CHANGELOG.md`;
  Phase 1 status/evidence in this file and `plan/README.md`.
- **How:** document normal-vs-alert usage, single-wrapper rule, required
  localized label, safe initial-target heuristics, focus-node ownership,
  nondismissible defaults, opt-in dismissal responsibility, semantic/focus
  compatibility, and Remix's remaining styling/product-copy checks. Build the
  ten-item §22 handoff packet and stable AD requirement-to-test table in the PR
  description; record exact head/merge-ref SHAs separately.
- **Review:** inspect the entire diff for source compatibility, semantics or
  focus drift, duplicated wrappers/helpers, resource ownership, test strength,
  hard-coded package copy, speculative abstractions, and unrelated changes.
- **Delivery:** stage only Phase 1 files, commit intentionally, push
  `feat/naked-alert-dialog`, and open one ready-for-review PR targeting `main`.
  Monitor every required check on the exact PR-head SHA. Do not merge without
  explicit maintainer authorization.

## Requirement-to-test map

| ID | Requirement | Cheapest automated owner | Required real proof |
|---|---|---|---|
| AD-API-01 | Existing dialog source/default semantics compatibility | widget + semantics + parity tests | exact-minimum CI |
| AD-API-02 | Role constrained to dialog/alertDialog | constructor + semantics tests | N/A |
| AD-DISMISS-01 | Alert defaults reject barrier and Escape | widget test | macOS pointer/key + Android touch + web key |
| AD-DISMISS-02 | Explicit action/result and opt-in dismissal fire once | widget test | integration result readout |
| AD-FOCUS-01 | Safe supplied node or first traversable fallback | widget test | macOS + Android + web |
| AD-FOCUS-02 | Forward/reverse closed loop and restoration | widget test | macOS + Android; web keyboard |
| AD-FOCUS-03 | Removed invoker/unusable node does not throw | widget lifecycle test | macOS integration |
| AD-SEM-01 | One named alert role with route flags/no fake action | exact semantics test | VoiceOver + TalkBack + Chrome tree |
| AD-SEM-02 | Background blocked/restored; children separate | transition semantics test | VoiceOver + TalkBack |
| AD-SEM-03 | Long message may receive non-button initial focus | semantics + focus test | macOS 200% text + VoiceOver |
| AD-VIS-01 | Safe focus, destructive result, long text, RTL layouts | pinned golden + screenshot scenarios | reviewed macOS/Android/web artifacts |
| AD-LIFE-01 | Caller-owned focus node survives close/disposal | widget lifecycle test | aggregate teardown/no exception |

## Integration proof plan

### Scenario-to-platform matrix

| Scenario | flutter-tester | real macOS | API 34 Android | pinned Chrome/web |
|---|---:|---:|---:|---:|
| Keyboard open, safe focus, loop, cancel, restore | Yes | Required | Required focus/restoration | Required |
| Pointer open, barrier rejected, Escape rejected | Yes | Required | Required touch | Escape required |
| Destructive action once + result | Yes | Required | Required + screenshot | Required |
| Invoker removed, programmatic close | Yes | Required | Required | Required |
| Long message, 200% text, non-action focus | Yes | Required + screenshot | Required | Required |
| RTL fixture | Yes | Required behavior | Required behavior | Required behavior; screenshot blocked pending supported capture/decision |

### Pumps, cleanup, artifacts, and manual evidence

- Pump once for focus application and use exact configured transition frames;
  use shared bounded `pumpUntil` only for an observable route/focus/result
  condition with a diagnostic naming current primary focus and visible state.
- Teardown owns semantics handles, test-created focus nodes, routes, view/DPR,
  text scale, direction, and fixture reset. Cleanup errors propagate.
- macOS screenshots: open safe focus and 200% long message. Android screenshot:
  destructive action result. Required web screenshot: RTL, presently blocked.
- Golden: canonical open safe-focus state under the Phase 0 pinned harness.
- Guidelines: label, Android/iOS target, and contrast on the styled open fixture.
- Manual sessions: macOS 26.5.2 VoiceOver on the exact PR head; TalkBack on the
  hosted/local API 34 target only when a human can operate and record it;
  Chrome 150 accessibility tree plus keyboard on the pinned browser; release
  iOS VoiceOver remains a distinct pre-release record. Automated semantics do
  not fill these rows.

## Execution record

The test-first sequence was observed locally on pinned Flutter 3.41.2 before
the corresponding production or fixture changes. Focused red runs proved the
missing alert role and helper API, missing initial-focus contract, route-scope
focus instead of the safe descendant, incorrect focus when `requestFocus` was
false, and unsafe acceptance of a supplied background node. Targeted mutation
runs also caught opt-in barrier dismissal, escaped traversal, non-modal route
semantics, undersized actions, and the missing canonical fixture.

The resulting focused widget, semantics, fixture, guideline, screenshot-smoke,
and six-scenario integration suites pass on `flutter-tester`. The fresh local
publication gate passed 586 package tests with three intentional integration
launcher skips, 17 example tests with two host-specific golden skips, and the
90-test integration aggregate with its existing tooltip skip. The integration
inventory also passed. The same six Alert Dialog scenarios and the 90-test
aggregate pass on the real local macOS target. The macOS runner printed
`Failed to foreground app; open returned 1` while still connecting, executing,
and passing both suites; hosted macOS remains the independent proof. Local
Android is unavailable because no device is attached and the installed SDK is
incomplete, so the hosted API 34 job is authoritative.

The full diff review found one scoped fixture regression: alert-specific target
size, focus styling, and animation changes had leaked into the legacy general
dialog example through a shared private button. The alert action was isolated,
legacy layout/timings were restored, and the affected fixture, guideline,
screenshot-smoke, `flutter-tester`, and real-macOS aggregates were rerun green.
No other major review findings remain.

The canonical Linux golden test compiles and skips off Linux, but its checked-in
baseline must be reviewed from the Ubuntu CI failure artifact before it can be
accepted. Local macOS screenshot capture produced the open-safe-focus and 200%
long-message states and both were visually inspected; final artifacts must be
recaptured against the committed PR SHA. The required RTL web screenshot
remains blocked by the Phase 0 Flutter 3.41.2 capture limitation. VoiceOver,
TalkBack, Chrome accessibility-tree, and release-iOS evidence remain human
review gates and are not inferred from automated semantics tests.

The first exact-head Ubuntu run confirmed that all 18 other example tests pass
and the only failure is the intentionally absent alert reference image. Flutter
does not emit a diagnostic file for a non-existent golden, so the existing
failure-only artifact was empty. The CI diagnostic path now generates candidate
images with `--update-goldens` on that same pinned Ubuntu host after the original
blocking test has failed; the candidate still requires explicit visual review
and a subsequent exact-head green run.

## Verification and publication gates

Focused development:

```sh
fvm flutter test packages/naked_ui/test/src/naked_dialog_test.dart
fvm flutter test packages/naked_ui/test/semantics/naked_dialog_semantics_test.dart
fvm flutter test packages/naked_ui/test/src/parity/naked_dialog_material_parity_test.dart
fvm flutter test packages/example/test/accessibility_guidelines_test.dart
fvm flutter test packages/example/test/goldens/components/naked_alert_dialog_golden_test.dart
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/components/naked_dialog_integration.dart
```

Required local publication gate from the repository root (with PATH set to the
pinned Flutter 3.41.2 SDK, or the equivalent FVM prefix):

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test packages/naked_ui/test
flutter test packages/example/test
cd packages/example
flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```

Additional exact proof:

```sh
flutter test packages/example/test/integration_inventory_test.dart
cd packages/example
flutter test -r compact -d macos integration_test/components/naked_dialog_integration.dart
flutter test -r compact -d macos integration_test/all_tests.dart
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshot_smoke.dart -d macos --dart-define=NAKED_UI_CAPTURE_SCREENSHOTS=true --dart-define=NAKED_UI_GIT_SHA=<full-sha> --dart-define=NAKED_UI_FLUTTER_VERSION=3.41.2
```

Hosted gates: primary and exact-minimum suites; canonical golden/guidelines;
`flutter-tester`; real macOS; API 34 Android behavior plus screenshot transport;
pinned Chrome/ChromeDriver behavior log; PR-title policy. Every result must be
green on the exact PR head (or identified merge-ref where GitHub tests one).

## Acceptance and stop conditions

- [x] Every A1/A2 test was observed failing for its intended missing behavior
      before implementation and the red evidence is recorded.
- [x] Existing dialog API remains source-compatible and normal dialog role and
      dismissal defaults do not change.
- [x] Alert role, single wrapper, safe dismissal defaults, action results,
      safe focus entry/fallback, closed loop, restoration, dynamic removal,
      exclusion, and external-node ownership pass focused tests.
- [ ] Canonical fixture, result/reset, non-English semantics, RTL, 200% text,
      golden, and accessibility guidelines pass.
- [ ] Integration component, inventory, fast aggregate, real macOS aggregate,
      hosted API 34, and pinned web behavior pass on the exact PR head.
- [ ] All four required screenshot names have reviewed evidence, or Phase 1 is
      explicitly blocked; an unsupported web screenshot is not marked passed.
- [ ] VoiceOver, TalkBack, Chrome accessibility-tree, and release-level iOS
      records are attached where required; missing human evidence blocks
      closure rather than being inferred from semantics tests.
- [ ] Full publication commands pass with Flutter 3.41.2 and hosted exact
      minimum Flutter 3.41.0 passes.
- [ ] API docs, README, changelog, compatibility statement, traceability table,
      platform manifests, visual review, and ten-item handoff packet are ready.
- [ ] Entire diff reviewed; only Phase 1 files staged; ready-for-review PR open
      and exact-head checks monitored.
- [ ] `plan/README.md` and this plan contain the final evidence/status.
- [ ] No merge occurs without explicit maintainer authorization; after an
      authorized merge, workflows on the resulting `main` commit are verified
      before Phase 1 is closed.

Block Phase 1 and continue Phase 2 Link if actual AT contradicts the contract,
a required target cannot execute an input path, focus escapes/is lost, a test
is retry-dependent, a stable required screenshot cannot be produced without
an explicit alternate-evidence decision, or manual AT evidence is unavailable.
