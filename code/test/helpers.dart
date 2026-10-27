import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/diary_store.dart';
import 'package:coach_app/data/profile_store.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/feed/feed_store.dart';
import 'package:coach_app/feed/kcal.dart';
import 'package:coach_app/feed/durchgezogen.dart';
import 'package:coach_app/feed/fokus.dart';
import 'package:coach_app/feed/muster.dart';
import 'package:coach_app/sleep/schlafzeiten.dart';
import 'package:coach_app/future_me/future_me_data.dart';
import 'package:coach_app/planner/planner_data.dart';
import 'package:coach_app/supplements/supplement_data.dart';
import 'package:coach_app/ernaehrung/ernaehrung_data.dart';
import 'package:coach_app/training/form_video.dart';
import 'package:coach_app/training/training_data.dart';
import 'package:coach_app/sleep/sleep.dart';
import 'package:coach_app/weight/weight.dart';

class MemoryProfileStore implements ProfileStore {
  MemoryProfileStore([this.profile = const UserProfile()]);

  UserProfile profile;

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<void> save(UserProfile p) async => profile = p;

  @override
  Future<void> clear() async => profile = const UserProfile();
}

class MemoryDiaryStore implements DiaryStore {
  final checkIns = <CheckIn>[];
  final weights = <WeightEntry>[];

  @override
  Future<List<CheckIn>> loadCheckIns() async => List.of(checkIns);

  @override
  Future<void> saveCheckIn(CheckIn c) async {
    checkIns
      ..removeWhere((x) => dayKey(x.datum) == dayKey(c.datum))
      ..add(c);
  }

  @override
  Future<List<WeightEntry>> loadWeights() async => List.of(weights);

  @override
  Future<void> addWeight(WeightEntry e) async => weights.add(e);

  final sleep = <SleepEntry>[];

  @override
  Future<List<SleepEntry>> loadSleep() async => List.of(sleep);

  @override
  Future<void> saveSleep(SleepEntry e) async {
    sleep
      ..removeWhere((x) => dayKey(x.datum) == dayKey(e.datum))
      ..add(e);
  }
}

class MemoryFeedStore implements FeedStore {
  TrainingPlan plan = TrainingPlan.empty();
  List<RoutineStep> routine = [];
  KcalProfil? kcal;
  final fragen = <CoachFrage>[];

  @override
  Future<TrainingPlan> loadPlan() async => plan;

  @override
  Future<void> savePlan(TrainingPlan p) async => plan = p;

  @override
  Future<List<RoutineStep>> loadRoutine() async => List.of(routine);

  @override
  Future<void> saveRoutine(List<RoutineStep> steps) async => routine = steps;

  @override
  Future<KcalProfil?> loadKcal() async => kcal;

  @override
  Future<void> saveKcal(KcalProfil p) async => kcal = p;

  @override
  Future<List<CoachFrage>> loadFragen() async => List.of(fragen);

  @override
  Future<void> addFrage(CoachFrage f) async => fragen.add(f);

  final termine = <Termin>[];
  int? mahlzeiten;
  Schwerpunkt? schwerpunkt;

  @override
  Future<Schwerpunkt?> loadSchwerpunkt() async => schwerpunkt;

  @override
  Future<void> saveSchwerpunkt(Schwerpunkt s) async => schwerpunkt = s;

  @override
  Future<List<Termin>> loadTermine() async => List.of(termine);

  @override
  Future<void> addTermin(Termin t) async => termine.add(t);

  @override
  Future<void> removeTermin(Termin t) async =>
      termine.removeWhere((x) => x.erstellt == t.erstellt);

  @override
  Future<int?> loadMahlzeiten() async => mahlzeiten;

  @override
  Future<void> saveMahlzeiten(int n) async => mahlzeiten = n;

  FotoEinstellungen? fotoEinstellungen;
  bool kitAktiv = false;

  @override
  Future<bool> loadKitAktiv() async => kitAktiv;

  @override
  Future<void> saveKitAktiv(bool aktiv) async => kitAktiv = aktiv;

  final wochenFotos = <WochenFoto>[];

  @override
  Future<FotoEinstellungen?> loadFotoEinstellungen() async => fotoEinstellungen;

  @override
  Future<void> saveFotoEinstellungen(FotoEinstellungen e) async =>
      fotoEinstellungen = e;

  @override
  Future<List<WochenFoto>> loadWochenFotos() async =>
      List.of(wochenFotos)..sort((a, b) => a.fototag.compareTo(b.fototag));

  @override
  Future<void> saveWochenFoto(WochenFoto f) async {
    wochenFotos
      ..removeWhere((x) => dayKey(x.fototag) == dayKey(f.fototag))
      ..add(f);
  }

  List<Supplement> supplements = [];
  final genommen = <String, Set<String>>{};

  @override
  Future<List<Supplement>> loadSupplements() async => List.of(supplements);

  @override
  Future<void> saveSupplements(List<Supplement> list) async =>
      supplements = list;

  @override
  Future<Set<String>> loadGenommen(DateTime day) async =>
      Set.of(genommen[dayKey(day)] ?? const {});

  @override
  Future<void> setGenommen(DateTime day, String id, bool g) async {
    final ids = genommen.putIfAbsent(dayKey(day), () => {});
    g ? ids.add(id) : ids.remove(id);
  }

  final muster = <Muster>[];
  String? musterGeprueft;

  @override
  Future<List<Muster>> loadMuster() async => List.of(muster);

  @override
  Future<void> saveMuster(List<Muster> list) async => muster
    ..clear()
    ..addAll(list);

  @override
  Future<String?> loadMusterGeprueft() async => musterGeprueft;

  @override
  Future<void> saveMusterGeprueft(DateTime day) async =>
      musterGeprueft = dayKey(day);

  Wochenfokus? fokus;
  FokusAuswahl? fokusAuswahl;

  @override
  Future<Wochenfokus?> loadFokus() async => fokus;

  @override
  Future<void> saveFokus(Wochenfokus f) async => fokus = f;

  @override
  Future<FokusAuswahl?> loadFokusAuswahl() async => fokusAuswahl;

  @override
  Future<void> saveFokusAuswahl(FokusAuswahl? a) async => fokusAuswahl = a;

  Schlafzeiten schlafzeiten = const Schlafzeiten();

  @override
  Future<Schlafzeiten> loadSchlafzeiten() async => schlafzeiten;

  @override
  Future<void> saveSchlafzeiten(Schlafzeiten z) async => schlafzeiten = z;

  String coachAnsicht = 'text';

  @override
  Future<String> loadCoachAnsicht() async => coachAnsicht;

  @override
  Future<void> saveCoachAnsicht(String a) async => coachAnsicht = a;

  final durchgezogen = <Durchgezogen>[];
  String? durchGeprueft;

  @override
  Future<List<Durchgezogen>> loadDurchgezogen() async => List.of(durchgezogen);

  @override
  Future<void> saveDurchgezogen(List<Durchgezogen> list) async => durchgezogen
    ..clear()
    ..addAll(list);

  @override
  Future<String?> loadDurchGeprueft() async => durchGeprueft;

  @override
  Future<void> saveDurchGeprueft(DateTime day) async =>
      durchGeprueft = dayKey(day);

  ({String tag, String? satz})? warumHeute;

  @override
  Future<({String tag, String? satz})?> loadWarumHeute() async => warumHeute;

  @override
  Future<void> saveWarumHeute(DateTime day, String? satz) async =>
      warumHeute = (tag: dayKey(day), satz: satz);

  TrainingDaten training = const TrainingDaten();
  List<FormVideo> formVideos = [];

  @override
  Future<TrainingDaten> loadTraining() async => training;

  @override
  Future<void> saveTraining(TrainingDaten d) async => training = d;

  @override
  Future<List<FormVideo>> loadFormVideos() async => List.of(formVideos);

  @override
  Future<void> saveFormVideos(List<FormVideo> list) async => formVideos = list;

  ErnaehrungDaten ernaehrung = const ErnaehrungDaten();

  @override
  Future<ErnaehrungDaten> loadErnaehrung() async => ernaehrung;

  @override
  Future<void> saveErnaehrung(ErnaehrungDaten d) async => ernaehrung = d;
}

/// Monday, 12 October 2026, 18:00.
final fixedNow = DateTime(2026, 10, 12, 18);
DateTime fixedClock() => fixedNow;

CheckIn checkInOn(DateTime day, {String reply = '', String training = 't'}) =>
    CheckIn(
      datum: DateTime(day.year, day.month, day.day),
      training: training,
      ernaehrung: 'e',
      schlaf: 's',
      mindset: 'm',
      kiAntwort: reply,
    );

/// Goes back to "Heute" and, for an area, opens it on its root and then
/// its full page ("Alles zu …").
Future<void> openTab(WidgetTester tester, String label) async {
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .popUntil((r) => r.isFirst);
  await tester.pumpAndSettle();
  if (label == 'Heute') return;
  final b = switch (label) {
    'Training' => 'training',
    'Ernährung' => 'ernaehrung',
    'Schlaf' => 'schlaf',
    _ => 'mindset',
  };
  await openBereich(tester, b);
  await tester.tap(find.byKey(ValueKey('alles-$b')));
  await tester.pumpAndSettle();
}

/// Taps the area [b] on its root: it opens big over the whole screen.
Future<void> openBereich(WidgetTester tester, String b) async {
  await scrollTo(tester, find.byKey(ValueKey('wurzel-$b')));
  await tester.tap(find.byKey(ValueKey('wurzel-$b')));
  await tester.pumpAndSettle();
}

/// Phone-sized portrait view, tall enough that whole pages are built.
void tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

/// Opens one of the round fields (or a fruit) in the tree crown on Heute.
Future<void> openKrone(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await scrollTo(tester, f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Scrolls the visible page until [finder] is built and on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    // It may sit above the visible part: start again from the top.
    final s = tester.state<ScrollableState>(
      find.byType(Scrollable).hitTestable().first,
    );
    s.position.jumpTo(0);
    await tester.pumpAndSettle();
  }
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.pumpAndSettle();
}
