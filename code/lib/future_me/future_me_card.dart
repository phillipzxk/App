import 'dart:convert';

import 'package:flutter/material.dart';

import '../home/feed_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'future_me_data.dart';

/// The card for "Dein zukünftiges Ich" on "Heute": asks for the photo on the
/// photo day, offers the catch-up the day after a missed one, and otherwise
/// names the next photo day. Tapping it opens the page.
class FutureMeCard extends StatelessWidget {
  const FutureMeCard({
    super.key,
    required this.today,
    required this.einstellungen,
    required this.fotos,
    required this.onOpen,
    required this.onFoto,
  });

  final DateTime today;
  final FotoEinstellungen? einstellungen;
  final List<WochenFoto> fotos;
  final VoidCallback onOpen;
  final VoidCallback onFoto;

  @override
  Widget build(BuildContext context) {
    final e = einstellungen;
    return GestureDetector(
      key: const ValueKey('zukunft-karte'),
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: e == null ? _setup() : _status(fotoLage(today, e, fotos), e),
    );
  }

  Widget _setup() => FeedCard(
    title: 'Dein zukünftiges Ich',
    children: [
      const HintText(
        'Leg einmal deinen Fototag und deine Posen fest. Dann siehst du jede '
        'Woche, wie du dich veränderst.',
      ),
      const SizedBox(height: 12),
      GhostButton(label: 'Einrichten', onPressed: onOpen),
    ],
  );

  Widget _status(FotoLage lage, FotoEinstellungen e) {
    switch (lage.status) {
      case FotoStatus.heute:
        return FeedCard(
          title: 'Dein zukünftiges Ich',
          highlight: true,
          trailing: const _DarkTag('Heute Fototag'),
          children: [
            Text(
              'Woche ${lage.woche}. Heute ist dein Foto dran.',
              style: CoachStyle.body.copyWith(fontSize: 14.5),
            ),
            if (fotos.isNotEmpty) ...[
              const SizedBox(height: 10),
              _Mini(first: fotos.first, last: fotos.last, pose: e.posen.first),
            ],
            const SizedBox(height: 12),
            MainButton(
              key: const ValueKey('foto-machen'),
              label: 'Foto machen',
              onPressed: onFoto,
            ),
            const SizedBox(height: 8),
            const HintText(
              'Schaffst du es heute nicht, kannst du es morgen einmal '
              'nachholen.',
            ),
          ],
        );
      case FotoStatus.nachholen:
        return FeedCard(
          title: 'Dein zukünftiges Ich',
          trailing: const Tag('Gestern verpasst'),
          children: [
            Text(
              'Dein Fototag war gestern. Du kannst das Foto heute noch '
              'nachholen, danach fällt die Woche aus.',
              style: CoachStyle.body.copyWith(fontSize: 14.5),
            ),
            const SizedBox(height: 12),
            GhostButton(
              key: const ValueKey('foto-nachholen'),
              label: 'Heute nachholen',
              onPressed: onFoto,
            ),
          ],
        );
      case FotoStatus.spaeter:
        return FeedCard(
          title: 'Dein zukünftiges Ich',
          trailing: const Tag('Nächstes Foto'),
          children: [
            Text(
              '${wochentage[lage.tag.weekday - 1]} · Woche ${lage.woche}',
              style: CoachStyle.body.copyWith(fontSize: 14.5),
            ),
          ],
        );
    }
  }
}

class _DarkTag extends StatelessWidget {
  const _DarkTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: CoachStyle.dark,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: CoachStyle.goldLabel.copyWith(
        fontSize: 11,
        letterSpacing: 0,
        color: CoachStyle.goldSoft,
      ),
    ),
  );
}

/// First photo next to the latest one, small.
class _Mini extends StatelessWidget {
  const _Mini({required this.first, required this.last, required this.pose});

  final WochenFoto first;
  final WochenFoto last;
  final String pose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FotoBild(foto: first, pose: pose, width: 44, height: 58),
        if (last != first) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('→', style: TextStyle(color: CoachStyle.gold)),
          ),
          FotoBild(foto: last, pose: pose, width: 44, height: 58),
        ],
        const SizedBox(width: 10),
        const Expanded(child: HintText('Start neben deinem letzten Foto')),
      ],
    );
  }
}

/// One stored photo, or a sand-coloured box when the pose has none.
class FotoBild extends StatelessWidget {
  const FotoBild({
    super.key,
    required this.foto,
    required this.pose,
    this.width,
    this.height,
    this.radius = 8,
  });

  final WochenFoto? foto;
  final String pose;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final data = foto?.bilder[pose];
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFDDD3C1),
        child: data == null
            ? null
            : Image.memory(
                base64Decode(data),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
      ),
    );
  }
}
