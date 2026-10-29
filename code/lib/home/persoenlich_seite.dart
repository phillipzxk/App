part of 'home_page.dart';

/// Persönlichkeit: Heute, Look, Pflege, Wissen (vault Umsetzung/
/// Persönlichkeit komplett, Phillip "passt" 2026-10-29).
extension _Persoenlich on _HomePageState {
  PersoenlichCoach get _persoenlichCoach => widget.coach is PersoenlichCoach
      ? widget.coach as PersoenlichCoach
      : const NoPersoenlichCoach();

  /// Puts the posture exercises onto every training day of the plan (after
  /// the day's own exercises, no doubles).
  Future<void> _haltungInsTraining(List<Tipp> uebungen) async {
    final p = _plan;
    final namen = [for (final t in p.tage) dayName(t)];
    final alle = [
      for (var k = 0; k < 7; k++)
        () {
          final l = p.uebungenAm(k);
          if (p.tage[k].trim().isEmpty) return l;
          final da = {for (final x in l) x.name.trim().toLowerCase()};
          return [
            ...l,
            for (final u in uebungen)
              if (!da.contains(u.titel.trim().toLowerCase()))
                () {
                  final z = [
                    for (final m in RegExp(r'\d+').allMatches(u.text))
                      int.parse(m.group(0)!),
                  ];
                  return PlanUebung(
                    name: u.titel,
                    art: UebungArt.koerpergewicht,
                    saetze: z.isNotEmpty ? z.first.clamp(1, 10) : 2,
                    wdhVon: z.length > 1 ? z[1].clamp(1, 50) : 12,
                    wdhBis: z.length > 1 ? z[1].clamp(1, 50) : 12,
                    pause: 45,
                    notiz: u.text,
                  );
                }(),
          ];
        }(),
    ];
    final neu = TrainingPlan.aus(namen, alle);
    await widget.feed.savePlan(neu);
    await _reload();
  }

  PersoenlichUmfeld get _persoenlichUmfeld => PersoenlichUmfeld(
    stand: _persoenlich,
    profile: widget.profile,
    coach: _persoenlichCoach,
    jetzt: widget.clock,
    fotos: _wochenFotos,
    onInsTraining: _plan.isEmpty ? null : _haltungInsTraining,
  );

  Feld _peFeld(
    String titel,
    IconData icon,
    String coach,
    Widget Function(PersoenlichUmfeld u) seite,
  ) => Feld(
    titel: titel,
    icon: icon,
    coach: coach,
    inhalt: (_) => [seite(_persoenlichUmfeld)],
  );

  Widget _persoenlichSeite() {
    final d = _persoenlich.d;
    final jetzt = widget.clock();
    final heute = dayKey(jetzt);
    final gestern = dayKey(jetzt.subtract(const Duration(days: 1)));
    final name = widget.profile.name.trim();
    final anrede = name.isEmpty ? '' : '$name, ';
    final wert = persoenlichWert(d, heute);
    final wertGestern = persoenlichWert(d, gestern);
    final morgens = morgensErledigt(d, heute);
    final offen = morgensOffen(d, heute);
    final stueck = pflegeAmStueck(d, jetzt);
    final lern = d.lernMinuten[heute] ?? 0;
    final k = d.kurs;
    final lek = k?.aktuelle;
    final look = d.look;
    final stil = d.stil;
    final haltung = d.haltung;
    final haut = d.haut;
    final frisur = d.frisur;
    final ft = frisur == null ? null : frisurTage(frisur, jetzt);
    final faellig = [
      for (final x in d.kleine)
        if (kleinesFaellig(x, jetzt) && !kleinesHeute(x, jetzt)) x,
    ];
    final umgesetzt = d.umsetzen.where((x) => x.erledigt != null).length;
    final fotos = _wochenFotos.where((w) => w.bilder.isNotEmpty).length;
    final verlauf = persoenlichVerlauf(d, jetzt);
    final da = [for (final v in verlauf) ?v];
    final schnitt = da.isEmpty
        ? null
        : (da.reduce((a, b) => a + b) / da.length).round();

    String sub() {
      if (wert == null) return 'Fang mit deiner Pflege-Routine an';
      if (wertGestern == null) return '$wert von 10';
      final diff = wert - wertGestern;
      return diff == 0
          ? 'gleich wie gestern'
          : '${diff > 0 ? '+' : '−'}${diff.abs()} zu gestern';
    }

    final verlaufF = Feld(
      titel: 'Persönlichkeit im Verlauf',
      icon: Icons.show_chart,
      coach:
          'Pflege und Lernen jeden Tag. Die gestrichelte Linie ist dein '
          'Schnitt.',
      inhalt: (_) => [
        _lebendig(
          () => Block(
            label: 'Persönlichkeit · 30 Tage',
            rechts: schnitt == null ? null : 'Ø $schnitt',
            children: [
              if (da.isEmpty)
                Text(
                  'Sobald du deine Pflege abhakst oder lernst, wächst hier '
                  'deine Linie.',
                  style: Glas.tSoft.copyWith(fontSize: 13.5),
                )
              else
                Linie30(
                  werte: persoenlichVerlauf(_persoenlich.d, widget.clock()),
                ),
            ],
          ),
        ),
        Block(
          children: [
            Text(
              'So rechne ich: Schritte deiner Pflege-Routine und die 10 '
              'Minuten Lernen.',
              style: Glas.tSoft.copyWith(fontSize: 13),
            ),
          ],
        ),
      ],
    );

    final seiten = [
      BSeite(
        name: 'Heute',
        coach: [
          if (offen != null) '$anrede$offen fehlt noch.',
          if (lern < 10)
            '${10 - lern} Minuten ${k?.skill ?? 'Lernen'}, dann hast du dein Lern-Ziel.'
          else
            'Lern-Ziel für heute geschafft.',
        ].join(' '),
        kacheln: [
          BKachel(
            id: 'pe-pflege',
            titel: 'Pflege-Routine',
            icon: Icons.spa_outlined,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: stueck == 0 ? null : '$stueck Tage',
            bild: pflegeRing(morgens, d.morgens.length),
            wert: 'Morgens',
            unter: [
              offen == null ? 'morgens alles erledigt' : '$offen fehlt noch',
              'abends ${d.abends.length} Schritte',
            ].join(' · '),
            feld: _peFeld(
              'Pflege-Routine',
              Icons.spa_outlined,
              'Morgens ${d.morgens.length} Schritte, abends ${d.abends.length}. '
                  'Mehr braucht es nicht.',
              (u) => PflegeSeite(u: u),
            ),
          ),
          BKachel(
            id: 'pe-lern',
            titel: 'Lern-Ziel',
            icon: Icons.school_outlined,
            wert: '$lern/10',
            text: null,
            bild: SizedBox(
              width: 80,
              child: GoldBalken(anteil: lern / 10, hoehe: 6),
            ),
            unter: lek == null
                ? 'Minuten heute'
                : 'Minuten heute · ${lek.titel}',
            feld: _peFeld(
              'Lern-Ziel',
              Icons.school_outlined,
              lek == null
                  ? '10 Minuten am Tag, Lektion für Lektion.'
                  : '10 Minuten am Tag. Heute: ${lek.titel}.',
              (u) => LernSeite(u: u),
            ),
          ),
          BKachel(
            id: 'pe-stimme',
            titel: 'Stimme',
            icon: Icons.mic_none,
            bild: const SizedBox(width: 90, child: Welle(n: 18, hoehe: 28)),
            text: 'Tempo, Füllwörter',
            unter: 'Aufnahme in der Handy-Version',
            feld: _peFeld(
              'Stimme aufnehmen',
              Icons.mic_none,
              'Ich höre auf Tempo, Füllwörter und wie sicher du klingst.',
              (_) => const StimmeSeite(),
            ),
          ),
        ],
      ),
      BSeite(
        name: 'Look',
        coach: look == null
            ? 'Ein Foto reicht. Ich zeige dir die drei kleinen Hebel, die bei dir '
                  'am meisten ausmachen.'
            : 'Drei kleine Hebel machen bei dir am meisten aus: '
                  '${look.punkte.map((p) => p.titel).join(', ')}.',
        kacheln: [
          BKachel(
            id: 'pe-look',
            titel: 'Look-Analyse',
            icon: Icons.face_retouching_natural,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: look == null ? null : '${look.punkte.length} Hebel',
            text: look?.titel ?? 'Foto machen',
            unter: 'ohne Punktzahl, nur was du ändern kannst',
            feld: _peFeld(
              'Look-Analyse',
              Icons.face_retouching_natural,
              'Keine Note fürs Gesicht. Nur die Dinge, die du selbst ändern '
                  'kannst.',
              (u) => LookSeite(u: u),
            ),
          ),
          BKachel(
            id: 'pe-stil',
            titel: 'Stil-Check',
            icon: Icons.checkroom_outlined,
            text: stil?.aendern ?? stil?.titel ?? 'Outfit zeigen',
            unter: stil == null
                ? 'ehrlich, was passt'
                : 'vom ${stil.tag.substring(8)}.${stil.tag.substring(5, 7)}.',
            feld: _peFeld(
              'Stil-Check',
              Icons.checkroom_outlined,
              'Foto vom Outfit, ich sage dir ehrlich, was passt.',
              (u) => StilSeite(u: u),
            ),
          ),
          BKachel(
            id: 'pe-haltung',
            titel: 'Haltung',
            icon: Icons.accessibility_new,
            text: haltung == null
                ? 'Foto von der Seite'
                : '${haltung.punkte.length} Übungen',
            unter: haltung == null
                ? 'Übungen landen im Training'
                : d.haltungImTraining
                ? 'stehen in deinem Training'
                : 'landen in deinem Training',
            feld: _peFeld(
              'Haltung',
              Icons.accessibility_new,
              'Aus deinem Foto. Die Übungen landen direkt in deinem Training.',
              (u) => HaltungSeite(u: u),
            ),
          ),
          BKachel(
            id: 'pe-verlauf',
            titel: 'Look-Verlauf',
            icon: Icons.compare,
            groesse: KachelGroesse.schmal,
            text: fotos < 2 ? 'ab 2 Fortschrittsfotos' : 'Woche 1 bis $fotos',
            feld: _peFeld(
              'Look-Verlauf',
              Icons.compare,
              'Jede Woche ein Foto, zusammen mit deinem Fortschrittsfoto.',
              (u) => LookVerlaufSeite(u: u),
            ),
          ),
        ],
      ),
      BSeite(
        name: 'Pflege',
        coach: [
          if (haut != null) 'Woche ${hautWoche(haut, jetzt)} vom Haut-Plan.',
          if (faellig.isNotEmpty)
            '${faellig.first.name} ${faellig.length == 1 ? 'ist' : 'und mehr sind'} heute dran.'
          else
            'Die kleinen Dinge sind heute erledigt.',
        ].join(' '),
        kacheln: [
          BKachel(
            id: 'pe-haut',
            titel: 'Haut-Plan',
            icon: Icons.water_drop_outlined,
            groesse: KachelGroesse.mittel,
            gold: true,
            hot: haut == null ? null : 'Woche ${hautWoche(haut, jetzt)} von 8',
            text: haut?.problem ?? 'Was stört dich an deiner Haut?',
            bild: haut == null
                ? null
                : SizedBox(
                    width: 110,
                    child: Striche(n: hautWoche(haut, jetzt), von: 8),
                  ),
            unter: haut == null
                ? 'ein Plan über 8 Wochen'
                : 'ein Schritt nach dem anderen',
            feld: _peFeld(
              'Haut-Plan',
              Icons.water_drop_outlined,
              'Ein Plan über 8 Wochen, ein Schritt nach dem anderen.',
              (u) => HautSeite(u: u),
            ),
          ),
          BKachel(
            id: 'pe-frisur',
            titel: 'Frisur',
            icon: Icons.content_cut,
            wert: ft == null
                ? null
                : ft <= 0
                ? 'Fällig'
                : '$ft Tage',
            text: frisur == null ? 'Was passt zu dir?' : null,
            unter: frisur == null
                ? 'und was du dem Friseur sagst'
                : 'bis zum nächsten Schnitt',
            feld: _peFeld(
              'Frisur-Berater',
              Icons.content_cut,
              'Was zu deiner Gesichtsform passt, und was du dem Friseur sagst.',
              (u) => FrisurSeite(u: u),
            ),
          ),
          BKachel(
            id: 'pe-kleine',
            titel: 'Kleine Dinge',
            icon: Icons.auto_awesome_outlined,
            text: faellig.isEmpty
                ? 'Alles erledigt'
                : '${faellig.first.name} heute',
            bild: SizedBox(
              width: 70,
              child: Striche(
                n: d.kleine
                    .where(
                      (x) =>
                          !kleinesFaellig(x, jetzt) || kleinesHeute(x, jetzt),
                    )
                    .length,
                von: d.kleine.length,
              ),
            ),
            unter: faellig.length > 1
                ? '${faellig.length - 1} weitere dran'
                : 'Zähne, Duft, Nägel, Brauen',
            feld: _peFeld(
              'Die kleinen Dinge',
              Icons.auto_awesome_outlined,
              'Zähne, Duft, Hände, Augenbrauen. Das sieht jeder, keiner sagt es.',
              (u) => KleineSeite(u: u),
            ),
          ),
        ],
      ),
      BSeite(
        name: 'Wissen',
        coach: d.umsetzen.isEmpty
            ? 'Viel wissen bringt nichts, wenn nichts passiert. Aus jedem Buch '
                  'machen wir einen kleinen Schritt.'
            : '$umgesetzt von ${d.umsetzen.length} Sachen aus Büchern und '
                  'Podcasts machst du schon.',
        kacheln: [
          BKachel(
            id: 'pe-kurs',
            titel: k == null ? 'Dein Skill' : 'Dein Skill · ${k.skill}',
            icon: Icons.route_outlined,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: lek == null ? null : 'Lektion ${k!.erreicht + 1}',
            bild: k == null
                ? null
                : SizedBox(
                    width: 120,
                    child: Striche(n: k.erreicht, von: k.lektionen.length),
                  ),
            text:
                lek?.titel ??
                (k == null
                    ? 'Welchen Skill willst du lernen?'
                    : 'Kurs geschafft'),
            unter: k == null
                ? '12 Lektionen, eine baut auf der anderen auf'
                : '${k.erreicht} von ${k.lektionen.length} · die nächste öffnet sich nach der Frage',
            feld: _peFeld(
              'Dein Skill',
              Icons.route_outlined,
              'Schritt für Schritt, wie ein Kurs, der aufeinander aufbaut.',
              (u) => KursSeite(u: u),
            ),
          ),
          BKachel(
            id: 'pe-buecher',
            titel: 'Bibliothek',
            icon: Icons.menu_book_outlined,
            wert: '${d.buecher.length}',
            unter: d.buecher.isEmpty
                ? 'Bücher und Podcasts'
                : 'Bücher · ich frage ab',
            feld: _peFeld(
              'Deine Bibliothek',
              Icons.menu_book_outlined,
              'Was du liest und hörst. Ich frage später ab, damit es bleibt.',
              (u) => BibliothekSeite(u: u),
            ),
          ),
          BKachel(
            id: 'pe-umsetzen',
            titel: 'Umsetzen',
            icon: Icons.bolt_outlined,
            wert: '$umgesetzt/${d.umsetzen.length}',
            unter: 'aus Büchern und Podcasts gemacht',
            feld: _peFeld(
              'Wissen umsetzen',
              Icons.bolt_outlined,
              'Viel wissen bringt nichts, wenn nichts passiert.',
              (u) => UmsetzenSeite(u: u),
            ),
          ),
        ],
      ),
    ];

    return BereichSeite(
      key: const ValueKey('persoenlich-seite'),
      name: 'Persönlichkeit',
      wert: wert,
      teile: [
        Unterbereich(
          id: 'persoenlich',
          name: 'Persönlichkeit',
          icon: Icons.person_outline,
          wert: wert,
          woche: [
            for (var i = 6; i >= 0; i--)
              persoenlichWert(d, dayKey(jetzt.subtract(Duration(days: i)))),
          ],
          sub: sub(),
          seiten: seiten,
        ),
      ],
      verlauf: verlaufF,
      frag: (_) => Feld(
        titel: 'Frag den Coach',
        icon: Icons.chat_bubble_outline,
        coach: 'Alles zu Auftreten, Look, Pflege und Lernen.',
        inhalt: (_) => [
          _lebendig(
            () => AskCoachCard(
              title: 'Woran willst du an dir arbeiten?',
              hint: 'Schreib, was dir an deinem Auftreten wichtig ist.',
              today: _todayFragen(Bereich.mindset),
              onSend: _ask(Bereich.mindset),
            ),
          ),
        ],
      ),
    );
  }
}
