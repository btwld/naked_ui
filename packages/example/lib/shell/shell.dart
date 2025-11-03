import 'package:flutter/material.dart';

import '../registry.dart';

class KitchenShell extends StatefulWidget {
  const KitchenShell({super.key, this.initialDemoId, this.embed = false});

  final String? initialDemoId;
  final bool embed;

  @override
  State<KitchenShell> createState() => _KitchenShellState();
}

class _KitchenShellState extends State<KitchenShell> {
  String _filter = '';
  Demo? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.initialDemoId != null) {
      _selected = DemoRegistry.find(widget.initialDemoId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embed) {
      final demo = _selected ?? DemoRegistry.demos.first;
      return _DemoScaffold(demo: demo, embed: true);
    }

    final categories = DemoRegistry.byCategory();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Naked Kitchen Sink'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Row(
        children: [
          SizedBox(
            width: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search demos...',
                    ),
                    onChanged: (v) => setState(() => _filter = v.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final entry in categories.entries)
                        _CategoryList(
                          title: entry.key,
                          demos: entry.value
                              .where(
                                (d) =>
                                    _filter.isEmpty ||
                                    d.title.toLowerCase().contains(_filter) ||
                                    d.tags.any((t) => t.contains(_filter)),
                              )
                              .toList(),
                          onTap: (demo) {
                            setState(() => _selected = demo);
                          },
                          selectedId: _selected?.id,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _DemoScaffold(demo: _selected ?? DemoRegistry.demos.first),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.title,
    required this.demos,
    required this.onTap,
    this.selectedId,
  });

  final String title;
  final List<Demo> demos;
  final ValueChanged<Demo> onTap;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    if (demos.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      initiallyExpanded: true,
      children: [
        for (final d in demos)
          ListTile(
            title: Text(d.title),
            onTap: () => onTap(d),
            selected: d.id == selectedId,
            dense: true,
          ),
      ],
    );
  }
}

class _DemoScaffold extends StatelessWidget {
  const _DemoScaffold({required this.demo, this.embed = false});

  final Demo demo;
  final bool embed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Text(demo.title, style: const TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(
                  tooltip: 'Open fullscreen',
                  icon: const Icon(Icons.open_in_full),
                  onPressed: () {
                    final uri = Uri(path: '/#/${'component'}/${demo.id}');
                    // On the web this opens the gh-pages URL; locally it’s fine.
                    // ignore: deprecated_member_use
                    // Navigator logic not used here; rely on copy for now.
                    debugPrint(uri.toString());
                  },
                ),
                if (demo.sourceUrl != null)
                  IconButton(
                    tooltip: 'View source',
                    icon: const Icon(Icons.code),
                    onPressed: () {
                      // A real app might use url_launcher; we avoid runtime deps here.
                      debugPrint('Source: ${demo.sourceUrl}');
                    },
                  ),
              ],
            ),
          ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: demo.builder(context),
            ),
          ),
        ),
      ],
    );
  }
}
