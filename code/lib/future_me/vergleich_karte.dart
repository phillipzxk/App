import 'dart:async';

import 'package:flutter/material.dart';

import '../home/feed_widgets.dart';
import '../ui/coach_style.dart';
import 'future_me_card.dart';
import 'future_me_data.dart';

/// Two weeks over each other with a slider in between, plus timelapse and
/// sharing (see Umsetzung/Dein zukünftiges Ich.md).
class VergleichKarte extends StatefulWidget {
  const VergleichKarte({
    super.key,
    required this.fotos,
    required this.pose,
    required this.woche,
  });

  /// All weekly photos, oldest first; at least one.
  final List<WochenFoto> fotos;
  final String pose;

  /// Week number of a photo.
  final int Function(WochenFoto) woche;

  @override
  State<VergleichKarte> createState() => _VergleichKarteState();
}

class _VergleichKarteState extends State<VergleichKarte> {
  late int _links = 0;
  late int _rechts = widget.fotos.length - 1;
  double _wert = 0.5;

  @override
  void didUpdateWidget(VergleichKarte old) {
    super.didUpdateWidget(old);
    if (old.fotos.length != widget.fotos.length) {
      _links = 0;
      _rechts = widget.fotos.length - 1;
    }
  }

  Widget _wahl(int value, ValueChanged<int> onChanged, String key) {
    return DropdownButton<int>(
      key: ValueKey(key),
      value: value,
      underline: const SizedBox.shrink(),
      style: CoachStyle.cardTitle.copyWith(fontSize: 13),
      items: [
        for (var i = 0; i < widget.fotos.length; i++)
          DropdownMenuItem(
            value: i,
            child: Text('Woche ${widget.woche(widget.fotos[i])}'),
          ),
      ],
      onChanged: (v) => v == null ? null : setState(() => onChanged(v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final links = widget.fotos[_links];
    final rechts = widget.fotos[_rechts];
    return FeedCard(
      title: 'Vergleich',
      icon: Icons.compare,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _wahl(_links, (v) => _links = v, 'vergleich-links'),
            const Icon(Icons.compare_arrows, color: CoachStyle.gold, size: 20),
            _wahl(_rechts, (v) => _rechts = v, 'vergleich-rechts'),
          ],
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: LayoutBuilder(
            builder: (context, c) {
              final x = c.maxWidth * _wert;
              return GestureDetector(
                onHorizontalDragUpdate: (d) => setState(
                  () => _wert = (d.localPosition.dx / c.maxWidth).clamp(0, 1),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FotoBild(foto: rechts, pose: widget.pose, radius: 14),
                    ClipRect(
                      clipper: _LinksClipper(x),
                      child: FotoBild(
                        foto: links,
                        pose: widget.pose,
                        radius: 14,
                      ),
                    ),
                    Positioned(
                      left: x - 1,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 2, color: CoachStyle.gold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Slider(
          key: const ValueKey('vergleich-regler'),
          value: _wert,
          activeColor: CoachStyle.gold,
          inactiveColor: CoachStyle.line,
          onChanged: (v) => setState(() => _wert = v),
        ),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                key: const ValueKey('zeitraffer'),
                label: 'Zeitraffer',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _Zeitraffer(
                    fotos: widget.fotos,
                    pose: widget.pose,
                    woche: widget.woche,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GhostButton(
                key: const ValueKey('teilen'),
                label: 'Teilen',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Teilen öffnet in der Handy-Version Instagram, TikTok '
                      'und Co. Geteilt wird nur, wenn du tippst.',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LinksClipper extends CustomClipper<Rect> {
  const _LinksClipper(this.x);

  final double x;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, x, size.height);

  @override
  bool shouldReclip(_LinksClipper old) => old.x != x;
}

/// Plays all weeks one after another.
class _Zeitraffer extends StatefulWidget {
  const _Zeitraffer({
    required this.fotos,
    required this.pose,
    required this.woche,
  });

  final List<WochenFoto> fotos;
  final String pose;
  final int Function(WochenFoto) woche;

  @override
  State<_Zeitraffer> createState() => _ZeitrafferState();
}

class _ZeitrafferState extends State<_Zeitraffer> {
  int _i = 0;
  late final Timer _timer = Timer.periodic(
    const Duration(milliseconds: 700),
    (_) => setState(() => _i = (_i + 1) % widget.fotos.length),
  );

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fotos[_i];
    return Dialog(
      backgroundColor: CoachStyle.dark,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: FotoBild(foto: f, pose: widget.pose, radius: 14),
            ),
            const SizedBox(height: 10),
            Text(
              'Woche ${widget.woche(f)}',
              style: CoachStyle.cardTitle.copyWith(color: CoachStyle.goldSoft),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Schließen',
                style: TextStyle(color: CoachStyle.goldLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
