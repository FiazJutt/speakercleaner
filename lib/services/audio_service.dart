import 'dart:async';

import 'package:audio_session/audio_session.dart' as audio_session_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

enum WaveType { sine, square, sawtooth }

class AudioDevice {
  final int id;
  final int type;
  final String name;
  final String productName;

  AudioDevice({
    required this.id,
    required this.type,
    required this.name,
    required this.productName,
  });

  factory AudioDevice.fromMap(Map<dynamic, dynamic> map) {
    return AudioDevice(
      id: map['id'] as int? ?? 0,
      type: map['type'] as int? ?? 0,
      name: map['name'] as String? ?? 'Unknown',
      productName: map['productName'] as String? ?? 'Unknown',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() => 'AudioDevice(id: $id, type: $type, name: $name)';
}

class AudioDeviceType {
  static const int TYPE_BUILTIN_SPEAKER = 2;
  static const int TYPE_BUILTIN_EARPIECE = 1;
  static const int TYPE_WIRED_HEADSET = 3;
  static const int TYPE_WIRED_HEADPHONES = 4;
  static const int TYPE_BLUETOOTH_A2DP = 8;
  static const int TYPE_BLUETOOTH_SCO = 7;
  static const int TYPE_USB_DEVICE = 11;
  static const int TYPE_USB_HEADSET = 22;
}

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isCleanerMode = false;
  WaveType _currentWave = WaveType.sine;
  double _frequency = 165.0;

  bool get isPlaying => _isPlaying;
  WaveType get currentWave => _currentWave;
  double get frequency => _frequency;

  static const MethodChannel _routingChannel = MethodChannel(
    "com.example.speakercleaner/routing",
  );

  AudioDevice? _selectedDevice;
  AudioDevice? get selectedDevice => _selectedDevice;

  List<AudioDevice> _availableDevices = [];
  List<AudioDevice> get availableDevices => _availableDevices;

  late audio_session_pkg.AudioSession _audioSession;

  Future<void> initialize() async {
    _audioSession = await audio_session_pkg.AudioSession.instance;

    // Default: Configure for SPEAKER (media playback)
    await _configureForSpeaker();

    await refreshAvailableDevices();

    if (kDebugMode) {
      print("🎵 AudioService initialized");
      print("🎵 Available devices: $_availableDevices");
    }
  }

  /// Configure audio session for SPEAKER output
  Future<void> _configureForSpeaker() async {
    if (kDebugMode) print("🔧 Configuring audio session for SPEAKER");

    await _audioSession.configure(
      const audio_session_pkg.AudioSessionConfiguration(
        avAudioSessionCategory:
            audio_session_pkg.AVAudioSessionCategory.playback,
        avAudioSessionMode: audio_session_pkg.AVAudioSessionMode.defaultMode,
        androidAudioAttributes: audio_session_pkg.AndroidAudioAttributes(
          contentType: audio_session_pkg.AndroidAudioContentType.music,
          usage: audio_session_pkg.AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType:
            audio_session_pkg.AndroidAudioFocusGainType.gain,
      ),
    );
  }

  /// Configure audio session for EARPIECE output
  Future<void> _configureForEarpiece() async {
    if (kDebugMode) print("🔧 Configuring audio session for EARPIECE");

    await _audioSession.configure(
      const audio_session_pkg.AudioSessionConfiguration(
        avAudioSessionCategory:
            audio_session_pkg.AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            audio_session_pkg.AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: audio_session_pkg.AVAudioSessionMode.voiceChat,
        androidAudioAttributes: audio_session_pkg.AndroidAudioAttributes(
          contentType: audio_session_pkg.AndroidAudioContentType.speech,
          usage: audio_session_pkg.AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType:
            audio_session_pkg.AndroidAudioFocusGainType.gain,
      ),
    );
  }

  Future<List<AudioDevice>> refreshAvailableDevices() async {
    try {
      final List<dynamic>? result = await _routingChannel.invokeMethod(
        'getAvailableDevices',
      );

      if (result != null) {
        _availableDevices = result
            .map((e) => AudioDevice.fromMap(e as Map<dynamic, dynamic>))
            .toList();

        if (_selectedDevice == null && _availableDevices.isNotEmpty) {
          _selectedDevice = _availableDevices.firstWhere(
            (d) => d.type == AudioDeviceType.TYPE_BUILTIN_SPEAKER,
            orElse: () => _availableDevices.first,
          );
        }

        if (kDebugMode) {
          print("🔊 Found ${_availableDevices.length} audio devices:");
          for (var device in _availableDevices) {
            print("   - ${device.name} (type: ${device.type})");
          }
        }
      }

      return _availableDevices;
    } catch (e) {
      if (kDebugMode) print("❌ Error getting devices: $e");
      return [];
    }
  }

  /// Set audio output device
  Future<bool> setAudioDevice(AudioDevice device) async {
    try {
      if (kDebugMode) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        print("🔊 Setting device to: ${device.name} (type: ${device.type})");
      }

      // Configure audio session based on device type
      if (device.type == AudioDeviceType.TYPE_BUILTIN_EARPIECE) {
        await _configureForEarpiece();
      } else {
        await _configureForSpeaker();
      }

      // Small delay for audio session to apply
      await Future.delayed(const Duration(milliseconds: 100));

      // Now set the native routing
      final result = await _routingChannel.invokeMethod<bool>(
        "setAudioDevice",
        {"deviceType": device.type},
      );

      if (result == true) {
        _selectedDevice = device;
        if (kDebugMode) {
          print("✅ Successfully set to: ${device.name}");
        }
        return true;
      } else {
        if (kDebugMode) {
          print("❌ Failed to set device: ${device.name}");
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error setting audio device: $e");
      return false;
    }
  }

  /// Play audio
  Future<void> play() async {
    try {
      // Stop any existing playback first
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      _isCleanerMode = false;
      final audioPath = _getAudioPath();
      if (kDebugMode) print("🎵 Loading: $audioPath");

      // STEP 1: Configure and set routing FIRST
      if (_selectedDevice != null) {
        await setAudioDevice(_selectedDevice!);
      }

      // STEP 2: Wait for routing to apply
      await Future.delayed(const Duration(milliseconds: 200));

      // STEP 3: Load and play audio
      await _audioPlayer.setAsset(audioPath);
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
      _isPlaying = true;

      if (kDebugMode) {
        print("▶️ Playing on: ${_selectedDevice?.name ?? 'Default'}");
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error playing audio: $e");
    }
  }

  /// Play cleaner sound
  Future<void> playCleaner() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      _isCleanerMode = true;
      if (kDebugMode) print("🧹 Loading cleaner sound...");

      // STEP 1: Configure and set routing FIRST
      if (_selectedDevice != null) {
        await setAudioDevice(_selectedDevice!);
      }

      // STEP 2: Wait for routing
      await Future.delayed(const Duration(milliseconds: 200));

      // STEP 3: Load and play
      await _audioPlayer.setAsset("assets/voices/cleaner_full.mp3");
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
      _isPlaying = true;

      if (kDebugMode) {
        print("▶️ Cleaner playing on: ${_selectedDevice?.name ?? 'Default'}");
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error playing cleaner: $e");
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    if (kDebugMode) print("⏹️ Audio stopped");
  }

  /// Switch to a different output device
  Future<bool> switchDevice(AudioDevice device) async {
    if (kDebugMode) {
      print("🔄 Switching from ${_selectedDevice?.name} to ${device.name}");
    }

    final wasPlaying = _isPlaying;
    final wasCleanerMode = _isCleanerMode;

    // Stop current playback
    if (wasPlaying) {
      await stop();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Set new device (this also configures audio session)
    final success = await setAudioDevice(device);

    if (!success) {
      if (kDebugMode) print("❌ Device switch failed");
      return false;
    }

    // Wait for routing to fully apply
    await Future.delayed(const Duration(milliseconds: 300));

    // Restart playback if it was playing
    if (wasPlaying) {
      if (wasCleanerMode) {
        await playCleaner();
      } else {
        await play();
      }
    }

    return true;
  }

  void setFrequency(double freq) {
    _frequency = freq;
    if (kDebugMode) print("📊 Frequency: $freq Hz");
    if (_isPlaying) {
      stop();
      play();
    }
  }

  void setWaveType(WaveType wave) {
    _currentWave = wave;
    if (kDebugMode) print("〰️ Wave type: $wave");
    if (_isPlaying) {
      stop();
      play();
    }
  }

  String _getAudioPath() {
    switch (_currentWave) {
      case WaveType.sine:
        return "assets/voices/40-60_hz_square.mp3";
      case WaveType.square:
        return "assets/voices/1-200_hz_square.mp3";
      case WaveType.sawtooth:
        return "assets/voices/150-200_hz_saw.mp3";
    }
  }

  void dispose() {
    _routingChannel.invokeMethod('resetAudioMode');
    _audioPlayer.dispose();
  }
}

// import 'dart:async';
//
// import 'package:audio_session/audio_session.dart' as audio_session_pkg;
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:just_audio/just_audio.dart';
//
// enum WaveType { sine, square, sawtooth }
//
// class AudioDevice {
//   final int id;
//   final int type;
//   final String name;
//   final String productName;
//
//   AudioDevice({
//     required this.id,
//     required this.type,
//     required this.name,
//     required this.productName,
//   });
//
//   factory AudioDevice.fromMap(Map<dynamic, dynamic> map) {
//     return AudioDevice(
//       id: map['id'] as int? ?? 0,
//       type: map['type'] as int? ?? 0,
//       name: map['name'] as String? ?? 'Unknown',
//       productName: map['productName'] as String? ?? 'Unknown',
//     );
//   }
//
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is AudioDevice &&
//           runtimeType == other.runtimeType &&
//           id == other.id &&
//           type == other.type;
//
//   @override
//   int get hashCode => id.hashCode ^ type.hashCode;
//
//   @override
//   String toString() => 'AudioDevice(id: $id, type: $type, name: $name)';
// }
//
// class AudioDeviceType {
//   static const int TYPE_BUILTIN_SPEAKER = 2;
//   static const int TYPE_BUILTIN_EARPIECE = 1;
//   static const int TYPE_WIRED_HEADSET = 3;
//   static const int TYPE_WIRED_HEADPHONES = 4;
//   static const int TYPE_BLUETOOTH_A2DP = 8;
//   static const int TYPE_BLUETOOTH_SCO = 7;
//   static const int TYPE_USB_DEVICE = 11;
//   static const int TYPE_USB_HEADSET = 22;
// }
//
// class AudioService {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   bool _isPlaying = false;
//   WaveType _currentWave = WaveType.sine;
//   double _frequency = 165.0;
//
//   bool get isPlaying => _isPlaying;
//   WaveType get currentWave => _currentWave;
//   double get frequency => _frequency;
//
//   static const MethodChannel _routingChannel = MethodChannel(
//     "com.example.speakercleaner/routing",
//   );
//
//   AudioDevice? _selectedDevice;
//   AudioDevice? get selectedDevice => _selectedDevice;
//
//   List<AudioDevice> _availableDevices = [];
//   List<AudioDevice> get availableDevices => _availableDevices;
//
//   late audio_session_pkg.AudioSession _audioSession;
//
//   Future<void> initialize() async {
//     _audioSession = await audio_session_pkg.AudioSession.instance;
//
//     // Configure for voice communication (required for earpiece routing)
//     await _audioSession.configure(
//       audio_session_pkg.AudioSessionConfiguration(
//         avAudioSessionCategory:
//             audio_session_pkg.AVAudioSessionCategory.playAndRecord,
//         avAudioSessionCategoryOptions:
//             audio_session_pkg.AVAudioSessionCategoryOptions.defaultToSpeaker |
//             audio_session_pkg.AVAudioSessionCategoryOptions.allowBluetooth,
//         avAudioSessionMode: audio_session_pkg.AVAudioSessionMode.voiceChat,
//         // IMPORTANT: Use voice communication for earpiece to work
//         androidAudioAttributes: const audio_session_pkg.AndroidAudioAttributes(
//           contentType: audio_session_pkg.AndroidAudioContentType.speech,
//           usage: audio_session_pkg.AndroidAudioUsage.voiceCommunication,
//         ),
//         androidAudioFocusGainType:
//             audio_session_pkg.AndroidAudioFocusGainType.gain,
//       ),
//     );
//
//     await refreshAvailableDevices();
//
//     if (kDebugMode) {
//       print("🎵 AudioService initialized");
//       print("🎵 Available devices: $_availableDevices");
//     }
//   }
//
//   Future<List<AudioDevice>> refreshAvailableDevices() async {
//     try {
//       final List<dynamic>? result = await _routingChannel.invokeMethod(
//         'getAvailableDevices',
//       );
//
//       if (result != null) {
//         _availableDevices = result
//             .map((e) => AudioDevice.fromMap(e as Map<dynamic, dynamic>))
//             .toList();
//
//         // Set default to speaker if not selected
//         if (_selectedDevice == null && _availableDevices.isNotEmpty) {
//           _selectedDevice = _availableDevices.firstWhere(
//             (d) => d.type == AudioDeviceType.TYPE_BUILTIN_SPEAKER,
//             orElse: () => _availableDevices.first,
//           );
//         }
//
//         if (kDebugMode) {
//           print("🔊 Found ${_availableDevices.length} audio devices:");
//           for (var device in _availableDevices) {
//             print("   - ${device.name} (type: ${device.type})");
//           }
//         }
//       }
//
//       return _availableDevices;
//     } catch (e) {
//       if (kDebugMode) print("❌ Error getting devices: $e");
//       return [];
//     }
//   }
//
//   /// Set audio output device - MUST be called before playback for earpiece
//   Future<bool> setAudioDevice(AudioDevice device) async {
//     try {
//       if (kDebugMode) {
//         print(
//           "🔊 Setting audio device to: ${device.name} (type: ${device.type})",
//         );
//       }
//
//       final result = await _routingChannel.invokeMethod<bool>(
//         "setAudioDevice",
//         {"deviceType": device.type},
//       );
//
//       if (result == true) {
//         _selectedDevice = device;
//         if (kDebugMode) {
//           print("✅ Successfully set to: ${device.name}");
//         }
//         return true;
//       } else {
//         if (kDebugMode) {
//           print("❌ Failed to set device: ${device.name}");
//         }
//         return false;
//       }
//     } catch (e) {
//       if (kDebugMode) print("❌ Error setting audio device: $e");
//       return false;
//     }
//   }
//
//   /// Prepare audio routing before playback (crucial for earpiece)
//   Future<bool> _prepareRouting() async {
//     if (_selectedDevice == null) return true;
//
//     try {
//       final result = await _routingChannel.invokeMethod<bool>(
//         "prepareForPlayback",
//         {"deviceType": _selectedDevice!.type},
//       );
//
//       if (kDebugMode) {
//         print("🔧 Routing prepared: $result for ${_selectedDevice!.name}");
//       }
//
//       // Give system time to apply routing
//       await Future.delayed(const Duration(milliseconds: 300));
//
//       return result ?? false;
//     } catch (e) {
//       if (kDebugMode) print("❌ Error preparing routing: $e");
//       return false;
//     }
//   }
//
//   /// Play audio with proper device routing
//   Future<void> play() async {
//     try {
//       final audioPath = _getAudioPath();
//       if (kDebugMode) print("🎵 Loading: $audioPath");
//
//       // STEP 1: Prepare routing BEFORE loading audio
//       await _prepareRouting();
//
//       // STEP 2: Load the audio asset
//       await _audioPlayer.setAsset(audioPath);
//       await _audioPlayer.setLoopMode(LoopMode.one);
//
//       // STEP 3: Apply routing again (reinforce)
//       if (_selectedDevice != null) {
//         await setAudioDevice(_selectedDevice!);
//       }
//
//       // STEP 4: Wait for routing to stabilize
//       await Future.delayed(const Duration(milliseconds: 200));
//
//       // STEP 5: Start playback
//       await _audioPlayer.play();
//       _isPlaying = true;
//
//       if (kDebugMode) {
//         print("▶️ Playing on: ${_selectedDevice?.name ?? 'Default'}");
//       }
//     } catch (e) {
//       if (kDebugMode) print("❌ Error playing audio: $e");
//     }
//   }
//
//   /// Play cleaner sound with proper device routing
//   Future<void> playCleaner() async {
//     try {
//       if (kDebugMode) print("🧹 Loading cleaner sound...");
//
//       // STEP 1: Prepare routing BEFORE loading audio
//       await _prepareRouting();
//
//       // STEP 2: Load cleaner audio
//       await _audioPlayer.setAsset("assets/voices/cleaner_full.mp3");
//       await _audioPlayer.setLoopMode(LoopMode.one);
//
//       // STEP 3: Apply routing again (reinforce)
//       if (_selectedDevice != null) {
//         await setAudioDevice(_selectedDevice!);
//       }
//
//       // STEP 4: Wait for routing
//       await Future.delayed(const Duration(milliseconds: 200));
//
//       // STEP 5: Play
//       await _audioPlayer.play();
//       _isPlaying = true;
//
//       if (kDebugMode) {
//         print("▶️ Cleaner playing on: ${_selectedDevice?.name ?? 'Default'}");
//       }
//     } catch (e) {
//       if (kDebugMode) print("❌ Error playing cleaner: $e");
//     }
//   }
//
//   Future<void> stop() async {
//     await _audioPlayer.stop();
//     _isPlaying = false;
//     if (kDebugMode) print("⏹️ Audio stopped");
//   }
//
//   /// Switch output device and restart playback if needed
//   Future<bool> switchDevice(AudioDevice device) async {
//     final wasPlaying = _isPlaying;
//
//     if (wasPlaying) {
//       await stop();
//       await Future.delayed(const Duration(milliseconds: 100));
//     }
//
//     final success = await setAudioDevice(device);
//
//     if (success && wasPlaying) {
//       await Future.delayed(const Duration(milliseconds: 200));
//       await play();
//     }
//
//     return success;
//   }
//
//   Future<bool> setSpeaker(bool useSpeaker) async {
//     final targetType = useSpeaker
//         ? AudioDeviceType.TYPE_BUILTIN_SPEAKER
//         : AudioDeviceType.TYPE_BUILTIN_EARPIECE;
//
//     final device = _availableDevices.firstWhere(
//       (d) => d.type == targetType,
//       orElse: () => AudioDevice(
//         id: 0,
//         type: targetType,
//         name: useSpeaker ? "Bottom Speaker" : "Top Earpiece",
//         productName: "Built-in",
//       ),
//     );
//
//     return switchDevice(device);
//   }
//
//   void setFrequency(double freq) {
//     _frequency = freq;
//     if (kDebugMode) print("📊 Frequency: $freq Hz");
//     if (_isPlaying) {
//       stop();
//       play();
//     }
//   }
//
//   void setWaveType(WaveType wave) {
//     _currentWave = wave;
//     if (kDebugMode) print("〰️ Wave type: $wave");
//     if (_isPlaying) {
//       stop();
//       play();
//     }
//   }
//
//   String _getAudioPath() {
//     switch (_currentWave) {
//       case WaveType.sine:
//         return "assets/voices/1-200_hz_square.mp3";
//       case WaveType.square:
//         return "assets/voices/1-200_hz_square.mp3";
//       case WaveType.sawtooth:
//         return "assets/voices/150-200_hz_saw.mp3";
//     }
//   }
//
//   void dispose() {
//     _routingChannel.invokeMethod('resetAudioMode');
//     _audioPlayer.dispose();
//   }
// }
