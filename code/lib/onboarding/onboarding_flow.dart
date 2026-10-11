import 'package:flutter/material.dart';

import '../data/profile_store.dart';
import '../data/user_profile.dart';
import '../ui/coach_style.dart';
import 'onboarding_evaluator.dart';
import 'onboarding_questions.dart';

/// The onboarding: six questions answered in the user's own words, then the
/// AI reads all answers at once and shows "So sehe ich dich gerade".
///
/// The profile is saved once all six answers are given, so a user who quits
/// halfway starts over next time.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.store,
    required this.evaluator,
    required this.onFinished,
  });

  final ProfileStore store;
  final OnboardingEvaluator evaluator;
  final ValueChanged<UserProfile> onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

enum _Phase { questions, evaluating, summary }

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Phase _phase = _Phase.questions;
  int _index = 0;
  UserProfile _profile = const UserProfile();
  late final List<TextEditingController> _controllers = [
    for (final _ in onboardingQuestions) TextEditingController(),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isLast => _index == onboardingQuestions.length - 1;

  Future<void> _next() async {
    if (!_isLast) {
      setState(() => _index++);
      return;
    }
    var profile = const UserProfile();
    for (var i = 0; i < onboardingQuestions.length; i++) {
      profile = onboardingQuestions[i].apply(
        profile,
        _controllers[i].text.trim(),
      );
    }
    setState(() => _phase = _Phase.evaluating);
    final summary = await widget.evaluator.summarize(profile);
    profile = profile.copyWith(zusammenfassung: summary ?? '');
    await widget.store.save(profile);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _phase = _Phase.summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _phase == _Phase.summary
              ? CoachStyle.summaryBackground
              : CoachStyle.questionBackground,
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: switch (_phase) {
                  _Phase.questions => _buildQuestion(),
                  _Phase.evaluating => const _Evaluating(),
                  _Phase.summary => _Summary(
                    summary: _profile.zusammenfassung,
                    onContinue: () => widget.onFinished(_profile),
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final question = onboardingQuestions[_index];
    final controller = _controllers[_index];
    return Column(
      key: ValueKey(_index),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressBar(done: _index + 1),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_index > 0)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: CoachStyle.inkSoft),
                tooltip: 'Zurück',
                onPressed: () => setState(() => _index--),
              ),
            Expanded(
              child: Text(
                'FRAGE ${_index + 1} VON ${onboardingQuestions.length} · '
                '${question.topic.toUpperCase()}',
                style: CoachStyle.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(question.question, style: CoachStyle.question),
        const SizedBox(height: 20),
        Expanded(
          child: TextField(
            controller: controller,
            expands: true,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: CoachStyle.body,
            cursorColor: CoachStyle.ink,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Schreib in deinen eigenen Worten …',
              hintStyle: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: _border(0.18),
              focusedBorder: _border(0.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _MainButton(
          label: _isLast ? 'Fertig' : 'Weiter',
          onPressed: controller.text.trim().isEmpty ? null : _next,
        ),
      ],
    );
  }

  static OutlineInputBorder _border(double alpha) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: alpha)),
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < onboardingQuestions.length; i++)
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

class _Evaluating extends StatelessWidget {
  const _Evaluating();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: CoachStyle.gold),
        SizedBox(height: 20),
        Text(
          'Ich lese deine Antworten …',
          style: CoachStyle.question,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary, required this.onContinue});

  final String summary;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Text('DEIN START', style: CoachStyle.label),
        const SizedBox(height: 12),
        const Text('So sehe ich dich gerade', style: CoachStyle.question),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            border: const Border(
              left: BorderSide(color: CoachStyle.gold, width: 3),
            ),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
          ),
          child: Text(
            summary.isNotEmpty
                ? summary
                : 'Deine Antworten sind gespeichert. Deine persönliche '
                      'Auswertung kommt bald, sobald dein Coach '
                      'freigeschaltet ist.',
            style: CoachStyle.body,
          ),
        ),
        const Spacer(),
        _MainButton(label: "Los geht's", onPressed: onContinue),
      ],
    );
  }
}

class _MainButton extends StatelessWidget {
  const _MainButton({required this.label, required this.onPressed});

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
