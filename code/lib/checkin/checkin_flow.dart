import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/diary_store.dart';
import '../data/user_profile.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../bereiche/glas.dart';
import 'checkin.dart';
import 'checkin_evaluator.dart';
import 'checkin_questions.dart';

/// Text shown instead of the AI reply until the AI is connected.
const noReplyYet =
    'Deine Antworten sind gespeichert. Sobald dein Coach freigeschaltet ist, '
    'bekommst du hier jeden Tag eine persönliche Antwort zu deinem Tag.';

/// The daily check-in on one screen: one glass card per area of the home
/// page (Körper, Produktivität & Fokus, Business & Beruf, Persönlichkeit,
/// Mindset; Phillip 2026-10-31) plus an optional note, then one AI reply to the
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
    this.vorgemerkt = const {},
    this.messwerte,
  });

  /// What Apple Health measured, for the coach's reply (vault
  /// Umsetzung/Apple Health.md). Asked when the check-in is sent.
  final Future<String> Function()? messwerte;

  /// Answers already picked when the check-in opens, e.g. "Gut trainiert"
  /// after a logged session (vault Umsetzung/Training eintragen.md).
  final Map<String, String> vorgemerkt;

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
  CheckIn? _gestern;
  late final _picked = <String, String>{...widget.vorgemerkt};
  final _note = TextEditingController();
  late int? _open = _nextOpen(-1);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool _cardDone(CheckInCard c) =>
      c.rows.every((r) => _picked[r.topic] != null);

  bool get _complete => checkInRows.every((r) => _picked[r.topic] != null);

  Future<void> _send() async {
    setState(() => _phase = _Phase.reading);
    final messwerte = await widget.messwerte?.call() ?? '';
    var checkIn = CheckIn(
      datum: DateTime(widget.today.year, widget.today.month, widget.today.day),
      training: _picked['Training']!,
      ernaehrung: _picked['Ernährung']!,
      schlaf: _picked['Schlaf']!,
      energie: _picked['Energie']!,
      fokus: _picked['Fokus']!,
      persoenlich: _picked['Ausstrahlung']!,
      mindset: _picked['Mindset']!,
      notiz: _note.text.trim(),
      messwerte: messwerte,
    );
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
    final g = DateTime(
      widget.today.year,
      widget.today.month,
      widget.today.day - 1,
    );
    setState(() {
      _saved = checkIn;
      _gestern = recent.where((c) => dayKey(c.datum) == dayKey(g)).lastOrNull;
      _phase = _Phase.reply;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CoachPage(
      dark: true,
      glas: true,
      child: switch (_phase) {
        _Phase.questions => _buildQuestions(),
        _Phase.reading => const ReadingIndicator(
          text: 'Ich schaue mir deinen Tag an …',
          dark: true,
        ),
        _Phase.reply => CheckInReply(
          reply: _saved!.kiAntwort,
          antworten: [
            _saved!.training,
            _saved!.ernaehrung,
            _saved!.schlaf,
            _saved!.energie,
            _saved!.fokus,
            _saved!.persoenlich,
            _saved!.mindset,
          ],
          werte: bereichWerte(_saved!, _gestern),
          onDone: () => widget.onFinished(_saved!),
        ),
      },
    );
  }

  Widget _buildQuestions() {
    final count = checkInCards.where(_cardDone).length;
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
                    _ProgressRing(done: count, total: checkInCards.length),
                  ],
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < checkInCards.length; i++) ...[
                  _AreaCard(
                    card: checkInCards[i],
                    open: _open == i,
                    picked: _picked,
                    ausDeinemTag: checkInCards[i].rows.every(
                      (r) =>
                          widget.vorgemerkt[r.topic] != null &&
                          widget.vorgemerkt[r.topic] == _picked[r.topic],
                    ),
                    onToggle: () =>
                        setState(() => _open = _open == i ? null : i),
                    onPick: (row, option) => setState(() {
                      _picked[row.topic] = option;
                      if (_cardDone(checkInCards[i])) _open = _nextOpen(i);
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                GlasBox(
                  padding: EdgeInsets.zero,
                  radius: 20,
                  child: TextField(
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
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
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

  /// The next card with an open answer after card [i], or null when all are
  /// answered.
  int? _nextOpen(int i) {
    final n = checkInCards.length;
    for (var k = 1; k <= n; k++) {
      final j = (i + k) % n;
      if (!_cardDone(checkInCards[j])) return j;
    }
    return null;
  }
}

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
        ..color = const Color(0x1FFFECDC),
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

/// One area as a glass card: closed it shows the answers with a gold tick,
/// open (gold glass) it shows its rows to tap. Only one card is open at a
/// time.
class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.card,
    required this.open,
    required this.picked,
    required this.onToggle,
    required this.onPick,
    this.ausDeinemTag = false,
  });

  final CheckInCard card;

  /// Every answer was picked from what the user entered during the day.
  final bool ausDeinemTag;
  final bool open;
  final Map<String, String> picked;
  final VoidCallback onToggle;
  final void Function(CheckInRow row, String option) onPick;

  @override
  Widget build(BuildContext context) {
    final answers = [
      for (final r in card.rows)
        if (picked[r.topic] != null) picked[r.topic]!,
    ];
    final answered = answers.length == card.rows.length;
    final sub = open
        ? card.question
        : (answers.isEmpty
              ? 'Noch offen'
              : '${answers.join(' · ')}${ausDeinemTag ? ' · aus deinem Tag' : ''}');
    return GlasBox(
      art: open ? GlasArt.gold : GlasArt.normal,
      padding: EdgeInsets.zero,
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Row(
                children: [
                  open
                      ? Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: CoachStyle.goldGradient,
                          ),
                          child: Icon(
                            card.icon,
                            size: 19,
                            color: CoachStyle.goldInk,
                          ),
                        )
                      : GlasIcon(card.icon, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: CoachStyle.cardTitle.copyWith(
                            color: Glas.text,
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
                                : Glas.soft,
                            fontWeight: answered && !open
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Room so long answers never run under the tick
                  // (Rundgang 2026-11-15, point 3).
                  if (!open) const SizedBox(width: 10),
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
                        border: Border.all(color: const Color(0x59FFECDC)),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final row in card.rows) ...[
                          if (row.label.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                                bottom: 7,
                                left: 2,
                              ),
                              child: Text(
                                row.label.toUpperCase(),
                                style: Glas.tLabel.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ),
                          LayoutBuilder(
                            builder: (context, box) {
                              final drei =
                                  row.options.length == 3 &&
                                  _woerterPassen(
                                    row.options,
                                    (box.maxWidth - 16) / 3 - 16,
                                  );
                              final width = drei
                                  ? (box.maxWidth - 16) / 3
                                  : (box.maxWidth - 8) / 2;
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final option in row.options)
                                    SizedBox(
                                      width: width,
                                      child: _Chip(
                                        label: option,
                                        selected: picked[row.topic] == option,
                                        onTap: () => onPick(row, option),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// One answer to tap; metallic gold when picked.
/// True when no single word of [labels] is wider than [breite], so a
/// chip never breaks inside a word ("Alles durchg|ezogen").
bool _woerterPassen(List<String> labels, double breite) {
  for (final l in labels) {
    for (final w in l.split(' ')) {
      final tp = TextPainter(
        text: TextSpan(
          text: w,
          style: CoachStyle.body.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final zu = tp.width > breite;
      tp.dispose();
      if (zu) return false;
    }
  }
  return true;
}

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
          color: selected ? null : const Color(0x0DFFECDC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFE6C789) : Glas.edge,
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
              constraints: const BoxConstraints(minHeight: 46),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: CoachStyle.body.copyWith(
                  fontSize: 13.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: selected ? CoachStyle.goldInk : Glas.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The coach's reply to the day, shown right after the check-in. The five
/// answers fly into the coach card, then the reply writes itself word by
/// word (decided with Phillip 2026-10-21).
class CheckInReply extends StatefulWidget {
  const CheckInReply({
    super.key,
    required this.reply,
    required this.onDone,
    this.antworten = const [],
    this.werte = const [],
  });

  /// The four areas' new values, shown under the reply once it is written.
  final List<BereichWert> werte;

  final String reply;
  final VoidCallback onDone;
  final List<String> antworten;

  @override
  State<CheckInReply> createState() => _CheckInReplyState();
}

class _CheckInReplyState extends State<CheckInReply>
    with TickerProviderStateMixin {
  late final _flug = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final String _text = widget.reply.isNotEmpty ? widget.reply : noReplyYet;
  late final List<String> _woerter = _text.split(' ');
  late final _tipp = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_woerter.length * 55).clamp(300, 4000)),
  );

  @override
  void initState() {
    super.initState();
    _flug.forward().whenComplete(() {
      if (mounted) _tipp.forward();
    });
  }

  @override
  void dispose() {
    _flug.dispose();
    _tipp.dispose();
    super.dispose();
  }

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
        GoldText(
          'Dein Coach heute',
          style: CoachStyle.question.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _flug,
          builder: (context, _) => SizedBox(
            // The answers fly into the card, then their space closes so
            // the reply and the values sit higher (Rundgang 2026-11-28).
            height:
                96 *
                (1 -
                    Curves.easeInOut.transform(
                      ((_flug.value - 0.75) / 0.25).clamp(0.0, 1.0),
                    )),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var k = 0; k < widget.antworten.length; k++)
                  Builder(
                    builder: (context) {
                      final e = Curves.easeInCubic.transform(
                        ((_flug.value - k * 0.07) / 0.6).clamp(0.0, 1.0),
                      );
                      return Opacity(
                        opacity: 1 - e,
                        child: Transform.translate(
                          offset: Offset(0, 90 * e),
                          child: Transform.scale(
                            scale: 1 - 0.6 * e,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: CoachStyle.tileGradient,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.antworten[k],
                                style: CoachStyle.body.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: CoachStyle.goldInk,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: Listenable.merge([_flug, _tipp]),
          builder: (context, _) {
            final puls = _flug.value < 0.6
                ? 0.0
                : math.sin(((_flug.value - 0.6) / 0.4) * math.pi);
            final n = (_woerter.length * _tipp.value).ceil();
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE0BF7E)
                        .withValues(alpha: 0.5 * puls),
                    blurRadius: 30 * puls,
                    spreadRadius: 2 * puls,
                  ),
                ],
              ),
              child: CoachCard(
                label: 'Dein Coach',
                text: _tipp.isCompleted ? _text : _woerter.take(n).join(' '),
              ),
            );
          },
        ),
        if (widget.werte.isNotEmpty) ...[
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _tipp,
            builder: (context, _) => Opacity(
              opacity: ((_tipp.value - 0.4) / 0.3).clamp(0.0, 1.0),
              child: Text(
                widget.werte.any((w) => w.diff != null)
                    ? 'DEINE WERTE · KLEIN: ZU GESTERN'
                    : 'DEINE WERTE HEUTE, VON 10',
                style: CoachStyle.goldLabel.copyWith(
                  fontFamily: 'Sora',
                  fontSize: 9.5,
                  letterSpacing: 1.4,
                  color: CoachStyle.beigeLabel,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _tipp,
            builder: (context, _) => Row(
              children: [
                for (var k = 0; k < widget.werte.length; k++) ...[
                  if (k > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final e = Curves.easeOutCubic.transform(
                          ((_tipp.value - 0.5 - k * 0.1) / 0.3).clamp(0.0, 1.0),
                        );
                        return Opacity(
                          opacity: e,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - e)),
                            child: _WertKachel(w: widget.werte[k], an: e),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const Spacer(),
        MainButton(label: 'Fertig', gold: true, onPressed: widget.onDone),
      ],
    );
  }
}

/// One area's value after the check-in: Körper is the average of
/// Training, Ernährung and Schlaf, like on Heute.
typedef BereichWert = ({String name, int wert, int? diff});

List<BereichWert> bereichWerte(CheckIn heute, CheckIn? gestern) {
  int? koerper(Map<String, int> w) {
    final l = [
      for (final k in const ['training', 'ernaehrung', 'schlaf']) ?w[k],
    ];
    return l.isEmpty ? null : (l.reduce((a, b) => a + b) / l.length).round();
  }

  int? wert(Map<String, int> w, String k) => k == 'koerper' ? koerper(w) : w[k];
  return [
    for (final (name, k) in const [
      ('Körper', 'koerper'),
      ('Fokus', 'produktiv'),
      ('Ausstrahlung', 'persoenlich'),
      ('Mindset', 'mindset'),
    ])
      if (wert(heute.werte, k) case final w?)
        (
          name: name,
          wert: w,
          diff: gestern == null
              ? null
              : switch (wert(gestern.werte, k)) {
                  final g? => w - g,
                  null => null,
                },
        ),
  ];
}

class _WertKachel extends StatelessWidget {
  const _WertKachel({required this.w, required this.an});

  final BereichWert w;

  /// 0..1 while it comes in, the number counts up with it.
  final double an;

  @override
  Widget build(BuildContext context) {
    final d = w.diff;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0x0DFFECDC),
        border: Border.all(color: Glas.edge),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoldText(
                '${(w.wert * an).round()}',
                style: CoachStyle.question.copyWith(fontSize: 26, height: 1),
              ),
              if (d != null) ...[
                const SizedBox(width: 3),
                Text(
                  d == 0 ? '±0' : '${d > 0 ? '+' : '−'}${d.abs()}',
                  style: CoachStyle.body.copyWith(
                    fontSize: 11.5,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: d > 0
                        ? CoachStyle.goldLight
                        : const Color(0xFF8F8270),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              w.name,
              style: CoachStyle.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CoachStyle.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
