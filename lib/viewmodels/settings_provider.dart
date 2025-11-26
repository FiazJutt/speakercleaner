import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isNotificationEnabled;
  final bool isNotificationScheduled;
  final bool isLoading;

  const SettingsState({
    this.isNotificationEnabled = false,
    this.isNotificationScheduled = false,
    this.isLoading = true,
  });

  SettingsState copyWith({
    bool? isNotificationEnabled,
    bool? isNotificationScheduled,
    bool? isLoading,
  }) {
    return SettingsState(
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      isNotificationScheduled:
          isNotificationScheduled ?? this.isNotificationScheduled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      state = state.copyWith(
        isNotificationEnabled: prefs.getBool('isNotificationEnabled') ?? false,
        isNotificationScheduled:
            prefs.getBool('isNotificationScheduled') ?? false,
        isLoading: false,
      );
      debugPrint('Settings loaded: ${state.isNotificationEnabled}');
    } catch (e) {
      debugPrint('Error loading settings: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setNotificationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationEnabled', value);
    state = state.copyWith(isNotificationEnabled: value);
    debugPrint('Notification enabled set to: $value');
  }

  Future<void> setNotificationScheduled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationScheduled', value);
    state = state.copyWith(isNotificationScheduled: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
