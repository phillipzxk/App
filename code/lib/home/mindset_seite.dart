part of 'home_page.dart';

/// Mindset: four pages Heute, Dranbleiben, Ruhe, Langfristig (vault
/// Umsetzung/Mindset komplett, Entwurf 7, Phillip "Ja" 2026-10-29).
extension _Mindset on _HomePageState {
  MindsetCoach get _mindsetCoach => widget.coach is MindsetCoach
      ? widget.coach as MindsetCoach
      : const NoMindsetCoach();

  /// What comes next today, for the Danach-Plan.
  List<String> _tagDanach() {
    final jetzt = widget.clock();
    final m = jetzt.hour * 60 + jetzt.minute;
    final r = _tagRahmen;
    final punkte = <(int, String)>[
      for (final s in _mahlzeitSlots) (s.minute, '${s.name} ${s.uhrzeit}'),
      if (r.training case final t?)
        (t, '${shortDay(_woche.forDay(jetzt).trim())} ${formatUhrzeit(t)}'),
      if (_bettzeit?.bett case final b?)
        (b, 'Ins Bett ${formatUhrzeit(b % 1440)}'),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final p in punkte)
        if (p.$1 > m) p.$2,
    ];
  }

  MindsetUmfeld get _mindsetUmfeld => MindsetUmfeld(
    stand: _mindset,
    profile: widget.profile,
    coach: _mindsetCoach,
    jetzt: widget.clock,
    tagDanach: _tagDanach(),
    kontext: _essenTagText(),
  );

  Feld _mFeld(
    String titel,
    IconData icon,
    String coach,
    Widget Function(MindsetUmfeld u) seite,
  ) => Feld(
    titel: titel,
    icon: icon,
    coach: coach,
    inhalt: (_) => [seite(_mindsetUmfeld)],
  );

  Widget _mindsetSeite() {
    const b = Bereich.mindset;
    final d = _mindset.d;
    final heute = widget.clock();
    final name = widget.profile.name.trim();
    final offen = d.offeneSteine;
    final w = wortWoche(d, heute);
    final stufe = selbststaendig(d);
    final aus = ausredenListe(d);
    final muster = sichtbareMuster(_muster);
    final durch = inWoche(_durchgezogen, heute).length;
    final durchVorher = inWoche(
      _durchgezogen,
      heute.subtract(const Duration(days: 7)),
    ).length;
    final ruhe = ruheWoche(d, heute);
    final werteSchnittW = werteSchnitt(d, heute);
    final brief = naechsterBrief(d, heute);
    final offeneBriefeN = offeneBriefe(d, heute).length;
    final rad = d.raeder.lastOrNull;
    final radTage = tageBisRad(d, heute);

    final bergF = _mFeld(
      'Dein Berg',
      Icons.landscape,
      offen.isEmpty
          ? 'Leg alles drauf, wovor du dich drückst. Jeder Stein bekommt einen '
                'ersten Schritt von 2 Minuten.'
          : 'Tipp einen Stein an. Ich will heute nur 2 Minuten von dir.',
      (u) => BergSeite(u: u),
    );
    final wortF = _mFeld(
      'Wort gehalten',
      Icons.handshake_outlined,
      'Morgens bis zu 3 Sachen vornehmen, abends ehrlich abhaken.',
      (u) => WortSeite(u: u),
    );
    final ruheF = _mFeld(
      'Ruhe-Knopf',
      Icons.self_improvement,
      'Drei Minuten. Alles andere aus.',
      (u) => RuheSeite(u: u),
    );
    final durchF = Feld(
      titel: 'Durchgezogen',
      icon: Icons.bolt,
      coach:
          'Was du trotzdem gemacht hast. Ich trage ein, was ich klar sehe, '
          'du trägst den Rest ein.',
      inhalt: (_) => [
        _lebendig(
          () => DurchgezogenKarte(
            alle: _durchgezogen,
            today: widget.clock(),
            onAdd: _durchAdd,
            onAlle: _durchAlle,
          ),
        ),
      ],
    );
    final stufeF = _mFeld(
      'Selbstständig',
      Icons.stairs_outlined,
      '${stufe.eigene} erste Schritte kamen bisher von dir.',
      (u) => StufeSeite(u: u),
    );
    final ausF = _mFeld(
      'Ausreden-Spiegel',
      Icons.psychology_alt_outlined,
      aus.isEmpty
          ? 'Kein Vorwurf. Nur damit du siehst, was dich wann abhält.'
          : '„${aus.first.text}“ kam ${aus.first.n} Mal'
                '${aus.first.wann == null ? '' : ', ${aus.first.wann}'}.',
      (u) => AusredenSeite(u: u),
    );
    final musterF = Feld(
      titel: 'Deine Muster',
      icon: Icons.insights,
      coach:
          'Ich zeige nur, was ich klar sehe. Stimmt etwas nicht, nehme ich es '
          'raus und sage es nicht wieder.',
      inhalt: (_) => [
        _lebendig(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final m in sichtbareMuster(_muster))
                MusterKarte(
                  muster: m,
                  onAblehnen: () => _musterAblehnen(m),
                  onAlle: _oeffneMuster,
                ),
              if (sichtbareMuster(_muster).isEmpty)
                Block(
                  children: [
                    Text(
                      'Gerade kein klares Muster. Ich melde mich, sobald ich '
                      'eins sicher sehe.',
                      style: Glas.tSoft.copyWith(fontSize: 13.5),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
    final werteF = _mFeld(
      'Deine Werte',
      Icons.diamond_outlined,
      'Sei ehrlich mit dir: Wie gut hast du diese Woche danach gelebt?',
      (u) => WerteSeite(u: u),
    );
    final sorgenF = _mFeld(
      'Sorgen abgeben',
      Icons.cloud_outlined,
      'Schreib einfach los, ohne Ordnung. Ich sortiere mit dir.',
      (u) => SorgenSeite(u: u),
    );
    final abendF = _mFeld(
      'Frage heute Abend',
      Icons.nightlight_round,
      'Eine Frage pro Abend, nach dem Abend-Journal.',
      (u) => AbendFrageSeite(u: u),
    );
    final radF = _mFeld(
      'Dein Lebensrad',
      Icons.donut_large,
      radSatz(d) ??
          'Alle 3 Monate einmal ehrlich: Wie zufrieden bist du in jedem '
              'Bereich?',
      (u) => RadSeite(u: u),
    );
    final briefF = _mFeld(
      'Brief an dich',
      Icons.mail_outline,
      brief == null
          ? 'Schreib dir heute. Er öffnet sich erst in 6 Monaten.'
          : 'Versiegelt. In ${brief.tageBis(heute)} Tagen lege ich dir daneben, '
                'was sich verändert hat.',
      (u) => BriefSeite(u: u),
    );
    final zieleF = _mFeld(
      'Lebensziele',
      Icons.brightness_7_outlined,
      'Ganz unten im Wurzelwerk. Alles andere wächst darauf zu.',
      (u) => ZieleSeite(u: u),
    );
    final warumF = Feld(
      titel: 'Dein Warum',
      icon: Icons.favorite_border,
      coach:
          'Deine eigenen Worte vom Anfang. Ich hole sie raus, wenn es zäh '
          'wird.',
      inhalt: (_) => [
        Block(
          art: GlasArt.gold,
          children: [
            Text(
              widget.profile.motivation.trim().isEmpty
                  ? 'Noch kein Warum. Du kannst das Onboarding neu machen.'
                  : '„${widget.profile.motivation.trim()}“',
              style: CoachStyle.question.copyWith(
                fontSize: 19,
                color: Glas.text,
              ),
            ),
            if (_warumSatz case final s?) ...[
              const SizedBox(height: 12),
              CoachZeile(s),
            ],
          ],
        ),
      ],
    );

    String coachHeute() {
      if (offen.isNotEmpty) {
        final s = offen.first;
        final n = tageSeit(s.seit, heute);
        return '${name.isEmpty ? '' : '$name, '}'
            '${name.isEmpty ? 'Der' : 'der'} Stein „${s.titel}“ liegt '
            '${n == 0 ? 'seit heute' : seitText(s.seit, heute)}. Heute nur 2 '
            'Minuten, mehr will ich nicht.';
      }
      return _coach(
        b,
        'Wovor drückst du dich gerade? Leg es auf deinen Berg, wir machen es '
        'klein.',
      );
    }

    final seiten = [
      BSeite(
        name: 'Heute',
        coach: coachHeute(),
        kacheln: [
          BKachel(
            id: 'm-berg',
            titel: 'Dein Berg',
            icon: Icons.landscape,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: offen.isEmpty ? null : 'heute dran',
            wert: '${offen.length} ${offen.length == 1 ? 'Stein' : 'Steine'}',
            unter: offen.isEmpty
                ? 'Leg deinen ersten Stein'
                : 'Nächster: ${offen.first.titel}, 2 Min',
            bild: BergMini(daten: d),
            feld: bergF,
          ),
          BKachel(
            id: 'm-wort',
            titel: 'Wort gehalten',
            icon: Icons.handshake_outlined,
            wert: '${w.gehalten}/${w.vorgenommen}',
            unter: 'diese Woche',
            feld: wortF,
          ),
          BKachel(
            id: 'm-ruhe',
            titel: 'Ruhe-Knopf',
            icon: Icons.self_improvement,
            text: '3 Minuten nur atmen',
            knopf: 'Starten',
            onKnopf: () => starteRuhe(context, _mindsetUmfeld),
            feld: ruheF,
          ),
        ],
      ),
      BSeite(
        name: 'Dranbleiben',
        coach: w.vorgenommen == 0 && stufe.eigene == 0
            ? 'Nimm dir morgens etwas vor und schlag erste Schritte selbst '
                  'vor. So brauchst du mich immer weniger.'
            : [
                if (w.vorgenommen > 0)
                  'Diese Woche ${w.gehalten} von ${w.vorgenommen} Mal Wort '
                      'gehalten.',
                if (stufe.eigene > 0)
                  '${stufe.eigene} erste Schritte kamen von dir.',
              ].join(' '),
        kacheln: [
          BKachel(
            id: 'm-durch',
            titel: 'Durchgezogen',
            icon: Icons.bolt,
            wert: '$durch×',
            unter: 'seit Montag · letzte Woche $durchVorher',
            feld: durchF,
          ),
          BKachel(
            id: 'm-stufe',
            titel: 'Selbstständig',
            icon: Icons.stairs_outlined,
            wert: 'Stufe ${stufe.stufe}',
            bild: StufenStriche(stufe: stufe.stufe),
            feld: stufeF,
          ),
          BKachel(
            id: 'm-aus',
            titel: 'Ausreden-Spiegel',
            icon: Icons.psychology_alt_outlined,
            groesse: KachelGroesse.mittel,
            text: aus.isEmpty ? 'Noch keine Ausrede' : '„${aus.first.text}“',
            unter: aus.isEmpty
                ? 'kommt, wenn du einen Stein liegen lässt'
                : aus.first.wann ?? '${aus.first.n} Mal',
            feld: ausF,
          ),
          BKachel(
            id: 'm-muster',
            titel: 'Deine Muster',
            icon: Icons.insights,
            groesse: KachelGroesse.schmal,
            hot: muster.isEmpty ? null : '${muster.length} erkannt',
            text: muster.isEmpty
                ? 'Gerade kein klares Muster'
                : muster.first.text,
            unter: muster.isEmpty
                ? null
                : 'Gegenschritt: ${muster.first.schritt}',
            feld: musterF,
          ),
        ],
      ),
      BSeite(
        name: 'Ruhe',
        coach: werteSchnittW == null
            ? (ruhe.n > 0
                  ? 'Diese Woche ${ruhe.n} Mal Ruhe genommen. Wie gut hast du '
                        'nach deinen Werten gelebt?'
                  : 'Wie gut hast du diese Woche nach deinen Werten gelebt?')
            : werteSchnittW >= 4
            ? 'Diese Woche hast du gut nach deinen Werten gelebt.'
            : 'Bei deinen Werten ist diese Woche noch Luft. Was hat gefehlt?',
        kacheln: [
          BKachel(
            id: 'm-werte',
            titel: 'Deine Werte',
            icon: Icons.diamond_outlined,
            text: d.werte.isEmpty
                ? 'Leg deine Werte fest'
                : d.werte.map((x) => x.name).join(' · '),
            unter: werteSchnittW == null
                ? 'diese Woche noch offen'
                : 'Schnitt ${werteSchnittW.toStringAsFixed(1)} von 5',
            feld: werteF,
          ),
          BKachel(
            id: 'm-sorgen',
            titel: 'Sorgen abgeben',
            icon: Icons.cloud_outlined,
            text: 'Was bedrückt dich gerade?',
            unter: 'Schreiben ›',
            feld: sorgenF,
          ),
          BKachel(
            id: 'm-abend',
            titel: 'Frage heute Abend',
            icon: Icons.nightlight_round,
            groesse: KachelGroesse.mittel,
            nacht: true,
            text: '„${abendFrage(d, heute)}“',
            unter: abendHeute(d, heute) == null
                ? 'nach dem Abend-Journal'
                : 'heute beantwortet',
            feld: abendF,
          ),
        ],
      ),
      BSeite(
        name: 'Langfristig',
        coach: radSatz(d) ?? 'Füll dein Lebensrad aus. Dann sehe ich, wo am meisten zu holen ist.',
        kacheln: [
          BKachel(
            id: 'm-rad',
            titel: 'Dein Lebensrad',
            icon: Icons.donut_large,
            groesse: KachelGroesse.hoch,
            wert: rad == null ? 'Ausfüllen' : 'Ø ${rad.schnitt.round()}',
            unter: rad == null
                ? 'alle 3 Monate, 5 Bereiche'
                : radTage == 0
                ? 'neues ist dran'
                : 'nächstes in $radTage Tagen',
            hot: rad != null && radTage == 0 ? 'dran' : null,
            bild: rad == null
                ? null
                : RadBild(
                    jetzt: rad.werte,
                    vorher: radVorher(d)?.werte,
                    size: 110,
                    namen: false,
                  ),
            feld: radF,
          ),
          BKachel(
            id: 'm-brief',
            titel: 'Brief an dich',
            icon: Icons.mail_outline,
            hot: offeneBriefeN > 0 ? 'offen' : null,
            wert: brief == null ? null : '${brief.tageBis(heute)}',
            text: brief == null
                ? (offeneBriefeN > 0 ? 'Dein Brief ist offen' : 'Schreib dir')
                : null,
            unter: brief == null
                ? 'öffnet nach 6 Monaten'
                : 'Tage, bis er sich öffnet',
            feld: briefF,
          ),
          BKachel(
            id: 'm-ziele',
            titel: 'Lebensziele',
            icon: Icons.brightness_7_outlined,
            text: d.ziele.isEmpty
                ? 'Was willst du erreichen?'
                : d.ziele.map((z) => z.text).join(' · '),
            unter: d.ziele.isEmpty
                ? 'ganz groß gedacht'
                : '${d.ziele.length} ${d.ziele.length == 1 ? 'Ziel' : 'Ziele'}',
            feld: zieleF,
          ),
          BKachel(
            id: 'm-warum',
            titel: 'Dein Warum',
            icon: Icons.favorite_border,
            groesse: KachelGroesse.schmal,
            text: widget.profile.motivation.trim().isEmpty
                ? 'Noch kein Warum'
                : '„${widget.profile.motivation.trim()}“',
            feld: warumF,
          ),
        ],
      ),
    ];

    return BereichSeite(
      key: const ValueKey('mindset-seite'),
      name: 'Mindset',
      wert: _wert(b).$1,
      teile: [
        Unterbereich(
          id: b.name,
          name: 'Mindset',
          icon: Icons.landscape,
          wert: _wert(b).$1,
          woche: _woche7(b),
          sub: _subZeile(b),
          seiten: seiten,
        ),
      ],
      verlauf: Feld(
        titel: 'Mindset im Verlauf',
        icon: Icons.show_chart,
        coach: 'Die letzten 30 Tage. Die gestrichelte Linie ist dein Schnitt.',
        inhalt: (_) => [
          _lebendig(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AreaChart(bereich: b),
                if (_heute?.gruende[b.name]?.trim() case final g?
                    when g.isNotEmpty)
                  Block(
                    label: 'Warum gerade hier',
                    children: [Text(g, style: Glas.tText)],
                  ),
              ],
            ),
          ),
        ],
      ),
      frag: (_) => Feld(
        titel: 'Frag den Coach',
        icon: Icons.chat_bubble_outline,
        coach:
            'Alles zu Mindset. Ich kenne deinen Berg, deine Ausreden und '
            'deine Check-ins.',
        inhalt: (_) => [
          _lebendig(
            () => AskCoachCard(
              title: 'Wovor drückst du dich gerade?',
              hint:
                  'Schreib es auf, und wir finden den ersten kleinen Schritt.',
              today: _todayFragen(b),
              onSend: _ask(b),
            ),
          ),
        ],
      ),
    );
  }
}
