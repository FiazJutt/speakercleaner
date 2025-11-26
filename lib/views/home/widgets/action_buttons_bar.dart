import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakercleaner/views/settings/settings_screen.dart';

import '../../../services/audio_service.dart';
import '../../../viewmodels/subscription_provider.dart';
import '../../paywall/premium_paywall_screen.dart';
import 'action_button.dart';
import 'wave_selector.dart';

class ActionButtonsBar extends ConsumerWidget {
  final bool isPlaying;
  final WaveType selectedWave;
  final AudioService audioService;
  final Function(WaveType) onWaveSelected;

  const ActionButtonsBar({
    super.key,
    required this.isPlaying,
    required this.selectedWave,
    required this.audioService,
    required this.onWaveSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Selected Wave Indicator (Always Active)
        ActionButton(
          icon: _getWaveIcon(selectedWave),
          label: _getWaveLabel(selectedWave),
          isActive: true,
          onTap: () {
            // Optional: Could also open wave selector here if desired
            _showWaveSelector(context, subscriptionService.isPremium);
          },
        ),
        // Wave Selector Trigger (Never Active)
        ActionButton(
          icon: Icons.graphic_eq,
          label: 'Waves',
          isActive: false,
          onTap: () {
            _showWaveSelector(context, subscriptionService.isPremium);
          },
        ),
        ActionButton(
          icon: Icons.settings,
          label: 'Settings',
          isActive: false,
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  String _getWaveLabel(WaveType wave) {
    switch (wave) {
      case WaveType.sine1:
        return 'Sine 1';
      case WaveType.sine2:
        return 'Sine 2';
      case WaveType.square:
        return 'Square';
      case WaveType.sawtooth:
        return 'Sawtooth';
    }
  }

  IconData _getWaveIcon(WaveType wave) {
    switch (wave) {
      case WaveType.sine1:
      case WaveType.sine2:
        return Icons.waves;
      case WaveType.square:
        return Icons.graphic_eq;
      case WaveType.sawtooth:
        return Icons.show_chart;
    }
  }

  void _showWaveSelector(BuildContext context, bool isPremium) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: WaveSelector(
          selectedWave: selectedWave,
          isPremium: isPremium,
          onWaveSelected: (wave) {
            // Check if wave is locked
            if (!isPremium && wave != WaveType.sine1) {
              // Close wave selector
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please upgrade or start trial to use this feature.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              // Show paywall
              _showPaywall(context);
              return;
            }

            onWaveSelected(wave);
            audioService.setWaveType(wave);
            if (isPlaying) {
              audioService.stop();
              audioService.play();
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PremiumPaywallScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}
