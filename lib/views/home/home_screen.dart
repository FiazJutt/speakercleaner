import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../services/audio_service.dart';
import 'widgets/layered_container.dart';
import 'widgets/wave_selector.dart';

// Audio service provider
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  service.initialize();
  return service;
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isPlaying = false;
  bool _turboMode = false;

  String _selectedOutput = "Bottom Speaker"; // Default route
  WaveType _selectedWave = WaveType.sine;
  bool _isCleanerMode = false;
  String _activeAction = '';

  final List<String> _availableOutputs = [
    "Bottom Speaker",
    "Top Earpiece",
    "Bluetooth / Headset (Auto)",
  ];

  @override
  Widget build(BuildContext context) {
    final audioService = ref.read(audioServiceProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientBlueStart, AppColors.gradientBlueEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Output Selector (Speaker / Earpiece)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
                child: _buildOutputSelector(audioService),
              ),

              const SizedBox(height: 40),

              // Power Control
              LayeredContainer(
                isActive: _isPlaying,
                onPowerPressed: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });

                  if (_isPlaying) {
                    if (_isCleanerMode) {
                      audioService.playCleaner();
                    } else {
                      audioService.play();
                    }
                  } else {
                    audioService.stop();
                  }
                },
              ),

              const SizedBox(height: 20),

              // Turbo Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: _buildTurboToggle(),
              ),

              const Spacer(),

              // Bottom Navigation Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: _buildActionButtons(audioService),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // OUTPUT SELECTOR (Speaker / Earpiece dropdown)
  // ---------------------------------------------------------
  Widget _buildOutputSelector(AudioService audio) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: _selectedOutput,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.gradientBlueEnd,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        items: _availableOutputs.map((String label) {
          return DropdownMenuItem<String>(
            value: label,
            child: Row(
              children: [
                const Icon(Icons.speaker, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedOutput = value);

            audio.selectOutput(value);
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // TURBO TOGGLE
  // ---------------------------------------------------------
  Widget _buildTurboToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _turboMode = !_turboMode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _turboMode
              ? AppColors.turboOrange.withOpacity(0.3)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _turboMode
                ? AppColors.turboOrange
                : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt,
              color: _turboMode ? AppColors.turboOrange : Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              "Turbo",
              style: TextStyle(
                color: _turboMode ? AppColors.turboOrange : Colors.white,
                fontSize: 12,
                fontWeight: _turboMode ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // BOTTOM ACTION BUTTONS
  // ---------------------------------------------------------
  Widget _buildActionButtons(AudioService audioService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Cleaner Mode
        _buildIconButton(
          icon: Icons.cleaning_services,
          label: 'Cleaner',
          isActive: _activeAction == 'cleaner',
          onTap: () {
            setState(() {
              _activeAction = 'cleaner';
              _isCleanerMode = true;
            });
          },
        ),

        // Waves
        _buildIconButton(
          icon: Icons.graphic_eq,
          label: 'Waves',
          isActive: _activeAction == 'waves',
          onTap: () {
            setState(() {
              _activeAction = 'waves';
              _isCleanerMode = false;
            });
            _showWaveSelector(audioService);
          },
        ),

        // Settings (future use)
        _buildIconButton(
          icon: Icons.settings,
          label: 'Settings',
          isActive: _activeAction == 'settings',
          onTap: () {
            setState(() => _activeAction = 'settings');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Settings coming soon")),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.gradientBlueEnd : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // WAVE SELECTOR MODAL
  // ---------------------------------------------------------
  void _showWaveSelector(AudioService audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.gradientBlueEnd,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: WaveSelector(
          selectedWave: _selectedWave,
          onWaveSelected: (wave) {
            setState(() => _selectedWave = wave);
            audio.setWaveType(wave);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
