# Phase 06 — Toast controller and viewport MVP

Authority: **inactive, demand-gated research draft; not approved for
implementation**.

Status: **Skip for now. A named Remix use case and explicit D-04–D-07 approval
are required before a just-in-time plan can be activated.**

Goal: provide transient status feedback with one visible toast, a FIFO queue,
safe optional actions, correct live semantics, deterministic auto-dismissal,
and no focus theft. Keep presentation, copy, and product policy in Remix.

Planning baseline: `d341b90` on 2026-07-13. Contract source: briefing
[§16](../briefing.md#16-component-contract-toast). Proposed narrowing is
recorded in the approval-pending
[D-04–D-07 recommendations](../decisions.md#component-plan-research-recommendations-2026-07-13).
Cross-cutting D-19 also requires approval before activation.

## MVP scope

- One visible toast at a time; pending entries are FIFO.
- Structured message, optional safe action, and optional close control.
- Normal (`status`) and urgent (`alert`) priority.
- Timer begins only when visible and pauses for hover, focus within, accessible
  navigation, and inactive/hidden application lifecycle.
- Optional nullable `maxQueued`; overflow is reported with an explicit
  dismissal reason. No silent dropping.
- No swipe dismissal, multi-visible stack, focus hotkey, or reserved global
  shortcut in the first release. A consumer may install its own shortcut.

## Reuse before new machinery

| Need | Reuse | Decision |
|---|---|---|
| App-root overlay | Flutter `OverlayPortal` + `OverlayPortalController` | Use a root-mounted viewport so visible semantics stay attached. |
| Lifecycle | Flutter `AppLifecycleListener` | Pause/resume remaining timer; do not rely on wall-clock sleeps. |
| Focus/hover | Flutter `Focus`/pointer regions | Pause while the user interacts; never request focus on show. |
| Semantics | `SemanticsRole.status` / `SemanticsRole.alert` | One concise message announcement; controls remain separate child nodes. |
| State/controller | `ChangeNotifier` and existing immutable builder-state conventions | Own queue/timers only, not styling or copy. |
| Content-sized nested overlay | Flutter 3.44.6 `Overlay.alwaysSizeToContent` | Reject for Toast: it requires a sizing `OverlayEntry` and does not provide an app-root viewport, queue, semantics, or timer lifecycle. |
| [`shadcn_flutter` ToastLayer](../shadcn-flutter-reference.md#component-findings) | Provides root placement, stacking, hover, and swipe stress cases, but not status/alert semantics, lifecycle/focus pauses, remaining-time accounting, FIFO policy, or dismissal reasons. | Use as test inspiration only; retain the smaller deterministic MVP. |

The stable, beta, and master audit found no raw toast/status controller.
Flutter 3.44.6 improves `OverlayPortal` propagation of target-overlay padding
and view insets, but the minimum remains 3.41, so the viewport must explicitly
prove safe-area/keyboard behavior on both versions. `alwaysSizeToContent` is
not a substitute for that viewport. See the shared
[raw-primitives mapping](../flutter-raw-primitives.md#component-by-component-result).

## Semantics and interaction contract

| Question | Required answer |
|---|---|
| Role | Normal message: status. Urgent time-sensitive message: alert. |
| Name | One concise caller-provided announcement string. Visual rich content cannot create a second copy. |
| Controls | Optional action and close are distinct named controls with their native button actions. |
| Focus on show | Never stolen. Existing page focus remains where it was. |
| Focus interaction | If the user tabs/clicks into action/close, timer pauses; dismissal restores normal traversal without forcing an old focus target. |
| Timing | Starts when entry becomes visible; exact remaining duration survives every pause/resume. |
| Accessible navigation | Auto-dismiss remains paused while enabled. |
| Queue | One visible FIFO; every removal reports one reason. |
| Urgency | Do not pair role and a duplicate `liveRegion`/explicit announcement for the same message. |

A toast action must be safe to miss. Work that requires a response belongs in
Alert Dialog, not Toast.

## Ordered work

### 1. Confirm demand and freeze the reduced contract

- Record at least one Remix screen and event needing transient feedback, its
  message priority, whether it has an action, and why inline status/callout is
  insufficient.
- If no use case exists, stop here with this plan; do not introduce a global
  controller speculatively.
- Review the entry/controller/viewport naming, dismissal reasons, duration
  ownership, and nullable `maxQueued`. Do not expose stacking/swipe APIs that
  the MVP will not implement.

### 2. Build pure queue and timer state test-first

- **Where:** proposed `packages/naked_ui/lib/src/naked_toast.dart` and
  `packages/naked_ui/test/src/naked_toast_test.dart`.
- Cover FIFO promotion, unique handles, programmatic/item/action/timeout/
  overflow reasons, exactly-once completion/callback, cap changes, clear,
  disposal, and reentrant callbacks.
- Drive time with fake frame time. Assert just-before and exact-boundary
  dismissal; nested pause reasons; resume with remaining duration; duration
  update policy; entry replacement; and no timer for pending entries.

### 3. Build one root viewport with structured composition

- Use `OverlayPortal` mounted under the app/root overlay, not under a scrolled
  list item whose semantics can be dropped while the overlay remains visible.
- Provide structured message/action/close slots or helpers so the viewport can
  exclude duplicate message semantics without hiding either control. Do not
  parse arbitrary descendants to guess their purpose.
- Respect safe area, view padding/insets, RTL, large text, and
  `MediaQuery.disableAnimations`; behavior timing must not depend on a visual
  transition completing.

### 4. Implement pause and lifecycle ownership

- Hover and focus-within add/remove independent pause tokens. Accessible
  navigation and `AppLifecycleListener` do the same; the timer resumes only
  when no reason remains.
- Handle app hide/pause/inactive, resume/show, viewport unmount/remount,
  controller disposal, and entry dismissal while paused without leaking
  timers/listeners/focus nodes.
- Keep any focus-access shortcut outside the component. The example may wire
  F8 to a caller action but docs must label it optional.

### 5. Prove announcement and focus behavior

- **Where:** proposed
  `packages/naked_ui/test/semantics/naked_toast_semantics_test.dart`.
- Test one status/alert node, one message, named action/close, no duplicate
  live region, no focus request, pause on focus, removal while focused, and
  back-to-back queued announcements once each.
- Manually test VoiceOver, TalkBack, and Chrome accessibility tree with normal,
  urgent, action, timeout, and queue promotion cases. Record interruption and
  duplicate-speech results, not just the static tree.

### 6. Add deterministic fixture and integration proof

- **Where:** proposed `packages/example/lib/api/naked_toast.0.dart`, registry,
  `packages/example/integration_test/components/naked_toast_integration.dart`,
  aggregate runner, `docs/widget/toast.mdx`, and changelog.
- Stable keys: `toast.show.normal`, `.show.urgent`, `.show.action`, `.viewport`,
  `.message`, `.action`, `.close`, `.queue-count`, `.last-reason`, and `.reset`.
- Prove show without focus steal, FIFO promotion, action/close, exact timeout,
  hover/focus pause, lifecycle pause, accessible navigation, overflow reason,
  large text, RTL, and soft-keyboard inset.
- Use exact pumps/bounded observable waits; never `pumpAndSettle()` while a
  toast timer is active.

## Planned visual evidence

- Screenshots: `toast__normal_action__macos__reference.png`,
  `toast__urgent_large_text__android__reference.png`, and
  `toast__keyboard_inset__macos__reference.png`.
- Golden: `packages/example/test/goldens/components/baselines/naked_toast__action.png`.
- Timer and announcement evidence is captured independently from the static
  image so a good screenshot cannot hide a lifecycle failure.

## Version and verification matrix

Run queue/controller logic on 3.41.0, 3.41.2, and 3.44.6. Run viewport inset,
semantics attachment, focus, and keyboard tests on 3.41.2 and 3.44.6 plus the
real target matrix. Use the exact install/spawn commands in the
[shared SDK matrix](../process.md#executable-sdk-and-local-command-matrix);
the commands below are the workspace slice.

```sh
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test packages/naked_ui/test/src/naked_toast_test.dart
fvm flutter test packages/naked_ui/test/semantics/naked_toast_semantics_test.dart
fvm flutter test packages/naked_ui/test
fvm flutter test packages/example/test
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/components/naked_toast_integration.dart
fvm flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```

## Stop conditions

Block the component if the visible portal loses its semantics when the source
scrolls, a message announces twice or not at all, showing steals focus, a
timer advances while any pause reason is active, queue removal lacks a reason,
or safe-area/keyboard behavior cannot be made truthful at the 3.41 floor.

## Acceptance

- [ ] A concrete Remix use case justifies transient rather than inline/modal feedback.
- [ ] One-visible FIFO and optional explicit cap have exactly-once dismissal reasons.
- [ ] Structured message/action/close produce one announcement and usable controls.
- [ ] Timers pass boundary, nested pause, lifecycle, accessibility, and disposal tests.
- [ ] Viewport semantics and insets pass 3.41/3.44.6 and real-platform proof.
- [ ] Swipe, stacking, and global shortcut remain deferred and undocumented as shipped features.
- [ ] Example, aggregate, docs, changelog, AT evidence, and status board are current.

## Primary references

- [Flutter `OverlayPortal`](https://api.flutter.dev/flutter/widgets/OverlayPortal-class.html)
- [Flutter `Overlay.alwaysSizeToContent`](https://api.flutter.dev/flutter/widgets/Overlay/alwaysSizeToContent.html)
- [Flutter `AppLifecycleListener`](https://api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html)
- [Flutter `SemanticsRole`](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html)
- [WCAG 2.2: Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages)
