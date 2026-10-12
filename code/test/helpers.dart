import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/diary_store.dart';
import 'package:coach_app/data/profile_store.dart';
import 'package:coach_app/data/user_profile.dart';
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
