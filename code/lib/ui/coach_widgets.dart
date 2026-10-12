import 'package:flutter/material.dart';

import 'coach_style.dart';

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
                color: i < done
                    ? CoachStyle.ink
                    : Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
      ],
    );
  }
}

/// Large free-text field on the dark background.
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
      cursorColor: CoachStyle.ink,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Schreib in deinen eigenen Worten …',
        hintStyle: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: _border(0.18),
        focusedBorder: _border(0.5),
      ),
    );
  }

  static OutlineInputBorder _border(double alpha) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: alpha)),
  );
}

/// Light full-width button; disabled when [onPressed] is null.
class MainButton extends StatelessWidget {
  const MainButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: CoachStyle.ink,
        foregroundColor: CoachStyle.tealDeep,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.18),
        disabledForegroundColor: CoachStyle.inkSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// Spinner with a short text while the AI reads the answers.
class ReadingIndicator extends StatelessWidget {
  const ReadingIndicator({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: CoachStyle.gold),
        const SizedBox(height: 20),
        Text(text, style: CoachStyle.question, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Text block with the gold bar on the left, used for AI texts.
class CoachNote extends StatelessWidget {
  const CoachNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: const Border(
          left: BorderSide(color: CoachStyle.gold, width: 3),
        ),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
      ),
      child: Text(text, style: CoachStyle.body),
    );
  }
}

/// Dark gradient page with the centred 480 px column used on every screen.
class CoachPage extends StatelessWidget {
  const CoachPage({
    super.key,
    required this.child,
    this.gradient = CoachStyle.questionBackground,
  });

  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
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
