import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../planner/planner_data.dart';
import 'feed_data.dart';
import 'kcal.dart';

/// Loads and saves what the user sets up in the Main Feed: training plan,
/// evening routine, kcal data, what they wrote into the coach fields, and
/// for the day plan their appointments and how many meals they want.
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

  /// All appointments of the day plan, in the order they were written.
  Future<List<Termin>> loadTermine();
  Future<void> addTermin(Termin termin);
  Future<void> removeTermin(Termin termin);

  /// Meals per day for the day plan; null until the user has set it.
  Future<int?> loadMahlzeiten();
  Future<void> saveMahlzeiten(int anzahl);
}

class LocalFeedStore implements FeedStore {
  static const _planKey = 'trainingsplan';
  static const _routineKey = 'abendroutine';
  static const _kcalKey = 'kcal_profil';
  static const _fragenKey = 'coach_fragen';
  static const _termineKey = 'termine';
  static const _mahlzeitenKey = 'mahlzeiten_pro_tag';

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

  @override
  Future<List<Termin>> loadTermine() async {
    final json = await _read(_termineKey) as List?;
    return [
      for (final e in json ?? const [])
        Termin.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> addTermin(Termin termin) async {
    final all = await loadTermine()
      ..add(termin);
    await _write(_termineKey, [for (final t in all) t.toJson()]);
  }

  @override
  Future<void> removeTermin(Termin termin) async {
    final all = await loadTermine()
      ..removeWhere((t) => t.erstellt == termin.erstellt);
    await _write(_termineKey, [for (final t in all) t.toJson()]);
  }

  @override
  Future<int?> loadMahlzeiten() async => await _read(_mahlzeitenKey) as int?;

  @override
  Future<void> saveMahlzeiten(int anzahl) => _write(_mahlzeitenKey, anzahl);
}
