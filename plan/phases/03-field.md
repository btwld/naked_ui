# Phase 03 — Field semantic composition

Authority: **inactive research draft; not approved for implementation**.

Status: **D-08 and D-09 recommendations await explicit approval. If activated
just in time, generic-control composition still has an evidence gate.**

Goal: add a small field scope that gives one primary control one accessible
name, description, required state, validation result, and current error without
duplicating speech. Integrate it first with `NakedTextField`, while preserving
standalone text-field behavior.

Planning baseline: `d341b90` on 2026-07-13. Contract source: briefing
[§17](../briefing.md#17-component-contract-field). Proposed narrowing is
recorded in the approval-pending
[D-08 and D-09 recommendations](../decisions.md#component-plan-research-recommendations-2026-07-13).
Cross-cutting D-19 also requires approval before activation.

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
| Role | The primary child keeps its native role and actions; Field adds no form/button role. |
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

Prefer semantic tree updates and a short-lived status/alert node over explicit
announcement APIs at the minimum SDK. Flutter 3.44.6's newer announcement API is
not available at 3.41, and role plus live-region duplication must be avoided.

## Ordered work

### 1. Freeze the minimal API with failing invariant tests

- **Where:** proposed `packages/naked_ui/lib/src/naked_field.dart` and
  `packages/naked_ui/test/src/naked_field_test.dart`.
- Keep one primary control. Support child-or-builder, label, optional
  description/error, required, enabled, read-only, validation result, error
  announcement policy, and exclusion.
- Exclude touched/dirty and validator callbacks. Normalize empty errors to
  absent. Assert contradictory `valid` + visible error.
- Assert a second registered primary control in debug mode.

### 2. Build a TextField-first scope

- **Where:** `packages/naked_ui/lib/src/naked_field.dart` and
  `packages/naked_ui/lib/src/naked_textfield.dart`.
- Field is the semantic source when present. Identical explicit TextField
  metadata is accepted; conflicting label/hint/error/required/validation data
  asserts in debug. Outside a field, current TextField behavior is unchanged.
- Let the primary control report focus/filled state only when needed by the
  builder. Guard updates during replacement/disposal.
- Label taps request focus only when the control is mounted, enabled, and can
  request focus.

### 3. Prove generic-control composition before exposing it

- Prototype the proposed `NakedFieldControl` around an existing non-text
  control such as `NakedSelect` or `NakedCheckbox`.
- Inspect the widget semantics tree and VoiceOver/TalkBack output. The wrapped
  control must keep its role, value/state, focus, and actions while receiving
  the label/description/error once.
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
- Stable keys: `field.email`, `.label`, `.control`, `.description`, `.error`,
  `.submit`, `.state`, and `.reset`.
- Scenarios: label focus, type, submit invalid, unchanged rebuild, correct and
  clear, disabled vs read-only, localization/RTL, large text, and the generic
  control only if its spike passes.
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

## Acceptance

- [ ] Minimal Field API contains no validation/business-state ownership.
- [ ] Standalone `NakedTextField` remains source- and behavior-compatible.
- [ ] Required, validation, label, description, and error semantics are exact.
- [ ] Error transition policy is deterministic and manually verified.
- [ ] Generic control ships only if role/action preservation passes the spike.
- [ ] Example, integration aggregate, docs, changelog, AT evidence, and status board are current.

## Primary references

- [Flutter `Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Flutter `SemanticsProperties.isRequired`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/isRequired.html)
- [Flutter `SemanticsProperties.validationResult`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/validationResult.html)
- [Flutter `FormField`](https://api.flutter.dev/flutter/widgets/FormField-class.html)
- [WAI Forms: Labels](https://www.w3.org/WAI/tutorials/forms/labels/)
- [WAI Forms: Instructions](https://www.w3.org/WAI/tutorials/forms/instructions/)
- [WAI Forms: Validation](https://www.w3.org/WAI/tutorials/forms/validation/)
