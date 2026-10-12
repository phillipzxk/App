import 'package:flutter/material.dart';

import '../data/diary_store.dart';
import '../data/user_profile.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'checkin.dart';
import 'checkin_evaluator.dart';
import 'checkin_questions.dart';

/// Text shown instead of the AI reply until the AI is connected.
const noReplyYet =
    'Deine Antworten sind gespeichert. Sobald dein Coach freigeschaltet ist, '
    'bekommst du hier jeden Tag eine persönliche Antwort zu deinem Tag.';

/// The daily check-in: four questions one at a time, then one AI reply to
/// the whole day.
class CheckInFlow extends StatefulWidget {
  const CheckInFlow({
    super.key,
    required this.profile,
    required this.store,
    required this.evaluator,
    required this.today,
    required this.onFinished,
  });

  final UserProfile profile;
  final DiaryStore store;
  final CheckInEvaluator evaluator;
  final DateTime today;

  /// Called with the saved check-in, or null if the user closed it early.
  final ValueChanged<CheckIn?> onFinished;

  @override
  State<CheckInFlow> createState() => _CheckInFlowState();
}

enum _Phase { questions, reading, reply }

class _CheckInFlowState extends State<CheckInFlow> {
  _Phase _phase = _Phase.questions;
  int _index = 0;
  CheckIn? _saved;
  late final List<TextEditingController> _controllers = [
    for (final _ in checkInQuestions) TextEditingController(),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isLast => _index == checkInQuestions.length - 1;

  Future<void> _next() async {
    if (!_isLast) {
      setState(() => _index++);
      return;
    }
    final a = [for (final c in _controllers) c.text.trim()];
    var checkIn = CheckIn(
      datum: DateTime(widget.today.year, widget.today.month, widget.today.day),
      training: a[0],
      ernaehrung: a[1],
      schlaf: a[2],
      mindset: a[3],
    );
    setState(() => _phase = _Phase.reading);
    final recent = await widget.store.loadCheckIns();
    final reply = await widget.evaluator.reply(widget.profile, checkIn, recent);
    checkIn = CheckIn(
      datum: checkIn.datum,
      training: checkIn.training,
      ernaehrung: checkIn.ernaehrung,
      schlaf: checkIn.schlaf,
      mindset: checkIn.mindset,
      kiAntwort: reply ?? '',
    );
    await widget.store.saveCheckIn(checkIn);
    if (!mounted) return;
    setState(() {
      _saved = checkIn;
      _phase = _Phase.reply;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CoachPage(
      gradient: _phase == _Phase.reply
          ? CoachStyle.summaryBackground
          : CoachStyle.questionBackground,
      child: switch (_phase) {
        _Phase.questions => _buildQuestion(),
        _Phase.reading => const ReadingIndicator(
          text: 'Ich schaue mir deinen Tag an …',
        ),
        _Phase.reply => CheckInReply(
          reply: _saved!.kiAntwort,
          onDone: () => widget.onFinished(_saved),
        ),
      },
    );
  }

  Widget _buildQuestion() {
    final question = checkInQuestions[_index];
    final controller = _controllers[_index];
    return Column(
      key: ValueKey(_index),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentBar(count: checkInQuestions.length, done: _index + 1),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: Icon(
                _index == 0 ? Icons.close : Icons.arrow_back,
                color: CoachStyle.inkSoft,
              ),
              tooltip: _index == 0 ? 'Schließen' : 'Zurück',
              onPressed: _index == 0
                  ? () => widget.onFinished(null)
                  : () => setState(() => _index--),
            ),
            Expanded(
              child: Text(
                'HEUTE · FRAGE ${_index + 1} VON ${checkInQuestions.length} · '
                '${question.topic.toUpperCase()}',
                style: CoachStyle.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(question.question, style: CoachStyle.question),
        const SizedBox(height: 20),
        Expanded(
          child: AnswerField(
            controller: controller,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        MainButton(
          label: _isLast ? 'Absenden' : 'Weiter',
          onPressed: controller.text.trim().isEmpty ? null : _next,
        ),
      ],
    );
  }
}

/// The coach's reply to the day; also opened again from the Main Feed.
class CheckInReply extends StatelessWidget {
  const CheckInReply({super.key, required this.reply, required this.onDone});

  final String reply;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Text('DEIN COACH · HEUTE', style: CoachStyle.label),
        const SizedBox(height: 12),
        const Text('Dein Tag', style: CoachStyle.question),
        const SizedBox(height: 20),
        CoachNote(text: reply.isNotEmpty ? reply : noReplyYet),
        const Spacer(),
        MainButton(label: 'Fertig', onPressed: onDone),
      ],
    );
  }
}
