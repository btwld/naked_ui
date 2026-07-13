# Context Menu accessibility spike — D-03 evidence

Status: **D-03 OPEN; production Context Menu API NOT AUTHORIZED**
Spike date: 2026-07-13
Fixture: `packages/example/lib/context_menu_accessibility_spike.dart`
Baseline: Link PR #65 head `8084ecf`, Flutter 3.41.2 workspace pin

This is a disposable V0/V1 evidence record. Automated semantics can establish
tree shape, actions, behavior, focus, and geometry. It cannot establish spoken
output, discoverability, or usability with assistive technology.

## Automated findings

| Surface | V0 | V1 | Result |
|---|---|---|---|
| NakedLink | One labeled Link node with tap; no long-press action | Same node/role/label/native actions plus one long-press action | Automated contract passes for this child only |
| SelectableText | One native text-field node with its own long-press action | Native node remains, plus a second unlabeled/valueless role-neutral long-press node | **V1 contract failure: duplicate long-press action and unlabeled action node** |
| Generic focusable row | Labeled row node plus its existing focus node; no long-press action | Row node remains, but the long-press action lands on the existing unlabeled focus node | **V1 contract failure: unlabeled action node** |

The physical `GestureDetector` is excluded from semantics. V2 was not built or
run because primary SelectableText selection and pre-threshold scrolling both
remain functional under V1; no destructive gesture failure justified the
passive-listener probe.

Additional automated observations:

- Secondary click, physical long press, Shift+F10, and the exposed Context Menu
  key each request one open through the shared path.
- Secondary pointer-down produces zero requests and zero opens; secondary
  pointer-up produces exactly one request and one actual open.
- A touch pointer held past the long-press threshold opens once, but dragging
  that same pointer over Rename and releasing produces zero selections and
  zero closes; the menu remains open until a separate Escape. The disposable
  scaffold therefore does **not** demonstrate Cupertino-style same-gesture
  item activation.
- Semantic activation on the Link requests and actually opens exactly once.
- Open requests, actual opens, close requests, actual closes, menu selections,
  and primary child activations are counted independently.
- Item selection and outside/Escape dismissal close once. A second secondary
  click on the trigger while open is classified outside the menu on pointer
  down, closes once, then reopens once on secondary tap-up. Repeated Escape
  after close does not produce another close callback.
- Current NakedMenu autofocus lands on its boundary. The test-only
  first-enabled probe focuses Delete when Rename is disabled. Focus returns to
  a mounted Link and removal of an open trigger does not request stale focus.
- The separate geometry probe clamps at all four edges. Anchor-local
  `RawMenuOverlayInfo.position` is preserved. Under scale, naïve
  `anchorRect.topLeft + position` drifts; converting the pointer global point
  into Overlay coordinates before `OverlayPositioner` remains accurate.
- Scroll offset, translated ancestry, RTL, and 200% text do not change the
  resolved invocation point in the fixed geometry probe.

### Automated SDK matrix

| Flutter | Focused widget | Flutter-tester integration | Menu/Select/Popover regressions | Result |
|---|---:|---:|---:|---|
| 3.41.0 declared minimum | 15/15 | 4/4 | 67/67 | PASS |
| 3.41.2 workspace pin | 15/15 | 4/4 | 67/67 | PASS; full analyze clean |
| 3.44.6 current stable | 15/15 | 4/4 | 67/67 | PASS |

The rapid-reopen assertion records the full ordered sequence. Each secondary
pointer interaction contributes one `open-request` then one `actual-open`; the
second click while open contributes one `close-request`/`actual-close` before
that reopen. The final Escape contributes one close pair, and the repeated
Escape contributes none. Totals are exactly 3/3 opens and 3/3 closes, with no
duplicate callback hidden by aggregate counts.

## Human AT sessions

No spoken output or browser accessibility result has been inferred from the
automated tests.

| Target | Operator/date | Build/device | V0 result | V1 result | Status |
|---|---|---|---|---|---|
| VoiceOver on macOS | — | — | — | — | **UNRUN** |
| TalkBack on Android | — | — | — | — | **UNRUN** |
| Chrome accessibility tree + keyboard | — | — | — | — | **UNRUN** |

### VoiceOver/macOS run sheet — UNRUN

```sh
fvm flutter run -d macos -t packages/example/lib/context_menu_accessibility_spike.dart
```

For Link, SelectableText, and row in both V0 and V1, record verbatim only what
the operator hears: role/name, whether a context-menu action is discoverable,
how it is invoked, whether the menu and first focus target are announced, and
the announcement after Escape or selection. Also run mouse secondary-click,
Shift+F10, and the Context Menu key if macOS exposes it. Edge screenshots:
**UNRUN / not attached**.

### TalkBack/Android run sheet — UNRUN

```sh
fvm flutter run -d android -t packages/example/lib/context_menu_accessibility_spike.dart
```

For all three children and both variants, record the actual TalkBack local
context/actions UI, spoken role/name/action, one-finger long press, focus after
open, selection exactly once, Escape/back dismissal, and restoration. Repeat
with 200% text and near every viewport edge. Screenshots: **UNRUN / not
attached**.

### Chrome run sheet — UNRUN

```sh
fvm flutter run -d chrome -t packages/example/lib/context_menu_accessibility_spike.dart
```

Inspect the headed Chrome accessibility tree for node count, role, name, and
actions in V0 and V1. Exercise secondary-click, Shift+F10, and Context Menu key
when reported by the browser/platform. Record actual tree output and keyboard
behavior; do not translate widget-test semantics into browser claims.
Screenshots/log: **UNRUN / not attached**.

## Gate conclusion

D-03 remains open because V1 fails the automated SelectableText and row action
node contract, the scaffold fails same-gesture touch selection, and all three
required human AT sessions are UNRUN. This evidence does not authorize exports,
production package code, a public constructor, registry changes,
aggregate-runner changes, docs, changelog, or goldens.
