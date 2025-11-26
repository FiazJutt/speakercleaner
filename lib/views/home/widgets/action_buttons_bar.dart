import 'package:flutter/material.dart';

import '../../../services/audio_service.dart';
import '../../settings/settings_screen.dart';
import 'action_button.dart';
import 'wave_selector.dart';

class ActionButtonsBar extends StatelessWidget {
  final String activeAction;
  final bool isPlaying;
  final WaveType selectedWave;
  final AudioService audioService;
  final Function(String) onActionChanged;
  final Function(WaveType) onWaveSelected;

  const ActionButtonsBar({
    super.key,
    required this.activeAction,
    required this.isPlaying,
    required this.selectedWave,
    required this.audioService,
    required this.onActionChanged,
    required this.onWaveSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ActionButton(
          icon: Icons.cleaning_services,
          label: 'Cleaner',
          isActive: activeAction == 'cleaner',
          onTap: () {
            onActionChanged('cleaner');
            if (isPlaying) {
              audioService.stop();
              audioService.playCleaner();
            }
          },
        ),
        ActionButton(
          icon: Icons.graphic_eq,
          label: 'Waves',
          isActive: activeAction == 'waves',
          onTap: () {
            onActionChanged('waves');
            if (isPlaying) {
              audioService.stop();
              audioService.play();
            }
            _showWaveSelector(context);
          },
        ),
        ActionButton(
          icon: Icons.settings,
          label: 'Settings',
          isActive: false,
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  void _showWaveSelector(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: WaveSelector(
          selectedWave: selectedWave,
          onWaveSelected: (wave) {
            onWaveSelected(wave);
            audioService.setWaveType(wave);
            if (isPlaying && activeAction != 'cleaner') {
              audioService.stop();
              audioService.play();
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
