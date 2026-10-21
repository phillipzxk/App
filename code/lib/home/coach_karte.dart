import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
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
    child: const CoachAvatar(),
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
    return Container(
      key: const ValueKey('coach-karte'),
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: CoachStyle.goldEdgeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CoachStyle.nightShadow,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2118), Color(0xFF1B1611)],
          ),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _avatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DEIN COACH · HEUTE',
                    style: CoachStyle.goldLabel.copyWith(
                      color: CoachStyle.goldLight,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('coach-klappen'),
                  tooltip: zu ? 'Aufklappen' : 'Wegklappen',
                  onPressed: () => widget.onAnsicht(zu ? _sicht : 'zu:$_sicht'),
                  icon: Icon(
                    zu ? Icons.expand_more : Icons.expand_less,
                    color: CoachStyle.goldLight,
                  ),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: CoachStyle.goldEdge),
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            if (zu)
              InkWell(
                key: const ValueKey('coach-aufklappen'),
                onTap: () => widget.onAnsicht(_sicht),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CoachStyle.body.copyWith(
                            fontSize: 13.5,
                            color: CoachStyle.inkSoft,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aufklappen',
                        style: CoachStyle.body.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: CoachStyle.goldLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (widget.jubel case final j?) ...[
                const SizedBox(height: 12),
                Text.rich(
                  key: const ValueKey('coach-jubel'),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: j.split('\n').first,
                        style: CoachStyle.title.copyWith(
                          fontSize: 17,
                          height: 1.4,
                          color: const Color(0xFFF5DFAE),
                        ),
                      ),
                      if (j.contains('\n'))
                        TextSpan(
                          text: '\n${j.split('\n').skip(1).join(' ')}',
                          style: CoachStyle.body.copyWith(
                            color: CoachStyle.beigeLabel,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (widget.umschaltbar) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Umschalter(sicht: _sicht, onWahl: _zeige),
                ),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: punkte ? _punkte() : _text(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _text() => Text(
    widget.text,
    key: const ValueKey('coach-text'),
    style: CoachStyle.body.copyWith(color: CoachStyle.onDark),
  );

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
              style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
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
        for (final p in widget.stichpunkte)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4A85E),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    p,
                    style: CoachStyle.body.copyWith(color: CoachStyle.onDark),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Small pill "Text | Stichpunkte".
class _Umschalter extends StatelessWidget {
  const _Umschalter({required this.sicht, required this.onWahl});

  final String sicht;
  final ValueChanged<String> onWahl;

  @override
  Widget build(BuildContext context) {
    Widget teil(String key, String label, String wert) {
      final an = sicht == wert;
      return Semantics(
        button: true,
        selected: an,
        child: InkWell(
          key: ValueKey(key),
          borderRadius: BorderRadius.circular(999),
          onTap: () => onWahl(wert),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: an ? CoachStyle.goldGradient : null,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: CoachStyle.body.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: an ? CoachStyle.goldInk : CoachStyle.beigeLabel,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1510),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF4A3D2E)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            teil('coach-als-text', 'Text', 'text'),
            teil('coach-als-punkte', 'Stichpunkte', 'punkte'),
          ],
        ),
      ),
    );
  }
}
