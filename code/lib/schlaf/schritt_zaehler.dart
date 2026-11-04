import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts real steps for the alarm task (vault Umsetzung/Echter Wecker,
/// "Schritte echt zählen"). Only while the task is open, only the number.
abstract class SchrittZaehler {
  /// Whether this device can count at all (iPhone; not the browser).
  bool get moeglich;

  /// Steps since the call, as they come in. Ends with an error when the
  /// user said no in Apple's question or the phone has no step counter.
  Stream<int> zaehlen();
}

/// Browser preview, tests and Android for now: tapping only.
class KeinZaehler implements SchrittZaehler {
  const KeinZaehler();

  @override
  bool get moeglich => false;

  @override
  Stream<int> zaehlen() => const Stream.empty();
}

/// The iPhone: CMPedometer in AppDelegate.swift over an event channel.
class IphoneSchritte implements SchrittZaehler {
  static const _kanal = EventChannel('groundset/schritte');

  @override
  bool get moeglich => true;

  @override
  Stream<int> zaehlen() =>
      _kanal.receiveBroadcastStream().map((e) => (e as num).toInt());
}

SchrittZaehler schrittZaehlerFuerPlattform() {
  if (kIsWeb) return const KeinZaehler();
  return defaultTargetPlatform == TargetPlatform.iOS
      ? IphoneSchritte()
      : const KeinZaehler();
}

/// The user's choice from the first time: count or tap. Null = not asked.
abstract class SchrittWahlStore {
  Future<bool?> zaehlenErlaubt();
  Future<void> setze(bool zaehlen);
}

const _wahlKey = 'schritte_zaehlen';

class LocalSchrittWahl implements SchrittWahlStore {
  const LocalSchrittWahl();

  @override
  Future<bool?> zaehlenErlaubt() async =>
      (await SharedPreferences.getInstance()).getBool(_wahlKey);

  @override
  Future<void> setze(bool zaehlen) async =>
      (await SharedPreferences.getInstance()).setBool(_wahlKey, zaehlen);
}

class MemorySchrittWahl implements SchrittWahlStore {
  MemorySchrittWahl([this.wert]);
  bool? wert;

  @override
  Future<bool?> zaehlenErlaubt() async => wert;

  @override
  Future<void> setze(bool zaehlen) async => wert = zaehlen;
}

/// "30 Schritte in 41 Sekunden" for the wake screen and the coach.
String schritteSatz(int schritte, Duration dauer) {
  final s = dauer.inSeconds;
  final zeit = s < 60
      ? '$s ${s == 1 ? 'Sekunde' : 'Sekunden'}'
      : s % 60 == 0
      ? '${s ~/ 60} ${s ~/ 60 == 1 ? 'Minute' : 'Minuten'}'
      : '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')} Minuten';
  return '$schritte Schritte in $zeit';
}

/// The coach line for the morning, e.g. "Heute Morgen: 30 Schritte in 41
/// Sekunden, 2 Minuten nach dem Wecker."
String morgenSatz(int schritte, Duration dauer, int minutenNachWecker) {
  final nach = minutenNachWecker <= 0
      ? 'direkt nach dem Wecker'
      : minutenNachWecker == 1
      ? '1 Minute nach dem Wecker'
      : '$minutenNachWecker Minuten nach dem Wecker';
  return 'Heute Morgen: ${schritteSatz(schritte, dauer)}, $nach.';
}
