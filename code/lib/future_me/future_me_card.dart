import 'dart:convert';

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';

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
        return 'Heute ist Fototag';
      case FotoStatus.nachholen:
        return 'Gestern verpasst, heute nachholen';
      case FotoStatus.spaeter:
        return 'Nächstes Foto am ${wochentage[lage.tag.weekday - 1]}';
    }
  }

  /// Small line under the main text.
  String _sub() {
    final e = einstellungen;
    if (e == null) return 'Jede Woche ein Foto, Start und Jetzt im Vergleich';
    final lage = fotoLage(today, e, fotos);
    final n = fotos.length;
    final schon = n == 0 ? 'noch keins' : (n == 1 ? '1 Foto' : '$n Fotos');
    return 'Woche ${lage.woche} · $schon';
  }

  bool get _jetzt {
    final e = einstellungen;
    if (e == null) return true;
    final s = fotoLage(today, e, fotos).status;
    return s == FotoStatus.heute || s == FotoStatus.nachholen;
  }

  @override
  Widget build(BuildContext context) {
    final letztes = fotos.isEmpty ? null : fotos.last;
    final pose = letztes == null || letztes.bilder.isEmpty
        ? null
        : letztes.bilder.keys.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: const ValueKey('zukunft-karte'),
        padding: const EdgeInsets.all(1.4),
        decoration: BoxDecoration(
          gradient: CoachStyle.goldEdgeGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: CoachStyle.goldGlow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.6),
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: const BoxDecoration(
                gradient: CoachStyle.creamGradient,
              ),
              child: InkWell(
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  child: Row(
                    children: [
                      _Rahmen(
                        child: pose == null
                            ? const Icon(
                                Icons.photo_camera_outlined,
                                color: CoachStyle.goldInk,
                                size: 24,
                              )
                            : FotoBild(
                                foto: letztes,
                                pose: pose,
                                width: 48,
                                height: 62,
                                radius: 6,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FORTSCHRITTSFOTO',
                              style: CoachStyle.goldLabel.copyWith(
                                color: const Color(0xFF7A5A2C),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _text(),
                              style: CoachStyle.cardTitle.copyWith(
                                color: CoachStyle.goldInk,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _sub(),
                              style: CoachStyle.body.copyWith(
                                fontSize: 12.5,
                                color: CoachStyle.creamInkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _jetzt
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: CoachStyle.goldInk,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                einstellungen == null ? 'Starten' : 'Foto',
                                style: CoachStyle.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: CoachStyle.goldLight,
                                ),
                              ),
                            )
                          : const Text(
                              '›',
                              style: TextStyle(
                                fontSize: 22,
                                color: CoachStyle.goldInk,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Photo frame with gold corner marks, like the camera outline.
class _Rahmen extends StatelessWidget {
  const _Rahmen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 66,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0x22000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF9A6D35), width: 1.4),
      ),
      alignment: Alignment.center,
      child: child,
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

/// Small "Foto" field on "Heute" next to the days in a row (Phillip
/// 2026-10-25): the latest photo as a thumbnail, the week and the next
/// photo day. On the photo day (or catch-up day) it turns gold.
class FotoFeld extends StatelessWidget {
  const FotoFeld({
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

  static const _kurz = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    final e = einstellungen;
    final lage = e == null ? null : fotoLage(today, e, fotos);
    final jetzt =
        lage != null &&
        (lage.status == FotoStatus.heute ||
            lage.status == FotoStatus.nachholen);
    final (titel, unter) = switch (lage?.status) {
      null => ('Festlegen ›', 'Fototag'),
      FotoStatus.heute => ('Heute dran ›', 'Woche ${lage!.woche}'),
      FotoStatus.nachholen => ('Nachholen ›', 'Woche ${lage!.woche}'),
      FotoStatus.spaeter => (
        'Woche ${lage!.woche}',
        'nächstes ${_kurz[lage.tag.weekday - 1]}',
      ),
    };
    final letztes = fotos.isEmpty ? null : fotos.last;
    final pose = letztes == null || letztes.bilder.isEmpty
        ? ''
        : letztes.bilder.keys.first;
    return Container(
      key: const ValueKey('foto-feld'),
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: jetzt ? CoachStyle.goldGradient : CoachStyle.goldEdgeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: jetzt
            ? const [BoxShadow(color: Color(0x55E0BF7E), blurRadius: 18)]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: jetzt
                  ? const [Color(0xFF3A2A16), Color(0xFF1A120B)]
                  : const [Color(0xFF261C12), Color(0xFF140F0A)],
            ),
            borderRadius: BorderRadius.circular(19),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 9, 10, 9),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: CoachStyle.goldEdge),
                    ),
                    child: letztes == null || pose.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 26,
                            color: Color(0xFF8A7158),
                          )
                        : FotoBild(
                            foto: letztes,
                            pose: pose,
                            width: 34,
                            height: 42,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'FOTO',
                          style: CoachStyle.goldLabel.copyWith(
                            fontFamily: 'Sora',
                            fontSize: 9,
                            letterSpacing: 1.4,
                          ),
                        ),
                        Text(
                          titel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CoachStyle.title.copyWith(
                            fontSize: 12.5,
                            height: 1.3,
                            color: CoachStyle.ink,
                          ),
                        ),
                        Text(
                          unter,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CoachStyle.body.copyWith(
                            fontSize: 11,
                            color: CoachStyle.beigeLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
