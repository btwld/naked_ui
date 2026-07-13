# Phase 01 — Alert Dialog completion

Status: **Implementation open in [PR #64](https://github.com/btwld/naked_ui/pull/64); completion evidence required.**

Goal: finish the alert-dialog specialization of `NakedDialog` with a small,
correct modal contract: an urgent dialog role, an explicit accessible name,
safe initial focus, contained traversal, predictable dismissal, and focus
restoration. Preserve all existing dialog behavior and styling freedom.

Planning baseline: workspace `d341b90`; reviewed PR head `409ec27` on
2026-07-13. Contract source: briefing
[§13](../briefing.md#13-component-contract-alert-dialog), with the explicit
delta below. Decisions:
[D-02](../decisions.md#phase-1-decision-evidence-2026-07-12) and approved
[D-19](../decisions.md#architecture-decision-evidence-approved-2026-07-13).

## Contract correction

The frozen briefing's proposal that Escape must not close an alert dialog is
superseded. Escape and platform Back close the modal through the route and
return `null`; outside-barrier taps remain disabled by default. This follows
the WAI-ARIA modal dialog pattern and keeps an urgent dialog distinguishable
from an inescapable workflow. A product that cannot safely cancel must prevent
entry or preserve work; Naked UI must not trap the user in the route.

## Scope

Ship `showNakedAlertDialog<T>` as a focused extension of the existing dialog
route. Do not add alert copy, action ordering, destructive-action styling, a
new dialog controller, or validation/business rules.

## Reuse before new machinery

| Need | Reuse | Decision |
|---|---|---|
| Route, barrier, animation, restoration | `showNakedDialog` / `RawDialogRoute` in `packages/naked_ui/lib/src/naked_dialog.dart` | Extend; do not create a second overlay stack. |
| Modal semantics | Existing dialog `BlockSemantics`/route semantics plus `SemanticsRole.alertDialog` | Add the narrower role and required name. |
| Focus containment | Existing `FocusTraversalGroup` route behavior | Retain closed-loop traversal and restoration. |
| Initial focus | Caller-owned `FocusNode`, otherwise first traversable descendant | Implement D-02; never create ownership ambiguity. |
| Newer dialog helper | Flutter 3.44.6 `showRawDialog` | Watch only; it is absent at the floor and experimental windowing can remove the barrier and ignore the custom route. |
| [`shadcn_flutter` DialogRoute/AlertDialog](../shadcn-flutter-reference.md#component-findings) | Confirms `RawDialogRoute`, safe area, context capture, and closed-loop traversal; its styled alert lacks this plan's explicit role/name contract and uses a default English barrier label. | Behavior reference only; reuse no package code or localization policy. |

`showRawDialog` is publicly exported in 3.44.6, but with experimental native
windowing it can create a true window without a modal barrier and silently
ignore `routeBuilder`. Private dialog/window controllers under
`package:flutter/src` are not supported APIs. Keep `RawDialogRoute` as the
cross-floor foundation; reconsider only after a deliberate SDK-floor change
and real window modal/focus/semantics proof. See the shared
[raw-primitives watchlist](../flutter-raw-primitives.md#showrawdialog).

## Semantics and interaction contract

| Question | Required answer |
|---|---|
| Role | One exposed container with `SemanticsRole.alertDialog`. |
| Name | Non-empty caller-supplied `semanticLabel`; reject an empty value in every build mode. |
| Value/state | No synthetic value; title, description, and controls remain traversable descendants. |
| Actions | Child actions only. The container does not masquerade as a button. |
| Focus on open | Valid `initialFocusNode`; otherwise normal first-focus behavior. Canonical destructive flows choose the least destructive action. |
| Focus while open | Traversal is contained. Disabled controls are skipped. |
| Close | Action, Escape, platform Back, or route removal; outside tap is inert by default. |
| Focus after close | Restore the previously focused trigger when it still exists and can request focus. |
| Disabled model | Not applicable to the route; individual actions own their enabled state. |
| Announcement | The role/name and newly focused content provide the announcement; do not issue a duplicate explicit announcement. |

## Ordered work

### 1. Rebase and isolate the component PR

- **Where:** PR #64 against `main`; shared workflow/example files touched by
  later component branches.
- Rebase onto current `main` (Phase 0 is already merged), retaining only Alert
  Dialog code, tests, example, docs, and required registry/integration entries.
- Confirm no unrelated planning corpus or Link changes remain in the diff.
- **Verify:** `git diff --stat origin/main...HEAD` and the PR Files tab describe
  one behavior contract.

### 2. Lock route and API invariants with tests

- **Where:** `packages/naked_ui/test/src/naked_dialog_test.dart` and
  `packages/naked_ui/test/semantics/naked_dialog_semantics_test.dart`.
- Cover builder context, generic result, non-empty label, barrier default,
  custom barrier opt-in, caller node ownership, invalid-node fallback, and
  route disposal.
- Prove Escape and Back return `null` even when outside tapping is disabled.
- First run each new test against the pre-feature baseline and record the
  intended failure in the PR.

### 3. Review the implementation against the raw route

- **Where:** `packages/naked_ui/lib/src/naked_dialog.dart` and export barrel
  `packages/naked_ui/lib/src/naked_widgets.dart`.
- Keep the specialization as a wrapper over the existing raw route. Avoid a
  parallel focus scope, overlay entry, or controller.
- Do not route through 3.44.6-only `showRawDialog`; the Alert contract requires
  the custom route and modal barrier on every supported target.
- Request initial focus after descendants are attached, guard unmounted/closed
  routes, and never dispose the caller's node.
- Ensure every close path is idempotent and focus restoration happens once.

### 4. Make the example prove safe defaults

- **Where:** `packages/example/lib/api/naked_dialog.0.dart` or a focused
  `naked_alert_dialog.0.dart`, plus `packages/example/lib/registry.dart`.
- Add stable keys for trigger, route, cancel, confirm, and state readout.
- Include acknowledgement and destructive variants; the latter initially
  focuses Cancel. Include large text and a scrollable-content case without
  encoding product copy in the package.

### 5. Complete real-platform proof

- **Where:** `packages/example/integration_test/components/naked_dialog_integration.dart`
  and `packages/example/integration_test/all_tests.dart`.
- Prove trigger focus → open → safe initial target → contained Tab/Shift+Tab →
  Escape close → trigger restoration; repeat with platform Back on Android and
  outside-tap refusal.
- Record VoiceOver (macOS/iOS), TalkBack (Android), and Chrome accessibility
  tree results: one alert-dialog node, correct name, readable descendants, no
  duplicate announcement, and restored focus.

### 6. Finish documentation and handoff

- **Where:** `docs/widget/dialog.mdx`, `CHANGELOG.md`, PR traceability/evidence.
- Document the difference between Dialog and Alert Dialog, safe initial-focus
  guidance, Escape/Back behavior, outside-tap default, node ownership, and the
  absence of action-ordering policy.
- Call out the briefing correction in the changelog/PR so it is reviewable.

## Planned visual evidence

- Screenshots: `alert_dialog__destructive_safe_focus__macos__reference.png`,
  `alert_dialog__long_text_200__android__reference.png`, and
  `alert_dialog__rtl__macos__reference.png`.
- Golden: `packages/example/test/goldens/components/baselines/naked_alert_dialog__destructive.png`
  with a focused test next to the existing component golden tests.
- Chrome supplies behavior/accessibility-tree evidence while Flutter 3.41 web
  screenshot capture remains explicitly unsupported.

## Verification

Run the workspace commands below plus every applicable exact-SDK command in
the [shared SDK matrix](../process.md#executable-sdk-and-local-command-matrix).

```sh
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test packages/naked_ui/test/src/naked_dialog_test.dart
fvm flutter test packages/naked_ui/test/semantics/naked_dialog_semantics_test.dart
fvm flutter test packages/naked_ui/test
fvm flutter test packages/example/test
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/components/naked_dialog_integration.dart
fvm flutter test -r compact -d flutter-tester integration_test/all_tests.dart
fvm flutter test -r compact -d macos integration_test/all_tests.dart
```

Hosted Android and pinned-Chrome jobs remain blocking per
[integration-testing.md](../integration-testing.md). Run release iOS evidence
before claiming iOS support; macOS VoiceOver is not a substitute.

## Stop conditions

Block this component if a supported screen reader fails to identify the route
as an alert dialog, focus escapes or is not restored on any standard close
path, Escape/Back cannot close without weakening modal behavior, or initial
focus requires Naked UI to own a caller node.

## Acceptance

- [ ] PR #64 contains only the Alert Dialog contract and is rebased on current `main`.
- [ ] Role, name, descendants, initial focus, loop, every close path, and restoration are tested.
- [ ] Outside tap is disabled by default; Escape and platform Back close safely.
- [ ] The required current-stable compatibility gate passes without using
      post-minimum production APIs.
- [ ] VoiceOver, TalkBack, Chrome tree, and release iOS evidence is attached.
- [ ] Example, docs, changelog, traceability table, and status board are current.

## Primary references

- [Flutter `RawDialogRoute`](https://api.flutter.dev/flutter/widgets/RawDialogRoute-class.html)
- [Flutter `showRawDialog`](https://api.flutter.dev/flutter/widgets/showRawDialog.html)
- [Flutter `SemanticsRole.alertDialog`](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html)
- [WAI-ARIA Alert Dialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/)
- [WAI-ARIA Modal Dialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
