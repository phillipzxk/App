import 'dart:convert';

import 'package:http/http.dart' as http;

import '../checkin/checkin.dart';
import '../checkin/checkin_evaluator.dart';
import '../data/user_profile.dart';
import '../feed/feed_coach.dart';
import '../feed/feed_data.dart';
import '../feed/fokus.dart';
import '../feed/muster.dart';
import '../onboarding/onboarding_evaluator.dart';

/// Address of the coach backend (backend/ in the repo, a Cloudflare Worker)
/// and the app token it checks. Set at build time:
/// `--dart-define=COACH_URL=... --dart-define=COACH_TOKEN=...`.
const coachUrl = String.fromEnvironment('COACH_URL');
const coachToken = String.fromEnvironment('COACH_TOKEN');

/// The AI coach behind all three places the app asks it: the onboarding
/// summary, the reply to the daily check-in and the fields in the Main Feed.
/// Any failure (offline, backend down) returns null, so the app shows its
/// "kommt bald" text instead of an error.
class RemoteCoach implements OnboardingEvaluator, CheckInEvaluator, FeedCoach {
  RemoteCoach({required this.baseUrl, required this.token, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _client;

  Future<Map?> _postJson(String path, Map<String, Object> body) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'content-type': 'application/json', 'x-app-token': token},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data is Map ? data : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _post(String path, Map<String, Object> body) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'content-type': 'application/json', 'x-app-token': token},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return null;
      final text = (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['text'];
      return text is String && text.trim().isNotEmpty ? text.trim() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> summarize(UserProfile answers) =>
      _post('/onboarding', {'profile': profileJson(answers)});

  @override
  Future<String?> reply(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  ) => _post('/checkin', {
    'profile': profileJson(profile),
    'today': today.toJson(),
    'recent': [for (final c in recent) c.toJson()],
  });

  @override
  Future<Map<String, BereichsWert>?> rate(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  ) async {
    final data = await _postJson('/werte', {
      'profile': profileJson(profile),
      'today': today.toJson(),
      'recent': [for (final c in recent) c.toJson()],
    });
    final werte = data?['werte'];
    if (werte is! Map) return null;
    final out = <String, BereichsWert>{};
    for (final e in werte.entries) {
      final v = e.value;
      if (v is! Map || v['wert'] is! num) continue;
      final wert = (v['wert'] as num).round();
      if (wert < 1 || wert > 10) continue;
      out[e.key as String] = BereichsWert(wert, v['grund'] as String? ?? '');
    }
    return out.isEmpty ? null : out;
  }

  @override
  Future<Muster?> findeMuster(
    UserProfile profile,
    List<CheckIn> checkIns,
    List<Muster> bisher,
  ) async {
    final data = await _postJson('/muster', {
      'profile': profileJson(profile),
      'checkins': [
        for (final c in checkIns.skip(
          checkIns.length > 30 ? checkIns.length - 30 : 0,
        ))
          c.toJson(),
      ],
      'bisher': [
        for (final m in bisher) {'text': m.text, 'abgelehnt': m.abgelehnt},
      ],
    });
    final m = data?['muster'];
    if (m is! Map) return null;
    final text = (m['text'] as String? ?? '').trim();
    final schritt = (m['schritt'] as String? ?? '').trim();
    if (text.isEmpty || schritt.isEmpty) return null;
    final last = checkIns.isEmpty ? DateTime.now() : checkIns.last.datum;
    return Muster(
      datum: last,
      text: text,
      schritt: schritt,
      von: (m['von'] as String? ?? '').trim(),
      nach: (m['nach'] as String? ?? '').trim(),
    );
  }

  @override
  Future<FokusAuswahl?> fokusVorschlaege(
    UserProfile profile,
    List<CheckIn> checkIns,
    List<Muster> muster, {
    Wochenfokus? letzter,
  }) async {
    final data = await _postJson('/fokus', {
      'profile': profileJson(profile),
      'checkins': [
        for (final c in checkIns.skip(
          checkIns.length > 14 ? checkIns.length - 14 : 0,
        ))
          c.toJson(),
      ],
      'muster': [for (final m in muster.take(5)) m.text],
      if (letzter != null)
        'letzter': {'text': letzter.text, 'geschafft': letzter.anzahlGeschafft},
    });
    final list = data?['vorschlaege'];
    if (list is! List) return null;
    final vorschlaege = [
      for (final v in list)
        if (v is Map && (v['text'] as String? ?? '').trim().isNotEmpty)
          FokusVorschlag(
            text: (v['text'] as String).trim(),
            warum: (v['warum'] as String? ?? '').trim(),
            behalten: v['behalten'] == true,
          ),
    ];
    if (vorschlaege.isEmpty) return null;
    final r = (data?['rueckblick'] as String? ?? '').trim();
    return FokusAuswahl(
      vorschlaege: vorschlaege.take(3).toList(),
      rueckblick: letzter == null || r.isEmpty ? null : r,
      geschafft: letzter?.anzahlGeschafft,
    );
  }

  @override
  Future<List<String>?> stichpunkte(String text) async {
    final data = await _postJson('/stichpunkte', {'text': text});
    final list = data?['punkte'];
    if (list is! List) return null;
    final punkte = [
      for (final p in list)
        if (p is String && p.trim().isNotEmpty) p.trim(),
    ];
    return punkte.length < 2 ? null : punkte;
  }

  @override
  Future<String?> answer(
    UserProfile profile,
    Bereich bereich,
    String text, {
    String context = '',
  }) => _post('/feed', {
    'profile': profileJson(profile),
    'bereich': bereich.name,
    'text': text,
    'context': context,
  });
}

Map<String, Object> profileJson(UserProfile p) => {
  'name': p.name,
  'ziel': p.ziel,
  'motivation': p.motivation,
  'level': p.level,
  'training': p.training,
  'ernaehrung': p.ernaehrung,
  'schlafEnergie': p.schlafEnergie,
  'zusammenfassung': p.zusammenfassung,
};
