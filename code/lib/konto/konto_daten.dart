import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// How someone signed in (vault Umsetzung/Konto und Sicherung.md).
enum Anmeldeart { apple, google, email }

extension AnmeldeartName on Anmeldeart {
  String get label => switch (this) {
    Anmeldeart.apple => 'Apple',
    Anmeldeart.google => 'Google',
    Anmeldeart.email => 'E-Mail',
  };
}

/// The signed-in account with its session, kept on this device only.
class Konto {
  const Konto({
    required this.id,
    required this.email,
    required this.art,
    this.accessToken = '',
    this.refreshToken = '',
    this.ablauf,
  });

  final String id;
  final String email;
  final Anmeldeart art;
  final String accessToken;
  final String refreshToken;

  /// When [accessToken] runs out.
  final DateTime? ablauf;

  bool abgelaufen(DateTime jetzt) =>
      ablauf != null &&
      !jetzt.isBefore(ablauf!.subtract(const Duration(minutes: 1)));

  Konto mitSitzung(String access, String refresh, DateTime ablauf) => Konto(
    id: id,
    email: email,
    art: art,
    accessToken: access,
    refreshToken: refresh,
    ablauf: ablauf,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'art': art.name,
    'access': accessToken,
    'refresh': refreshToken,
    'ablauf': ablauf?.toIso8601String(),
  };

  factory Konto.fromJson(Map<String, Object?> j) => Konto(
    id: j['id'] as String? ?? '',
    email: j['email'] as String? ?? '',
    art: Anmeldeart.values.asNameMap()[j['art']] ?? Anmeldeart.email,
    accessToken: j['access'] as String? ?? '',
    refreshToken: j['refresh'] as String? ?? '',
    ablauf: DateTime.tryParse(j['ablauf'] as String? ?? ''),
  );
}

/// What the settings page shows and the two switches.
class SicherungsStand {
  const SicherungsStand({
    this.zuletzt,
    this.bytes = 0,
    this.fotosSichern = true,
    this.nurWlan = true,
  });

  /// Last successful backup, null if none yet.
  final DateTime? zuletzt;
  final int bytes;
  final bool fotosSichern;
  final bool nurWlan;

  SicherungsStand copyWith({
    DateTime? zuletzt,
    int? bytes,
    bool? fotosSichern,
    bool? nurWlan,
  }) => SicherungsStand(
    zuletzt: zuletzt ?? this.zuletzt,
    bytes: bytes ?? this.bytes,
    fotosSichern: fotosSichern ?? this.fotosSichern,
    nurWlan: nurWlan ?? this.nurWlan,
  );

  Map<String, Object?> toJson() => {
    'zuletzt': zuletzt?.toIso8601String(),
    'bytes': bytes,
    'fotos': fotosSichern,
    'wlan': nurWlan,
  };

  factory SicherungsStand.fromJson(Map<String, Object?> j) => SicherungsStand(
    zuletzt: DateTime.tryParse(j['zuletzt'] as String? ?? ''),
    bytes: (j['bytes'] as num?)?.toInt() ?? 0,
    fotosSichern: j['fotos'] as bool? ?? true,
    nurWlan: j['wlan'] as bool? ?? true,
  );
}

/// Keys of the account itself: never part of a backup.
const kontoKeys = {'konto', 'sicherung_stand'};

/// Keys holding photos and form videos (big, can be switched off).
const fotoKeys = {'wochen_fotos', 'form_videos'};

/// Account and backup state on this device.
abstract class KontoStore {
  Future<Konto?> loadKonto();
  Future<void> saveKonto(Konto? konto);
  Future<SicherungsStand> loadStand();
  Future<void> saveStand(SicherungsStand stand);
}

class LocalKontoStore implements KontoStore {
  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  @override
  Future<Konto?> loadKonto() async {
    final s = (await _p).getString('konto');
    if (s == null || s.isEmpty) return null;
    return Konto.fromJson(jsonDecode(s) as Map<String, Object?>);
  }

  @override
  Future<void> saveKonto(Konto? konto) async {
    final p = await _p;
    if (konto == null) {
      await p.remove('konto');
    } else {
      await p.setString('konto', jsonEncode(konto.toJson()));
    }
  }

  @override
  Future<SicherungsStand> loadStand() async {
    final s = (await _p).getString('sicherung_stand');
    if (s == null || s.isEmpty) return const SicherungsStand();
    return SicherungsStand.fromJson(jsonDecode(s) as Map<String, Object?>);
  }

  @override
  Future<void> saveStand(SicherungsStand stand) async =>
      (await _p).setString('sicherung_stand', jsonEncode(stand.toJson()));
}

class MemoryKontoStore implements KontoStore {
  Konto? konto;
  SicherungsStand stand = const SicherungsStand();

  @override
  Future<Konto?> loadKonto() async => konto;

  @override
  Future<void> saveKonto(Konto? k) async => konto = k;

  @override
  Future<SicherungsStand> loadStand() async => stand;

  @override
  Future<void> saveStand(SicherungsStand s) async => stand = s;
}

/// "214 MB", "820 KB".
String formatGroesse(int bytes) {
  if (bytes >= 1024 * 1024) {
    final mb = bytes / (1024 * 1024);
    return '${mb >= 10 ? mb.round() : mb.toStringAsFixed(1).replaceAll('.', ',')} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}

/// "gerade eben", "vor 2 Min.", "vor 3 Std.", "gestern", "am 12.10.".
String formatZuletzt(DateTime? t, DateTime jetzt) {
  if (t == null) return 'noch nie';
  final d = jetzt.difference(t);
  if (d.inMinutes < 1) return 'gerade eben';
  if (d.inMinutes < 60) return 'vor ${d.inMinutes} Min.';
  if (d.inHours < 24) return 'vor ${d.inHours} Std.';
  if (d.inDays == 1) return 'gestern';
  return 'am ${t.day}.${t.month}.';
}
