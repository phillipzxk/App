import 'package:flutter/foundation.dart';

import '../business/business_coach.dart' show tippsAus, zeilenAus;
import '../data/user_profile.dart';
import 'persoenlich_data.dart';

/// What the coach does on the Persönlichkeit page (route /persoenlich). One
/// call with an [art]; the typed helpers below read the answer. Null means
/// no coach or not reachable.
abstract class PersoenlichCoach {
  Future<Map?> persoenlich(
    UserProfile profile,
    String art,
    Map<String, Object> mehr,
  );
}

class NoPersoenlichCoach implements PersoenlichCoach {
  const NoPersoenlichCoach();

  @override
  Future<Map?> persoenlich(
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

Quiz? quizAus(Object? v) {
  if (v is! Map) return null;
  final f = _t(v['frage'], 200);
  final a = zeilenAus(v['antworten'], max: 4);
  final r = (v['richtig'] as num?)?.toInt();
  if (f == null || a.length < 2 || r == null || r < 0 || r >= a.length) {
    return null;
  }
  return Quiz(frage: f, antworten: a, richtig: r);
}

final _hex = RegExp(r'^#[0-9a-fA-F]{6}$');

extension PersoenlichFragen on PersoenlichCoach {
  Future<FotoBefund?> look(UserProfile p, String bild, String tag) async {
    final d = await persoenlich(p, 'look', {'bild': bild});
    final t = _t(d?['titel'], 80);
    final h = tippsAus(d?['hebel'], max: 3);
    if (t == null || h.isEmpty) return null;
    return FotoBefund(tag: tag, titel: t, punkte: h);
  }

  Future<FotoBefund?> stil(UserProfile p, String bild, String tag) async {
    final d = await persoenlich(p, 'stil', {'bild': bild});
    final t = _t(d?['titel'], 80);
    if (t == null) return null;
    return FotoBefund(
      tag: tag,
      titel: t,
      passt: _t(d!['passt'], 300),
      aendern: _t(d['aendern'], 300),
      farben: [
        for (final f in zeilenAus(d['farben'], max: 6))
          if (_hex.hasMatch(f)) f,
      ],
    );
  }

  Future<FotoBefund?> haltung(UserProfile p, String bild, String tag) async {
    final d = await persoenlich(p, 'haltung', {'bild': bild});
    final t = _t(d?['befund'], 200);
    final u = tippsAus(d?['uebungen'], max: 3);
    if (t == null || u.isEmpty) return null;
    return FotoBefund(tag: tag, titel: t, punkte: u);
  }

  Future<List<Tipp>?> haut(UserProfile p, String problem) async {
    final l = tippsAus(
      (await persoenlich(p, 'haut', {'problem': problem}))?['phasen'],
      max: 4,
    );
    return l.length < 2 ? null : l;
  }

  Future<Frisur?> frisur(
    UserProfile p,
    String beschreibung,
    String? bild,
  ) async {
    final d = await persoenlich(p, 'frisur', {
      'beschreibung': beschreibung,
      'bild': ?bild,
    });
    final e = _t(d?['empfehlung'], 120);
    final f = _t(d?['friseur'], 500);
    if (e == null || f == null) return null;
    return Frisur(
      empfehlung: e,
      friseur: f,
      styling: _t(d!['styling'], 300),
      wochen: ((d['wochen'] as num?)?.toInt() ?? 4).clamp(2, 12),
    );
  }

  Future<List<String>?> kurs(UserProfile p, String skill) async {
    final l = zeilenAus(
      (await persoenlich(p, 'kurs', {'skill': skill}))?['lektionen'],
      max: 12,
    );
    return l.length < 8 ? null : l;
  }

  Future<({String text, Quiz quiz})?> lektion(
    UserProfile p,
    String skill,
    String titel,
    int nummer,
  ) async {
    final d = await persoenlich(p, 'lektion', {
      'skill': skill,
      'titel': titel,
      'nummer': nummer,
    });
    final t = _t(d?['text'], 700);
    final q = quizAus(d);
    if (t == null || q == null) return null;
    return (text: t, quiz: q);
  }

  Future<List<Quiz>?> buchQuiz(UserProfile p, String buch) async {
    final d = await persoenlich(p, 'quiz', {'buch': buch});
    final l = [for (final x in d?['fragen'] as List? ?? const []) ?quizAus(x)]
        .take(3)
        .toList();
    return l.isEmpty ? null : l;
  }

  Future<String?> umsetzen(
    UserProfile p,
    String quelle,
    String gelernt,
    String kontext,
  ) async => _t(
    (await persoenlich(p, 'umsetzen', {
      'quelle': quelle,
      'gelernt': gelernt,
      'kontext': kontext,
    }))?['schritt'],
    200,
  );
}

/// The Persönlichkeit data in memory; every change is saved right away.
class PersoenlichStand extends ChangeNotifier {
  PersoenlichStand(this._speichern);

  final Future<void> Function(PersoenlichDaten d) _speichern;
  PersoenlichDaten _d = const PersoenlichDaten();
  PersoenlichDaten get d => _d;

  void laden(PersoenlichDaten d) {
    _d = d;
    notifyListeners();
  }

  Future<void> setze(PersoenlichDaten d) async {
    _d = d;
    notifyListeners();
    await _speichern(d);
  }
}
