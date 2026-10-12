import 'package:flutter/material.dart';

import '../data/profile_store.dart';
import '../data/user_profile.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
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
    return CoachPage(
      gradient: _phase == _Phase.summary
          ? CoachStyle.summaryBackground
          : CoachStyle.questionBackground,
      child: switch (_phase) {
        _Phase.questions => _buildQuestion(),
        _Phase.evaluating => const ReadingIndicator(
          text: 'Ich lese deine Antworten …',
        ),
        _Phase.summary => _Summary(
          summary: _profile.zusammenfassung,
          onContinue: () => widget.onFinished(_profile),
        ),
      },
    );
  }

  Widget _buildQuestion() {
    final question = onboardingQuestions[_index];
    final controller = _controllers[_index];
    return Column(
      key: ValueKey(_index),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentBar(count: onboardingQuestions.length, done: _index + 1),
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
          child: AnswerField(
            controller: controller,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        MainButton(
          label: _isLast ? 'Fertig' : 'Weiter',
          onPressed: controller.text.trim().isEmpty ? null : _next,
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
        CoachNote(
          text: summary.isNotEmpty
              ? summary
              : 'Deine Antworten sind gespeichert. Deine persönliche '
                    'Auswertung kommt bald, sobald dein Coach '
                    'freigeschaltet ist.',
        ),
        const Spacer(),
        MainButton(label: "Los geht's", onPressed: onContinue),
      ],
    );
  }
}
