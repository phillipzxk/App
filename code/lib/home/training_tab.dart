import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import 'feed_widgets.dart';

const _weekdays = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

/// Training page: progress, the user's own week plan with focus, today
/// highlighted and the next target per day (hybrid engine), and the field
/// "Wie war dein Training?".
class TrainingTab extends StatelessWidget {
  const TrainingTab({
    super.key,
    required this.plan,
    required this.schwerpunkt,
    required this.today,
    required this.fragen,
    required this.onSavePlan,
    required this.onSchwerpunkt,
    required this.onAsk,
  });

  final TrainingPlan plan;
  final Schwerpunkt? schwerpunkt;
  final DateTime today;
  final List<CoachFrage> fragen;
  final Future<void> Function(TrainingPlan plan) onSavePlan;
  final Future<void> Function(Schwerpunkt s) onSchwerpunkt;
  final Future<void> Function(String text) onAsk;

  Future<void> _edit(BuildContext context) async {
    final saved = await Navigator.of(context).push<TrainingPlan>(
      MaterialPageRoute(builder: (_) => TrainingPlanEditor(plan: plan)),
    );
    if (saved != null) await onSavePlan(saved);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        const PageHeader(
          label: 'Bereich',
          title: 'Training',
          icon: Icons.fitness_center,
        ),
        const GroupLabel('Dein Verlauf'),
        const AreaChart(),
        const GroupLabel('Deine Basis'),
        if (plan.isEmpty)
          FeedCard(
            title: 'Dein Plan',
            icon: Icons.event_note_outlined,
            gold: true,
            children: [
              const HintText('Was trainierst du an welchem Tag?'),
              const SizedBox(height: 12),
              GhostButton(
                label: 'Plan festlegen',
                onPressed: () => _edit(context),
              ),
            ],
          )
        else
          FeedCard(
            title: 'Dein Plan · diese Woche',
            icon: Icons.event_note_outlined,
            gold: true,
            children: [
              const Text('Dein Schwerpunkt', style: CoachStyle.label),
              const SizedBox(height: 6),
              _SchwerpunktChips(value: schwerpunkt, onPick: onSchwerpunkt),
              const SizedBox(height: 10),
              for (var i = 0; i < 7; i++)
                _DayRow(
                  key: ValueKey('plan-tag-$i'),
                  tag: _weekdays[i],
                  text: plan.tage[i],
                  heute: i == today.weekday - 1,
                  first: i == 0,
                ),
              const SizedBox(height: 12),
              GhostButton(
                label: 'Plan bearbeiten',
                onPressed: () => _edit(context),
              ),
            ],
          ),
        const GroupLabel('Frag deinen Coach'),
        AskCoachCard(
          title: 'Wie war dein Training?',
          hint:
              'Was hast du geschafft, was nicht, und warum? Gern mit '
              'Gewicht, Wiederholungen oder Kilometern.',
          today: fragen,
          onSend: onAsk,
        ),
      ],
    );
  }
}

class _SchwerpunktChips extends StatelessWidget {
  const _SchwerpunktChips({required this.value, required this.onPick});

  final Schwerpunkt? value;
  final Future<void> Function(Schwerpunkt s) onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in Schwerpunkt.values)
          InkWell(
            key: ValueKey('schwerpunkt-${s.name}'),
            borderRadius: BorderRadius.circular(999),
            onTap: () => onPick(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: s == value ? CoachStyle.beige : CoachStyle.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: s == value ? CoachStyle.beige : CoachStyle.edgeStrong,
                ),
              ),
              child: Text(
                s.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: s == value ? FontWeight.w600 : FontWeight.w400,
                  color: s == value ? CoachStyle.goldInk : CoachStyle.inkSoft,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One weekday of the plan: name, exercises and, on training days, the
/// next target from the coach.
class _DayRow extends StatelessWidget {
  const _DayRow({
    super.key,
    required this.tag,
    required this.text,
    required this.heute,
    required this.first,
  });

  final String tag;
  final String text;
  final bool heute;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final frei = text.trim().isEmpty;
    final details = dayDetails(text);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: heute ? CoachStyle.gold.withValues(alpha: 0.12) : null,
        borderRadius: heute ? BorderRadius.circular(10) : null,
        border: first || heute
            ? null
            : const Border(top: BorderSide(color: CoachStyle.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              tag.substring(0, 2),
              style: CoachStyle.cardTitle.copyWith(
                fontSize: 13,
                color: heute ? CoachStyle.gold : CoachStyle.inkSoft,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heute ? '${shortDay(text)} · heute' : shortDay(text),
                  style: CoachStyle.body.copyWith(
                    fontWeight: frei ? FontWeight.w400 : FontWeight.w600,
                    color: frei ? CoachStyle.inkSoft : CoachStyle.ink,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: CoachStyle.body.copyWith(
                      fontSize: 13.5,
                      color: CoachStyle.inkSoft,
                    ),
                  ),
                ],
                if (!frei) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: CoachStyle.goldSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Nächstes Ziel: folgt vom Coach',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF7A5A2A),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Per weekday a short name (e.g. "Push + Laufen") and the exercises in
/// own words, as many as needed. An empty day is a day off.
class TrainingPlanEditor extends StatefulWidget {
  const TrainingPlanEditor({super.key, required this.plan});

  final TrainingPlan plan;

  @override
  State<TrainingPlanEditor> createState() => _TrainingPlanEditorState();
}

class _TrainingPlanEditorState extends State<TrainingPlanEditor> {
  late final _names = [
    for (final t in widget.plan.tage)
      TextEditingController(text: t.trim().isEmpty ? '' : shortDay(t)),
  ];
  late final _uebungen = [
    for (final t in widget.plan.tage)
      TextEditingController(text: dayDetails(t)),
  ];

  @override
  void dispose() {
    for (final c in [..._names, ..._uebungen]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorPage(
      title: 'Dein Trainingsplan',
      intro:
          'Gib jedem Tag einen kurzen Namen, z. B. „Push + Laufen“, und '
          'schreib darunter alle Übungen in eigenen Worten, so viele du '
          'willst. Jede Sportart geht. Lass einen Tag leer, wenn er frei ist.',
      onSave: () => Navigator.of(context).pop(
        TrainingPlan([
          for (var i = 0; i < 7; i++)
            joinDay(_names[i].text, _uebungen[i].text),
        ]),
      ),
      children: [
        for (var i = 0; i < 7; i++) ...[
          Text(_weekdays[i], style: CoachStyle.cardTitle),
          const SizedBox(height: 6),
          EditorField(
            key: ValueKey('plan-name-$i'),
            controller: _names[i],
            label: 'Name',
            hint: i == 0
                ? 'z. B. Push + Laufen'
                : i == 1
                ? 'z. B. Pull'
                : null,
          ),
          const SizedBox(height: 8),
          EditorField(
            key: ValueKey('plan-uebungen-$i'),
            controller: _uebungen[i],
            label: 'Übungen',
            hint: i == 0
                ? 'z. B. Bankdrücken 5x5 mit 80 kg\nSchulterdrücken 3x8\n'
                      'Dips 3x10\nLaufen 5 km locker'
                : null,
            multiline: true,
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}
