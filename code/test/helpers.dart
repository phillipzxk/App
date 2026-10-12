import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/diary_store.dart';
import 'package:coach_app/data/profile_store.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/feed/feed_store.dart';
import 'package:coach_app/feed/kcal.dart';
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
