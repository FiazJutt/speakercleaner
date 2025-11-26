import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio_service.dart';
import 'widgets/action_buttons_bar.dart';
import 'widgets/layered_container.dart';
import 'widgets/output_selector.dart';

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
  WaveType _selectedWave = WaveType.sine1;

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
          child: OutputSelector(
            availableDevices: _availableDevices,
            selectedDevice: _selectedDevice,
            audioService: audioService,
            onDeviceChanged: (device) =>
                _handleDeviceChange(device, audioService),
            onRefreshDevices: () => _refreshDevices(audioService),
          ),
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
          child: ActionButtonsBar(
            activeAction: _activeAction,
            isPlaying: _isPlaying,
            selectedWave: _selectedWave,
            audioService: audioService,
            onActionChanged: (action) {
              setState(() {
                _activeAction = action;
                _isCleanerMode = action == 'cleaner';
              });
            },
            onWaveSelected: (wave) {
              setState(() => _selectedWave = wave);
            },
          ),
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

  Future<void> _handleDeviceChange(
    AudioDevice? device,
    AudioService audioService,
  ) async {
    if (device != null && device != _selectedDevice) {
      if (kDebugMode) {
        print("User selected: ${device.name}");
      }

      setState(() => _selectedDevice = device);

      final theme = Theme.of(context);

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
}
