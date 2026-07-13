# `shadcn_flutter` component reference audit

Audited: **2026-07-13**. The requested “Flutter shadcn” comparison is scoped to
the [`shadcn_flutter`](https://pub.dev/packages/shadcn_flutter) package by
sunarya-thito. Pub currently lists 0.0.52; the repository master inspected here
declares 0.0.53 at commit
[`a4504aae7a99844a350e64d92f3d2ae773ebb361`](https://github.com/sunarya-thito/shadcn_flutter/commit/a4504aae7a99844a350e64d92f3d2ae773ebb361)
(2026-07-12). Master is reference evidence, not a package dependency or a
stable contract.

This library is a styled UI ecosystem with its own theme, form, interaction,
and overlay systems. Naked UI should not depend on it or copy its machinery.
The useful output of this audit is a set of behavior ideas and negative test
cases to carry into the eight headless plans.

## Component findings

| Naked UI phase | What `shadcn_flutter` does | Recommendation for Naked UI |
|---|---|---|
| Alert Dialog | Its dialog route extends `RawDialogRoute`, uses safe-area and closed-loop traversal, and captures inherited data. Its visual `AlertDialog` does not itself establish the required alert-dialog role/name, while the route layer supplies a hard-coded English barrier label. | The raw-route choice is independently validated. Keep Naked UI's explicit role/name, localization, safe initial focus, barrier policy, and restoration contract; reuse no shadcn code. |
| Link | `Button.link` is a visual button variant built on the generic `Clickable`; both Enter and Space activate it, and it does not establish link role/destination semantics. | Treat it only as a visual-state example. It cannot replace `NakedLink`; retain one link node, Enter-only keyboard activation, unavailable destination removal, and the approved official `url_launcher.Link` navigation coordinator. |
| Field | Its `FormField<T>` owns validators/error-display timing and visually lays out label, hint, child, and error. The wrapper does not create the semantic association/required/validation contract planned for Naked Field. | Do not copy validation ownership. The compositional slots are useful example input, but Naked Field remains a controlled semantic scope integrated with the native child. |
| Toggle Group | `ControlledToggle`/`SelectedButton` manage one boolean state and `ButtonGroup` visually joins buttons. There is no equivalent composite toggle-group role/roving-focus contract. The generic clickable also binds arrow keys to spatial focus and Enter/Space to activation per button. | Borrow no group implementation. Preserve Naked UI's intent split and implement/test one group Tab stop, controlled selection, orientation/RTL arrows, disabled skip, and exact selected-vs-toggled semantics. |
| Context Menu | `ContextMenu` opens a custom overlay from secondary-tap-down and mobile long-press; its menu core has arrow/Enter/Escape handling. The trigger wrapper has no Shift+F10/Context Menu key path or explicit trigger semantic-action contract. | Use its pointer entry and platform-gating cases as test inputs, but keep `RawMenuAnchor` plus existing Naked Menu items/focus/semantics. Add the missing keyboard and AT trigger proof. |
| Toast | A root `ToastLayer` supports six locations, multiple stacked entries, hover expansion, hover timer cancellation, and swipe dismissal. It does not supply status/alert semantics, application-lifecycle or focus/accessibility pauses, remaining-duration accounting, FIFO promotion policy, or explicit dismissal reasons. | Do not inherit the larger stack/swipe surface. Keep the reduced one-visible FIFO MVP, structured semantics, exact remaining time, lifecycle/focus pauses, and exactly-once reasons. |
| Hover Card | `HoverCard` uses delayed hover, keeps the overlay open while the card is hovered, allows long-press, and accepts arbitrary content. Its counter-based `Future.delayed` model has no keyboard-focus open, Escape ownership, semantic boundary, noninteractive-content rule, or pointer grace corridor. | Reuse only the trigger/card hover-persistence scenario. Keep cancellable deterministic timing, focus/Escape support, nonessential noninteractive content, per-instance close, and tested corridor geometry. |
| Combobox | Its `AutoComplete` owns a custom popover/highlight model rather than `RawAutocomplete`. It accepts the highlighted suggestion on Tab, has no combobox/active-option semantic contract, and does not model disabled options, async races, or IME safeguards. | This is a negative behavioral reference: Tab must never select. Continue the unexported `RawAutocomplete` spike with input focus retained, popup `ExcludeFocus`, real AT/IME proof, and a documented disabled-option outcome. |

## What is worth carrying forward

- Dialog composition confirms that `RawDialogRoute`, safe area, closed-loop
  traversal, and inherited-context capture are the correct low-level pieces.
- Context Menu and Hover Card provide useful pointer fixtures: secondary-click
  position, mobile long-press, trigger-to-overlay hover persistence, and edge
  placement.
- Toast provides stress cases for stacked visuals, hover, swipe, and close
  animation. Those are regression ideas, not permission to expand the MVP.
- Autocomplete provides an explicit anti-regression: accepting on Tab is
  convenient for text completion but wrong for the planned combobox contract.
- The package's visual `WidgetState` patterns are already covered by Naked
  UI's own state/builders; importing a styled ecosystem would add no missing
  headless primitive.

## What must not be imported as architecture

- The package-wide custom overlay manager, popover handlers, form controller,
  themes, and generic clickable are broader than each Naked UI contract and
  would create a second lifecycle/semantics stack beside Flutter raw widgets.
- Documentation claims such as “accessibility” or “proper lifecycle” are not
  substitutes for semantics nodes, assistive-technology output, deterministic
  disposal tests, and exact keyboard postconditions.
- Default English labels, button-styled links, Tab-to-accept autocomplete,
  timer restarts, arbitrary interactive hover content, and missing trigger
  semantics are examples to test against, not defaults to reproduce.

## Primary source files inspected

- [`AlertDialog`](https://github.com/sunarya-thito/shadcn_flutter/blob/a4504aae7a99844a350e64d92f3d2ae773ebb361/packages/shadcn_flutter/lib/src/components/layout/dialog/alert_dialog.dart)
  and [`DialogRoute`](https://github.com/sunarya-thito/shadcn_flutter/blob/a4504aae7a99844a350e64d92f3d2ae773ebb361/packages/shadcn_flutter/lib/src/components/overlay/dialog.dart)
- [`Clickable` / button variants](https://github.com/sunarya-thito/shadcn_flutter/blob/a4504aae7a99844a350e64d92f3d2ae773ebb361/packages/shadcn_flutter/lib/src/components/control/clickable.dart)
- [`FormField`](https://github.com/sunarya-thito/shadcn_flutter/blob/a4504aae7a99844a350e64d92f3d2ae773ebb361/packages/shadcn_flutter/lib/src/components/form/form.dart)
- [`ContextMenu`](https://github.com/sunarya-thito/shadcn_flutter/blob/a4504aae7a99844a350e64d92f3d2ae773ebb361/packages/shadcn_flutter/lib/src/components/menu/context_menu.dart)
- [`ToastLayer`](https://github.com/sunarya-thito/shadcn_flutter/blob/a4504aae7a99844a350e64d92f3d2ae773ebb361/packages/shadcn_flutter/lib/src/components/overlay/toast.dart)
- [`HoverCard`](https://github.com/sunarya-thito/shadcn_flutter/blob/a4504aae7a99844a350e64d92f3d2ae773ebb361/packages/shadcn_flutter/lib/src/components/overlay/hover_card.dart)
- [`AutoComplete`](https://github.com/sunarya-thito/shadcn_flutter/blob/a4504aae7a99844a350e64d92f3d2ae773ebb361/packages/shadcn_flutter/lib/src/components/form/autocomplete.dart)
