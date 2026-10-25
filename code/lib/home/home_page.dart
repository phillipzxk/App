import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../data/diary_store.dart';
import '../data/user_profile.dart';
import '../feed/durchgezogen.dart';
import '../feed/feed_coach.dart';
import '../feed/feed_data.dart';
import '../feed/feed_store.dart';
import '../feed/fokus.dart';
import '../feed/kcal.dart';
import '../feed/muster.dart';
import '../future_me/future_me_data.dart';
import '../future_me/future_me_page.dart';
import '../planner/planner_data.dart';
import '../sleep/schlafzeiten.dart';
import '../sleep/sleep.dart';
import '../supplements/supplement_data.dart';
import '../ui/coach_style.dart';
import '../weight/weight.dart';
import 'durchgezogen_widgets.dart';
import 'fokus_widgets.dart';
import 'reality_check.dart';
import 'bereich_uebersicht.dart';
import 'sonnenbogen.dart';
import 'day_plan.dart';
import 'feed_widgets.dart';
import 'wurzelwerk.dart';
import '../future_me/future_me_card.dart';
import '../ui/coach_widgets.dart';
import 'mindset_tab.dart';
import 'muster_widgets.dart';
import 'nutrition_tab.dart';
import 'sleep_tab.dart';
import 'bereichs_werte.dart';
import 'today_tab.dart';
import 'training_tab.dart';

/// The Main Feed: opens after the daily check-in. "Heute" on top, the
/// four areas on the roots below; each opens big and leads to its full page
/// (vault Umsetzung/Home-Schichten.md, 2026-10-25).
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.profile,
    required this.store,
    required this.feed,
    required this.coach,
    required this.clock,
    required this.onRestartOnboarding,
  });

  final UserProfile profile;
  final DiaryStore store;
  final FeedStore feed;
  final FeedCoach coach;
  final DateTime Function() clock;
  final VoidCallback onRestartOnboarding;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loaded = false;
  final _stand = ValueNotifier<int>(0);
  List<CheckIn> _checkIns = const [];
  List<WeightEntry> _weights = const [];
  List<SleepEntry> _sleep = const [];
  TrainingPlan _plan = TrainingPlan.empty();
  List<RoutineStep> _routine = const [];
  KcalProfil? _kcal;
  List<CoachFrage> _fragen = const [];
  List<Termin> _termine = const [];
  int? _mahlzeiten;
  Schwerpunkt? _schwerpunkt;
  FotoEinstellungen? _fotoEinstellungen;
  List<WochenFoto> _wochenFotos = const [];
  List<Supplement> _supplements = const [];
  Set<String> _genommen = const {};
  List<Muster> _muster = const [];
  Wochenfokus? _fokus;
  FokusAuswahl? _fokusAuswahl;
  bool _fokusLaedt = false;
  bool _fokusVersucht = false;
  Schlafzeiten _schlafzeiten = const Schlafzeiten();
  String _coachAnsicht = 'text';
  List<Durchgezogen> _durchgezogen = const [];
  String? _jubel;
  int _jubelTick = 0;
  final _heuteScroll = ScrollController();

  @override
  void dispose() {
    _heuteScroll.dispose();
    _stand.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final checkIns = await widget.store.loadCheckIns();
    final weights = await widget.store.loadWeights();
    final sleep = await widget.store.loadSleep();
    final plan = await widget.feed.loadPlan();
    final routine = await widget.feed.loadRoutine();
    final kcal = await widget.feed.loadKcal();
    final fragen = await widget.feed.loadFragen();
    final termine = await widget.feed.loadTermine();
    final mahlzeiten = await widget.feed.loadMahlzeiten();
    final schwerpunkt = await widget.feed.loadSchwerpunkt();
    final fotoEinstellungen = await widget.feed.loadFotoEinstellungen();
    final wochenFotos = await widget.feed.loadWochenFotos();
    final supplements = await widget.feed.loadSupplements();
    final genommen = await widget.feed.loadGenommen(widget.clock());
    final muster = await widget.feed.loadMuster();
    final fokus = await widget.feed.loadFokus();
    final fokusAuswahl = await widget.feed.loadFokusAuswahl();
    final schlafzeiten = await widget.feed.loadSchlafzeiten();
    final coachAnsicht = await widget.feed.loadCoachAnsicht();
    final durchgezogen = await widget.feed.loadDurchgezogen();
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _checkIns = checkIns;
      _weights = weights;
      _sleep = sleep;
      _plan = plan;
      _routine = routine;
      _kcal = kcal;
      _fragen = fragen;
      _termine = termine;
      _mahlzeiten = mahlzeiten;
      _schwerpunkt = schwerpunkt;
      _fotoEinstellungen = fotoEinstellungen;
      _wochenFotos = wochenFotos;
      _supplements = supplements;
      _genommen = genommen;
      _muster = muster;
      _fokus = fokus;
      _fokusAuswahl = fokusAuswahl;
      _schlafzeiten = schlafzeiten;
      _coachAnsicht = coachAnsicht;
      _durchgezogen = durchgezogen;
    });
    _stand.value++;
    _pruefeMuster(checkIns, muster);
    _pruefeDurchgezogen(checkIns, durchgezogen);
    if (!_fokusVersucht) _holeFokusVorschlaege();
  }

  bool get _fokusLaeuft {
    final f = _fokus;
    return f != null && !f.vorbei(widget.clock());
  }

  /// Without a running focus, the coach suggests three (the first time from
  /// the onboarding, later with a look back). Kept until one is chosen.
  Future<void> _holeFokusVorschlaege() async {
    if (_fokusLaeuft || _fokusAuswahl != null || _fokusLaedt) return;
    _fokusVersucht = true;
    setState(() => _fokusLaedt = true);
    final letzter = _fokus;
    final auswahl = await widget.coach.fokusVorschlaege(
      widget.profile,
      _checkIns,
      sichtbareMuster(_muster),
      letzter: letzter,
      training: letzter == null
          ? null
          : TrainingWoche.aus(letzter, _plan, _checkIns),
    );
    if (auswahl != null) await widget.feed.saveFokusAuswahl(auswahl);
    if (!mounted) return;
    setState(() {
      _fokusLaedt = false;
      _fokusAuswahl = auswahl;
    });
  }

  Future<void> _starteFokus(FokusVorschlag v) async {
    final today = widget.clock();
    // Keeping the old focus starts a fresh week with the same text.
    await widget.feed.saveFokus(
      Wochenfokus(
        start: DateTime(today.year, today.month, today.day),
        text: v.text,
      ),
    );
    await widget.feed.saveFokusAuswahl(null);
    await _reload();
  }

  Widget _fokusWidget() {
    final f = _fokus;
    if (f != null && !f.vorbei(widget.clock())) {
      return FokusKarte(
        fokus: f,
        today: widget.clock(),
        onUmschalten: () async {
          final neu = f.umschalten(widget.clock());
          await widget.feed.saveFokus(neu);
          final geschafft = neu.heuteGeschafft(widget.clock());
          // Scroll up first so the sprout and the coach can be seen.
          if (geschafft && _heuteScroll.hasClients) {
            await _heuteScroll.animateTo(
              0,
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeInOutCubic,
            );
          }
          if (!mounted) return;
          setState(() {
            if (geschafft) {
              _jubelTick++;
              final n = widget.profile.name.trim();
              _jubel =
                  'Ja${n.isEmpty ? '' : ', $n'}! Fokus heute geschafft.\n'
                  'Oben siehst du den Trieb, aber das Wichtigste wächst '
                  'darunter: Deine Wurzeln sind heute wieder tiefer geworden.';
            } else {
              _jubel = null;
            }
          });
          await _reload();
        },
      );
    }
    final laedt = _fokusLaedt || !_fokusVersucht;
    // A week just ended: only the small Reality Check field on Heute.
    if (f != null) {
      final a = _fokusAuswahl;
      return RealityFeld(
        auswahl: a,
        laedt: laedt,
        onNochmal: _holeFokusVorschlaege,
        onOpen: () => _oeffneReality(a!),
      );
    }
    return FokusWahl(
      auswahl: _fokusAuswahl,
      laedt: laedt,
      onStart: _starteFokus,
      onNochmal: _holeFokusVorschlaege,
    );
  }

  Future<void> _oeffneReality(FokusAuswahl a) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RealityCheckSeite(auswahl: a, onStart: _starteFokus),
    ),
  );

  bool _prueft = false;

  /// Once a day, after today's check-in and from 5 check-ins on, the coach
  /// looks for one clear new pattern. Nothing found: nothing shows.
  Future<void> _pruefeMuster(
    List<CheckIn> checkIns,
    List<Muster> bisher,
  ) async {
    final today = widget.clock();
    if (_prueft || checkIns.length < musterAbCheckIns) return;
    if (!checkIns.any((c) => dayKey(c.datum) == dayKey(today))) return;
    if (await widget.feed.loadMusterGeprueft() == dayKey(today)) return;
    _prueft = true;
    await widget.feed.saveMusterGeprueft(today);
    final neu = await widget.coach.findeMuster(
      widget.profile,
      checkIns,
      bisher,
    );
    _prueft = false;
    if (neu == null) return;
    await widget.feed.saveMuster([...bisher, neu]);
    await _reload();
  }

  bool _durchPrueft = false;

  /// Once a day after today's check-in the coach may add one entry to
  /// "Durchgezogen", only when something was clearly done despite
  /// reluctance (decided with Phillip 2026-10-20).
  Future<void> _pruefeDurchgezogen(
    List<CheckIn> checkIns,
    List<Durchgezogen> bisher,
  ) async {
    final today = widget.clock();
    final key = dayKey(today);
    if (_durchPrueft) return;
    final heute = checkIns.where((c) => dayKey(c.datum) == key).toList();
    if (heute.isEmpty) return;
    if (bisher.any((e) => e.vonCoach && dayKey(e.datum) == key)) return;
    if (await widget.feed.loadDurchGeprueft() == key) return;
    _durchPrueft = true;
    await widget.feed.saveDurchGeprueft(today);
    final f = _fokusLaeuft ? _fokus : null;
    final text = await widget.coach.durchgezogen(
      widget.profile,
      heute.last,
      fokus: f?.text,
      fokusGeschafft: f?.heuteGeschafft(today) ?? false,
      bisher: bisher,
    );
    _durchPrueft = false;
    if (text == null || text.trim().isEmpty) return;
    final aktuell = await widget.feed.loadDurchgezogen();
    await widget.feed.saveDurchgezogen([
      ...aktuell,
      Durchgezogen(
        datum: DateTime(today.year, today.month, today.day),
        text: text.trim(),
        vonCoach: true,
        erstellt: widget.clock(),
      ),
    ]);
    await _reload();
  }

  Future<void> _durchAdd(String text) async {
    final today = widget.clock();
    final aktuell = await widget.feed.loadDurchgezogen();
    await widget.feed.saveDurchgezogen([
      ...aktuell,
      Durchgezogen(
        datum: DateTime(today.year, today.month, today.day),
        text: text,
        vonCoach: false,
        erstellt: today,
      ),
    ]);
    await _reload();
  }

  Future<void> _durchAlle() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DurchgezogenSeite(
          alle: _durchgezogen,
          today: widget.clock(),
          onDelete: (e) async {
            final aktuell = await widget.feed.loadDurchgezogen();
            await widget.feed.saveDurchgezogen([
              for (final x in aktuell)
                if (x.erstellt != e.erstellt || x.text != e.text) x,
            ]);
          },
        ),
      ),
    );
    await _reload();
  }

  List<CoachFrage> _todayFragen(Bereich b) {
    final key = dayKey(widget.clock());
    return [
      for (final f in _fragen)
        if (f.bereich == b && dayKey(f.datum) == key) f,
    ];
  }

  Future<void> Function(String) _ask(Bereich b) => (text) async {
    final antwort = await widget.coach.answer(
      widget.profile,
      b,
      text,
      context: _context(b),
    );
    await widget.feed.addFrage(
      CoachFrage(
        datum: widget.clock(),
        bereich: b,
        text: text,
        antwort: antwort ?? '',
      ),
    );
    await _reload();
  };

  Future<void> _addWeight() async {
    final kg = await showDialog<double>(
      context: context,
      builder: (context) => const WeightDialog(),
    );
    if (kg == null) return;
    await widget.store.addWeight(WeightEntry(widget.clock(), kg));
    await _reload();
  }

  Future<void> _addSleep() async {
    final h = await showDialog<double>(
      context: context,
      builder: (context) => const SleepDialog(),
    );
    if (h == null) return;
    await widget.store.saveSleep(SleepEntry(widget.clock(), h));
    await _reload();
  }

  Future<void> _saveKcal(KcalProfil profil, double? kg) async {
    await widget.feed.saveKcal(profil);
    if (kg != null) {
      await widget.store.addWeight(WeightEntry(widget.clock(), kg));
    }
    await _reload();
  }

  /// What the user set up for [b], so the coach can refer to it.
  String _context(Bereich b) {
    switch (b) {
      case Bereich.training:
        if (_plan.isEmpty) return '';
        const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
        return [
          'Trainingsplan:',
          for (var i = 0; i < 7; i++)
            '${days[i]}: ${_plan.tage[i].trim().isEmpty ? 'frei' : _plan.tage[i].trim()}',
          'Heute ist ${days[widget.clock().weekday - 1]}.',
        ].join('\n');
      case Bereich.ernaehrung:
        final ziel = _kcalZiel;
        if (ziel == null) return '';
        return 'kcal-Ziel heute: $ziel kcal '
            '(nur als Orientierung, nicht zum Zählen). '
            'Gewicht zuletzt: ${_weights.last.kg} kg.';
      case Bereich.schlaf:
        final b = _bettzeit;
        final z = _schlafzeiten;
        final lines = [
          if (z.werktag != null)
            'Aufstehen Mo bis Fr: ${formatUhrzeit(z.werktag!)}',
          if (z.wochenende != null)
            'Aufstehen Sa und So: ${formatUhrzeit(z.wochenende!)}',
          if (z.gesetzt)
            'Schlaf, den sie braucht: ${formatStunden(z.stunden)} Stunden',
          if (b != null)
            'Bettzeit heute: ${formatUhrzeit(b.bett)}, morgen raus um ${formatUhrzeit(b.aufstehen)}',
          if (_routine.isNotEmpty) 'Abendroutine:',
          for (final s in _routine) '${s.zeit} ${s.was}',
          for (final e in _sleep.reversed.take(7))
            'Schlaf ${dayKey(e.datum)}: ${e.stunden} Stunden',
        ];
        return lines.join('\n');
      case Bereich.mindset:
        return '';
    }
  }

  Bettzeit? get _bettzeit =>
      bettzeitFuer(_schlafzeiten, widget.clock(), _termine);

  int? get _kcalZiel {
    final p = _kcal;
    if (p == null || _weights.isEmpty) return null;
    return kcalZiel(p, _weights.last.kg);
  }

  static const _icons = {
    Bereich.training: Icons.fitness_center,
    Bereich.ernaehrung: Icons.restaurant,
    Bereich.schlaf: Icons.bedtime,
    Bereich.mindset: Icons.landscape,
  };

  static const _namen = {
    Bereich.training: 'Training',
    Bereich.ernaehrung: 'Ernährung',
    Bereich.schlaf: 'Schlaf & Energie',
    Bereich.mindset: 'Mindset',
  };

  CheckIn? get _heute {
    final key = dayKey(widget.clock());
    for (final c in _checkIns) {
      if (dayKey(c.datum) == key) return c;
    }
    return null;
  }

  (int?, int?) _wert(Bereich b) {
    final w = werteVerlauf(_checkIns, b, widget.clock(), 2);
    final d = w[1] != null && w[0] != null ? w[1]! - w[0]! : null;
    return (w[1], d);
  }

  static String _komma(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

  /// Mo..So of this week: true = trained, false = planned, null = nothing.
  List<bool?> _trainingsWoche() {
    final t = widget.clock();
    final mo = DateTime(t.year, t.month, t.day - (t.weekday - 1));
    final ruhe = RegExp(r'^(ruhe|pause|frei|off\b)', caseSensitive: false);
    final byDay = {for (final c in _checkIns) dayKey(c.datum): c};
    return [
      for (var i = 0; i < 7; i++)
        () {
          final d = DateTime(mo.year, mo.month, mo.day + i);
          final c = byDay[dayKey(d)];
          final a = c?.training.trim() ?? '';
          if (a.isNotEmpty && !a.startsWith('Pause')) return true;
          final p = _plan.tage[i].trim();
          return p.isNotEmpty && !ruhe.hasMatch(p) ? false : null;
        }(),
    ];
  }

  /// The big view of one area: its 4 fixed tiles (vault
  /// Umsetzung/Home-Schichten.md, decided 2026-10-25).
  BereichDaten _daten(Bereich b) {
    final today = widget.clock();
    final (wert, diff) = _wert(b);
    final verlauf = Kachel(
      key: ValueKey('kachel-verlauf-${b.name}'),
      titel: 'Verlauf · 14 Tage',
      wert: '',
      breit: true,
      verlauf: werteVerlauf(_checkIns, b, today, 14),
    );
    final List<Kachel> kacheln;
    switch (b) {
      case Bereich.training:
        final tag = _plan.forDay(today);
        final name = shortDay(tag);
        final uebungen = [
          for (final l in dayDetails(tag).split('\n'))
            if (l.trim().isNotEmpty) l.trim(),
        ];
        final woche = _trainingsWoche();
        final gemacht = woche.where((x) => x == true).length;
        final ruhe = RegExp(r'^(ruhe|pause|frei|off\b)', caseSensitive: false);
        final geplant = _plan.tage
            .where((t) => t.trim().isNotEmpty && !ruhe.hasMatch(t.trim()))
            .length;
        final antwort = _heute?.training.trim() ?? '';
        kacheln = [
          Kachel(
            key: const ValueKey('kachel-heute-training'),
            titel: 'Heute',
            wert: name != 'frei'
                ? name
                : (_plan.isEmpty ? 'Plan festlegen' : 'Frei'),
            unter: uebungen.take(4).join('\n'),
            breit: uebungen.isNotEmpty,
          ),
          Kachel(
            titel: 'Woche',
            wert: geplant == 0 ? '$gemacht' : '$gemacht von $geplant',
            unter: 'Trainingstage',
            tage: woche,
          ),
          Kachel(
            titel: 'Wie war es?',
            wert: antwort.isEmpty ? 'Noch offen' : antwort,
            unter: 'aus deinem Check-in',
          ),
          verlauf,
        ];
      case Bereich.ernaehrung:
        final ids = {for (final s in _supplements) s.id};
        final gen = _genommen.where(ids.contains).length;
        final offen = _supplements.length - gen;
        final next = naechsteOffene(_supplements, _genommen, today);
        final ziel = _kcalZiel;
        String gewichtUnter = '';
        if (_weights.length > 1) {
          final last = _weights.last;
          final vor = _weights.firstWhere(
            (w) => last.datum.difference(w.datum).inDays <= 28,
            orElse: () => last,
          );
          final d = last.kg - vor.kg;
          if (!identical(vor, last)) {
            final wochen = (last.datum.difference(vor.datum).inDays / 7)
                .round()
                .clamp(1, 4);
            gewichtUnter =
                '${d > 0 ? '+' : (d < 0 ? '−' : '±')}${_komma(d.abs())} in $wochen ${wochen == 1 ? 'Woche' : 'Wochen'}';
          }
        }
        kacheln = [
          Kachel(
            key: const ValueKey('supp-hinweis'),
            titel: 'Supplements',
            wert: _supplements.isEmpty
                ? 'Festlegen'
                : '$gen von ${_supplements.length}',
            unter: _supplements.isEmpty
                ? 'deine Routine'
                : (offen > 0 && next != null
                      ? '$offen offen, nächste ${next.zeit} ${next.name}'
                      : 'alle genommen'),
          ),
          Kachel(
            titel: 'kcal-Ziel',
            wert: ziel == null ? 'Einrichten' : '$ziel',
            unter: ziel == null ? 'dein Tagesziel' : 'kcal am Tag',
          ),
          Kachel(
            titel: 'Gewicht',
            wert: _weights.isEmpty
                ? 'Eintragen'
                : '${_komma(_weights.last.kg)} kg',
            unter: gewichtUnter,
          ),
          verlauf,
        ];
      case Bereich.schlaf:
        final bz = _bettzeit;
        final naechte = [for (final e in _sleep.reversed.take(7)) e.stunden]
            .reversed
            .toList();
        kacheln = [
          Kachel(
            titel: 'Heute ins Bett',
            wert: bz == null ? 'Eintragen' : formatUhrzeit(bz.bett),
            unter: bz == null
                ? 'deine Schlafzeiten'
                : 'Aufstehen ${formatUhrzeit(bz.aufstehen)}',
          ),
          Kachel(
            titel: 'Nächte',
            wert: naechte.isEmpty
                ? 'Eintragen'
                : '${_komma(naechte.reduce((a, b) => a + b) / naechte.length)} h',
            unter: naechte.isEmpty ? 'wie lange du schläfst' : 'Schnitt',
            balken: naechte.length > 1 ? naechte : null,
          ),
          Kachel(
            titel: 'Abendroutine',
            wert: _routine.isEmpty
                ? 'Festlegen'
                : '${_routine.length} ${_routine.length == 1 ? 'Schritt' : 'Schritte'}',
            unter: _routine.isEmpty
                ? 'vor dem Schlafen'
                : 'ab ${_routine.first.zeit}',
          ),
          verlauf,
        ];
      case Bereich.mindset:
        final mo = DateTime(
          today.year,
          today.month,
          today.day - (today.weekday - 1),
        );
        final n = _durchgezogen.where((e) => !e.datum.isBefore(mo)).length;
        final warum = widget.profile.motivation.trim();
        kacheln = [
          Kachel(titel: 'Durchgezogen', wert: '$n Mal', unter: 'seit Montag'),
          Kachel(
            titel: 'Wovor drückst du dich?',
            wert: 'Schreiben',
            unter: 'mit dem Coach',
          ),
          Kachel(
            titel: 'Dein Warum',
            wert: warum.isEmpty ? 'Noch offen' : '',
            unter: warum.isEmpty ? '' : '„$warum“',
            breit: true,
          ),
          verlauf,
        ];
    }
    return BereichDaten(
      bereich: b,
      name: _namen[b]!,
      icon: _icons[b]!,
      wert: wert,
      diff: diff,
      grund: _heute?.gruende[b.name],
      kacheln: kacheln,
    );
  }

  /// A page that rebuilds whenever the data changes.
  Widget _lebendig(Widget Function() bau) => ValueListenableBuilder<int>(
    valueListenable: _stand,
    builder: (context, _, _) =>
        WerteScope(checkIns: _checkIns, today: widget.clock(), child: bau()),
  );

  Future<void> _oeffneBereich(Bereich b, Offset mitte) => oeffneMitKreis(
    context,
    mitte,
    (_) => _lebendig(
      () => BereichUebersicht(daten: _daten(b), onAlles: () => _oeffneSeite(b)),
    ),
  );

  /// The full area page with everything the old tab had.
  Future<void> _oeffneSeite(Bereich b) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _UnterSeite(child: _lebendig(() => _seite(b))),
    ),
  );

  /// Today from getting up to bedtime: arc start and end (minutes, end may
  /// pass midnight) and every point with a time, for both sun arcs.
  ({int start, int ende, List<BogenPunkt> punkte, String? ohneZeit})
  _tagesPunkte() {
    final jetzt = widget.clock();
    final aufstehen = _schlafzeiten.aufstehenAm(jetzt);
    final bz = _bettzeit;
    final start = aufstehen ?? 7 * 60;
    var ende = bz?.bett ?? 23 * 60;
    if (ende <= start) ende += 1440;
    final training = _plan.forDay(jetzt).trim();
    final trZeit = trainingZeit(training);
    // Until the coach plans meals, they are spread evenly over the day:
    // from half an hour after getting up to 2.5 hours before bed.
    final n = _mahlzeiten ?? 0;
    final von = start + 30, bis = math.max(von, ende - 150);
    final punkte = <BogenPunkt>[
      if (aufstehen != null)
        BogenPunkt(
          id: 'aufstehen',
          minute: aufstehen,
          art: 'Aufstehen',
          titel: 'Aufstehen',
        ),
      if (_fotoTag != null)
        BogenPunkt(
          id: 'foto',
          minute: start + 15,
          art: 'Foto',
          titel: 'Foto',
          text: _fotoTag,
        ),
      for (final t in termineAm(_termine, jetzt))
        if (parseUhrzeit(t.zeit ?? '') case final m?)
          BogenPunkt(
            id: 'termin-${t.erstellt.microsecondsSinceEpoch}',
            minute: m,
            art: 'Termin',
            titel: t.text,
          ),
      if (trZeit != null)
        BogenPunkt(
          id: 'training',
          minute: trZeit < start ? trZeit + 1440 : trZeit,
          art: 'Training',
          titel: shortDay(training),
          text: dayDetails(training).isEmpty ? null : 'Übungen in deinem Plan',
        ),
      for (var i = 0; i < n; i++)
        BogenPunkt(
          id: 'mahlzeit-$i',
          minute: n == 1 ? (von + bis) ~/ 2 : von + (bis - von) * i ~/ (n - 1),
          art: 'Essen',
          titel: 'Mahlzeit ${i + 1} von $n',
        ),
      for (final x in _supplements)
        if (parseUhrzeit(x.zeit) case final m?)
          BogenPunkt(
            id: 'supp-${x.id}',
            minute: m < start ? m + 1440 : m,
            art: 'Supplement',
            titel: x.name,
            text: [
              if (x.menge.isNotEmpty) x.menge,
              if (_genommen.contains(x.id)) 'genommen ✓',
            ].join(' · '),
            erledigt: _genommen.contains(x.id),
          ),
      if (bz != null && _routine.isNotEmpty)
        if (parseUhrzeit(_routine.first.zeit) case final ab?)
          if (ab < bz.bett && bz.bett - ab <= 180)
            BogenPunkt(
              id: 'routine',
              minute: ab + (ende - bz.bett),
              art: 'Schlaf',
              titel: 'Abendroutine',
            ),
      if (bz != null)
        BogenPunkt(
          id: 'bett',
          minute: ende,
          art: 'Schlaf',
          titel: 'Bettzeit',
          text: 'Morgen um ${formatUhrzeit(bz.aufstehen)} raus',
        ),
    ];
    return (
      start: start,
      ende: ende,
      punkte: punkte,
      ohneZeit: training.isEmpty || trZeit != null ? null : shortDay(training),
    );
  }

  double get _jetztMinute {
    final j = widget.clock();
    return j.hour * 60 + j.minute + j.second / 60;
  }

  /// The sun arc on top of "Dein Tag": from getting up to bedtime.
  Widget _sonnenbogen() {
    final t = _tagesPunkte();
    return Sonnenbogen(
      punkte: t.punkte,
      start: t.start,
      ende: t.ende,
      jetzt: _jetztMinute,
      ohneZeit: t.ohneZeit,
    );
  }

  /// "Heute dran" on Heute: the small sun arc with everything of today.
  Widget _heuteBogen() {
    final t = _tagesPunkte();
    return HeuteBogen(
      key: const ValueKey('dein-tag'),
      punkte: t.punkte,
      start: t.start,
      ende: t.ende,
      jetzt: _jetztMinute,
      ohneZeit: t.ohneZeit,
      onTap: _oeffneTag,
    );
  }

  Future<void> _oeffneTag() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _UnterSeite(
        child: _lebendig(
          () => NightScope(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                PageHeader(
                  label: germanDate(widget.clock()),
                  title: 'Dein Tag',
                ),
                _sonnenbogen(),
                const SizedBox(height: 16),
                DayPlanCard(
                  today: widget.clock(),
                  termine: _termine,
                  training: _plan.forDay(widget.clock()),
                  mahlzeiten: _mahlzeiten,
                  kcalZiel: _kcalZiel,
                  onAddTermin: (text) async {
                    await widget.feed.addTermin(
                      parseTermin(text, widget.clock()),
                    );
                    await _reload();
                  },
                  onRemoveTermin: (t) async {
                    await widget.feed.removeTermin(t);
                    await _reload();
                  },
                  onSetMahlzeiten: (n) async {
                    await widget.feed.saveMahlzeiten(n);
                    await _reload();
                  },
                  onOpenTraining: () => _oeffneSeite(Bereich.training),
                  foto: _fotoTag,
                  onOpenFoto: _oeffneZukunft,
                  bettzeit: _bettzeit,
                  schlafStunden: _schlafzeiten.stunden,
                  routineAb: _routine.isEmpty ? null : _routine.first.zeit,
                  onOpenSchlaf: () => _oeffneSeite(Bereich.schlaf),
                  aufstehen: _schlafzeiten.aufstehenAm(widget.clock()),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  /// "Foto · Woche 7" on the photo day, null on other days.
  String? get _fotoTag {
    final e = _fotoEinstellungen;
    if (e == null) return null;
    final lage = fotoLage(widget.clock(), e, _wochenFotos);
    return switch (lage.status) {
      FotoStatus.heute => 'Foto · Woche ${lage.woche}',
      FotoStatus.nachholen => 'Foto nachholen · Woche ${lage.woche}',
      FotoStatus.spaeter => null,
    };
  }

  Future<void> _oeffneZukunft() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FutureMePage(store: widget.feed, clock: widget.clock),
      ),
    );
    await _reload();
  }

  Future<void> _oeffneMuster() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          MusterSeite(muster: sichtbareMuster(_muster), heute: widget.clock()),
    ),
  );

  Future<void> _musterAblehnen(Muster m) async {
    await widget.feed.saveMuster([
      for (final x in _muster) identical(x, m) ? x.ablehnen() : x,
    ]);
    await _reload();
  }

  Widget _seite(Bereich b) {
    switch (b) {
      case Bereich.training:
        return TrainingTab(
          plan: _plan,
          schwerpunkt: _schwerpunkt,
          today: widget.clock(),
          fragen: _todayFragen(Bereich.training),
          onSchwerpunkt: (sp) async {
            await widget.feed.saveSchwerpunkt(sp);
            await _reload();
          },
          onSavePlan: (p) async {
            await widget.feed.savePlan(p);
            await _reload();
          },
          onAsk: _ask(Bereich.training),
          // The progress photo lives with training (Frame Kit included).
          extra: [
            const GroupLabel('Fortschrittsfoto'),
            FutureMeCard(
              today: widget.clock(),
              einstellungen: _fotoEinstellungen,
              fotos: _wochenFotos,
              onOpen: _oeffneZukunft,
            ),
          ],
        );
      case Bereich.ernaehrung:
        return NutritionTab(
          kcal: _kcal,
          weights: _weights,
          fragen: _todayFragen(Bereich.ernaehrung),
          onSaveKcal: _saveKcal,
          onAddWeight: _addWeight,
          onAsk: _ask(Bereich.ernaehrung),
          supplements: _supplements,
          genommen: _genommen,
          onSaveSupplements: (list) async {
            await widget.feed.saveSupplements(list);
            await _reload();
          },
          onToggleSupplement: (s, an) async {
            await widget.feed.setGenommen(widget.clock(), s.id, an);
            await _reload();
          },
        );
      case Bereich.schlaf:
        return SleepTab(
          routine: _routine,
          sleep: _sleep,
          today: widget.clock(),
          fragen: _todayFragen(Bereich.schlaf),
          onAddSleep: _addSleep,
          onSaveRoutine: (steps) async {
            await widget.feed.saveRoutine(steps);
            await _reload();
          },
          onAsk: _ask(Bereich.schlaf),
          schlafzeiten: _schlafzeiten,
          bettzeit: _bettzeit,
          onSaveSchlafzeiten: (z) async {
            await widget.feed.saveSchlafzeiten(z);
            await _reload();
          },
        );
      case Bereich.mindset:
        final muster = sichtbareMuster(_muster);
        return MindsetTab(
          profile: widget.profile,
          fragen: _todayFragen(Bereich.mindset),
          onAsk: _ask(Bereich.mindset),
          durchgezogen: _durchgezogen,
          today: widget.clock(),
          onDurchAdd: _durchAdd,
          onDurchAlle: _durchAlle,
          extra: [
            if (muster.isNotEmpty) ...[
              const GroupLabel('Deine Muster'),
              MusterKarte(
                muster: muster.first,
                onAblehnen: () => _musterAblehnen(muster.first),
                onAlle: _oeffneMuster,
              ),
            ],
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.clock();
    final heute = TodayTab(
      name: widget.profile.name,
      date: germanDate(today),
      today: today,
      checkIns: _checkIns,
      training: _plan.forDay(today),
      fotoEinstellungen: _fotoEinstellungen,
      wochenFotos: _wochenFotos,
      onOpenZukunft: _oeffneZukunft,
      onOpenTag: _oeffneTag,
      heuteDran: _heuteBogen(),
      muster: sichtbareMuster(_muster),
      onMusterAblehnen: _musterAblehnen,
      onOpenMuster: _oeffneMuster,
      fokus: _fokusWidget(),
      coachAnsicht: _coachAnsicht,
      onCoachAnsicht: (a) {
        setState(() => _coachAnsicht = a);
        widget.feed.saveCoachAnsicht(a);
      },
      onStichpunkte: (c) async {
        final p = await widget.coach.stichpunkte(c.kiAntwort);
        if (p == null) return;
        await widget.store.saveCheckIn(c.withStichpunkte(p));
        await _reload();
      },
      bettzeit: _bettzeit,
      bereiche: [
        for (final b in Bereich.values)
          () {
            final (w, d) = _wert(b);
            return WurzelBereich(
              bereich: b,
              name: _namen[b]!,
              icon: _icons[b]!,
              wert: w,
              diff: d,
            );
          }(),
      ],
      onOpenBereich: _oeffneBereich,
      wurzeln: _fokusLaeuft ? _fokus!.anzahlGeschafft : 0,
      jubel: _jubel,
      jubelTick: _jubelTick,
      scroll: _heuteScroll,
      onRestartOnboarding: widget.onRestartOnboarding,
    );
    // The whole app is dark with beige and gold (Phillip 2026-10-18).
    return Scaffold(
      backgroundColor: CoachStyle.night,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: CoachStyle.nightGradient),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: CoachStyle.nightGlow),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                // Heute pads its own top part; the soil runs edge to edge.
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: _loaded
                      ? WerteScope(
                          checkIns: _checkIns,
                          today: today,
                          child: heute,
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: CoachStyle.gold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A pushed page in the app's dark look with a back arrow.
class _UnterSeite extends StatelessWidget {
  const _UnterSeite({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachStyle.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: CoachStyle.goldLight,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: CoachStyle.nightGradient),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// E.g. "Montag, 12. Oktober".
String germanDate(DateTime d) {
  const days = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];
  const months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  return '${days[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]}';
}
