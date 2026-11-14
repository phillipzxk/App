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
    final name = widget.profile.name.trim();
    final anrede = name.isEmpty ? '' : '$name, ';
    final wert = _pew(jetzt);
    final wertGestern = _pew(jetzt.subtract(const Duration(days: 1)));
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
    final verlauf = _verlauf(_pew, jetzt);
    final da = [for (final v in verlauf) ?v];
    final schnitt = da.isEmpty
        ? null
        : (da.reduce((a, b) => a + b) / da.length).round();

    // For the pictures (draft "Bereiche als Bilder" 3).
    final an = d.pflegeAm(heute);
    final schritte = [
      for (final (i, n) in d.morgens.indexed)
        (name: n, fertig: an.contains('m$i')),
    ];
    final List<LookPunkt?> lookPunkte = [
      if (look == null || look.punkte.isEmpty)
        (name: 'Look', ziel: 'pe-look')
      else
        (name: look.punkte.first.titel, ziel: 'pe-look'),
      if (look != null && look.punkte.length > 1)
        (name: look.punkte[1].titel, ziel: 'pe-look')
      else
        null,
      (name: 'Stil', ziel: 'pe-stil'),
      (name: 'Haltung', ziel: 'pe-haltung'),
    ];
    final hw = haut == null ? null : hautWoche(haut, jetzt);
    (int, int)? wochen(String titel) {
      final z = [
        for (final m in RegExp(r'\d+').allMatches(titel))
          int.parse(m.group(0)!),
      ];
      return z.isEmpty ? null : (z.first, z.last);
    }

    final phase = haut == null || hw == null
        ? null
        : haut.phasen.where((p) {
            final w = wochen(p.titel);
            return w != null && w.$1 <= hw && hw <= w.$2;
          }).firstOrNull;
    final teiler = [
      for (final p in haut?.phasen ?? const <Tipp>[])
        if (wochen(p.titel) case final w? when w.$2 < 8) w.$2,
    ];
    final kleineSortiert = [...d.kleine]
      ..sort((a, b) {
        int r(KleinesDing x) => kleinesHeute(x, jetzt)
            ? 1
            : kleinesFaellig(x, jetzt)
            ? 0
            : 2;
        return r(a).compareTo(r(b));
      });
    final List<KleinesPunkt> kleinePunkte = [
      for (final x in kleineSortiert.take(3))
        (
          name: x.name,
          unter: kleinesHeute(x, jetzt)
              ? 'erledigt'
              : kleinesFaellig(x, jetzt)
              ? 'fällig'
              : 'in ${x.alle - tageSeit(x.zuletzt!, jetzt)} Tagen',
          an: kleinesFaellig(x, jetzt) && !kleinesHeute(x, jetzt),
          fertig: kleinesHeute(x, jetzt),
          ziel: 'pe-kleine',
        ),
      (
        name: 'Frisur',
        unter: frisur == null
            ? 'was passt?'
            : ft == null
            ? 'Schnitt eintragen'
            : ft <= 0
            ? 'fällig'
            : ft < 14
            ? 'in $ft Tagen'
            : 'in ${ft ~/ 7} Wochen',
        an: ft != null && ft <= 0,
        fertig: false,
        ziel: 'pe-frisur',
      ),
    ];
    final kleineHeute = d.kleine.where((x) => kleinesHeute(x, jetzt)).length;
    final bald = [
      for (final x in d.kleine)
        if (!kleinesFaellig(x, jetzt) &&
            x.alle - tageSeit(x.zuletzt!, jetzt) <= 7)
          x,
    ].length;
    final lese = d.buecher.indexWhere((b) => !b.fertig);
    final regal = [
      for (final (i, b) in d.buecher.take(5).indexed)
        (
          titel: b.titel,
          art: d.umsetzen.any((u) => u.quelle == b.titel && u.erledigt != null)
              ? 3
              : i == lese
              ? 2
              : b.fertig
              ? 1
              : 0,
        ),
    ];

    String sub() {
      if (wert == null) return 'Fang mit deiner Pflege-Routine an';
      if (wertGestern == null) return '$wert von 10';
      final diff = wert - wertGestern;
      return diff == 0
          ? 'gleich wie gestern'
          : '${diff > 0 ? '+' : '−'}${diff.abs()} zu gestern';
    }

    final verlaufF = Feld(
      titel: 'Ausstrahlung im Verlauf',
      icon: Icons.show_chart,
      coach:
          'Pflege und Lernen jeden Tag. Die gestrichelte Linie ist dein '
          'Schnitt.',
      inhalt: (_) => [
        _lebendig(
          () => Block(
            label: 'Ausstrahlung · 30 Tage',
            rechts: schnitt == null ? null : 'Ø $schnitt',
            children: [
              if (da.isEmpty)
                Text(
                  'Sobald du deine Pflege abhakst oder lernst, wächst hier '
                  'deine Linie.',
                  style: Glas.tSoft.copyWith(fontSize: 13.5),
                )
              else
                Linie30(werte: _verlauf(_pew, widget.clock())),
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

    // New structure with more motivation, like the other areas (vault
    // Umsetzung/Schlaf und Mindset Aufbau; Phillip "ja erstell alle im
    // gleichen stil" 2026-11-14). All numbers come from real entries.
    final stark = name.isEmpty
        ? 'Geschafft. Stark.'
        : 'Geschafft. Stark, $name.';
    final zielSatz = widget.profile.zielSatz;
    final dafuer = zielSatz.isEmpty ? null : '„$zielSatz“';
    final montag = dayKey(montagVon(jetzt));
    final pflegeTage = [
      for (final t in d.pflege.keys)
        if (pflegeVoll(d, t)) t,
    ];
    final lernTage = [
      for (final e in d.lernMinuten.entries)
        if (e.value >= 10) e.key,
    ];
    BSerie serieAus(({int jetzt, int rekord}) x, String text) => BSerie(
      zahl: x.jetzt,
      einheit: x.jetzt == 1 ? 'Tag' : 'Tage',
      text: x.jetzt == 0 ? 'Startet mit deinem nächsten Eintrag' : text,
      rekord: x.rekord,
    );
    final seriePflege = serieAus(
      serieTage(pflegeTage, jetzt),
      'in Folge Pflege komplett',
    );
    final serieLernen = serieAus(
      serieTage(lernTage, jetzt),
      'in Folge 10 Minuten gelernt',
    );
    final geschafftPe = <(String, String, String)>[
      for (final t in pflegeTage)
        if (t.compareTo(montag) >= 0) ('Pflege komplett', t, 'b'),
      for (final t in lernTage)
        if (t.compareTo(montag) >= 0) ('10 Minuten gelernt', t, 'a'),
      for (final x in d.umsetzen)
        if (x.erledigt case final t? when t.compareTo(montag) >= 0)
          ('Umgesetzt: ${x.schritt}', t.substring(0, 10), 'c'),
    ]..sort((a, b) => '${b.$2}${b.$3}'.compareTo('${a.$2}${a.$3}'));
    final geschafftListe = [
      for (final g in geschafftPe.take(4))
        (g.$1, tagKurz(DateTime.parse(g.$2))),
    ];
    final lernZiel = BNaechstes(
      titel: 'Lern-Ziel heute',
      anteil: lern / 10,
      text: lern >= 10
          ? '$lern Minuten, geschafft.'
          : 'Noch ${10 - lern} Minuten.',
    );
    final kleineGesamt = kleineHeute + faellig.length;

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
        bild: BBild(
          bau: (tipp, v, t) => PflegeHeuteBild(
            schritte: schritte,
            lern: lern,
            onSchritt: (i) => _persoenlich.setze(
              _persoenlich.d.pflegeUmschalten(heute, 'm$i'),
            ),
            tipp: tipp,
            v: v,
            t: t,
          ),
          zahlen: [
            BZahl(
              d.morgens.isEmpty ? '–' : '$morgens/${d.morgens.length}',
              'Pflege',
              ziel: 'pe-pflege',
            ),
            BZahl('$lern/10', 'Minuten', ziel: 'pe-lern'),
            const BZahl('–', 'Füllwörter', ziel: 'pe-stimme'),
          ],
          knopf: ('Lernen starten', 'pe-lern'),
          knopf2: (Icons.mic_none, 'pe-stimme'),
        ),
        aufbau: BAufbau(
          dafuer: dafuer,
          jetzt: offen != null
              ? BJetzt(
                  titel: 'Pflege: $offen',
                  text: '$morgens von ${d.morgens.length} am Morgen erledigt.',
                  ring: morgens / d.morgens.length,
                  mitte: '$morgens/${d.morgens.length}',
                  unter: 'Pflege',
                  knopf: ('Pflege abhaken', 'pe-pflege'),
                )
              : lern < 10
              ? BJetzt(
                  titel: 'Noch ${10 - lern} Minuten ${k?.skill ?? 'Lernen'}',
                  text: 'Dann hast du dein Lern-Ziel für heute.',
                  ring: lern / 10,
                  mitte: '$lern/10',
                  unter: 'Minuten',
                  knopf: ('Lernen starten', 'pe-lern'),
                )
              : BJetzt(
                  fertig: true,
                  titel: stark,
                  text: 'Pflege und Lern-Ziel sind für heute geschafft.',
                  knopf: ('Weiter lernen', 'pe-lern'),
                ),
          serie: seriePflege,
          naechstes: lernZiel,
          geschafft: geschafftListe,
        ),
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
        bild: BBild(
          bau: (tipp, v, t) => LookBild(
            punkte: lookPunkte,
            unten: fotos < 2
                ? 'Look-Verlauf ab 2 Fortschrittsfotos'
                : 'Look-Verlauf: Woche 1 bis $fotos',
            tipp: tipp,
            v: v,
            t: t,
          ),
          zahlen: [
            BZahl('${look?.punkte.length ?? 0}', 'Hinweise', ziel: 'pe-look'),
            BZahl('$fotos', 'Fotos', ziel: 'pe-verlauf'),
            const BZahl('ehrlich', 'Stil-Check', ziel: 'pe-stil'),
          ],
          knopf: ('Foto machen', 'pe-look'),
          knopf2: (Icons.photo_camera_outlined, 'pe-stil'),
        ),
        aufbau: BAufbau(
          dafuer: dafuer,
          jetzt: look == null || look.punkte.isEmpty
              ? const BJetzt(
                  titel: 'Ein Foto reicht',
                  text:
                      'Ich zeige dir die drei kleinen Hebel, die bei dir am '
                      'meisten ausmachen.',
                  mitte: '0',
                  unter: 'Hinweise',
                  knopf: ('Foto machen', 'pe-look'),
                )
              : BJetzt(
                  titel: 'Dein Hebel: ${look.punkte.first.titel}',
                  text: '${look.punkte.length} Hinweise aus deinem Foto.',
                  mitte: '${look.punkte.length}',
                  unter: 'Hinweise',
                  knopf: ('Hinweise ansehen', 'pe-look'),
                ),
          serie: seriePflege,
          naechstes: BNaechstes(
            titel: 'Look-Verlauf',
            anteil: fotos / 2,
            text: fotos < 2
                ? 'Ab 2 Fortschrittsfotos siehst du den Verlauf.'
                : '$fotos Wochen im Verlauf.',
          ),
          geschafft: geschafftListe,
        ),
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
        bild: BBild(
          bau: (tipp, v, t) => HautBild(
            woche: hw,
            teiler: teiler,
            gross: hw == null
                ? 'Was stört dich an deiner Haut?'
                : 'Woche $hw von 8',
            klein: haut == null
                ? 'ein Plan über 8 Wochen'
                : phase?.text ?? haut.problem,
            kleine: kleinePunkte,
            tipp: tipp,
            v: v,
            t: t,
          ),
          zahlen: [
            BZahl(hw == null ? '–' : '$hw/8', 'Wochen', ziel: 'pe-haut'),
            BZahl(
              '$kleineHeute/${kleineHeute + faellig.length}',
              'heute dran',
              ziel: 'pe-kleine',
            ),
            BZahl('$bald', 'bald fällig', ziel: 'pe-kleine'),
          ],
          knopf: ('Routine abhaken', 'pe-kleine'),
          knopf2: (Icons.add, 'pe-haut'),
        ),
        aufbau: BAufbau(
          dafuer: dafuer,
          jetzt: faellig.isNotEmpty
              ? BJetzt(
                  titel: '${faellig.first.name} ist heute dran',
                  text: faellig.length == 1
                      ? 'Eine kleine Sache mit großer Wirkung.'
                      : 'Und ${faellig.length - 1} weitere kleine '
                            '${faellig.length == 2 ? 'Sache' : 'Sachen'}.',
                  ring: kleineGesamt == 0 ? null : kleineHeute / kleineGesamt,
                  mitte: '$kleineHeute/$kleineGesamt',
                  unter: 'heute',
                  knopf: ('Routine abhaken', 'pe-kleine'),
                )
              : haut == null
              ? const BJetzt(
                  titel: 'Was stört dich an deiner Haut?',
                  text: 'Daraus wird ein Plan über 8 Wochen.',
                  mitte: '0/8',
                  unter: 'Wochen',
                  knopf: ('Haut-Plan starten', 'pe-haut'),
                )
              : BJetzt(
                  fertig: true,
                  titel: stark,
                  text: 'Die kleinen Dinge sind für heute erledigt.',
                  knopf: ('Haut-Plan ansehen', 'pe-haut'),
                ),
          serie: seriePflege,
          naechstes: hw == null
              ? const BNaechstes(
                  titel: 'Haut-Plan',
                  anteil: 0,
                  text: 'Noch nicht gestartet.',
                )
              : BNaechstes(
                  titel: 'Haut-Plan: 8 Wochen',
                  anteil: hw / 8,
                  text: 'Woche $hw von 8.',
                ),
          geschafft: geschafftListe,
        ),
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
        bild: BBild(
          bau: (tipp, v, t) => WissenBild(
            skill: k?.skill,
            lektionen: k?.lektionen.length ?? 12,
            erreicht: k?.erreicht ?? 0,
            lektionText: lek != null
                ? 'Lektion ${k!.erreicht + 1} von ${k.lektionen.length}: ${lek.titel}'
                : k == null
                ? 'Welchen Skill willst du lernen?'
                : 'Kurs geschafft',
            buecher: regal,
            tipp: tipp,
            v: v,
            t: t,
          ),
          zahlen: [
            BZahl(
              k == null ? '–' : '${k.erreicht}/${k.lektionen.length}',
              'Lektionen',
              ziel: 'pe-kurs',
            ),
            BZahl('${d.buecher.length}', 'Bücher', ziel: 'pe-buecher'),
            BZahl('$umgesetzt', 'umgesetzt', ziel: 'pe-umsetzen'),
          ],
          knopf: lek != null
              ? ('Lektion ${k!.erreicht + 1} starten', 'pe-kurs')
              : k == null
              ? ('Skill wählen', 'pe-kurs')
              : ('Kurs ansehen', 'pe-kurs'),
          knopf2: (Icons.add, 'pe-buecher'),
        ),
        aufbau: BAufbau(
          dafuer: dafuer,
          jetzt: lek != null
              ? BJetzt(
                  titel: 'Lektion ${k!.erreicht + 1}: ${lek.titel}',
                  text: 'Dein Kurs ${k.skill}.',
                  ring: k.erreicht / k.lektionen.length,
                  mitte: '${k.erreicht}/${k.lektionen.length}',
                  unter: 'Lektionen',
                  knopf: ('Lektion ${k.erreicht + 1} starten', 'pe-kurs'),
                )
              : k == null
              ? const BJetzt(
                  titel: 'Welchen Skill willst du lernen?',
                  text: 'Ich baue dir daraus einen Kurs in kleinen Lektionen.',
                  mitte: '–',
                  unter: 'Lektionen',
                  knopf: ('Skill wählen', 'pe-kurs'),
                )
              : BJetzt(
                  fertig: true,
                  titel: stark,
                  text: 'Dein Kurs ${k.skill} ist durch.',
                  knopf: ('Kurs ansehen', 'pe-kurs'),
                ),
          serie: serieLernen,
          naechstes: d.umsetzen.isEmpty
              ? const BNaechstes(
                  titel: 'Erster Schritt aus einem Buch',
                  anteil: 0,
                  text: 'Aus jedem Buch machen wir einen kleinen Schritt.',
                )
              : BNaechstes(
                  titel: 'Wissen umsetzen',
                  anteil: umgesetzt / d.umsetzen.length,
                  text: '$umgesetzt von ${d.umsetzen.length} machst du schon.',
                ),
          geschafft: geschafftListe,
        ),
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
      name: 'Ausstrahlung',
      wert: wert,
      teile: [
        Unterbereich(
          id: 'persoenlich',
          name: 'Ausstrahlung',
          icon: Icons.person_outline,
          wert: wert,
          woche: [
            for (var i = 6; i >= 0; i--)
              _pew(jetzt.subtract(Duration(days: i))),
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
