import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
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
        _buildWaveOption(WaveType.sine, 'Sine', Icons.waves),
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
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
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
              color: isSelected ? AppColors.gradientBlueEnd : Colors.white70,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.gradientBlueEnd : Colors.white70,
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
