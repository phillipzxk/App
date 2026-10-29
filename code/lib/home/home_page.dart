import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../data/diary_store.dart';
import '../data/user_profile.dart';
import '../ernaehrung/ernaehrung_coach.dart';
import '../ernaehrung/ernaehrung_logik.dart';
import '../ernaehrung/ernaehrung_stand.dart';
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
import '../schlaf/abend.dart';
import '../schlaf/schlaf_coach.dart';
import '../schlaf/schlaf_data.dart';
import '../schlaf/schlaf_logik.dart';
import '../schlaf/schlaf_widgets.dart';
import '../sleep/schlafzeiten.dart';
import '../sleep/sleep.dart';
import '../supplements/supplement_data.dart';
import '../training/training_coach.dart';
import '../training/training_data.dart';
import '../training/training_logik.dart';
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
import '../bereiche/bereich_seite.dart';
import '../bereiche/glas.dart';
import '../ernaehrung/einkaufsliste.dart';
import '../ernaehrung/heisshunger_seite.dart';
import '../ernaehrung/kochbuch.dart';
import '../ernaehrung/kuehlschrank.dart';
import '../ernaehrung/teller_foto.dart';
import '../schlaf/aufwachen.dart';
import '../schlaf/muster_tag.dart';
import '../schlaf/wecker_seite.dart';
import '../mindset/berg.dart';
import '../mindset/dranbleiben.dart';
import '../mindset/langfristig.dart';
import '../mindset/mindset_coach.dart';
import '../mindset/mindset_logik.dart';
import '../mindset/mindset_ui.dart';
import '../mindset/ruhe.dart';
import '../produktiv/produktiv_logik.dart';
import '../produktiv/produktiv_data.dart';
import '../produktiv/produktiv_seiten.dart';
import '../business/business_bilder.dart';
import '../business/business_coach.dart';
import '../business/business_logik.dart';
import '../business/business_seiten.dart';
import '../persoenlich/persoenlich_coach.dart';
import '../persoenlich/persoenlich_data.dart';
import '../persoenlich/persoenlich_logik.dart';
import '../persoenlich/persoenlich_seiten.dart';

part 'koerper_seite.dart';
part 'mindset_seite.dart';
part 'produktiv_seite.dart';
part 'business_seite.dart';
part 'persoenlich_seite.dart';

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
  TrainingDaten _training = const TrainingDaten();

  /// This week's plan with skipped and moved sessions.
  TrainingPlan get _woche => wochenPlan(_plan, _training, widget.clock());

  TrainingCoach get _trainingCoach => widget.coach is TrainingCoach
      ? widget.coach as TrainingCoach
      : const NoTrainingCoach();
  ErnaehrungCoach get _essenCoach => widget.coach is ErnaehrungCoach
      ? widget.coach as ErnaehrungCoach
      : const NoErnaehrungCoach();

  /// Everything of the Ernährung page (meals, cookbook, list, checks).
  late final _essen = ErnaehrungStand(widget.feed.saveErnaehrung)
    ..addListener(_essenGeaendert);
  void _essenGeaendert() {
    if (mounted) setState(() {});
  }

  SchlafCoach get _schlafCoach => widget.coach is SchlafCoach
      ? widget.coach as SchlafCoach
      : const NoSchlafCoach();

  /// Everything of Schlaf & Energie (mornings, journal, alarm, patterns).
  late final _schlaf = SchlafStand(widget.feed.saveSchlaf)
    ..addListener(_essenGeaendert);

  /// Everything of Mindset (stones, promises, values, letters, Lebensrad).
  late final _mindset = MindsetStand(widget.feed.saveMindset)
    ..addListener(_essenGeaendert);

  /// Everything of Produktivität (focus, blocks, urges, habits).
  late final _produktiv = ProduktivStand(widget.feed.saveProduktiv)
    ..addListener(_essenGeaendert);

  /// Everything of Business & Beruf.
  late final _business = BusinessStand(widget.feed.saveBusiness)
    ..addListener(_essenGeaendert);

  /// Everything of Persönlichkeit (care, look, learning).
  late final _persoenlich = PersoenlichStand(widget.feed.savePersoenlich)
    ..addListener(_essenGeaendert);

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

  /// The coach's "Dein Warum" sentence for today, null on a normal day.
  String? _warumSatz;
  String? _jubel;
  int _jubelTick = 0;
  final _heuteScroll = ScrollController();

  @override
  void dispose() {
    _heuteScroll.dispose();
    _essen.removeListener(_essenGeaendert);
    _essen.dispose();
    _schlaf.removeListener(_essenGeaendert);
    _schlaf.dispose();
    _mindset.removeListener(_essenGeaendert);
    _mindset.dispose();
    _produktiv.removeListener(_essenGeaendert);
    _produktiv.dispose();
    _business.removeListener(_essenGeaendert);
    _business.dispose();
    _persoenlich.removeListener(_essenGeaendert);
    _persoenlich.dispose();
    _stand.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// Pages opened from Heute (coach, focus) rebuild with every change too.
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _stand.value++;
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
    final warumHeute = await widget.feed.loadWarumHeute();
    final training = await widget.feed.loadTraining();
    final essen = await widget.feed.loadErnaehrung();
    final schlaf = await widget.feed.loadSchlaf();
    final mindset = await widget.feed.loadMindset();
    final produktiv = await widget.feed.loadProduktiv();
    final business = await widget.feed.loadBusiness();
    final persoenlich = await widget.feed.loadPersoenlich();
    if (!mounted) return;
    _essen.laden(essen.aufgeraeumt(widget.clock()));
    _schlaf.laden(schlaf);
    _mindset.laden(mindset);
    _produktiv.laden(produktiv);
    _business.laden(business);
    _persoenlich.laden(persoenlich);
    setState(() {
      _loaded = true;
      _checkIns = checkIns;
      _weights = weights;
      _sleep = sleep;
      _plan = plan;
      _training = training;
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
      _warumSatz = warumHeute?.tag == dayKey(widget.clock())
          ? warumHeute!.satz
          : null;
    });
    _stand.value++;
    _pruefeMuster(checkIns, muster);
    _pruefeDurchgezogen(checkIns, durchgezogen);
    _pruefeWarum(checkIns, warumHeute?.tag);
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

  /// Ticks today's focus on or off; ticking on lets the coach cheer.
  Future<void> _umschalten(Wochenfokus f) async {
    final neu = f.umschalten(widget.clock());
    await widget.feed.saveFokus(neu);
    final geschafft = neu.heuteGeschafft(widget.clock());
    // Scroll up first so the crown and the coach can be seen.
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
            'Das Wichtigste wächst unter der Oberfläche: '
            'Deine Wurzeln sind heute wieder tiefer geworden.';
      } else {
        _jubel = null;
      }
    });
    await _reload();
  }

  /// The full focus card or choice, on its own page (opened from the crown).
  Widget _fokusWidget(BuildContext seite) {
    final f = _fokus;
    if (f != null && !f.vorbei(widget.clock())) {
      return FokusKarte(
        fokus: f,
        today: widget.clock(),
        onUmschalten: () async {
          // Ticking on: back to Heute, where the tree cheers.
          if (!f.heuteGeschafft(widget.clock())) Navigator.of(seite).pop();
          await _umschalten(f);
        },
      );
    }
    final laedt = _fokusLaedt || !_fokusVersucht;
    return FokusWahl(
      auswahl: _fokusAuswahl,
      laedt: laedt,
      onStart: (v) async {
        await _starteFokus(v);
        if (seite.mounted) Navigator.of(seite).pop();
      },
      onNochmal: _holeFokusVorschlaege,
    );
  }

  /// The Reality Check is due: the week ran out (Umsetzung/Reality Check).
  bool get _realityFaellig => _fokus != null && !_fokusLaeuft;

  /// What the round Fokus field in the crown shows.
  Widget _fokusFeld() {
    final f = _fokus;
    final label = CoachStyle.goldLabel.copyWith(
      fontFamily: 'Sora',
      fontSize: 8.5,
      letterSpacing: 1.4,
      color: CoachStyle.gold,
    );
    final titel = CoachStyle.body.copyWith(
      fontSize: 12.5,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFF6EEDD),
    );
    final klein = CoachStyle.body.copyWith(
      fontSize: 10.5,
      color: CoachStyle.beigeLabel,
    );
    if (f != null && _fokusLaeuft) {
      final heute = widget.clock();
      final tag = f.tag(heute).clamp(1, Wochenfokus.tage);
      final striche = f.striche;
      final geschafft = f.heuteGeschafft(heute);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('FOKUS · TAG $tag/${Wochenfokus.tage}', style: label),
          const SizedBox(height: 5),
          Text(
            f.text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titel,
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < Wochenfokus.tage; i++)
                Container(
                  width: 8,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1.3),
                  decoration: BoxDecoration(
                    gradient: striche[i] ? CoachStyle.goldGradient : null,
                    color: striche[i]
                        ? null
                        : i < tag
                        ? const Color(0xFF4A3D2E)
                        : const Color(0xFF2E251B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            key: const ValueKey('fokus-heute'),
            onTap: () => _umschalten(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                gradient: geschafft ? null : CoachStyle.goldGradient,
                borderRadius: BorderRadius.circular(20),
                border: geschafft
                    ? Border.all(color: CoachStyle.goldEdge)
                    : null,
              ),
              child: Text(
                geschafft ? '✓ Geschafft' : 'Heute geschafft',
                maxLines: 1,
                softWrap: false,
                style: CoachStyle.body.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: geschafft
                      ? CoachStyle.goldLight
                      : const Color(0xFF1A140E),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_realityFaellig) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('NEUE WOCHE', style: label),
          const SizedBox(height: 6),
          Text(
            'Erst dein\nReality Check',
            textAlign: TextAlign.center,
            style: titel,
          ),
          const SizedBox(height: 6),
          Text(
            _fokusAuswahl == null ? 'Coach schaut zurück …' : 'Öffnen ›',
            style: klein,
          ),
        ],
      );
    }
    final laedt = _fokusLaedt || !_fokusVersucht;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('FOKUS DER WOCHE', style: label),
        const SizedBox(height: 6),
        Text(
          laedt ? 'Dein Coach sucht\nVorschläge …' : 'Wähl deinen\nFokus',
          textAlign: TextAlign.center,
          style: titel,
        ),
        const SizedBox(height: 6),
        Text(laedt ? '' : '3 Vorschläge ›', style: klein),
      ],
    );
  }

  void _oeffneFokus(Offset mitte) {
    if (_realityFaellig) {
      final a = _fokusAuswahl;
      if (a == null) {
        _holeFokusVorschlaege();
      } else {
        _oeffneReality(a);
      }
      return;
    }
    oeffneMitKreis(
      context,
      mitte,
      (seite) => _UnterSeite(
        child: _lebendig(
          () => NightScope(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                PageHeader(
                  label: germanDate(widget.clock()),
                  title: 'Fokus der Woche',
                ),
                _fokusWidget(seite),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A pattern found in the last two days counts as new: it shows on Heute.
  Muster? get _neuesMuster {
    final sichtbar = sichtbareMuster(_muster);
    if (sichtbar.isEmpty) return null;
    final m = sichtbar.first;
    final t = widget.clock();
    final d = DateTime(m.datum.year, m.datum.month, m.datum.day);
    return DateTime(t.year, t.month, t.day).difference(d).inDays <= 2
        ? m
        : null;
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

  bool _warumPrueft = false;

  /// Once per day after the check-in the coach decides whether the user is
  /// in a weak phase; then "Dein Warum" shows on Heute (vault
  /// Umsetzung/Dein Warum.md).
  Future<void> _pruefeWarum(List<CheckIn> checkIns, String? geprueft) async {
    final today = widget.clock();
    final key = dayKey(today);
    if (_warumPrueft || geprueft == key) return;
    if (widget.profile.motivation.trim().isEmpty) return;
    final heute = checkIns.where((c) => dayKey(c.datum) == key).toList();
    if (heute.isEmpty) return;
    _warumPrueft = true;
    final satz = await widget.coach.warumSatz(
      widget.profile,
      heute.last,
      checkIns.length > 6 ? checkIns.sublist(checkIns.length - 6) : checkIns,
    );
    _warumPrueft = false;
    await widget.feed.saveWarumHeute(today, satz);
    if (!mounted) return;
    setState(() => _warumSatz = satz);
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
          for (final e in _training.einheiten.reversed.take(3))
            'Eingetragen ${dayKey(e.datum)} (${e.name}): ${e.status == EinheitStatus.uebersprungen ? 'übersprungen, ${e.grund ?? ''}' : e.uebungen.map((u) => '${u.name} ${u.fertige.map((x) => satzText(u.art, x.werte)).join(', ')}${u.gefuehl == null ? '' : ' (${u.gefuehl})'}').join('; ')}',
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
          schlafKontext(_schlaf.d, widget.clock()),
          for (final m in sichtbareSchlafMuster(_schlaf.d))
            'Erkanntes Muster: ${m.text}',
        ];
        return lines.where((l) => l.trim().isNotEmpty).join('\n');
      case Bereich.mindset:
        return '';
    }
  }

  Bettzeit? get _bettzeit =>
      bettzeitFuer(_schlafzeiten, widget.clock(), _termine);

  SchlafUmfeld get _schlafUmfeld {
    final jetzt = widget.clock();
    final training = _woche.forDay(jetzt).trim();
    return SchlafUmfeld(
      stand: _schlaf,
      profile: widget.profile,
      coach: _schlafCoach,
      jetzt: widget.clock,
      zeiten: _schlafzeiten,
      bett: _bettzeit?.bett,
      weckzeit: _bettzeit?.aufstehen,
      tagText: _essenTagText,
      onMorgen: (h) async {
        await widget.store.saveSleep(SleepEntry(widget.clock(), h));
        await _reload();
      },
      routine: [for (final r in _routine) (r.zeit, r.was)],
      training: _tagRahmen.training,
      trainingName: training.isEmpty ? null : shortDay(training),
      mahlzeiten: [for (final m in _mahlzeitSlots) (m.minute, m.name)],
      termine: [
        for (final t in termineAm(_termine, jetzt))
          if (parseUhrzeit(t.zeit ?? '') case final m?) (m, t.text),
      ],
    );
  }

  int? get _kcalZiel {
    final p = _kcal;
    if (p == null || _weights.isEmpty) return null;
    return kcalZiel(p, _weights.last.kg) + _essen.d.kcalAnpassung;
  }

  /// Today's start and end (minutes) and training time for the meals.
  ({int start, int ende, int? training}) get _tagRahmen {
    final jetzt = widget.clock();
    final start = _schlafzeiten.aufstehenAm(jetzt) ?? 7 * 60;
    var ende = _bettzeit?.bett ?? 23 * 60;
    if (ende <= start) ende += 1440;
    return (
      start: start,
      ende: ende,
      training: trainingZeit(_woche.forDay(jetzt).trim()),
    );
  }

  /// Today's meals: placed around training, moved by the user.
  List<MahlzeitSlot> get _mahlzeitSlots {
    final r = _tagRahmen;
    return planeMahlzeiten(
      anzahl: _mahlzeiten ?? 0,
      start: r.start,
      ende: r.ende,
      training: r.training,
      verschoben: _essen.d.verschoben[dayKey(widget.clock())] ?? const {},
    );
  }

  EssenUmfeld get _essenUmfeld => EssenUmfeld(
    stand: _essen,
    profile: widget.profile,
    coach: _essenCoach,
    jetzt: widget.clock,
    mahlzeiten: () => _mahlzeitSlots,
    tagText: _essenTagText,
    musterText: _essenMusterText,
    training: _tagRahmen.training,
  );

  String _essenTagText() {
    final jetzt = widget.clock();
    final training = _woche.forDay(jetzt).trim();
    final eintraege = _essen.d.tag(dayKey(jetzt));
    final ziel = _kcalZiel;
    return [
      'Jetzt: ${formatUhrzeit(jetzt.hour * 60 + jetzt.minute)}',
      training.isEmpty
          ? 'Heute kein Training.'
          : 'Training heute: ${shortDay(training)}',
      if (ziel != null) 'kcal-Ziel (nur Orientierung): $ziel',
      for (final m in _mahlzeitSlots)
        '${m.name} ${m.uhrzeit}: ${eintraege[m.id]?.gegessen == true ? 'gegessen${eintraege[m.id]!.gefuehl == null ? '' : ', ${eintraege[m.id]!.gefuehl}'}' : 'noch offen'}',
    ].join('\n');
  }

  String _essenMusterText() {
    final d = _essen.d;
    return [
      for (final h in d.heisshunger.reversed.take(10))
        'Heißhunger ${dayKey(h.zeit)} ${formatUhrzeit(h.zeit.hour * 60 + h.zeit.minute)}: ${h.grund}',
      for (final c in _checkIns.reversed.take(10))
        if (c.ernaehrung.isNotEmpty)
          'Check-in ${dayKey(c.datum)}: ${c.ernaehrung}',
      for (final e in _sleep.reversed.take(7))
        'Schlaf ${dayKey(e.datum)}: ${e.stunden} h',
    ].join('\n');
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
          if (_training.einheitAm(d)?.status == EinheitStatus.fertig) {
            return true;
          }
          final a = c?.training.trim() ?? '';
          if (a.isNotEmpty && !a.startsWith('Pause')) return true;
          final p = _woche.tage[i].trim();
          return p.isNotEmpty && !ruhe.hasMatch(p) ? false : null;
        }(),
    ];
  }

  /// Two short facts for the info card next to an area on "Heute", taken
  /// from the area's first two tiles (draft B, Phillip 2026-10-25).
  List<(String, String)> _infos(Bereich b) {
    final k = _daten(b).kacheln;
    String kurz(String t) => switch (t) {
      'Heute ins Bett' => 'Bett',
      'Nächte' => 'Ø',
      'kcal-Ziel' => 'Ziel',
      _ => t,
    };
    if (b == Bereich.mindset) {
      return [(k[0].titel, k[0].wert), ('Dein Warum', '›')];
    }
    return [for (final x in k.take(2)) (kurz(x.titel), x.wert)];
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
        final tag = _woche.forDay(today);
        final name = shortDay(tag);
        final uebungen = [
          for (final l in dayDetails(tag).split('\n'))
            if (l.trim().isNotEmpty) l.trim(),
        ];
        final woche = _trainingsWoche();
        final gemacht = woche.where((x) => x == true).length;
        final ruhe = RegExp(r'^(ruhe|pause|frei|off\b)', caseSensitive: false);
        final geplant = _woche.tage
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
        final morgen = _schlaf.d.morgenAm(dayKey(today));
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
            wert: morgen != null
                ? '${morgen.wert}'
                : naechte.isEmpty
                ? 'Eintragen'
                : '${_komma(naechte.reduce((a, b) => a + b) / naechte.length)} h',
            unter: morgen != null
                ? 'Schlafwert heute'
                : naechte.isEmpty
                ? 'wie lange du schläfst'
                : 'Schnitt',
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

  /// The five roots on Heute (vault Home-Schichten, Glas-Look
  /// 2026-10-28): Körper with its 3 parts, Produktivität & Fokus, Business
  /// & Beruf, Persönlichkeit and Mindset.
  List<WurzelBereich> _wurzeln(DateTime today) {
    final koerper = [Bereich.training, Bereich.ernaehrung, Bereich.schlaf];
    int? schnitt(List<int?> l) {
      final da = [for (final x in l) ?x];
      return da.isEmpty
          ? null
          : (da.reduce((a, b) => a + b) / da.length).round();
    }

    final kw = schnitt([for (final b in koerper) _wert(b).$1]);
    final kd = schnitt([for (final b in koerper) _wert(b).$2]);
    final kWoche = [
      for (var i = 0; i < 7; i++)
        schnitt([
          for (final b in koerper) werteVerlauf(_checkIns, b, today, 7)[i],
        ]),
    ];
    // The coach's sentence of the weakest part.
    Bereich? schwach;
    for (final b in koerper) {
      final w = _wert(b).$1;
      if (w == null) continue;
      if (schwach == null || w < _wert(schwach).$1!) schwach = b;
    }
    (int?, int?) diff(List<int?> woche) => (
      woche.last,
      woche.last == null || woche[woche.length - 2] == null
          ? null
          : woche.last! - woche[woche.length - 2]!,
    );
    final heute = dayKey(today);
    final p = _produktiv.d;
    final pWoche = [
      for (var i = 6; i >= 0; i--)
        produktivWert(p, dayKey(today.subtract(Duration(days: i)))),
    ];
    final pf = p.fokusAm(heute);
    final bz = _business.d;
    final bWoche = [
      for (var i = 6; i >= 0; i--)
        businessWert(bz, today.subtract(Duration(days: i))),
    ];
    final h = bz.hebelIn(dayKey(montagVon(today)));
    final pe = _persoenlich.d;
    final peWoche = [
      for (var i = 6; i >= 0; i--)
        persoenlichWert(pe, dayKey(today.subtract(Duration(days: i)))),
    ];
    final (mw, md) = _wert(Bereich.mindset);
    final steine = _mindset.d.offeneSteine;
    return [
      WurzelBereich(
        id: 'koerper',
        name: 'Körper',
        icon: Icons.fitness_center,
        wert: kw,
        diff: kd,
        grund: schwach == null ? null : _heute?.gruende[schwach.name],
        woche: kWoche,
        teile: const ['Training', 'Ernährung', 'Schlaf & Routine'],
      ),
      WurzelBereich(
        id: 'produktiv',
        name: 'Produktivität & Fokus',
        icon: Icons.bolt,
        wert: diff(pWoche).$1,
        diff: diff(pWoche).$2,
        woche: pWoche,
        grund: pf == null
            ? 'Noch keine Sache festgelegt, die heute zählt.'
            : pf.erledigt
            ? 'Die eine Sache heute ist geschafft.'
            : null,
        infos: [if (pf != null) ('Fokus', pf.text)],
      ),
      WurzelBereich(
        id: 'business',
        name: 'Business & Beruf',
        icon: Icons.work_outline,
        wert: diff(bWoche).$1,
        diff: diff(bWoche).$2,
        woche: bWoche,
        infos: [
          if (h != null) ('Hebel', '${h.erledigt} von ${h.punkte.length}'),
          if (bz.ziele[monatVon(today)] case final z?)
            ('Umsatz', '${euro(umsatzIm(bz, monatVon(today)))} von ${euro(z)}'),
        ],
        grund: h == null ? 'Noch kein Hebel für diese Woche.' : null,
      ),
      WurzelBereich(
        id: 'persoenlich',
        name: 'Persönlichkeit',
        icon: Icons.person_outline,
        wert: diff(peWoche).$1,
        diff: diff(peWoche).$2,
        woche: peWoche,
        infos: [
          (
            'Pflege',
            '${morgensErledigt(pe, heute)} von ${pe.morgens.length} morgens',
          ),
          if (pe.kurs?.aktuelle case final l?) ('Lernen', l.titel),
        ],
      ),
      WurzelBereich(
        id: 'mindset',
        name: 'Mindset',
        icon: Icons.landscape,
        wert: mw,
        diff: md,
        grund: _heute?.gruende[Bereich.mindset.name],
        woche: werteVerlauf(_checkIns, Bereich.mindset, today, 7),
        infos: [
          if (steine.isNotEmpty) ('Dein Berg', steine.first.titel),
          ..._infos(Bereich.mindset).take(steine.isEmpty ? 2 : 1),
        ],
      ),
    ];
  }

  /// "Deine Lebensziele" at the end of the tap root.
  Widget _lebenszieleKarte() {
    final z = _mindset.d.ziele;
    return GestureDetector(
      key: const ValueKey('lebensziele'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _lebendig(
            () => FeldSeite(
              bereich: 'Mindset',
              feld: Feld(
                titel: 'Deine Lebensziele',
                icon: Icons.brightness_7_outlined,
                coach:
                    'Ganz unten, wo alle Wurzeln hinführen. Groß gedacht, '
                    'aus allen Bereichen.',
                inhalt: (_) => [ZieleSeite(u: _mindsetUmfeld)],
              ),
            ),
          ),
        ),
      ),
      child: GlasBox(
        art: GlasArt.gold,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: CoachStyle.goldGradient,
                boxShadow: CoachStyle.goldGlow,
              ),
            ),
            const SizedBox(height: 8),
            Text('Ganz unten', style: Glas.tSoft.copyWith(fontSize: 12)),
            GoldSchrift(
              'Deine Lebensziele',
              style: Glas.tBig.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            if (z.isEmpty)
              Text(
                'Tippen und aufschreiben, was du im Leben erreichen willst',
                textAlign: TextAlign.center,
                style: Glas.tSoft,
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final x in z.take(4))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0x55E0BF7E)),
                      ),
                      child: Text(
                        x.text,
                        style: Glas.tLabel.copyWith(fontSize: 12),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _oeffneBereich(String id, Offset mitte) => oeffneMitKreis(
    context,
    mitte,
    (_) => _lebendig(switch (id) {
      'mindset' => _mindsetSeite,
      'produktiv' => _produktivSeite,
      'business' => _businessSeite,
      'persoenlich' => _persoenlichSeite,
      // Training, Ernährung and Schlaf & Routine live in Körper now
      // (vault Umsetzung/Körper komplett, Entwurf 3, 2026-10-29).
      _ => () => _koerperSeite(Bereich.training),
    }),
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
    final training = _woche.forDay(jetzt).trim();
    final trZeit = trainingZeit(training);
    final gegessen = _essen.d.tag(dayKey(jetzt));
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
      for (final m in _mahlzeitSlots)
        BogenPunkt(
          id: 'mahlzeit-${m.id}',
          minute: m.minute,
          art: 'Essen',
          titel: m.name,
          text: gegessen[m.id]?.gegessen == true ? 'gegessen' : null,
          erledigt: gegessen[m.id]?.gegessen == true,
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
      if (_schlaf.d.ablauf case final a?
          when a.uebernommen && a.tag == dayKey(jetzt))
        for (final p in a.punkte)
          if (p.neu)
            BogenPunkt(
              id: 'coach-${p.minute}',
              minute: p.minute < start ? p.minute + 1440 : p.minute,
              art: 'Coach',
              titel: p.was,
              text: p.warum,
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
      punkte: t.punkte,
      start: t.start,
      ende: t.ende,
      jetzt: _jetztMinute,
      ohneZeit: t.ohneZeit,
      rund: true,
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
                if (_schlaf.d.journalAm(SchlafDaten.gestern(widget.clock()))
                    case final j? when j.besser.any((x) => x.isNotEmpty))
                  FeedCard(
                    key: const ValueKey('besser-heute'),
                    title: 'Heute besser machen',
                    icon: Icons.auto_awesome,
                    children: [
                      for (final b in j.besser)
                        if (b.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(b, style: CoachStyle.body),
                          ),
                      const HintText('Aus deinem Abend-Journal von gestern.'),
                    ],
                  ),
                DayPlanCard(
                  today: widget.clock(),
                  termine: _termine,
                  training: _woche.forDay(widget.clock()),
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

  Widget _seite(Bereich b, {String? teil}) {
    switch (b) {
      case Bereich.training:
        return TrainingTab(
          teil: teil,
          profile: widget.profile,
          feed: widget.feed,
          coach: _trainingCoach,
          checkIns: _checkIns,
          onGeaendert: _reload,
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
        final r = _tagRahmen;
        return NutritionTab(
          teil: teil,
          umfeld: _essenUmfeld,
          mahlzeiten: _mahlzeitSlots,
          anzahl: _mahlzeiten,
          start: r.start,
          ende: r.ende,
          training: r.training,
          trainingName: shortDay(_woche.forDay(widget.clock()).trim()),
          onSetMahlzeiten: (n) async {
            await widget.feed.saveMahlzeiten(n);
            await _reload();
          },
          kcal: _kcal,
          kcalHeute: _kcalZiel,
          sleep: _sleep,
          checkIns: _checkIns,
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
          teil: teil,
          umfeld: _schlafUmfeld,
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
      heuteDran: _heuteBogen(),
      fokusFeld: _fokusFeld(),
      onOpenTag: (_) => _oeffneTag(),
      onOpenFokus: _oeffneFokus,
      fokusKey: _realityFaellig && _fokusAuswahl != null
          ? const ValueKey('reality-feld')
          : null,
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
      warum: widget.profile.motivation,
      warumSatz: _warumSatz,
      muster: sichtbareMuster(_muster).firstOrNull,
      musterNeu: _neuesMuster != null,
      fotoFeld: FotoFeld(
        today: today,
        einstellungen: _fotoEinstellungen,
        fotos: _wochenFotos,
        onOpen: _oeffneZukunft,
      ),
      onOpenMuster: _oeffneMuster,
      bereiche: _wurzeln(today),
      lebensziele: _lebenszieleKarte(),
      onOpenBereich: _oeffneBereich,
      wurzeln: _fokusLaeuft ? _fokus!.anzahlGeschafft : 0,
      jubel: _jubel,
      jubelTick: _jubelTick,
      scroll: _heuteScroll,
      onRestartOnboarding: widget.onRestartOnboarding,
    );
    final ruhe = _schlaf.d.ruheBis;
    if (_loaded && ruhe != null && ruhe.isAfter(today)) {
      return RuheSchirm(umfeld: _schlafUmfeld, bis: ruhe);
    }
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
