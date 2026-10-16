import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/diary_store.dart';
import 'package:coach_app/data/profile_store.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/feed/feed_store.dart';
import 'package:coach_app/feed/kcal.dart';
import 'package:coach_app/future_me/future_me_data.dart';
import 'package:coach_app/planner/planner_data.dart';
import 'package:coach_app/supplements/supplement_data.dart';
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
}

/// Monday, 12 October 2026, 18:00.
final fixedNow = DateTime(2026, 10, 12, 18);
DateTime fixedClock() => fixedNow;

CheckIn checkInOn(DateTime day, {String reply = ''}) => CheckIn(
  datum: DateTime(day.year, day.month, day.day),
  training: 't',
  ernaehrung: 'e',
  schlaf: 's',
  mindset: 'm',
  kiAntwort: reply,
);

/// Switches the Main Feed to the page of [label] via the bottom bar.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Phone-sized portrait view, tall enough that whole pages are built.
void tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

/// Scrolls the visible page until [finder] is built and on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.pumpAndSettle();
}
