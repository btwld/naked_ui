# Per-component process

Every component phase follows this workflow. The frozen briefing is the
historical handoff and research baseline. A file under `phases/` becomes
execution authority only when that phase is active, its blocking decisions are
explicitly approved, current code has been re-inspected, and the plan has been
activated just in time. Inactive phase files are research drafts: they preserve
useful evidence but cannot authorize implementation or silently narrow the
briefing. Every approved delta must be visible in the active plan and in
`decisions.md`.

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
- **Reuse before invention** — inspect the declared-minimum and current-stable
  Flutter raw primitives plus existing Naked UI utilities. Apply the audit and
  release protocol in
  [flutter-raw-primitives.md](flutter-raw-primitives.md). Record why a raw
  primitive is adopted, adapted, used as a behavior reference, watched, or
  rejected; never copy private framework implementation merely to force a
  proposed API to work. Material/Cupertino and
  [`shadcn_flutter`](shadcn-flutter-reference.md) comparisons contribute
  behavior and negative test cases, not styling or a second component-system
  dependency.
- **Version truthfulness** — compile and test on exact Flutter 3.41.0 and the
  workspace pin. Components depending on raw behavior that changed by current
  stable also run a pinned 3.44.6 compatibility slice. Use the executable FVM
  matrix below; re-verify the current stable version and commit when
  implementation begins. Beta/main runs are non-blocking canaries only and
  never authorize a package API or release claim.
- **Integration proof is operational, not implied** — every phase follows
  [integration-testing.md](integration-testing.md), including authoritative
  runners, bounded waits, failure triage, artifacts, and manual AT evidence.
- Confirmed vs proposed vs open-decision language is defined in
  [§2.1](briefing.md#21-confirmed-facts-versus-proposals). Open decisions are
  explicitly approved and resolved in [decisions.md](decisions.md) **before**
  the implementation PR.

## Workflow (briefing [§8](briefing.md#8-required-implementation-process))

| Phase | Deliverable | Gate |
|---|---|---|
| **A — Contract review** | Phase plan linked in the issue/PR; raw-reuse decision, release watchlist, and semantics matrix reviewed; every input path, focus path, timer, platform scenario, SDK boundary, and known engine limitation listed | Demand/spike gates passed, current Flutter channels re-audited, reviewer sign-off on the contract, decisions resolved, integration playbook checklist mapped |
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

## Executable SDK and local command matrix

Run from the repository root. The committed `.fvmrc` pins Flutter 3.41.2.
`fvm flutter`/`fvm dart` resolve that project pin, while `fvm spawn <version>`
runs a Flutter command on an exact alternate SDK. This syntax is defined by the
[FVM command reference](https://fvm.app/documentation/guides/basic-commands)
and was rechecked locally with FVM 4.1.0 on 2026-07-13.

Workspace publication gate:

```sh
fvm install --skip-pub-get
fvm flutter pub get
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test packages/naked_ui/test
fvm flutter test packages/example/test

# fast integration smoke
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/all_tests.dart

# real macOS
fvm flutter test -r compact -d macos integration_test/all_tests.dart
```

Exact declared-minimum gate, mirroring the hosted minimum job:

```sh
fvm install 3.41.0 --skip-pub-get
fvm spawn 3.41.0 pub get
fvm spawn 3.41.0 analyze
fvm spawn 3.41.0 test packages/naked_ui/test
```

Current-stable compatibility gate for a component whose raw primitive changed
after 3.41. Flutter 3.44.6 was verified as the stable release dated 2026-07-09;
the active phase must recheck the current stable before execution and record
why it keeps or updates this pin.

```sh
fvm install 3.44.6 --skip-pub-get
fvm spawn 3.44.6 pub get
fvm spawn 3.44.6 analyze
fvm spawn 3.44.6 test packages/naked_ui/test
```

Do not write a vague `beta` or `main` gate. If the raw-primitives watchlist
identifies a relevant unreleased change, the active plan must record an exact
Flutter commit and the exact focused `fvm spawn <commit> ...` command. That run
is diagnostic and non-blocking. See [§21.7](briefing.md#217-exact-local-commands)
and [integration-testing.md](integration-testing.md) for Android/web drivers
and artifact commands.

## Phase plan file template

Use this shape when adding or materially revising a phase plan:

```markdown
# Phase NN — <name>

Authority: active just-in-time execution plan | inactive research draft
Goal: <one paragraph>
Contract source: briefing §<n>; list every explicit delta. Decisions: D-xx.
Baseline commit: <sha this plan was derived against>

## Scope and stop gate
State what ships, what is deferred, what evidence authorizes implementation,
and what blocks only this component.

## Reuse before new machinery
List existing Naked UI code, raw Flutter primitives at minimum/current SDK,
and rejected alternatives with reasons.

## Semantics and interaction contract
Answer role, name, value/state, actions, focus, keyboard, pointer/touch,
disabled/read-only, announcement, overlay, timer, and localization questions.

## Tasks
For each task: What / Where (file:line) / How / Verify (exact command).
Order tasks so the PR stays releasable at every merge point.

## Research and readiness
- Current-code baseline re-verified:
- Minimum/current Flutter behavior re-verified:
- Decisions resolved with explicit approval evidence:
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
