import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SearchableSelectExample(),
        ),
      ),
    );
  }
}

class SearchableSelectExample extends StatefulWidget {
  const SearchableSelectExample({super.key});

  @override
  State<SearchableSelectExample> createState() =>
      _SearchableSelectExampleState();
}

class _SearchableSelectExampleState extends State<SearchableSelectExample> {
  String? _selectedCountry;
  String? _selectedLanguage;
  final List<_SelectOption> _countries = [
    _SelectOption('US', 'United States', '🇺🇸'),
    _SelectOption('CA', 'Canada', '🇨🇦'),
    _SelectOption('GB', 'United Kingdom', '🇬🇧'),
    _SelectOption('DE', 'Germany', '🇩🇪'),
    _SelectOption('FR', 'France', '🇫🇷'),
    _SelectOption('IT', 'Italy', '🇮🇹'),
    _SelectOption('ES', 'Spain', '🇪🇸'),
    _SelectOption('JP', 'Japan', '🇯🇵'),
    _SelectOption('CN', 'China', '🇨🇳'),
    _SelectOption('AU', 'Australia', '🇦🇺'),
    _SelectOption('BR', 'Brazil', '🇧🇷'),
    _SelectOption('IN', 'India', '🇮🇳'),
  ];

  final List<_SelectOption> _languages = [
    _SelectOption('en', 'English', '🔤'),
    _SelectOption('es', 'Spanish', '🔡'),
    _SelectOption('fr', 'French', '🔠'),
    _SelectOption('de', 'German', '📝'),
    _SelectOption('it', 'Italian', '📋'),
    _SelectOption('pt', 'Portuguese', '📄'),
    _SelectOption('ru', 'Russian', '📃'),
    _SelectOption('ja', 'Japanese', '🈳'),
    _SelectOption('ko', 'Korean', '🈴'),
    _SelectOption('zh', 'Chinese', '🈂'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Searchable Select Components',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 32),
          _buildCountrySelect(),
          const SizedBox(height: 24),
          _buildLanguageSelect(),
          const SizedBox(height: 32),
          _buildSelectionSummary(),
        ],
      ),
    );
  }

  Widget _buildCountrySelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Country',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        _SearchableSelect(
          value: _selectedCountry,
          options: _countries,
          onChanged: (value) => setState(() => _selectedCountry = value),
          placeholder: 'Search and select country...',
          searchHint: 'Type country name',
        ),
      ],
    );
  }

  Widget _buildLanguageSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Language',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        _SearchableSelect(
          value: _selectedLanguage,
          options: _languages,
          onChanged: (value) => setState(() => _selectedLanguage = value),
          placeholder: 'Search and select language...',
          searchHint: 'Type language name',
        ),
      ],
    );
  }

  Widget _buildSelectionSummary() {
    if (_selectedCountry == null && _selectedLanguage == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Select country and language to see summary',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      );
    }

    final selectedCountry = _countries.firstWhere(
      (c) => c.value == _selectedCountry,
      orElse: () => _SelectOption('', 'None selected', ''),
    );
    final selectedLanguage = _languages.firstWhere(
      (l) => l.value == _selectedLanguage,
      orElse: () => _SelectOption('', 'None selected', ''),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selection Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Country: ${selectedCountry.icon} ${selectedCountry.label}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Language: ${selectedLanguage.icon} ${selectedLanguage.label}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectOption {
  final String value;
  final String label;
  final String icon;

  _SelectOption(this.value, this.label, this.icon);
}

class _SearchableSelect extends StatefulWidget {
  const _SearchableSelect({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.placeholder,
    required this.searchHint,
  });

  final String? value;
  final List<_SelectOption> options;
  final ValueChanged<String?> onChanged;
  final String placeholder;
  final String searchHint;

  @override
  State<_SearchableSelect> createState() => _SearchableSelectState();
}

class _SearchableSelectState extends State<_SearchableSelect> {
  bool _isOpen = false;
  bool _isFocused = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<_SelectOption> get _filteredOptions {
    if (_searchQuery.isEmpty) return widget.options;
    return widget.options.where((option) {
      return option.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          option.value.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  _SelectOption? get _selectedOption {
    if (widget.value == null) return null;
    return widget.options.firstWhere(
      (option) => option.value == widget.value,
      orElse: () => _SelectOption('', 'Unknown', ''),
    );
  }

  void _toggleOpen() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _selectOption(_SelectOption option) {
    widget.onChanged(option.value);
    setState(() {
      _isOpen = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NakedSelect<String>(
      selectedValue: widget.value,
      onSelectedValueChanged: widget.onChanged,
      closeOnSelect: true,
      overlay: _isOpen ? _buildMenu() : const SizedBox.shrink(),
      child: NakedSelectTrigger(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: _buildTrigger(),
      ),
    );
  }

  Widget _buildTrigger() {
    return GestureDetector(
      onTap: _toggleOpen,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isOpen
              ? Colors.blue.shade50
              : _isFocused
                  ? Colors.grey.shade50
                  : Colors.white,
          border: Border.all(
            color: _isOpen
                ? Colors.blue.shade600
                : _isFocused
                    ? Colors.grey.shade400
                    : Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (_isOpen)
              BoxShadow(
                color: Colors.blue.shade200.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_selectedOption != null) ...[
              Text(
                _selectedOption!.icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedOption!.label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ] else
              Expanded(
                child: Text(
                  widget.placeholder,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _isOpen ? 0.5 : 0,
              child: const Icon(
                Icons.expand_more,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchField(),
          const Divider(height: 1),
          _buildOptionsList(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: widget.searchHint,
          prefixIcon: const Icon(Icons.search, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          isDense: true,
        ),
        autofocus: true,
      ),
    );
  }

  Widget _buildOptionsList() {
    final filtered = _filteredOptions;

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final option = filtered[index];
          return _OptionItem(
            option: option,
            isSelected: option.value == widget.value,
            searchQuery: _searchQuery,
            onTap: () => _selectOption(option),
          );
        },
      ),
    );
  }
}

class _OptionItem extends StatefulWidget {
  const _OptionItem({
    required this.option,
    required this.isSelected,
    required this.searchQuery,
    required this.onTap,
  });

  final _SelectOption option;
  final bool isSelected;
  final String searchQuery;
  final VoidCallback onTap;

  @override
  State<_OptionItem> createState() => _OptionItemState();
}

class _OptionItemState extends State<_OptionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (_isHovered ? Colors.blue.shade100 : Colors.blue.shade50)
                : (_isHovered ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                widget.option.icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHighlightedText(),
              ),
              if (widget.isSelected)
                Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.blue.shade600,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText() {
    if (widget.searchQuery.isEmpty) {
      return Text(
        widget.option.label,
        style: TextStyle(
          fontSize: 14,
          color: widget.isSelected
              ? Colors.blue.shade700
              : const Color(0xFF1A1A1A),
        ),
      );
    }

    final text = widget.option.label;
    final query = widget.searchQuery.toLowerCase();
    final index = text.toLowerCase().indexOf(query);

    if (index == -1) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: widget.isSelected
              ? Colors.blue.shade700
              : const Color(0xFF1A1A1A),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, index),
            style: TextStyle(
              fontSize: 14,
              color: widget.isSelected
                  ? Colors.blue.shade700
                  : const Color(0xFF1A1A1A),
            ),
          ),
          TextSpan(
            text: text.substring(index, index + widget.searchQuery.length),
            style: TextStyle(
              fontSize: 14,
              color: widget.isSelected
                  ? Colors.blue.shade700
                  : const Color(0xFF1A1A1A),
              backgroundColor: Colors.yellow.shade200,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text.substring(index + widget.searchQuery.length),
            style: TextStyle(
              fontSize: 14,
              color: widget.isSelected
                  ? Colors.blue.shade700
                  : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
