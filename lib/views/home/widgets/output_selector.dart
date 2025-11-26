import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../services/audio_service.dart';

class OutputSelector extends StatelessWidget {
  final List<AudioDevice> availableDevices;
  final AudioDevice? selectedDevice;
  final AudioService audioService;
  final Function(AudioDevice?) onDeviceChanged;
  final VoidCallback onRefreshDevices;

  const OutputSelector({
    super.key,
    required this.availableDevices,
    required this.selectedDevice,
    required this.audioService,
    required this.onDeviceChanged,
    required this.onRefreshDevices,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fallback if no devices loaded yet
    if (availableDevices.isEmpty) {
      return GestureDetector(
        onTap: onRefreshDevices,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(width: 8),
              Text("Tap to load devices...", style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    return Container(
      child: DropdownButton<AudioDevice>(
        isDense: true,
        alignment: Alignment.center,
        iconSize: 30,
        icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
        value: selectedDevice,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: theme.colorScheme.surface,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        items: availableDevices.map((AudioDevice device) {
          return DropdownMenuItem<AudioDevice>(
            value: device,
            child: Text(device.name),
          );
        }).toList(),
        onChanged: onDeviceChanged,
      ),
    );
  }
}
