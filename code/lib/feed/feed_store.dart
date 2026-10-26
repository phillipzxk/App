import '../sleep/schlafzeiten.dart';
import 'durchgezogen.dart';
import 'fokus.dart';
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

  /// The current focus of the week (or the one that just ended).
  Future<Wochenfokus?> loadFokus();
  Future<void> saveFokus(Wochenfokus fokus);

  /// Suggestions waiting for a choice; null clears them.
  Future<FokusAuswahl?> loadFokusAuswahl();
  Future<void> saveFokusAuswahl(FokusAuswahl? auswahl);

  /// Wake-up times and hours of sleep, empty until set.
  Future<Schlafzeiten> loadSchlafzeiten();
  Future<void> saveSchlafzeiten(Schlafzeiten z);

  /// How the coach's reply on "Heute" is shown: 'text', 'punkte' or 'zu'.
  Future<String> loadCoachAnsicht();
  Future<void> saveCoachAnsicht(String ansicht);

  /// "Durchgezogen": all entries, from the coach and the user.
  Future<List<Durchgezogen>> loadDurchgezogen();
  Future<void> saveDurchgezogen(List<Durchgezogen> list);

  /// Day the coach last looked for an entry (once per day at most).
  Future<String?> loadDurchGeprueft();
  Future<void> saveDurchGeprueft(DateTime day);

  /// "Dein Warum" on Heute: the day the coach last checked for a weak
  /// phase and its sentence (null on a normal day).
  Future<({String tag, String? satz})?> loadWarumHeute();
  Future<void> saveWarumHeute(DateTime day, String? satz);
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
  static const _fokusKey = 'fokus';
  static const _fokusAuswahlKey = 'fokus_auswahl';
  static const _schlafzeitenKey = 'schlafzeiten';
  static const _coachAnsichtKey = 'coach_ansicht';
  static const _durchKey = 'durchgezogen';
  static const _durchGeprueftKey = 'durchgezogen_geprueft';
  static const _warumKey = 'warum_heute';

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

  @override
  Future<Wochenfokus?> loadFokus() async {
    final json = await _read(_fokusKey);
    return json == null
        ? null
        : Wochenfokus.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> saveFokus(Wochenfokus fokus) =>
      _write(_fokusKey, fokus.toJson());

  @override
  Future<FokusAuswahl?> loadFokusAuswahl() async {
    final json = await _read(_fokusAuswahlKey);
    return json == null
        ? null
        : FokusAuswahl.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> saveFokusAuswahl(FokusAuswahl? auswahl) async {
    if (auswahl == null) {
      await (await SharedPreferences.getInstance()).remove(_fokusAuswahlKey);
    } else {
      await _write(_fokusAuswahlKey, auswahl.toJson());
    }
  }

  @override
  Future<Schlafzeiten> loadSchlafzeiten() async {
    final json = await _read(_schlafzeitenKey);
    return json == null
        ? const Schlafzeiten()
        : Schlafzeiten.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> saveSchlafzeiten(Schlafzeiten z) =>
      _write(_schlafzeitenKey, z.toJson());

  @override
  Future<String> loadCoachAnsicht() async =>
      await _read(_coachAnsichtKey) as String? ?? 'text';

  @override
  Future<void> saveCoachAnsicht(String ansicht) =>
      _write(_coachAnsichtKey, ansicht);

  @override
  Future<List<Durchgezogen>> loadDurchgezogen() async {
    final json = await _read(_durchKey) as List?;
    return [
      for (final e in json ?? const [])
        Durchgezogen.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> saveDurchgezogen(List<Durchgezogen> list) =>
      _write(_durchKey, [for (final e in list) e.toJson()]);

  @override
  Future<String?> loadDurchGeprueft() async =>
      await _read(_durchGeprueftKey) as String?;

  @override
  Future<void> saveDurchGeprueft(DateTime day) =>
      _write(_durchGeprueftKey, dayKey(day));

  @override
  Future<({String tag, String? satz})?> loadWarumHeute() async {
    final json = await _read(_warumKey) as Map?;
    final tag = json?['tag'];
    if (tag is! String) return null;
    final satz = json!['satz'];
    return (tag: tag, satz: satz is String ? satz : null);
  }

  @override
  Future<void> saveWarumHeute(DateTime day, String? satz) =>
      _write(_warumKey, {'tag': dayKey(day), 'satz': satz});
}
