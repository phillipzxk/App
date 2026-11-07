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

  Unterbereich _teilTraining() {
    const b = Bereich.training;
    final today = widget.clock();
    final tag = _woche.forDay(today);
    final name = shortDay(tag);
    final uebungen = [
      for (final l in dayDetails(tag).split('\n'))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    final frei = name == 'frei';
    final einheit = _training.einheitAm(today);
    final woche = _trainingsWoche();
    final gemacht = woche.where((x) => x == true).length;
    final geplant = woche.where((x) => x != null).length;
    final stag = stagnationFaellig(_training, planUebungen(_plan), today);
    final alle = planUebungen(_plan);
    final sport = _training.sportarten;
    final planTage = _plan.tage.where((t) => t.trim().isNotEmpty).length;
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
    final fertig = einheit?.status == EinheitStatus.fertig;
    return Unterbereich(
      id: b.name,
      name: 'Training',
      icon: Icons.fitness_center,
      wert: _wert(b).$1,
      woche: _woche7(b),
      sub: _koerperZeile(),
      szene: SzeneArt.training,
      szeneDaten: SzeneDaten(
        zeile: frei
            ? 'Heute frei · Erholung zählt mit'
            : fertig
            ? 'Heute $name · geschafft'
            : 'Heute $name${uebungen.isEmpty ? '' : ' · ${uebungen.length} Übungen'}',
      ),
      seiten: [
        BSeite(
          name: 'Heute',
          zeigt: frei || fertig || _plan.isEmpty ? null : 't-heute',
          coach: _coach(
            b,
            frei
                ? 'Heute ist frei. Erholung gehört zum Training.'
                : 'Heute $name. Die Ziele sind schon eingetragen.',
          ),
          kacheln: [
            BKachel(
              id: 't-heute',
              titel: frei ? 'Heute' : 'Heute · $name',
              icon: Icons.fitness_center,
              groesse: KachelGroesse.hoch,
              gold: true,
              wert: frei
                  ? (_plan.isEmpty ? 'Plan anlegen' : 'Frei')
                  : (uebungen.isEmpty ? name : '${uebungen.length} Übungen'),
              unter: switch (einheit?.status) {
                EinheitStatus.fertig => 'Geschafft',
                EinheitStatus.uebersprungen => 'Übersprungen',
                _ => uebungen.take(3).join(' · '),
              },
              hot: einheit?.status == EinheitStatus.fertig ? 'geschafft' : null,
              knopf: frei ? null : 'Trainings-Modus',
              feld: _plan.isEmpty ? null : heute,
              seite: _plan.isEmpty ? _planAnlegen : null,
            ),
            BKachel(
              id: 't-modus',
              titel: 'Trainings-Modus',
              icon: Icons.crop_portrait,
              text: 'Eine Übung pro Bild',
              unter: 'große Zahlen, danach der Pausen-Ring',
              feld: heute,
            ),
            BKachel(
              id: 't-form',
              titel: 'Form filmen',
              icon: Icons.videocam_outlined,
              text: 'Hinweise vom Coach',
              unter: 'ein Satz pro Übung',
              feld: heute,
            ),
          ],
        ),
        BSeite(
          name: 'Woche',
          zeigt: stag == null ? null : 't-stag',
          coach:
              'Deine Woche auf einen Blick. Verschiebt sich etwas, sage ich '
              'dir warum.',
          kacheln: [
            BKachel(
              id: 't-woche',
              titel: 'Woche',
              icon: Icons.calendar_today,
              groesse: KachelGroesse.mittel,
              gold: true,
              wert: geplant == 0 ? '$gemacht' : '$gemacht von $geplant',
              unter: 'Trainingstage diese Woche',
              bild: _Wochenpunkte(woche),
              feld: wocheF,
            ),
            BKachel(
              id: 't-balance',
              titel: 'Hybrid-Balance',
              icon: Icons.balance,
              text: sport.length > 1 ? 'Kraft und Ausdauer' : 'Eine Sportart',
              unter: sport.length > 1
                  ? 'wie sich die Woche verteilt'
                  : 'erscheint ab zwei Sportarten',
              feld: wocheF,
            ),
            BKachel(
              id: 't-stag',
              titel: 'Stagnation',
              icon: Icons.timeline,
              text: stag ?? 'Alles bewegt sich',
              unter: stag == null
                  ? 'ich melde mich, wenn etwas steht'
                  : 'steht seit 3 Wochen',
              feld: wocheF,
            ),
          ],
        ),
        BSeite(
          name: 'Plan',
          coach:
              'Dein Plan läuft von selbst weiter. Nach dem Training '
              'schlägst du zuerst dein nächstes Ziel vor.',
          kacheln: [
            BKachel(
              id: 't-plan',
              titel: 'Dein Plan',
              icon: Icons.list_alt,
              groesse: KachelGroesse.hoch,
              gold: true,
              wert: _plan.isEmpty ? 'Anlegen' : '$planTage Tage',
              unter: _plan.isEmpty
                  ? 'einmal festlegen, dann läuft er'
                  : '${alle.length} Übungen · läuft von selbst',
              feld: _plan.isEmpty ? null : planF,
              seite: _plan.isEmpty ? _planAnlegen : null,
            ),
            BKachel(
              id: 't-sport',
              titel: 'Sportarten',
              icon: Icons.sports,
              text: sport.isEmpty ? 'Festlegen' : sport.join(' + '),
              unter: _schwerpunkt == null
                  ? 'und dein Schwerpunkt'
                  : 'Schwerpunkt ${_schwerpunkt!.label}',
              feld: planF,
            ),
            BKachel(
              id: 't-selbst',
              titel: 'Nächstes Ziel',
              icon: Icons.spa_outlined,
              text: 'Du schlägst vor',
              unter: 'nach dem Training, ich prüfe',
              feld: heute,
            ),
          ],
        ),
        BSeite(
          name: 'Verlauf',
          coach:
              'Jede Übung hat ihre Kurve, ihre Rekorde und ihre '
              'Form-Videos.',
          kacheln: [
            BKachel(
              id: 't-kurve',
              titel: 'Übungen im Verlauf',
              icon: Icons.trending_up,
              groesse: KachelGroesse.mittel,
              gold: true,
              wert: '${alle.length}',
              unter: alle.isEmpty
                  ? 'sobald du etwas einträgst'
                  : alle.take(3).join(' · '),
              feld: verlaufF,
            ),
            BKachel(
              id: 't-rekorde',
              titel: 'Rekorde',
              icon: Icons.emoji_events_outlined,
              text: 'Goldener Trieb',
              unter: 'jeder Bestwert lässt ihn wachsen',
              feld: verlaufF,
            ),
            BKachel(
              id: 't-videos',
              titel: 'Form-Videos',
              icon: Icons.play_circle_outline,
              text: 'Alt neben neu',
              unter: 'pro Übung',
              feld: verlaufF,
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
    Widget seite(Widget Function() bau) => _lebendig(bau);
    return Unterbereich(
      id: b.name,
      name: 'Ernährung',
      icon: Icons.restaurant,
      wert: _wert(b).$1,
      woche: _woche7(b),
      sub: _koerperZeile(),
      szene: SzeneArt.ernaehrung,
      szeneDaten: SzeneDaten(
        zeile: slots.isEmpty
            ? 'Deine Energie über den Tag'
            : '${gegessen.length} von ${slots.length} Mahlzeiten · ${literText(trink.liter)} l getrunken',
        mahlzeiten: [
          for (final m in slots)
            (tagPos(m.minute), eintraege[m.id]?.gegessen == true),
        ],
        jetzt: tagPos(minuteJetzt),
      ),
      seiten: [
        BSeite(
          name: 'Heute',
          zeigt: wenigWasser
              ? 'e-trinken'
              : (slots.isNotEmpty && naechste.isNotEmpty ? 'e-essen' : null),
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
          kacheln: [
            BKachel(
              id: 'e-essen',
              titel: 'Dein Essen heute',
              icon: Icons.show_chart,
              groesse: KachelGroesse.mittel,
              gold: true,
              wert: slots.isEmpty
                  ? 'Festlegen'
                  : '${gegessen.length}/${slots.length}',
              unter: slots.isEmpty
                  ? 'wie oft du am Tag isst'
                  : naechste.isEmpty
                  ? 'alles gegessen, Teller voll'
                  : 'nächste: ${naechste.first.name} ${naechste.first.uhrzeit}',
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
              text: 'Teller oder Kühlschrank',
              unter: 'ich erkenne, was es ist',
              seite: (_) => seite(() => FotoSeite(umfeld: u)),
            ),
            BKachel(
              id: 'e-heiss',
              titel: 'Heißhunger',
              icon: Icons.local_fire_department_outlined,
              text: 'Jetzt antippen',
              unter: 'ein Schritt für jetzt',
              seite: (_) => seite(() => HeisshungerSeite(umfeld: u)),
            ),
            BKachel(
              id: 'e-trinken',
              titel: 'Trinken',
              icon: Icons.local_drink_outlined,
              groesse: KachelGroesse.mittel,
              wert: '${literText(trink.liter)} l',
              bild: TrinkGlas(anteil: trink.liter / wasser, size: 54),
              unter:
                  'von ${literText(wasser)} l'
                  '${trink.kaffee.isEmpty ? '' : ' · Kaffee ${trink.kaffee.length}'}'
                  '${trink.alkohol == 0 ? '' : ' · Alkohol ${trink.alkohol}'}',
              seite: (_) => seite(() => TrinkenSeite(umfeld: u)),
            ),
          ],
        ),
        BSeite(
          name: 'Gerichte',
          coach:
              'Jedes gekochte und bewertete Gericht wird ein Blatt in '
              'deinem Kochbuch. Die Einkaufsliste kommt aus deinen Gerichten.',
          kacheln: [
            BKachel(
              id: 'e-koch',
              titel: 'Dein Kochbuch',
              icon: Icons.menu_book_outlined,
              groesse: KachelGroesse.hoch,
              gold: true,
              wert: '$blaetter',
              unter:
                  '${blaetter == 1 ? 'Blatt' : 'Blätter'} · Basis und Rettung',
              bild: KochbuchRanke(blaetter: blaetter),
              seite: (_) => seite(() => KochbuchSeite(umfeld: u)),
            ),
            BKachel(
              id: 'e-einkauf',
              titel: 'Einkaufsliste',
              icon: Icons.shopping_cart_outlined,
              wert: offen == 0 ? 'Leer' : '$offen offen',
              unter: 'aus deinen Gerichten, sortiert',
              seite: (_) => seite(() => EinkaufslisteSeite(umfeld: u)),
            ),
          ],
        ),
        BSeite(
          name: 'Ziel',
          zeigt: _supplements.isNotEmpty && suppOffen > 0 ? 'e-supp' : null,
          coach: 'Das kcal-Ziel ist nur Orientierung. Gezählt wird nichts.',
          kacheln: [
            BKachel(
              id: 'e-ziel',
              titel: 'kcal & Gewicht',
              icon: Icons.monitor_weight_outlined,
              groesse: KachelGroesse.mittel,
              gold: true,
              wert: ziel == null ? 'Einrichten' : '$ziel kcal',
              unter: ziel == null
                  ? 'aus Größe, Alter, Aktivität und Ziel'
                  : _weights.isEmpty
                  ? 'Gewicht noch eintragen'
                  : '${_HomePageState._komma(_weights.last.kg)} kg · Wochenschnitt zählt',
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
              wert: _supplements.isEmpty ? null : '$gen/${_supplements.length}',
              text: _supplements.isEmpty ? 'Festlegen' : null,
              unter: _supplements.isEmpty
                  ? 'einmal festlegen, dann abhaken'
                  : (suppOffen > 0 && next != null
                        ? '$suppOffen offen, nächste ${next.zeit} ${next.name}'
                        : 'alle genommen'),
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
    final naechte = [for (final e in _sleep.reversed.take(7)) e.stunden]
        .reversed
        .toList();
    Widget seite(Widget Function() bau) => _lebendig(bau);
    return Unterbereich(
      id: b.name,
      name: 'Schlaf & Routine',
      icon: Icons.bedtime,
      wert: _wert(b).$1,
      woche: _woche7(b),
      sub: _koerperZeile(),
      szene: SzeneArt.schlaf,
      szeneDaten: SzeneDaten(
        mond: (morgen?.wert ?? 70) / 100,
        zeile: bz == null
            ? 'Leg deine Schlafzeiten fest'
            : 'Heute ins Bett um ${formatUhrzeit(bz.bett)}',
      ),
      seiten: [
        BSeite(
          name: 'Morgen',
          zeigt: morgen == null ? 's-himmel' : null,
          coach: _coach(
            b,
            morgen == null
                ? 'Wie bist du aufgewacht? Daraus kommt dein Schlafwert.'
                : 'Schlafwert ${morgen.wert} heute. 5 Minuten Licht, dann '
                      'wirst du schneller wach.',
          ),
          kacheln: [
            BKachel(
              id: 's-himmel',
              titel: 'Aufwach-Himmel',
              icon: Icons.wb_twilight,
              groesse: KachelGroesse.hoch,
              gold: morgen == null,
              wert: morgen == null ? null : '${morgen.wert}',
              text: morgen == null ? 'Wie bist du aufgewacht?' : null,
              unter: morgen == null
                  ? 'Himmel ziehen und kurz, was nachts war'
                  : 'Schlafwert heute',
              hot: u.weckzeit == null
                  ? null
                  : 'heute ${formatUhrzeit(u.weckzeit!)}',
              seite: (_) => seite(() => AufwachSeite(umfeld: u)),
            ),
            BKachel(
              id: 's-licht',
              titel: 'Sonnenlicht',
              icon: Icons.wb_sunny_outlined,
              text: '5 Minuten raus',
              unter: 'oder Licht-Modus',
              seite: (_) => seite(() => AufwachSeite(umfeld: u)),
            ),
            BKachel(
              id: 's-wecker',
              titel: 'Wecker',
              icon: Icons.alarm,
              wert: u.weckzeit == null ? null : formatUhrzeit(u.weckzeit!),
              text: u.weckzeit == null ? 'Einstellen' : null,
              unter: weckerKurz(d.wecker),
              seite: (_) => seite(() => WeckerSeite(umfeld: u)),
            ),
          ],
        ),
        BSeite(
          name: 'Nacht',
          coach:
              'Dein Schlafwert kommt aus allem, was du angibst. Später '
              'auch von Uhr oder Ring.',
          kacheln: [
            BKachel(
              id: 's-wert',
              titel: 'Schlafwert',
              icon: Icons.nightlight_round,
              groesse: KachelGroesse.hoch,
              nacht: true,
              wert: morgen == null ? '–' : '${morgen.wert}',
              unter: morgen == null
                  ? 'nach dem Aufwach-Himmel'
                  : 'aus Länge, Erholung, Durchschlafen, Rhythmus',
              bild: SchlafMond(
                fuell: mondFuell(d.morgen, u.jetzt()) ?? .5,
                size: 74,
              ),
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
              text: naechte.isEmpty
                  ? 'Eintragen'
                  : 'Ø ${_HomePageState._komma(naechte.reduce((a, b) => a + b) / naechte.length)} h',
              unter: 'letzte Nächte',
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
              text: bz == null
                  ? 'Festlegen'
                  : '${formatUhrzeit(bz.bett)} ins Bett',
              unter: bz == null
                  ? 'wann du aufstehst'
                  : 'Aufstehen ${formatUhrzeit(bz.aufstehen)}',
              feld: _feld(
                b,
                'zeiten',
                'Deine Schlafzeiten',
                Icons.schedule,
                'Daraus rechne ich jeden Abend deine Bettzeit.',
              ),
            ),
          ],
        ),
        BSeite(
          name: 'Abend',
          zeigt: today.hour >= 20 && journal == null ? 's-journal' : null,
          coach: _routine.isEmpty
              ? 'Leg einmal fest, wie dein Abend aussieht. Danach 3 und 3, '
                    'dann Gute Nacht.'
              : 'Um ${_routine.first.zeit} geht deine Routine los. Danach 3 '
                    'und 3, dann Gute Nacht.',
          kacheln: [
            BKachel(
              id: 's-journal',
              titel: 'Abend-Journal',
              icon: Icons.auto_awesome_outlined,
              groesse: KachelGroesse.mittel,
              gold: true,
              text: '3 dankbar · 3 morgen besser',
              unter: journal?.guteNacht != null
                  ? 'Heute schon fertig'
                  : 'dann Gute Nacht',
              hot: journal?.guteNacht != null ? 'fertig' : null,
              seite: (_) => seite(() => AbendSeite(umfeld: u)),
            ),
            BKachel(
              id: 's-routine',
              titel: 'Abendroutine',
              icon: Icons.format_list_bulleted,
              text: _routine.isEmpty
                  ? 'Festlegen'
                  : 'ab ${_routine.first.zeit}',
              unter: _routine.isEmpty
                  ? 'vor dem Schlafen'
                  : _routine.take(3).map((r) => r.was).join(' · '),
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
              nacht: true,
              text: u.weckzeit == null
                  ? 'Nach Gute Nacht'
                  : 'bis ${formatUhrzeit(u.weckzeit!)}',
              unter: 'alles dunkel bis zum Wecker',
              seite: (_) => seite(() => AbendSeite(umfeld: u)),
            ),
          ],
        ),
        BSeite(
          name: 'Tag',
          coach:
              'Ich baue deinen Tag aus deinen Mustern. Jeder Punkt hat '
              'seinen Grund.',
          kacheln: [
            BKachel(
              id: 's-tag',
              titel: 'Dein Tag vom Coach',
              icon: Icons.wb_sunny,
              groesse: KachelGroesse.mittel,
              gold: true,
              text:
                  d.ablauf?.tag == dayKey(today) &&
                      d.ablauf?.uebernommen == true
                  ? 'Übernommen'
                  : 'Bester Ablauf heute',
              unter: 'aus deinen Mustern gebaut',
              seite: (_) => seite(() => TagesablaufSeite(umfeld: u)),
            ),
            BKachel(
              id: 's-muster',
              titel: 'Erkannt bei dir',
              icon: Icons.hub_outlined,
              wert: '${muster.length}',
              unter: muster.isEmpty
                  ? 'nach 14 Morgen schaue ich'
                  : 'Muster mit Gegenschritt',
              seite: (_) => seite(() => SchlafMusterSeite(umfeld: u)),
            ),
            BKachel(
              id: 's-daten',
              titel: 'Mehr Daten',
              icon: Icons.favorite_border,
              groesse: KachelGroesse.schmal,
              text: 'Uhr · Ring · Health',
              unter: 'in der Handy-Version',
              feld: _feld(
                b,
                'daten',
                'Mehr Daten',
                Icons.favorite_border,
                'Damit der Schlafwert noch genauer wird.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mo..So as small dots: gold = trained, ring = planned.
class _Wochenpunkte extends StatelessWidget {
  const _Wochenpunkte(this.tage);
  final List<bool?> tage;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final t in tage)
        Container(
          width: 11,
          height: 11,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: t == true ? CoachStyle.goldGradient : null,
            color: t == true ? null : const Color(0x1FFFECC8),
            border: t == false
                ? Border.all(color: CoachStyle.goldLight, width: 1.2)
                : null,
          ),
        ),
    ],
  );
}
