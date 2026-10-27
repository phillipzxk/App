import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../data/user_profile.dart';
import '../sleep/schlafzeiten.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'schlaf_coach.dart';
import 'schlaf_data.dart';
import 'schlaf_logik.dart';

/// Holds the Schlaf & Energie data, saves every change and tells the pages.
class SchlafStand extends ChangeNotifier {
  SchlafStand(this._speichern);

  final Future<void> Function(SchlafDaten d) _speichern;
  SchlafDaten _d = const SchlafDaten();
  SchlafDaten get d => _d;

  void laden(SchlafDaten d) {
    _d = d;
    notifyListeners();
  }

  Future<void> setze(SchlafDaten d) async {
    _d = d;
    notifyListeners();
    await _speichern(d);
  }
}

/// What every Schlaf & Energie page needs.
class SchlafUmfeld {
  const SchlafUmfeld({
    required this.stand,
    required this.profile,
    required this.coach,
    required this.jetzt,
    required this.zeiten,
    required this.bett,
    required this.tagText,
    required this.onMorgen,
    this.routine = const [],
    this.training,
    this.trainingName,
    this.weckzeit,
    this.mahlzeiten = const [],
    this.termine = const [],
  });

  final SchlafStand stand;
  final UserProfile profile;
  final SchlafCoach coach;
  final DateTime Function() jetzt;
  final Schlafzeiten zeiten;

  /// Tonight's bedtime (minutes), null while no wake-up time is set.
  final int? bett;

  /// Today in lines for the coach: plan, appointments, meals.
  final String Function() tagText;

  /// Saves the morning hours as a sleep entry too.
  final Future<void> Function(double stunden) onMorgen;

  /// The evening routine: time and step.
  final List<(String, String)> routine;
  final int? training;
  final String? trainingName;

  /// Tomorrow's alarm (minutes): the wake-up time, earlier with an early
  /// appointment. Null while no wake-up time is set.
  final int? weckzeit;

  /// Today's meals and appointments: minute and name, for the coach's day.
  final List<(int, String)> mahlzeiten;
  final List<(int, String)> termine;

  SchlafDaten get d => stand.d;
  String get heute => dayKey(jetzt());
  int get aufstehen => zeiten.aufstehenAm(jetzt()) ?? 7 * 60;
  int get bettHeute => bett ?? 23 * 60;

  /// Everything for the coach in one text.
  String kontext() => [
    'Aufstehen heute ${formatUhrzeit(aufstehen)}, Bettzeit heute ${formatUhrzeit(bettHeute)}, '
        'braucht ${formatStunden(zeiten.stunden)} Stunden Schlaf.',
    if (training != null)
      'Training heute ${formatUhrzeit(training! % 1440)}${trainingName == null ? '' : ' ($trainingName)'}.',
    tagText(),
    schlafKontext(d, jetzt()),
    for (final m in sichtbareSchlafMuster(d)) 'Erkanntes Muster: ${m.text}',
  ].where((x) => x.trim().isNotEmpty).join('\n');
}

/// Fetching from the coach, each at most once a day (or week).
extension SchlafHolen on SchlafUmfeld {
  /// Today's energy forecast from last night and training.
  ({List<(int, double)> werte, (int, int) hoch, int tief}) energieHeute() =>
      energieTag(
        aufstehen: aufstehen,
        bett: bettHeute,
        wert: d.morgenAm(heute)?.wert,
        training: training,
        lernen: energieLernen(d.energie),
      );

  /// The forecast sentence for today, from the coach once a day.
  Future<void> holeEnergieSatz() async {
    if (d.energieSatz?.tag == heute) return;
    final e = energieHeute();
    final satz =
        await coach.energie(
          profile,
          '${kontext()}\nVorhersage heute: Hoch ${formatUhrzeit(e.hoch.$1 % 1440)} bis '
          '${formatUhrzeit(e.hoch.$2 % 1440)}, Tief um ${formatUhrzeit(e.tief % 1440)}.',
        ) ??
        energieSatzOhneCoach(
          hoch: e.hoch,
          tief: e.tief,
          training: training,
          wert: d.morgenAm(heute)?.wert,
        );
    await stand.setze(d.copyWith(energieSatz: (tag: heute, satz: satz)));
  }

  /// New patterns at most once a week, from 14 mornings on.
  Future<void> holeMuster() async {
    if (!musterFaellig(d, jetzt())) return;
    final tag = heute;
    final r = await coach.muster(profile, kontext());
    if (r == null) {
      await stand.setze(d.copyWith(musterTag: tag));
      return;
    }
    final weg = {
      for (final m in d.muster)
        if (m.abgelehnt) m.text,
    };
    await stand.setze(
      d.copyWith(
        musterTag: tag,
        muster: [
          for (final m in d.muster)
            if (m.abgelehnt) m,
          for (final m in r.muster)
            if (!weg.contains(m.text)) m,
        ],
        besteZeit: r.besteZeit,
      ),
    );
  }

  /// The best day from the coach, without him from the forecast.
  Future<Tagesablauf> holeAblauf() async {
    final alt = d.ablauf;
    if (alt != null && alt.tag == heute) return alt;
    final e = energieHeute();
    final r = await coach.tagesablauf(
      profile,
      '${kontext()}\nVorhersage heute: Hoch ${formatUhrzeit(e.hoch.$1 % 1440)} bis '
      '${formatUhrzeit(e.hoch.$2 % 1440)}, Tief um ${formatUhrzeit(e.tief % 1440)}.',
    );
    final a = Tagesablauf(
      tag: heute,
      punkte:
          r?.punkte ??
          ablaufOhneCoach(
            aufstehen: aufstehen,
            bett: bettHeute,
            hoch: e.hoch,
            tief: e.tief,
            training: training,
            trainingName: trainingName,
            mahlzeiten: mahlzeiten,
            termine: termine,
            routineAb: routine.isEmpty ? null : routine.first.$1,
            dunkel: nochDunkel(jetzt(), aufstehen),
          ),
      satz:
          r?.satz ??
          'Nach deiner Nacht und dem, was ich bei dir kenne, ist das heute '
              'dein bester Ablauf. Deine Termine bleiben, ich plane drumherum.',
    );
    await stand.setze(d.copyWith(ablauf: a));
    return a;
  }
}

/// The area's own sky: morning red, warm gold by day, night blue with
/// stars and a moon in the evening (Phillip 2026-10-27).
class SchlafHimmel extends StatelessWidget {
  const SchlafHimmel({super.key, required this.phase, required this.child});

  final HimmelPhase phase;
  final Widget child;

  static const _farben = {
    HimmelPhase.morgen: [
      Color(0xFF2A1838),
      Color(0xFF6B2F3C),
      Color(0xFF9C4A38),
      Color(0xFF2A1A12),
      Color(0xFF120C08),
    ],
    HimmelPhase.tag: [
      Color(0xFF4A3418),
      Color(0xFF3A2A17),
      Color(0xFF241A10),
      Color(0xFF1A120B),
      Color(0xFF100B07),
    ],
    HimmelPhase.abend: [
      Color(0xFF070B1C),
      Color(0xFF0E1630),
      Color(0xFF111426),
      Color(0xFF120F18),
      Color(0xFF0B0806),
    ],
  };

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: ValueKey('himmel-${phase.name}'),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _farben[phase]!,
        stops: const [0, .2, .38, .6, 1],
      ),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _HimmelMaler(phase)),
          ),
        ),
        child,
      ],
    ),
  );
}

class _HimmelMaler extends CustomPainter {
  _HimmelMaler(this.phase);
  final HimmelPhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (phase == HimmelPhase.abend) {
      final r = math.Random(7);
      final p = Paint()..color = const Color(0xCCFFFFFF);
      for (var i = 0; i < 40; i++) {
        canvas.drawCircle(
          Offset(r.nextDouble() * size.width, r.nextDouble() * 260),
          r.nextDouble() * 1.1 + .3,
          p,
        );
      }
      // A small crescent moon top right.
      final c = Offset(size.width - 44, 46);
      canvas.saveLayer(Rect.fromCircle(center: c, radius: 20), Paint());
      canvas.drawCircle(c, 15, Paint()..color = const Color(0xFFF2E4C2));
      canvas.drawCircle(
        c + const Offset(-7, -4),
        14,
        Paint()..blendMode = BlendMode.clear,
      );
      canvas.restore();
    } else {
      final glut = phase == HimmelPhase.morgen
          ? const Color(0x55F2B860)
          : const Color(0x336B4A22);
      canvas.drawCircle(
        Offset(
          phase == HimmelPhase.morgen ? size.width / 2 : size.width * .8,
          phase == HimmelPhase.morgen ? 200 : 0,
        ),
        200,
        Paint()
          ..shader = RadialGradient(colors: [glut, const Color(0x00000000)])
              .createShader(
                Rect.fromCircle(
                  center: Offset(
                    phase == HimmelPhase.morgen
                        ? size.width / 2
                        : size.width * .8,
                    phase == HimmelPhase.morgen ? 200 : 0,
                  ),
                  radius: 200,
                ),
              ),
      );
    }
  }

  @override
  bool shouldRepaint(_HimmelMaler old) => old.phase != phase;
}

/// The Schlaf-Mond: full when the last 7 nights were good.
class SchlafMond extends StatelessWidget {
  const SchlafMond({
    super.key,
    required this.fuell,
    this.size = 96,
    this.child,
  });

  final double fuell;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _MondMaler(fuell.clamp(0, 1).toDouble()),
      child: child == null ? null : Center(child: child),
    ),
  );
}

class _MondMaler extends CustomPainter {
  _MondMaler(this.f);
  final double f;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 3;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF3A2E21));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFF6B5535)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final licht = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.2, -.3),
        colors: [Color(0xFFFFF4D6), Color(0xFFE9C987), Color(0xFFB8894A)],
        stops: [0, .7, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    if (f >= .99) {
      canvas.drawCircle(c, r, licht);
    } else if (f > .01) {
      // Right half lit, closed by an ellipse: crescent below half, gibbous
      // above.
      final rx = (1 - 2 * f).abs() * r;
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..arcToPoint(
          Offset(c.dx, c.dy + r),
          radius: Radius.circular(r),
          clockwise: true,
        )
        ..arcToPoint(
          Offset(c.dx, c.dy - r),
          radius: Radius.elliptical(math.max(rx, .1), r),
          clockwise: f > .5,
        )
        ..close();
      canvas.drawPath(path, licht);
    }
    final krater = Paint()..color = const Color(0x14000000);
    canvas.drawCircle(c + Offset(-r * .25, -r * .2), r * .09, krater);
    canvas.drawCircle(c + Offset(r * .3, r * .25), r * .13, krater);
  }

  @override
  bool shouldRepaint(_MondMaler old) => old.f != f;
}

/// Today's predicted energy with the high window and the training time.
class EnergieVorhersage extends StatelessWidget {
  const EnergieVorhersage({
    super.key,
    required this.werte,
    required this.hoch,
    required this.jetzt,
    this.training,
  });

  final List<(int, double)> werte;
  final (int, int) hoch;
  final int jetzt;
  final int? training;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('energie-vorhersage'),
    height: 140,
    width: double.infinity,
    child: CustomPaint(painter: _EnergieMaler(this)),
  );
}

class _EnergieMaler extends CustomPainter {
  _EnergieMaler(this.w);
  final EnergieVorhersage w;

  @override
  void paint(Canvas canvas, Size size) {
    final v = w.werte;
    if (v.length < 2) return;
    final von = v.first.$1.toDouble(), bis = v.last.$1.toDouble();
    const unten = 18.0, oben = 22.0;
    double x(num m) => 6 + (m - von) / (bis - von) * (size.width - 12);
    double y(double e) =>
        size.height - unten - e * (size.height - unten - oben);

    // The high window and training.
    final hoch = RRect.fromLTRBR(
      x(w.hoch.$1),
      oben - 8,
      x(w.hoch.$2),
      size.height - unten,
      const Radius.circular(8),
    );
    canvas.drawRRect(hoch, Paint()..color = const Color(0x22E0BF7E));
    _text(
      canvas,
      'Dein Hoch',
      Offset((x(w.hoch.$1) + x(w.hoch.$2)) / 2, 2),
      const Color(0xFFE0BF7E),
      10,
      true,
    );
    final t = w.training;
    if (t != null && t >= von && t <= bis) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          x(t) - 12,
          oben - 8,
          x(t) + 12,
          size.height - unten,
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0x14CDBB98),
      );
      _text(
        canvas,
        'Training',
        Offset(x(t), 2),
        CoachStyle.beigeLabel,
        9.5,
        false,
      );
    }

    final path = Path()..moveTo(x(v.first.$1), y(v.first.$2));
    for (var i = 1; i < v.length; i++) {
      final xm = (x(v[i - 1].$1) + x(v[i].$1)) / 2;
      path.cubicTo(xm, y(v[i - 1].$2), xm, y(v[i].$2), x(v[i].$1), y(v[i].$2));
    }
    final flaeche = Path.from(path)
      ..lineTo(x(v.last.$1), size.height - unten)
      ..lineTo(x(v.first.$1), size.height - unten)
      ..close();
    canvas.drawPath(
      flaeche,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x59E0BF7E), Color(0x00E0BF7E)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF5DFAE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    // Now.
    if (w.jetzt >= von && w.jetzt <= bis) {
      final xj = x(w.jetzt);
      final p = Paint()
        ..color = const Color(0x99E0BF7E)
        ..strokeWidth = 1;
      for (var yy = oben; yy < size.height - unten; yy += 6) {
        canvas.drawLine(Offset(xj, yy), Offset(xj, yy + 3), p);
      }
    }
    // Hours.
    for (var h = (von / 60).ceil(); h * 60 <= bis; h += 3) {
      _text(
        canvas,
        '${h % 24}',
        Offset(x(h * 60), size.height - 13),
        CoachStyle.inkSoft,
        10,
        false,
      );
    }
  }

  void _text(
    Canvas c,
    String s,
    Offset mitte,
    Color farbe,
    double gr,
    bool fett,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'Figtree',
          fontSize: gr,
          color: farbe,
          fontWeight: fett ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(mitte.dx - tp.width / 2, mitte.dy));
  }

  @override
  bool shouldRepaint(_EnergieMaler old) => true;
}

/// A sub page of Schlaf & Energie: under the area's sky, rebuilt with
/// every change.
class SchlafSeite extends StatelessWidget {
  const SchlafSeite({
    super.key,
    required this.umfeld,
    required this.label,
    required this.titel,
    required this.bau,
    this.phase,
  });

  final SchlafUmfeld umfeld;
  final String label, titel;
  final HimmelPhase? phase;
  final List<Widget> Function(BuildContext context) bau;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CoachStyle.night,
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: CoachStyle.goldLight,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    body: SchlafHimmel(
      phase:
          phase ??
          himmelPhase(
            umfeld.jetzt(),
            umfeld.zeiten.aufstehenAm(umfeld.jetzt()),
          ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListenableBuilder(
              listenable: umfeld.stand,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 40),
                children: [
                  TLabel(label),
                  const SizedBox(height: 4),
                  GoldText(titel, style: tTitel.copyWith(fontSize: 22)),
                  const SizedBox(height: 14),
                  ...bau(context),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A part of the sleep score: name, bar, short word.
class TeilZeile extends StatelessWidget {
  const TeilZeile({
    super.key,
    required this.name,
    required this.wert,
    required this.text,
  });
  final String name, text;
  final int wert;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(width: 100, child: Text(name, style: tSoft)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: const Color(0xFF2A2118)),
                FractionallySizedBox(
                  widthFactor: (wert / 100).clamp(0, 1).toDouble(),
                  child: Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: CoachStyle.goldGradient,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 82,
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: tSoft.copyWith(color: CoachStyle.beigeLabel),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

/// A pattern row: + or − and the text, with "Stimmt nicht".
class MusterZeile extends StatelessWidget {
  const MusterZeile({super.key, required this.m, this.onWeg});
  final SchlafMuster m;
  final VoidCallback? onWeg;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: m.gut ? CoachStyle.goldGradient : null,
            color: m.gut ? null : const Color(0xFF2A1F13),
            border: m.gut ? null : Border.all(color: const Color(0xFF6B5535)),
          ),
          child: Icon(
            m.gut ? Icons.add : Icons.remove,
            size: 16,
            color: m.gut ? CoachStyle.goldInk : CoachStyle.beigeLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.text, style: tText),
              if (m.beleg != null || onWeg != null)
                Row(
                  children: [
                    if (m.beleg != null)
                      Expanded(child: Text(m.beleg!, style: tSoft))
                    else
                      const Spacer(),
                    if (onWeg != null)
                      TLink('Stimmt nicht', soft: true, onTap: onWeg),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<T?> zeigeSchlafSeite<T>(BuildContext context, Widget seite) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => seite));
