import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../schlaf/abend.dart';
import '../schlaf/aufwachen.dart';
import '../schlaf/muster_tag.dart';
import '../schlaf/schlaf_data.dart';
import '../schlaf/schlaf_logik.dart';
import '../schlaf/schlaf_widgets.dart';
import '../schlaf/wecker_seite.dart';
import '../sleep/schlafzeiten.dart';
import '../sleep/sleep.dart';
import '../sleep/sleep_chart.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'bereichs_werte.dart';
import 'feed_widgets.dart';

/// Schlaf & Energie page (vault Umsetzung/Schlaf und Energie komplett.md,
/// Phillip 2026-10-27): under its own sky the morning entry, the
/// Schlafwert with the Schlaf-Mond, today's energy forecast, what only
/// applies to you, alarm, bedtime, evening journal and the coach's day.
/// Below the basics: sleep times, evening routine, the ask field and the
/// nights.
class SleepTab extends StatefulWidget {
  const SleepTab({
    super.key,
    required this.umfeld,
    required this.routine,
    required this.sleep,
    required this.today,
    required this.fragen,
    required this.onSaveRoutine,
    required this.onAddSleep,
    required this.onAsk,
    this.schlafzeiten = const Schlafzeiten(),
    this.bettzeit,
    this.onSaveSchlafzeiten,
    this.teil,
  });

  /// Only one part for the glass area page: 'wert', 'energie', 'naechte',
  /// 'zeiten', 'routine', 'daten'. Null = the whole old page.
  final String? teil;

  final SchlafUmfeld umfeld;
  final Schlafzeiten schlafzeiten;

  /// Tonight's bedtime, null until a wake-up time is set.
  final Bettzeit? bettzeit;
  final Future<void> Function(Schlafzeiten z)? onSaveSchlafzeiten;

  final List<RoutineStep> routine;
  final List<SleepEntry> sleep;
  final DateTime today;
  final VoidCallback onAddSleep;
  final List<CoachFrage> fragen;
  final Future<void> Function(List<RoutineStep> steps) onSaveRoutine;
  final Future<void> Function(String text) onAsk;

  @override
  State<SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends State<SleepTab> {
  SchlafUmfeld get u => widget.umfeld;

  @override
  void initState() {
    super.initState();
    _holen();
  }

  Future<void> _holen() async {
    await u.holeEnergieSatz();
    await u.holeMuster();
  }

  Future<void> _edit(BuildContext context) async {
    final saved = await Navigator.of(context).push<List<RoutineStep>>(
      MaterialPageRoute(builder: (_) => RoutineEditor(steps: widget.routine)),
    );
    if (saved != null) await widget.onSaveRoutine(saved);
  }

  void _zeige(Widget seite) => zeigeSchlafSeite(context, seite);

  @override
  Widget build(BuildContext context) {
    final liste = ListenableBuilder(
      listenable: u.stand,
      builder: (context, _) => _liste(context),
    );
    if (widget.teil != null) return liste;
    return SchlafHimmel(
      phase: himmelPhase(u.jetzt(), u.zeiten.aufstehenAm(u.jetzt())),
      child: liste,
    );
  }

  Widget _liste(BuildContext context) {
    final d = u.d;
    final heute = d.morgenAm(u.heute);
    final fuell = mondFuell(d.morgen, u.jetzt());
    final e = u.energieHeute();
    final jetzt = u.jetzt();
    final muster = sichtbareSchlafMuster(d);
    final journal = d.journalAm(u.heute);
    final ablauf = d.ablauf?.tag == u.heute ? d.ablauf : null;
    final bz = widget.bettzeit;
    final routine = widget.routine;
    final nacht = [
      for (final m in d.morgen)
        if (!DateTime.parse(m.tag)
            .isBefore(DateTime(jetzt.year, jetzt.month, jetzt.day - 13)))
          m,
    ];
    final alles = widget.teil == null;
    bool zeig(String t) => alles || widget.teil == t;
    final kinder = <Widget>[
      if (alles) ...[
        const PageHeader(
          label: 'Bereich',
          title: 'Schlaf & Energie',
          icon: Icons.bedtime,
        ),
        const AreaChart(bereich: Bereich.schlaf),
      ],
      if (!zeig('wert'))
        const SizedBox.shrink()
      else if (heute == null)
        TKarte(
          key: const ValueKey('wie-geschlafen'),
          gold: true,
          child: InkWell(
            onTap: () => _zeige(AufwachSeite(umfeld: u)),
            child: Row(
              children: [
                const Icon(
                  Icons.wb_twilight,
                  size: 30,
                  color: CoachStyle.goldLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wie hast du geschlafen?',
                        style: tTitel.copyWith(fontSize: 15),
                      ),
                      const Text(
                        'Aufwach-Himmel und kurz, was nachts war. Daraus '
                        'kommt dein Schlafwert.',
                        style: tSoft,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: CoachStyle.goldLight),
              ],
            ),
          ),
        )
      else
        TKarte(
          key: const ValueKey('schlafwert-seite'),
          gold: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      SchlafMond(fuell: fuell ?? heute.wert / 100, size: 92),
                      const SizedBox(height: 4),
                      const Text('Schlaf-Mond', style: tSoft),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TLabel('Dein Schlafwert'),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 6,
                          children: [
                            GoldText(
                              '${heute.wert}',
                              key: const ValueKey('schlafwert-zahl'),
                              style: tTitel.copyWith(fontSize: 40),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text('von 100', style: tSoft),
                            ),
                          ],
                        ),
                        Text(
                          '${formatDauer(heute.stunden)}, '
                          '${himmelWort(heute.himmel).toLowerCase()} aufgewacht.',
                          style: tSoft,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final t in teilNamen.entries)
                TeilZeile(
                  name: t.value,
                  wert: heute.teile[t.key] ?? 0,
                  text: teilText(t.key, heute),
                ),
              const SizedBox(height: 8),
              CoachZeile(text: heute.satz ?? mondSatz(fuell ?? .5)),
              if (heute.satz != null && fuell != null) ...[
                const SizedBox(height: 6),
                Text(mondSatz(fuell), style: tSoft),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TLink(
                  'Deine Nacht ansehen ›',
                  key: const ValueKey('morgen-oeffnen'),
                  onTap: () => _zeige(AufwachSeite(umfeld: u)),
                ),
              ),
            ],
          ),
        ),
      if (zeig('energie'))
        TKarte(
          key: const ValueKey('energie-heute'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Expanded(child: TLabel('Deine Energie heute')),
                  Text('Vorhersage', style: tSoft),
                ],
              ),
              const SizedBox(height: 6),
              EnergieVorhersage(
                werte: e.werte,
                hoch: e.hoch,
                jetzt: jetzt.hour * 60 + jetzt.minute,
                training: u.training,
              ),
              const SizedBox(height: 8),
              CoachZeile(
                text: d.energieSatz?.tag == u.heute
                    ? d.energieSatz!.satz
                    : energieSatzOhneCoach(
                        hoch: e.hoch,
                        tief: e.tief,
                        training: u.training,
                        wert: heute?.wert,
                      ),
              ),
              const SizedBox(height: 12),
              const TLabel('Wie war deine Energie wirklich?'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final w in const [
                    'Wie vorhergesagt',
                    'Besser',
                    'Schlechter',
                  ])
                    TChip(
                      w,
                      key: ValueKey('energie-$w'),
                      an: d.energieAm(u.heute) == w,
                      onTap: () => u.stand.setze(
                        d.mitEnergie(EnergieMeldung(tag: u.heute, wie: w)),
                      ),
                    ),
                ],
              ),
              if (d.energieAm(u.heute) != null)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Gemerkt. Daraus lernt der Coach deine eigene Kurve.',
                    style: tSoft,
                  ),
                ),
            ],
          ),
        ),
      if (alles)
        TKarte(
          key: const ValueKey('erkannt'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TLabel('Erkannt bei dir'),
              if (muster.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    d.morgen.length < 14
                        ? 'Nach 14 Morgen schaut der Coach, was nur bei dir gilt. '
                              'Noch ${14 - d.morgen.length}.'
                        : 'Gerade ist nichts klar zu sehen.',
                    style: tSoft,
                  ),
                )
              else
                for (final m in muster.take(2)) MusterZeile(m: m),
              Align(
                alignment: Alignment.centerLeft,
                child: TLink(
                  'Alles, was nur bei dir gilt ›',
                  key: const ValueKey('muster-oeffnen'),
                  onTap: () => _zeige(SchlafMusterSeite(umfeld: u)),
                ),
              ),
            ],
          ),
        ),
      if (alles)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _Kachel(
              key: const ValueKey('kachel-wecker'),
              label: 'Wecker',
              wert: u.weckzeit == null ? '–' : formatUhrzeit(u.weckzeit!),
              text: weckerKurz(d.wecker),
              onTap: () => _zeige(WeckerSeite(umfeld: u)),
            ),
            _Kachel(
              key: const ValueKey('kachel-bett'),
              label: 'Heute ins Bett',
              wert: bz == null ? '–' : formatUhrzeit(bz.bett),
              text: routine.isEmpty
                  ? 'Gute Nacht über das Journal'
                  : 'Routine ab ${routine.first.zeit}',
              onTap: () => _zeige(AbendSeite(umfeld: u)),
            ),
            _Kachel(
              key: const ValueKey('kachel-journal'),
              label: 'Abend-Journal',
              wert: journal?.guteNacht != null
                  ? 'Fertig'
                  : (journal?.fertig ?? false)
                  ? 'Bereit'
                  : 'Offen',
              text: '3 dankbar, 3 besser',
              onTap: () => _zeige(AbendSeite(umfeld: u)),
            ),
            _Kachel(
              key: const ValueKey('kachel-tag'),
              label: 'Dein Tag',
              wert: ablauf?.uebernommen == true ? 'Übernommen' : 'Vom Coach',
              text: 'bester Ablauf heute',
              onTap: () => _zeige(TagesablaufSeite(umfeld: u)),
            ),
          ],
        ),
      if (alles) const SizedBox(height: 12),
      if (zeig('naechte') && nacht.length >= 2)
        TKarte(
          key: const ValueKey('naechte-wert'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Expanded(child: TLabel('Letzte Nächte')),
                  Text('Schlafwert', style: tSoft),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final m in nacht)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            height: 60 * m.wert / 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: m.wert >= 75
                                  ? CoachStyle.goldGradient
                                  : null,
                              color: m.wert >= 75
                                  ? null
                                  : const Color(0xFF4A3B2A),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (alles) const GroupLabel('Deine Basis'),
      if (zeig('zeiten'))
        SchlafzeitenKarte(
          zeiten: widget.schlafzeiten,
          bettzeit: bz,
          onSave: widget.onSaveSchlafzeiten,
        ),
      if (zeig('routine'))
        FeedCard(
          title: 'Deine Abendroutine',
          icon: Icons.nightlight_outlined,
          gold: true,
          children: [
            if (routine.isEmpty)
              const HintText('Leg einmal fest, wie dein Abend aussieht.')
            else
              for (final s in routine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          s.zeit,
                          style: CoachStyle.body.copyWith(
                            color: CoachStyle.gold,
                          ),
                        ),
                      ),
                      Expanded(child: Text(s.was, style: CoachStyle.body)),
                    ],
                  ),
                ),
            const SizedBox(height: 12),
            GhostButton(
              label: routine.isEmpty
                  ? 'Abendroutine festlegen'
                  : 'Routine bearbeiten',
              onPressed: () => _edit(context),
            ),
          ],
        ),
      if (alles) const GroupLabel('Frag deinen Coach'),
      if (alles)
        AskCoachCard(
          title: 'Frag zu deinem Schlaf',
          hint: 'Was stört dich gerade beim Schlafen?',
          today: widget.fragen,
          onSend: widget.onAsk,
        ),
      if (alles) const GroupLabel('Deine Werte'),
      if (zeig('naechte'))
        SleepCard(
          entries: widget.sleep,
          today: widget.today,
          onAdd: widget.onAddSleep,
        ),
      if (zeig('daten'))
        TKarte(
          key: const ValueKey('mehr-daten'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TLabel('Mehr Daten für deinen Schlafwert'),
              const SizedBox(height: 6),
              for (final o in const [
                ('Apple Health', 'Schlafphasen, Puls, Herzratenvariabilität'),
                ('Google Health Connect', 'für Android-Handys und Uhren'),
                (
                  'Deine Uhr oder dein Ring',
                  'zum Beispiel Apple Watch, Garmin, Oura',
                ),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.$1, style: tText),
                            Text(o.$2, style: tSoft),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4A3B2A)),
                        ),
                        child: const Text(
                          'Handy-Version',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 10.5,
                            color: CoachStyle.beigeLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                'Bis dahin kommt der Schlafwert aus allem, was du angibst: '
                'Aufwach-Himmel, was nachts war, Schlafzeiten, Bettzeit '
                'eingehalten, Abend-Journal, Check-in.',
                style: tSoft,
              ),
            ],
          ),
        ),
    ];
    if (!alles) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: kinder,
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: kinder,
    );
  }
}

class _Kachel extends StatelessWidget {
  const _Kachel({
    super.key,
    required this.label,
    required this.wert,
    required this.text,
    required this.onTap,
  });
  final String label, wert, text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xCC1E1710),
        border: Border.all(color: const Color(0xFF3A2E21)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TLabel(label),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              wert,
              style: tTitel.copyWith(
                fontSize: 20,
                color: const Color(0xFFF5DFAE),
              ),
            ),
          ),
          Text(
            text,
            style: tSoft,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

/// "Deine Schlafzeiten": wake-up time Mon-Fri and Sat/Sun and hours of
/// sleep, each set once; below it tonight's bedtime.
class SchlafzeitenKarte extends StatelessWidget {
  const SchlafzeitenKarte({
    super.key,
    required this.zeiten,
    required this.bettzeit,
    required this.onSave,
  });

  final Schlafzeiten zeiten;
  final Bettzeit? bettzeit;
  final Future<void> Function(Schlafzeiten z)? onSave;

  Future<void> _zeit(
    BuildContext context,
    String titel,
    int? jetzt,
    Schlafzeiten Function(int m) neu,
  ) async {
    final m = await showDialog<int>(
      context: context,
      builder: (_) => _UhrzeitDialog(titel: titel, jetzt: jetzt),
    );
    if (m != null) await onSave?.call(neu(m));
  }

  Future<void> _stunden(BuildContext context) async {
    final h = await showDialog<double>(
      context: context,
      builder: (_) => const SleepDialog(
        titel: 'Wie viele Stunden Schlaf brauchst du pro Nacht?',
      ),
    );
    if (h != null) await onSave?.call(zeiten.copyWith(stunden: h));
  }

  @override
  Widget build(BuildContext context) {
    Widget zeile(
      String key,
      String label,
      String wert,
      VoidCallback onTap, {
      bool last = false,
    }) => InkWell(
      key: ValueKey(key),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: CoachStyle.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
              ),
            ),
            Text(
              wert,
              style: CoachStyle.cardTitle.copyWith(
                fontSize: 16,
                color: const Color(0xFFF5DFAE),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              wert == '–' ? 'Festlegen' : 'Ändern',
              style: CoachStyle.body.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: CoachStyle.goldLight,
              ),
            ),
          ],
        ),
      ),
    );
    String uhr(int? m) => m == null ? '–' : formatUhrzeit(m);
    final b = bettzeit;
    return FeedCard(
      key: const ValueKey('schlafzeiten'),
      title: 'Deine Schlafzeiten',
      icon: Icons.alarm,
      dark: true,
      children: [
        zeile(
          'aufstehen-werktag',
          'Aufstehen Mo bis Fr',
          uhr(zeiten.werktag),
          () => _zeit(
            context,
            'Wann stehst du Mo bis Fr auf?',
            zeiten.werktag,
            (m) => zeiten.copyWith(werktag: m),
          ),
        ),
        zeile(
          'aufstehen-wochenende',
          'Aufstehen Sa und So',
          uhr(zeiten.wochenende),
          () => _zeit(
            context,
            'Wann stehst du am Wochenende auf?',
            zeiten.wochenende ?? zeiten.werktag,
            (m) => zeiten.copyWith(wochenende: m),
          ),
        ),
        zeile(
          'schlaf-stunden',
          'Schlaf pro Nacht',
          '${formatStunden(zeiten.stunden)} Std.',
          () => _stunden(context),
          last: true,
        ),
        const SizedBox(height: 8),
        Container(
          key: const ValueKey('heute-ins-bett'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            gradient: CoachStyle.tileGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text.rich(
            b == null
                ? const TextSpan(
                    text:
                        'Trag ein, wann du aufstehst. Daraus rechnet '
                        'die App jeden Abend deine Bettzeit.',
                  )
                : TextSpan(
                    children: [
                      TextSpan(
                        text: 'Heute ins Bett: ${formatUhrzeit(b.bett)}.',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: b.termin != null
                            ? ' Wegen deines Termins morgen früh stehst du '
                                  'schon um ${formatUhrzeit(b.aufstehen)} auf.'
                            : ' Ein früher Termin morgen schiebt das '
                                  'automatisch vor.',
                      ),
                    ],
                  ),
            style: CoachStyle.body.copyWith(
              fontSize: 13.5,
              color: CoachStyle.goldInk,
            ),
          ),
        ),
      ],
    );
  }
}

class _UhrzeitDialog extends StatefulWidget {
  const _UhrzeitDialog({required this.titel, this.jetzt});

  final String titel;
  final int? jetzt;

  @override
  State<_UhrzeitDialog> createState() => _UhrzeitDialogState();
}

class _UhrzeitDialogState extends State<_UhrzeitDialog> {
  late final _controller = TextEditingController(
    text: widget.jetzt == null ? '' : formatUhrzeit(widget.jetzt!),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final m = parseUhrzeit(_controller.text);
    if (m == null) {
      setState(() => _error = 'Bitte als Uhrzeit, z. B. 6:30.');
      return;
    }
    Navigator.of(context).pop(m);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titel),
      content: TextField(
        key: const ValueKey('uhrzeit-feld'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.datetime,
        decoration: InputDecoration(
          suffixText: 'Uhr',
          hintText: 'z. B. 6:30',
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _save, child: const Text('Speichern')),
      ],
    );
  }
}

/// Hours slept per night: average of the last 7 nights, change to the
/// week before and one bar per night for the last 14 nights.
class SleepCard extends StatelessWidget {
  const SleepCard({
    super.key,
    required this.entries,
    required this.today,
    required this.onAdd,
  });

  final List<SleepEntry> entries;
  final DateTime today;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final nights = lastNights(entries, today, 14);
    final thisWeek = average(nights.sublist(7));
    final lastWeek = average(nights.sublist(0, 7));
    if (thisWeek == null && lastWeek == null) {
      return FeedCard(
        title: 'Schlafdauer',
        icon: Icons.bedtime_outlined,
        children: [
          const HintText(
            'Trag jeden Morgen ein, wie lange du geschlafen hast.',
          ),
          const SizedBox(height: 16),
          MainButton(label: 'Schlaf eintragen', onPressed: onAdd),
        ],
      );
    }
    final diff = thisWeek != null && lastWeek != null
        ? thisWeek - lastWeek
        : null;
    return FeedCard(
      title: 'Schlafdauer · letzte 14 Nächte',
      icon: Icons.bedtime_outlined,
      children: [
        Text(
          thisWeek == null
              ? 'Diese Woche noch nichts'
              : 'Ø ${formatHours(thisWeek)} Std.',
          style: CoachStyle.question,
        ),
        if (diff != null)
          Text(
            '${diff > 0
                ? '+'
                : diff < 0
                ? '−'
                : '±'}'
            '${formatHours(diff.abs())} Std. zur Vorwoche',
            style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
          ),
        const SizedBox(height: 12),
        SleepChart(nights: nights),
        const SizedBox(height: 16),
        MainButton(label: 'Schlaf eintragen', onPressed: onAdd),
      ],
    );
  }
}

class SleepDialog extends StatefulWidget {
  const SleepDialog({
    super.key,
    this.titel = 'Wie lange hast du letzte Nacht geschlafen?',
  });

  final String titel;

  @override
  State<SleepDialog> createState() => _SleepDialogState();
}

class _SleepDialogState extends State<SleepDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final h = parseHours(_controller.text);
    if (h == null) {
      setState(() => _error = 'Bitte zwischen 1 und 16 Stunden, z. B. 7,5.');
      return;
    }
    Navigator.of(context).pop(h);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titel),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.datetime,
        decoration: InputDecoration(
          suffixText: 'Std.',
          hintText: 'z. B. 7,5 oder 7:30',
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _save, child: const Text('Speichern')),
      ],
    );
  }
}

/// Rows of time and activity; empty rows are dropped on save.
class RoutineEditor extends StatefulWidget {
  const RoutineEditor({super.key, required this.steps});

  final List<RoutineStep> steps;

  @override
  State<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<RoutineEditor> {
  late final List<(TextEditingController, TextEditingController)> _rows = [
    for (final s in widget.steps)
      (TextEditingController(text: s.zeit), TextEditingController(text: s.was)),
    if (widget.steps.isEmpty) _newRow(),
  ];

  (TextEditingController, TextEditingController) _newRow() =>
      (TextEditingController(), TextEditingController());

  @override
  void dispose() {
    for (final (a, b) in _rows) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorPage(
      title: 'Deine Abendroutine',
      intro:
          'Was machst du ab wann am Abend? Zum Beispiel: 22:15 Handy weg, '
          '22:30 lesen, 22:45 Licht aus.',
      onSave: () => Navigator.of(context).pop([
        for (final (zeit, was) in _rows)
          if (was.text.trim().isNotEmpty)
            RoutineStep(zeit.text.trim(), was.text.trim()),
      ]),
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: EditorField(controller: row.$1, hint: '22:15'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EditorField(
                    controller: row.$2,
                    hint: 'Was machst du?',
                  ),
                ),
                IconButton(
                  tooltip: 'Schritt entfernen',
                  icon: const Icon(Icons.close, color: CoachStyle.inkSoft),
                  onPressed: () => setState(() => _rows.remove(row)),
                ),
              ],
            ),
          ),
        GhostButton(
          label: 'Schritt hinzufügen',
          onPressed: () => setState(() => _rows.add(_newRow())),
        ),
      ],
    );
  }
}
