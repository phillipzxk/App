import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import '../konto/konto_ui.dart' show bewegungAn;
import '../ui/umbau.dart';
import 'heute_animationen.dart';

/// The coach's reply on "Heute" (decided with Phillip 2026-10-20): as text
/// or as 3 to 4 points, and foldable with the arrow at the top right.
///
/// [ansicht] is 'text' or 'punkte', with a 'zu:' prefix while folded, so
/// unfolding returns to the view chosen before.
class CoachKarte extends StatefulWidget {
  const CoachKarte({
    super.key,
    required this.text,
    required this.stichpunkte,
    required this.ansicht,
    required this.onAnsicht,
    required this.onStichpunkte,
    this.umschaltbar = true,
    this.jubel,
    this.jubelTick = 0,
  });

  final String text;
  final List<String> stichpunkte;
  final String ansicht;
  final ValueChanged<String> onAnsicht;

  /// Asks the coach for the points; called when they are missing.
  final Future<void> Function() onStichpunkte;

  /// False while there is no real reply yet (only the placeholder text).
  final bool umschaltbar;

  /// Short cheer shown above the reply (e.g. after "Heute geschafft").
  final String? jubel;

  /// Goes up each time the coach should cheer: the avatar hops and sparks.
  final int jubelTick;

  @override
  State<CoachKarte> createState() => _CoachKarteState();
}

class _CoachKarteState extends State<CoachKarte>
    with SingleTickerProviderStateMixin {
  bool _laedt = false;
  late final _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didUpdateWidget(CoachKarte old) {
    super.didUpdateWidget(old);
    if (widget.jubelTick > old.jubelTick) {
      if (_zu) widget.onAnsicht(_sicht);
      _hop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  /// The avatar hops three times, wobbling, with a gold ring and sparks.
  Widget _avatar() => AnimatedBuilder(
    animation: _hop,
    builder: (context, child) {
      final v = _hop.value;
      final hop = v == 0 ? 0.0 : (math.sin(v * math.pi * 3)).abs() * (1 - v);
      final dreh = v == 0 ? 0.0 : math.sin(v * math.pi * 6) * 0.22 * (1 - v);
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (v > 0 && v < 1)
            Container(
              width: 52 * (1 + v * 0.9),
              height: 52 * (1 + v * 0.9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF5DFAE).withValues(alpha: 1 - v),
                  width: 2,
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(0, -16 * hop),
            child: Transform.rotate(
              angle: dreh,
              child: Transform.scale(scale: 1 + 0.15 * hop, child: child),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: FunkenPainter(v, anzahl: 26, weite: 120),
              ),
            ),
          ),
        ],
      );
    },
    child: Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: Umbau.grad,
      ),
      child: _Bild(lacht: widget.jubel != null),
    ),
  );

  bool get _zu => widget.ansicht.startsWith('zu:');
  String get _sicht => widget.ansicht.replaceFirst('zu:', '');

  Future<void> _zeige(String sicht) async {
    widget.onAnsicht(sicht);
    if (sicht == 'punkte' && widget.stichpunkte.isEmpty && !_laedt) {
      setState(() => _laedt = true);
      await widget.onStichpunkte();
      if (mounted) setState(() => _laedt = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zu = _zu;
    final punkte = _sicht == 'punkte' && widget.umschaltbar;
    final klappen = GestureDetector(
      key: const ValueKey('coach-klappen'),
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onAnsicht(zu ? _sicht : 'zu:$_sicht'),
      child: Tooltip(
        message: zu ? 'Aufklappen' : 'Wegklappen',
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            zu ? Icons.expand_more : Icons.expand_less,
            size: 20,
            color: Umbau.weich,
          ),
        ),
      ),
    );
    // Since the Umbau (2026-11-12) the coach stands free on the page: the
    // picture with a gold ring, beside it the reply that types itself.
    return Row(
      key: const ValueKey('coach-karte'),
      crossAxisAlignment: zu
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        _avatar(),
        const SizedBox(width: 14),
        Expanded(
          child: zu
              ? GestureDetector(
                  key: const ValueKey('coach-aufklappen'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onAnsicht(_sicht),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _stil.copyWith(
                            fontSize: 13.5,
                            color: Umbau.weich,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Aufklappen', style: _link),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.jubel case final j?) ...[
                      Text.rich(
                        key: const ValueKey('coach-jubel'),
                        TextSpan(
                          children: [
                            TextSpan(
                              text: j.split('\n').first,
                              style: CoachStyle.title.copyWith(
                                fontSize: 17,
                                height: 1.4,
                                color: Umbau.gold,
                              ),
                            ),
                            if (j.contains('\n'))
                              TextSpan(
                                text: '\n${j.split('\n').skip(1).join(' ')}',
                                style: _stil.copyWith(
                                  fontSize: 13.5,
                                  color: Umbau.hell,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    punkte ? _punkte() : _text(),
                    if (widget.umschaltbar)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GestureDetector(
                          key: ValueKey(
                            punkte ? 'coach-als-text' : 'coach-als-punkte',
                          ),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _zeige(punkte ? 'text' : 'punkte'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              punkte ? 'Als Text ›' : 'Als Stichpunkte ›',
                              style: _link,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        klappen,
      ],
    );
  }

  static const _stil = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 15,
    height: 1.45,
    color: Color(0xFFF1E6D2),
  );

  static const _link = TextStyle(
    fontFamily: 'Figtree',
    fontWeight: FontWeight.w600,
    fontSize: 11.5,
    color: Umbau.gold,
  );

  Widget _text() =>
      _Getippt(widget.text, key: const ValueKey('coach-text'), style: _stil);

  Widget _punkte() {
    if (widget.stichpunkte.isEmpty) {
      if (_laedt) {
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CoachStyle.gold,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Der Coach fasst zusammen …',
              style: _stil.copyWith(color: Umbau.weich),
            ),
          ],
        );
      }
      // Coach not reachable: keep the full text readable.
      return _text();
    }
    return Column(
      key: const ValueKey('coach-punkte'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, p) in widget.stichpunkte.indexed)
          Einflug(
            platz: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: const BoxDecoration(
                      gradient: Umbau.grad,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(child: Text(p, style: _stil)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A text that types itself once when it appears (whole at once in tests).
class _Getippt extends StatelessWidget {
  const _Getippt(this.text, {super.key, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (!bewegungAn) return Text(text, style: style);
    final z = text.characters;
    return TweenAnimationBuilder<int>(
      key: ValueKey(text),
      tween: IntTween(begin: 0, end: z.length),
      duration: Duration(milliseconds: 300 + z.length * 16),
      builder: (context, n, _) => Text.rich(
        TextSpan(
          children: [
            TextSpan(text: z.take(n).toString()),
            // The rest keeps its place, so nothing jumps while typing.
            TextSpan(
              text: z.skip(n).toString(),
              style: const TextStyle(color: Color(0x00000000)),
            ),
          ],
        ),
        style: style,
      ),
    );
  }
}

/// The coach's picture, round, without the old frame.
class _Bild extends StatelessWidget {
  const _Bild({required this.lacht});
  final bool lacht;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('coach-avatar'),
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFF1A110A), width: 2),
    ),
    child: ClipOval(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Image.asset(
          lacht ? 'assets/images/coach_lacht.jpg' : 'assets/images/coach.jpg',
          key: ValueKey(lacht),
          fit: BoxFit.cover,
          width: 44,
          height: 44,
          semanticLabel: lacht ? 'Dein Coach lacht' : 'Dein Coach',
        ),
      ),
    ),
  );
}
