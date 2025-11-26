import 'package:flutter/material.dart';

import '../../../services/audio_service.dart';

class WaveSelector extends StatelessWidget {
  final WaveType selectedWave;
  final Function(WaveType) onWaveSelected;
  final bool isPremium;

  const WaveSelector({
    super.key,
    required this.selectedWave,
    required this.onWaveSelected,
    this.isPremium = false,
  });

  bool _isWaveLocked(WaveType wave) {
    // Sine1 is free, all others require premium
    return !isPremium && wave != WaveType.sine1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Select Wave Type',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Wave options in a vertical list for better spacing
          _buildWaveOption(
            context,
            WaveType.sine1,
            'Sine Wave 1',
            Icons.waves,
            'Clean & smooth frequency',
          ),
          const SizedBox(height: 12),
          _buildWaveOption(
            context,
            WaveType.sine2,
            'Sine Wave 2',
            Icons.waves,
            'Alternative sine pattern',
          ),
          const SizedBox(height: 12),
          _buildWaveOption(
            context,
            WaveType.square,
            'Square Wave',
            Icons.graphic_eq,
            'Sharp & precise output',
          ),
          const SizedBox(height: 12),
          _buildWaveOption(
            context,
            WaveType.sawtooth,
            'Sawtooth Wave',
            Icons.show_chart,
            'Linear gradient wave',
          ),

          const SizedBox(height: 16),

          // Premium note if not premium
          if (!isPremium)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unlock all wave types with Premium',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
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

  Widget _buildWaveOption(
    BuildContext context,
    WaveType wave,
    String label,
    IconData icon,
    String description,
  ) {
    final theme = Theme.of(context);
    final isSelected = selectedWave == wave;
    final isLocked = _isWaveLocked(wave);

    return GestureDetector(
      onTap: () => onWaveSelected(wave),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : theme.iconTheme.color,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Lock icon or checkmark
            if (isLocked)
              Icon(
                Icons.lock,
                color: isSelected
                    ? Colors.white.withOpacity(0.7)
                    : theme.iconTheme.color?.withOpacity(0.5),
                size: 20,
              )
            else if (isSelected)
              Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
