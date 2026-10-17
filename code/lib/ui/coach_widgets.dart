import 'package:flutter/material.dart';

import 'coach_style.dart';
import 'logo.dart';

/// Segmented progress bar above a question, e.g. 2 of 4 filled.
class SegmentBar extends StatelessWidget {
  const SegmentBar({super.key, required this.count, required this.done});

  final int count;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < done ? CoachStyle.gold : CoachStyle.bar,
              ),
            ),
          ),
      ],
    );
  }
}

/// One-line field for the user's first name.
class NameField extends StatelessWidget {
  const NameField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      style: CoachStyle.body,
      cursorColor: CoachStyle.gold,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Dein Vorname',
        hintStyle: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
        filled: true,
        fillColor: CoachStyle.card,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: AnswerField.border(CoachStyle.line),
        focusedBorder: AnswerField.border(CoachStyle.gold),
      ),
    );
  }
}

/// Large free-text field for the answers in the user's own words.
class AnswerField extends StatelessWidget {
  const AnswerField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      expands: true,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      style: CoachStyle.body,
      cursorColor: CoachStyle.gold,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Schreib in deinen eigenen Worten …',
        hintStyle: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
        filled: true,
        fillColor: CoachStyle.card,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: border(CoachStyle.line),
        focusedBorder: border(CoachStyle.gold),
      ),
    );
  }

  static OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color),
  );
}

/// Dark full-width button with gold text; disabled when [onPressed] is null.
class MainButton extends StatelessWidget {
  const MainButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: CoachStyle.dark,
        foregroundColor: CoachStyle.goldSoft,
        disabledBackgroundColor: const Color(0xFFE2DACB),
        disabledForegroundColor: const Color(0xFFA39A8A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// Logo, a short text and a gold spinner while the AI reads the answers.
class ReadingIndicator extends StatelessWidget {
  const ReadingIndicator({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LogoMark(size: 72),
        const SizedBox(height: 16),
        Text(
          text,
          style: CoachStyle.question.copyWith(fontSize: 19),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        const SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            color: CoachStyle.gold,
            strokeWidth: 2.5,
          ),
        ),
      ],
    );
  }
}

/// Card with a gold edge, used for AI texts.
class CoachNote extends StatelessWidget {
  const CoachNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoachStyle.card,
        border: Border.all(color: const Color(0xFFE2CFA9)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: CoachStyle.body),
    );
  }
}

/// Sand-coloured page with the centred 480 px column used on every screen.
class CoachPage extends StatelessWidget {
  const CoachPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachStyle.page,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: CoachStyle.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The coach's own words on a dark card with a gold label, so the most
/// important text of the day stands out.
class CoachCard extends StatelessWidget {
  const CoachCard({super.key, required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: CoachStyle.coachGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4A4134)),
        boxShadow: CoachStyle.darkShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CoachAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: CoachStyle.goldLabel.copyWith(
                    color: CoachStyle.goldLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: CoachStyle.body.copyWith(color: CoachStyle.onDark)),
        ],
      ),
    );
  }
}

/// The coach's face: the proboscis monkey, round with a gold edge.
class CoachAvatar extends StatelessWidget {
  const CoachAvatar({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('coach-avatar'),
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CoachStyle.goldLight,
        boxShadow: [
          const BoxShadow(color: Color(0xFF2A2620), spreadRadius: 2),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/coach.jpg',
          fit: BoxFit.cover,
          semanticLabel: 'Dein Coach',
        ),
      ),
    );
  }
}
