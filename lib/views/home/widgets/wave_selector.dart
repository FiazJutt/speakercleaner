import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/audio_service.dart';

class WaveSelector extends StatelessWidget {
  final WaveType selectedWave;
  final Function(WaveType) onWaveSelected;

  const WaveSelector({
    super.key,
    required this.selectedWave,
    required this.onWaveSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildWaveOption(WaveType.sine1, 'Sine1', Icons.waves),
        _buildWaveOption(WaveType.sine2, 'Sin2', Icons.waves),
        _buildWaveOption(WaveType.square, 'Square', Icons.graphic_eq),
        _buildWaveOption(WaveType.sawtooth, 'Sawtooth', Icons.show_chart),
      ],
    );
  }

  Widget _buildWaveOption(WaveType wave, String label, IconData icon) {
    final isSelected = selectedWave == wave;

    return GestureDetector(
      onTap: () => onWaveSelected(wave),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.black12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondaryLight,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
