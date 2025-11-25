import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
        child: SafeArea(
          child: audioServiceAsync.when(
            loading: () => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing audio...',
                    style: theme.textTheme.bodyMedium,
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
                    style: theme.textTheme.bodyLarge,
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
              // Load devices when service is first available
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
    final theme = Theme.of(context);
    return Column(
      children: [
        // Dynamic Output Selector
        Padding(
          padding: const EdgeInsets.fromLTRB(90, 30, 90, 0),
          child: _buildOutputSelector(audioService),
        ),

        const SizedBox(height: 80),

        // Power Control
        LayeredContainer(
          isActive: _isPlaying,
          onPowerPressed: () => _togglePlayback(audioService),
        ),

        const SizedBox(height: 20),

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
    final theme = Theme.of(context);
    // Fallback if no devices loaded yet
    if (_availableDevices.isEmpty) {
      return GestureDetector(
        onTap: () => _refreshDevices(audioService),
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
        value: _selectedDevice,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: theme.colorScheme.surface,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        items: _availableDevices.map((AudioDevice device) {
          return DropdownMenuItem<AudioDevice>(
            value: device,
            child: Text(device.name),
          );
        }).toList(),

        onChanged: (AudioDevice? device) async {
          if (device != null && device != _selectedDevice) {
            if (kDebugMode) {
              print("User selected: ${device.name}");
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
                  backgroundColor: theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
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
              color: isActive ? Colors.white : theme.iconTheme.color,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showWaveSelector(AudioService audio) {
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
