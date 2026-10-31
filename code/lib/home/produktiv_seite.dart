part of 'home_page.dart';

/// Produktivität & Fokus: Heute, Handy, Rhythmus, Gewohnheiten (vault
/// Umsetzung/Produktivität und Fokus komplett, Phillip 2026-10-29 16:36).
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
    final verlauf = _verlauf(_pw, jetzt);
    final da = [for (final v in verlauf) ?v];
    final schnitt = da.isEmpty
        ? null
        : (da.reduce((a, b) => a + b) / da.length).round();

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

    final seiten = [
      BSeite(
        name: 'Heute',
        coach: f == null
            ? 'Was ist heute die eine Sache, die wirklich zählt?'
            : f.erledigt
            ? 'Die eine Sache ist geschafft. Der Rest darf leichter sein.'
            : '${name.isEmpty ? '' : '$name, '}heute zählt nur „${f.text}“. '
                  'Leg es in dein Hoch, $hoch.',
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
        name: 'Handy',
        coach: stunde == null
            ? 'Tipp den Drang-Knopf, wenn du zum Handy greifen willst. Mehr '
                  'musst du nicht tun.'
            : 'Der Griff zum Handy kommt meist zwischen $stunde.',
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
        ],
      ),
      BSeite(
        name: 'Rhythmus',
        coach:
            'Am klarsten bist du heute von $hoch. Das Schwere gehört dorthin, '
            'nicht in den Abend.',
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
      name: 'Produktivität & Fokus',
      wert: wert,
      teile: [
        Unterbereich(
          id: 'produktiv',
          name: 'Produktivität',
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
            'Alles zu Fokus und Energie. Ich kenne deinen Schlaf, dein Training '
            'und deinen Tag.',
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
