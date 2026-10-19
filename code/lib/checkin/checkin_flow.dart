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
  String? _open = checkInRows.first.topic;

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
    // Reply and area scores are asked at the same time.
    final replyFuture = widget.evaluator.reply(widget.profile, checkIn, recent);
    final werteFuture = widget.evaluator.rate(widget.profile, checkIn, recent);
    final reply = await replyFuture;
    final werte = await werteFuture;
    checkIn = checkIn.withReply(reply ?? '');
    if (werte != null) checkIn = checkIn.withWerte(werte);
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
      dark: true,
      child: switch (_phase) {
        _Phase.questions => _buildQuestions(),
        _Phase.reading => const ReadingIndicator(
          text: 'Ich schaue mir deinen Tag an …',
          dark: true,
        ),
        _Phase.reply => CheckInReply(
          reply: _saved!.kiAntwort,
          onDone: () => widget.onFinished(_saved!),
        ),
      },
    );
  }

  Widget _buildQuestions() {
    final count = checkInRows.where((r) => _picked[r.topic] != null).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HEUTE · CHECK-IN',
                            style: CoachStyle.goldLabel.copyWith(
                              fontFamily: 'Sora',
                              letterSpacing: 2.2,
                              color: const Color(0xFFC9A25C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GoldText(
                            'Wie war dein Tag?',
                            style: CoachStyle.question.copyWith(fontSize: 26),
                          ),
                        ],
                      ),
                    ),
                    _ProgressRing(done: count, total: checkInRows.length),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00C9A25C),
                        Color(0xB3C9A25C),
                        Color(0x00C9A25C),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final row in checkInRows) ...[
                  _AreaCard(
                    row: row,
                    open: _open == row.topic,
                    picked: _picked[row.topic],
                    onToggle: () => setState(
                      () => _open = _open == row.topic ? null : row.topic,
                    ),
                    onPick: (option) => setState(() {
                      _picked[row.topic] = option;
                      _open = _nextOpen(row.topic);
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                TextField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  style: CoachStyle.body.copyWith(color: CoachStyle.cream),
                  cursorColor: CoachStyle.goldBright,
                  decoration: InputDecoration(
                    hintText: 'Was war heute besonders? (freiwillig)',
                    hintStyle: CoachStyle.body.copyWith(
                      color: const Color(0xFF8F8270),
                      fontSize: 14.5,
                    ),
                    filled: true,
                    fillColor: const Color(0x0DFFFFFF),
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: AnswerField.border(const Color(0xFF4A3E2F)),
                    focusedBorder: AnswerField.border(CoachStyle.goldBright),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        MainButton(
          label: 'Absenden',
          gold: true,
          onPressed: _complete ? _send : null,
        ),
      ],
    );
  }

  /// The next area without an answer after [topic], or null when all are
  /// answered.
  String? _nextOpen(String topic) {
    final i = checkInRows.indexWhere((r) => r.topic == topic);
    final order = [...checkInRows.skip(i + 1), ...checkInRows.take(i)];
    for (final r in order) {
      if (_picked[r.topic] == null) return r.topic;
    }
    return null;
  }
}

const _areaIcons = {
  'Training': Icons.fitness_center,
  'Ernährung': Icons.eco,
  'Schlaf': Icons.bedtime,
  'Energie': Icons.bolt,
  'Mindset': Icons.spa,
};

const _areaQuestions = {
  'Training': 'Wie lief dein Training?',
  'Ernährung': 'Wie hast du gegessen?',
  'Schlaf': 'Wie hast du geschlafen?',
  'Energie': 'Wie ist deine Energie?',
  'Mindset': 'Hast du durchgezogen?',
};

/// Gold ring around "x von 5".
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 56,
      child: CustomPaint(
        painter: _RingPainter(done / total),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1,
                  color: Color(0xFFF0D9A6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'VON $total',
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 8.5,
                  letterSpacing: 1,
                  color: Color(0xFF8F8270),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(3);
    canvas.drawArc(
      ring,
      0,
      6.2832,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFF2E261C),
    );
    if (value <= 0) return;
    canvas.drawArc(
      ring,
      -1.5708,
      6.2832 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [Color(0xFFF5DFAE), Color(0xFFD4A85E), Color(0xFF9A6D35)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

/// One area as a card: closed it shows the answer with a gold tick, open
/// it shows the answers to tap. Only one card is open at a time.
class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.row,
    required this.open,
    required this.picked,
    required this.onToggle,
    required this.onPick,
  });

  final CheckInRow row;
  final bool open;
  final String? picked;
  final VoidCallback onToggle;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final answered = picked != null;
    final sub = open
        ? (_areaQuestions[row.topic] ?? '')
        : (picked ?? 'Noch offen');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: open ? CoachStyle.goldEdgeGradient : null,
        color: open ? null : CoachStyle.hairline,
        borderRadius: BorderRadius.circular(22),
        boxShadow: open ? CoachStyle.nightShadow : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: open
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A2118), Color(0xFF1B1611)],
                )
              : null,
          color: open ? null : CoachStyle.nightCard,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(21),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: open ? CoachStyle.goldGradient : null,
                        color: open
                            ? null
                            : (answered
                                  ? const Color(0xFF2E2519)
                                  : CoachStyle.nightChip),
                      ),
                      child: Icon(
                        _areaIcons[row.topic],
                        size: 20,
                        color: open
                            ? CoachStyle.goldInk
                            : (answered
                                  ? const Color(0xFFD9B66F)
                                  : CoachStyle.nightMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.topic,
                            style: CoachStyle.cardTitle.copyWith(
                              color: const Color(0xFFF6EEDD),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub,
                            style: CoachStyle.body.copyWith(
                              fontSize: 13.5,
                              height: 1.3,
                              color: answered && !open
                                  ? CoachStyle.goldBright
                                  : CoachStyle.creamSoft,
                              fontWeight: answered && !open
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (answered && !open)
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: CoachStyle.goldGradient,
                          boxShadow: [
                            BoxShadow(color: Color(0x73D6AA5E), blurRadius: 14),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: CoachStyle.goldInk,
                        ),
                      )
                    else if (!open)
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF5A4B38)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: open
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final width = (box.maxWidth - 8) / 2;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final option in row.options)
                                SizedBox(
                                  width: width,
                                  child: _Chip(
                                    label: option,
                                    selected: picked == option,
                                    onTap: () => onPick(option),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// One answer to tap; metallic gold when picked.
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: selected ? CoachStyle.goldGradient : null,
          color: selected ? null : CoachStyle.nightChip,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFE6C789)
                : CoachStyle.nightLineStrong,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x4DD6AA5E),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: CoachStyle.body.copyWith(
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? CoachStyle.goldInk
                      : const Color(0xFFE8DCC6),
                ),
              ),
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
        Text(
          'HEUTE',
          style: CoachStyle.goldLabel.copyWith(
            fontFamily: 'Sora',
            letterSpacing: 2.2,
            color: const Color(0xFFC9A25C),
          ),
        ),
        const SizedBox(height: 12),
        GoldText('Dein Tag', style: CoachStyle.question.copyWith(fontSize: 26)),
        const SizedBox(height: 20),
        CoachCard(
          label: 'Dein Coach',
          text: reply.isNotEmpty ? reply : noReplyYet,
        ),
        const Spacer(),
        MainButton(label: 'Fertig', gold: true, onPressed: onDone),
      ],
    );
  }
}
