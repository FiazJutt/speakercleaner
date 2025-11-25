import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../settings/settings_screen.dart';
import 'widgets/layered_container.dart';
import 'widgets/wave_selector.dart';

// Audio service provider - properly initialized
final audioServiceProvider = FutureProvider<AudioService>((ref) async {
  final service = AudioService();
  await service.initialize();
  return service;
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isPlaying = false;
  bool _isCleanerMode = false;
  String _activeAction = '';
  WaveType _selectedWave = WaveType.sine;

  // Dynamic device list from native
  List<AudioDevice> _availableDevices = [];
  AudioDevice? _selectedDevice;

  // Track if initial device load has been done
  bool _initialLoadDone = false;

  @override
  Widget build(BuildContext context) {
    final audioServiceAsync = ref.watch(audioServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Container(
        decoration: const BoxDecoration(color: AppColors.backgroundLight),
        child: SafeArea(
          child: audioServiceAsync.when(
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryLight),
                  SizedBox(height: 16),
                  Text(
                    'Initializing audio...',
                    style: TextStyle(color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            error: (e, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $e',
                    style: const TextStyle(color: AppColors.textPrimaryLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(audioServiceProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (audioService) {
              // ✅ Load devices when service is first available
              _syncDevicesFromService(audioService);
              return _buildContent(audioService);
            },
          ),
        ),
      ),
    );
  }

  /// Sync local state with AudioService's already-loaded devices
  void _syncDevicesFromService(AudioService audioService) {
    if (!_initialLoadDone) {
      _initialLoadDone = true;

      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _availableDevices = audioService.availableDevices;
            _selectedDevice = audioService.selectedDevice;
          });
        }
      });
    }
  }

  Widget _buildContent(AudioService audioService) {
    return Column(
      children: [
        // Dynamic Output Selector
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
          child: Row(
            children: [
              Expanded(child: _buildOutputSelector(audioService)),
              const SizedBox(width: 8),

              // Refresh button
              _buildRefreshButton(audioService),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Power Control
        LayeredContainer(
          isActive: _isPlaying,
          onPowerPressed: () => _togglePlayback(audioService),
        ),

        const SizedBox(height: 20),

        // Debug info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔊 Current: ${_selectedDevice?.name ?? "None"}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '📱 Devices: ${_availableDevices.length} found',
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '▶️ Playing: $_isPlaying',
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Bottom Navigation Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: _buildActionButtons(audioService),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  void _togglePlayback(AudioService audioService) async {
    setState(() => _isPlaying = !_isPlaying);

    if (_isPlaying) {
      if (_isCleanerMode) {
        await audioService.playCleaner();
      } else {
        await audioService.play();
      }
    } else {
      await audioService.stop();
    }
  }

  // Dynamic Output Selector with real devices
  Widget _buildOutputSelector(AudioService audioService) {
    // Fallback if no devices loaded yet
    if (_availableDevices.isEmpty) {
      return GestureDetector(
        onTap: () => _refreshDevices(audioService),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              SizedBox(width: 8),
              Text(
                "Tap to load devices...",
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButton<AudioDevice>(
        value: _selectedDevice,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.surfaceLight,
        icon: const Icon(
          Icons.arrow_drop_down,
          color: AppColors.textPrimaryLight,
          size: 18,
        ),
        style: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        items: _availableDevices.map((AudioDevice device) {
          return DropdownMenuItem<AudioDevice>(
            value: device,
            child: Row(
              children: [
                Icon(
                  _getDeviceIcon(device.type),
                  color: AppColors.textPrimaryLight,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        onChanged: (AudioDevice? device) async {
          if (device != null && device != _selectedDevice) {
            if (kDebugMode) {
              print("📱 User selected: ${device.name}");
            }

            setState(() => _selectedDevice = device);

            // Show switching indicator
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text("Switching to ${device.name}..."),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.primaryLight,
                ),
              );
            }

            // Switch device with proper handling
            final success = await audioService.switchDevice(device);

            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        success ? Icons.check_circle : Icons.error,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        success
                            ? "Now using ${device.name}"
                            : "Failed to switch to ${device.name}",
                      ),
                    ],
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildRefreshButton(AudioService audioService) {
    return GestureDetector(
      onTap: () => _refreshDevices(audioService),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12, width: 1),
        ),
        child: const Icon(
          Icons.refresh,
          color: AppColors.textPrimaryLight,
          size: 20,
        ),
      ),
    );
  }

  Future<void> _refreshDevices(AudioService audioService) async {
    final devices = await audioService.refreshAvailableDevices();
    if (mounted) {
      setState(() {
        _availableDevices = devices;
        _selectedDevice = audioService.selectedDevice;
      });
    }
  }

  IconData _getDeviceIcon(int type) {
    switch (type) {
      case AudioDeviceType.TYPE_BUILTIN_SPEAKER:
        return Icons.speaker;
      case AudioDeviceType.TYPE_BUILTIN_EARPIECE:
        return Icons.phone_in_talk;
      case AudioDeviceType.TYPE_WIRED_HEADSET:
      case AudioDeviceType.TYPE_WIRED_HEADPHONES:
        return Icons.headphones;
      case AudioDeviceType.TYPE_BLUETOOTH_A2DP:
      case AudioDeviceType.TYPE_BLUETOOTH_SCO:
        return Icons.bluetooth_audio;
      case AudioDeviceType.TYPE_USB_DEVICE:
      case AudioDeviceType.TYPE_USB_HEADSET:
        return Icons.usb;
      default:
        return Icons.speaker;
    }
  }

  Widget _buildActionButtons(AudioService audioService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildIconButton(
          icon: Icons.cleaning_services,
          label: 'Cleaner',
          isActive: _activeAction == 'cleaner',
          onTap: () {
            setState(() {
              _activeAction = 'cleaner';
              _isCleanerMode = true;
            });
            if (_isPlaying) {
              audioService.stop();
              audioService.playCleaner();
            }
          },
        ),
        _buildIconButton(
          icon: Icons.graphic_eq,
          label: 'Waves',
          isActive: _activeAction == 'waves',
          onTap: () {
            setState(() {
              _activeAction = 'waves';
              _isCleanerMode = false;
            });
            if (_isPlaying) {
              audioService.stop();
              audioService.play();
            }
            _showWaveSelector(audioService);
          },
        ),
        _buildIconButton(
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
              color: isActive ? AppColors.primaryLight : AppColors.surfaceLight,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primaryLight.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textSecondaryLight,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? AppColors.primaryLight
                  : AppColors.textSecondaryLight,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showWaveSelector(AudioService audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: WaveSelector(
          selectedWave: _selectedWave,
          onWaveSelected: (wave) {
            setState(() => _selectedWave = wave);
            audio.setWaveType(wave);
            if (_isPlaying && !_isCleanerMode) {
              audio.stop();
              audio.play();
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
