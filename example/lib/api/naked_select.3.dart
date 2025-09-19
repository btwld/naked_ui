import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Searchable Select',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Type to filter options',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 32),
                SearchableSelectExample(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchableSelectExample extends StatefulWidget {
  const SearchableSelectExample({super.key});

  @override
  State<SearchableSelectExample> createState() => _SearchableSelectExampleState();
}

class _SearchableSelectExampleState extends State<SearchableSelectExample> {
  String? _selectedCountry;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<Map<String, String>> _countries = [
    {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
    {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
    {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
    {'code': 'IT', 'name': 'Italy', 'flag': '🇮🇹'},
    {'code': 'ES', 'name': 'Spain', 'flag': '🇪🇸'},
    {'code': 'JP', 'name': 'Japan', 'flag': '🇯🇵'},
    {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': 'BR', 'name': 'Brazil', 'flag': '🇧🇷'},
    {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
    {'code': 'MX', 'name': 'Mexico', 'flag': '🇲🇽'},
  ];

  List<Map<String, String>> get filteredCountries {
    if (_searchQuery.isEmpty) return _countries;
    return _countries.where((country) {
      final query = _searchQuery.toLowerCase();
      return country['name']!.toLowerCase().contains(query) ||
          country['code']!.toLowerCase().contains(query);
    }).toList();
  }

  Map<String, String>? get selectedCountry {
    if (_selectedCountry == null) return null;
    return _countries.firstWhere(
      (country) => country['code'] == _selectedCountry,
      orElse: () => {'code': '', 'name': '', 'flag': ''},
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchableOption(Map<String, String> country) {
    return NakedSelectOption<String>(
      value: country['code']!,
      builder: (context, states, _) {
        final hovered = states.contains(WidgetState.hovered);
        final selected = states.contains(WidgetState.selected);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Colors.blue.shade50
                : hovered
                    ? Colors.grey.shade100
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Text(
                country['flag']!,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  country['name']!,
                  style: TextStyle(
                    color: selected ? Colors.blue : Colors.black,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.blue,
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: NakedSelect<String>(
        value: _selectedCountry,
        onChanged: (value) => setState(() => _selectedCountry = value),
        onOpen: () {
          _searchQuery = '';
          _searchController.clear();
        },
        triggerBuilder: (context, states) {
          final focused = states.contains(WidgetState.focused);
          final hovered = states.contains(WidgetState.hovered);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: focused ? Colors.blue : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: hovered
                      ? const Color(0x14000000)
                      : const Color(0x0A000000),
                  blurRadius: hovered ? 8 : 4,
                  offset: Offset(0, hovered ? 2 : 1),
                ),
              ],
            ),
            child: Row(
              children: [
                if (selectedCountry != null) ...[
                  Text(
                    selectedCountry!['flag']!,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    selectedCountry?['name'] ?? 'Search countries...',
                    style: TextStyle(
                      color: selectedCountry != null
                          ? Colors.black
                          : Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          );
        },
        overlayBuilder: (context, info) {
          return Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type to search countries...',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                if (filteredCountries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No countries found',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'Try a different search term',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      children: filteredCountries.map(_buildSearchableOption).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}