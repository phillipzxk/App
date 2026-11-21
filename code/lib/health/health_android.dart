import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_daten.dart';
import 'health_dienst.dart';

/// Android: reads Health Connect (vault Umsetzung/Android nachziehen.md).
/// Only reads, never writes. Same values as Apple Health, without daylight,
/// which Android does not measure. Samsung Health, Fitbit, Garmin, Oura and
/// others come in through Health Connect.
class HealthConnect implements HealthDienst {
  HealthConnect({Health? health}) : _h = health ?? Health();

  final Health _h;
  bool _bereit = false;

  static const _verbundenKey = 'health_verbunden';

  static const _schlafArten = {
    HealthDataType.SLEEP_AWAKE: 'wach',
    HealthDataType.SLEEP_DEEP: 'tief',
    HealthDataType.SLEEP_LIGHT: 'kern',
    HealthDataType.SLEEP_REM: 'rem',
    HealthDataType.SLEEP_ASLEEP: 'schlaf',
    HealthDataType.SLEEP_SESSION: 'schlaf',
  };

  static final _typen = [
    ..._schlafArten.keys,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.STEPS,
    HealthDataType.WEIGHT,
    HealthDataType.WORKOUT,
  ];

  Future<void> _start() async {
    if (_bereit) return;
    await _h.configure();
    _bereit = true;
  }

  @override
  bool get moeglich => true;

  @override
  Future<bool> verbunden() async =>
      (await SharedPreferences.getInstance()).getBool(_verbundenKey) ?? false;

  @override
  Future<bool> verbinden() async {
    try {
      await _start();
      if (await _h.getHealthConnectSdkStatus() !=
          HealthConnectSdkStatus.sdkAvailable) {
        // Older phones: Health Connect comes from the Play Store once.
        await _h.installHealthConnect();
        return false;
      }
      final ok = await _h.requestAuthorization(
        _typen,
        permissions: [for (final _ in _typen) HealthDataAccess.READ],
      );
      if (ok) {
        await (await SharedPreferences.getInstance()).setBool(
          _verbundenKey,
          true,
        );
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<List<HealthDataPoint>> _lies(
    HealthDataType t,
    DateTime von,
    DateTime bis,
  ) async {
    try {
      return await _h.getHealthDataFromTypes(
        types: [t],
        startTime: von,
        endTime: bis,
      );
    } catch (_) {
      return const [];
    }
  }

  static num? _zahl(HealthDataPoint p) => switch (p.value) {
    NumericHealthValue(:final numericValue) => numericValue,
    _ => null,
  };

  @override
  Future<HealthTag?> lesen(DateTime heute) async {
    if (!await verbunden()) return null;
    try {
      await _start();
      final m = await _werte(heute).timeout(const Duration(seconds: 10));
      final t = HealthTag.ausHandy(heute, m);
      return t.leer ? null : t;
    } catch (_) {
      return null;
    }
  }

  /// The same map AppDelegate.swift sends, so HealthTag.ausHandy reads both.
  Future<Map<Object?, Object?>> _werte(DateTime jetzt) async {
    final tag = DateTime(jetzt.year, jetzt.month, jetzt.day);
    int ms(DateTime d) => d.millisecondsSinceEpoch;
    final aus = <Object?, Object?>{};

    // The night: from 18:00 the evening before to 14:00 today.
    final schlaf = <Map<String, Object>>[];
    for (final e in _schlafArten.entries) {
      for (final p in await _lies(
        e.key,
        tag.subtract(const Duration(hours: 6)),
        tag.add(const Duration(hours: 14)),
      )) {
        schlaf.add({
          'von': ms(p.dateFrom),
          'bis': ms(p.dateTo),
          'art': e.value,
        });
      }
    }
    aus['schlaf'] = schlaf;

    // Latest value and the 30-day average.
    Future<void> zuletztUndSchnitt(HealthDataType t, String name) async {
      final neu = await _lies(
        t,
        tag.subtract(const Duration(hours: 36)),
        jetzt,
      );
      neu.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final z = neu.isEmpty ? null : _zahl(neu.first);
      if (z != null) aus[name] = z.toDouble();
      final alt = [
        for (final p in await _lies(
          t,
          tag.subtract(const Duration(days: 30)),
          tag,
        ))
          ?_zahl(p),
      ];
      if (alt.isNotEmpty) {
        aus['${name}_schnitt'] =
            alt.fold<double>(0, (s, x) => s + x) / alt.length;
      }
    }

    await zuletztUndSchnitt(HealthDataType.RESTING_HEART_RATE, 'ruhepuls');
    await zuletztUndSchnitt(HealthDataType.HEART_RATE_VARIABILITY_RMSSD, 'hrv');

    try {
      final s = await _h.getTotalStepsInInterval(tag, jetzt);
      if (s != null) aus['schritte'] = s;
    } catch (_) {}

    // The weight from the scale, the last 2 days.
    final gewicht = await _lies(
      HealthDataType.WEIGHT,
      tag.subtract(const Duration(days: 1)),
      jetzt,
    );
    gewicht.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
    if (gewicht.isNotEmpty) {
      final kg = _zahl(gewicht.first);
      if (kg != null) {
        aus['gewicht'] = {
          'kg': kg.toDouble(),
          'zeit': ms(gewicht.first.dateFrom),
        };
      }
    }

    // Workouts from today.
    final trainings = await _lies(HealthDataType.WORKOUT, tag, jetzt);
    trainings.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    aus['trainings'] = [
      for (final w in trainings.take(10))
        {
          'art': switch (w.value) {
            WorkoutHealthValue(:final workoutActivityType) => trainingName(
              workoutActivityType,
            ),
            _ => 'Training',
          },
          'start': ms(w.dateFrom),
          'minuten': w.dateTo.difference(w.dateFrom).inMinutes,
        },
    ];
    return aus;
  }
}

/// German names, the same as on the iPhone.
String trainingName(HealthWorkoutActivityType t) => switch (t) {
  HealthWorkoutActivityType.RUNNING ||
  HealthWorkoutActivityType.RUNNING_TREADMILL => 'Laufen',
  HealthWorkoutActivityType.WALKING => 'Gehen',
  HealthWorkoutActivityType.HIKING => 'Wandern',
  HealthWorkoutActivityType.BIKING ||
  HealthWorkoutActivityType.BIKING_STATIONARY => 'Radfahren',
  HealthWorkoutActivityType.SWIMMING ||
  HealthWorkoutActivityType.SWIMMING_POOL ||
  HealthWorkoutActivityType.SWIMMING_OPEN_WATER => 'Schwimmen',
  HealthWorkoutActivityType.ROWING ||
  HealthWorkoutActivityType.ROWING_MACHINE => 'Rudern',
  HealthWorkoutActivityType.STRENGTH_TRAINING ||
  HealthWorkoutActivityType.WEIGHTLIFTING => 'Krafttraining',
  HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING => 'HIIT',
  HealthWorkoutActivityType.YOGA => 'Yoga',
  HealthWorkoutActivityType.PILATES => 'Pilates',
  HealthWorkoutActivityType.SOCCER => 'Fußball',
  HealthWorkoutActivityType.BASKETBALL => 'Basketball',
  HealthWorkoutActivityType.TENNIS => 'Tennis',
  HealthWorkoutActivityType.BOXING => 'Boxen',
  HealthWorkoutActivityType.MARTIAL_ARTS => 'Kampfsport',
  HealthWorkoutActivityType.ROCK_CLIMBING => 'Klettern',
  HealthWorkoutActivityType.ELLIPTICAL => 'Crosstrainer',
  HealthWorkoutActivityType.STAIR_CLIMBING ||
  HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE => 'Treppensteigen',
  _ => 'Training',
};
