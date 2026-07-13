# Phase 07 — Hover Card preview

Authority: **inactive, dependency/demand-gated research draft; not approved for
implementation**.

Status: **Skip for now. Link must land, Remix must supply a valid
noninteractive preview use case, and D-17 must be explicitly approved before a
just-in-time spike/plan is activated.**

Goal: show a noninteractive, supplementary preview from hover or keyboard
focus, keep it visible while the pointer crosses into it, dismiss it with
Escape, and never make essential information available only through hover.

Planning baseline: `d341b90` on 2026-07-13. Contract source: briefing
[§19](../briefing.md#19-component-contract-hover-card--preview-card). Proposed
refinement is recorded in the approval-pending
[D-17 recommendation](../decisions.md#component-plan-research-recommendations-2026-07-13).
Cross-cutting D-19 also requires approval before activation.

## Scope

The first release is a preview, not a second popover:

- trigger is normally a `NakedLink` or another already meaningful control;
- preview contains no focusable/interactive children;
- all essential information and actions remain available on the destination
  or in normal page content;
- mouse hover and keyboard focus open it after a delay; leaving both trigger
  and card closes it after pointer grace; Escape closes immediately;
- touch has no hidden long-press-only contract in the MVP.

Use `NakedPopover` when content is interactive. Use `NakedTooltip` for a short
text label. Do not make Hover Card absorb either component's job.

## Reuse before new machinery

| Candidate | Finding | Decision |
|---|---|---|
| `RawTooltip` | Already handles delays/hover persistence and is a useful behavior reference. 3.44.6 adds `ignorePointer` (default `false`), but the 3.41 floor still has no per-instance public hide and neither version owns Hover Card focus/Escape behavior. | Do not use as the final base unless the spike proves a clean per-instance close path without global dismissal; do not reference the 3.44-only property at the floor. |
| `RawMenuAnchor` + `MenuController` | Per-instance open/close, anchor information, overlay lifecycle, and collision plumbing. | Preferred raw base; use without menu roles or menu focus behavior. |
| Existing `AnchoredOverlayShell` | Reusable positioner and lifecycle, but currently includes menu-oriented focus/shortcuts. | Extract or parameterize only the generic behavior; do not give a preview menu semantics. |
| Private `TooltipWindow`/`PopupWindow` | Experimental native-window implementations under `package:flutter/src` | Reject; wait for a documented public export and cross-platform fallback. |
| [`shadcn_flutter` HoverCard](../shadcn-flutter-reference.md#component-findings) | Demonstrates delayed trigger/card hover persistence, but uses counter-based delays, long press, and arbitrary content without focus/Escape/semantic/noninteractive guarantees. | Reuse the persistence scenario only, not its controller/timer contract. |

No new standalone overlay engine should be created. Any shared shell change
must keep Menu, Select, Popover, Context Menu, and Tooltip regression suites
green. The master `RawMenuAnchor` close-while-closed change also makes
idempotent close handling a forward-compatibility requirement. See the shared
[raw-primitives watchlist](../flutter-raw-primitives.md#beta-and-master-watchlist).

## Semantics and interaction contract

| Question | Required answer |
|---|---|
| Trigger | Keeps its original role, name, destination, action, and focus behavior. |
| Preview role | No interactive/dialog/menu role. Decorative duplicate preview content is excluded from semantics. |
| Accessible content | Any meaningful preview facts are also present in the link name/description or destination; hover is never the sole path. |
| Open | Delayed pointer hover or keyboard focus. No focus transfer. |
| Persistent | Stays open while trigger or card is hovered, or trigger retains focus. |
| Close | Escape immediately; otherwise after leaving both regions and pointer-grace timeout. |
| Pointer crossing | A diagonal movement through the trigger/card corridor does not flicker closed. |
| Disabled | No open timer or overlay; trigger retains its own correct disabled behavior. |

This implements WCAG's dismissible, hoverable, and persistent content rule
without claiming that a visual preview is a screen-reader interaction surface.

## Ordered work

### 1. Confirm a valid Remix preview story

- Name the trigger, preview facts, destination, and why Tooltip/Popover/inline
  content is not the better primitive.
- Prove every meaningful fact and action is still available without hover.
- If the preview would contain buttons, links, selection, or essential status,
  stop and use Popover/normal content. If no concrete story remains, defer the
  component.

### 2. Spike raw overlay and pointer grace

- Prototype `RawTooltip` and `RawMenuAnchor` against the same trigger/card
  fixture on 3.41.2 and 3.44.6. Required operations: delayed show,
  per-instance immediate Escape close, focus open/close, pointer entry into the
  card, edge collision, and disposal.
- Run the raw-menu master close-request canary after the stable comparison;
  keep it non-blocking and use it to verify exactly-once close completion.
- Choose the smallest approach that owns each instance independently. Record
  D-17's final implementation evidence; do not call global tooltip dismissal
  to close one card.
- Implement pointer-grace geometry as a pure tested function (trigger rect,
  card rect, latest points, direction, timeout), independent of styling.

### 3. Lock timing and state tests before the widget

- **Where:** proposed `packages/naked_ui/test/src/naked_hover_card_test.dart`.
- Test just-before/exact open delay, close delay, re-entry cancellation,
  diagonal corridor, rapid trigger-to-trigger movement, focus+hover overlap,
  Escape, route change, scroll/reposition, disabled state, controller/trigger
  replacement, reduced motion, and disposal with pending timers.
- Timers use fake frame time and independent pause/open reasons. Never use
  `pumpAndSettle()` while a delay is pending.

### 4. Implement noninteractive composition

- **Where:** proposed `packages/naked_ui/lib/src/naked_hover_card.dart` plus the
  smallest reviewed generic overlay utility change.
- Preserve child semantics/actions. Exclude preview duplicates from semantics
  and debug-assert detectable focusable descendants where practical; document
  that runtime semantic inspection cannot enforce every interactive widget.
- Expose open/hover/focus state and injectable durations to the builder, not
  card styling or product copy.
- Make close idempotent and ensure Escape is handled only while this card is
  open, leaving the focused trigger in place.

### 5. Prove screen-reader and keyboard boundaries

- **Where:** proposed
  `packages/naked_ui/test/semantics/naked_hover_card_semantics_test.dart`.
- Assert the trigger remains one Link/control node and preview opening adds no
  duplicate link/name or menu/dialog role.
- Manually check VoiceOver, TalkBack, and Chrome: focusing the trigger remains
  understandable without entering the preview, Escape closes visually, and
  normal activation/navigation is unchanged.

### 6. Add fixture, integration, and docs

- **Where:** proposed `packages/example/lib/api/naked_hover_card.0.dart`,
  registry, `packages/example/integration_test/components/naked_hover_card_integration.dart`,
  aggregate runner, `docs/widget/hover-card.mdx`, and changelog.
- Stable keys: `hover-card.trigger`, `.card`, `.state`, `.edge-trigger`, and
  `.reset`.
- Scenarios: delayed mouse open, diagonal crossing, persistent card hover,
  delayed close, keyboard-focus open/Escape, activate Link, viewport edge,
  200% text, RTL, and rapid disposal.
- Docs include the Tooltip vs Hover Card vs Popover decision table and the
  prohibition on essential/interactive preview content.

## Planned visual evidence

- Screenshots: `hover_card__pointer_corridor__macos__reference.png` and
  `hover_card__edge_200__macos__reference.png`.
- Golden: `packages/example/test/goldens/components/baselines/naked_hover_card__open.png`.
- Pointer traces/timing assertions and AT notes accompany the images; the open
  image alone does not prove hover persistence or Escape.

## Verification

Run the workspace commands below plus the exact 3.41.0 and 3.44.6 commands in
the [shared SDK matrix](../process.md#executable-sdk-and-local-command-matrix).

```sh
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test packages/naked_ui/test/src/naked_hover_card_test.dart
fvm flutter test packages/naked_ui/test/semantics/naked_hover_card_semantics_test.dart
fvm flutter test packages/naked_ui/test/src/naked_tooltip_test.dart
fvm flutter test packages/naked_ui/test/src/naked_popover_test.dart
fvm flutter test packages/naked_ui/test/src/naked_menu_test.dart
fvm flutter test packages/naked_ui/test
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/components/naked_hover_card_integration.dart
fvm flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```

## Stop conditions

Defer if no concrete noninteractive preview remains after the content audit.
Block if Escape can only be implemented with global dismissal, the pointer
corridor flickers under deterministic input, preview content becomes an AT-only
dead end or a duplicate announcement, focus moves into the card, or shared
overlay changes regress an existing component.

## Acceptance

- [ ] Link has landed and a concrete noninteractive Remix preview is recorded.
- [ ] Raw primitive choice has 3.41/3.44.6 evidence and per-instance dismissal.
- [ ] Preview is dismissible, hoverable, persistent, and nonessential.
- [ ] Trigger semantics/navigation remain unchanged and preview has no interactive descendants.
- [ ] Timing, pointer grace, edge geometry, Escape, and disposal are deterministic.
- [ ] Example, aggregate, docs, changelog, platform/AT evidence, and status board are current.

## Primary references

- [Flutter `RawTooltip`](https://api.flutter.dev/flutter/widgets/RawTooltip-class.html)
- [Flutter `RawMenuAnchor`](https://api.flutter.dev/flutter/widgets/RawMenuAnchor-class.html)
- [WCAG 2.2: Content on Hover or Focus](https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html)
