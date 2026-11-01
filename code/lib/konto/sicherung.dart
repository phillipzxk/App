import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'konto_daten.dart';
import 'konto_dienst.dart';

/// What the backup holds right now, e.g. for "142 Check-ins · 12 Fotos".
class SicherungsInhalt {
  const SicherungsInhalt({
    this.checkIns = 0,
    this.trainings = 0,
    this.fotos = 0,
    this.videos = 0,
  });
  final int checkIns;
  final int trainings;
  final int fotos;
  final int videos;

  String get text => [
    '$checkIns ${checkIns == 1 ? 'Check-in' : 'Check-ins'}',
    '$trainings ${trainings == 1 ? 'Training' : 'Trainings'}',
    '$fotos ${fotos == 1 ? 'Foto' : 'Fotos'}',
    '$videos Form-${videos == 1 ? 'Video' : 'Videos'}',
  ].join(' · ');
}

/// Backs up everything the app keeps on the device as two files: the data,
/// and the photos and form videos (vault Umsetzung/Konto und Sicherung).
/// The device stays the main copy; the server is the safety net.
class Sicherung {
  Sicherung({
    required this.dienst,
    required this.store,
    this.clock = DateTime.now,
  });

  final KontoDienst dienst;
  final KontoStore store;
  final DateTime Function() clock;

  static const datenDatei = 'daten.json';
  static const fotoDatei = 'fotos.json';

  Future<Map<String, String>> _alles() async {
    final p = await SharedPreferences.getInstance();
    return {
      for (final k in p.getKeys())
        if (!kontoKeys.contains(k) && p.get(k) is String) k: p.getString(k)!,
    };
  }

  /// Counts for the settings page.
  Future<SicherungsInhalt> inhalt() async {
    final a = await _alles();
    int laenge(String key, [String? feld]) {
      final s = a[key];
      if (s == null) return 0;
      final j = jsonDecode(s);
      if (j is List) return j.length;
      if (j is Map && feld != null && j[feld] is List) {
        return (j[feld] as List).length;
      }
      return 0;
    }

    return SicherungsInhalt(
      checkIns: laenge('checkins'),
      trainings: laenge('training_daten', 'einheiten'),
      fotos: laenge('wochen_fotos'),
      videos: laenge('form_videos'),
    );
  }

  /// A valid session, renewed if needed.
  Future<Konto?> _konto() async {
    var k = await store.loadKonto();
    if (k == null) return null;
    if (k.abgelaufen(clock())) {
      k = await dienst.erneuern(k);
      await store.saveKonto(k);
    }
    return k;
  }

  /// Uploads everything now. Returns the new state.
  Future<SicherungsStand> sichern() async {
    final k = await _konto();
    final stand = await store.loadStand();
    if (k == null) return stand;
    final a = await _alles();
    final daten = utf8.encode(
      jsonEncode({
        for (final e in a.entries)
          if (!fotoKeys.contains(e.key)) e.key: e.value,
      }),
    );
    await dienst.hochladen(k, datenDatei, daten);
    var bytes = daten.length;
    if (stand.fotosSichern) {
      final fotos = utf8.encode(
        jsonEncode({
          for (final e in a.entries)
            if (fotoKeys.contains(e.key)) e.key: e.value,
        }),
      );
      await dienst.hochladen(k, fotoDatei, fotos);
      bytes += fotos.length;
    }
    final neu = stand.copyWith(zuletzt: clock(), bytes: bytes);
    await store.saveStand(neu);
    return neu;
  }

  /// Puts a backup from the server onto this device (new phone). Returns
  /// false when there is none yet.
  Future<bool> wiederherstellen() async {
    final k = await _konto();
    if (k == null) return false;
    final daten = await dienst.herunterladen(k, datenDatei);
    if (daten == null) return false;
    final fotos = await dienst.herunterladen(k, fotoDatei);
    final p = await SharedPreferences.getInstance();
    for (final teil in [daten, ?fotos]) {
      final j = jsonDecode(utf8.decode(teil)) as Map<String, Object?>;
      for (final e in j.entries) {
        if (e.value is String && !kontoKeys.contains(e.key)) {
          await p.setString(e.key, e.value! as String);
        }
      }
    }
    final stand = await store.loadStand();
    await store.saveStand(
      stand.copyWith(
        zuletzt: clock(),
        bytes: daten.length + (fotos?.length ?? 0),
      ),
    );
    return true;
  }

  /// Everything as one readable file ("Meine Daten herunterladen").
  Future<String> export() async {
    final a = await _alles();
    final k = await store.loadKonto();
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'Groundset',
      'erstellt': clock().toIso8601String(),
      if (k != null) 'konto': {'email': k.email, 'anmeldung': k.art.label},
      'daten': {for (final e in a.entries) e.key: _lesbar(e.value)},
    });
  }

  static Object? _lesbar(String s) {
    try {
      return jsonDecode(s);
    } on FormatException {
      return s;
    }
  }

  /// Removes everything from this device (after deleting the account or
  /// signing out on a shared phone).
  Future<void> alleDatenLoeschen() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }
}
