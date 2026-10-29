import 'package:flutter/foundation.dart';

import '../data/user_profile.dart';
import 'business_data.dart';

/// What the coach does on the Business page (route /business). One call
/// with an [art]; the typed helpers below read the answer. Every call may
/// return null (no coach or not reachable); the page then has its own
/// fallback.
abstract class BusinessCoach {
  Future<Map?> business(
    UserProfile profile,
    String art,
    Map<String, Object> mehr,
  );
}

class NoBusinessCoach implements BusinessCoach {
  const NoBusinessCoach();

  @override
  Future<Map?> business(
    UserProfile profile,
    String art,
    Map<String, Object> mehr,
  ) async => null;
}

String? _t(Object? v, [int max = 400]) {
  if (v is! String) return null;
  final s = v.trim();
  if (s.isEmpty) return null;
  return s.length > max ? '${s.substring(0, max - 1)}…' : s;
}

List<Tipp> tippsAus(Object? v, {int max = 4}) => [
  for (final x in v as List? ?? const [])
    if (x is Map && _t(x['titel'], 120) != null)
      Tipp(_t(x['titel'], 120)!, _t(x['text'], 300) ?? ''),
].take(max).toList();

List<String> zeilenAus(Object? v, {int max = 8}) =>
    [for (final x in v as List? ?? const []) ?_t(x, 160)].take(max).toList();

/// The typed calls.
extension BusinessFragen on BusinessCoach {
  /// A lever for the week: the action, its single steps and 3 tips.
  Future<({String hebel, List<String> punkte, List<Tipp> tipps})?> hebel(
    UserProfile p,
    String kontext,
  ) async {
    final d = await business(p, 'hebel', {'kontext': kontext});
    final h = _t(d?['hebel'], 160);
    if (h == null) return null;
    return (
      hebel: h,
      punkte: zeilenAus(d!['punkte'], max: 5),
      tipps: tippsAus(d['tipps'], max: 3),
    );
  }

  Future<List<Tipp>?> tipps(UserProfile p, String hebel, String kontext) async {
    final l = tippsAus(
      (await business(p, 'tipps', {
        'hebel': hebel,
        'kontext': kontext,
      }))?['tipps'],
      max: 3,
    );
    return l.isEmpty ? null : l;
  }

  Future<({String angebot, int? preis})?> ersterEuro(
    UserProfile p,
    String idee,
    String kontext,
  ) async {
    final d = await business(p, 'euro', {'idee': idee, 'kontext': kontext});
    final a = _t(d?['angebot'], 200);
    if (a == null) return null;
    return (angebot: a, preis: (d!['preis'] as num?)?.toInt());
  }

  Future<String?> lohntSich(
    UserProfile p,
    String frage,
    String kontext,
  ) async => _t(
    (await business(p, 'lohnt', {
      'frage': frage,
      'kontext': kontext,
    }))?['antwort'],
    500,
  );

  Future<({List<Tipp> tipps, String? satz})?> sparen(
    UserProfile p,
    String ausgaben,
    String kontext,
  ) async {
    final d = await business(p, 'sparen', {
      'ausgaben': ausgaben,
      'kontext': kontext,
    });
    final l = tippsAus(d?['tipps'], max: 3);
    if (l.isEmpty) return null;
    return (tipps: l, satz: _t(d!['satz'], 300));
  }

  Future<String?> stundenFokus(UserProfile p, String kontext) async =>
      _t((await business(p, 'stunde', {'kontext': kontext}))?['satz'], 400);

  Future<({String ziel, List<String> schritte})?> ausarbeiten(
    UserProfile p,
    String idee,
    List<String> gedanken,
    String kontext,
  ) async {
    final d = await business(p, 'ausarbeiten', {
      'idee': idee,
      'gedanken': gedanken,
      'kontext': kontext,
    });
    final z = _t(d?['ziel'], 200);
    final s = zeilenAus(d?['schritte'], max: 8);
    if (z == null || s.length < 2) return null;
    return (ziel: z, schritte: s);
  }

  Future<List<String>?> pruefFragen(
    UserProfile p,
    String idee,
    String kontext,
  ) async {
    final l = zeilenAus(
      (await business(p, 'pruefen', {
        'idee': idee,
        'kontext': kontext,
      }))?['fragen'],
      max: 5,
    );
    return l.length < 3 ? null : l;
  }

  Future<({int reife, String satz})?> urteil(
    UserProfile p,
    IdeePruefung pr,
  ) async {
    final d = await business(p, 'urteil', {
      'idee': pr.idee,
      'fragen': [
        for (final f in pr.fragen)
          {'frage': f.frage, 'antwort': f.antwort ?? ''},
      ],
    });
    final r = (d?['reife'] as num?)?.toInt();
    final s = _t(d?['satz'], 400);
    if (r == null || s == null) return null;
    return (reife: r.clamp(0, 100), satz: s);
  }

  Future<({List<Tipp> schritte, List<Einwand> einwaende})?> gespraech(
    UserProfile p,
    String mit,
    String ziel,
    String kontext,
  ) async {
    final d = await business(p, 'gespraech', {
      'mit': mit,
      'ziel': ziel,
      'kontext': kontext,
    });
    final s = tippsAus(d?['schritte'], max: 5);
    if (s.length < 3) return null;
    return (
      schritte: s,
      einwaende: [
        for (final x in d!['einwaende'] as List? ?? const [])
          if (x is Map &&
              _t(x['sagt'], 160) != null &&
              _t(x['antwort'], 300) != null)
            Einwand(_t(x['sagt'], 160)!, _t(x['antwort'], 300)!),
      ].take(3).toList(),
    );
  }

  Future<List<String>?> meilensteine(UserProfile p, String kontext) async {
    final l = zeilenAus(
      (await business(p, 'meilensteine', {'kontext': kontext}))?['vorschlaege'],
      max: 3,
    );
    return l.isEmpty ? null : l;
  }

  Future<List<Tipp>?> skillStufen(
    UserProfile p,
    String skill,
    String kontext,
  ) async {
    final l = tippsAus(
      (await business(p, 'skill', {
        'skill': skill,
        'kontext': kontext,
      }))?['stufen'],
      max: 7,
    );
    return l.length < 5 ? null : l;
  }
}

/// The Business data in memory; every change is saved right away.
class BusinessStand extends ChangeNotifier {
  BusinessStand(this._speichern);

  final Future<void> Function(BusinessDaten d) _speichern;
  BusinessDaten _d = const BusinessDaten();
  BusinessDaten get d => _d;

  void laden(BusinessDaten d) {
    _d = d;
    notifyListeners();
  }

  Future<void> setze(BusinessDaten d) async {
    _d = d;
    notifyListeners();
    await _speichern(d);
  }
}
