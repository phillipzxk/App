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

/// Training page: progress, the user's own week plan with today
/// highlighted, and the field "Wie war dein Training?".
class TrainingTab extends StatelessWidget {
  const TrainingTab({
    super.key,
    required this.plan,
    required this.today,
    required this.fragen,
    required this.onSavePlan,
    required this.onAsk,
  });

  final TrainingPlan plan;
  final DateTime today;
  final List<CoachFrage> fragen;
  final Future<void> Function(TrainingPlan plan) onSavePlan;
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
              const HintText(
                'Leg einmal fest, was du an welchem Tag trainierst, egal ob '
                'Gym, Laufen, Radfahren oder Kampfsport. Dann siehst du hier '
                'jeden Tag, was ansteht, und der Coach arbeitet mit deinem '
                'Plan.',
              ),
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
              _WeekRow(plan: plan, today: today),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Heute: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: plan.forDay(today).trim().isEmpty
                          ? 'frei'
                          : plan.forDay(today).trim(),
                    ),
                  ],
                ),
                style: CoachStyle.body,
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
          hint: 'Was hast du geschafft, was nicht, und warum?',
          today: fragen,
          onSend: onAsk,
        ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.plan, required this.today});

  final TrainingPlan plan;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              decoration: BoxDecoration(
                color: i == today.weekday - 1
                    ? CoachStyle.dark
                    : const Color(0xFFF1ECE2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    _weekdays[i].substring(0, 2),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: i == today.weekday - 1
                          ? CoachStyle.goldSoft
                          : CoachStyle.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shortDay(plan.tage[i]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: i == today.weekday - 1
                          ? CoachStyle.goldSoft
                          : CoachStyle.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One free-text field per weekday; an empty day is a day off.
class TrainingPlanEditor extends StatefulWidget {
  const TrainingPlanEditor({super.key, required this.plan});

  final TrainingPlan plan;

  @override
  State<TrainingPlanEditor> createState() => _TrainingPlanEditorState();
}

class _TrainingPlanEditorState extends State<TrainingPlanEditor> {
  late final _controllers = [
    for (final t in widget.plan.tage) TextEditingController(text: t),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorPage(
      title: 'Dein Trainingsplan',
      intro:
          'Schreib in eigenen Worten, was du an welchem Tag machst. Jede '
          'Sportart geht. Lass einen Tag leer, wenn er frei ist.',
      onSave: () =>
          Navigator.of(context)
              .pop(TrainingPlan([for (final c in _controllers) c.text.trim()])),
      children: [
        for (var i = 0; i < 7; i++) ...[
          EditorField(
            controller: _controllers[i],
            label: _weekdays[i],
            hint: i == 0
                ? 'z. B. Oberkörper: Bankdrücken 3x8, Klimmzüge 3x6'
                : i == 1
                ? 'z. B. Laufen 5 km locker'
                : null,
            multiline: true,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
