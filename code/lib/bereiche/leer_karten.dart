import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/umbau.dart';
import 'koerper_bilder.dart' show RegalBuch;
import 'glas.dart';

/// Calm glass card used instead of a big, almost empty picture
/// (draft "Leere Stellen", Phillip 2026-11-18).
class LeerKarte extends StatelessWidget {
  const LeerKarte({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
    decoration: BoxDecoration(
      color: Klar.glas,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Umbau.label),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

/// Small pill with a dashed-looking gold edge: a free place or an add.
class StrichPille extends StatelessWidget {
  const StrichPille(this.text, {super.key, this.plus = false});

  final String text;
  final bool plus;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: plus ? const Color(0x0FF5DFAE) : null,
      border: Border.all(
        color: plus ? const Color(0x66E0BF7E) : const Color(0x33E0BF7E),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (plus) ...[
          const Icon(Icons.add, size: 16, color: Glas.label),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Figtree',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: plus ? Glas.label : Glas.soft,
          ),
        ),
      ],
    ),
  );
}

Widget _fuss(String text) => Padding(
  padding: const EdgeInsets.only(top: 12),
  child: Text(
    text,
    textAlign: TextAlign.center,
    style: Glas.tSoft.copyWith(fontSize: 12),
  ),
);

/// Routinen without any routine yet: three free places and the add pill.
class RoutinenLeer extends StatelessWidget {
  const RoutinenLeer({super.key, required this.neu, required this.fuss});

  /// The add pill, already wrapped so it opens "Routine andocken".
  final Widget Function(Widget pille) neu;
  final String fuss;

  @override
  Widget build(BuildContext context) => LeerKarte(
    key: const ValueKey('routinen-leer'),
    label: 'DEINE ROUTINEN',
    children: [
      const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StrichPille('Routine 1'),
          StrichPille('Routine 2'),
          StrichPille('Routine 3'),
        ],
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: neu(const StrichPille('Neue Routine andocken', plus: true)),
      ),
      _fuss(fuss),
    ],
  );
}

/// Wissen, part 1: the skill course as a row of lessons.
class SkillKarte extends StatelessWidget {
  const SkillKarte({
    super.key,
    required this.skill,
    required this.lektionen,
    required this.erreicht,
    required this.text,
  });

  final String? skill;
  final int lektionen, erreicht;
  final String text;

  @override
  Widget build(BuildContext context) {
    final n = lektionen <= 0 ? 12 : lektionen;
    return LeerKarte(
      key: const ValueKey('skill-karte'),
      label: skill == null
          ? 'DEIN SKILL'
          : 'DEIN SKILL · ${skill!.toUpperCase()}',
      children: [
        Row(
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: skill != null && i < erreicht
                          ? Umbau.grad
                          : null,
                      color: skill != null && i < erreicht
                          ? null
                          : const Color(0x14FFF5E6),
                      border: skill != null && i == erreicht
                          ? Border.all(color: Glas.label, width: 1.5)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(text, style: Glas.tText.copyWith(fontSize: 14)),
      ],
    );
  }
}

/// Wissen, part 2: the library as books on a short shelf.
class BibliothekKarte extends StatelessWidget {
  const BibliothekKarte({super.key, required this.buecher, required this.neu});

  final List<RegalBuch> buecher;

  /// Wraps the add pill so it opens the library.
  final Widget Function(Widget pille) neu;

  static const _hoehen = [64.0, 58.0, 70.0, 54.0, 50.0];

  @override
  Widget build(BuildContext context) {
    final leer = buecher.isEmpty;
    return LeerKarte(
      key: const ValueKey('bibliothek-karte'),
      label: 'DEINE BIBLIOTHEK',
      children: [
        Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF4A3A27), width: 3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < (leer ? 3 : math.min(buecher.length, 5)); i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: leer ? _leerBuch(i) : _buch(buecher[i], i),
                ),
            ],
          ),
        ),
        if (leer) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: neu(const StrichPille('Erstes Buch ins Regal', plus: true)),
          ),
        ],
        _fuss('Gold = umgesetzt · Leuchten = liest du gerade'),
      ],
    );
  }

  Widget _leerBuch(int i) => Container(
    width: 22,
    height: _hoehen[i] - 6,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      border: Border.all(color: const Color(0x55E0BF7E)),
    ),
  );

  Widget _buch(RegalBuch b, int i) => Container(
    width: 34,
    height: _hoehen[i],
    padding: const EdgeInsets.only(bottom: 6),
    alignment: Alignment.bottomCenter,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
      gradient: b.art == 3 ? Umbau.grad : null,
      color: b.art == 3
          ? null
          : b.art == 2
          ? const Color(0x2EF5DFAE)
          : const Color(0x17FFF5E6),
      border: b.art == 3
          ? null
          : Border.all(
              color: b.art == 2 ? Glas.label : const Color(0x22FFF5E6),
            ),
      boxShadow: b.art == 2
          ? const [BoxShadow(color: Color(0x40E0BF7E), blurRadius: 10)]
          : null,
    ),
    child: RotatedBox(
      quarterTurns: 3,
      child: Text(
        b.titel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.w700,
          fontSize: 10,
          color: b.art == 3 ? Umbau.tinte : Glas.text,
        ),
      ),
    ),
  );
}
