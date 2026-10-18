import 'package:flutter/material.dart';

import '../data/profile_store.dart';
import '../data/user_profile.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../ui/logo.dart';
import 'onboarding_evaluator.dart';
import 'onboarding_questions.dart';

/// The onboarding: first the user's name, then six questions answered by
/// tapping answers plus a short field in the user's own words, then the AI reads all answers at once and shows
/// "So sehe ich dich gerade".
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

enum _Phase { name, questions, evaluating, summary }

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Phase _phase = _Phase.name;
  int _index = 0;
  UserProfile _profile = const UserProfile();
  final _nameController = TextEditingController();
  late final List<TextEditingController> _controllers = [
    for (final _ in onboardingQuestions) TextEditingController(),
  ];
  late final List<Set<String>> _picked = [
    for (final _ in onboardingQuestions) <String>{},
  ];

  @override
  void dispose() {
    _nameController.dispose();
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
    var profile = UserProfile(name: _nameController.text.trim());
    for (var i = 0; i < onboardingQuestions.length; i++) {
      final q = onboardingQuestions[i];
      profile = q.apply(profile, q.compose(_picked[i], _controllers[i].text));
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
      child: switch (_phase) {
        _Phase.name => _buildName(),
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

  Widget _buildName() {
    return Column(
      key: const ValueKey('name'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Align(alignment: Alignment.centerLeft, child: LogoMark(size: 56)),
        const SizedBox(height: 16),
        const Text('BEVOR WIR STARTEN', style: CoachStyle.goldLabel),
        const SizedBox(height: 12),
        const Text('Wie heißt du?', style: CoachStyle.question),
        const SizedBox(height: 6),
        Text(
          'So spricht dich dein Coach an.',
          style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
        ),
        const SizedBox(height: 20),
        NameField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
        ),
        const Spacer(),
        MainButton(
          label: 'Weiter',
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () => setState(() => _phase = _Phase.questions),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    final question = onboardingQuestions[_index];
    final controller = _controllers[_index];
    final picked = _picked[_index];
    return Column(
      key: ValueKey(_index),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentBar(count: onboardingQuestions.length, done: _index + 1),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: CoachStyle.inkSoft),
              tooltip: 'Zurück',
              onPressed: () => setState(() {
                if (_index > 0) {
                  _index--;
                } else {
                  _phase = _Phase.name;
                }
              }),
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
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(question.question, style: CoachStyle.question),
                const SizedBox(height: 6),
                Text(
                  'Tippe an, was passt. Mehreres ist möglich.',
                  style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
                ),
                const SizedBox(height: 16),
                for (final option in question.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _OptionTile(
                      label: option,
                      selected: picked.contains(option),
                      onTap: () => setState(() {
                        if (!picked.remove(option)) picked.add(option);
                      }),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  question.fieldRequired
                      ? question.fieldLabel
                      : '${question.fieldLabel} (freiwillig)',
                  style: CoachStyle.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  style: CoachStyle.body,
                  cursorColor: CoachStyle.gold,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: question.fieldHint,
                    hintStyle: CoachStyle.body.copyWith(
                      color: CoachStyle.inkSoft,
                    ),
                    filled: true,
                    fillColor: CoachStyle.card,
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: AnswerField.border(CoachStyle.line),
                    focusedBorder: AnswerField.border(CoachStyle.gold),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        MainButton(
          label: _isLast ? 'Fertig' : 'Weiter',
          onPressed: question.canContinue(picked, controller.text)
              ? _next
              : null,
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
        const Text('DEIN START', style: CoachStyle.goldLabel),
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

/// One answer to tap; gold edge and check mark when picked.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? CoachStyle.goldSoft : CoachStyle.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? CoachStyle.gold : CoachStyle.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: CoachStyle.body)),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: selected ? CoachStyle.gold : CoachStyle.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
