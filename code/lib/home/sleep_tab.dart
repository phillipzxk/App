import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../sleep/schlafzeiten.dart';
import '../sleep/sleep.dart';
import '../sleep/sleep_chart.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'bereichs_werte.dart';
import 'feed_widgets.dart';

/// Schlaf page: progress, the evening routine (set once), a field for
/// sleep tips and the sleep duration per night.
class SleepTab extends StatelessWidget {
  const SleepTab({
    super.key,
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
  });

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

  Future<void> _edit(BuildContext context) async {
    final saved = await Navigator.of(context).push<List<RoutineStep>>(
      MaterialPageRoute(builder: (_) => RoutineEditor(steps: routine)),
    );
    if (saved != null) await onSaveRoutine(saved);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        const PageHeader(
          label: 'Bereich',
          title: 'Schlaf & Energie',
          icon: Icons.bedtime,
        ),
        const AreaChart(bereich: Bereich.schlaf),
        const GroupLabel('Deine Basis'),
        SchlafzeitenKarte(
          zeiten: schlafzeiten,
          bettzeit: bettzeit,
          onSave: onSaveSchlafzeiten,
        ),
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
        const GroupLabel('Frag deinen Coach'),
        AskCoachCard(
          title: 'Frag zu deinem Schlaf',
          hint: 'Was stört dich gerade beim Schlafen?',
          today: fragen,
          onSend: onAsk,
        ),
        const GroupLabel('Deine Werte'),
        SleepCard(entries: sleep, today: today, onAdd: onAddSleep),
      ],
    );
  }
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
