import 'muster.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../checkin/checkin.dart';
import '../future_me/future_me_data.dart';
import '../planner/planner_data.dart';
import '../supplements/supplement_data.dart';
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

  /// The training focus for the hybrid engine; null until chosen.
  Future<Schwerpunkt?> loadSchwerpunkt();
  Future<void> saveSchwerpunkt(Schwerpunkt s);

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

  /// "Dein zukünftiges Ich": null until photo day and poses are set up.
  Future<FotoEinstellungen?> loadFotoEinstellungen();
  Future<void> saveFotoEinstellungen(FotoEinstellungen e);

  /// The weekly photos, oldest photo day first.
  Future<List<WochenFoto>> loadWochenFotos();

  /// Adds the week's entry, replacing one for the same photo day.
  Future<void> saveWochenFoto(WochenFoto foto);

  /// True once the code from the Frame Kit was entered (see
  /// Umsetzung/Foto-Kit.md).
  Future<bool> loadKitAktiv();
  Future<void> saveKitAktiv(bool aktiv);

  /// The supplement routine, empty until set.
  Future<List<Supplement>> loadSupplements();
  Future<void> saveSupplements(List<Supplement> list);

  /// Ids of the intakes ticked off on [day].
  Future<Set<String>> loadGenommen(DateTime day);
  Future<void> setGenommen(DateTime day, String id, bool genommen);

  /// "Deine Muster": all patterns the coach found, rejected ones included.
  Future<List<Muster>> loadMuster();
  Future<void> saveMuster(List<Muster> list);

  /// Day the coach last looked for a pattern (once per day at most).
  Future<String?> loadMusterGeprueft();
  Future<void> saveMusterGeprueft(DateTime day);
}

class LocalFeedStore implements FeedStore {
  static const _planKey = 'trainingsplan';
  static const _routineKey = 'abendroutine';
  static const _kcalKey = 'kcal_profil';
  static const _fragenKey = 'coach_fragen';
  static const _termineKey = 'termine';
  static const _mahlzeitenKey = 'mahlzeiten_pro_tag';
  static const _schwerpunktKey = 'schwerpunkt';
  static const _fotoEinstellungenKey = 'foto_einstellungen';
  static const _wochenFotosKey = 'wochen_fotos';
  static const _kitKey = 'frame_kit';
  static const _supplementsKey = 'supplements';
  static const _genommenKey = 'supplements_genommen';
  static const _musterKey = 'muster';
  static const _musterGeprueftKey = 'muster_geprueft';

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
  Future<Schwerpunkt?> loadSchwerpunkt() async {
    final name = await _read(_schwerpunktKey) as String?;
    for (final s in Schwerpunkt.values) {
      if (s.name == name) return s;
    }
    return null;
  }

  @override
  Future<void> saveSchwerpunkt(Schwerpunkt s) =>
      _write(_schwerpunktKey, s.name);

  @override
  Future<int?> loadMahlzeiten() async => await _read(_mahlzeitenKey) as int?;

  @override
  Future<void> saveMahlzeiten(int anzahl) => _write(_mahlzeitenKey, anzahl);

  @override
  Future<FotoEinstellungen?> loadFotoEinstellungen() async {
    final json = await _read(_fotoEinstellungenKey);
    return json == null
        ? null
        : FotoEinstellungen.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> saveFotoEinstellungen(FotoEinstellungen e) =>
      _write(_fotoEinstellungenKey, e.toJson());

  @override
  Future<List<WochenFoto>> loadWochenFotos() async {
    final json = await _read(_wochenFotosKey) as List?;
    return [
      for (final e in json ?? const [])
        WochenFoto.fromJson(e as Map<String, dynamic>),
    ]..sort((a, b) => a.fototag.compareTo(b.fototag));
  }

  @override
  Future<void> saveWochenFoto(WochenFoto foto) async {
    final all = await loadWochenFotos()
      ..removeWhere((f) => dayKey(f.fototag) == dayKey(foto.fototag))
      ..add(foto);
    await _write(_wochenFotosKey, [for (final f in all) f.toJson()]);
  }

  @override
  Future<bool> loadKitAktiv() async => await _read(_kitKey) == true;

  @override
  Future<void> saveKitAktiv(bool aktiv) => _write(_kitKey, aktiv);

  @override
  Future<List<Supplement>> loadSupplements() async {
    final json = await _read(_supplementsKey) as List?;
    return [
      for (final e in json ?? const [])
        Supplement.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> saveSupplements(List<Supplement> list) =>
      _write(_supplementsKey, [for (final s in list) s.toJson()]);

  /// Only today's ticks are kept, so the list never grows.
  @override
  Future<Set<String>> loadGenommen(DateTime day) async {
    final json = await _read(_genommenKey) as Map<String, dynamic>?;
    final ids = json?[dayKey(day)] as List?;
    return {for (final id in ids ?? const []) id as String};
  }

  @override
  Future<void> setGenommen(DateTime day, String id, bool genommen) async {
    final ids = await loadGenommen(day);
    genommen ? ids.add(id) : ids.remove(id);
    await _write(_genommenKey, {dayKey(day): ids.toList()});
  }

  @override
  Future<List<Muster>> loadMuster() async {
    final json = await _read(_musterKey) as List?;
    return [
      for (final e in json ?? const [])
        Muster.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> saveMuster(List<Muster> list) =>
      _write(_musterKey, [for (final m in list) m.toJson()]);

  @override
  Future<String?> loadMusterGeprueft() async =>
      await _read(_musterGeprueftKey) as String?;

  @override
  Future<void> saveMusterGeprueft(DateTime day) =>
      _write(_musterGeprueftKey, dayKey(day));
}
