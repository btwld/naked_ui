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
          child: RadioGroupExample(),
        ),
      ),
    );
  }
}

class RadioGroupExample extends StatefulWidget {
  const RadioGroupExample({super.key});

  @override
  State<RadioGroupExample> createState() => _RadioGroupExampleState();
}

class _RadioGroupExampleState extends State<RadioGroupExample> {
  // Primary example
  String? _selectedPriority = 'medium';
  
  // Settings example
  String? _selectedTheme = 'system';
  
  // Notification example
  String? _selectedNotification = 'push';
  
  // User type example
  String? _selectedUserType;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Radio Group Examples',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Single selection from multiple options',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Priority selection
          _PriorityRadioGroup(
            selectedValue: _selectedPriority,
            onChanged: (value) => setState(() => _selectedPriority = value),
          ),
          
          const SizedBox(height: 24),
          
          // Theme selection
          _ThemeRadioGroup(
            selectedValue: _selectedTheme,
            onChanged: (value) => setState(() => _selectedTheme = value),
          ),
          
          const SizedBox(height: 24),
          
          // Notification settings
          _NotificationRadioGroup(
            selectedValue: _selectedNotification,
            onChanged: (value) => setState(() => _selectedNotification = value),
          ),
          
          const SizedBox(height: 24),
          
          // User type with validation
          _UserTypeRadioGroup(
            selectedValue: _selectedUserType,
            onChanged: (value) => setState(() => _selectedUserType = value),
          ),
          
          const SizedBox(height: 32),
          
          // Selection summary
          _SelectionSummary(
            priority: _selectedPriority,
            theme: _selectedTheme,
            notification: _selectedNotification,
            userType: _selectedUserType,
          ),
          
          const SizedBox(height: 24),
          
          // Radio group benefits
          const _RadioGroupBenefits(),
        ],
      ),
    );
  }
}

class _PriorityRadioGroup extends StatelessWidget {
  const _PriorityRadioGroup({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final priorities = [
      {
        'value': 'low',
        'title': 'Low Priority',
        'subtitle': 'Can wait for later resolution',
        'color': const Color(0xFF4CAF50),
        'icon': Icons.keyboard_arrow_down,
      },
      {
        'value': 'medium',
        'title': 'Medium Priority',
        'subtitle': 'Should be addressed soon',
        'color': const Color(0xFFFF9800),
        'icon': Icons.remove,
      },
      {
        'value': 'high',
        'title': 'High Priority',
        'subtitle': 'Needs immediate attention',
        'color': const Color(0xFFF44336),
        'icon': Icons.keyboard_arrow_up,
      },
      {
        'value': 'critical',
        'title': 'Critical Priority',
        'subtitle': 'Urgent and blocking issues',
        'color': const Color(0xFF9C27B0),
        'icon': Icons.warning,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.priority_high,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Task Priority',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NakedRadioGroup<String>(
            groupValue: selectedValue,
            onChanged: onChanged,
            child: Column(
              children: priorities.map((priority) {
                return _RadioTile(
                  value: priority['value'] as String,
                  title: priority['title'] as String,
                  subtitle: priority['subtitle'] as String,
                  color: priority['color'] as Color,
                  icon: priority['icon'] as IconData,
                  isSelected: selectedValue == priority['value'],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeRadioGroup extends StatelessWidget {
  const _ThemeRadioGroup({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final themes = [
      {
        'value': 'light',
        'title': 'Light Theme',
        'subtitle': 'Bright and clean appearance',
        'color': const Color(0xFFFFC107),
        'icon': Icons.light_mode,
      },
      {
        'value': 'dark',
        'title': 'Dark Theme',
        'subtitle': 'Easy on the eyes in low light',
        'color': const Color(0xFF424242),
        'icon': Icons.dark_mode,
      },
      {
        'value': 'system',
        'title': 'System Theme',
        'subtitle': 'Follow device settings',
        'color': const Color(0xFF2196F3),
        'icon': Icons.settings_system_daydream,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'App Theme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NakedRadioGroup<String>(
            groupValue: selectedValue,
            onChanged: onChanged,
            child: Column(
              children: themes.map((theme) {
                return _RadioTile(
                  value: theme['value'] as String,
                  title: theme['title'] as String,
                  subtitle: theme['subtitle'] as String,
                  color: theme['color'] as Color,
                  icon: theme['icon'] as IconData,
                  isSelected: selectedValue == theme['value'],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRadioGroup extends StatelessWidget {
  const _NotificationRadioGroup({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'value': 'push',
        'title': 'Push Notifications',
        'subtitle': 'Instant alerts on your device',
        'color': const Color(0xFF4CAF50),
        'icon': Icons.notifications_active,
      },
      {
        'value': 'email',
        'title': 'Email Only',
        'subtitle': 'Receive notifications via email',
        'color': const Color(0xFF2196F3),
        'icon': Icons.email,
      },
      {
        'value': 'none',
        'title': 'No Notifications',
        'subtitle': 'Silent mode, check manually',
        'color': const Color(0xFF757575),
        'icon': Icons.notifications_off,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Notification Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NakedRadioGroup<String>(
            groupValue: selectedValue,
            onChanged: onChanged,
            child: Column(
              children: notifications.map((notification) {
                return _RadioTile(
                  value: notification['value'] as String,
                  title: notification['title'] as String,
                  subtitle: notification['subtitle'] as String,
                  color: notification['color'] as Color,
                  icon: notification['icon'] as IconData,
                  isSelected: selectedValue == notification['value'],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTypeRadioGroup extends StatelessWidget {
  const _UserTypeRadioGroup({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  bool get hasSelection => selectedValue != null;

  @override
  Widget build(BuildContext context) {
    final userTypes = [
      {
        'value': 'student',
        'title': 'Student',
        'subtitle': 'Academic or learning purposes',
        'color': const Color(0xFF2196F3),
        'icon': Icons.school,
      },
      {
        'value': 'professional',
        'title': 'Professional',
        'subtitle': 'Business or work-related use',
        'color': const Color(0xFF4CAF50),
        'icon': Icons.work,
      },
      {
        'value': 'personal',
        'title': 'Personal Use',
        'subtitle': 'Individual or hobby projects',
        'color': const Color(0xFFFF9800),
        'icon': Icons.person,
      },
      {
        'value': 'organization',
        'title': 'Organization',
        'subtitle': 'Team or company account',
        'color': const Color(0xFF9C27B0),
        'icon': Icons.business,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasSelection ? Colors.purple.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSelection ? Colors.purple.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSelection ? Icons.person_outline : Icons.error_outline,
                color: hasSelection ? Colors.purple.shade700 : Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'User Type (Required)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasSelection ? Colors.purple.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NakedRadioGroup<String>(
            groupValue: selectedValue,
            onChanged: onChanged,
            child: Column(
              children: userTypes.map((userType) {
                return _RadioTile(
                  value: userType['value'] as String,
                  title: userType['title'] as String,
                  subtitle: userType['subtitle'] as String,
                  color: userType['color'] as Color,
                  icon: userType['icon'] as IconData,
                  isSelected: selectedValue == userType['value'],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasSelection ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasSelection ? Colors.green.shade300 : Colors.red.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasSelection ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: hasSelection ? Colors.green.shade700 : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasSelection
                        ? 'User type selected successfully!'
                        : 'Please select a user type to continue.',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasSelection ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioTile extends StatefulWidget {
  const _RadioTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.isSelected,
  });

  final String value;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isSelected;

  @override
  State<_RadioTile> createState() => _RadioTileState();
}

class _RadioTileState extends State<_RadioTile> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  Color get backgroundColor {
    if (widget.isSelected) {
      return widget.color.withValues(alpha: 0.1);
    }
    if (_isPressed) {
      return Colors.grey.shade200;
    }
    if (_isHovered) {
      return Colors.grey.shade100;
    }
    return Colors.transparent;
  }

  Color get borderColor {
    if (widget.isSelected) {
      return widget.color;
    }
    if (_isFocused) {
      return widget.color.withValues(alpha: 0.8);
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NakedRadio<String>(
        value: widget.value,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        onHoverChange: (hovered) => setState(() => _isHovered = hovered),
        onPressChange: (pressed) => setState(() => _isPressed = pressed),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio button indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected ? widget.color : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.color,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isSelected 
                    ? widget.color.withValues(alpha: 0.2)
                    : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isSelected ? widget.color : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected 
                          ? widget.color 
                          : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isSelected 
                          ? widget.color.withValues(alpha: 0.8)
                          : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selection indicator
              if (widget.isSelected)
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: widget.color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.priority,
    required this.theme,
    required this.notification,
    required this.userType,
  });

  final String? priority;
  final String? theme;
  final String? notification;
  final String? userType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt,
                color: Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Selection Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryItem(
            label: 'Priority',
            value: priority ?? 'Not selected',
            hasValue: priority != null,
          ),
          _SummaryItem(
            label: 'Theme',
            value: theme ?? 'Not selected',
            hasValue: theme != null,
          ),
          _SummaryItem(
            label: 'Notifications',
            value: notification ?? 'Not selected',
            hasValue: notification != null,
          ),
          _SummaryItem(
            label: 'User Type',
            value: userType ?? 'Not selected (Required)',
            hasValue: userType != null,
            isRequired: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.hasValue,
    this.isRequired = false,
  });

  final String label;
  final String value;
  final bool hasValue;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: hasValue 
                ? Colors.green.shade100
                : (isRequired ? Colors.red.shade100 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasValue 
                  ? Colors.green.shade300
                  : (isRequired ? Colors.red.shade300 : Colors.grey.shade300),
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasValue 
                  ? Colors.green.shade800
                  : (isRequired ? Colors.red.shade800 : Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioGroupBenefits extends StatelessWidget {
  const _RadioGroupBenefits();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radio_button_checked,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Radio Group Benefits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.check_circle_outline,
            title: 'Mutually Exclusive',
            description: 'Only one option can be selected at a time',
          ),
          const _BenefitItem(
            icon: Icons.group,
            title: 'Group Management',
            description: 'Automatic state synchronization across all radio buttons',
          ),
          const _BenefitItem(
            icon: Icons.accessibility,
            title: 'Screen Reader Support',
            description: 'Proper semantics for assistive technologies',
          ),
          const _BenefitItem(
            icon: Icons.keyboard,
            title: 'Keyboard Navigation',
            description: 'Arrow keys navigate between options in the group',
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}