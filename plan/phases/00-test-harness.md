# Phase 0 — Test-harness hardening

Status: **Closed** — delivered by
[PR #63](https://github.com/btwld/naked_ui/pull/63), squash-merged to `main` as
`58a48a3` from reviewed head `3cb5487`.

Goal: make it impossible for later component work to look green while proving
nothing. Today the integration harness can swallow keyboard failures, "verify"
tab order without checking focus, skips Tooltip entirely, runs a "macOS" CI job
on `flutter-tester`, and has no screenshot/golden/guideline evidence at all.
Fix the harness first so every later phase inherits trustworthy gates.

Contract: briefing [§6.2](../briefing.md#62-confirmed-delivery-gaps-to-fix-before-adding-the-new-suite)
and [§21](../briefing.md#21-integration-screenshot-golden-and-ci-implementation).
Baseline commit: `0ca0b8b` (all file:line references below verified 2026-07-12).

Decisions **D-12–D-15** were resolved with maintainer approval on 2026-07-12
in [decisions.md](../decisions.md). Their decision-dependent tasks are included
in this implementation.

Split guidance: land **Group A + B1** as one PR (pure repairs, releasable),
then **B2–B6** as CI PRs once D-12/D-13/D-15 are resolved. **Group C** may land
here or ride the first component PR (phase 1), per §6.2 — do not let it slip
past phase 1.

---

## Group A — repair the existing harness (no decisions needed)

### A1. Fix the stale integration runner path
- **Where:** `tool/run_integration_all.sh:9` — `pushd example`, but the app
  lives at `packages/example`. The script fails on first use today.
- **How:** change to `pushd packages/example`.
- **Verify:** `bash tool/run_integration_all.sh flutter-tester` runs every
  component file to completion from the repo root.

### A2. Add Tooltip to the aggregate runner
- **Where:** `packages/example/integration_test/all_tests.dart:6-17` imports 12
  component files; `components/naked_tooltip_integration.dart` exists on disk
  but is never imported, so it silently doesn't run in CI.
- **How:** add the import and a `group('Tooltip Tests', tooltip_tests.main)`
  entry. Then add a guard so this can't recur: a small test (or CI step) that
  lists `integration_test/components/*.dart` and fails if any file is missing
  from `all_tests.dart` (briefing §21.1 item 8 / "inventory check").
- **Verify:** aggregate run on `flutter-tester` executes Tooltip groups;
  deleting the import makes the inventory check fail.

### A3. Make `testKeyboardActivation` throw instead of returning false
- **Where:** `packages/example/integration_test/helpers/keyboard_test_helpers.dart:47-72`
  — wraps key sends in `try/catch`, returns `bool`, callers can (and do) ignore
  it. A failed key event currently passes CI.
- **How:** per briefing [§12.4](../briefing.md#124-keyboard-test-standard):
  remove the try/catch and the `bool` return; focus via a known node (or tap
  when pointer-focus is the subject), pump one frame, **assert the target has
  primary focus**, send the key, pump the needed duration, and let callers
  assert the outcome (value change, overlay, callback count). Update all 8
  call-site files: `naked_button_integration.dart`,
  `naked_dialog_integration.dart`, `naked_popover_integration.dart`,
  `naked_toggle_integration.dart`, `naked_checkbox_integration.dart`,
  `naked_tabs_integration.dart`, `naked_accordion_integration.dart`,
  `naked_radio_integration.dart` — each must assert the post-key outcome, not
  the helper's return.
- **Verify:** aggregate green on `flutter-tester`; sanity-check by temporarily
  sending a wrong key in one test and confirming the suite **fails**.

### A4. Make `verifyTabOrder` assert actual focus
- **Where:** same helpers file, lines 24-40 — after `nextFocus()` it only
  asserts `findsOneWidget` (comment admits it: "Just verify the widget
  exists"). Tab order is currently unproven.
- **How:** after each traversal step, assert
  `FocusManager.instance.primaryFocus` is the node attached to
  `expectedOrder[i]` (e.g. compare against `Focus.of(element(...))` /
  the widget's `FocusNode`). Include disabled-item skips where used.
- **Verify:** reorder two finders in one existing call and confirm the test
  fails; restore.

### A5. Remove the real 2-second delay and the 30-minute blanket timeout
- **Where:** `packages/example/integration_test/all_tests.dart:22-24`
  (`defaultTestTimeout = 30 minutes` conceals hangs) and `:31-35`
  (`tearDownAll` with `Future.delayed(seconds: 2)` real sleep).
- **How:** set a bounded default (e.g. 2 minutes per test), drop the
  `tearDownAll` delay — if a documented runner bug requires it, keep it with a
  comment linking the issue (briefing §21.1 items 3, 7).
- **Verify:** aggregate run completes; total wall time drops; an intentionally
  hung test times out at the bounded limit, not 30 minutes.

### A6. Bounded cleanup and a `pumpUntil` helper
- **Where:** `cleanupBetweenTests` (helpers file, lines 8-20) calls
  `pumpAndSettle()`, which hangs on components with live timers or repeating
  animations — fatal once Toast/Hover Card exist. 156 `pumpAndSettle` calls
  exist across `integration_test/` overall.
- **How:** add the bounded `pumpUntil` helper from briefing
  [§21.2](../briefing.md#212-deterministic-pumping) (fails with a diagnostic
  after a frame budget); rewrite `cleanupBetweenTests` to use bounded pumps.
  Do **not** rewrite all 156 call sites now — that churn belongs to each
  component phase; this task only makes shared helpers timer-safe and provides
  the tool.
- **Verify:** existing aggregate stays green; `pumpUntil` has its own small
  test proving it fails (not passes) when the condition is never met.

## Group B — CI gates

### B1. Run the shell runner (or an inventory smoke) in CI
- **Why:** A1/A2 regressions must fail a PR, not be discovered manually
  (briefing §21.1 item 8).
- **How:** add a fast job/step that executes
  `bash tool/run_integration_all.sh flutter-tester` (or at minimum the
  inventory check from A2 plus one component file via the script).
- **Verify:** break the path locally on a branch → CI fails.

### B2. Make the macOS job actually run macOS *(D-13 resolved)*
- **Where:** `.github/workflows/integration-tests.yml:46` runs
  `-d flutter-tester` on a `macos-latest` runner under the name "Integration
  Tests". `packages/example` has **no** committed `macos/` directory, so
  `-d macos` cannot run today.
- **How:** resolve D-13 (commit minimal reviewed platform files vs
  `flutter create --platforms macos .` in CI), then split the workflow into a
  fast `flutter-tester` smoke job and a real `-d macos` job. Job names must
  match the device they run (briefing §21.7-21.8).
- **Verify:** CI log shows the run targeting `macos`; a focus-dependent test
  passes there.

### B3. Gate Android on PRs or nightly + release *(D-15 resolved)*
- **Where:** `.github/workflows/integration-android.yml:3-4` —
  `workflow_dispatch` only; nobody is required to run it.
- **How:** per D-15: affected-path `pull_request` trigger or nightly schedule,
  and a release gate requiring a passing run on the exact release commit.
- **Verify:** open a PR touching `packages/naked_ui/lib/` → Android job queues
  (or nightly run visible + release checklist references it).

### B4. Add a web integration workflow *(D-13, D-15 resolved)*
- **Why:** no web gate exists; web is where semantics-DOM and keyboard behavior
  diverge most. The driver entry already exists
  (`packages/example/test_driver/integration_test.dart`).
- **How:** pinned Chrome/ChromeDriver job running
  `fvm flutter drive --driver=test_driver/integration_test_behavior.dart --target=integration_test/all_tests.dart -d chrome`
  after web platform files exist (D-13), per briefing §21.7.
- **Verify:** job green in CI; artifacts uploaded.

### B5. Exact-minimum SDK job *(D-12 resolved)*
- **Where:** package floor is Flutter `>=3.41.0`
  (`packages/naked_ui/pubspec.yaml:12`) but every CI job pins `3.41.2` — the
  declared minimum is untested.
- **How:** per D-12: either add an analyze/unit/semantics job on exactly
  `3.41.0`, or deliberately raise the floor to `3.41.2` in a changelog'd PR.
- **Verify:** the job exists and passes, or the floor is raised — no third state.

### B6. Stop the advisory coverage theater
- **Where:** `.github/workflows/ci.yml:79` — coverage check is
  `continue-on-error: true` with actual 7.3% vs an advertised 80% target.
- **How:** don't jump to a blocking 80% (it would be a lie in the other
  direction). Agree a component-level rule instead: new/changed component
  source in a phase PR must come with its contract tests (process.md Phase B),
  and the coverage job reports without claiming a threshold it doesn't enforce.
  Make the agreed rule blocking; delete the misleading 80% label.
- **Verify:** CI output no longer advertises an unenforced threshold.

## Group C — evidence infrastructure (may ride phase 1; do not slip past it)

### C1. Screenshot helper + manifest
- **How:** shared helper per briefing
  [§21.3](../briefing.md#213-screenshot-helper) (single
  `IntegrationTestWidgetsFlutterBinding`, `convertFlutterSurfaceToImage()` on
  Android, capture **after** assertions pass, conditional io/web imports),
  artifact naming `component__scenario__platform__theme.png`, and the manifest
  fields from [§21.4](../briefing.md#214-screenshot-manifest). CI uploads
  screenshots + manifest as artifacts.
- **Verify:** one existing component (e.g. Dialog) produces a named screenshot
  artifact in CI on macOS.

Implementation deviation (2026-07-12): Flutter 3.41.2's `integration_test`
package registers native screenshot plugins only for Android and iOS; invoking
`takeScreenshot` on macOS throws `MissingPluginException`. The helper therefore
uses a fixed `RepaintBoundary.toImage()` desktop fallback and inserts its PNG
bytes into the binding's standard `screenshots` report data. Android uses the
native surface conversion/capture path. Capture remains a dedicated
`screenshot_smoke.dart` target so the full behavioral aggregate and evidence
capture have independent blocking results without retries. The host driver
uses the standard request-data protocol and validates/writes the PNG bytes and
manifest; the behavior aggregate uses a minimal standard driver.

Web screenshot evidence is explicitly unsupported on Flutter 3.41.2: its
WebDriver screenshot command timed out before invoking the host callback, while
the web repaint-boundary fallback produced inconsistent transparent regions
across identical pinned runs. The web implementation therefore throws a clear
unsupported error if capture is requested. The blocking pinned-Chrome behavior
aggregate remains enabled and uploads its test log; later component phases must
not claim reviewed web screenshots until this engine limitation is resolved.

### C2. Golden harness *(D-14 resolved)*
- **How:** `packages/example/test/goldens/components/` harness pinning SDK,
  surface, DPR, locale/direction, text scale, brightness, fonts via
  `FontLoader`, animation state ([§21.5](../briefing.md#215-golden-harness)).
  Baseline update flow is the two-command sequence in §21.5 plus reviewed
  image diffs.
- **Verify:** one golden for an existing component passes twice in CI
  (deterministic) and fails on an intentional 1px change.

### C3. Accessibility-guideline fixture helper
- **How:** helper applying `labeledTapTargetGuideline`,
  `androidTapTargetGuideline`, `iOSTapTargetGuideline`,
  `textContrastGuideline` to canonical styled examples
  ([§21.6](../briefing.md#216-accessibility-guideline-fixture)) — guidelines
  run against the styled example, never the headless wrapper alone.
- **Verify:** guideline test green for one existing canonical example; fails
  when a label is removed.

---

## Acceptance

- [x] A1–A6 implemented; aggregate integration suite green on `flutter-tester`
- [x] A3/A4 proven to fail on induced errors (no catch-and-continue remains)
- [x] Inventory check prevents un-imported integration files (A2)
- [x] B1 smoke and B2 real-macOS job implemented; local targeted and hosted
      aggregate macOS runs are green
- [x] B3/B4/B5 implemented per resolved D-12/D-13/D-15
- [x] B6: no CI output advertises an unenforced threshold
- [x] C1 helper/manifest implemented; named 800×600 real-macOS artifact produced
      and visually inspected locally
- [x] C2 golden harness implemented; update/verify is deterministic and an
      intentional 1px mutation was proven to fail
- [x] C3 accessibility-guideline helper and canonical fixture implemented;
      unlabeled-target failure is covered
- [x] Existing widget and integration suites still pass
- [x] `plan/README.md` status board + `plan/decisions.md` D-12…D-15 updated

Phase 0 is closed. PR #63 at reviewed head `3cb5487` was squash-merged to
`main` as `58a48a3`. It has green hosted proof for the main and exact-minimum
test suites, `flutter-tester`, real macOS, pinned headless Chrome, and the API
34 Android emulator; the workflows triggered by the merged commit also passed.
Android could not be run locally because this machine has no Android
SDK/emulator, so the hosted job is the authoritative Android evidence.

## Verify commands

```sh
fvm flutter pub get
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test packages/naked_ui/test
bash tool/run_integration_all.sh flutter-tester
cd packages/example && fvm flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```
