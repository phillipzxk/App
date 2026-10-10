import 'package:shared_preferences/shared_preferences.dart';

import 'user_profile.dart';

/// Loads and saves the [UserProfile].
///
/// Only a local implementation exists for now. Once the backend is decided
/// (Firebase is proposed), a second implementation can replace it without
/// touching the screens.
abstract class ProfileStore {
  Future<UserProfile> load();
  Future<void> save(UserProfile profile);
  Future<void> clear();
}

/// Stores the profile on the device.
class LocalProfileStore implements ProfileStore {
  static const _keys = (
    ziel: 'ziel',
    level: 'level',
    ausgangssituation: 'ausgangssituation',
    onboardingNotiz: 'onboarding_notiz',
  );

  @override
  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      ziel: prefs.getString(_keys.ziel) ?? '',
      level: prefs.getString(_keys.level) ?? '',
      ausgangssituation: prefs.getString(_keys.ausgangssituation) ?? '',
      onboardingNotiz: prefs.getString(_keys.onboardingNotiz) ?? '',
    );
  }

  @override
  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keys.ziel, profile.ziel);
    await prefs.setString(_keys.level, profile.level);
    await prefs.setString(_keys.ausgangssituation, profile.ausgangssituation);
    await prefs.setString(_keys.onboardingNotiz, profile.onboardingNotiz);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keys.ziel);
    await prefs.remove(_keys.level);
    await prefs.remove(_keys.ausgangssituation);
    await prefs.remove(_keys.onboardingNotiz);
  }
}
