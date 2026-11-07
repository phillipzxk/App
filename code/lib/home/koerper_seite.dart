part of 'home_page.dart';

/// Körper: Training, Ernährung and Schlaf & Routine switch directly at the
/// top, each with its four pages and everything already built (vault
/// Umsetzung/Körper komplett, Entwurf 3, Phillip "Passt" 2026-10-29).
extension _Koerper on _HomePageState {
  static const _teile = [Bereich.training, Bereich.ernaehrung, Bereich.schlaf];

  Widget _koerperSeite(Bereich start) {
    final werte = [for (final b in _teile) _wert(b).$1];
    final da = [for (final w in werte) ?w];
    final koerper = da.isEmpty
        ? null
        : (da.reduce((a, b) => a + b) / da.length).round();
    return BereichSeite(
      key: const ValueKey('koerper-seite'),
      name: 'Körper',
      wert: koerper,
      start: _teile.indexOf(start).clamp(0, 2),
      teile: [_teilTraining(), _teilErnaehrung(), _teilSchlaf()],
      verlauf: _koerperVerlauf(),
      frag: _frag,
    );
  }

  /// Under the Körper ring: what the number is and how it moved, the
  /// values of the three parts are in the bar below.
  String _koerperZeile() {
    final heute = <int>[], gestern = <int>[];
    for (final b in _teile) {
      final (w, d) = _wert(b);
      if (w == null) continue;
      heute.add(w);
      if (d != null) gestern.add(w - d);
    }
    if (heute.isEmpty) return 'Heute noch kein Wert, erst nach dem Check-in';
    int schnitt(List<int> l) => (l.reduce((a, b) => a + b) / l.length).round();
    if (gestern.length != heute.length) return 'Schnitt aus allen drei';
    final d = schnitt(heute) - schnitt(gestern);
    final diff = d == 0
        ? 'gleich wie gestern'
        : '${d > 0 ? '+' : '−'}${d.abs()} zu gestern';
    return 'Schnitt aus allen drei · $diff';
  }

  String _subZeile(Bereich b) {
    final (w, d) = _wert(b);
    if (w == null) return 'Heute noch kein Wert, erst nach dem Check-in';
    final diff = d == null
        ? ''
        : d == 0
        ? 'gleich wie gestern'
        : '${d > 0 ? '+' : '−'}${d.abs()} zu gestern';
    return diff.isEmpty ? '$w von 10' : diff;
  }

  /// "Plan anlegen" opens the plan straight away, without the page in
  /// between (Rundgang 2026-10-31).
  Widget _planAnlegen(BuildContext _) => TrainingPlanEditor(
    plan: _plan,
    sportarten: _training.sportarten,
    schwerpunkt: _schwerpunkt,
    startTag: widget.clock().weekday - 1,
    onFertig: (r) async {
      await widget.feed.saveTraining(
        _training.copyWith(sportarten: r.sportarten),
      );
      if (r.schwerpunkt case final sp?) {
        await widget.feed.saveSchwerpunkt(sp);
      }
      await widget.feed.savePlan(r.plan);
      await _reload();
    },
  );

  String _coach(Bereich b, String sonst) {
    final g = _heute?.gruende[b.name]?.trim() ?? '';
    return g.isEmpty ? sonst : g;
  }

  List<int?> _woche7(Bereich b) =>
      werteVerlauf(_checkIns, b, widget.clock(), 7);

  /// A tile page with one part of an existing area page in it.
  Feld _feld(
    Bereich b,
    String teil,
    String titel,
    IconData icon,
    String coach,
  ) => Feld(
    titel: titel,
    icon: icon,
    coach: coach,
    inhalt: (_) => [_lebendig(() => _seite(b, teil: teil))],
  );

  Feld _frag(Unterbereich t) {
    final b = Bereich.values.byName(t.id);
    final (titel, hint) = switch (b) {
      Bereich.training => (
        'Wie war dein Training?',
        'Was hast du geschafft, was nicht, und warum? Der Coach sieht auch '
            'deine Einträge.',
      ),
      Bereich.ernaehrung => (
        'Wie sieht deine Ernährung heute aus?',
        'Schreib grob, was du heute gegessen hast. Der Coach schätzt ein, ob '
            'es zu deinem Ziel passt.',
      ),
      _ => ('Frag zu deinem Schlaf', 'Was stört dich gerade beim Schlafen?'),
    };
    return Feld(
      titel: 'Frag den Coach',
      icon: Icons.chat_bubble_outline,
      coach:
          'Alles zu ${t.name}. Ich kenne deinen Plan, deine Check-ins und '
          'deine Muster.',
      inhalt: (_) => [
        _lebendig(
          () => AskCoachCard(
            title: titel,
            hint: hint,
            today: _todayFragen(b),
            onSend: _ask(b),
          ),
        ),
      ],
    );
  }

  /// Behind the Körper ring: everything together (the old Verlauf page).
  Feld _koerperVerlauf() => Feld(
    titel: 'Körper im Verlauf',
    icon: Icons.show_chart,
    coach:
        'Training, Ernährung und Schlaf zusammen. Die gestrichelte Linie ist '
        'jeweils dein Schnitt.',
    inhalt: (_) => [
      _lebendig(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final b in _teile) AreaChart(bereich: b),
            if (_essen.d.zusammenhang?.satz case final z?)
              GlasBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hängt zusammen', style: Glas.tLabel),
                    const SizedBox(height: 6),
                    Text(z, style: Glas.tText),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FutureMeCard(
              today: widget.clock(),
              einstellungen: _fotoEinstellungen,
              fotos: _wochenFotos,
              onOpen: _oeffneZukunft,
            ),
          ],
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------- Training

  /// Sets and target of a planned exercise, e.g. "4×8 · 62,5 kg".
  static String _zielText(PlanUebung u) {
    final wdh = u.modus == WdhModus.rir
        ? 'bis kurz vor Schluss'
        : u.wdhVon == u.wdhBis || u.modus == WdhModus.fest
        ? '${u.wdhVon}'
        : '${u.wdhVon}-${u.wdhBis}';
    final einheit = switch (u.art) {
      UebungArt.gewicht || UebungArt.zusatzgewicht => ' kg',
      UebungArt.zeit => ' s',
      UebungArt.strecke => ' km',
      UebungArt.koerpergewicht => '',
    };
    final w = u.wert;
    return '${u.saetze}×$wdh${w == null || einheit.isEmpty ? '' : ' · ${_zahl1(w)}$einheit'}';
  }

  /// The best value of each logged session of one exercise.
  List<double> _bestwerte(String name) => [
    for (final (_, log) in _training.verlauf(name))
      if (log.saetze.where((x) => x.fertig && x.wert != null).isNotEmpty)
        log.saetze
            .where((x) => x.fertig && x.wert != null)
            .map((x) => x.wert!)
            .reduce(math.max),
  ];

  Unterbereich _teilTraining() {
    const b = Bereich.training;
    final today = widget.clock();
    final tag = _woche.forDay(today);
    final name = shortDay(tag);
    final heuteIndex = today.weekday - 1;
    final planHeute = _woche.uebungenAm(heuteIndex);
    final uebungen = [
      for (final l in dayDetails(tag).split('\n'))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    final frei = name == 'frei';
    final einheit = _training.einheitAm(today);
    final fertig = einheit?.status == EinheitStatus.fertig;
    bool erledigt(String n) =>
        fertig ||
        (einheit?.uebungen.any(
              (x) =>
                  x.name.toLowerCase() == n.toLowerCase() &&
                  x.saetze.any((s) => s.fertig),
            ) ??
            false);
    final heuteListe = <HeuteUebung>[
      if (planHeute.isNotEmpty)
        for (final u in planHeute)
          (name: u.name, ziel: _zielText(u), fertig: erledigt(u.name))
      else
        for (final l in uebungen) (name: l, ziel: '', fertig: erledigt(l)),
    ];
    final woche = _trainingsWoche();
    final gemacht = woche.where((x) => x == true).length;
    final geplant = woche.where((x) => x != null).length;
    final stag = stagnationFaellig(_training, planUebungen(_plan), today);
    final alle = planUebungen(_plan);
    final sport = _training.sportarten;
    final planTage = _plan.tage.where((t) => t.trim().isNotEmpty).length;
    final mitVerlauf = [
      for (final n in {..._training.geloggteUebungen, ...alle})
        if (_bestwerte(n).isNotEmpty) n,
    ];
    final zeigeUebung = mitVerlauf.isNotEmpty
        ? mitVerlauf.first
        : (alle.isEmpty ? null : alle.first);
    final werte = zeigeUebung == null
        ? const <double>[]
        : _bestwerte(zeigeUebung);
    final rekord = werte.isEmpty ? null : werte.reduce(math.max);
    final art = zeigeUebung == null
        ? null
        : planUebung(_plan, zeigeUebung)?.art;
    final kg =
        art == null ||
        art == UebungArt.gewicht ||
        art == UebungArt.zusatzgewicht;
    Feld f(String teil, String titel, IconData icon, String coach) =>
        _feld(b, teil, titel, icon, coach);
    final heute = f(
      'heute',
      'Training heute',
      Icons.fitness_center,
      'Die Felder sind schon mit dem Ziel ausgefüllt. Du änderst nur, was '
          'anders war.',
    );
    final wocheF = f(
      'woche',
      'Deine Woche',
      Icons.calendar_today,
      'Kommt ein Termin dazu, schiebe ich die Einheit und sage dir warum.',
    );
    final planF = f(
      'plan',
      'Dein Plan',
      Icons.list_alt,
      'Einmal angelegt, läuft er von selbst weiter.',
    );
    final verlaufF = f(
      'uebungen',
      'Übungen im Verlauf',
      Icons.trending_up,
      'Kurve, Rekorde und Form-Videos pro Übung.',
    );
    final wochenTage = <WochenTag>[
      for (var i = 0; i < 7; i++)
        (
          tag: 'MDMDFSS'[i],
          name: shortDay(_woche.tage[i]),
          fertig: woche[i],
          heute: i == heuteIndex,
        ),
    ];
    final leer = _plan.isEmpty
        ? (
            label: 'NOCH KEIN PLAN',
            titel: 'Plan anlegen',
            unter: 'einmal festlegen, dann läuft er',
          )
        : frei
        ? (
            label: 'HEUTE FREI',
            titel: 'Erholung zählt mit',
            unter: woche.contains(false)
                ? 'diese Woche noch ${geplant - gemacht} offen'
                : 'morgen geht es weiter',
          )
        : null;
    return Unterbereich(
      id: b.name,
      name: 'Training',
      icon: Icons.fitness_center,
      wert: _wert(b).$1,
      woche: _woche7(b),
      sub: _koerperZeile(),
      seiten: [
        BSeite(
          name: 'Heute',
          coach: _coach(
            b,
            frei
                ? 'Heute ist frei. Erholung gehört zum Training.'
                : fertig
                ? 'Heute $name geschafft. Stark durchgezogen.'
                : 'Heute $name. Die Ziele sind schon eingetragen.',
          ),
          bild: BBild(
            bau: (tipp, v, t) => TrainingHeuteBild(
              uebungen: heuteListe,
              leer: leer,
              tipp: tipp,
              v: v,
              t: t,
            ),
            zahlen: [
              BZahl(leer != null ? '–' : '${heuteListe.length}', 'Übungen'),
              BZahl(frei ? 'frei' : name, 'heute'),
              BZahl(
                geplant == 0 ? '$gemacht' : '$gemacht/$geplant',
                'diese Woche',
              ),
            ],
            knopf: _plan.isEmpty
                ? ('Plan anlegen', 't-heute')
                : frei
                ? ('Training ansehen', 't-heute')
                : fertig
                ? ('Training ansehen', 't-heute')
                : ('Training starten', 't-modus'),
            knopf2: _plan.isEmpty || frei
                ? null
                : (Icons.videocam_outlined, 't-form'),
          ),
          kacheln: [
            BKachel(
              id: 't-heute',
              titel: frei ? 'Heute' : 'Heute · $name',
              icon: Icons.fitness_center,
              feld: _plan.isEmpty ? null : heute,
              seite: _plan.isEmpty ? _planAnlegen : null,
            ),
            BKachel(
              id: 't-modus',
              titel: 'Trainings-Modus',
              icon: Icons.crop_portrait,
              feld: heute,
            ),
            BKachel(
              id: 't-form',
              titel: 'Form filmen',
              icon: Icons.videocam_outlined,
              feld: heute,
            ),
          ],
        ),
        BSeite(
          name: 'Woche',
          coach: stag != null
              ? '$stag Tipp unten auf Stagnation, dann schauen wir zusammen.'
              : geplant == 0
              ? 'Leg einmal deinen Plan an. Dann siehst du hier deine Woche.'
              : '$gemacht von $geplant geschafft. Verschiebt sich etwas, sage '
                    'ich dir warum.',
          bild: BBild(
            bau: (tipp, v, t) =>
                TrainingWocheBild(tage: wochenTage, tipp: tipp, v: v, t: t),
            zahlen: [
              BZahl(
                geplant == 0 ? '$gemacht' : '$gemacht/$geplant',
                'Einheiten',
              ),
              BZahl(
                sport.isEmpty ? '–' : sport.first,
                sport.length > 1 ? '+ ${sport.length - 1} mehr' : 'Sportart',
                ziel: 't-balance',
              ),
              BZahl(
                stag == null ? 'keine' : 'prüfen',
                'Stagnation',
                ziel: 't-stag',
              ),
            ],
            knopf: (_plan.isEmpty ? 'Plan anlegen' : 'Plan ändern', 't-plan'),
            knopf2: (Icons.sports_gymnastics, 't-sport'),
          ),
          kacheln: [
            BKachel(
              id: 't-woche',
              titel: 'Woche',
              icon: Icons.calendar_today,
              feld: wocheF,
            ),
            BKachel(
              id: 't-balance',
              titel: 'Hybrid-Balance',
              icon: Icons.balance,
              feld: wocheF,
            ),
            BKachel(
              id: 't-stag',
              titel: 'Stagnation',
              icon: Icons.timeline,
              feld: wocheF,
            ),
            BKachel(
              id: 't-plan',
              titel: 'Dein Plan',
              icon: Icons.list_alt,
              wert: _plan.isEmpty ? 'Anlegen' : '$planTage Tage',
              feld: _plan.isEmpty ? null : planF,
              seite: _plan.isEmpty ? _planAnlegen : null,
            ),
            BKachel(
              id: 't-sport',
              titel: 'Sportarten',
              icon: Icons.sports,
              feld: _plan.isEmpty ? null : planF,
              seite: _plan.isEmpty ? _planAnlegen : null,
            ),
          ],
        ),
        BSeite(
          name: 'Fortschritt',
          coach: werte.length >= 2 && rekord != null
              ? '${zeigeUebung!}: ${werte.last >= rekord ? 'neuer Bestwert' : 'Bestwert ${_zahl1(rekord)}${kg ? ' kg' : ''}'}. '
                    'Was schlägst du als nächstes Ziel vor?'
              : 'Jede Übung bekommt ihre Kurve. Jeder Rekord lässt einen '
                    'goldenen Trieb wachsen.',
          bild: BBild(
            bau: (tipp, v, t) => TrainingVerlaufBild(
              uebungen: [
                ?zeigeUebung,
                for (final n in alle)
                  if (n != zeigeUebung) n,
              ].take(3).toList(),
              werte: werte,
              einheit: kg ? 'kg' : '',
              videos: 0,
              tipp: tipp,
              v: v,
              t: t,
            ),
            zahlen: [
              BZahl(
                rekord == null ? '–' : _zahl1(rekord),
                kg ? 'Rekord kg' : 'Rekord',
                ziel: 't-rekorde',
              ),
              BZahl(
                werte.length < 2
                    ? '–'
                    : '${werte.last - werte.first >= 0 ? '+' : '−'}${_zahl1((werte.last - werte.first).abs())}',
                'seit Start',
              ),
              BZahl('${alle.length}', 'Übungen'),
            ],
            knopf: ('Nächstes Ziel vorschlagen', 't-selbst'),
            knopf2: (Icons.play_circle_outline, 't-videos'),
          ),
          kacheln: [
            BKachel(
              id: 't-kurve',
              titel: 'Übungen im Verlauf',
              icon: Icons.trending_up,
              feld: verlaufF,
            ),
            BKachel(
              id: 't-rekorde',
              titel: 'Rekorde',
              icon: Icons.emoji_events_outlined,
              feld: verlaufF,
            ),
            BKachel(
              id: 't-videos',
              titel: 'Form-Videos',
              icon: Icons.play_circle_outline,
              feld: verlaufF,
            ),
            BKachel(
              id: 't-selbst',
              titel: 'Nächstes Ziel',
              icon: Icons.spa_outlined,
              feld: _plan.isEmpty ? null : heute,
              seite: _plan.isEmpty ? _planAnlegen : null,
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------- Ernährung

  Unterbereich _teilErnaehrung() {
    const b = Bereich.ernaehrung;
    final today = widget.clock();
    final u = _essenUmfeld;
    final d = _essen.d;
    final slots = _mahlzeitSlots;
    final eintraege = d.tag(dayKey(today));
    final gegessen = slots.where((s) => eintraege[s.id]?.gegessen == true);
    final naechste = slots.where((s) => eintraege[s.id]?.gegessen != true);
    final blaetter = kochbuchBlaetter(d);
    final rettung = d.gerichte.where((g) => g.quelle == 'coach').length;
    final offen = einkaufsliste(d)
        .where((p) => !d.einkauf.erledigt.contains(p.key))
        .length;
    final ids = {for (final s in _supplements) s.id};
    final gen = _genommen.where(ids.contains).length;
    final ziel = _kcalZiel;
    final next = naechsteOffene(_supplements, _genommen, today);
    final suppOffen = _supplements.length - gen;
    final trink = d.trinkTag(dayKey(today));
    final wasser = wasserZiel(u.kg, training: u.training != null);
    final minuteJetzt = today.hour * 60 + today.minute;
    double tagPos(int m) => ((m - 6 * 60) / (17 * 60)).clamp(0.0, 1.0);
    final wenigWasser = today.hour >= 13 && trink.liter < wasser / 2;
    final teller = tagesTeller(slots, eintraege);
    final kg = _weights.isEmpty ? null : _weights.last.kg;
    final vor14 = _weights.where(
      (w) => !w.datum.isAfter(today.subtract(const Duration(days: 14))),
    );
    final diff = kg == null || vor14.isEmpty ? null : kg - vor14.last.kg;
    Widget seite(Widget Function() bau) => _lebendig(bau);
    return Unterbereich(
      id: b.name,
      name: 'Ernährung',
      icon: Icons.restaurant,
      wert: _wert(b).$1,
      woche: _woche7(b),
      sub: _koerperZeile(),
      seiten: [
        BSeite(
          name: 'Heute',
          coach: _coach(
            b,
            wenigWasser
                ? 'Erst ${literText(trink.liter)} von ${literText(wasser)} l. '
                      'Wenig Wasser macht nachmittags müde.'
                : slots.isEmpty
                ? 'Leg einmal fest, wie oft du isst. Dann plane ich deine '
                      'Mahlzeiten um Training und Termine.'
                : '${gegessen.length} von ${slots.length} Mahlzeiten. '
                      '${naechste.isEmpty ? 'Alles gegessen.' : 'Als Nächstes ${naechste.first.name} um ${naechste.first.uhrzeit}.'}',
          ),
          bild: BBild(
            bau: (tipp, v, t) => EssenHeuteBild(
              mahlzeiten: [
                for (final m in slots)
                  (
                    tagPos(m.minute),
                    eintraege[m.id]?.gegessen == true,
                    m.uhrzeit,
                  ),
              ],
              jetzt: tagPos(minuteJetzt),
              teller: [teller.eiweiss, teller.gemuese, teller.energie],
              liter: trink.liter,
              ziel: wasser,
              tipp: tipp,
              v: v,
              t: t,
            ),
            zahlen: [
              BZahl(
                slots.isEmpty ? '–' : '${gegessen.length}/${slots.length}',
                'Mahlzeiten',
              ),
              BZahl(
                naechste.isEmpty ? '–' : naechste.first.uhrzeit,
                'als Nächstes',
              ),
              BZahl('${literText(trink.liter)} l', 'Wasser', ziel: 'e-trinken'),
            ],
            knopf: ('Foto machen', 'e-foto'),
            knopf2: (Icons.local_fire_department_outlined, 'e-heiss'),
          ),
          kacheln: [
            BKachel(
              id: 'e-essen',
              titel: 'Dein Essen heute',
              icon: Icons.show_chart,
              feld: _feld(
                b,
                'energie,teller',
                'Dein Essen heute',
                Icons.show_chart,
                'Oben deine Mahlzeiten auf der Energie-Kurve, darunter füllt '
                    'sich dein Teller. Gezählt wird nichts.',
              ),
            ),
            BKachel(
              id: 'e-foto',
              titel: 'Foto',
              icon: Icons.photo_camera_outlined,
              seite: (_) => seite(() => FotoSeite(umfeld: u)),
            ),
            BKachel(
              id: 'e-heiss',
              titel: 'Heißhunger',
              icon: Icons.local_fire_department_outlined,
              seite: (_) => seite(() => HeisshungerSeite(umfeld: u)),
            ),
            BKachel(
              id: 'e-trinken',
              titel: 'Trinken',
              icon: Icons.local_drink_outlined,
              seite: (_) => seite(() => TrinkenSeite(umfeld: u)),
            ),
          ],
        ),
        BSeite(
          name: 'Küche',
          coach: blaetter == 0
              ? 'Jedes Gericht, das du kochst und bewertest, wird ein Blatt. '
                    'Die Einkaufsliste kommt aus deinen Gerichten.'
              : '$blaetter ${blaetter == 1 ? 'Gericht' : 'Gerichte'} in deinem '
                    'Kochbuch. Die Einkaufsliste kommt von selbst daraus.',
          bild: BBild(
            bau: (tipp, v, t) => KuecheBild(
              blaetter: [
                for (final g in d.gerichte)
                  (voll: g.imKochbuch, rettung: g.quelle == 'coach'),
              ],
              korb: offen,
              tipp: tipp,
              v: v,
              t: t,
            ),
            zahlen: [
              BZahl('$blaetter', 'Gerichte', ziel: 'e-koch'),
              BZahl('$rettung', 'Rettung'),
              BZahl('$offen', 'im Korb'),
            ],
            knopf: ('Einkaufsliste', 'e-einkauf'),
            knopf2: (Icons.menu_book_outlined, 'e-koch'),
          ),
          kacheln: [
            BKachel(
              id: 'e-koch',
              titel: 'Dein Kochbuch',
              icon: Icons.menu_book_outlined,
              seite: (_) => seite(() => KochbuchSeite(umfeld: u)),
            ),
            BKachel(
              id: 'e-einkauf',
              titel: 'Einkaufsliste',
              icon: Icons.shopping_cart_outlined,
              seite: (_) => seite(() => EinkaufslisteSeite(umfeld: u)),
            ),
          ],
        ),
        BSeite(
          name: 'Ziel',
          coach: suppOffen > 0 && next != null
              ? 'Supplements: $suppOffen offen, nächste ${next.zeit} '
                    '${next.name}. Tipp auf die Kapseln zum Abhaken.'
              : diff == null
              ? 'Das kcal-Ziel ist nur Orientierung. Gezählt wird nichts.'
              : 'In zwei Wochen ${diff > 0 ? '+' : (diff < 0 ? '−' : '±')}'
                    '${_HomePageState._komma(diff.abs())} kg. Der Wochenschnitt '
                    'zählt, nicht der einzelne Tag.',
          bild: BBild(
            bau: (tipp, v, t) => ZielBild(
              kcal: ziel,
              gewichte: [for (final w in _weights) w.kg],
              kapseln: [
                for (final s in _supplements)
                  (s.name, _genommen.contains(s.id)),
              ],
              tipp: tipp,
              v: v,
              t: t,
            ),
            zahlen: [
              BZahl(
                kg == null ? '–' : _HomePageState._komma(kg),
                'kg heute',
                ziel: 'e-ziel',
              ),
              BZahl(
                diff == null
                    ? '–'
                    : '${diff > 0 ? '+' : (diff < 0 ? '−' : '±')}${_HomePageState._komma(diff.abs())}',
                'in 2 Wochen',
              ),
              BZahl(
                _supplements.isEmpty ? '–' : '$gen/${_supplements.length}',
                'Supplements',
                ziel: 'e-supp',
              ),
            ],
            knopf: ('Gewicht eintragen', 'e-ziel'),
            knopf2: (Icons.medication_outlined, 'e-supp'),
          ),
          kacheln: [
            BKachel(
              id: 'e-ziel',
              titel: 'kcal & Gewicht',
              icon: Icons.monitor_weight_outlined,
              feld: _feld(
                b,
                'kcal,gewicht',
                'kcal & Gewicht',
                Icons.monitor_weight_outlined,
                'Bewegt sich dein Gewicht 3 Wochen nicht passend zum Ziel, '
                    'frage ich dich zuerst.',
              ),
            ),
            BKachel(
              id: 'e-supp',
              titel: 'Supplements',
              icon: Icons.medication_outlined,
              feld: _feld(
                b,
                'supp',
                'Supplement-Routine',
                Icons.medication_outlined,
                'Du legst alles selbst fest. Bei Fragen zu Mitteln oder '
                    'Mengen: frag deinen Arzt.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------- Schlaf & Routine

  Unterbereich _teilSchlaf() {
    const b = Bereich.schlaf;
    final today = widget.clock();
    final u = _schlafUmfeld;
    final d = _schlaf.d;
    final morgen = d.morgenAm(dayKey(today));
    final bz = _bettzeit;
    final journal = d.journalAm(dayKey(today));
    final muster = sichtbareSchlafMuster(d);
    final letzte = _sleep.reversed.take(7).toList().reversed.toList();
    final naechte = [
      for (final e in letzte) (e.stunden, 'MDMDFSS'[e.datum.weekday - 1]),
    ];
    final schnitt = letzte.isEmpty
        ? null
        : letzte.map((e) => e.stunden).reduce((a, b) => a + b) / letzte.length;
    final kurz = letzte.where((e) => e.stunden < 6.5).length;
    final minute = today.hour * 60 + today.minute;
    int? minuten(String z) {
      final m = RegExp(r'^(\d{1,2})[:.](\d{2})').firstMatch(z.trim());
      return m == null
          ? null
          : int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    }

    final dankbar =
        journal?.dankbar.where((x) => x.trim().isNotEmpty).length ?? 0;
    final besser =
        journal?.besser.where((x) => x.trim().isNotEmpty).length ?? 0;
    final gewaehlt = morgen == null
        ? null
        : morgen.himmel >= 67
        ? 0
        : morgen.himmel >= 34
        ? 1
        : 2;
    Widget seite(Widget Function() bau) => _lebendig(bau);
    return Unterbereich(
      id: b.name,
      name: 'Schlaf & Routine',
      icon: Icons.bedtime,
      wert: _wert(b).$1,
      woche: _woche7(b),
      sub: _koerperZeile(),
      seiten: [
        BSeite(
          name: 'Morgen',
          coach: _coach(
            b,
            morgen == null
                ? 'Guten Morgen. Wie bist du aufgewacht? Daraus kommt dein '
                      'Schlafwert.'
                : 'Schlafwert ${morgen.wert} heute. Jetzt 5 Minuten raus ins '
                      'Licht, das macht dich wach.',
          ),
          bild: BBild(
            bau: (tipp, v, t) => MorgenBild(
              licht: 0,
              gewaehlt: gewaehlt,
              tipp: tipp,
              v: v,
              t: t,
            ),
            zahlen: [
              BZahl(
                u.weckzeit == null ? '–' : formatUhrzeit(u.weckzeit!),
                'Wecker',
                ziel: 's-wecker',
              ),
              BZahl(morgen == null ? '–' : '${morgen.wert}', 'Schlafwert'),
              BZahl(
                morgen == null
                    ? '–'
                    : '${_HomePageState._komma(morgen.stunden)} h',
                'geschlafen',
              ),
            ],
            knopf: ('Licht-Timer starten', 's-licht'),
            knopf2: (Icons.alarm, 's-wecker'),
          ),
          kacheln: [
            BKachel(
              id: 's-himmel',
              titel: 'Aufwach-Himmel',
              icon: Icons.wb_twilight,
              seite: (_) => seite(() => AufwachSeite(umfeld: u)),
            ),
            BKachel(
              id: 's-licht',
              titel: 'Sonnenlicht',
              icon: Icons.wb_sunny_outlined,
              seite: (_) => seite(() => AufwachSeite(umfeld: u)),
            ),
            BKachel(
              id: 's-wecker',
              titel: 'Wecker',
              icon: Icons.alarm,
              seite: (_) => seite(() => WeckerSeite(umfeld: u)),
            ),
          ],
        ),
        BSeite(
          name: 'Nacht',
          coach: muster.isNotEmpty
              ? 'Ich habe etwas bei dir erkannt: ${muster.first.text} Tipp '
                    'rechts unten, dann siehst du alles.'
              : bz == null
              ? 'Leg deine Schlafzeiten fest. Daraus rechne ich jeden Abend '
                    'deine Bettzeit.'
              : 'Heute ${formatUhrzeit(bz.bett)} ins Bett, dann passt die '
                    'Nacht zu deinem Wecker.',
          bild: BBild(
            bau: (tipp, v, t) => NachtBild(
              bett: bz == null ? '–' : formatUhrzeit(bz.bett),
              auf: bz == null ? '–' : formatUhrzeit(bz.aufstehen),
              wert: morgen == null ? '–' : '${morgen.wert}',
              unter: morgen == null
                  ? 'Schlafwert · nach dem Aufwachen'
                  : 'Schlafwert · ${_HomePageState._komma(morgen.stunden)} h geschlafen',
              naechte: naechte,
              tipp: tipp,
              v: v,
              t: t,
            ),
            zahlen: [
              BZahl(
                schnitt == null ? '–' : '${_HomePageState._komma(schnitt)} h',
                'Schnitt',
              ),
              BZahl(
                bz == null ? '–' : formatUhrzeit(bz.bett),
                'ins Bett',
                ziel: 's-zeiten',
              ),
              BZahl('$kurz', 'kurze Nächte', ziel: 's-naechte'),
            ],
            knopf: ('Schlafzeiten', 's-zeiten'),
            knopf2: (Icons.hub_outlined, 's-muster'),
          ),
          kacheln: [
            BKachel(
              id: 's-wert',
              titel: 'Schlafwert',
              icon: Icons.nightlight_round,
              feld: _feld(
                b,
                'wert',
                'Schlafwert',
                Icons.nightlight_round,
                'Aus vier Teilen. Später kommen die Daten auch von Uhr oder '
                    'Ring.',
              ),
            ),
            BKachel(
              id: 's-naechte',
              titel: 'Nächte',
              icon: Icons.bar_chart,
              feld: _feld(
                b,
                'naechte',
                'Letzte Nächte',
                Icons.bar_chart,
                'Deine Nächte und wie lange du geschlafen hast.',
              ),
            ),
            BKachel(
              id: 's-zeiten',
              titel: 'Schlafzeiten',
              icon: Icons.schedule,
              feld: _feld(
                b,
                'zeiten',
                'Deine Schlafzeiten',
                Icons.schedule,
                'Daraus rechne ich jeden Abend deine Bettzeit.',
              ),
            ),
            BKachel(
              id: 's-muster',
              titel: 'Erkannt bei dir',
              icon: Icons.hub_outlined,
              seite: (_) => seite(() => SchlafMusterSeite(umfeld: u)),
            ),
          ],
        ),
        BSeite(
          name: 'Abend',
          coach: journal?.guteNacht != null
              ? 'Heute ist alles erledigt. Gute Nacht.'
              : _routine.isEmpty
              ? 'Leg einmal fest, wie dein Abend aussieht. Danach 3 und 3, '
                    'dann Gute Nacht.'
              : 'Um ${_routine.first.zeit} geht deine Routine los. Danach 3 '
                    'und 3, dann Gute Nacht.',
          bild: BBild(
            bau: (tipp, v, t) => AbendBild(
              kerzen: [
                for (final r in _routine.take(3))
                  (r.was, (minuten(r.zeit) ?? 24 * 60) <= minute),
              ],
              dankbar: dankbar,
              besser: besser,
              tipp: tipp,
              v: v,
              t: t,
            ),
            zahlen: [
              BZahl(
                _routine.isEmpty ? '–' : _routine.first.zeit,
                'Routine ab',
                ziel: 's-routine',
              ),
              BZahl('${dankbar + besser}/6', 'Sterne', ziel: 's-journal'),
              BZahl(bz == null ? '–' : formatUhrzeit(bz.bett), 'Bett'),
            ],
            knopf: ('Gute Nacht', 's-ruhe'),
            knopf2: (Icons.wb_sunny_outlined, 's-tag'),
          ),
          kacheln: [
            BKachel(
              id: 's-journal',
              titel: 'Abend-Journal',
              icon: Icons.auto_awesome_outlined,
              seite: (_) => seite(() => AbendSeite(umfeld: u)),
            ),
            BKachel(
              id: 's-routine',
              titel: 'Abendroutine',
              icon: Icons.format_list_bulleted,
              feld: _feld(
                b,
                'routine',
                'Abendroutine',
                Icons.format_list_bulleted,
                'Einmal festgelegt. Wenn der Schlaf öfter schlecht ist, passe '
                    'ich sie an.',
              ),
            ),
            BKachel(
              id: 's-ruhe',
              titel: 'Ruhezustand',
              icon: Icons.dark_mode_outlined,
              seite: (_) => seite(() => AbendSeite(umfeld: u)),
            ),
            BKachel(
              id: 's-tag',
              titel: 'Dein Tag vom Coach',
              icon: Icons.wb_sunny,
              seite: (_) => seite(() => TagesablaufSeite(umfeld: u)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mo..So as small dots: gold = trained, ring = planned.

/// "62,5" or "60": one decimal at most.
String _zahl1(double v) {
  final r = (v * 10).round() / 10;
  return (r == r.roundToDouble() ? r.toInt().toString() : '$r').replaceAll(
    '.',
    ',',
  );
}
