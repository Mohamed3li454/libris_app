import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _kFirstTimeUserKey = 'is_first_time_user';

  /// Returns `true` if the user is launching the app for the first time.
  static Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFirstTimeUserKey) ?? true;
  }

  /// Sets `isFirstTimeUser` to `false` when onboarding is completed or skipped.
  static Future<void> setFirstTimeUserComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFirstTimeUserKey, false);
  }
}
