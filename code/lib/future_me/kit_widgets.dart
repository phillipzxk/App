import 'dart:async';

import 'package:flutter/material.dart';

import '../home/feed_widgets.dart';
import '../ui/coach_style.dart';
import 'future_me_card.dart';
import 'future_me_data.dart';

/// The small gold line for users without the Frame Kit, shown on the photo
/// screen (no pop-up). Tapping it tells what the kit is.
class KitZeile extends StatelessWidget {
  const KitZeile({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3E8D3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const ValueKey('kit-zeile'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          backgroundColor: CoachStyle.page,
          builder: (_) => const _KitInfo(),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CoachStyle.goldLight),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  kitZeile,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: CoachStyle.gold,
                  ),
                ),
              ),
              Text(
                '›',
                style: CoachStyle.cardTitle.copyWith(color: CoachStyle.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KitInfo extends StatelessWidget {
  const _KitInfo();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FRAMEWORK BY GROUNDSET', style: CoachStyle.goldLabel),
            const SizedBox(height: 6),
            Text('Das Frame Kit', style: CoachStyle.cardTitle),
            const SizedBox(height: 10),
            const HintText(
              'Matte mit Fußmarken, Abstandsband und Licht. So steht dein '
              'Foto jede Woche gleich: gleicher Stand, gleicher Abstand, '
              'gleiches Licht. Die App erkennt die Matte und richtet jedes '
              'Foto automatisch aus.',
            ),
            const SizedBox(height: 10),
            const HintText(
              'Framework Mat 29 € · Framework Kit 59 €. Der Code im Kit schaltet '
              'die Kit-Funktionen frei und dazu einen Monat Groundset gratis.',
            ),
            const SizedBox(height: 10),
            const HintText(
              'Der Link zum Shop kommt, sobald die Warteliste online ist.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the code from the kit's box. Returns true when it was accepted.
Future<bool> kitCodeEingeben(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _KitCodeDialog(),
  );
  return ok ?? false;
}

class _KitCodeDialog extends StatefulWidget {
  const _KitCodeDialog();

  @override
  State<_KitCodeDialog> createState() => _KitCodeDialogState();
}

class _KitCodeDialogState extends State<_KitCodeDialog> {
  final _controller = TextEditingController();
  String? _fehler;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ok() {
    if (kitCodeGueltig(_controller.text)) {
      Navigator.of(context).pop(true);
    } else {
      setState(
        () => _fehler = 'Der Code stimmt nicht. Er steht auf der Karte im Kit.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CoachStyle.page,
      title: Text('Code aus dem Kit', style: CoachStyle.cardTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('kit-code-feld'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _ok(),
            decoration: InputDecoration(
              hintText: 'z. B. FRAME-7K2Q9',
              errorText: _fehler,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 10),
          const HintText(
            'Schaltet die Kit-Funktionen dauerhaft frei, dazu einen Monat '
            'Groundset gratis.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Abbrechen',
            style: TextStyle(color: CoachStyle.inkSoft),
          ),
        ),
        TextButton(
          key: const ValueKey('kit-code-ok'),
          onPressed: _ok,
          child: const Text(
            'Freischalten',
            style: TextStyle(color: CoachStyle.gold),
          ),
        ),
      ],
    );
  }
}

/// Two weeks over each other with a slider in between, plus timelapse and
/// sharing (see Umsetzung/Foto-Kit.md).
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
