import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();

    final completed = prefs.getBool(_onboardingCompletedKey) ?? false;
    return completed;
  }

  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  // Temporary method for testing - remove in production
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
  }
}
