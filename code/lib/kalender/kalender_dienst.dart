import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../checkin/checkin.dart';
import '../planner/planner_data.dart';

/// Kalender verbinden (vault Umsetzung/Kalender verbinden.md, Phillip
/// 2026-11-09 "yes"): one button, then the appointments come only from
/// the phone's calendar and the app's own list is gone.

/// One calendar on the phone, e.g. "Privat" or "Arbeit".
class KalenderInfo {
  const KalenderInfo({
    required this.id,
    required this.name,
    this.farbe = 0xFFE0BF7E,
    this.schreibbar = true,
  });
  final String id;
  final String name;

  /// ARGB, as the calendar app shows it.
  final int farbe;

  /// False for e.g. holidays: nothing can be added there.
  final bool schreibbar;
}

/// What the user chose: connected, which calendars are hidden and where
/// new appointments go.
class KalenderEinstellung {
  const KalenderEinstellung({
    this.verbunden = false,
    this.aus = const {},
    this.ziel,
  });
  final bool verbunden;

  /// Ids of the calendars not shown.
  final Set<String> aus;

  /// Id of the calendar new appointments go to; null: the phone's default.
  final String? ziel;

  KalenderEinstellung copyWith({
    bool? verbunden,
    Set<String>? aus,
    String? Function()? ziel,
  }) => KalenderEinstellung(
    verbunden: verbunden ?? this.verbunden,
    aus: aus ?? this.aus,
    ziel: ziel == null ? this.ziel : ziel(),
  );

  Map<String, dynamic> toJson() => {
    'verbunden': verbunden,
    'aus': aus.toList(),
    'ziel': ziel,
  };

  factory KalenderEinstellung.fromJson(Map<String, dynamic> j) =>
      KalenderEinstellung(
        verbunden: j['verbunden'] == true,
        aus: {
          for (final a in (j['aus'] as List?) ?? const [])
            if (a is String) a,
        },
        ziel: j['ziel'] as String?,
      );
}

/// The phone's calendar.
abstract class KalenderDienst {
  /// Whether this device can connect at all.
  bool get moeglich;

  /// "iPhone-Kalender" or "Handy-Kalender".
  String get name;

  /// Shows the phone's own question. True when allowed.
  Future<bool> verbinden();

  /// All calendars, the phone's default for new appointments first.
  Future<List<KalenderInfo>> kalender();

  /// Appointments from [von] to [bis] (days), without the calendars in
  /// [aus]. Each carries its calendar's name in [Termin.kalender].
  Future<List<Termin>> termine(DateTime von, DateTime bis, Set<String> aus);

  /// Adds [t] to the calendar [kalenderId] (null: default). An hour long
  /// with a time, else all day. True when it worked.
  Future<bool> anlegen(Termin t, String? kalenderId);
}

/// Tests and Android for now.
class KeinKalender implements KalenderDienst {
  const KeinKalender();
  @override
  bool get moeglich => false;
  @override
  String get name => 'Handy-Kalender';
  @override
  Future<bool> verbinden() async => false;
  @override
  Future<List<KalenderInfo>> kalender() async => const [];
  @override
  Future<List<Termin>> termine(DateTime v, DateTime b, Set<String> a) async =>
      const [];
  @override
  Future<bool> anlegen(Termin t, String? k) async => false;
}

int _ms(DateTime d) => d.millisecondsSinceEpoch;
DateTime _tag(DateTime d) => DateTime(d.year, d.month, d.day);

/// Start of [t] (its time, or midnight when it has none).
DateTime terminStart(Termin t) {
  final m = parseUhrzeitText(t.zeit);
  final tag = _tag(t.datum);
  return m == null ? tag : tag.add(Duration(minutes: m));
}

/// "17:30" -> 1050; null when it isn't a time.
int? parseUhrzeitText(String? s) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s?.trim() ?? '');
  if (m == null) return null;
  final h = int.parse(m.group(1)!), min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

/// The iPhone: EventKit in AppDelegate.swift over a channel.
class IphoneKalender implements KalenderDienst {
  static const _kanal = MethodChannel('groundset/kalender');

  @override
  bool get moeglich => true;

  @override
  String get name => 'iPhone-Kalender';

  @override
  Future<bool> verbinden() async {
    try {
      return await _kanal.invokeMethod<bool>('verbinden') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<List<KalenderInfo>> kalender() async {
    try {
      final l = await _kanal.invokeListMethod<Object?>('kalender') ?? [];
      return [
        for (final k in l)
          if (k is Map)
            KalenderInfo(
              id: '${k['id']}',
              name: '${k['name']}',
              farbe: (k['farbe'] as num?)?.toInt() ?? 0xFFE0BF7E,
              schreibbar: k['schreibbar'] != false,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Termin>> termine(
    DateTime von,
    DateTime bis,
    Set<String> aus,
  ) async {
    try {
      final l =
          await _kanal.invokeListMethod<Object?>('termine', {
            'von': _ms(_tag(von)),
            'bis': _ms(_tag(bis).add(const Duration(days: 1))),
            'aus': aus.toList(),
          }) ??
          [];
      return [
        for (final e in l)
          if (e is Map) ?_ausHandy(e),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Termin? _ausHandy(Map<Object?, Object?> e) {
    final start = e['start'], titel = e['titel'];
    if (start is! num || titel is! String) return null;
    final s = DateTime.fromMillisecondsSinceEpoch(start.toInt());
    final ganz = e['ganztags'] == true;
    return Termin(
      datum: _tag(s),
      zeit: ganz
          ? null
          : '${s.hour.toString().padLeft(2, '0')}:'
                '${s.minute.toString().padLeft(2, '0')}',
      text: titel.trim().isEmpty ? 'Termin' : titel.trim(),
      erstellt: s,
      kalender: (e['kalender'] as String?) ?? 'Kalender',
    );
  }

  @override
  Future<bool> anlegen(Termin t, String? kalenderId) async {
    try {
      return await _kanal.invokeMethod<bool>('anlegen', {
            'titel': t.text,
            'start': _ms(terminStart(t)),
            'ganztags': parseUhrzeitText(t.zeit) == null,
            'kalender': kalenderId,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}

/// Browser preview: connecting works, then the example appointments of the
/// draft; new ones are kept in the browser.
class VorschauKalender implements KalenderDienst {
  VorschauKalender({this.clock = DateTime.now});
  final DateTime Function() clock;
  static const _key = 'vorschau_kalender';

  static const _liste = [
    KalenderInfo(id: 'privat', name: 'Privat', farbe: 0xFFE6A157),
    KalenderInfo(id: 'arbeit', name: 'Arbeit', farbe: 0xFF7FA6D9),
    KalenderInfo(
      id: 'feiertage',
      name: 'Feiertage',
      farbe: 0xFF9BC48A,
      schreibbar: false,
    ),
  ];

  @override
  bool get moeglich => true;

  @override
  String get name => 'iPhone-Kalender';

  @override
  Future<bool> verbinden() async => true;

  @override
  Future<List<KalenderInfo>> kalender() async => _liste;

  Future<List<(String, Termin)>> _eigene() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return [];
    return [
      for (final e in jsonDecode(raw) as List)
        if (Termin.fromJson((e['t'] as Map).cast<String, dynamic>())
            case final t)
          (
            e['k'] as String,
            Termin(
              datum: t.datum,
              zeit: t.zeit,
              text: t.text,
              erstellt: t.erstellt,
              kalender: _liste
                  .firstWhere((x) => x.id == e['k'], orElse: () => _liste.first)
                  .name,
            ),
          ),
    ];
  }

  @override
  Future<List<Termin>> termine(
    DateTime von,
    DateTime bis,
    Set<String> aus,
  ) async {
    final h = _tag(clock());
    Termin b(int tag, String? zeit, String text, String k) => Termin(
      datum: h.add(Duration(days: tag)),
      zeit: zeit,
      text: text,
      erstellt: h.add(Duration(days: tag, minutes: text.length)),
      kalender: _liste.firstWhere((x) => x.id == k).name,
    );
    final alle = <(String, Termin)>[
      ('privat', b(0, '10:00', 'Zahnarzt', 'privat')),
      ('arbeit', b(0, '13:00', 'Call mit Paul', 'arbeit')),
      ('privat', b(0, '19:30', 'Essen mit Lisa', 'privat')),
      ('arbeit', b(2, '09:00', 'Teammeeting', 'arbeit')),
      ('privat', b(4, '18:00', 'Geburtstag Mama', 'privat')),
      ...await _eigene(),
    ];
    final v = dayKey(von), z = dayKey(bis);
    return [
      for (final (k, t) in alle)
        if (!aus.contains(k) &&
            dayKey(t.datum).compareTo(v) >= 0 &&
            dayKey(t.datum).compareTo(z) <= 0)
          t,
    ];
  }

  @override
  Future<bool> anlegen(Termin t, String? kalenderId) async {
    final k = kalenderId ?? _liste.first.id;
    final name = _liste
        .firstWhere((x) => x.id == k, orElse: () => _liste.first)
        .name;
    final neu = [
      ...await _eigene(),
      (
        k,
        Termin(
          datum: t.datum,
          zeit: t.zeit,
          text: t.text,
          erstellt: t.erstellt,
          kalender: name,
        ),
      ),
    ];
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode([
        for (final (k, t) in neu) {'k': k, 't': t.toJson()},
      ]),
    );
    return true;
  }
}

KalenderDienst kalenderFuerPlattform() {
  if (kIsWeb) return VorschauKalender();
  return defaultTargetPlatform == TargetPlatform.iOS
      ? IphoneKalender()
      : const KeinKalender();
}
