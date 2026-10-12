import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import 'feed_widgets.dart';

/// Schlaf page: progress, the evening routine (set once) and a field for
/// sleep tips.
class SleepTab extends StatelessWidget {
  const SleepTab({
    super.key,
    required this.routine,
    required this.fragen,
    required this.onSaveRoutine,
    required this.onAsk,
  });

  final List<RoutineStep> routine;
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
