import 'package:flutter/material.dart';

import '../sleep/schlafzeiten.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'aufwachen.dart';
import 'schlaf_data.dart';
import 'schlaf_logik.dart';
import 'schlaf_widgets.dart';

/// "Was nur bei dir gilt": the best time of day and what gives and takes
/// energy, each with "Stimmt nicht".
class SchlafMusterSeite extends StatelessWidget {
  const SchlafMusterSeite({super.key, required this.umfeld});
  final SchlafUmfeld umfeld;

  @override
  Widget build(BuildContext context) {
    final u = umfeld;
    return SchlafSeite(
      umfeld: u,
      label: 'Schlaf & Energie',
      titel: 'Was nur bei dir gilt',
      bau: (context) {
        final muster = sichtbareSchlafMuster(u.d);
        final b = u.d.besteZeit;
        final fehlen = 14 - u.d.morgen.length;
        return [
          if (b != null)
            TKarte(
              key: const ValueKey('beste-zeit'),
              gold: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TLabel('Deine beste Zeit'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        b.typ.toLowerCase().contains('abend')
                            ? Icons.nightlight_round
                            : Icons.wb_sunny_outlined,
                        size: 32,
                        color: CoachStyle.goldLight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.typ, style: tTitel.copyWith(fontSize: 16)),
                            Text(b.text, style: tSoft),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          TKarte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TLabel('Gibt dir Energie · Nimmt dir Energie'),
                const SizedBox(height: 4),
                if (muster.isEmpty)
                  Text(
                    fehlen > 0
                        ? 'Noch zu früh. Nach $fehlen weiteren Morgen schaut der '
                              'Coach, was bei dir klar zu sehen ist.'
                        : 'Gerade ist nichts klar zu sehen. Der Coach schaut '
                              'jede Woche wieder.',
                    key: const ValueKey('muster-leer'),
                    style: tSoft,
                  )
                else
                  for (final m in muster)
                    MusterZeile(
                      key: ValueKey('schlaf-muster-${m.text}'),
                      m: m,
                      onWeg: () => u.stand.setze(
                        u.d.copyWith(
                          muster: [
                            for (final x in u.d.muster)
                              identical(x, m) ? x.ablehnen() : x,
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const Text(
            'Der Coach nutzt diese Muster für deinen Tag, den Wecker und seine '
            'Antworten. Neue kommen nur, wenn sie klar zu sehen sind.',
            style: tSoft,
          ),
        ];
      },
    );
  }
}

/// "Dein Tag vom Coach": the best day with a reason per point. Übernehmen
/// puts it into "Dein Tag", Rückgängig takes it out again.
class TagesablaufSeite extends StatefulWidget {
  const TagesablaufSeite({super.key, required this.umfeld});
  final SchlafUmfeld umfeld;

  @override
  State<TagesablaufSeite> createState() => _TagesablaufSeiteState();
}

class _TagesablaufSeiteState extends State<TagesablaufSeite> {
  SchlafUmfeld get u => widget.umfeld;

  @override
  void initState() {
    super.initState();
    u.holeAblauf();
  }

  @override
  Widget build(BuildContext context) => SchlafSeite(
    umfeld: u,
    label: germanWeekday(u.jetzt()),
    titel: 'Dein Tag vom Coach',
    bau: (context) {
      final a = u.d.ablauf;
      if (a == null || a.tag != u.heute) {
        return const [
          Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(color: CoachStyle.gold),
            ),
          ),
        ];
      }
      return [
        if (a.satz != null)
          TKarte(gold: true, child: CoachZeile(text: a.satz!)),
        TKarte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final p in a.punkte) _PlanZeile(p: p)],
          ),
        ),
        if (a.uebernommen)
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Übernommen in „Dein Tag“.',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 12.5,
                    color: CoachStyle.goldLight,
                  ),
                ),
              ),
              TLink(
                'Rückgängig',
                key: const ValueKey('ablauf-rueckgaengig'),
                onTap: () => u.stand.setze(
                  u.d.copyWith(ablauf: a.mit(uebernommen: false)),
                ),
              ),
            ],
          )
        else
          MainButton(
            key: const ValueKey('ablauf-uebernehmen'),
            label: 'Übernehmen',
            onPressed: () =>
                u.stand.setze(u.d.copyWith(ablauf: a.mit(uebernommen: true))),
          ),
        const SizedBox(height: 8),
        const Text(
          'Gold markiert = neu vom Coach. Deine eigenen Termine bleiben immer.',
          style: tSoft,
        ),
      ];
    },
  );
}

class _PlanZeile extends StatelessWidget {
  const _PlanZeile({required this.p});
  final AblaufPunkt p;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFF2E261C))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 34,
          margin: const EdgeInsets.only(right: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: p.neu ? CoachStyle.goldGradient : null,
            color: p.neu ? null : const Color(0xFF2E261C),
          ),
        ),
        SizedBox(
          width: 46,
          child: Text(
            formatUhrzeit(p.minute % 1440),
            style: tTitel.copyWith(fontSize: 13, color: CoachStyle.goldLight),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.was, style: tTitel.copyWith(fontSize: 13.5)),
              if (p.warum != null) Text(p.warum!, style: tSoft),
            ],
          ),
        ),
      ],
    ),
  );
}
