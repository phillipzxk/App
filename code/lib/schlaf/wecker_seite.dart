import 'package:flutter/material.dart';

import '../sleep/schlafzeiten.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'aufwachen.dart';
import 'schlaf_data.dart';
import 'schlaf_widgets.dart';

/// "Dein Wecker": the time from the sleep times, the sunrise before it,
/// the sound, snooze at most once and the task that switches it off.
class WeckerSeite extends StatelessWidget {
  const WeckerSeite({super.key, required this.umfeld});
  final SchlafUmfeld umfeld;

  static const aufgaben = [
    (
      'foto',
      Icons.wb_sunny_outlined,
      'Foto vom Himmel',
      'Du musst aufstehen und ans Fenster. Bringt dich direkt ans Licht.',
    ),
    (
      'frage',
      Icons.help_outline,
      'Aufwach-Himmel',
      'Erst beantworten, dann ist er aus.',
    ),
    (
      'schritte',
      Icons.directions_walk,
      '30 Schritte gehen',
      'Die App zählt mit, bis du in Bewegung bist.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final u = umfeld;
    return SchlafSeite(
      umfeld: u,
      label: 'Schlaf & Energie',
      titel: 'Dein Wecker',
      bau: (context) {
        final w = u.d.wecker;
        Future<void> setze(Wecker n) => u.stand.setze(u.d.copyWith(wecker: n));
        final morgen = u.jetzt().add(const Duration(days: 1));
        return [
          TKarte(
            gold: true,
            child: Column(
              children: [
                TLabel('Morgen, ${germanWeekday(morgen).toLowerCase()}'),
                const SizedBox(height: 4),
                GoldText(
                  u.weckzeit == null ? '–' : formatUhrzeit(u.weckzeit!),
                  key: const ValueKey('wecker-morgen'),
                  style: tTitel.copyWith(fontSize: 52),
                ),
                const SizedBox(height: 4),
                Text(
                  u.weckzeit == null
                      ? 'Leg unten auf der Schlaf-Seite fest, wann du aufstehst.'
                      : 'Aus deinen Schlafzeiten. Ein früher Termin schiebt ihn '
                            'automatisch vor.',
                  textAlign: TextAlign.center,
                  style: tSoft,
                ),
              ],
            ),
          ),
          TKarte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Schalter(
                  key: const ValueKey('wecker-sonne'),
                  titel: 'Sonnenaufgang vorher',
                  text: 'Bildschirm wird 10 Minuten vorher langsam warm hell',
                  an: w.sonne,
                  onTap: () => setze(w.copyWith(sonne: !w.sonne)),
                ),
                const SizedBox(height: 8),
                Text('Klang', style: tTitel.copyWith(fontSize: 13.5)),
                const Text('wird langsam lauter', style: tSoft),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final k in Wecker.klaenge)
                      TChip(
                        k,
                        key: ValueKey('klang-$k'),
                        an: w.klang == k,
                        onTap: () => setze(w.copyWith(klang: k)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _Schalter(
                  key: const ValueKey('wecker-schlummern-an'),
                  titel: 'Schlummern',
                  text: 'höchstens einmal, 5 Minuten',
                  an: w.schlummern,
                  onTap: () => setze(w.copyWith(schlummern: !w.schlummern)),
                ),
              ],
            ),
          ),
          const TLabel('Ausschalten nur mit'),
          const SizedBox(height: 8),
          for (final a in aufgaben)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Aufgabe(
                key: ValueKey('aufgabe-${a.$1}'),
                icon: a.$2,
                titel: a.$3,
                text: a.$4,
                an: w.aufgabe == a.$1,
                onTap: () => setze(w.copyWith(aufgabe: a.$1)),
              ),
            ),
          const SizedBox(height: 6),
          TGhost(
            'Wecker testen',
            key: const ValueKey('wecker-testen'),
            onTap: () => zeigeSchlafSeite(context, WeckerKlingelt(umfeld: u)),
          ),
          const SizedBox(height: 14),
          const Text(
            'Der echte Wecker kommt mit der Handy-Version. Auf dem iPhone '
            'erlaubt Apple fremde Wecker nur mit Einschränkungen, das prüfen '
            'wir dann.',
            style: tSoft,
          ),
        ];
      },
    );
  }
}

class _Schalter extends StatelessWidget {
  const _Schalter({
    super.key,
    required this.titel,
    required this.text,
    required this.an,
    required this.onTap,
  });
  final String titel, text;
  final bool an;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titel, style: tTitel.copyWith(fontSize: 13.5)),
                Text(text, style: tSoft),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 26,
            padding: const EdgeInsets.all(3),
            alignment: an ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: an ? CoachStyle.goldGradient : null,
              color: an ? null : const Color(0xFF2A1F13),
              border: an ? null : Border.all(color: const Color(0xFF4A3B2A)),
            ),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: an ? CoachStyle.goldInk : CoachStyle.beigeLabel,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Aufgabe extends StatelessWidget {
  const _Aufgabe({
    super.key,
    required this.icon,
    required this.titel,
    required this.text,
    required this.an,
    required this.onTap,
  });
  final IconData icon;
  final String titel, text;
  final bool an;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xCC1A140E),
        border: Border.all(
          color: an ? CoachStyle.goldLight : const Color(0xFF3A2E21),
          width: an ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: an ? CoachStyle.goldGradient : null,
              color: an ? null : const Color(0xFF2A1F13),
            ),
            child: Icon(
              icon,
              size: 18,
              color: an ? CoachStyle.goldInk : CoachStyle.goldLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titel, style: tTitel.copyWith(fontSize: 13.5)),
                Text(text, style: tSoft),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// The alarm in one short line for the tile on the Schlaf page.
String weckerKurz(Wecker w) => w.sonne ? 'mit Sonnenaufgang' : w.klang;
