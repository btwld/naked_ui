# Phase 03 — Field semantic composition

Authority: **active just-in-time implementation contract for the TextField-first
slice**.

Status: **activated after a clean `origin/main` preflight at `58a48a3` on
2026-07-13 and refreshed onto `936b171`. D-08, D-09, and D-19 are approved.
Production `NakedField` plus `NakedTextField` integration is review-ready on
PR #67; generic-control composition remains unexported and deferred behind its
separate evidence gate.**

Goal: add a small field scope that gives one primary control one accessible
name, description, required state, validation result, and current error without
duplicating speech. Integrate it first with `NakedTextField`, while preserving
standalone source and interaction behavior except for D-09's approved
initial-error announcement correction.

Implementation baseline: `936b171` on 2026-07-13. Contract source: briefing
[§17](../briefing.md#17-component-contract-field). The approved narrowing and
cross-cutting release policy are recorded in
[D-08, D-09, and D-19](../decisions.md#architecture-decision-evidence-approved-2026-07-13).

## Scope correction

The first release does not own `touched`, `dirty`, validation execution, or
Flutter `FormField` state. Those are application/form-library policies, not
headless field semantics. Add them later only for a demonstrated cross-control
behavior requirement. The MVP accepts controlled label, description, error,
required, enabled/read-only, and `SemanticsValidationResult` values.

## Reuse before new machinery

| Need | Reuse | Decision |
|---|---|---|
| Editable control | Existing `NakedTextField` / Flutter `EditableText` | Integrate through scope; do not wrap another text field. |
| Required/validity state | Flutter `Semantics.isRequired` and `validationResult` | Use directly; available at the 3.41 floor. |
| Focus activation | Caller/control `FocusNode` | Label requests focus; Field never owns or disposes it. |
| Form validation | Flutter `FormField` and consumer libraries | Compose outside Field; do not duplicate validators or error lifecycle. |
| State exposure | Existing immutable `NakedState`/scope conventions | Expose only behavior needed to render the field. |
| [`shadcn_flutter` `FormField`](../shadcn-flutter-reference.md#component-findings) | Visually composes label/hint/error and owns validation timing, but does not provide this plan's semantic association contract. | Use its slots as fixture ideas only; do not copy validation ownership. |

Flutter 3.44.6 exposes `FormState.fields`, `FormState.clearError`, and
`FormFieldState.clearError`, but relying on them would break the 3.41 minimum
and would incorrectly make Field a validation owner. They are explicitly
rejected, not missing work; see the shared
[raw-primitives mapping](../flutter-raw-primitives.md#component-by-component-result).

## Semantics contract

| Question | Required answer |
|---|---|
| Role | Apply Field metadata to the actual text-field semantics node; the primary child keeps its native role and actions, and Field adds no form/button role or generic replacement for `EditableText`. |
| Name | Visible label becomes the control name exactly once. |
| Description | Included once as the control hint/description in stable order. |
| Error | Current error remains discoverable from the control; a changed non-empty error is announced once. |
| Required | `isRequired` reflects the controlled field value. |
| Validation | `validationResult` is controlled; error + `valid` is a debug conflict. |
| Disabled/read-only | Effective state is the stricter field/control state; read-only remains focusable/readable but not editable. |
| Actions | Only the child's valid actions plus label-to-focus activation. |
| Visual helper nodes | Label/description/error are not separately spoken when that would duplicate associated control text. |
| Initial error | Discoverable but not assertively announced on first build. |
| Later error | A new non-empty value announces once; unchanged rebuilds do not; clear/re-add counts as a new transition. |

Prefer implicit semantic-tree updates over explicit announcement APIs.
`SemanticsService.sendAnnouncement` exists at the 3.41 floor, but Flutter's own
contract prefers implicit semantics and warns that explicit announcements can
disrupt Android output. Use one transient role-based announcement path only;
never combine an alert/status role with `liveRegion` for the same message. Its
bounded lifetime must survive a completed semantics update and be verified by
transition tests plus VoiceOver/TalkBack evidence rather than assumed to be a
particular frame count.

D-09 intentionally changes existing `NakedTextField` behavior: today every
displayed semantic error, including an initial error, marks the merged text
field as a live region. Standalone and Field-integrated `NakedTextField` must
keep the initial error discoverable without that initial live announcement.
Record the behavior change in the changelog and verify the transition timing
manually with VoiceOver and TalkBack.

## Ordered work

### 1. Freeze the minimal API with failing invariant tests

- **Where:** proposed `packages/naked_ui/lib/src/naked_field.dart` and
  `packages/naked_ui/test/src/naked_field_test.dart`.
- Keep one primary control. Public scope is `NakedField`, immutable
  `NakedFieldState`, `NakedFieldErrorAnnouncement`, and the label/description/
  error visual helpers. Support child-or-builder, label, optional description/
  error, required, enabled, read-only, validation result, error announcement
  policy, and exclusion. `NakedTextField` may add nullable `isRequired` and
  `validationResult` metadata for standalone use and migration.
- Exclude touched/dirty and validator callbacks. Normalize only null/empty
  errors to absent; do not trim or rewrite non-empty localized content. Assert
  contradictory `valid` + visible error.
- Assert a second registered primary control in debug mode.

### 2. Build a TextField-first scope

- **Where:** `packages/naked_ui/lib/src/naked_field.dart` and
  `packages/naked_ui/lib/src/naked_textfield.dart`.
- Field is the semantic source when present. Identical explicit TextField
  metadata is accepted; conflicting label/hint/error/required/validation data
  asserts in debug. If assertions are disabled, the Field value
  deterministically wins. D-09's initial-error live-region correction applies
  to standalone and Field-integrated `NakedTextField`; other standalone source
  and interaction behavior remains unchanged.
- Resolve label, description, error, required, and validation independently;
  do not compare a composed hint with one raw metadata field. For this
  TextField-first slice, `NakedTextField` owns the single effective error
  transition/announcement path in both standalone and Field-integrated use;
  Field supplies policy and metadata but must not create a second announcer.
- Let the primary control report focus/filled state only when needed by the
  builder. Guard updates during replacement/disposal.
- Label taps request focus only when the control is mounted, enabled, and can
  request focus.

### 3. Record generic-control composition as a deferred follow-up

- Do not export or implement a production `NakedFieldControl` in this slice.
  A later disposable prototype may wrap an existing non-text control such as
  `NakedSelect` or `NakedCheckbox`.
- Do not run that prototype as part of this active implementation. When it is
  separately authorized, inspect the widget semantics tree and
  VoiceOver/TalkBack output; the wrapped control must keep its role,
  value/state, focus, and actions while receiving the metadata once.
- Flutter has no general public `labelledBy` relation across arbitrary
  semantics nodes. If merging/replacement loses the child role or duplicates
  speech, do not publish `NakedFieldControl` in this release. Ship the proven
  TextField integration and record generic controls as blocked follow-up.

### 4. Implement deterministic error transitions

- Track normalized previous error only while mounted. Initial content is not
  assertive; a different non-empty error creates one transient announcement
  node; unrelated rebuilds create none; clear then re-add may announce again.
- Do not combine `SemanticsRole.alert` with another `liveRegion` path for the
  same text. Cancel pending state on disposal.
- Test localization changes separately from error transitions so translated
  content has an explicit, documented announcement result.

### 5. Add semantics, compatibility, and composition tests

- **Where:** proposed
  `packages/naked_ui/test/semantics/naked_field_semantics_test.dart`, existing
  `naked_textfield_test.dart`, and `naked_textfield_semantics_test.dart`.
- Cover name/description/error exactly once, required true/false, validation
  none/valid/invalid, effective disabled/read-only, label focus, field
  replacement, initial/changed/unchanged/cleared errors, exclusion, and
  standalone regression.
- Use node/action assertions, not concatenated debug strings alone.

### 6. Add the canonical form fixture and evidence

- **Where:** proposed `packages/example/lib/api/naked_field.0.dart`, registry,
  `packages/example/integration_test/components/naked_field_integration.dart`,
  aggregate runner, `docs/widget/field.mdx`, and changelog.
- The changelog must explicitly name the intentional initial-error live-region
  correction rather than presenting Field integration as semantics-neutral.
- Stable keys: `field.email`, `.label`, `.control`, `.description`, `.error`,
  `.submit`, `.state`, and `.reset`.
- Scenarios: label focus, type, submit invalid, unchanged rebuild, correct and
  clear, disabled vs read-only, localization/RTL, and large text.
- Record VoiceOver, TalkBack, and Chrome tree output for required/invalid and
  error-transition timing.

## Planned visual evidence

- Screenshots: `field__required_invalid__macos__reference.png`,
  `field__disabled_readonly_200__android__reference.png`, and
  `field__rtl__macos__reference.png`.
- Golden: `packages/example/test/goldens/components/baselines/naked_field__invalid.png`.
- Announcement timing is evidenced by AT notes/logs, not inferred from the
  screenshot.

## Version and verification proof

Run the full feature suite on exact Flutter 3.41.0 and workspace 3.41.2. Add a
3.44.6 compatibility run before closure because Remix consumes 3.44, but keep
the production code on APIs available at the declared minimum. Use the
[shared SDK matrix](../process.md#executable-sdk-and-local-command-matrix) for
those exact-version gates; the commands below are the workspace slice.

```sh
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test packages/naked_ui/test/src/naked_field_test.dart
fvm flutter test packages/naked_ui/test/semantics/naked_field_semantics_test.dart
fvm flutter test packages/naked_ui/test/src/naked_textfield_test.dart
fvm flutter test packages/naked_ui/test/semantics/naked_textfield_semantics_test.dart
fvm flutter test packages/naked_ui/test
fvm flutter test packages/example/test
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/components/naked_field_integration.dart
fvm flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```

## Stop conditions

Block the generic wrapper if it changes a child's role/actions or produces
duplicate speech. Block the whole phase if TextField cannot receive one stable
name/description/error, validation changes announce more than once, initial
errors unexpectedly interrupt users, or the result requires post-3.41 APIs
without raising the package floor deliberately.

## Execution evidence (2026-07-13)

- [PR #67](https://github.com/btwld/naked_ui/pull/67) implements the approved
  TextField-first contract at `c1a8073`; generic control composition remains
  unexported and no validator, touched/dirty, or submission ownership was added.
- Flutter 3.41.0, 3.41.2, and 3.44.6 each pass the full package matrix (633
  tests with 3 documented skips). Focused semantics pass 11 tests, focused
  Field integration passes 5, and the aggregate passes 98 with 1 documented
  Tooltip skip. Format and fatal-info analysis are clean.
- Completed-semantics-update history proves initial errors are not alerts,
  changed non-empty errors are introduced once, unchanged rebuilds do not
  repeat, and clear/re-add is one new transition. The changelog records D-09.
- The pinned Ubuntu invalid-state golden was reviewed and committed at SHA-256
  `259aa87e0a010bc00d8cbaa8dfafa71581f6a675bc9420a8ae3dba24f36f7b35`.
  Exact-head required-invalid (`b502e06c…af720`), Arabic RTL
  (`78e1bd9d…c5e3d`), and Android 200% disabled/read-only
  (`247dc12b…d78c8d50`) captures were visually reviewed. The RTL fixture scopes
  English explanatory copy LTR while retaining Arabic Field/control metadata
  as RTL.
- All seven exact-head hosted checks pass: minimum Flutter, primary tests,
  flutter-tester, real macOS, pinned web, Android API 34, and PR-title policy.
  VoiceOver, TalkBack, headed Chrome accessibility-tree, and release-level iOS
  sessions remain unrun and are not inferred from automated semantics.

## Acceptance

- [x] Minimal Field API contains no validation/business-state ownership.
- [x] Standalone `NakedTextField` remains source- and interaction-compatible
      except for the documented D-09 semantics correction.
- [x] Required, validation, label, description, and error semantics are exact.
- [x] Error transition policy is deterministic in completed-update tests; the
      changelog names the initial-error behavior correction.
- [ ] Error transition policy is manually verified with VoiceOver and TalkBack.
- [x] Generic control remains unexported and explicitly deferred.
- [ ] Example, integration aggregate, docs, changelog, AT evidence, and status board are current.

## Primary references

- [Flutter `Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Flutter `SemanticsProperties.isRequired`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/isRequired.html)
- [Flutter `SemanticsProperties.validationResult`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/validationResult.html)
- [Flutter `FormField`](https://api.flutter.dev/flutter/widgets/FormField-class.html)
- [WAI Forms: Labels](https://www.w3.org/WAI/tutorials/forms/labels/)
- [WAI Forms: Instructions](https://www.w3.org/WAI/tutorials/forms/instructions/)
- [WAI Forms: Validation](https://www.w3.org/WAI/tutorials/forms/validation/)
