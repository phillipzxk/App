import 'dart:convert';

import 'package:http/http.dart' as http;

import '../checkin/checkin.dart';
import '../checkin/checkin_evaluator.dart';
import '../data/user_profile.dart';
import '../feed/feed_coach.dart';
import '../feed/feed_data.dart';
import '../feed/durchgezogen.dart';
import '../feed/fokus.dart';
import '../feed/muster.dart';
import '../onboarding/onboarding_evaluator.dart';
import '../training/form_video.dart';
import '../training/training_coach.dart';
import '../training/training_data.dart';

/// Address of the coach backend (backend/ in the repo, a Cloudflare Worker)
/// and the app token it checks. Set at build time:
/// `--dart-define=COACH_URL=... --dart-define=COACH_TOKEN=...`.
const coachUrl = String.fromEnvironment('COACH_URL');
const coachToken = String.fromEnvironment('COACH_TOKEN');

/// The AI coach behind all three places the app asks it: the onboarding
/// summary, the reply to the daily check-in and the fields in the Main Feed.
/// Any failure (offline, backend down) returns null, so the app shows its
/// "kommt bald" text instead of an error.
class RemoteCoach
    implements OnboardingEvaluator, CheckInEvaluator, FeedCoach, TrainingCoach {
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
    TrainingWoche? training,
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
        'letzter': {
          'text': letzter.text,
          'geschafft': letzter.anzahlGeschafft,
          if (training != null) 'trainingGeplant': training.geplant,
          if (training != null) 'trainingGemacht': training.gemacht,
        },
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
    final b = (data?['bremse'] as String? ?? '').trim();
    return FokusAuswahl(
      vorschlaege: vorschlaege.take(3).toList(),
      rueckblick: letzter == null || r.isEmpty ? null : r,
      geschafft: letzter?.anzahlGeschafft,
      fokusText: letzter?.text,
      start: letzter?.start,
      bremse: letzter == null || b.isEmpty ? null : b,
      training: letzter == null ? null : training,
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
  Future<String?> durchgezogen(
    UserProfile profile,
    CheckIn today, {
    String? fokus,
    bool fokusGeschafft = false,
    List<Durchgezogen> bisher = const [],
  }) async {
    final data = await _postJson('/durchgezogen', {
      'profile': profileJson(profile),
      'today': today.toJson(),
      if (fokus != null) 'fokus': {'text': fokus, 'geschafft': fokusGeschafft},
      'bisher': [for (final e in bisher.reversed.take(6)) e.text],
    });
    final e = data?['eintrag'];
    return e is String && e.trim().isNotEmpty ? e.trim() : null;
  }

  @override
  Future<String?> warumSatz(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  ) async {
    final data = await _postJson('/warum', {
      'profile': profileJson(profile),
      'today': today.toJson(),
      'recent': [for (final c in recent) c.toJson()],
    });
    final s = data?['satz'];
    return s is String && s.trim().isNotEmpty ? s.trim() : null;
  }

  // Training logging (vault Umsetzung/Training eintragen.md): one route,
  // the part is named in "art".
  Future<Map?> _training(String art, Map<String, Object> body) =>
      _postJson('/training', {'art': art, ...body});

  static String? _text(Object? v, [int max = 400]) {
    if (v is! String || v.trim().isEmpty) return null;
    final t = v.trim();
    return t.length > max ? t.substring(0, max) : t;
  }

  @override
  Future<({String satz, Anpassung? anpassung})?> tagesform(
    UserProfile profile,
    CheckIn? heute,
    List<CheckIn> recent,
    String einheit,
  ) async {
    final data = await _training('tagesform', {
      'profile': profileJson(profile),
      if (heute != null) 'today': heute.toJson(),
      'recent': [for (final c in recent) c.toJson()],
      'einheit': einheit,
    });
    final satz = _text(data?['satz']);
    if (satz == null) return null;
    final a = data!['anpassung'];
    Anpassung? anpassung;
    if (a is Map && _text(a['uebung']) != null && _text(a['grund']) != null) {
      anpassung = Anpassung(
        uebung: _text(a['uebung'])!,
        saetze: (a['saetze'] as num?)?.toInt(),
        menge: (a['wdh'] as num?)?.toInt(),
        grund: _text(a['grund'])!,
      );
      if (anpassung.saetze == null && anpassung.menge == null) anpassung = null;
    }
    return (satz: satz, anpassung: anpassung);
  }

  @override
  Future<({String antwort, bool ok, SatzWert? werte})?> vorschlag(
    UserProfile profile,
    String uebung,
    String heute,
    String vorschlag,
  ) async {
    final data = await _training('vorschlag', {
      'profile': profileJson(profile),
      'uebung': uebung,
      'heute': heute,
      'vorschlag': vorschlag,
    });
    final antwort = _text(data?['antwort']);
    if (antwort == null) return null;
    final w = data!['wert'], m = data['wdh'];
    return (
      antwort: antwort,
      ok: data['ok'] != false,
      werte: w is num || m is num
          ? SatzWert((w as num?)?.toDouble(), (m as num?)?.toDouble())
          : null,
    );
  }

  @override
  Future<
    ({
      String sicht,
      String vorschlag,
      ({bool zuerst, PlanUebung uebung})? aenderung,
    })?
  >
  stagnation(
    UserProfile profile,
    PlanUebung uebung,
    String verlauf,
    String grund,
    List<CheckIn> recent,
    String tag,
  ) async {
    final data = await _training('stagnation', {
      'profile': profileJson(profile),
      'uebung': uebung.name,
      'plan': uebung.zeile,
      'verlauf': verlauf,
      'grund': grund,
      'tag': tag,
      'recent': [for (final c in recent) c.toJson()],
    });
    final sicht = _text(data?['sicht'], 600);
    final vorschlag = _text(data?['vorschlag']);
    if (sicht == null || vorschlag == null) return null;
    final a = data!['aenderung'];
    ({bool zuerst, PlanUebung uebung})? aenderung;
    if (a is Map) {
      final saetze = (a['saetze'] as num?)?.toInt();
      final von = (a['wdh_von'] as num?)?.toInt();
      final bis = (a['wdh_bis'] as num?)?.toInt();
      final wert = (a['wert'] as num?)?.toDouble();
      aenderung = (
        zuerst: a['zuerst'] == true,
        uebung: uebung.copyWith(
          saetze: saetze != null && saetze > 0 && saetze < 10 ? saetze : null,
          wdhVon: von != null && von > 0 ? von : null,
          wdhBis: bis != null && bis > 0
              ? bis
              : (von != null && von > 0 ? von : null),
          modus: von != null && bis != null && bis > von
              ? WdhModus.bereich
              : null,
          wert: wert != null && wert >= 0 ? wert : null,
          jederSatz: const [],
        ),
      );
    }
    return (sicht: sicht, vorschlag: vorschlag, aenderung: aenderung);
  }

  @override
  Future<String?> balance(UserProfile profile, String woche) async {
    final data = await _training('balance', {
      'profile': profileJson(profile),
      'woche': woche,
    });
    return _text(data?['satz']);
  }

  @override
  Future<FormHinweise?> formCheck(
    String uebung,
    String satz,
    List<String> bilder, {
    String? frueher,
  }) async {
    final data = await _training('form', {
      'uebung': uebung,
      'satz': satz,
      'bilder': bilder.take(4).toList(),
      'frueher': ?frueher,
    });
    if (data == null) return null;
    final h = FormHinweise(
      gut: [
        for (final g in data['gut'] as List? ?? const [])
          if (_text(g) != null) _text(g)!,
      ].take(3).toList(),
      besser: [
        for (final b in data['besser'] as List? ?? const [])
          if (b is Map && _text(b['text']) != null)
            (text: _text(b['text'])!, bild: (b['bild'] as num?)?.toInt()),
      ].take(3).toList(),
      vergleich: _text(data['vergleich']),
    );
    return h.leer ? null : h;
  }

  @override
  Future<String?> verlauf(
    UserProfile profile,
    String uebung,
    String verlauf,
    List<CheckIn> recent,
  ) async {
    final data = await _training('verlauf', {
      'profile': profileJson(profile),
      'uebung': uebung,
      'verlauf': verlauf,
      'recent': [for (final c in recent) c.toJson()],
    });
    return _text(data?['satz']);
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
