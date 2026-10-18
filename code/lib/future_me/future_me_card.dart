import 'dart:convert';

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';

import '../home/feed_widgets.dart';
import 'future_me_data.dart';

/// The field for "Dein zukünftiges Ich" on "Heute": says when the photo is
/// due (today, catch-up today, or the next photo day). Tapping it opens the
/// page, where the photo is taken.
class FutureMeCard extends StatelessWidget {
  const FutureMeCard({
    super.key,
    required this.today,
    required this.einstellungen,
    required this.fotos,
    required this.onOpen,
  });

  final DateTime today;
  final FotoEinstellungen? einstellungen;
  final List<WochenFoto> fotos;
  final VoidCallback onOpen;

  String _text() {
    final e = einstellungen;
    if (e == null) return 'Fototag und Posen festlegen';
    final lage = fotoLage(today, e, fotos);
    switch (lage.status) {
      case FotoStatus.heute:
        return 'Heute Fototag, Woche ${lage.woche} · Foto machen';
      case FotoStatus.nachholen:
        return 'gestern verpasst, heute noch nachholen';
      case FotoStatus.spaeter:
        return 'nächstes Foto ${wochentage[lage.tag.weekday - 1]}, '
            'Woche ${lage.woche}';
    }
  }

  @override
  Widget build(BuildContext context) => HinweisFeld(
    key: const ValueKey('zukunft-karte'),
    icon: Icons.photo_camera_outlined,
    title: 'Dein zukünftiges Ich',
    text: _text(),
    onTap: onOpen,
  );
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
        color: CoachStyle.bar,
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
