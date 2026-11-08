import '../data/user_profile.dart';
import '../ernaehrung/ernaehrung_logik.dart';
import '../sleep/schlafzeiten.dart';

/// Schnell-Eintrag (vault Umsetzung/Schnell-Eintrag.md, Phillip
/// 2026-11-08 "sehr geil"): say or type everything at once, the coach
/// splits it into single entries and the app files each in its area.

/// One thing out of the spoken text.
class SchnellEintrag {
  const SchnellEintrag({
    required this.art,
    required this.titel,
    this.detail = '',
    this.frage,
    this.daten = const {},
  });

  /// mahlzeit, training, termin, gewicht, schlaf, supplement,
  /// durchgezogen or notiz.
  final String art;
  final String titel;
  final String detail;

  /// Set when the coach is unsure: the card asks, "Nein" drops it.
  final String? frage;

  /// The fields of the kind, as the coach sent them.
  final Map<String, Object?> daten;

  String? text(String k) {
    final v = daten[k];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  double? zahl(String k) {
    final v = daten[k];
    return v is num ? v.toDouble() : null;
  }

  bool flag(String k) => daten[k] == true;

  /// Where the card says it goes.
  String get bereich => switch (art) {
    'mahlzeit' => 'Körper · Ernährung',
    'training' => 'Körper · Training',
    'gewicht' => 'Körper · Ernährung',
    'schlaf' => 'Körper · Schlaf',
    'supplement' => 'Körper · Supplements',
    'termin' => 'Dein Tag',
    'durchgezogen' => 'Mindset',
    _ => switch (text('bereich')) {
      'training' || 'ernaehrung' || 'schlaf' => 'Körper',
      'produktiv' => 'Fokus & Arbeit',
      'persoenlich' => 'Ausstrahlung',
      _ => 'Mindset',
    },
  };

  static SchnellEintrag? fromJson(Object? v) {
    if (v is! Map) return null;
    final art = v['art'], titel = v['titel'];
    if (art is! String || titel is! String || titel.trim().isEmpty) {
      return null;
    }
    final frage = v['unsicher'] == true && v['frage'] is String
        ? (v['frage'] as String).trim()
        : null;
    return SchnellEintrag(
      art: art,
      titel: titel.trim(),
      detail: (v['detail'] as String?)?.trim() ?? '',
      frage: frage == null || frage.isEmpty ? null : frage,
      daten: {
        for (final e in v.entries)
          if (e.key is String) e.key as String: e.value,
      },
    );
  }
}

/// What the coach made of one text.
class SchnellAntwort {
  const SchnellAntwort({this.satz, this.eintraege = const []});
  final String? satz;
  final List<SchnellEintrag> eintraege;
}

/// Route /schnell of the coach. Null: no coach or not reachable.
abstract class SchnellCoach {
  Future<SchnellAntwort?> schnell(
    UserProfile profile,
    String text,
    String kontext,
  );
}

/// One follow-up question about something important that is missing today
/// (Phillip 2026-11-08: only serious things). [ja] is filed on "Ja".
class Gegenfrage {
  const Gegenfrage({
    required this.id,
    required this.frage,
    required this.ja,
    required this.jaText,
    required this.neinText,
  });
  final String id;
  final String frage;
  final SchnellEintrag ja;
  final String jaText;
  final String neinText;
}

/// At most two questions, only about today's planned training whose time is
/// over by an hour, and main meals over by two hours, that are not logged
/// and not in [eintraege].
List<Gegenfrage> gegenfragen({
  required int jetzt,
  String? trainingName,
  int? trainingMinute,
  bool trainingGeloggt = false,
  List<MahlzeitSlot> mahlzeiten = const [],
  Set<String> gegessen = const {},
  List<SchnellEintrag> eintraege = const [],
}) {
  final out = <Gegenfrage>[];
  final trainingDrin = eintraege.any((e) => e.art == 'training');
  if (trainingName != null &&
      trainingMinute != null &&
      !trainingGeloggt &&
      !trainingDrin &&
      jetzt >= trainingMinute + 60) {
    out.add(
      Gegenfrage(
        id: 'training',
        frage:
            '„$trainingName“ war für ${formatUhrzeit(trainingMinute)} geplant. Hast du trainiert?',
        ja: SchnellEintrag(
          art: 'training',
          titel: '$trainingName gemacht',
          detail: 'als fertig im Training',
          daten: const {'fertig': true, 'uebung': ''},
        ),
        jaText: 'Ja, gemacht',
        neinText: 'Nein, heute nicht',
      ),
    );
  }
  final drin = {
    for (final e in eintraege)
      if (e.art == 'mahlzeit') e.text('mahlzeit'),
  };
  for (final m in mahlzeiten) {
    if (out.length >= 2) break;
    if (m.snack || gegessen.contains(m.id)) continue;
    if (jetzt < m.minute + 120) continue;
    final wort = _wort(m.id);
    if (drin.contains(wort)) continue;
    out.add(
      Gegenfrage(
        id: 'mahlzeit-${m.id}',
        frage: 'Hast du ${_artikel(m)} schon gegessen?',
        ja: SchnellEintrag(
          art: 'mahlzeit',
          titel: '${m.name} gegessen',
          detail: 'in Mahlzeiten heute',
          daten: {'mahlzeit': wort, 'slot': m.id},
        ),
        jaText: 'Ja',
        neinText: 'Noch nicht',
      ),
    );
  }
  return out.take(2).toList();
}

String _wort(String id) => switch (id) {
  'fruehstueck' => 'fruehstueck',
  'mittag' => 'mittag',
  'abend' || 'nach' => 'abend',
  _ => 'snack',
};

String _artikel(MahlzeitSlot m) => switch (m.id) {
  'fruehstueck' => 'dein Frühstück',
  'mittag' => 'zu Mittag',
  'abend' => 'zu Abend',
  'nach' => 'nach dem Training',
  _ => m.name,
};

/// The meal slot an entry goes to: an exact slot from a follow-up, else the
/// matching open slot, else the open slot nearest to now. Null: no slot.
MahlzeitSlot? slotFuer(
  SchnellEintrag e,
  List<MahlzeitSlot> mahlzeiten,
  Set<String> gegessen,
  int jetzt,
) {
  final slot = e.text('slot');
  for (final m in mahlzeiten) {
    if (m.id == slot) return m;
  }
  final offen = [
    for (final m in mahlzeiten)
      if (!gegessen.contains(m.id)) m,
  ];
  if (offen.isEmpty) return null;
  final wort = e.text('mahlzeit') ?? 'snack';
  for (final m in offen) {
    if (_wort(m.id) == wort && (wort != 'snack' || m.snack)) return m;
  }
  offen.sort(
    (a, b) => (a.minute - jetzt).abs().compareTo((b.minute - jetzt).abs()),
  );
  return offen.first;
}
