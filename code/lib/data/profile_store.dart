import 'package:shared_preferences/shared_preferences.dart';

import 'user_profile.dart';

/// Loads and saves the [UserProfile].
///
/// Only a local implementation exists for now. Once the backend is set up
/// (Firebase is planned), a second implementation can replace it without
/// touching the screens.
abstract class ProfileStore {
  Future<UserProfile> load();
  Future<void> save(UserProfile profile);
  Future<void> clear();
}

/// Stores the profile on the device.
class LocalProfileStore implements ProfileStore {
  static const _keys = [
    'ziel',
    'motivation',
    'level',
    'training',
    'ernaehrung',
    'schlaf_energie',
    'zusammenfassung',
    'name',
    'koerper',
    'produktiv',
    'business',
    'persoenlich',
  ];

  /// Keys of the first onboarding version, removed on save and clear.
  static const _oldKeys = ['ausgangssituation', 'onboarding_notiz'];

  @override
  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = [for (final k in _keys) prefs.getString(k) ?? ''];
    return UserProfile(
      ziel: v[0],
      motivation: v[1],
      level: v[2],
      training: v[3],
      ernaehrung: v[4],
      schlafEnergie: v[5],
      zusammenfassung: v[6],
      name: v[7],
      koerper: v[8],
      produktiv: v[9],
      business: v[10],
      persoenlich: v[11],
    );
  }

  @override
  Future<void> save(UserProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    final values = [
      p.ziel,
      p.motivation,
      p.level,
      p.training,
      p.ernaehrung,
      p.schlafEnergie,
      p.zusammenfassung,
      p.name,
      p.koerper,
      p.produktiv,
      p.business,
      p.persoenlich,
    ];
    for (var i = 0; i < _keys.length; i++) {
      await prefs.setString(_keys[i], values[i]);
    }
    for (final k in _oldKeys) {
      await prefs.remove(k);
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [..._keys, ..._oldKeys]) {
      await prefs.remove(k);
    }
  }
}
