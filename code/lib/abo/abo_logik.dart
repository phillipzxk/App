import '../checkin/checkin.dart';
import '../checkin/checkin_evaluator.dart';
import '../data/user_profile.dart';
import '../feed/durchgezogen.dart';
import '../feed/fokus.dart';
import '../feed/muster.dart';
import 'abo_daten.dart';

/// The coach's look back at a week (worker route /woche).
abstract class WochenCoach {
  Future<String?> wochenRueckblick(
    UserProfile profile,
    List<CheckIn> woche, {
    String muster = '',
    bool erste = false,
  });
}

/// What the coach may still do without Abo: the area values (so Heute and
/// the roots are not empty), patterns, the Sunday sentence and the
/// onboarding summary. Everything else stays silent.
const freiePfade = {'/werte', '/muster', '/woche', '/onboarding'};

bool pfadErlaubt(String pfad, AboStand stand, DateTime jetzt) =>
    stand.coachAn(jetzt) || freiePfade.contains(pfad);

/// The coach's line on day 6 of the free week.
const tag6Satz =
    'Morgen zeige ich dir, was ich in deinen ersten 7 Tagen über dich '
    'gelernt habe.';

/// The grey coach card from Monday to Saturday without Abo.
const stillSatz =
    'Dein Check-in ist gespeichert. Ich melde mich am Sonntag mit deiner '
    'Woche.';

/// The check-in reply with the Abo rules: day 6 announces the week, without
/// Abo the coach is silent except for the Sunday sentence.
class AboEvaluator implements CheckInEvaluator {
  AboEvaluator({
    required this.inner,
    required this.stand,
    required this.clock,
    this.woche,
  });

  final CheckInEvaluator inner;
  final AboStand Function() stand;
  final DateTime Function() clock;
  final WochenCoach? woche;

  @override
  Future<String?> reply(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  ) async {
    final s = stand();
    final jetzt = clock();
    if (s.coachAn(jetzt)) {
      final r = await inner.reply(profile, today, recent);
      if (s.zaehlerTag(jetzt) == 6 && r != null && r.isNotEmpty) {
        return '$r $tag6Satz';
      }
      return r;
    }
    if (s.wochenSatzTag(jetzt)) {
      final tage = [
        ...recent.where((c) => dayKey(c.datum) != dayKey(today.datum)),
        today,
      ];
      final w = await woche?.wochenRueckblick(
        profile,
        letzteSieben(tage, jetzt),
      );
      if (w != null && w.trim().isNotEmpty) return w.trim();
    }
    return stillSatz;
  }

  @override
  Future<Map<String, BereichsWert>?> rate(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  ) => inner.rate(profile, today, recent);
}

/// The check-ins of the 7 days up to [jetzt].
List<CheckIn> letzteSieben(List<CheckIn> alle, DateTime jetzt) {
  final keys = {for (final t in wochenTage(jetzt)) dayKey(t)};
  return [
    for (final c in alle)
      if (keys.contains(dayKey(c.datum))) c,
  ];
}

/// The 7 days up to and including [bis], oldest first.
List<DateTime> wochenTage(DateTime bis) {
  final d = DateTime(bis.year, bis.month, bis.day);
  return [for (var i = 6; i >= 0; i--) DateTime(d.year, d.month, d.day - i)];
}

const _kurz = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// One day on the Abo screen: its short name and what stood out.
typedef WochenPunkt = ({String tag, String text, bool da});

/// The numbers and days of the first week for the Abo screen.
class WochenBild {
  const WochenBild({
    required this.punkte,
    required this.checkIns,
    required this.fokusTage,
    required this.durchgezogen,
    this.muster,
  });

  final List<WochenPunkt> punkte;
  final int checkIns;
  final int fokusTage;
  final int durchgezogen;
  final String? muster;

  factory WochenBild.aus({
    required DateTime jetzt,
    required List<CheckIn> checkIns,
    Wochenfokus? fokus,
    List<Durchgezogen> durch = const [],
    List<Muster> muster = const [],
  }) {
    final tage = wochenTage(jetzt);
    final keys = {for (final t in tage) dayKey(t)};
    final proTag = {for (final c in checkIns) dayKey(c.datum): c};
    final punkte = [
      for (final t in tage)
        (
          tag: _kurz[t.weekday - 1],
          text: _merkmal(proTag[dayKey(t)]),
          da: proTag.containsKey(dayKey(t)),
        ),
    ];
    final m = [
      for (final x in muster)
        if (!x.abgelehnt) x,
    ]..sort((a, b) => b.datum.compareTo(a.datum));
    return WochenBild(
      punkte: punkte,
      checkIns: punkte.where((p) => p.da).length,
      fokusTage: fokus == null
          ? 0
          : fokus.geschafft.where(keys.contains).length,
      durchgezogen: durch.where((d) => keys.contains(dayKey(d.datum))).length,
      muster: m.isEmpty ? null : m.first.text,
    );
  }
}

/// A short word for a day: what was most telling in its check-in.
String _merkmal(CheckIn? c) {
  if (c == null) return 'kein Check-in';
  for (final a in [c.training, c.mindset, c.schlaf, c.ernaehrung]) {
    final t = a.trim();
    if (t.isNotEmpty) return t;
  }
  return 'Check-in';
}

/// When the coach cannot be reached: a plain sentence from the numbers.
String wochenTextLokal(String name, WochenBild b) {
  final mal = _mal(b.checkIns);
  final anfang = name.trim().isEmpty
      ? '${mal[0].toUpperCase()}${mal.substring(1)}'
      : '${name.trim()}, $mal';
  return '$anfang hast du in dieser Woche ehrlich hingeschaut. Ab jetzt '
      'sehe ich immer genauer, wo es bei dir hängt.';
}

String _mal(int n) => switch (n) {
  1 => 'einmal',
  2 => 'zweimal',
  3 => 'dreimal',
  4 => 'viermal',
  5 => 'fünfmal',
  6 => 'sechsmal',
  7 => 'siebenmal',
  _ => '${n}mal',
};
