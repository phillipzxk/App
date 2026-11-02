import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../checkin/checkin.dart';
import 'health_daten.dart';

/// Reads Apple Health (vault Umsetzung/Apple Health.md). Only reads,
/// never writes. Google Health Connect comes with the Android version.
abstract class HealthDienst {
  /// Whether this device can connect at all (iPhone; the browser preview
  /// shows example data).
  bool get moeglich;

  /// Whether the user connected once.
  Future<bool> verbunden();

  /// Shows Apple's own question. True when the user went through it.
  Future<bool> verbinden();

  /// Today's values, the night before included. Null when nothing came.
  Future<HealthTag?> lesen(DateTime heute);
}

const _verbundenKey = 'health_verbunden';

/// Tests and Android for now: no Health.
class KeinHealth implements HealthDienst {
  const KeinHealth();

  @override
  bool get moeglich => false;

  @override
  Future<bool> verbunden() async => false;

  @override
  Future<bool> verbinden() async => false;

  @override
  Future<HealthTag?> lesen(DateTime heute) async => null;
}

/// The iPhone: HealthKit in AppDelegate.swift over a channel.
class AppleHealth implements HealthDienst {
  static const _kanal = MethodChannel('groundset/health');

  @override
  bool get moeglich => true;

  @override
  Future<bool> verbunden() async =>
      (await SharedPreferences.getInstance()).getBool(_verbundenKey) ?? false;

  @override
  Future<bool> verbinden() async {
    try {
      final ok = await _kanal.invokeMethod<bool>('verbinden') ?? false;
      if (ok) {
        await (await SharedPreferences.getInstance()).setBool(
          _verbundenKey,
          true,
        );
      }
      return ok;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<HealthTag?> lesen(DateTime heute) async {
    if (!await verbunden()) return null;
    try {
      final m = await _kanal
          .invokeMapMethod<Object?, Object?>('lesen', {
            'tag': DateTime(
              heute.year,
              heute.month,
              heute.day,
            ).millisecondsSinceEpoch,
            'jetzt': heute.millisecondsSinceEpoch,
          })
          .timeout(const Duration(seconds: 8));
      if (m == null) return null;
      final t = HealthTag.ausHandy(heute, m);
      return t.leer ? null : t;
    } catch (_) {
      return null;
    }
  }
}

/// Browser preview: connecting works, then example values like in the
/// draft, so the design can be seen.
class VorschauHealth implements HealthDienst {
  @override
  bool get moeglich => true;

  @override
  Future<bool> verbunden() async =>
      (await SharedPreferences.getInstance()).getBool(_verbundenKey) ?? false;

  @override
  Future<bool> verbinden() async {
    await (await SharedPreferences.getInstance()).setBool(_verbundenKey, true);
    return true;
  }

  @override
  Future<HealthTag?> lesen(DateTime heute) async {
    if (!await verbunden()) return null;
    return beispielTag(heute);
  }
}

/// The night and values from Entwurf 2.
HealthTag beispielTag(DateTime heute) {
  final h = DateTime(heute.year, heute.month, heute.day);
  DateTime t(int stunde, int minute) =>
      h.add(Duration(hours: stunde, minutes: minute));
  const k = PhaseArt.kern, r = PhaseArt.rem, d = PhaseArt.tief;
  const w = PhaseArt.wach;
  final teile = [
    (-1, 12, k),
    (-1, 40, d),
    (0, 35, k),
    (1, 0, r),
    (1, 20, w),
    (1, 25, k),
    (1, 55, d),
    (2, 40, k),
    (3, 20, r),
    (3, 50, k),
    (4, 30, w),
    (4, 38, k),
    (5, 10, r),
    (5, 45, k),
    (6, 25, w),
    (6, 30, r),
  ];
  final phasen = <SchlafPhase>[
    for (var i = 0; i < teile.length; i++)
      SchlafPhase(
        t(teile[i].$1, teile[i].$2),
        i + 1 < teile.length ? t(teile[i + 1].$1, teile[i + 1].$2) : t(6, 41),
        teile[i].$3,
      ),
  ];
  final jetzt = heute;
  return HealthTag(
    tag: dayKey(h),
    nacht: HealthNacht(phasen),
    ruhepuls: 58,
    ruhepulsSchnitt: 52,
    hrv: 41,
    hrvSchnitt: 61,
    schritte: jetzt.hour < 8 ? 120 : 4280,
    tageslicht: jetzt.hour < 9 ? 0 : 12,
    gewicht: 81.4,
    gewichtZeit: t(6, 50),
    trainings: [
      if (jetzt.hour >= 8)
        UhrTraining(art: 'Laufen', start: t(7, 10), minuten: 32),
    ],
  );
}

HealthDienst healthFuerPlattform() {
  if (kIsWeb) return VorschauHealth();
  return defaultTargetPlatform == TargetPlatform.iOS
      ? AppleHealth()
      : const KeinHealth();
}
