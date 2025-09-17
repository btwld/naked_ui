import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

class SwitchExample extends StatefulWidget {
  const SwitchExample({super.key});

  @override
  State<SwitchExample> createState() => _SwitchExampleState();
}

class _SwitchExampleState extends State<SwitchExample> {
  bool _airplaneMode = false;
  bool _wifi = true;
  bool _bluetooth = false;
  bool _locationServices = true;

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          NakedToggle(
            value: value,
            asSwitch: true, // Switch semantics
            onChanged: onChanged,
            semanticLabel: title,
            builder: (context, states, child) {
              final isSelected = states.contains(WidgetState.selected);
              final isHovered = states.contains(WidgetState.hovered);
              final isFocused = states.contains(WidgetState.focused);
              final isDisabled = states.contains(WidgetState.disabled);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDisabled
                      ? Colors.grey.shade300
                      : isSelected
                          ? Colors.green.shade500
                          : Colors.grey.shade400,
                  border: isFocused
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                  boxShadow: isHovered && !isDisabled
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      isSelected ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch Example'),
        backgroundColor: Colors.grey.shade50,
      ),
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connectivity Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildSwitchRow(
                title: 'Airplane Mode',
                subtitle: 'Disable all wireless connections',
                value: _airplaneMode,
                onChanged: (value) => setState(() => _airplaneMode = value),
                icon: Icons.airplanemode_active,
              ),
              const Divider(height: 1),
              _buildSwitchRow(
                title: 'Wi-Fi',
                subtitle: 'Connect to wireless networks',
                value: _wifi,
                onChanged: (value) => setState(() => _wifi = value),
                icon: Icons.wifi,
              ),
              const Divider(height: 1),
              _buildSwitchRow(
                title: 'Bluetooth',
                subtitle: 'Connect to nearby devices',
                value: _bluetooth,
                onChanged: (value) => setState(() => _bluetooth = value),
                icon: Icons.bluetooth,
              ),
              const Divider(height: 1),
              _buildSwitchRow(
                title: 'Location Services',
                subtitle: 'Allow apps to access your location',
                value: _locationServices,
                onChanged: (value) => setState(() => _locationServices = value),
                icon: Icons.location_on,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
