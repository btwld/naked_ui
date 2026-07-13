# Per-component process

Every component phase follows this workflow. It is a navigation layer over the
briefing — the briefing sections linked here are the binding contract; this
file just makes them executable in order. Do not restate contract details here.

## Ground rules (apply to every PR)

- **Headless boundary** — behavior/semantics in Naked UI; styling, copy, and
  business rules stay in consumers ([§5](briefing.md#5-definition-of-the-headless-boundary)).
- **API conventions** — builder/child invariant, controlled state, controller
  ownership, effective-enabled, localization (no hard-coded English), reduced
  motion ([§9](briefing.md#9-cross-component-api-conventions)).
- **Semantics contract** — answer every row of the universal matrix
  ([§10](briefing.md#10-universal-semantics-contract)); mind the Flutter 3.41.2
  role caveats ([§10.2](briefing.md#102-important-flutter-3412-caveat)).
- **Keyboard/focus rules** — test outcomes, not key sends; use
  `Shortcuts`/`Actions`/`FocusTraversalGroup`; directionality and restoration
  rules ([§11](briefing.md#11-universal-keyboard-and-focus-rules)).
- **One behavior contract per PR**, each PR releasable
  ([§7](briefing.md#7-delivery-sequence-and-pull-request-boundaries)).
- **Integration proof is operational, not implied** — every phase follows
  [integration-testing.md](integration-testing.md), including authoritative
  runners, bounded waits, failure triage, artifacts, and manual AT evidence.
- Confirmed vs proposed vs open-decision language is defined in
  [§2.1](briefing.md#21-confirmed-facts-versus-proposals). Open decisions are
  resolved in [decisions.md](decisions.md) **before** the implementation PR.

## Workflow (briefing [§8](briefing.md#8-required-implementation-process))

| Phase | Deliverable | Gate |
|---|---|---|
| **A — Contract review** | Component contract section copied into the issue/PR; semantics matrix written; every input path, focus path, timer, platform scenario, and known engine limitation listed | Reviewer sign-off on the contract, decisions resolved, integration playbook checklist mapped |
| **B — Failing tests** | Tests in the order of §8 Phase B (invariants → builder/scope → pointer → keyboard/focus → semantics → overlay → timers → disposal) | Each test fails for the intended missing behavior |
| **C — Implementation** | Smallest behavior surface; existing `NakedState`/builder/scope conventions; injectable durations; no styles, no English defaults | Analyze/format/unit green |
| **D — Example fixture** | Deterministic canonical example: stable `ValueKey`s, local data, state readout, fixed viewport, RTL/large-text variants, reset behavior | Fixture reviewed against §8 Phase D list |
| **E — Platform proof** | Follow [integration-testing.md](integration-testing.md): flutter-tester → real macOS → Android behavior → pinned web behavior; independent screenshot/golden evidence; accessibility guidelines; manual AT checks | All layers in [§12.1](briefing.md#121-required-test-layers) evidenced; unsupported requirements block closure unless explicitly resolved |
| **F — Handoff packet** | The 10-item evidence package ([§22.1](briefing.md#221-per-component-pr-contents)) incl. traceability table ([§22.2](briefing.md#222-requirement-traceability-table-template)), manual AT records ([§22.3](briefing.md#223-manual-accessibility-result-template)), screenshot review ([§22.4](briefing.md#224-screenshot-review-template)) | Reviewer answers the API review questions ([§22.5](briefing.md#225-api-review-questions)) |

## Test standards (non-negotiable)

- Semantics tests follow the 10-point standard in
  [§12.3](briefing.md#123-semantics-test-standard).
- Keyboard tests follow [§12.4](briefing.md#124-keyboard-test-standard) — no
  catch-and-continue helpers, assert postconditions.
- Deterministic pumping: exact pumps or bounded `pumpUntil`; `pumpAndSettle()`
  is forbidden for timer/repeating-animation components
  ([§21.2](briefing.md#212-deterministic-pumping)).
- File placement and naming: [§12.2](briefing.md#122-proposed-file-names).
  Export from `packages/naked_ui/lib/src/naked_widgets.dart`; add the
  integration main to `packages/example/integration_test/all_tests.dart` — a
  test file not in the aggregate runner is not delivered.
- Flake policy: no `continue-on-error` on required checks, no real sleeps,
  quarantine requires issue+owner+date ([§21.10](briefing.md#2110-flake-policy)).
- Native behavior uses `flutter test`; `flutter drive` is limited to web and
  host-side screenshot/report-data transport. Behavior and evidence are
  separate blocking results ([integration playbook](integration-testing.md)).
- Pointer/gesture cleanup errors propagate. Platform-specific failures follow
  the playbook's root-cause protocol; retries and timeout inflation are not
  fixes.
- Disposal/leak checklist for every overlay/timer component
  ([§21.11](briefing.md#2111-leak-and-disposal-checks)).

## Definition of done

A component is done only when every box in
[§23.1](briefing.md#231-package-level-definition-of-done) is checked, including
real macOS/Android/web runs, reviewed screenshots, manual VoiceOver/TalkBack
records, and a changelog naming any semantic or keyboard behavior change.
Escalation conditions that block a component are listed in
[§24.3](briefing.md#243-escalation-rule).

## Local commands

Root of this repo (see [§21.7](briefing.md#217-exact-local-commands) for the
full set including Android/web):

```sh
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test packages/naked_ui/test
flutter test packages/example/test

# fast integration smoke
cd packages/example
flutter test -r compact -d flutter-tester integration_test/all_tests.dart

# real macOS (after Phase 0 lands platform files)
flutter test -r compact -d macos integration_test/all_tests.dart
```

## Phase plan file template

Create an NN-name.md plan under [phases/](phases/) when a phase starts:

```markdown
# Phase NN — <name>

Goal: <one paragraph>
Contract: briefing §<n> (binding). Decisions resolved: D-xx (link decisions.md).
Baseline commit: <sha this plan was derived against>

## Tasks
For each task: What / Where (file:line) / How / Verify (exact command).
Order tasks so the PR stays releasable at every merge point.

## Research and readiness
- Current-code baseline re-verified:
- Decisions resolved:
- Required spike/manual AT sessions:
- Known engine/platform limitations and stop conditions:

## Integration proof plan
- Integration file and aggregate group:
- Stable fixture keys and deterministic data/reset:
- Scenario-to-platform matrix:
- Exact pumps / observable waits / teardown ownership:
- Screenshot, golden, guideline, and manual AT evidence:
- Exact local and hosted commands:

## Acceptance
- [ ] Contract checklist from briefing §<n> acceptance section
- [ ] Existing suite green (widget + integration aggregate)
- [ ] Integration playbook checklist evidenced on every applicable target
- [ ] Status board + decisions.md updated
```
