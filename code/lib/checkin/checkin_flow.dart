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

/// The daily check-in on one screen: one tap per area (training, nutrition,
/// sleep, energy, mindset) plus an optional note, then one AI reply to the
/// whole day. Opens by itself on the first app start of each day; the Main
/// Feed only comes after it. Shortened with Phillip on 2026-10-18.
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

  /// Called with the saved check-in once the user has seen the reply.
  final ValueChanged<CheckIn> onFinished;

  @override
  State<CheckInFlow> createState() => _CheckInFlowState();
}

enum _Phase { questions, reading, reply }

class _CheckInFlowState extends State<CheckInFlow> {
  _Phase _phase = _Phase.questions;
  CheckIn? _saved;
  final _picked = <String, String>{};
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _complete => checkInRows.every((r) => _picked[r.topic] != null);

  Future<void> _send() async {
    var checkIn = CheckIn(
      datum: DateTime(widget.today.year, widget.today.month, widget.today.day),
      training: _picked['Training']!,
      ernaehrung: _picked['Ernährung']!,
      schlaf: _picked['Schlaf']!,
      energie: _picked['Energie']!,
      mindset: _picked['Mindset']!,
      notiz: _note.text.trim(),
    );
    setState(() => _phase = _Phase.reading);
    final recent = await widget.store.loadCheckIns();
    final reply = await widget.evaluator.reply(widget.profile, checkIn, recent);
    checkIn = checkIn.withReply(reply ?? '');
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
      child: switch (_phase) {
        _Phase.questions => _buildQuestions(),
        _Phase.reading => const ReadingIndicator(
          text: 'Ich schaue mir deinen Tag an …',
        ),
        _Phase.reply => CheckInReply(
          reply: _saved!.kiAntwort,
          onDone: () => widget.onFinished(_saved!),
        ),
      },
    );
  }

  Widget _buildQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text('HEUTE · CHECK-IN', style: CoachStyle.goldLabel),
                const SizedBox(height: 10),
                const Text('Wie war dein Tag?', style: CoachStyle.question),
                const SizedBox(height: 4),
                Text(
                  'Pro Zeile einmal antippen.',
                  style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
                ),
                for (final row in checkInRows) ...[
                  const SizedBox(height: 18),
                  Text(row.topic.toUpperCase(), style: CoachStyle.label),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, box) {
                      // Two answers per line; short ones (energy) three.
                      final columns = row.options.every((o) => o.length <= 8)
                          ? row.options.length
                          : 2;
                      final width =
                          (box.maxWidth - 8 * (columns - 1)) / columns;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final option in row.options)
                            SizedBox(
                              width: width,
                              child: _Chip(
                                label: option,
                                selected: _picked[row.topic] == option,
                                onTap: () =>
                                    setState(() => _picked[row.topic] = option),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  'Was war heute besonders? (freiwillig)',
                  style: CoachStyle.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  style: CoachStyle.body,
                  cursorColor: CoachStyle.gold,
                  decoration: InputDecoration(
                    hintText: 'Ein Satz reicht …',
                    hintStyle: CoachStyle.body.copyWith(
                      color: CoachStyle.inkSoft,
                    ),
                    filled: true,
                    fillColor: CoachStyle.card,
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: AnswerField.border(CoachStyle.line),
                    focusedBorder: AnswerField.border(CoachStyle.gold),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        MainButton(label: 'Absenden', onPressed: _complete ? _send : null),
      ],
    );
  }
}

/// One answer to tap; gold when picked.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? CoachStyle.goldSoft : CoachStyle.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? CoachStyle.gold : CoachStyle.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: CoachStyle.body.copyWith(
              fontSize: 14,
              height: 1.25,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// The coach's reply to the day, shown right after the check-in.
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
        const Text('HEUTE', style: CoachStyle.goldLabel),
        const SizedBox(height: 12),
        const Text('Dein Tag', style: CoachStyle.question),
        const SizedBox(height: 20),
        CoachCard(
          label: 'Dein Coach',
          text: reply.isNotEmpty ? reply : noReplyYet,
        ),
        const Spacer(),
        MainButton(label: 'Fertig', onPressed: onDone),
      ],
    );
  }
}
