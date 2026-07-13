# Decision log

Living copy of the briefing's decision register
([§24.1](briefing.md#241-decision-log)). The briefing copy is frozen; **this
file is where resolutions are recorded.** No item here may be decided silently
inside an implementation PR — resolve the row, link the PR/issue, then
implement. Blocking relationships are shown on the
[status board](README.md#status-board).

Status values:

- `open` when evidence or a choice is still missing;
- `open (recommendation recorded; approval pending)` when research supports a
  direction but the maintainer has not explicitly approved it; and
- `resolved(<choice>)` only after explicit approval, with a link to the
  approval/evidence record.

Phase 0 repair-slice review (2026-07-12): Group A and B1 proceeded without
choosing an SDK-floor policy, platform-directory strategy, golden host/font,
or Android/web cadence. The maintainer approved the evidence-backed D-12–D-15
recommendations on 2026-07-12 before decision-dependent implementation began.

### Component-plan research recommendations (2026-07-13)

These are evidence-backed recommendations, not approvals. The clean-sheet
review requested on 2026-07-13 compared current Naked UI source/tests and open
PRs with Flutter 3.41.0/3.41.2, Flutter 3.44.6 stable source, beta/master
canaries, official Flutter package implementations, current `shadcn_flutter`
source, and relevant WAI-ARIA/WCAG behavior. They remain open until the
maintainer explicitly approves them; decisions that depend on real
assistive-technology output also require the named spike. The exact upstream
audits are recorded in
[flutter-raw-primitives.md](flutter-raw-primitives.md) and
[shadcn-flutter-reference.md](shadcn-flutter-reference.md).

- **D-01:** preserve the existing single constructor's button + `selected`
  semantics. A future multiple constructor uses button + `toggled`; one node
  never exposes both. Content switching uses `NakedTabs`, and exclusive form
  choice uses `NakedRadioGroup`. Multiple mode requires a real consumer story.
- **D-04:** Toast uses structured message, optional action, and optional close
  composition so one announcement can be separated from usable controls.
- **D-05:** Toast installs no global shortcut. Consumers may opt in; an example
  may demonstrate F8 without making it a package default.
- **D-06:** Toast MVP shows one entry and promotes a FIFO queue. `maxQueued` is
  nullable; an explicit cap reports overflow through a dismissal reason. No
  entry is dropped silently.
- **D-07:** swipe dismissal is deferred from the Toast MVP.
- **D-08:** Field is the semantic source inside its scope. Identical explicit
  TextField metadata is accepted; conflicting metadata asserts in debug.
- **D-09:** an initial error is discoverable but not assertively announced. A
  later changed non-empty error announces once; unchanged rebuilds do not.
- **D-17:** `RawTooltip` is a behavior reference for Hover Card but is not the
  default base because the minimum SDK lacks per-instance public hide/focus/
  Escape ownership. Spike `RawMenuAnchor` plus existing generic positioning
  first; reverse only with recorded per-instance evidence.
- **D-18:** Combobox starts with an unexported `RawAutocomplete` spike and
  single editable selection. Multiple/token selection is a separate phase.
  No public API freezes until active-option AT, disabled options, IME, async,
  and 3.41/3.44.6 behavior pass.
- **D-19:** production code may use only public Flutter APIs available at the
  declared minimum. Current-stable additions are compatibility evidence until
  the floor is deliberately raised; beta/master are non-blocking canaries.
  Never import `package:flutter/src/...` or depend on experimental windowing.

### Phase 2 decision evidence (approved 2026-07-13)

- **D-16:** after the reviewer reproduced duplicate browser navigation and a
  still-navigable unavailable Link, the maintainer authorized the correction.
  `linkUrl` is the destination and availability source. Naked UI directly uses
  the official
  [`url_launcher` 6.3.2 `Link`](https://github.com/flutter/packages/blob/url_launcher-v6.3.2/packages/url_launcher/url_launcher/lib/src/link.dart):
  its follow callback performs
  default navigation, while a supplied `onPressed` replaces that callback so
  one activation has one owner. Effective enabled state is
  `enabled && linkUrl != null`. The unavailable path bypasses the official web
  wrapper because the
  [`url_launcher_web` 2.4.3 delegate](https://github.com/flutter/packages/blob/url_launcher_web-v2.4.3/packages/url_launcher/url_launcher_web/lib/src/link.dart)
  retains Link semantics when `uri` is null; the
  result has no Link flag, URL, semantic tap, focus path, DOM anchor, or
  `href`, while the consumer child remains ordinary discoverable content.
  Implementation `dc20214` and documentation head `8084ecf` are on
  [PR #65](https://github.com/btwld/naked_ui/pull/65); every available hosted
  check is green on `8084ecf`. Required web screenshots, human AT sessions,
  and real Context Menu/Hover Card composition still block phase closure.

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
| D-01 | Toggle option semantics migration (`selected` → `toggled`) | Preserve `selected` for existing single mode; use `toggled` only for future multiple mode; route Tabs/Radio intent correctly | Before Toggle Group implementation (phase 4) | [open (recommendation recorded; approval pending)](#component-plan-research-recommendations-2026-07-13) |
| D-02 | Alert Dialog initial focus API | Keep optional `initialFocusNode`; document safe-target heuristics; explicit canonical examples | Before Alert Dialog PR approval (phase 1) | [resolved(optional caller-owned node plus documented safe-target heuristics)](#phase-1-decision-evidence-2026-07-12) |
| D-03 | Context Menu trigger semantic action | Preserve child role + long-press semantic action; no fake button; prototype with VoiceOver/TalkBack | During Context Menu spike (phase 5) | open |
| D-04 | Toast composition API | Structured message/action/close helpers so duplicate message semantics can be excluded without hiding controls | Before Toast tests are written (phase 6) | [open (recommendation recorded; approval pending)](#component-plan-research-recommendations-2026-07-13) |
| D-05 | Toast global shortcut | Caller opt-in only; canonical example may use F8; never reserve a key by default | Before Toast PR approval (phase 6) | [open (recommendation recorded; approval pending)](#component-plan-research-recommendations-2026-07-13) |
| D-06 | Toast queue overflow | Unlimited pending queue or explicit nullable `maxQueued`; never drop silently without a dismissal reason | Before controller implementation (phase 6) | [open (recommendation recorded; approval pending)](#component-plan-research-recommendations-2026-07-13) |
| D-07 | Toast swipe in first release | Defer unless all alternate dismissal + deterministic drag tests fit the PR | At Toast scoping (phase 6) | [open (recommendation recorded; approval pending)](#component-plan-research-recommendations-2026-07-13) |
| D-08 | Field/TextField duplicate metadata | Debug-assert conflicting values; allow identical values; field scope is semantic source of truth | Before Field implementation (phase 3) | [open (recommendation recorded; approval pending)](#component-plan-research-recommendations-2026-07-13) |
| D-09 | Initial Field error announcement | Initial error discoverable but not automatically assertive; later transitions announce once | Before Field semantics tests (phase 3) | [open (recommendation recorded; approval pending)](#component-plan-research-recommendations-2026-07-13) |
| D-10 | Combobox active-option strategy | Choose only after the macOS/Android/web spike; status announcer is the leading fallback | Before Combobox public API freeze (phase 8) | open |
| D-11 | Combobox role on Flutter 3.41 | Use `SemanticsRole.comboBox` only if the prototype shows no regression; otherwise document fallback + upstream issue | During Combobox spike (phase 8) | open |
| D-12 | Naked UI minimum Flutter | Keep `>=3.41.0` only if an exact 3.41.0 CI job passes; otherwise raise the minimum deliberately | Phase 0 (test-harness PR) | [resolved(keep `>=3.41.0`; exact-minimum CI)](#phase-0-decision-evidence-2026-07-12) |
| D-13 | Example platform directories | Commit reviewed minimal platform files or generate reproducibly in CI; job names must match actual devices | Phase 0 (test-harness PR) | [resolved(commit reviewed Android/macOS/web directories)](#phase-0-decision-evidence-2026-07-12) |
| D-14 | Golden host/font pinning | One Ubuntu image, Flutter 3.41.2, fixed surface config, checked-in licensed test font | Phase 0 (test-harness PR) | [resolved(Ubuntu 24.04, Flutter 3.41.2, Roboto Apache-2.0, fixed harness)](#phase-0-decision-evidence-2026-07-12) |
| D-15 | Android/web PR frequency | Affected-path PR/merge-queue jobs; release blocked unless both passed on the exact release commit | Phase 0 (test-harness PR) | [resolved(affected PR/merge queue plus exact-tag release gates)](#phase-0-decision-evidence-2026-07-12) |
| D-16 | Link destination and native-browser contract | `linkUrl` owns destination/availability; official `url_launcher.Link` owns default platform navigation; supplied `onPressed` replaces default navigation; unavailable output has no Link/URL/anchor | Before Link PR approval (phase 2) | [resolved(destination-owned official Link with custom override)](#phase-2-decision-evidence-approved-2026-07-13) |
| D-17 | Hover Card raw overlay primitive | Prefer per-instance `RawMenuAnchor`/existing positioning; use `RawTooltip` only if per-instance close/focus/Escape is proven | During Hover Card spike (phase 7) | [open (recommendation recorded; approval pending)](#component-plan-research-recommendations-2026-07-13) |
| D-18 | Combobox raw foundation and first mode | Spike `RawAutocomplete`; single editable selection first; multiple/token selection separate | Before Combobox API work (phase 8) | [open (recommendation recorded; approval pending)](#component-plan-research-recommendations-2026-07-13) |
| D-19 | Flutter raw-primitive release policy | Public APIs at the minimum only; current stable is compatibility evidence; beta/master are canaries; no `package:flutter/src` or experimental feature dependency | Every phase contract review | [open (recommendation recorded; approval pending)](#component-plan-research-recommendations-2026-07-13) |

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
