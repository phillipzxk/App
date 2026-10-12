import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../sleep/sleep.dart';
import '../sleep/sleep_chart.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
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
  });

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
      children: [
        const PageHeader(label: 'Bereich', title: 'Schlaf'),
        const AreaChart(),
        FeedCard(
          title: 'Deine Abendroutine',
          children: [
            if (routine.isEmpty)
              const HintText(
                'Leg einmal fest, wie dein Abend aussehen soll. Der Coach '
                'arbeitet damit und passt sie an, wenn du öfter schlecht '
                'schläfst.',
              )
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
        AskCoachCard(
          title: 'Frag zu deinem Schlaf',
          hint: 'Was stört dich gerade beim Schlafen?',
          today: fragen,
          onSend: onAsk,
        ),
        SleepCard(entries: sleep, today: today, onAdd: onAddSleep),
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
        children: [
          const HintText(
            'Trag jeden Morgen ein, wie lange du geschlafen hast. Dann siehst '
            'du hier jede Nacht als Balken und deinen Schnitt.',
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
        const SizedBox(height: 8),
        const HintText(
          'Jeder Balken ist eine Nacht, ganz rechts heute. Die gestrichelte '
          'Linie liegt bei 8 Stunden. Der Schnitt zählt die letzten 7 Nächte.',
        ),
        const SizedBox(height: 16),
        MainButton(label: 'Schlaf eintragen', onPressed: onAdd),
      ],
    );
  }
}

class SleepDialog extends StatefulWidget {
  const SleepDialog({super.key});

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
      title: const Text('Wie lange hast du letzte Nacht geschlafen?'),
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
