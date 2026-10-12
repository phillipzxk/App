import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'feed_data.dart';
import 'kcal.dart';

/// Loads and saves what the user sets up in the Main Feed: training plan,
/// evening routine, kcal data and what they wrote into the coach fields.
///
/// Like the other stores, only a local implementation exists until the
/// backend (Firebase) is set up.
abstract class FeedStore {
  Future<TrainingPlan> loadPlan();
  Future<void> savePlan(TrainingPlan plan);

  Future<List<RoutineStep>> loadRoutine();
  Future<void> saveRoutine(List<RoutineStep> steps);

  /// Null until the kcal target has been set up.
  Future<KcalProfil?> loadKcal();
  Future<void> saveKcal(KcalProfil profil);

  /// All coach questions, oldest first.
  Future<List<CoachFrage>> loadFragen();
  Future<void> addFrage(CoachFrage frage);
}

class LocalFeedStore implements FeedStore {
  static const _planKey = 'trainingsplan';
  static const _routineKey = 'abendroutine';
  static const _kcalKey = 'kcal_profil';
  static const _fragenKey = 'coach_fragen';

  Future<Object?> _read(String key) async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    return raw == null ? null : jsonDecode(raw);
  }

  Future<void> _write(String key, Object value) async =>
      (await SharedPreferences.getInstance()).setString(key, jsonEncode(value));

  @override
  Future<TrainingPlan> loadPlan() async {
    final json = await _read(_planKey);
    return json == null
        ? TrainingPlan.empty()
        : TrainingPlan.fromJson(json as List);
  }

  @override
  Future<void> savePlan(TrainingPlan plan) => _write(_planKey, plan.toJson());

  @override
  Future<List<RoutineStep>> loadRoutine() async {
    final json = await _read(_routineKey) as List?;
    return [
      for (final e in json ?? const [])
        RoutineStep.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> saveRoutine(List<RoutineStep> steps) =>
      _write(_routineKey, [for (final s in steps) s.toJson()]);

  @override
  Future<KcalProfil?> loadKcal() async {
    final json = await _read(_kcalKey);
    return json == null
        ? null
        : KcalProfil.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> saveKcal(KcalProfil profil) => _write(_kcalKey, profil.toJson());

  @override
  Future<List<CoachFrage>> loadFragen() async {
    final json = await _read(_fragenKey) as List?;
    return [
      for (final e in json ?? const [])
        CoachFrage.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> addFrage(CoachFrage frage) async {
    final all = await loadFragen()
      ..add(frage);
    await _write(_fragenKey, [for (final f in all) f.toJson()]);
  }
}
