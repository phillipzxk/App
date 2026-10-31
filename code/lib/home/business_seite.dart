part of 'home_page.dart';

/// Business & Beruf: Woche, Ziele, Ideen, Wachstum (vault Umsetzung/
/// Business und Beruf komplett, Phillip "jo passt" 2026-10-29).
extension _Business on _HomePageState {
  BusinessCoach get _businessCoach => widget.coach is BusinessCoach
      ? widget.coach as BusinessCoach
      : const NoBusinessCoach();

  /// Work done (Produktivität value) on training days, other days and after
  /// short nights, over the last 30 days. Each needs 3 days.
  ArbeitKoerper _arbeitKoerper() {
    final jetzt = widget.clock();
    final mit = <int>[], ohne = <int>[], kurz = <int>[];
    final schlaf = {for (final m in _schlaf.d.morgen) m.tag: m.stunden};
    final checks = {for (final c in _checkIns) dayKey(c.datum): c};
    for (var i = 0; i < 30; i++) {
      final k = dayKey(jetzt.subtract(Duration(days: i)));
      final w = produktivWert(_produktiv.d, k);
      if (w == null) continue;
      final c = checks[k];
      if (c != null) {
        (c.training == 'Gut trainiert' || c.training == 'Lief zäh' ? mit : ohne)
            .add(w);
      }
      if ((schlaf[k] ?? 99) < 7) kurz.add(w);
    }
    double? schnitt(List<int> l) =>
        l.length < 3 ? null : l.reduce((a, b) => a + b) / l.length;
    return (
      mit: schnitt(mit),
      ohne: schnitt(ohne),
      kurz: schnitt(kurz),
      tage: mit.length + ohne.length,
    );
  }

  BusinessUmfeld get _businessUmfeld => BusinessUmfeld(
    stand: _business,
    profile: widget.profile,
    coach: _businessCoach,
    jetzt: widget.clock,
    koerper: _arbeitKoerper(),
  );

  Feld _bFeld(
    String titel,
    IconData icon,
    String coach,
    Widget Function(BusinessUmfeld u) seite,
  ) => Feld(
    titel: titel,
    icon: icon,
    coach: coach,
    inhalt: (_) => [seite(_businessUmfeld)],
  );

  Widget _businessSeite() {
    final d = _business.d;
    final jetzt = widget.clock();
    final name = widget.profile.name.trim();
    final wert = _bw(jetzt);
    final wertGestern = _bw(jetzt.subtract(const Duration(days: 1)));
    final h = d.hebelIn(dayKey(montagVon(jetzt)));
    final monat = monatVon(jetzt);
    final ziel = d.ziele[monat];
    final um = umsatzIm(d, monat);
    final mutig = d.anfragen.where((a) => a.an).length;
    final offen = d.anfragen.length - mutig;
    final e = d.euro;
    final s = d.spar;
    final sw = stundenwert(d);
    final best = besteTaetigkeit(d);
    final kerne = d.gedanken.where((g) => g.kern).length;
    final p = d.pruefung;
    final g = d.gespraech;
    final ast = naechsterAst(d);
    final astText = ast == null ? null : d.meilensteine[ast].text;
    final astAnt = astText == null ? null : astAnteil(astText, d, jetzt);
    final erreicht = d.meilensteine.where((m) => m.an).length;
    final sk = d.skill;
    final plus = trainingsPlus(_arbeitKoerper());
    final verlauf = _verlauf(_bw, jetzt);
    final da = [for (final v in verlauf) ?v];
    final schnitt = da.isEmpty
        ? null
        : (da.reduce((a, b) => a + b) / da.length).round();
    final anrede = name.isEmpty ? '' : '$name, ';

    String sub() {
      if (wert == null) return 'Leg deinen Hebel für diese Woche fest';
      if (wertGestern == null) return '$wert von 10';
      final diff = wert - wertGestern;
      return diff == 0
          ? 'gleich wie gestern'
          : '${diff > 0 ? '+' : '−'}${diff.abs()} zu gestern';
    }

    final verlaufF = Feld(
      titel: 'Business im Verlauf',
      icon: Icons.show_chart,
      coach:
          'Wie dein Business sich bewegt. Die gestrichelte Linie ist dein '
          'Schnitt.',
      inhalt: (_) => [
        _lebendig(
          () => Block(
            label: 'Business · 30 Tage',
            rechts: schnitt == null ? null : 'Ø $schnitt',
            children: [
              if (da.isEmpty)
                Text(
                  'Sobald du einen Hebel, ein Umsatz-Ziel oder mutige Anfragen '
                  'einträgst, wächst hier deine Linie.',
                  style: Glas.tSoft.copyWith(fontSize: 13.5),
                )
              else
                Linie30(werte: _verlauf(_bw, widget.clock())),
            ],
          ),
        ),
        Block(
          children: [
            Text(
              'So rechne ich: die Schritte deines Hebels, dein Umsatz gegen '
              'das Monatsziel bis heute und mutige Anfragen dieser Woche.',
              style: Glas.tSoft.copyWith(fontSize: 13),
            ),
          ],
        ),
      ],
    );

    final seiten = [
      BSeite(
        name: 'Woche',
        coach: h == null
            ? '${anrede}welche eine Aktion bewegt diese Woche am meisten?'
            : '${anrede}diese Woche zählt ein Hebel: ${h.text}.'
                  '${h.punkte.isEmpty ? '' : ' ${h.erledigt} von ${h.punkte.length} geschafft.'}',
        kacheln: [
          BKachel(
            id: 'b-hebel',
            titel: 'Hebel der Woche',
            icon: Icons.trending_up,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: h == null ? 'diese Woche' : 'bis Sonntag',
            text: h?.text ?? 'Was bewegt diese Woche am meisten?',
            unter: h == null
                ? 'eine Aktion, dazu 3 Tipps vom Coach'
                : '${h.erledigt} von ${h.punkte.length} erledigt'
                      '${h.tipps.isEmpty ? '' : ' · ${h.tipps.length} Tipps vom Coach'}',
            feld: _bFeld(
              'Hebel der Woche',
              Icons.trending_up,
              'Eine Aktion, die diese Woche am meisten bewegt. Dazu Tipps, auf '
                  'die man allein nicht kommt.',
              (u) => HebelSeite(u: u),
            ),
          ),
          BKachel(
            id: 'b-anfrage',
            titel: 'Mutige Anfrage',
            icon: Icons.send_outlined,
            bild: Spross(n: mutig, size: 56),
            wert: '$mutig',
            unter: 'geschafft · $offen offen',
            feld: _bFeld(
              'Mutige Anfrage',
              Icons.send_outlined,
              'Alles, was dir schwerfällt. Jedes Mal, wenn du eins schaffst, '
                  'wächst etwas.',
              (u) => AnfrageSeite(u: u),
            ),
          ),
          BKachel(
            id: 'b-euro',
            titel: 'Der erste Euro',
            icon: Icons.euro,
            text: e.da != null
                ? 'Ist da'
                : e.angebot ?? 'Was kannst du verkaufen?',
            unter: e.da != null
                ? 'Glückwunsch'
                : e.preis == null
                ? 'kleinste Version, die jemand kauft'
                : '${euro(e.preis!)} · Schritt ${e.schritte} von 4',
            bild: SizedBox(width: 70, child: Striche(n: e.schritte, von: 4)),
            feld: _bFeld(
              'Der erste Euro',
              Icons.euro,
              'Nicht perfekt, sondern verkauft. Die kleinste Version, für die '
                  'diese Woche jemand zahlt.',
              (u) => EuroSeite(u: u),
            ),
          ),
        ],
      ),
      BSeite(
        name: 'Ziele',
        coach: ziel == null
            ? 'Setz dir ein Umsatz-Ziel für ${monatName(jetzt)}. Eins, mehr nicht.'
            : um >= ziel
            ? 'Monatsziel geschafft. Alles darüber ist Vorsprung.'
            : 'Noch ${euro(ziel - um)} bis zu deinem Monatsziel.'
                  '${best == null ? '' : ' ${best.name} bringt dir am meisten pro Stunde.'}',
        kacheln: [
          BKachel(
            id: 'b-umsatz',
            titel: 'Umsatz-Ziel',
            icon: Icons.flag_outlined,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: monatName(jetzt),
            bild: ziel == null
                ? null
                : GoldRing(
                    anteil: um / ziel,
                    text: '${(um / ziel * 100).clamp(0, 999).round()} %',
                    size: 76,
                    dicke: 8,
                  ),
            wert: ziel == null ? 'Ziel setzen' : euro(um),
            unter: ziel == null
                ? 'ein Ziel für den Monat'
                : um >= ziel
                ? 'von ${euro(ziel)} · geschafft'
                : 'von ${euro(ziel)} · noch ${euro(ziel - um)}',
            feld: _bFeld(
              'Umsatz-Ziel',
              Icons.flag_outlined,
              'Ein Ziel für den Monat. Wenn es geschafft ist, haken wir es '
                  'ganz groß ab.',
              (u) => UmsatzSeite(u: u),
            ),
          ),
          BKachel(
            id: 'b-spar',
            titel: 'Spar-Plan',
            icon: Icons.savings_outlined,
            text: s?.name ?? 'Wofür sparst du?',
            bild: s == null
                ? null
                : SizedBox(
                    width: 90,
                    child: GoldBalken(anteil: s.anteil, hoehe: 6),
                  ),
            unter: s == null
                ? 'und lohnt sich das?'
                : '${euro(s.stand)} von ${euro(s.ziel)}'
                      '${s.monatlich > 0 ? ' · ${euro(s.monatlich)} im Monat' : ''}',
            feld: _bFeld(
              'Spar-Plan',
              Icons.savings_outlined,
              'Wie viel du zurücklegst, wofür, und ob sich etwas wirklich lohnt.',
              (u) => SparSeite(u: u),
            ),
          ),
          BKachel(
            id: 'b-stunde',
            titel: 'Stundenwert',
            icon: Icons.schedule,
            wert: sw == null ? '– €' : '$sw €',
            unter: best == null
                ? 'pro Stunde'
                : 'pro Stunde · ${best.name} bringt ${best.proStunde} €',
            feld: _bFeld(
              'Dein Stundenwert',
              Icons.schedule,
              'Was dir eine Stunde Arbeit wirklich bringt, und worauf du dich '
                  'deshalb konzentrierst.',
              (u) => StundeSeite(u: u),
            ),
          ),
        ],
      ),
      BSeite(
        name: 'Ideen',
        coach: kerne > 0
            ? 'Du hast $kerne Kernidee${kerne == 1 ? '' : 'n'}. Arbeite die '
                  'stärkste mit mir aus, dann wird ein Plan daraus.'
            : p != null && p.reifeJetzt < 80
            ? '„${p.idee}“ ist noch nicht reif. Erst die harten Fragen.'
            : 'Leg jeden Gedanken ab, auch die halben. Gold machst du die, die '
                  'zählen.',
        kacheln: [
          BKachel(
            id: 'b-brain',
            titel: 'Brainstorming',
            icon: Icons.lightbulb_outline,
            groesse: KachelGroesse.mittel,
            gold: true,
            hot: kerne == 0 ? null : '$kerne Kernidee${kerne == 1 ? '' : 'n'}',
            text: d.gedanken.isEmpty
                ? 'Einfach losschreiben, ohne Ordnung'
                : [for (final x in d.gedanken.reversed.take(4)) x.text]
                      .map((t) => t.length > 26 ? '${t.substring(0, 25)}…' : t)
                      .join(' · '),
            unter: '${d.gedanken.length} Gedanken abgelegt',
            feld: _bFeld(
              'Brainstorming',
              Icons.lightbulb_outline,
              'Deine Gedanken, ohne Ordnung. Daraus machen wir zusammen Ziele '
                  'und einen Plan vom Anfang bis zum Ende.',
              (u) => BrainSeite(u: u),
            ),
          ),
          BKachel(
            id: 'b-pruef',
            titel: 'Ideen-Prüfer',
            icon: Icons.verified_outlined,
            text: p?.idee ?? 'Idee prüfen, bevor du baust',
            bild: p == null
                ? null
                : SizedBox(
                    width: 80,
                    child: GoldBalken(anteil: p.reifeJetzt / 100, hoehe: 6),
                  ),
            unter: p == null
                ? 'harte Fragen, Reife in Prozent'
                : '${p.reifeJetzt} % reif'
                      '${p.offen == 0 ? '' : ' · ${p.offen} Fragen offen'}',
            feld: _bFeld(
              'Ideen-Prüfer',
              Icons.verified_outlined,
              'Harte Fragen, bevor du Zeit in eine Idee steckst.',
              (u) => PruefSeite(u: u),
            ),
          ),
          BKachel(
            id: 'b-gespraech',
            titel: 'Gesprächs-Hilfe',
            icon: Icons.forum_outlined,
            text: g?.mit ?? 'Wichtiges Gespräch?',
            unter: g == null
                ? 'Leitfaden und Antworten auf Einwände'
                : '${g.wann == null ? '' : '${g.wann} · '}Leitfaden fertig',
            feld: _bFeld(
              'Gesprächs-Hilfe',
              Icons.forum_outlined,
              'Vor jedem wichtigen Gespräch ein Leitfaden.',
              (u) => GespraechSeite(u: u),
            ),
          ),
        ],
      ),
      BSeite(
        name: 'Wachstum',
        coach: astText == null
            ? 'Trag deine Meilensteine ein. Jeder wird ein Ast an deinem Baum.'
            : '$erreicht ${erreicht == 1 ? 'Ast steht' : 'Äste stehen'} schon. '
                  'Der nächste ist $astText'
                  '${astAnt == null ? '.' : ', du bist bei ${(astAnt * 100).round()} Prozent.'}',
        kacheln: [
          BKachel(
            id: 'b-baum',
            titel: 'Business-Baum',
            icon: Icons.park_outlined,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: '$erreicht ${erreicht == 1 ? 'Ast' : 'Äste'}',
            bild: d.meilensteine.isEmpty
                ? null
                : SizedBox(
                    width: 130,
                    child: BusinessBaum(meilensteine: d.meilensteine),
                  ),
            text: astText ?? 'Dein erster Meilenstein?',
            unter: astText == null
                ? 'jeder Meilenstein ein Ast'
                : astAnt == null
                ? 'nächster Ast'
                : 'nächster Ast · du bist bei ${(astAnt * 100).round()} %',
            feld: _bFeld(
              'Business-Baum',
              Icons.park_outlined,
              'Jeder Meilenstein ist ein Ast. So siehst du, wie dein Business '
                  'wächst.',
              (u) => BaumSeite(u: u),
            ),
          ),
          BKachel(
            id: 'b-skill',
            titel: 'Skill-Leiter',
            icon: Icons.stairs_outlined,
            text: sk?.name ?? 'Welcher Skill?',
            bild: sk == null
                ? null
                : SizedBox(
                    width: 90,
                    child: Striche(n: sk.erreicht, von: sk.stufen.length),
                  ),
            unter: sk == null
                ? '7 Stufen, eine nach der anderen'
                : 'Stufe ${sk.erreicht} von ${sk.stufen.length}',
            feld: _bFeld(
              'Skill-Leiter',
              Icons.stairs_outlined,
              'Ein Skill, Stufe für Stufe, jede baut auf der letzten auf.',
              (u) => SkillSeite(u: u),
            ),
          ),
          BKachel(
            id: 'b-koerper',
            titel: 'Arbeit & Körper',
            icon: Icons.monitor_heart_outlined,
            wert: plus == null
                ? '–'
                : '${plus >= 0 ? '+' : '−'}${plus.abs()} %',
            unter: plus == null
                ? 'kommt nach ein paar Tagen'
                : 'mehr geschafft an Trainingstagen',
            feld: _bFeld(
              'Arbeit & Körper',
              Icons.monitor_heart_outlined,
              'Wie Training, Schlaf und Energie deine Arbeit verändern.',
              (u) => KoerperArbeitSeite(u: u),
            ),
          ),
        ],
      ),
    ];

    return BereichSeite(
      key: const ValueKey('business-seite'),
      name: 'Business',
      wert: wert,
      teile: [
        Unterbereich(
          id: 'business',
          name: 'Business',
          icon: Icons.work_outline,
          wert: wert,
          woche: [
            for (var i = 6; i >= 0; i--) _bw(jetzt.subtract(Duration(days: i))),
          ],
          sub: sub(),
          seiten: seiten,
        ),
      ],
      verlauf: verlaufF,
      frag: (_) => Feld(
        titel: 'Frag den Coach',
        icon: Icons.chat_bubble_outline,
        coach:
            'Alles zu Business und Beruf. Ich kenne deinen Hebel, deine '
            'Ziele und deine Ideen.',
        inhalt: (_) => [
          _lebendig(
            () => AskCoachCard(
              title: 'Wo hängt es gerade im Business?',
              hint: 'Schreib, was dich bremst oder was du vorhast.',
              today: _todayFragen(Bereich.mindset),
              onSend: _ask(Bereich.mindset),
            ),
          ),
        ],
      ),
    );
  }
}
