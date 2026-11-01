import 'dart:convert';

import 'package:http/http.dart' as http;

import 'konto_daten.dart';

/// Server address and public key, set at build time like the coach URL.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Sign-in providers switched on at the server, e.g. "apple,google".
const supabaseAnbieter = String.fromEnvironment('SUPABASE_ANBIETER');

/// Thrown with a sentence the user can read.
class KontoFehler implements Exception {
  const KontoFehler(this.text);
  final String text;
  @override
  String toString() => text;
}

/// Sign-in and the backup files on the server (Supabase, Frankfurt).
abstract class KontoDienst {
  /// True when the app talks to a real server (false in the preview
  /// without one: then any 6 numbers work and nothing leaves the device).
  bool get echt;

  /// Whether sign-in with Apple or Google is switched on yet.
  bool anbieterAn(Anmeldeart art);

  Future<void> codeSenden(String email);
  Future<Konto> codePruefen(String email, String code);

  /// Opens the Apple or Google sign-in (on the web: leaves the page and
  /// comes back with the session in the address, see [ausAdresse]).
  Future<void> mitAnbieter(Anmeldeart art);

  /// A session handed back in the address after Apple or Google.
  Future<Konto?> ausAdresse(Uri adresse);

  /// A fresh session when the old one ran out.
  Future<Konto> erneuern(Konto konto);

  Future<void> hochladen(Konto konto, String datei, List<int> inhalt);

  /// Null when the file does not exist yet.
  Future<List<int>?> herunterladen(Konto konto, String datei);

  /// Signs out here, or on all devices with [ueberall].
  Future<void> abmelden(Konto konto, {bool ueberall = false});

  /// Deletes the backup files and the account itself.
  Future<void> loeschen(Konto konto);
}

class SupabaseKontoDienst implements KontoDienst {
  SupabaseKontoDienst({
    required this.url,
    required this.key,
    this.anbieter = const {},
    http.Client? client,
  }) : _http = client ?? http.Client();

  final String url;
  final String key;
  final Set<Anmeldeart> anbieter;
  final http.Client _http;

  static const bucket = 'sicherungen';

  @override
  bool get echt => true;

  @override
  bool anbieterAn(Anmeldeart art) =>
      art == Anmeldeart.email || anbieter.contains(art);

  Map<String, String> _kopf([Konto? k]) => {
    'apikey': key,
    'Content-Type': 'application/json',
    if (k != null) 'Authorization': 'Bearer ${k.accessToken}',
  };

  Never _fehler(http.Response r, String sonst) {
    if (r.statusCode == 429) {
      throw const KontoFehler(
        'Zu viele Versuche. Warte kurz und probier es nochmal.',
      );
    }
    throw KontoFehler(sonst);
  }

  Konto _sitzung(Map<String, Object?> j, Anmeldeart art, DateTime jetzt) {
    final user = (j['user'] as Map?)?.cast<String, Object?>() ?? const {};
    return Konto(
      id: user['id'] as String? ?? '',
      email: user['email'] as String? ?? '',
      art: art,
      accessToken: j['access_token'] as String? ?? '',
      refreshToken: j['refresh_token'] as String? ?? '',
      ablauf: jetzt.add(
        Duration(seconds: (j['expires_in'] as num?)?.toInt() ?? 3600),
      ),
    );
  }

  @override
  Future<void> codeSenden(String email) async {
    final r = await _http.post(
      Uri.parse('$url/auth/v1/otp'),
      headers: _kopf(),
      body: jsonEncode({'email': email, 'create_user': true}),
    );
    if (r.statusCode >= 300) {
      _fehler(r, 'Der Code ließ sich nicht schicken. Stimmt die Adresse?');
    }
  }

  @override
  Future<Konto> codePruefen(String email, String code) async {
    final r = await _http.post(
      Uri.parse('$url/auth/v1/verify'),
      headers: _kopf(),
      body: jsonEncode({'type': 'email', 'email': email, 'token': code}),
    );
    if (r.statusCode >= 300) {
      _fehler(r, 'Der Code stimmt nicht oder ist abgelaufen.');
    }
    return _sitzung(
      jsonDecode(r.body) as Map<String, Object?>,
      Anmeldeart.email,
      DateTime.now(),
    );
  }

  @override
  Future<void> mitAnbieter(Anmeldeart art) async {
    // The redirect itself is done by the web page (see konto_web.dart).
    throw const KontoFehler('Die Anmeldung mit Apple oder Google folgt.');
  }

  /// The address to send the browser to for Apple or Google.
  Uri anbieterAdresse(Anmeldeart art, Uri zurueck) => Uri.parse(
    '$url/auth/v1/authorize',
  ).replace(queryParameters: {'provider': art.name, 'redirect_to': '$zurueck'});

  @override
  Future<Konto?> ausAdresse(Uri adresse) async {
    final teile = Uri.splitQueryString(adresse.fragment);
    final access = teile['access_token'];
    if (access == null) return null;
    final r = await _http.get(
      Uri.parse('$url/auth/v1/user'),
      headers: {'apikey': key, 'Authorization': 'Bearer $access'},
    );
    if (r.statusCode >= 300) return null;
    final user = jsonDecode(r.body) as Map<String, Object?>;
    final provider =
        ((user['app_metadata'] as Map?)?['provider'] as String?) ?? 'email';
    return _sitzung(
      {
        'user': user,
        'access_token': access,
        'refresh_token': teile['refresh_token'],
        'expires_in': int.tryParse(teile['expires_in'] ?? ''),
      },
      Anmeldeart.values.asNameMap()[provider] ?? Anmeldeart.email,
      DateTime.now(),
    );
  }

  @override
  Future<Konto> erneuern(Konto konto) async {
    final r = await _http.post(
      Uri.parse('$url/auth/v1/token?grant_type=refresh_token'),
      headers: _kopf(),
      body: jsonEncode({'refresh_token': konto.refreshToken}),
    );
    if (r.statusCode >= 300) {
      _fehler(r, 'Bitte melde dich nochmal an.');
    }
    final j = jsonDecode(r.body) as Map<String, Object?>;
    return konto.mitSitzung(
      j['access_token'] as String? ?? '',
      j['refresh_token'] as String? ?? konto.refreshToken,
      DateTime.now().add(
        Duration(seconds: (j['expires_in'] as num?)?.toInt() ?? 3600),
      ),
    );
  }

  @override
  Future<void> hochladen(Konto konto, String datei, List<int> inhalt) async {
    final r = await _http.post(
      Uri.parse('$url/storage/v1/object/$bucket/${konto.id}/$datei'),
      headers: {..._kopf(konto), 'x-upsert': 'true'},
      body: inhalt,
    );
    if (r.statusCode >= 300) {
      _fehler(
        r,
        'Die Sicherung hat nicht geklappt. Ich versuche es später nochmal.',
      );
    }
  }

  @override
  Future<List<int>?> herunterladen(Konto konto, String datei) async {
    final r = await _http.get(
      Uri.parse(
        '$url/storage/v1/object/authenticated/$bucket/${konto.id}/$datei',
      ),
      headers: _kopf(konto),
    );
    if (r.statusCode == 400 || r.statusCode == 404) return null;
    if (r.statusCode >= 300) {
      _fehler(r, 'Deine Sicherung ließ sich nicht laden.');
    }
    return r.bodyBytes;
  }

  @override
  Future<void> abmelden(Konto konto, {bool ueberall = false}) async {
    await _http.post(
      Uri.parse('$url/auth/v1/logout?scope=${ueberall ? 'global' : 'local'}'),
      headers: _kopf(konto),
    );
  }

  @override
  Future<void> loeschen(Konto konto) async {
    // First the two files, then the account (backend/supabase/schema.sql).
    final f = await _http.delete(
      Uri.parse('$url/storage/v1/object/$bucket'),
      headers: _kopf(konto),
      body: jsonEncode({
        'prefixes': ['${konto.id}/daten.json', '${konto.id}/fotos.json'],
      }),
    );
    if (f.statusCode >= 300 && f.statusCode != 404) {
      _fehler(f, 'Das Löschen hat nicht geklappt. Versuch es bitte nochmal.');
    }
    final r = await _http.post(
      Uri.parse('$url/rest/v1/rpc/konto_loeschen'),
      headers: _kopf(konto),
      body: '{}',
    );
    if (r.statusCode >= 300) {
      _fehler(r, 'Das Löschen hat nicht geklappt. Versuch es bitte nochmal.');
    }
  }
}

/// Preview without a server: every step works, nothing leaves the device.
class VorschauKontoDienst implements KontoDienst {
  VorschauKontoDienst({this.dateien});

  /// Files "on the server", for tests.
  final Map<String, List<int>>? dateien;
  late final Map<String, List<int>> _dateien = dateien ?? {};

  @override
  bool get echt => false;

  @override
  bool anbieterAn(Anmeldeart art) => true;

  @override
  Future<void> codeSenden(String email) async {
    if (!email.contains('@')) {
      throw const KontoFehler('Das sieht nicht nach einer E-Mail-Adresse aus.');
    }
  }

  @override
  Future<Konto> codePruefen(String email, String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const KontoFehler('Der Code hat 6 Zahlen.');
    }
    return Konto(id: 'vorschau', email: email, art: Anmeldeart.email);
  }

  @override
  Future<void> mitAnbieter(Anmeldeart art) async {}

  /// In the preview Apple and Google sign in straight away.
  Konto anbieterKonto(Anmeldeart art) => Konto(
    id: 'vorschau',
    email: art == Anmeldeart.apple ? 'versteckt@privaterelay.appleid.com' : '',
    art: art,
  );

  @override
  Future<Konto?> ausAdresse(Uri adresse) async => null;

  @override
  Future<Konto> erneuern(Konto konto) async => konto;

  @override
  Future<void> hochladen(Konto konto, String datei, List<int> inhalt) async =>
      _dateien['${konto.id}/$datei'] = inhalt;

  @override
  Future<List<int>?> herunterladen(Konto konto, String datei) async =>
      _dateien['${konto.id}/$datei'];

  @override
  Future<void> abmelden(Konto konto, {bool ueberall = false}) async {}

  @override
  Future<void> loeschen(Konto konto) async =>
      _dateien.removeWhere((k, _) => k.startsWith('${konto.id}/'));
}
