import 'package:example/src/testing/context_menu_accessibility_spike.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ContextMenuAccessibilitySpikeApp());

/// Standalone direct-target runner for the disposable D-03 evidence spike.
class ContextMenuAccessibilitySpikeApp extends StatelessWidget {
  const ContextMenuAccessibilitySpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _ContextMenuAccessibilitySpikePage(),
    );
  }
}

class _ContextMenuAccessibilitySpikePage extends StatefulWidget {
  const _ContextMenuAccessibilitySpikePage();

  @override
  State<_ContextMenuAccessibilitySpikePage> createState() =>
      _ContextMenuAccessibilitySpikePageState();
}

class _ContextMenuAccessibilitySpikePageState
    extends State<_ContextMenuAccessibilitySpikePage> {
  final _link = ContextMenuSpikeCounters();
  final _selectable = ContextMenuSpikeCounters();
  final _row = ContextMenuSpikeCounters();
  final _geometry = ContextMenuGeometryObservations();

  ContextMenuSpikeVariant _variant =
      ContextMenuSpikeVariant.v1SemanticLongPress;
  ContextMenuSpikeInitialFocus _initialFocus =
      ContextMenuSpikeInitialFocus.boundary;
  bool _enabled = true;
  bool _disableFirstItem = false;
  bool _rtl = false;
  bool _largeText = false;

  @override
  void dispose() {
    _link.dispose();
    _selectable.dispose();
    _row.dispose();
    _geometry.dispose();
    super.dispose();
  }

  void _reset() {
    _link.reset();
    _selectable.reset();
    _row.reset();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: _largeText
            ? const TextScaler.linear(2)
            : TextScaler.noScaling,
      ),
      child: Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(title: const Text('Context Menu D-03 spike')),
          body: ListView(
            key: ContextMenuSpikeKeys.scroll,
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Disposable evidence fixture — not a production Context Menu API.',
              ),
              const SizedBox(height: 16),
              DropdownButton<ContextMenuSpikeVariant>(
                key: ContextMenuSpikeKeys.variant,
                value: _variant,
                items: ContextMenuSpikeVariant.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _variant = value!),
              ),
              DropdownButton<ContextMenuSpikeInitialFocus>(
                value: _initialFocus,
                items: ContextMenuSpikeInitialFocus.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _initialFocus = value!),
              ),
              SwitchListTile(
                key: ContextMenuSpikeKeys.disable,
                title: const Text('Context trigger enabled'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              CheckboxListTile(
                title: const Text('Disable first menu item'),
                value: _disableFirstItem,
                onChanged: (value) =>
                    setState(() => _disableFirstItem = value!),
              ),
              CheckboxListTile(
                title: const Text('RTL'),
                value: _rtl,
                onChanged: (value) => setState(() => _rtl = value!),
              ),
              CheckboxListTile(
                title: const Text('200% text'),
                value: _largeText,
                onChanged: (value) => setState(() => _largeText = value!),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: ContextMenuSpikeKeys.reset,
                  onPressed: _reset,
                  child: const Text('Reset counters'),
                ),
              ),
              const Divider(),
              const Text('Real NakedLink'),
              ContextMenuSpikeTrigger(
                variant: _variant,
                childKind: ContextMenuSpikeChildKind.link,
                counters: _link,
                initialFocus: _initialFocus,
                enabled: _enabled,
                disableFirstItem: _disableFirstItem,
              ),
              const SizedBox(height: 28),
              const Text('Real SelectableText'),
              ContextMenuSpikeTrigger(
                variant: _variant,
                childKind: ContextMenuSpikeChildKind.selectableText,
                counters: _selectable,
                initialFocus: _initialFocus,
                enabled: _enabled,
                disableFirstItem: _disableFirstItem,
              ),
              const SizedBox(height: 28),
              const Text('Generic list row'),
              ContextMenuSpikeTrigger(
                variant: _variant,
                childKind: ContextMenuSpikeChildKind.row,
                counters: _row,
                initialFocus: _initialFocus,
                enabled: _enabled,
                disableFirstItem: _disableFirstItem,
              ),
              const SizedBox(height: 28),
              const Text('Independent point-geometry probe'),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ContextMenuGeometryProbe(observations: _geometry),
              ),
              const SizedBox(height: 28),
              ListenableBuilder(
                listenable: Listenable.merge([_link, _selectable, _row]),
                builder: (context, child) => SelectableText(
                  key: ContextMenuSpikeKeys.state,
                  'Link: $_link\nSelectable: $_selectable\nRow: $_row',
                ),
              ),
              const SizedBox(height: 400),
            ],
          ),
        ),
      ),
    );
  }
}
