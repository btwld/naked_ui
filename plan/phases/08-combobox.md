# Phase 08 — Combobox accessibility and RawAutocomplete spike

Status: **Spike plan ready; public API and implementation remain blocked.**

Goal: determine whether Flutter's raw autocomplete can support an accessible,
editable, single-selection combobox on the declared SDK range without breaking
IME/text editing, controlled state, disabled options, or active-option
announcements. Freeze an implementation plan only if the spike passes.

Planning baseline: `d341b90` on 2026-07-13. Contract source: briefing
[§18](../briefing.md#18-component-contract-combobox), narrowed by
[D-18](../decisions.md#component-plan-decision-evidence-2026-07-13). Open
evidence decisions: [D-10 and D-11](../decisions.md#decision-log).

## Scope correction

The first shippable candidate is editable **single selection**. Multiple
selection/token editing is a separate future phase with its own focus,
deletion, announcement, and semantics contract. Do not freeze the briefing's
large single+multiple API before proving the raw foundation.

Combobox is not an editable `NakedSelect`: the text input retains focus while
the popup highlight moves, editing/IME keys keep their normal meaning, and Tab
never acts as implicit selection.

## Reuse before new machinery

| Need | Reuse | Decision |
|---|---|---|
| Text/overlay/highlight core | Flutter `RawAutocomplete<T>` with `OptionsViewOpenDirection.mostSpace` | Starting point for the spike; reuse the public direction policy and do not copy its private overlay/key machinery first. |
| Highlight state | `AutocompleteHighlightedOption.of(context)` | Observe raw highlight in option builders and test an AT announcement adapter. |
| Popup Tab exclusion | Flutter `ExcludeFocus` around the options view | Add explicitly for 3.41–3.44.6; beta Flutter adds this inside `RawAutocomplete`, but release code cannot assume it. |
| Field semantics | Phase 03 `NakedField` + existing `NakedTextField` | Reuse only after Field lands; preserve one input semantics node. |
| Selection display | `displayStringForOption` | Reuse Flutter convention; caller owns domain equality and display copy. |
| Select/menu code | Existing `NakedSelect`/`NakedMenuItem` | Behavior reference only; do not reuse their trigger-focus/menu semantics. |
| [`shadcn_flutter` AutoComplete](../shadcn-flutter-reference.md#component-findings) | Custom overlay/highlight implementation that accepts on Tab and lacks the planned combobox/disabled-option/IME semantic contract. | Negative reference; do not reuse. Add an explicit Tab-no-selection regression. |

`RawAutocomplete` already provides focus/controller coordination, async
stale-result protection, options overlay, arrow/Page key handling, highlight,
and eager text update on selection. It does not understand disabled options,
multiple values, controlled selection rejection, or a complete cross-platform
combobox accessibility mapping. Flutter 3.44.6 improves async-disposal and
soft-keyboard inset behavior, while beta adds popup `ExcludeFocus`; both are
compatibility evidence, not reasons to raise the floor silently. See the
shared [raw-primitives watchlist](../flutter-raw-primitives.md#beta-and-master-watchlist).

## Target semantics and interaction contract

| Question | Candidate contract to prove |
|---|---|
| Input role | Text field plus `SemanticsRole.comboBox` only if real AT mapping is useful on every supported target. |
| Name/value | Field label once; editable query/value from the text control. |
| Expanded | Accurate while options overlay is visible. |
| Relationship | `controlsNodes` references a stable popup semantics identifier if the engine exposes it correctly; the popup explicitly creates its semantics boundary with `container: true`. |
| Active option | Highlighted label/state is announced once without moving input focus or duplicating option-count announcements. |
| Options | Explicit child nodes with names, selected/disabled state, and tap only when enabled; no false menu semantics. |
| Focus | Input keeps primary focus while arrows change highlight. Popup is outside page Tab order. |
| Keyboard | Down/Up/Page/Home/End as proven; Enter accepts enabled highlight; Escape closes; Tab closes and moves focus without selecting. |
| Editing/IME | Caret movement, selection shortcuts, composing text, dead keys, paste, undo, and platform IME are not stolen. |
| Async | Latest query wins; stale results/errors never reopen or replace current options after disposal. |

## Spike protocol — no public API before all gates pass

### 1. Build a disposable RawAutocomplete adapter

- **Where:** `.context/combobox-spike/` or an unexported test fixture; do not add
  it to `naked_widgets.dart`.
- Supply one `TextEditingController`/`FocusNode` to RawAutocomplete and render
  `NakedTextField` from its field builder. Render local synchronous options
  first, then a controllable async source.
- Set `optionsViewOpenDirection` to `OptionsViewOpenDirection.mostSpace` and
  wrap the options-view result in `ExcludeFocus`. Prove Tab reaches the next
  field without entering a focusable option or selecting it.
- Expose observable query, open, highlight, selected value, loading, and empty
  state only inside the spike.

### 2. Map the raw behavior gaps precisely

- Determine whether disabled options can remain visible while raw keyboard
  highlight skips them. If not, do not patch private indices with brittle
  reflection/copies; record the blocker or define a deliberately narrower
  enabled-options-only contract.
- Test RawAutocomplete's eager text update/overlay close against Naked UI's
  controlled conventions. Decide whether selection is an event with eager
  query display or whether a maintainable adapter can wait for the parent.
  Do not promise parent rejection until proven.
- Test duplicate/equal options, option reorder, selected option disappearing,
  empty/loading/error rows, and async stale results.

### 3. Run the D-10/D-11 accessibility matrix

- Candidate A: comboBox role + expanded/controls relationship + option nodes,
  relying on platform output.
- Candidate B: the same tree plus one controlled status node derived from
  `AutocompleteHighlightedOption` for highlight changes.
- On VoiceOver/macOS and release iOS, TalkBack/Android, and Chrome's
  accessibility tree with a screen reader, record: role/name/value, expanded
  state, result count, each highlight, selected/disabled option, acceptance,
  no-results, and close.
- Reject any candidate that announces twice, loses input context, or requires
  focus to enter the popup. Resolve D-10 and D-11 only from these results.
- Give the popup an explicit `Semantics(container: true, identifier: ...)`
  boundary. Flutter 3.44.6 makes `identifier` create a node implicitly, but
  3.41 does not; never let that release difference define the relationship.

### 4. Prove editing and platform keyboard behavior

- Test printable text, Left/Right caret, Shift selection, Cmd/Ctrl+A/C/V/X/Z,
  Home/End ambiguity, dead keys, composing range, candidate selection, Enter,
  Escape, Tab/Shift+Tab, and pointer option selection.
- While composing, combobox shortcuts must not accept/close a candidate unless
  the platform text-input protocol has completed composition.
- Run a real hardware-keyboard path on macOS/web and Android/iOS where
  available; widget key simulation alone is insufficient for IME claims.

### 5. Prove the supported-version boundary

- Run the same spike on Flutter 3.41.0/3.41.2 and 3.44.6. In 3.44.6,
  RawAutocomplete changed soft-keyboard inset constraints, async mounted
  guards, selection bookkeeping, and announcement plumbing.
- Run the beta `ExcludeFocus` implementation as a non-blocking canary. The
  explicit adapter wrapper remains until the package floor contains the
  upstream fix and the Tab regression still passes without it.
- Test an input near every viewport edge, 200% text, RTL, and an open Android
  soft keyboard. If equivalent 3.41 behavior cannot be supplied with public
  APIs, choose explicitly between narrowing the guarantee, raising the Flutter
  floor, or blocking the component.

## Implementation work only after the spike passes

1. Write a short implementation contract from the winning prototype: public
   single-select API, controlled/eager selection rule, option-disabled rule,
   semantics strategy, and exact version guarantee.
2. Add `packages/naked_ui/lib/src/naked_combobox.dart` as a thin adapter around
   RawAutocomplete, not a copied fork. Export it from `naked_widgets.dart`.
3. Add failing behavior and semantics tests in proposed
   `naked_combobox_test.dart` and `naked_combobox_semantics_test.dart`, including
   all spike regressions and disposal.
4. Integrate Field/TextField without a second name/error/input semantics node.
5. Add `packages/example/lib/api/naked_combobox.0.dart`, stable local data,
   registry, `naked_combobox_integration.dart`, aggregate entry,
   `docs/widget/combobox.mdx`, changelog, and the full evidence packet.
6. Open a separate future plan for multiple/token selection; do not append it
   opportunistically to the single-select PR.

Stable fixture keys after approval: `combobox.field`, `.popup`, `.option.<id>`,
`.query`, `.selection`, `.loading`, `.empty`, `.outside-focus`, and `.reset`.

## Planned visual evidence after spike approval

- Screenshots: `combobox__expanded_highlight__macos__reference.png`,
  `combobox__keyboard_inset__android__reference.png`, and
  `combobox__empty_200_rtl__macos__reference.png`.
- Golden: `packages/example/test/goldens/components/baselines/naked_combobox__expanded.png`.
- Active-option and IME claims require AT/input logs in addition to images.

## Verification after implementation

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test packages/naked_ui/test/src/naked_combobox_test.dart
flutter test packages/naked_ui/test/semantics/naked_combobox_semantics_test.dart
flutter test packages/naked_ui/test/src/naked_textfield_test.dart
flutter test packages/naked_ui/test/semantics/naked_textfield_semantics_test.dart
flutter test packages/naked_ui/test
flutter test packages/example/test
cd packages/example
flutter test -r compact -d flutter-tester integration_test/components/naked_combobox_integration.dart
flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```

## Stop conditions

Block the component—not the wider program—if active-option/expanded state is
not understandable on any supported AT target, input focus must move into the
popup, RawAutocomplete cannot skip disabled visible options without copying
private machinery, editing/IME commands are stolen, async results race after
disposal, Tab selects, or truthful keyboard-inset behavior would require an
undeclared Flutter floor increase.

## Acceptance for the spike

- [ ] RawAutocomplete reuse and every gap are documented at 3.41 and 3.44.6.
- [ ] D-10 and D-11 have real VoiceOver, TalkBack, Chrome, and release iOS evidence.
- [ ] Input focus, editing, IME, disabled options, Tab, async races, and insets pass.
- [ ] The single-selection controlled/eager contract is explicit and testable.
- [ ] A thin public adapter is feasible without copying Flutter private implementation.
- [ ] Only then is the implementation contract/public API approved.

## Primary references

- [Flutter `RawAutocomplete`](https://api.flutter.dev/flutter/widgets/RawAutocomplete-class.html)
- [Flutter `AutocompleteHighlightedOption`](https://api.flutter.dev/flutter/widgets/AutocompleteHighlightedOption-class.html)
- [Flutter `OptionsViewOpenDirection`](https://api.flutter.dev/flutter/widgets/OptionsViewOpenDirection.html)
- [Flutter `ExcludeFocus`](https://api.flutter.dev/flutter/widgets/ExcludeFocus-class.html)
- [Flutter `SemanticsRole`](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html)
- [WAI-ARIA Combobox Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/)
