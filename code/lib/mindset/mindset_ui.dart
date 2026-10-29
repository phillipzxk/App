import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../data/user_profile.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'mindset_coach.dart';

/// What every Mindset page needs.
class MindsetUmfeld {
  const MindsetUmfeld({
    required this.stand,
    required this.profile,
    required this.coach,
    required this.jetzt,
    this.tagDanach = const [],
    this.kontext = '',
  });

  final MindsetStand stand;
  final UserProfile profile;
  final MindsetCoach coach;
  final DateTime Function() jetzt;

  /// What comes next in today's plan (e.g. "Abendessen 19:00"), for the
  /// Danach-Plan when the coach is not reachable.
  final List<String> tagDanach;

  /// Text for the coach about the user's day and areas.
  final String kontext;
}

/// A glass text field.
class GlasFeld extends StatelessWidget {
  const GlasFeld({
    super.key,
    required this.controller,
    required this.hint,
    this.zeilen = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int zeilen;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder rand(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c),
    );
    return TextField(
      controller: controller,
      minLines: zeilen,
      maxLines: zeilen == 1 ? 1 : zeilen + 4,
      onChanged: onChanged,
      style: Glas.tText.copyWith(fontWeight: FontWeight.w500),
      cursorColor: CoachStyle.goldLight,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: Glas.tSoft.copyWith(fontSize: 14),
        filled: true,
        fillColor: const Color(0x0FFFECC8),
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: rand(const Color(0x2EFFEECD)),
        focusedBorder: rand(CoachStyle.goldLight),
      ),
    );
  }
}

/// Gold (or ghost) button in the glass look.
class GlasKnopf extends StatelessWidget {
  const GlasKnopf({
    super.key,
    required this.label,
    required this.onTap,
    this.ghost = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool ghost;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final an = onTap != null;
    return Opacity(
      opacity: an ? 1 : .45,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: ghost ? null : CoachStyle.goldGradient,
              color: ghost ? const Color(0x0FFFECC8) : null,
              border: ghost ? Border.all(color: const Color(0x38FFEECD)) : null,
              boxShadow: ghost || !an ? null : CoachStyle.goldGlow,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: ghost ? CoachStyle.goldLight : CoachStyle.goldInk,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: ghost
                              ? CoachStyle.goldLight
                              : CoachStyle.goldInk,
                        ),
                      ),
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

/// Small tappable chip, gold when picked.
class GlasChip extends StatelessWidget {
  const GlasChip({
    super.key,
    required this.label,
    required this.an,
    required this.onTap,
  });

  final String label;
  final bool an;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: an ? CoachStyle.goldGradient : null,
        color: an ? null : const Color(0x12FFECC8),
        border: Border.all(
          color: an ? Colors.transparent : const Color(0x2EFFEECD),
        ),
      ),
      child: Text(
        label,
        style: Glas.tLabel.copyWith(
          fontSize: 13,
          color: an ? CoachStyle.goldInk : Glas.text,
        ),
      ),
    ),
  );
}

/// Round tick box.
class GlasHaken extends StatelessWidget {
  const GlasHaken({super.key, required this.an, required this.onTap});

  final bool an;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: an ? CoachStyle.goldGradient : null,
        border: Border.all(
          color: an ? Colors.transparent : const Color(0x55FFEECD),
          width: 1.4,
        ),
        boxShadow: an ? CoachStyle.goldGlow : null,
      ),
      child: an
          ? const Icon(Icons.check, size: 17, color: CoachStyle.goldInk)
          : null,
    ),
  );
}

/// A glass block with a small label on top.
class Block extends StatelessWidget {
  const Block({
    super.key,
    this.label,
    this.rechts,
    required this.children,
    this.art = GlasArt.normal,
  });

  final String? label;
  final String? rechts;
  final List<Widget> children;
  final GlasArt art;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: GlasBox(
      art: art,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null)
            Row(
              children: [
                Expanded(child: Text(label!, style: Glas.tLabel)),
                if (rechts != null) Text(rechts!, style: Glas.tSoft),
              ],
            ),
          if (label != null) const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

/// The coach speaking inside a block.
class CoachZeile extends StatelessWidget {
  const CoachZeile(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CoachAvatar(size: 30),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: Glas.tText.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14.5,
          ),
        ),
      ),
    ],
  );
}

/// Shows [text] as a short note at the bottom.
void hinweis(BuildContext context, String text) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A2219),
        content: Text(text, style: Glas.tText.copyWith(fontSize: 14)),
      ),
    );
}

/// A row: tick, text and a small status on the right.
class HakenZeile extends StatelessWidget {
  const HakenZeile({
    super.key,
    required this.an,
    required this.onTap,
    required this.titel,
    this.unter,
    this.rechts,
  });

  final bool an;
  final VoidCallback onTap;
  final String titel;
  final String? unter;
  final String? rechts;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        GlasHaken(an: an, onTap: onTap),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titel, style: Glas.tText.copyWith(fontSize: 14.5)),
              if (unter != null && unter!.isNotEmpty)
                Text(unter!, style: Glas.tSoft),
            ],
          ),
        ),
        if (rechts != null) Text(rechts!, style: Glas.tSoft),
      ],
    ),
  );
}
