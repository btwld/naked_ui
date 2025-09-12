Flutter Headless Widgets — Complete Semantics Guide (v3, Role‑First)

A production‑ready, API‑accurate reference for implementing accessibility semantics in headless Flutter component libraries. This version emphasizes roles first (where applicable), eliminates duplicate actions, and bakes in the latest platform guidance.

What’s new in v3
	•	Role‑first semantics: Prefer role: SemanticsRole.* when an appropriate role exists (tabs, dialogs, lists, menus, progress, etc.). Keep boolean flags (button, checked, toggled, link, etc.) for states and for controls that have no corresponding role.
	•	Radio redesign: Note the new RadioGroup API and how it centralizes selection + semantics.
	•	Links: Use link: true and linkUrl for destinations.
	•	Dialogs: Clarified namesRoute vs scopesRoute and iOS duplication caveat.
	•	Testing: Use SemanticsData.hasAction(...) in tests; sample helpers included.
	•	Adjustables: Added increasedValue/decreasedValue patterns for sliders.
	•	Traversal: Added SemanticsSortKey/OrdinalSortKey examples.

Target: Flutter 3.35 (stable)

⸻

Table of Contents
	•	Critical Rules
	•	Roles vs. Flags: Quick Map
	•	Core Principles
	•	Focus Management Strategies
	•	Component Implementations
	•	Testing & Debugging
	•	Common Pitfalls
	•	Platform Considerations
	•	Migration Notes
	•	References

⸻

Critical Rules

🚨 Rule 0: Prefer Roles (when they exist)

Use role: SemanticsRole.* to declare the purpose of a subtree when an applicable role exists (e.g., dialog, alertDialog, list, listItem, tab, tabBar, tabPanel, menu, menuItem, comboBox, progressBar, loadingSpinner, radioGroup).
	•	Roles do not replace control state flags (button, checked, toggled, selected, textField, link, etc.). Keep using those flags for interaction/state.
	•	Don’t invent roles. If there is no role for a given control (e.g., button, checkbox, switch, slider), use the flags.

🚨 Rule 1: Exclude Gesture Detectors When You Provide Actions

If a parent Semantics provides actions (onTap, onLongPress, onIncrease/onDecrease, etc.), set excludeFromSemantics: true on GestureDetector, InkWell, or InkResponse to avoid duplicate actions.

// ✅ CORRECT
Semantics(
  onTap: onPressed,
  child: GestureDetector(
    onTap: onPressed,
    excludeFromSemantics: true, // Avoid duplicate actions
    child: child,
  ),
);

🚨 Rule 2: Place Semantics inside FocusableActionDetector

FocusableActionDetector(includeFocusSemantics: true) injects focus semantics (focusable/focused). Wrapping Semantics inside keeps role/flags and focus on the same node. Only set includeFocusSemantics: false if you’re deliberately controlling focus semantics elsewhere.

🚨 Rule 3: Prefer MergeSemantics over nuking children

Use MergeSemantics (or Semantics(excludeSemantics: true) only when absolutely necessary) to combine label + control semantics.

🚨 Rule 4: Never expose obscured values

For password fields, set obscured: true and omit value.

⸻

Container Semantics: when to create a node (and when not to)

Short answer: Don’t default to container: true in a headless library. Only create a node when you truly need a dedicated, addressable control in the semantics tree.

Use container: true when…
	•	The subtree should be announced as a single unit (e.g., an icon + label button that must be one focus target).
	•	You need a stable node to attach things like SemanticsSortKey, tooltip, or keyboard/focus semantics that shouldn’t merge upward.
	•	You’re deliberately preventing child semantics from merging into an ancestor that has different meaning.

Avoid container: true when…
	•	The host (parent) widget is providing the label/description and you want that to merge with your control’s actions; prefer MergeSemantics at the parent.
	•	The widget is a simple leaf where the parent already supplies the correct semantics.

Important nuances
	•	Flutter implicitly introduces container boundaries in common cases (e.g., a parent with multiple semantics-providing children) so you often don’t need to set container yourself.
	•	BlockSemantics hides nodes “painted before it in the same semantic container.” Put BlockSemantics at the overlay/dialog root. Sprinkling extra containers inside your dialog usually isn’t necessary and can change what’s considered “previous” locally.
	•	For dialogs with scopesRoute: true, remember explicitChildNodes: true is required. That’s orthogonal to container.

Headless-library default
	•	Expose a knob like createSemanticsNode (default false). Let integrators opt-in when they want a dedicated node.

⸻

Roles vs. Flags: Quick Map

UI pattern	Prefer Role	Keep Flags
Dialog / Alert	role: SemanticsRole.dialog or SemanticsRole.alertDialog	scopesRoute: true, explicitChildNodes: true, optional namesRoute + label
Tabs	tabBar on the container, tab on each tab, tabPanel for active panel	selected, button: true (optional for custom tab buttons)
Dropdown / Select	Collapsed: comboBox	button: true, value, expanded (when open)
Expanded menu popup	menu on list, menuItem on each option	selected, onTap
Lists	list on container, listItem on rows	selected, button: true (if tappable)
Progress	progressBar (linear), loadingSpinner (indeterminate/circular)	value (localized), liveRegion: true for polite updates
Radio sets	radioGroup on container	Each item: checked, inMutuallyExclusiveGroup: true
Links	(no role)	link: true, linkUrl
Buttons	(no role)	button: true
Checkbox / Switch / Slider	(no role)	checked/mixed, toggled, onIncrease/onDecrease, value

If both a role and a traditional flag make sense (e.g., a tab that acts like a button), set the role and the necessary flags. Keep them consistent.

⸻

Core Principles
	•	Container nodes: Use container: true to create a dedicated node for composite widgets (e.g., icon + label buttons) and to prevent odd merges.
	•	Human‑readable values: Provide localized, human strings in value, increasedValue, and decreasedValue (e.g., "45%", "Volume 8 of 10").
	•	Traversal order: When visual and logical orders diverge, set sortKey: OrdinalSortKey(n) on siblings to shape screen reader traversal.
	•	Input fields: For custom text fields, set textField: true, and when relevant inputType: SemanticsInputType.* (e.g., number, password).

⸻

Headless composition recipe (no painting)

Headless components contribute behavior + semantics and let the host render visuals. Keep rendering in the builder; keep actions/semantics in the wrapper.

class HeadlessButton extends StatelessWidget {
  const HeadlessButton({
    super.key,
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.createSemanticsNode = false,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, FocusNode focusNode) builder; // host paints
  final String? semanticLabel;
  final bool createSemanticsNode; // default false; opt-in boundary

  @override
  Widget build(BuildContext context) {
    final focusNode = FocusNode(skipTraversal: onPressed == null);
    return FocusableActionDetector(
      focusNode: focusNode,
      enabled: onPressed != null,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) { onPressed?.call(); return null; },
        ),
      },
      child: Semantics(
        // No role for a generic button; use flags
        button: true,
        enabled: onPressed != null,
        label: semanticLabel,
        onTap: onPressed,
        container: createSemanticsNode, // usually false for headless
        child: builder(context, focusNode), // host renders visuals
      ),
    );
  }
}

Tip: start with createSemanticsNode: false and rely on the parent to merge label+control using MergeSemantics. Flip it to true only when you need an explicit node.

⸻

Focus Management Strategies
	•	Use FocusableActionDetector when you need hover, shortcuts, focus highlights, or complex interactions.
	•	Use Focus for simple focus only. Note: Focus.includeSemantics defaults to true (it creates focusable/focused semantics automatically).

FocusableActionDetector(
  includeFocusSemantics: true, // default
  actions: {
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) { onActivate(); return null; }),
  },
  child: Semantics(
    // role/flags/state here
    child: child,
  ),
);


⸻

Component Implementations

For each component, we show role‑first patterns (when roles exist) and the required flags/actions.

Button

No SemanticsRole exists for a generic button; use flags + actions.

return Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  button: true,
  enabled: onPressed != null,
  label: semanticLabel,
  tooltip: tooltip,
  focusable: onPressed != null,
  focused: focusNode?.hasFocus == true,
  onTap: onPressed,
  onLongPress: onLongPress,
  child: GestureDetector(
    onTap: onPressed,
    onLongPress: onLongPress,
    excludeFromSemantics: true,
    child: Focus(focusNode: focusNode, child: child),
  ),
);


⸻

Checkbox (Tristate‑aware)

return MergeSemantics(
  child: Semantics(
    container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
    checked: value == true,
    mixed: tristate && value == null,
    enabled: onChanged != null,
    label: semanticLabel,
    onTap: onChanged != null ? _toggleValue : null,
    focusable: onChanged != null,
    focused: focusNode?.hasFocus == true,
    child: GestureDetector(
      onTap: onChanged != null ? _toggleValue : null,
      excludeFromSemantics: true,
      child: Focus(focusNode: focusNode, child: child),
    ),
  ),
);

void _toggleValue() {
  if (tristate) {
    final newValue = value == false ? true : value == true ? null : false;
    onChanged?.call(newValue);
  } else {
    onChanged?.call(!(value ?? false));
  }
}


⸻

Radio / Radio Group

Prefer the built‑in Radio with RadioGroup. If you must build from scratch:

// Container for a set of radios
Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  role: SemanticsRole.radioGroup,
  child: childListOfCustomRadios,
);

// Individual radio
Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  checked: isSelected,
  inMutuallyExclusiveGroup: true,
  enabled: onChanged != null,
  label: semanticLabel,
  onTap: onChanged != null ? () => onChanged!(value) : null,
  child: GestureDetector(
    onTap: onChanged != null ? () => onChanged!(value) : null,
    excludeFromSemantics: true,
    child: Focus(focusNode: focusNode, child: child),
  ),
);


⸻

Switch

return Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  toggled: value, // use toggled for switches
  enabled: onChanged != null,
  label: semanticLabel,
  onTap: onChanged != null ? () => onChanged!(!value) : null,
  focusable: onChanged != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onTap: onChanged != null ? () => onChanged!(!value) : null,
    excludeFromSemantics: true,
    child: Focus(focusNode: focusNode, child: child),
  ),
);


⸻

Slider (Adjustable)

Add localized value plus onIncrease/onDecrease and the future value hints.

return Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  // No role for slider; use flags + actions
  label: semanticLabel,
  value: _valueLabel(value),              // e.g., "45%" or "7 of 10"
  increasedValue: _valueLabel(_stepUp(value)),
  decreasedValue: _valueLabel(_stepDown(value)),
  enabled: onChanged != null,
  onIncrease: (onChanged != null && value < max) ? () => _bump(true) : null,
  onDecrease: (onChanged != null && value > min) ? () => _bump(false) : null,
  focusable: onChanged != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onHorizontalDragUpdate: onChanged != null ? _handleDrag : null,
    excludeFromSemantics: true,
    child: Focus(focusNode: focusNode, child: child),
  ),
);


⸻

TextField (Headless EditableText)

return Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  textField: true,
  inputType: isNumeric ? SemanticsInputType.number : null,
  multiline: (maxLines ?? 1) > 1,
  obscured: obscureText,
  readOnly: readOnly,
  maxValueLength: maxLength,
  currentValueLength: (maxLength != null && controller != null)
      ? controller!.text.characters.length
      : null,
  value: obscureText ? null : controller?.text,
  label: semanticLabel,
  hint: semanticHint,
  focusable: !readOnly,
  focused: focusNode?.hasFocus == true,
  child: EditableText(
    controller: controller,
    focusNode: focusNode,
    // ... platform text config
  ),
);


⸻

Dropdown / Select

Collapsed (button‑like) — use the combo box role.

return Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  role: SemanticsRole.comboBox,
  enabled: onChanged != null,
  label: semanticLabel,
  value: selectedValue?.toString() ?? 'None selected',
  onTap: onChanged != null ? _openDropdown : null,
  focusable: onChanged != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onTap: onChanged != null ? _openDropdown : null,
    excludeFromSemantics: true,
    child: Focus(focusNode: focusNode, child: child),
  ),
);

Expanded (popup list) — model as menu with menu items.

return Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  role: SemanticsRole.menu,
  expanded: true,
  enabled: onChanged != null,
  label: semanticLabel,
  child: ListView.builder(
    itemCount: options.length,
    itemBuilder: (context, index) {
      final option = options[index];
      return Semantics(
        container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
        role: SemanticsRole.menuItem,
        selected: option == selectedValue,
        label: option.toString(),
        onTap: () => _selectOption(option),
        child: GestureDetector(
          onTap: () => _selectOption(option),
          excludeFromSemantics: true,
          child: _buildOption(option),
        ),
      );
    },
  ),
);

Need a strict listbox pattern? Combine role: menu/menuItem with sortKey for deterministic traversal.

⸻

Tabs

// Tab bar container
final tabBar = Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  role: SemanticsRole.tabBar,
  child: Row(children: tabs),
);

// Individual tab
Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  role: SemanticsRole.tab,
  selected: isSelected,
  enabled: onTap != null,
  label: semanticLabel,
  onTap: onTap,
  child: GestureDetector(
    onTap: onTap,
    excludeFromSemantics: true,
    child: Focus(focusNode: focusNode, child: child),
  ),
);

// Active panel area
Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  role: SemanticsRole.tabPanel,
  child: panelChild,
);


⸻

Dialog

Widget dialog = Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  role: isAlert ? SemanticsRole.alertDialog : SemanticsRole.dialog,
  scopesRoute: true,
  explicitChildNodes: true,     // pair with scopesRoute
  // Consider namesRoute + label for non‑iOS to avoid double title announcement on iOS
  namesRoute: announceTitleOnThisPlatform,
  label: semanticLabel ?? dialogTitle,
  child: child,
);

// Only for modal dialogs
if (modal) {
  dialog = BlockSemantics(child: dialog);
}
return dialog;

Notes
	•	scopesRoute: true + explicitChildNodes: true are recommended for dialog containers.
	•	Use namesRoute + label thoughtfully. Some platforms (notably iOS) can announce the title twice if both the title widget and the route name are read.

⸻

Tooltip

Prefer the built‑in Tooltip. If you supply your own description:

return Semantics(
  tooltip: message,
  // Optional role if you’re exposing a persistent helper region
  role: SemanticsRole.tooltip,
  child: child,
);

If you also use Tooltip(message: ...), don’t duplicate labels. You can set Tooltip.excludeFromSemantics: true if you are providing a custom Semantics(tooltip: ...).

⸻

Progress Indicator

return Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  role: value == null ? SemanticsRole.loadingSpinner : SemanticsRole.progressBar,
  label: semanticLabel ?? (value == null ? 'Loading' : 'Progress'),
  value: value != null ? '${(value * 100).round()}%' : null,
  liveRegion: true, // asks AT to politely announce updates
  child: child,
);


⸻

Link

return Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  link: true,
  linkUrl: (url != null) ? Uri.parse(url!) : null, // provide when available
  enabled: onTap != null,
  label: semanticLabel,
  onTap: onTap,
  focusable: onTap != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onTap: onTap,
    excludeFromSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Focus(focusNode: focusNode, child: child),
    ),
  ),
);


⸻

List / List Item

// List container
Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  role: SemanticsRole.list,
  child: listView,
);

// Individual row
Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  role: SemanticsRole.listItem,
  button: onTap != null,
  enabled: onTap != null,
  label: label,
  selected: isSelected,
  onTap: onTap,
  child: onTap != null
      ? GestureDetector(
          onTap: onTap,
          excludeFromSemantics: true,
          child: Focus(focusNode: focusNode, child: child),
        )
      : child,
);


⸻

Toggle / Collapsible

return Semantics(
  container: true, // Only if you need a dedicated node; omit otherwise (see Container Semantics)
  button: true,
  expanded: expanded,
  enabled: onToggle != null,
  label: semanticLabel,
  onTap: onToggle,
  child: GestureDetector(
    onTap: onToggle,
    excludeFromSemantics: true,
    child: Focus(focusNode: focusNode, child: child),
  ),
);


⸻

Testing & Debugging

Visualize semantics

MaterialApp(
  showSemanticsDebugger: true,
)

Dump the tree in logs (useful in tests/dev tools):

debugDumpSemanticsTree();
// or with order
debugDumpSemanticsTree(DebugSemanticsDumpOrder.inverseHitTest);
```dart
MaterialApp(
  showSemanticsDebugger: true,
  // ...
)

Matchers and nodes

testWidgets('button has correct semantics', (tester) async {
  final handle = tester.ensureSemantics();

  await tester.pumpWidget(MyButton(onPressed: () {}, label: 'Submit'));

  expect(
    tester.getSemantics(find.byType(MyButton)),
    matchesSemantics(
      label: 'Submit',
      isButton: true,
      isEnabled: true,
      isFocusable: true,
      hasEnabledState: true,
      hasTapAction: true,
    ),
  );

  handle.dispose();
});

Count (or verify) actions using SemanticsData

final SemanticsNode root = tester.getSemantics(find.byType(MyButton));
int tapActions = 0;
void visit(SemanticsNode n) {
  final data = n.getSemanticsData();
  if (data.hasAction(SemanticsAction.tap)) tapActions++;
  n.visitChildren(visit);
}
visit(root);
expect(tapActions, 1);

Perform actions in tests

final node = tester.getSemantics(find.byType(MyButton));
await tester.binding.pipelineOwner.semanticsOwner!.performAction(
  node.id,
  SemanticsAction.tap,
);

Focus semantics

testWidgets('focus updates semantics', (tester) async {
  final focusNode = FocusNode();
  await tester.pumpWidget(MaterialApp(home: MyButton(focusNode: focusNode, label: 'Test')));

  expect(tester.getSemantics(find.byType(MyButton)).isFocused, false);
  focusNode.requestFocus();
  await tester.pump();
  expect(tester.getSemantics(find.byType(MyButton)).isFocused, true);
  focusNode.dispose();
});

Shape traversal order

Semantics(
  sortKey: const OrdinalSortKey(1),
  child: first,
);
Semantics(
  sortKey: const OrdinalSortKey(2),
  child: second,
);


⸻

Common Pitfalls
	•	Duplicate actions: Don’t leave GestureDetector semantics enabled when a parent Semantics already supplies onTap/onLongPress.
	•	Roles where none exist: There is no SemanticsRole.button/checkbox/switch/slider. Use flags.
	•	Missing linkUrl: When link: true, set linkUrl if you have a destination.
	•	Dialog announcements: Unconditional namesRoute: true can cause duplicate title announcements on some platforms. Be intentional.
	•	Raw values: Provide human‑readable value/increasedValue/decreasedValue instead of raw numbers.

⸻

Platform Considerations
	•	iOS VoiceOver: May announce dialog titles via both the title widget and route name. Tune namesRoute accordingly.
	•	Android TalkBack: Swipe up/down can trigger onIncrease/onDecrease for adjustables.
	•	Desktop/Web: Keyboard traversal expects focusable nodes; roles improve mapping to ARIA. Flutter Web maps scopesRoute/namesRoute to dialog semantics and uses roles where available.

⸻

Migration Notes
	•	Add excludeFromSemantics: true to all GestureDetector/InkWell/InkResponse where a parent Semantics provides actions.
	•	Consider FocusableActionDetector for custom interactive controls needing keyboard/hover.
	•	Update radio sets to RadioGroup where using stock widgets.
	•	Add roles where available (tabs/lists/dialogs/menus/progress) and keep legacy flags for control state.
	•	Use linkUrl with link: true.

⸻

References
	•	API: Semantics (widgets), SemanticsProperties (semantics), Focus/FocusableActionDetector, MergeSemantics/ExcludeSemantics, BlockSemantics, SemanticsSortKey/OrdinalSortKey, SemanticsRole, SemanticsAction
	•	Guides: Flutter Accessibility docs; Material Accessibility; WCAG quick ref
	•	Notes: Radio API redesign (RadioGroup), tooltip semantics/exclusion, route naming (scopesRoute/namesRoute)

