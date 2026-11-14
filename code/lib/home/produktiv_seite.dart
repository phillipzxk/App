part of 'home_page.dart';

/// Fokus & Arbeit: Heute, Ziele, Handy, Rhythmus, Routinen (vault
/// Umsetzung/Produktivität und Fokus komplett, Phillip 2026-10-29 16:36;
/// "Ziele" from the old Business area since 2026-11-04).
extension _Produktiv on _HomePageState {
  ProduktivUmfeld get _produktivUmfeld {
    final jetzt = widget.clock();
    final e = _schlafUmfeld.energieHeute();
    return ProduktivUmfeld(
      stand: _produktiv,
      jetzt: widget.clock,
      energieJetzt: energieUm(e.werte, jetzt.hour * 60 + jetzt.minute),
      aufstehen: _schlafzeiten.aufstehenAm(jetzt),
      tag: _tagZeilen(),
    );
  }

  /// Today's plan as short lines for the Fokus page.
  List<String> _tagZeilen() {
    final jetzt = widget.clock();
    final r = _tagRahmen;
    final punkte = <(int, String)>[
      for (final s in _mahlzeitSlots) (s.minute, s.name),
      if (r.training case final t?) (t, shortDay(_woche.forDay(jetzt).trim())),
      for (final t in termineAm(_termine, jetzt))
        if (parseUhrzeit(t.zeit ?? '') case final m?) (m, t.text),
      if (_bettzeit?.bett case final b?) (b, 'Ins Bett'),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final p in punkte) '${formatUhrzeit(p.$1 % 1440)}  ${p.$2}'];
  }

  Feld _pFeld(
    String titel,
    IconData icon,
    String coach,
    Widget Function(ProduktivUmfeld u) seite,
  ) => Feld(
    titel: titel,
    icon: icon,
    coach: coach,
    inhalt: (_) => [seite(_produktivUmfeld)],
  );

  Widget _produktivSeite() {
    final d = _produktiv.d;
    final jetzt = widget.clock();
    final heute = dayKey(jetzt);
    final gestern = dayKey(jetzt.subtract(const Duration(days: 1)));
    final name = widget.profile.name.trim();
    final wert = _pw(jetzt);
    final wertGestern = _pw(jetzt.subtract(const Duration(days: 1)));
    final u = _produktivUmfeld;
    final e = _schlafUmfeld.energieHeute();
    final hoch =
        '${formatUhrzeit(e.hoch.$1 % 1440)} bis ${formatUhrzeit(e.hoch.$2 % 1440)}';
    final f = d.fokusAm(heute);
    final block = blockVorschlag(u.energieJetzt);
    final bild = d.bildschirm[heute];
    final bildGestern = d.bildschirm[gestern];
    final drangHeute = drangAm(d, heute).length;
    final stunde = drangStunde(d);
    final frei7 = letzte7(d.handyfreiTage, jetzt).where((x) => x).length;
    final aktiv = aktiverAndock(d);
    final laeuft = laufende(d);
    final schlafMuster = sichtbareSchlafMuster(_schlaf.d);
    final gibt = schlafMuster.where((m) => m.gut).toList();
    final nimmt = schlafMuster.where((m) => !m.gut).toList();
    final bz = _business.d;
    final h = bz.hebelIn(dayKey(montagVon(jetzt)));
    final ast = naechsterAst(bz);
    final astText = ast == null ? null : bz.meilensteine[ast].text;
    final astAnt = astText == null ? null : astAnteil(astText, bz, jetzt);
    final erreicht = bz.meilensteine.where((m) => m.an).length;
    final verlauf = _verlauf(_pw, jetzt);
    final da = [for (final v in verlauf) ?v];
    final schnitt = da.isEmpty
        ? null
        : (da.reduce((a, b) => a + b) / da.length).round();

    // For the pictures (draft "Bereiche als Bilder" 3).
    String kurz(int m) =>
        m % 60 == 0 ? '${(m ~/ 60) % 24}' : formatUhrzeit(m % 1440);
    final tagVon = e.werte.first.$1, tagBis = e.werte.last.$1;
    final drangGestern = drangAm(d, gestern).length;
    final gruendeHeute = <String, int>{};
    for (final x in drangAm(d, heute).isEmpty ? d.drang : drangAm(d, heute)) {
      if (x.grund case final g?) gruendeHeute[g] = (gruendeHeute[g] ?? 0) + 1;
    }
    final gruende = [for (final e in gruendeHeute.entries) (e.key, e.value)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final freiMin = d.handyfreiMinuten;
    String minText(int m) => m < 60
        ? '$m Min'
        : m % 60 == 0
        ? '${m ~/ 60} h'
        : '${(m / 60).toStringAsFixed(1).replaceAll('.', ',')} h';
    final ms = bz.meilensteine;
    final List<ZielBlatt> blaetter;
    if (ms.isEmpty) {
      blaetter = [(name: 'Dein erster Meilenstein?', art: -1)];
    } else {
      final int start = ((ast ?? ms.length) - 1).clamp(
        0,
        math.max(0, ms.length - 4),
      );
      blaetter = [
        for (var i = start; i < math.min(start + 4, ms.length); i++)
          (
            name: ms[i].text,
            art: ms[i].an
                ? 2
                : i == ms.length - 1 && ms.length > 1
                ? -1
                : i == ast
                ? 1
                : 0,
          ),
      ];
    }
    final hebelFertig =
        h != null && h.punkte.isNotEmpty && h.erledigt == h.punkte.length;
    int amStueck(List<String> tage) {
      var n = 0;
      var t = jetzt;
      if (!tage.contains(dayKey(t))) t = t.subtract(const Duration(days: 1));
      while (tage.contains(dayKey(t)) && n < 999) {
        n++;
        t = t.subtract(const Duration(days: 1));
      }
      return n;
    }

    final glieder = [
      ...d.andocken.where((a) => !a.laeuft),
      ...d.andocken.where((a) => a.laeuft),
    ].take(3).toList();
    final stueck = d.andocken.isEmpty
        ? 0
        : d.andocken.map((a) => amStueck(a.tage)).reduce(math.max);

    String sub() {
      if (wert == null) return 'Leg heute deinen Fokus fest';
      if (wertGestern == null) return '$wert von 10';
      final diff = wert - wertGestern;
      return diff == 0
          ? 'gleich wie gestern'
          : '${diff > 0 ? '+' : '−'}${diff.abs()} zu gestern';
    }

    final verlaufF = Feld(
      titel: 'Produktivität im Verlauf',
      icon: Icons.show_chart,
      coach:
          'Wie gut du deine Zeit und deinen Fokus genutzt hast. Die '
          'gestrichelte Linie ist dein Schnitt.',
      inhalt: (_) => [
        _lebendig(
          () => Block(
            label: 'Produktivität · 30 Tage',
            rechts: schnitt == null ? null : 'Ø $schnitt',
            children: [
              if (da.isEmpty)
                Text(
                  'Sobald du Fokus, Blöcke oder handyfreie Morgen einträgst, '
                  'wächst hier deine Linie.',
                  style: Glas.tSoft.copyWith(fontSize: 13.5),
                )
              else
                Linie30(werte: _verlauf(_pw, widget.clock())),
            ],
          ),
        ),
        Block(
          children: [
            Text(
              'So rechne ich: die eine Sache geschafft, Minuten im Fokus '
              '(50 sind voll) und der handyfreie Morgen.',
              style: Glas.tSoft.copyWith(fontSize: 13),
            ),
          ],
        ),
      ],
    );

    final stundenF = Feld(
      titel: 'Deine besten Stunden',
      icon: Icons.wb_sunny_outlined,
      coach:
          'Aus deinem Schlaf, deinem Training und deinen Rückmeldungen. Danach '
          'lege ich die wichtige Arbeit.',
      inhalt: (ctx) => [
        _lebendig(() {
          final su = _schlafUmfeld;
          final en = su.energieHeute();
          final j = widget.clock();
          final b = _schlaf.d.besteZeit;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Block(
                label: 'Deine Kurve heute',
                rechts:
                    '${formatUhrzeit(en.hoch.$1 % 1440)} – ${formatUhrzeit(en.hoch.$2 % 1440)}',
                children: [
                  EnergieVorhersage(
                    werte: en.werte,
                    hoch: en.hoch,
                    jetzt: j.hour * 60 + j.minute,
                    training: _tagRahmen.training,
                  ),
                ],
              ),
              Block(
                label: 'So legt der Coach deinen Tag',
                children: [
                  _StundenZeile(
                    plus: true,
                    zeit:
                        '${formatUhrzeit(en.hoch.$1 % 1440)} – ${formatUhrzeit(en.hoch.$2 % 1440)}',
                    was: 'Wichtige Arbeit, Fokus-Block',
                  ),
                  _StundenZeile(
                    plus: false,
                    zeit: 'um ${formatUhrzeit(en.tief % 1440)}',
                    was: 'Leichte Sachen, kurz raus',
                  ),
                  if (_tagRahmen.training case final t?)
                    _StundenZeile(
                      plus: true,
                      zeit: formatUhrzeit(t),
                      was: 'Training',
                    ),
                ],
              ),
              if (b != null)
                Block(
                  art: GlasArt.gold,
                  children: [CoachZeile('${b.typ}. ${b.text}')],
                ),
              const SizedBox(height: 12),
              GlasKnopf(
                key: const ValueKey('stunden-tag'),
                label: 'Dein bester Tagesablauf',
                ghost: true,
                onTap: () => Navigator.of(ctx).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _lebendig(
                      () => TagesablaufSeite(umfeld: _schlafUmfeld),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
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
    BSerie serieAus(({int jetzt, int rekord}) x, String einheit, String text) =>
        BSerie(
          zahl: x.jetzt,
          einheit: einheit,
          text: x.jetzt == 0 ? 'Startet mit deinem nächsten Eintrag' : text,
          rekord: x.rekord,
        );
    final sFokus = serieTage([
      for (final x in d.fokus)
        if (x.erledigt) x.tag,
    ], jetzt);
    final serieFokus = serieAus(
      sFokus,
      sFokus.jetzt == 1 ? 'Tag' : 'Tage',
      'in Folge die eine Sache geschafft',
    );
    final sFrei = serieTage(d.handyfreiTage, jetzt);
    final geschafftP = <(String, String, String)>[
      for (final x in d.fokus)
        if (x.erledigt && x.tag.compareTo(montag) >= 0)
          ('Geschafft: ${x.text}', x.tag, 'b'),
      for (final t in d.handyfreiTage)
        if (t.compareTo(montag) >= 0) ('Handyfreier Morgen', t, 'a'),
    ]..sort((a, b) => '${b.$2}${b.$3}'.compareTo('${a.$2}${a.$3}'));
    final geschafftListe = [
      for (final g in geschafftP.take(4)) (g.$1, tagKurz(DateTime.parse(g.$2))),
    ];
    final fokusMin = fokusMinuten(d, heute);
    final fokusZiel = BNaechstes(
      titel: '50 Minuten im Fokus',
      anteil: fokusMin / 50,
      text: fokusMin >= 50
          ? '$fokusMin Minuten heute, geschafft.'
          : 'Noch ${50 - fokusMin} Minuten heute.',
    );
    final freiHeute = d.handyfreiTage.contains(heute);
    final aktivTage = aktiv?.tage.length ?? 0;

    final seiten = [
      BSeite(
        name: 'Heute',
        coach: f == null
            ? 'Was ist heute die eine Sache, die wirklich zählt?'
            : f.erledigt
            ? 'Die eine Sache ist geschafft. Der Rest darf leichter sein.'
            : '${name.isEmpty ? '' : '$name, '}heute zählt nur „${f.text}“. '
                  'Leg es in dein Hoch, $hoch.',
        bild: BBild(
          bau: (tipp, v, t) => FokusHeuteBild(
            sache: f?.text,
            erledigt: f?.erledigt ?? false,
            energie: e.werte,
            hoch: e.hoch,
            tief: e.tief,
            tiefText: 'Tief ${formatUhrzeit(e.tief % 1440)}',
            block: block,
            tipp: tipp,
            v: v,
            t: t,
          ),
          zahlen: [
            BZahl('$block Min', 'Fokus-Block', ziel: 'p-block'),
            BZahl(
              'bis ${formatUhrzeit(e.hoch.$2 % 1440)}',
              'hoch',
              ziel: 'p-energie',
            ),
            BZahl(
              f?.erledigt ?? false ? '1/1' : '0/1',
              'die eine Sache',
              ziel: 'p-fokus',
            ),
          ],
          knopf: ('Fokus-Block starten', 'p-block'),
          knopf2: (Icons.edit_outlined, 'p-fokus'),
        ),
        aufbau: BAufbau(
          dafuer: dafuer,
          jetzt: f == null
              ? const BJetzt(
                  titel: 'Was ist heute die eine Sache?',
                  text: 'Leg sie fest. Dann zählt heute nur sie.',
                  mitte: '0/1',
                  unter: 'eine Sache',
                  knopf: ('Eine Sache festlegen', 'p-fokus'),
                )
              : f.erledigt
              ? BJetzt(
                  fertig: true,
                  titel: stark,
                  text:
                      '„${f.text}“ ist geschafft. Der Rest darf leichter '
                      'sein.',
                  knopf: ('Fokus-Block starten', 'p-block'),
                )
              : BJetzt(
                  titel: 'Heute zählt: ${f.text}',
                  text: 'Leg es in dein Hoch, $hoch.',
                  ring: fokusMin / 50,
                  mitte: '$block',
                  unter: 'Min Block',
                  knopf: ('Fokus-Block starten', 'p-block'),
                ),
          serie: serieFokus,
          naechstes: fokusZiel,
          geschafft: geschafftListe,
        ),
        kacheln: [
          BKachel(
            id: 'p-fokus',
            titel: 'Fokus für heute',
            icon: Icons.center_focus_strong,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: f == null
                ? 'die eine Sache'
                : f.erledigt
                ? 'geschafft'
                : 'heute',
            text: f?.text ?? 'Was zählt heute wirklich?',
            unter: f == null
                ? 'eine Sache, mehr nicht'
                : 'in deinem Hoch, $hoch',
            feld: _pFeld(
              'Fokus für heute',
              Icons.center_focus_strong,
              'Eine Sache, die heute wirklich zählt. Alles andere darf warten.',
              (u) => FokusHeuteSeite(u: u),
            ),
          ),
          BKachel(
            id: 'p-block',
            titel: 'Fokus-Block',
            icon: Icons.timer_outlined,
            wert: '$block Min',
            unter: 'Länge nach deiner Energie',
            knopf: 'Starten',
            onKnopf: () => starteFokus(context, u, minuten: block),
            feld: _pFeld(
              'Fokus-Block',
              Icons.timer_outlined,
              block == 75
                  ? 'Deine Energie ist gerade sehr hoch, deshalb 75 Minuten.'
                  : block == 50
                  ? 'Deine Energie ist gerade gut, deshalb 50 Minuten.'
                  : 'Deine Energie ist gerade eher unten, deshalb 25 Minuten.',
              (u) => BlockSeite(u: u),
            ),
          ),
          BKachel(
            id: 'p-energie',
            titel: 'Energie heute',
            icon: Icons.bolt,
            text: 'Hoch bis ${formatUhrzeit(e.hoch.$2 % 1440)}',
            unter: 'Tief um ${formatUhrzeit(e.tief % 1440)}',
            feld: _feld(
              Bereich.schlaf,
              'energie',
              'Energie heute',
              Icons.bolt,
              'So sehe ich deinen Tag heute. Abends sagst du mir, wie er '
                  'wirklich war.',
            ),
          ),
        ],
      ),
      BSeite(
        name: 'Ziele',
        coach: h == null
            ? '${name.isEmpty ? 'W' : '$name, w'}elche eine Aktion bringt dich '
                  'diese Woche bei der Arbeit am weitesten?'
            : '${name.isEmpty ? '' : '$name, '}diese Woche zählt ein Hebel: '
                  '${h.text}.'
                  '${h.punkte.isEmpty ? '' : ' ${h.erledigt} von ${h.punkte.length} geschafft.'}',
        bild: BBild(
          bau: (tipp, v, t) => FokusZieleBild(
            hebel: h?.text,
            hebelFertig: hebelFertig,
            blaetter: blaetter,
            skill: bz.skill?.name,
            stufen: bz.skill?.stufen.length ?? 0,
            erreicht: bz.skill?.erreicht ?? 0,
            tipp: tipp,
            v: v,
            t: t,
          ),
          zahlen: [
            BZahl(
              ms.isEmpty ? '–' : '$erreicht/${ms.length}',
              'Meilensteine',
              ziel: 'b-baum',
            ),
            BZahl(
              bz.skill == null
                  ? '–'
                  : '${bz.skill!.erreicht}/${bz.skill!.stufen.length}',
              'Skill-Stufe',
              ziel: 'b-skill',
            ),
            BZahl(
              h == null || h.punkte.isEmpty
                  ? '–'
                  : '${h.erledigt}/${h.punkte.length}',
              'Hebel',
              ziel: 'b-hebel',
            ),
          ],
          knopf: ('Meilenstein eintragen', 'b-baum'),
          knopf2: (Icons.add, 'b-hebel'),
        ),
        aufbau: BAufbau(
          dafuer: dafuer,
          jetzt: h == null
              ? const BJetzt(
                  titel: 'Dein Hebel der Woche',
                  text: 'Welche eine Aktion bringt dich am weitesten?',
                  mitte: '–',
                  unter: 'Hebel',
                  knopf: ('Hebel festlegen', 'b-hebel'),
                )
              : hebelFertig
              ? BJetzt(
                  fertig: true,
                  titel: stark,
                  text: 'Hebel der Woche geschafft: ${h.text}.',
                  knopf: ('Meilenstein eintragen', 'b-baum'),
                )
              : BJetzt(
                  titel: 'Dein Hebel: ${h.text}',
                  text: h.punkte.isEmpty
                      ? 'Das ist diese Woche die eine Aktion.'
                      : '${h.erledigt} von ${h.punkte.length} Schritten '
                            'geschafft.',
                  ring: h.punkte.isEmpty ? null : h.erledigt / h.punkte.length,
                  mitte: h.punkte.isEmpty
                      ? '–'
                      : '${h.erledigt}/${h.punkte.length}',
                  unter: 'Hebel',
                  knopf: ('Hebel öffnen', 'b-hebel'),
                ),
          serie: serieFokus,
          naechstes: astText == null
              ? BNaechstes(
                  titel: ms.isEmpty ? 'Erster Meilenstein' : 'Alle erreicht',
                  anteil: ms.isEmpty ? 0 : 1,
                  text: ms.isEmpty
                      ? 'Trag ein, wo du hinwillst.'
                      : '$erreicht von ${ms.length} Meilensteinen.',
                )
              : BNaechstes(
                  titel: astText,
                  anteil: astAnt ?? erreicht / ms.length,
                  text: '$erreicht von ${ms.length} Meilensteinen erreicht.',
                ),
          geschafft: geschafftListe,
        ),
        kacheln: [
          BKachel(
            id: 'b-hebel',
            titel: 'Hebel der Woche',
            icon: Icons.trending_up,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: h == null ? 'diese Woche' : 'bis Sonntag',
            text: h?.text ?? 'Was bringt dich diese Woche am weitesten?',
            unter: h == null
                ? 'für Job, Studium oder eigene Firma'
                : '${h.erledigt} von ${h.punkte.length} erledigt'
                      '${h.tipps.isEmpty ? '' : ' · ${h.tipps.length} Tipps vom Coach'}',
            feld: _bFeld(
              'Hebel der Woche',
              Icons.trending_up,
              'Eine Aktion, die dich diese Woche bei der Arbeit am meisten '
                  'voranbringt. Dazu Tipps, auf die man allein nicht kommt.',
              (u) => HebelSeite(u: u),
            ),
          ),
          BKachel(
            id: 'b-baum',
            titel: 'Dein Weg zum Ziel',
            icon: Icons.park_outlined,
            groesse: KachelGroesse.mittel,
            hot: erreicht == 0
                ? null
                : '$erreicht ${erreicht == 1 ? 'Ast' : 'Äste'}',
            bild: bz.meilensteine.isEmpty
                ? null
                : SizedBox(
                    width: 110,
                    child: BusinessBaum(meilensteine: bz.meilensteine),
                  ),
            text: astText ?? 'Dein erster Meilenstein?',
            unter: astText == null
                ? 'jeder Meilenstein ein Ast'
                : astAnt == null
                ? 'nächster Ast'
                : 'nächster Ast · ${(astAnt * 100).round()} %',
            feld: _bFeld(
              'Dein Weg zum Ziel',
              Icons.park_outlined,
              'Jeder Meilenstein ist ein Ast, egal ob Prüfung, Beförderung '
                  'oder erste Kunden. So siehst du, wie du vorankommst.',
              (u) => BaumSeite(u: u),
            ),
          ),
          // The skill ladder of the picture opens here.
          BKachel(
            id: 'b-skill',
            titel: 'Dein Skill',
            icon: Icons.stairs_outlined,
            groesse: KachelGroesse.schmal,
            feld: _bFeld(
              'Dein Skill',
              Icons.stairs_outlined,
              'Ein Skill, Stufe für Stufe. Jede Stufe eine Aufgabe für die '
                  'Woche.',
              (u) => SkillSeite(u: u),
            ),
          ),
        ],
      ),
      BSeite(
        name: 'Handy',
        coach: stunde == null
            ? 'Tipp den Drang-Knopf, wenn du zum Handy greifen willst. Mehr '
                  'musst du nicht tun.'
            : 'Der Griff zum Handy kommt meist zwischen $stunde.',
        bild: BBild(
          bau: (tipp, v, t) => HandyBild(
            n: drangHeute,
            gruende: gruende,
            frei: freiMin <= 0
                ? null
                : (
                    0.0,
                    (freiMin / math.max(60, tagBis - tagVon)).clamp(0.0, 1.0),
                  ),
            freiLinks: '${kurz(tagVon)}–${kurz(tagVon + freiMin)} Uhr',
            freiRechts: '$frei7 von 7 Morgen',
            onDrang: () async {
              final pd = _produktiv.d;
              await _produktiv.setze(
                pd.copyWith(
                  drang: [
                    ...pd.drang,
                    Drang(zeit: widget.clock()),
                  ],
                ),
              );
            },
            tipp: tipp,
            v: v,
            t: t,
          ),
          zahlen: [
            BZahl('$drangHeute×', 'heute', ziel: 'p-drang'),
            BZahl(
              drangHeute == drangGestern
                  ? '±0'
                  : '${drangHeute < drangGestern ? '−' : '+'}${(drangHeute - drangGestern).abs()}',
              'vs. gestern',
              ziel: 'p-drang',
            ),
            BZahl(minText(freiMin), 'handyfrei', ziel: 'p-handyfrei'),
          ],
          knopf: ('Handyfreie Zeit festlegen', 'p-handyfrei'),
          knopf2: (Icons.lightbulb_outline, 'p-frei'),
        ),
        aufbau: BAufbau(
          dafuer: dafuer,
          jetzt: freiMin <= 0
              ? const BJetzt(
                  titel: 'Leg deine handyfreie Zeit fest',
                  text: 'Der Morgen ohne Handy gehört dir.',
                  mitte: '–',
                  unter: 'handyfrei',
                  knopf: ('Handyfreie Zeit festlegen', 'p-handyfrei'),
                )
              : freiHeute
              ? BJetzt(
                  fertig: true,
                  titel: stark,
                  text:
                      'Handyfreier Morgen geschafft. $frei7 von 7 in dieser '
                      'Woche.',
                  knopf: ('Handyfreie Zeit ansehen', 'p-handyfrei'),
                )
              : BJetzt(
                  titel: 'Dein Morgen ohne Handy',
                  text:
                      '${minText(freiMin)} nach dem Aufstehen. $frei7 von 7 '
                      'Morgen geschafft.',
                  ring: frei7 / 7,
                  mitte: '$frei7/7',
                  unter: 'Morgen',
                  knopf: ('Handyfreie Zeit öffnen', 'p-handyfrei'),
                ),
          serie: serieAus(sFrei, 'Morgen', 'in Folge ohne Handy gestartet'),
          naechstes: BNaechstes(
            titel: '7 handyfreie Morgen',
            anteil: frei7 / 7,
            text: frei7 >= 7
                ? 'Alle 7 geschafft.'
                : 'Noch ${7 - frei7} in den letzten 7 Tagen.',
          ),
          geschafft: geschafftListe,
        ),
        kacheln: [
          BKachel(
            id: 'p-spiegel',
            titel: 'Handy-Spiegel',
            icon: Icons.phone_iphone,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: bild != null && bildGestern != null
                ? '${bild <= bildGestern ? '−' : '+'}${(bild - bildGestern).abs()} Min'
                : null,
            wert: bild == null ? 'Eintragen' : stundenText(bild),
            unter: stunde == null
                ? 'Bildschirmzeit heute'
                : 'Unruhe meist $stunde',
            feld: _pFeld(
              'Handy-Spiegel',
              Icons.phone_iphone,
              'Wie viel Zeit das Handy bekommt und wann es dich packt.',
              (u) => SpiegelSeite(u: u),
            ),
          ),
          BKachel(
            id: 'p-drang',
            titel: 'Ablenkung',
            icon: Icons.touch_app_outlined,
            bild: DrangKnopf(
              n: drangHeute,
              onTap: () async {
                final pd = _produktiv.d;
                await _produktiv.setze(
                  pd.copyWith(
                    drang: [
                      ...pd.drang,
                      Drang(zeit: widget.clock()),
                    ],
                  ),
                );
              },
            ),
            unter: '$drangHeute× heute getippt',
            feld: _pFeld(
              'Ablenkung',
              Icons.touch_app_outlined,
              'Du musst nicht widerstehen, nur tippen. Ich sehe mit der Zeit, '
                  'wann und warum.',
              (u) => DrangSeite(u: u),
            ),
          ),
          BKachel(
            id: 'p-frei',
            titel: 'Handyfrei',
            icon: Icons.phonelink_erase,
            text: handyfreiText(u.aufstehen, d.handyfreiMinuten),
            unter: 'nach dem Aufstehen · $frei7 von 7',
            knopf: 'Fokus-Knopf',
            onKnopf: () => starteFokus(context, u, minuten: 30, knopf: true),
            feld: _pFeld(
              'Handyfrei',
              Icons.phonelink_erase,
              'Der Morgen gehört dir, nicht dem Handy.',
              (u) => HandyfreiSeite(u: u),
            ),
          ),
          // The same page without the focus button, for the picture.
          BKachel(
            id: 'p-handyfrei',
            titel: 'Handyfrei',
            icon: Icons.phonelink_erase,
            feld: _pFeld(
              'Handyfrei',
              Icons.phonelink_erase,
              'Der Morgen gehört dir, nicht dem Handy.',
              (u) => HandyfreiSeite(u: u),
            ),
          ),
        ],
      ),
      BSeite(
        name: 'Rhythmus',
        coach:
            'Am klarsten bist du heute von $hoch. Das Schwere gehört dorthin, '
            'nicht in den Abend.',
        bild: BBild(
          bau: (tipp, v, t) => RhythmusBild(
            von: tagVon,
            bis: tagBis,
            hoch: e.hoch,
            tief: e.tief,
            training: _tagRahmen.training,
            vonText: formatUhrzeit(tagVon % 1440),
            bisText: formatUhrzeit(tagBis % 1440),
            hochText: '${kurz(e.hoch.$1)}–${kurz(e.hoch.$2)}',
            geber: [
              for (final m in [...gibt.take(2), ...nimmt.take(1)])
                (text: m.text, gut: m.gut),
            ],
            tipp: tipp,
            v: v,
            t: t,
          ),
          zahlen: [
            BZahl(
              '${kurz(e.hoch.$1)}–${kurz(e.hoch.$2)}',
              'beste Zeit',
              ziel: 'p-stunden',
            ),
            BZahl(formatUhrzeit(e.tief % 1440), 'Tief', ziel: 'p-stunden'),
            BZahl('${gibt.length}', 'Geber', ziel: 'p-geber'),
          ],
          knopf: ('Tag danach planen', 'p-stunden'),
          knopf2: (Icons.add, 'p-geber'),
        ),
        aufbau: BAufbau(
          dafuer: dafuer,
          jetzt: BJetzt(
            titel: 'Das Schwere in dein Hoch',
            text: 'Heute bist du von $hoch am klarsten.',
            mitte: '${kurz(e.hoch.$1)}–${kurz(e.hoch.$2)}',
            unter: 'Uhr',
            knopf: ('Tag danach planen', 'p-stunden'),
          ),
          serie: serieFokus,
          naechstes: fokusZiel,
          geschafft: geschafftListe,
        ),
        kacheln: [
          BKachel(
            id: 'p-stunden',
            titel: 'Deine besten Stunden',
            icon: Icons.wb_sunny_outlined,
            groesse: KachelGroesse.mittel,
            gold: true,
            hot: hoch,
            text: 'Wichtige Arbeit liegt dort',
            unter: _tagRahmen.training == null
                ? 'Leichtes ins Tief um ${formatUhrzeit(e.tief % 1440)}'
                : 'Training ${formatUhrzeit(_tagRahmen.training!)}',
            feld: stundenF,
          ),
          BKachel(
            id: 'p-geber',
            titel: 'Geber & Räuber',
            icon: Icons.swap_vert,
            text: gibt.isEmpty && nimmt.isEmpty
                ? 'Kommt nach 14 Morgen'
                : [
                    if (gibt.isNotEmpty) '+ ${gibt.first.text}',
                    if (nimmt.isNotEmpty) '− ${nimmt.first.text}',
                  ].join('\n'),
            seite: (_) =>
                _lebendig(() => SchlafMusterSeite(umfeld: _schlafUmfeld)),
          ),
          BKachel(
            id: 'p-verlauf',
            titel: 'Verlauf',
            icon: Icons.show_chart,
            wert: schnitt == null ? '–' : 'Ø $schnitt',
            unter: 'letzte 30 Tage',
            feld: verlaufF,
          ),
        ],
      ),
      BSeite(
        name: 'Routinen',
        coach: aktiv == null
            ? 'Dock eine neue Gewohnheit an etwas an, das du sowieso machst.'
            : '„${aktiv.neu}“ hält seit ${aktiv.tage.length} Tagen. Die '
                  'nächste kommt erst, wenn sie von allein läuft.',
        bild: BBild(
          bau: (tipp, v, t) => RoutinenBild(
            ketten: [
              for (final a in glieder)
                (
                  anker: a.anker,
                  neu: a.neu,
                  unter: a.laeuft
                      ? 'seit ${a.tage.length} Tagen'
                      : 'Tag ${a.tage.length}/21',
                  heute: a.tage.contains(heute),
                  aktiv: identical(a, aktiv),
                ),
            ],
            laeuftText: laeuft.isEmpty
                ? 'Nach 21 Tagen läuft eine Gewohnheit von allein'
                : 'Läuft von allein: ${laeuft.map((a) => a.neu).join(', ')}',
            tipp: tipp,
            v: v,
            t: t,
          ),
          zahlen: [
            BZahl('${d.andocken.length}', 'angedockt', ziel: 'p-andock'),
            BZahl('$stueck', 'Tage am Stück', ziel: 'p-andock'),
            BZahl('${laeuft.length}', 'laufen allein', ziel: 'p-laeuft'),
          ],
          knopf: ('Gewohnheit andocken', 'p-neu'),
          knopf2: (Icons.add, 'p-andock'),
        ),
        aufbau: BAufbau(
          dafuer: dafuer,
          jetzt: aktiv == null
              ? const BJetzt(
                  titel: 'Dock eine Gewohnheit an',
                  text: 'An etwas, das du sowieso jeden Tag machst.',
                  mitte: '0/21',
                  unter: 'Tage',
                  knopf: ('Gewohnheit andocken', 'p-neu'),
                )
              : aktiv.tage.contains(heute)
              ? BJetzt(
                  fertig: true,
                  titel: stark,
                  text:
                      '„${aktiv.neu}“ ist für heute erledigt. Tag '
                      '$aktivTage von 21.',
                  knopf: ('Routinen ansehen', 'p-andock'),
                )
              : BJetzt(
                  titel: aktiv.neu,
                  text: 'Direkt nach: ${aktiv.anker}. Tag $aktivTage von 21.',
                  ring: aktivTage / 21,
                  mitte: '$aktivTage/21',
                  unter: 'Tage',
                  knopf: ('Heute abhaken', 'p-andock'),
                ),
          serie: BSerie(
            zahl: stueck,
            einheit: stueck == 1 ? 'Tag' : 'Tage',
            text: stueck == 0
                ? 'Startet mit deinem nächsten Eintrag'
                : 'am Stück bei deiner Gewohnheit',
          ),
          naechstes: aktiv == null
              ? const BNaechstes(
                  titel: 'Erste Gewohnheit',
                  anteil: 0,
                  text: 'Nach 21 Tagen läuft sie von allein.',
                )
              : BNaechstes(
                  titel: 'Läuft von allein',
                  anteil: aktivTage / 21,
                  text:
                      'Noch ${math.max(0, 21 - aktivTage)} Tage, dann kommt '
                      'die nächste.',
                ),
          geschafft: geschafftListe,
        ),
        kacheln: [
          BKachel(
            id: 'p-andock',
            titel: 'Gewohnheit andocken',
            icon: Icons.link,
            groesse: KachelGroesse.hoch,
            gold: true,
            hot: aktiv == null ? null : 'Tag ${aktiv.tage.length}',
            text: aktiv == null ? 'Noch keine angedockt' : null,
            bild: aktiv == null
                ? null
                : SizedBox(
                    width: 260,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Kette(anker: aktiv.anker, neu: aktiv.neu, klein: true),
                        const SizedBox(height: 10),
                        EinundzwanzigPunkte(n: aktiv.tage.length, klein: true),
                      ],
                    ),
                  ),
            unter: aktiv == null
                ? 'an etwas, das du sowieso machst'
                : 'noch ${21 - aktiv.tage.length} Tage, dann läuft sie von '
                      'allein',
            feld: _pFeld(
              'Gewohnheit andocken',
              Icons.link,
              'Eine Gewohnheit nach der anderen, jede an etwas, das du sowieso '
                  'machst.',
              (u) => AndockSeite(u: u),
            ),
          ),
          BKachel(
            id: 'p-neu',
            titel: 'Neue andocken',
            icon: Icons.add_link,
            text: 'Woran willst du sie hängen?',
            unter: 'Wenn ich …, dann …',
            feld: _pFeld(
              'Neue andocken',
              Icons.add_link,
              'Woran willst du die neue Gewohnheit hängen?',
              (u) => NeuAndockSeite(u: u),
            ),
          ),
          BKachel(
            id: 'p-laeuft',
            titel: 'Läuft von allein',
            icon: Icons.all_inclusive,
            wert: '${laeuft.length}',
            unter: laeuft.isEmpty
                ? 'nach 21 Tagen'
                : laeuft.map((a) => a.neu).join(' · '),
            feld: _pFeld(
              'Läuft von allein',
              Icons.all_inclusive,
              'Diese Gewohnheiten brauchen keinen Anker mehr.',
              (u) => LaeuftSeite(u: u),
            ),
          ),
        ],
      ),
    ];

    return BereichSeite(
      key: const ValueKey('produktiv-seite'),
      name: 'Fokus & Arbeit',
      wert: wert,
      teile: [
        Unterbereich(
          id: 'produktiv',
          name: 'Fokus & Arbeit',
          icon: Icons.bolt,
          wert: wert,
          woche: [
            for (var i = 6; i >= 0; i--) _pw(jetzt.subtract(Duration(days: i))),
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
            'Alles zu Fokus, Energie und Arbeit. Ich kenne deinen Schlaf, dein '
            'Training, deinen Tag und deinen Hebel.',
        inhalt: (_) => [
          _lebendig(
            () => AskCoachCard(
              title: 'Wobei verlierst du gerade deinen Fokus?',
              hint: 'Schreib, was dich ablenkt oder bremst.',
              today: _todayFragen(Bereich.schlaf),
              onSend: _ask(Bereich.schlaf),
            ),
          ),
        ],
      ),
    );
  }
}

class _StundenZeile extends StatelessWidget {
  const _StundenZeile({
    required this.plus,
    required this.zeit,
    required this.was,
  });
  final bool plus;
  final String zeit;
  final String was;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: plus ? CoachStyle.goldGradient : null,
            border: plus ? null : Border.all(color: const Color(0x44FFEECD)),
          ),
          child: Text(
            plus ? '+' : '–',
            style: Glas.tLabel.copyWith(
              color: plus ? CoachStyle.goldInk : Glas.label,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(zeit, style: Glas.tText.copyWith(fontSize: 14.5)),
              Text(was, style: Glas.tSoft),
            ],
          ),
        ),
      ],
    ),
  );
}
