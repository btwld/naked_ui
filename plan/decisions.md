# Decision log

Living copy of the briefing's decision register
([§24.1](briefing.md#241-decision-log)). The briefing copy is frozen; **this
file is where resolutions are recorded.** No item here may be decided silently
inside an implementation PR — resolve the row, link the PR/issue, then
implement. Blocking relationships are shown on the
[status board](README.md#status-board).

Status values: `open` → `resolved(<choice>)` with a link to where it was decided.

Phase 0 repair-slice review (2026-07-12): Group A and B1 proceeded without
choosing an SDK-floor policy, platform-directory strategy, golden host/font,
or Android/web cadence. The maintainer approved the evidence-backed D-12–D-15
recommendations on 2026-07-12 before decision-dependent implementation began.

### Phase 1 decision evidence (2026-07-12)

- **D-02:** approved the optional caller-owned `initialFocusNode`. When the
  supplied node is available and focusable, the alert dialog focuses it after
  opening; otherwise normal route focus chooses the first focusable descendant.
  Canonical examples must focus the least destructive action for irreversible
  work, the expected action for a simple acknowledgement, or a non-action
  semantic container near the start of long or structured content. Naked UI
  never disposes the caller's node. This follows the
  [WAI-ARIA modal-dialog focus guidance](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/),
  while retaining the target control exposed by established primitives such as
  [React Spectrum AlertDialog](https://react-spectrum.adobe.com/Dialog) and
  [Radix Alert Dialog](https://www.radix-ui.com/primitives/docs/components/alert-dialog).

### Phase 0 decision evidence (2026-07-12)

- **D-12:** the official Flutter repository contains the exact `3.41.0` tag.
  A local FVM 3.41.0 run resolved the workspace, analyzed with no issues, and
  passed all 574 package/widget/semantics tests (three intentional skips).
- **D-13:** Flutter 3.41.2 generated standard Android, macOS, and web platform
  directories totaling about 516 KiB (152/300/64 KiB). The reviewed generator
  output is present in the working tree so local real-target commands and CI do
  not regenerate target scaffolding on every run.
- **D-14:** the pinned Flutter 3.41.2 SDK contains `Roboto-Regular.ttf` with its
  Apache-2.0 license. A checked-in copy plus an explicit Ubuntu runner label,
  fixed surface/DPR/locale/text scale/brightness, and disabled animation now
  provide the golden harness a reproducible baseline.
- **D-15:** GitHub has no recorded runs of the existing manual Android workflow.
  Recent `flutter-tester` integration runs take roughly two to three minutes.
  Affected-path PR/merge-queue jobs plus reusable Android/web release gates now
  require the exact tagged commit while avoiding unrelated docs-only runs.

| ID | Decision | Briefing recommendation | Must resolve by | Status |
|---|---|---|---|---|
| D-01 | Toggle option semantics migration (`selected` → `toggled`) | Use button + `toggled` for all Toggle Group modes; changelog + announcement note; keep Radio Group for radio semantics | Before Toggle Group implementation (phase 4) | open |
| D-02 | Alert Dialog initial focus API | Keep optional `initialFocusNode`; document safe-target heuristics; explicit canonical examples | Before Alert Dialog PR approval (phase 1) | [resolved(optional caller-owned node plus documented safe-target heuristics)](#phase-1-decision-evidence-2026-07-12) |
| D-03 | Context Menu trigger semantic action | Preserve child role + long-press semantic action; no fake button; prototype with VoiceOver/TalkBack | During Context Menu spike (phase 5) | open |
| D-04 | Toast composition API | Structured message/action/close helpers so duplicate message semantics can be excluded without hiding controls | Before Toast tests are written (phase 6) | open |
| D-05 | Toast global shortcut | Caller opt-in only; canonical example may use F8; never reserve a key by default | Before Toast PR approval (phase 6) | open |
| D-06 | Toast queue overflow | Unlimited pending queue or explicit nullable `maxQueued`; never drop silently without a dismissal reason | Before controller implementation (phase 6) | open |
| D-07 | Toast swipe in first release | Defer unless all alternate dismissal + deterministic drag tests fit the PR | At Toast scoping (phase 6) | open |
| D-08 | Field/TextField duplicate metadata | Debug-assert conflicting values; allow identical values; field scope is semantic source of truth | Before Field implementation (phase 3) | open |
| D-09 | Initial Field error announcement | Initial error discoverable but not automatically assertive; later transitions announce once | Before Field semantics tests (phase 3) | open |
| D-10 | Combobox active-option strategy | Choose only after the macOS/Android/web spike; status announcer is the leading fallback | Before Combobox public API freeze (phase 8) | open |
| D-11 | Combobox role on Flutter 3.41 | Use `SemanticsRole.comboBox` only if the prototype shows no regression; otherwise document fallback + upstream issue | During Combobox spike (phase 8) | open |
| D-12 | Naked UI minimum Flutter | Keep `>=3.41.0` only if an exact 3.41.0 CI job passes; otherwise raise the minimum deliberately | Phase 0 (test-harness PR) | [resolved(keep `>=3.41.0`; exact-minimum CI)](#phase-0-decision-evidence-2026-07-12) |
| D-13 | Example platform directories | Commit reviewed minimal platform files or generate reproducibly in CI; job names must match actual devices | Phase 0 (test-harness PR) | [resolved(commit reviewed Android/macOS/web directories)](#phase-0-decision-evidence-2026-07-12) |
| D-14 | Golden host/font pinning | One Ubuntu image, Flutter 3.41.2, fixed surface config, checked-in licensed test font | Phase 0 (test-harness PR) | [resolved(Ubuntu 24.04, Flutter 3.41.2, Roboto Apache-2.0, fixed harness)](#phase-0-decision-evidence-2026-07-12) |
| D-15 | Android/web PR frequency | Affected-path PR/merge-queue jobs; release blocked unless both passed on the exact release commit | Phase 0 (test-harness PR) | [resolved(affected PR/merge queue plus exact-tag release gates)](#phase-0-decision-evidence-2026-07-12) |

## Risk register

The risk register lives in the briefing
([§24.2](briefing.md#242-risk-register)) and stays there; link a risk row from
a phase plan when it becomes active.

## Escalation rule ([§24.3](briefing.md#243-escalation-rule))

Block the component (not the program) when: real screen-reader behavior
contradicts the semantics contract; a supported target cannot perform a
required keyboard/touch path; focus escapes or is lost after a standard close
path; a required test is flaky without retries; base behavior needs product
styling or business logic to work; or an unresolved Flutter limitation would
make the release claim misleading.
