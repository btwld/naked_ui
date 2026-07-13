# Naked UI component expansion — plan

This folder is the working plan for delivering the eight new/expanded headless
primitives (and the test-harness hardening that must precede them) described in
the engineering briefing handed off from the Remix team.

Consumer: **Remix for Flutter**. Boundary rule: Naked UI owns behavior, focus,
keyboard, overlays, timers, and semantics — never styling, product copy, or
business rules ([briefing §5](briefing.md#5-definition-of-the-headless-boundary)).

## Folder contents

| File | Role | Mutability |
|---|---|---|
| [briefing.md](briefing.md) | Full handoff contract (per-component behavior, semantics, tests, evidence) | **Frozen** — reference only |
| [process.md](process.md) | The repeatable per-component workflow and PR gates | Stable |
| [integration-testing.md](integration-testing.md) | Mandatory runner, determinism, evidence, and failure-triage playbook | Stable |
| [decisions.md](decisions.md) | Decision log D-01…D-15 and escalation rule | **Living** — update as decisions resolve |
| README.md (this file) | Index and status board | **Living** — update every phase PR |
| [phases/](phases/) using the NN-name.md convention | Executable plan for one phase | Created just-in-time when a phase starts |

## Status board

Phase numbers follow the briefing's PR order ([§7](briefing.md#7-delivery-sequence-and-pull-request-boundaries)).
A phase plan file is created from the briefing contract when the phase starts —
do not pre-write plans for phases whose blocking decisions are unresolved.

| Phase | Scope | Contract | Blocking decisions | Plan | Status |
|---:|---|---|---|---|---|
| 0 | Test-harness hardening | [§6.2](briefing.md#62-confirmed-delivery-gaps-to-fix-before-adding-the-new-suite), [§21](briefing.md#21-integration-screenshot-golden-and-ci-implementation) | D-12, D-13, D-14, D-15 (resolved) | [phases/00-test-harness.md](phases/00-test-harness.md) | **Closed** — delivered by [PR #63](https://github.com/btwld/naked_ui/pull/63), squash-merged as `58a48a3` |
| 1 | Alert Dialog (extend `NakedDialog`) | [§13](briefing.md#13-component-contract-alert-dialog) | D-02 (resolved) | — | Ready for phase plan |
| 2 | Link | [§20](briefing.md#20-component-contract-link) | — | — | Not started |
| 3 | Field + `NakedTextField` integration | [§17](briefing.md#17-component-contract-field) | D-08, D-09 | — | Not started |
| 4 | Toggle Group expansion | [§14](briefing.md#14-component-contract-toggle-group) | D-01 | — | Not started |
| 5 | Context Menu | [§15](briefing.md#15-component-contract-context-menu) | D-03 | — | Not started |
| 6 | Toast | [§16](briefing.md#16-component-contract-toast) | D-04, D-05, D-06, D-07 | — | Not started |
| 7 | Hover Card | [§19](briefing.md#19-component-contract-hover-card--preview-card) | — | — | Not started |
| 8 | Combobox | [§18](briefing.md#18-component-contract-combobox) | D-10, D-11 + **accessibility spike ([§18.3](briefing.md#183-accessibility-spike-required-before-final-api))** | — | Blocked on spike |

Release grouping ([§23.2](briefing.md#232-recommended-release-grouping)):
prerelease 1 = phases 1–3, prerelease 2 = phases 4–5, prerelease 3 = phases 6–7,
Combobox ships alone after its spike passes. A blocked phase does not block
independent phases.

## Program readiness

Phase 0 made the harness trustworthy enough to begin component work. The
program is **ready to start targeted planning**, but it is not research-complete
for every phase and no phase may bypass its open decisions, spikes, or evidence
gates.

| Phase | Start readiness | Required work before implementation |
|---:|---|---|
| 1 — Alert Dialog | **Ready for a just-in-time phase plan** | Re-verify the current `NakedDialog` baseline, carry the resolved D-02 focus contract into tests/examples, then create the phase plan. |
| 2 — Link | **Ready for a just-in-time phase plan** | Re-verify Flutter 3.41.0/3.41.2 link semantics and existing interaction-state patterns; no product decision currently blocks implementation. |
| 3 — Field | Blocked on decisions | Resolve D-08 metadata precedence and D-09 initial-error announcement policy before implementation/semantics tests. |
| 4 — Toggle Group | Blocked on compatibility decision | Resolve D-01 and document the consumer-facing `selected` to `toggled` announcement migration. |
| 5 — Context Menu | Spike/decision required | Resolve D-03 with a trigger-role/semantic-long-press prototype and real VoiceOver/TalkBack results. |
| 6 — Toast | Blocked on scope/API decisions | Resolve D-04–D-07 before tests or controller implementation; timer, queue, focus, and announcement contracts then become the phase plan. |
| 7 — Hover Card | Contract ready, dependency pending | Land Link first, then create the phase plan and verify reusable overlay positioning plus pointer-grace geometry. |
| 8 — Combobox | **Blocked on required accessibility spike** | Land Field, run the macOS/Android/web spike, then resolve D-10/D-11 before freezing the API. |

Shared closure gates for every component:

- Follow [integration-testing.md](integration-testing.md) and include its
  per-phase checklist in the executable phase plan.
- Re-evaluate or explicitly resolve the Flutter 3.41.2 web-screenshot
  limitation; a web behavior log is not a silent substitute for a required
  screenshot.
- Schedule and record the required VoiceOver, TalkBack, Chrome accessibility
  tree, and release-level iOS checks. Automated semantics alone are not enough.
- Re-verify the phase's current-code baseline when its just-in-time plan is
  created; the original `0ca0b8b` audit is historical evidence, not a permanent
  assumption.

Recommended next move: start the Phase 1 Alert Dialog plan in the nominal
delivery order. Phase 2 Link remains independently ready if Phase 1 becomes
blocked during implementation. Do not begin all phases in parallel.

## How to work a phase

1. Resolve the phase's blocking decisions in [decisions.md](decisions.md) first
   — nothing is decided silently inside an implementation PR.
2. Create an NN-name.md plan under [phases/](phases/) by deriving tasks from
   the phase's briefing contract section (see the template at the end of
   [process.md](process.md)).
3. Follow the workflow in [process.md](process.md) (contract review → failing
   tests → implementation → fixture → platform proof → evidence packet).
4. In the phase's final PR, update this status board and any resolved rows in
   decisions.md.

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
