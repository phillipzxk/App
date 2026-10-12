import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../checkin/checkin.dart';
import '../weight/weight.dart';

/// Loads and saves daily check-ins and weight entries.
///
/// Like [ProfileStore], only a local implementation exists until the
/// backend (Firebase) is set up.
abstract class DiaryStore {
  /// All check-ins, oldest first.
  Future<List<CheckIn>> loadCheckIns();

  /// Saves a check-in, replacing one from the same day.
  Future<void> saveCheckIn(CheckIn checkIn);

  /// All weight entries, oldest first.
  Future<List<WeightEntry>> loadWeights();
  Future<void> addWeight(WeightEntry entry);
}

/// Stores everything on the device as JSON lists.
class LocalDiaryStore implements DiaryStore {
  static const _checkInsKey = 'checkins';
  static const _weightsKey = 'gewicht';

  @override
  Future<List<CheckIn>> loadCheckIns() async {
    final raw = (await SharedPreferences.getInstance()).getString(_checkInsKey);
    if (raw == null) return [];
    return [
      for (final e in jsonDecode(raw) as List)
        CheckIn.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> saveCheckIn(CheckIn checkIn) async {
    final all = await loadCheckIns()
      ..removeWhere((c) => dayKey(c.datum) == dayKey(checkIn.datum))
      ..add(checkIn)
      ..sort((a, b) => a.datum.compareTo(b.datum));
    await (await SharedPreferences.getInstance()).setString(
      _checkInsKey,
      jsonEncode([for (final c in all) c.toJson()]),
    );
  }

  @override
  Future<List<WeightEntry>> loadWeights() async {
    final raw = (await SharedPreferences.getInstance()).getString(_weightsKey);
    if (raw == null) return [];
    return [
      for (final e in jsonDecode(raw) as List)
        WeightEntry.fromJson(e as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> addWeight(WeightEntry entry) async {
    final all = await loadWeights()
      ..add(entry)
      ..sort((a, b) => a.datum.compareTo(b.datum));
    await (await SharedPreferences.getInstance()).setString(
      _weightsKey,
      jsonEncode([for (final w in all) w.toJson()]),
    );
  }
}
