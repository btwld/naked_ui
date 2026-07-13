# Naked UI component expansion — plan

This folder is the working plan for evaluating and delivering eight proposed
headless primitives, plus the test-harness hardening that preceded them. The
active plans and inactive research drafts incorporate the current repository,
open PRs, Flutter 3.41–3.44 raw primitives, and accessibility research. A draft
may recommend narrowing or blocking part of the original Remix briefing, but
only an explicitly approved active plan can make that delta authoritative.

Consumer: **Remix for Flutter**. Boundary rule: Naked UI owns behavior, focus,
keyboard, overlays, timers, and semantics — never styling, product copy, or
business rules ([briefing §5](briefing.md#5-definition-of-the-headless-boundary)).

## Folder contents

| File | Role | Mutability |
|---|---|---|
| [briefing.md](briefing.md) | Original Remix handoff and historical research baseline | **Frozen** — reference only; an approved active plan may explicitly supersede a proposal |
| [process.md](process.md) | The repeatable per-component workflow and PR gates | Stable |
| [integration-testing.md](integration-testing.md) | Mandatory runner, determinism, evidence, and failure-triage playbook | Stable |
| [decisions.md](decisions.md) | Decision log D-01…D-19 and escalation rule | **Living** — update as decisions resolve |
| [flutter-raw-primitives.md](flutter-raw-primitives.md) | Exact stable/beta/master raw-primitive audit, component mapping, and release watchlist | **Living** — re-audit when a phase starts or Flutter releases |
| [shadcn-flutter-reference.md](shadcn-flutter-reference.md) | Per-component source audit of `shadcn_flutter`; reusable behaviors and negative test cases | Reference baseline — refresh only if a phase relies on changed upstream behavior |
| README.md (this file) | Index and status board | **Living** — update every phase PR |
| [phases/](phases/) using the NN-name.md convention | Active-phase execution plan or inactive-phase research draft, including deltas, reuse, evidence, and stop gates | Only an explicitly activated, decision-cleared just-in-time plan is execution authority; inactive drafts are advisory |

## Status board

Phase numbers retain the briefing's nominal PR order. The inactive phase files
preserve useful clean-sheet research so dependencies and wrong assumptions are
visible, but they are **not** pre-approved execution plans. Only the active
phase's explicitly activated just-in-time plan authorizes implementation. A
blocked phase authorizes only a separately approved spike, and an unresolved
decision is never settled by prose in a draft.

| Phase | Scope | Contract | Blocking decisions | Plan | Status |
|---:|---|---|---|---|---|
| 0 | Test-harness hardening | [§6.2](briefing.md#62-confirmed-delivery-gaps-to-fix-before-adding-the-new-suite), [§21](briefing.md#21-integration-screenshot-golden-and-ci-implementation) | D-12, D-13, D-14, D-15 (resolved) | [phases/00-test-harness.md](phases/00-test-harness.md) | **Closed** — delivered by [PR #63](https://github.com/btwld/naked_ui/pull/63), squash-merged as `58a48a3` |
| 1 | Alert Dialog (extend `NakedDialog`) | [§13](briefing.md#13-component-contract-alert-dialog) | D-02 (resolved) | [phases/01-alert-dialog.md](phases/01-alert-dialog.md) | **PR #64 open** — implementation is sound; manual AT/release evidence and briefing correction remain |
| 2 | Link | [§20](briefing.md#20-component-contract-link) | D-16 (resolved) | [phases/02-link.md](phases/02-link.md) | **PR #65 review-ready at `8084ecf`** — approved correction implemented; all seven exact-head hosted checks pass; closure still awaits required web screenshots, manual AT, and real Context Menu/Hover Card composition |
| 3 | Field + `NakedTextField` integration | [§17](briefing.md#17-component-contract-field) | D-08, D-09, D-19 (approval pending) | [phases/03-field.md](phases/03-field.md) | **Research draft only** — TextField-first recommendation; activate just in time only after D-08/D-09/D-19 approval |
| 4 | Toggle Group intent/focus | [§14](briefing.md#14-component-contract-toggle-group) | D-01, D-19 (approval pending) | [phases/04-toggle-group.md](phases/04-toggle-group.md) | **Research draft only** — preserve-single recommendation; activate only after decision approval and consumer classification |
| 5 | Context Menu | [§15](briefing.md#15-component-contract-context-menu) | D-03 (evidence spike open); D-19 (approval pending) | [phases/05-context-menu.md](phases/05-context-menu.md) | **Research/spike draft only** — implementation blocked on trigger-role/AT evidence and decisions |
| 6 | Toast | [§16](briefing.md#16-component-contract-toast) | D-04–D-07, D-19 (approval pending) | [phases/06-toast.md](phases/06-toast.md) | **Demand-gated research draft only** — no implementation until a named use case and explicit decisions |
| 7 | Hover Card | [§19](briefing.md#19-component-contract-hover-card--preview-card) | D-17, D-19 (approval pending) | [phases/07-hover-card.md](phases/07-hover-card.md) | **Demand/dependency-gated research draft only** — Link must land and Remix must supply a valid preview story |
| 8 | Combobox | [§18](briefing.md#18-component-contract-combobox) | D-10, D-11 (evidence spike open); D-18, D-19 (approval pending) | [phases/08-combobox.md](phases/08-combobox.md) | **Research/spike draft only** — public API blocked on RawAutocomplete/AT/IME/version evidence and decisions |

**Clean-sheet research recommendation: split.** This is not an approval or one
eight-component commitment.
Finish/refine Alert Dialog and Link, then implement the smaller TextField-first
Field and the compatible single-mode Toggle focus work after approval. The
Context Menu and Combobox research recommends spike-only evaluation; Toast and
Hover Card remain demand-gated. No inactive draft authorizes either a spike or
implementation. This keeps the proven parts of the briefing while removing
speculative APIs and wrong semantic shortcuts.

Recommended sequence is evidence-driven rather than a promise to ship all
eight: finish Alert Dialog, correct and land Link, then—only after explicit
decision approval and just-in-time activation—build the TextField-first Field.
Toggle Group's single-mode focus work can follow under the same rule. Context
Menu proceeds only after D-03; Toast and Hover Card require named Remix demand;
Combobox ships alone only after its spike passes. A blocked phase does not block
independent work.

## Program readiness

Phase 0 made the harness trustworthy. Repository and upstream research is
captured for every component, but only the active, decision-cleared
just-in-time plan may be executed. No component may bypass its approval,
demand, spike, version, or manual assistive-technology gate.

| Phase | Start readiness | Required work before implementation |
|---:|---|---|
| 1 — Alert Dialog | **Completion ready** | Rebase/isolate PR #64; finish VoiceOver, TalkBack, Chrome tree, and release iOS evidence. |
| 2 — Link | **Review-ready; not closed** | Approved correction is on PR #65 and exact-head hosted checks pass; obtain web screenshots, manual AT, real Phase 5/7 composition, merge authorization, and post-merge proof. |
| 3 — Field | **Approval + activation required** | Approve D-08/D-09/D-19, re-inspect current code, then create/activate the just-in-time TextField-first plan. |
| 4 — Toggle Group | **Approval + activation required** | Approve D-01/D-19 and classify Remix stories before activating a just-in-time plan. |
| 5 — Context Menu | **Spike approval required** | Approve D-19 and separately approve/run the D-03 trigger-role/semantic-long-press spike before implementation planning. |
| 6 — Toast | **Demand + decisions required** | Name a transient-feedback screen and approve D-04–D-07/D-19 before activating a plan. |
| 7 — Hover Card | **Dependency + demand + decision required** | Land Link, prove a noninteractive/nonessential preview story, and approve D-17/D-19 before activating a spike/plan. |
| 8 — Combobox | **Spike + decisions required** | Land Field; approve D-18/D-19; prove RawAutocomplete, active-option AT, disabled options, IME, and exact 3.41/3.44.6 behavior; then resolve D-10/D-11. |

Shared closure gates for every component:

- Follow [integration-testing.md](integration-testing.md) and include its
  per-phase checklist in the executable phase plan.
- Apply the stable/floor policy and re-audit protocol in
  [flutter-raw-primitives.md](flutter-raw-primitives.md); beta/master findings
  are canaries, not package dependencies.
- Re-evaluate or explicitly resolve the Flutter 3.41.2 web-screenshot
  limitation; a web behavior log is not a silent substitute for a required
  screenshot.
- Schedule and record the required VoiceOver, TalkBack, Chrome accessibility
  tree, and release-level iOS checks. Automated semantics alone are not enough.
- Re-verify the phase's current-code and current-stable Flutter baseline when
  implementation starts; `d341b90` and Flutter 3.44.6 are planning evidence,
  not permanent assumptions.

Recommended next move: finish the missing manual/evidence gates for PRs #64
and #65, then obtain explicit merge authorization. Before Field begins,
present D-08/D-09/D-19 for approval and re-derive its just-in-time plan from
the then-current `main`; do not execute the inactive research draft directly.

## How to work a phase

1. Confirm that the phase has been explicitly activated. Only that active
   just-in-time plan is execution authority; an inactive research draft cannot
   supersede the frozen briefing or authorize work.
2. Re-inspect current `main`, resolve and explicitly approve the phase's
   demand/spike/decision gates in [decisions.md](decisions.md), then revise the
   active plan with every approved delta before public API implementation.
3. Follow the workflow in [process.md](process.md) (contract review → failing
   tests → implementation → fixture → platform proof → evidence packet).
4. In the phase's final PR, update this status board and any resolved rows in
   decisions.md.

### Component-plan research record (2026-07-13)

The inactive research drafts were re-derived at workspace `d341b90` from current source and
tests, open Alert Dialog PR head `409ec27`, open Link PR head `2614555`, exact
Flutter 3.41.0/3.41.2 behavior, and Flutter 3.44.6 current-stable source
(`ee80f08bbf97172ec030b8751ceab557177a34a6`). That baseline was compared with beta
`677d472756f83c14371dd8cc624387065f3d32a7` and master
`cf9e8afe9a5e601158517782b5b824a328bb2c68`. The audit covered
`RawDialogRoute`/`showRawDialog`, `RawMenuAnchor`, the new Cupertino menu
family, `RawTooltip`, `OverlayPortal`/`Overlay`, `RawAutocomplete`, `FormField`,
Semantics roles/properties, Material `SegmentedButton`, official
`url_launcher.Link`, current `shadcn_flutter` master
`a4504aae7a99844a350e64d92f3d2ae773ebb361`, and the relevant WAI-ARIA/WCAG
patterns. The complete Flutter adopt/adapt/watch/reject record is in
[flutter-raw-primitives.md](flutter-raw-primitives.md); the third-party
comparison is in [shadcn-flutter-reference.md](shadcn-flutter-reference.md).
Each draft records a proposed reuse decision, semantics matrix, SDK matrix,
ordered tasks, and stop gate. Those proposals still require just-in-time
revalidation and explicit decision approval before execution.

## Verification record

The briefing's factual claims were checked against this repository at commit
`0ca0b8b` on 2026-07-12 before this plan was created. All 16 checked claims
held, including: package `1.0.0-beta.3` with Flutter `>=3.41.0` floor vs CI pin
`3.41.2`; the "macOS integration" job running `-d flutter-tester`
(`.github/workflows/integration-tests.yml:46`); Android integration being
`workflow_dispatch`-only; no web integration workflow; zero usages of
`takeScreenshot`/`matchesGoldenFile`/`meetsGuideline`; `testKeyboardActivation`
catch-and-return-false and `verifyTabOrder` asserting only widget existence
(`packages/example/integration_test/helpers/keyboard_test_helpers.dart`); the
stale `example/` path in `tool/run_integration_all.sh:9`; the Tooltip
integration file missing from `all_tests.dart`; the 30-minute blanket timeout
and 2-second real `tearDownAll` delay in `all_tests.dart`; 498 widget tests and
89 integration `testWidgets`; the advisory 7.3%-vs-80% coverage gate
(`.github/workflows/ci.yml:79`); and no committed `macos/`/`web/`/`android/`
platform directories under `packages/example`.

Phase 0 hosted evidence was completed for PR #63 at head `3cb5487`, then
squash-merged to `main` as `58a48a3`. The main test suite, exact Flutter 3.41.0
job, aggregate `flutter-tester`, real macOS, pinned headless Chrome, API 34
Android emulator, and PR-title check all passed. The workflows triggered by the
merged commit also passed. Android behavior runs through `flutter test`;
`flutter drive` remains only for screenshot/report-data transport and web
integration.

If the repo has moved past `0ca0b8b`, re-verify a claim before building on it.

### Phase 0 closure (2026-07-12)

All A1–A6, B1–B6, and C1–C3 implementation tasks landed in PR #63 after
maintainer approval of D-12–D-15. The inventory guard, keyboard postcondition,
tab-order assertion, golden 1px mutation, and unnamed-target accessibility
failure were each proven to fail for the intended reason; all temporary
mutations were restored. Phase 0 is closed.

Local verification passed on Flutter 3.41.0 and 3.41.2, real macOS, and matched
Chrome/ChromeDriver 149.0.7827.201; hosted web verification used the pinned
150.0.7871.115 pair. The inspected Dialog screenshot is an 800×600 real-macOS
PNG with a complete manifest. Flutter 3.41.2 web screenshots remain explicitly
unsupported after both the WebDriver path and a repaint-boundary fallback
proved unstable; the blocking web behavior gate uploads its test log instead.
No Android emulator/AVD is installed locally, so the hosted API 34 job is the
authoritative Android proof.

Verification evidence:

- Flutter 3.41.0: analyze clean; 574 package tests passed with 3 documented
  skips.
- Flutter 3.41.2: format and analyze clean; 574 package tests passed with 3
  documented skips; 13 example tests passed with 1 documented golden skip.
- Integration: the sequential component runner completed; the aggregate passed
  88 tests with 1 documented Tooltip skip on `flutter-tester`, real macOS, and
  pinned Chrome.
- Evidence: the approved golden update/verify sequence passed with an unchanged
  SHA-256 baseline; macOS screenshot/manifest generation passed and the image
  was visually inspected.
- CI definitions: every workflow parses as YAML and actionlint reports no
  findings; the pinned Chrome action tag, inputs, and outputs were verified
  against its upstream action definition.
