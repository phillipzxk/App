import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../data/profile_store.dart';
import '../data/user_profile.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../mindset/mindset_ui.dart' show CoachZeile;
import '../ui/logo.dart';
import 'onboarding_evaluator.dart';
import 'onboarding_questions.dart';

/// The onboarding: first the user's name, then seven questions (one per
/// area since 2026-10-31) answered by
/// tapping answers plus a short field in the user's own words, then the AI reads all answers at once and shows
/// "So sehe ich dich gerade".
///
/// The profile is saved once all answers are given, so a user who quits
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
      dark: true,
      glas: true,
      child: switch (_phase) {
        _Phase.name => _buildName(),
        _Phase.questions => _buildQuestion(),
        _Phase.evaluating => const ReadingIndicator(
          text: 'Ich lese deine Antworten …',
          dark: true,
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
        GoldSchrift('Wie heißt du?', style: CoachStyle.question),
        const SizedBox(height: 6),
        Text(
          'So spricht dich dein Coach an.',
          style: CoachStyle.body.copyWith(color: Glas.soft),
        ),
        const SizedBox(height: 20),
        _GlasFeld(
          controller: _nameController,
          hint: 'Dein Vorname',
          einzeilig: true,
          onChanged: (_) => setState(() {}),
        ),
        const Spacer(),
        MainButton(
          gold: true,
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
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Glas.soft),
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
                style: Glas.tLabel.copyWith(fontSize: 11.5, letterSpacing: 1.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _WurzelFortschritt(count: onboardingQuestions.length, done: _index + 1),
        const SizedBox(height: 18),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question.question,
                  style: CoachStyle.question.copyWith(color: Glas.text),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tippe an, was passt. Mehreres ist möglich.',
                  style: CoachStyle.body.copyWith(color: Glas.soft),
                ),
                const SizedBox(height: 16),
                for (final option in question.options) ...[
                  for (final g in question.gruppen.entries)
                    if (g.value == option)
                      Padding(
                        padding: EdgeInsets.only(
                          top: g.key.isEmpty ? 6 : 8,
                          bottom: 8,
                          left: 2,
                        ),
                        child: g.key.isEmpty
                            ? const SizedBox.shrink()
                            : Text(
                                g.key.toUpperCase(),
                                style: Glas.tLabel.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 1.6,
                                ),
                              ),
                      ),
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
                ],
                const SizedBox(height: 14),
                Text(
                  question.fieldRequired
                      ? question.fieldLabel
                      : '${question.fieldLabel} (freiwillig)',
                  style: CoachStyle.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Glas.text,
                  ),
                ),
                const SizedBox(height: 8),
                _GlasFeld(
                  controller: controller,
                  hint: question.fieldHint,
                  onChanged: (_) => setState(() {}),
                ),
                if (question.coach.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  GlasBox(
                    padding: const EdgeInsets.all(12),
                    radius: 18,
                    child: CoachZeile(question.coach),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        MainButton(
          gold: true,
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
        GoldSchrift('So sehe ich dich gerade', style: CoachStyle.question),
        const SizedBox(height: 20),
        GlasBox(
          art: GlasArt.gold,
          padding: const EdgeInsets.all(18),
          child: CoachZeile(
            summary.isNotEmpty
                ? summary
                : 'Deine Antworten sind gespeichert. Deine persönliche '
                      'Auswertung kommt bald, sobald dein Coach '
                      'freigeschaltet ist.',
          ),
        ),
        const Spacer(),
        MainButton(label: "Los geht's", gold: true, onPressed: onContinue),
      ],
    );
  }
}

/// The progress as a root: one dot per question, joined by a line that
/// turns gold up to the current question.
class _WurzelFortschritt extends StatelessWidget {
  const _WurzelFortschritt({required this.count, required this.done});

  final int count;
  final int done;

  @override
  Widget build(BuildContext context) {
    Widget punkt(bool an) => AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: an ? 9 : 7,
      height: an ? 9 : 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: an ? const Color(0xFFF3DCA6) : const Color(0x26FFECDC),
        boxShadow: an
            ? const [BoxShadow(color: Color(0xB3E0BF7E), blurRadius: 10)]
            : null,
      ),
    );
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          punkt(i < done),
          if (i < count - 1)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 2.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: i < done - 1
                      ? const LinearGradient(
                          colors: [Color(0xFFC08E45), Color(0xFFF3DCA6)],
                        )
                      : null,
                  color: i < done - 1 ? null : const Color(0x1AFFECDC),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// A text field on glass.
class _GlasFeld extends StatelessWidget {
  const _GlasFeld({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.einzeilig = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool einzeilig;

  @override
  Widget build(BuildContext context) => GlasBox(
    padding: EdgeInsets.zero,
    radius: 18,
    child: TextField(
      controller: controller,
      minLines: einzeilig ? 1 : 2,
      maxLines: einzeilig ? 1 : 4,
      textCapitalization: einzeilig
          ? TextCapitalization.words
          : TextCapitalization.sentences,
      style: CoachStyle.body.copyWith(color: Glas.text),
      cursorColor: CoachStyle.goldBright,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: CoachStyle.body.copyWith(color: const Color(0x99CDBB98)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(15),
      ),
    ),
  );
}

/// One answer to tap: a glass pane that turns gold with a glowing dot when
/// picked.
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: GlasBox(
            key: ValueKey(selected),
            art: selected ? GlasArt.gold : GlasArt.normal,
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: CoachStyle.body.copyWith(
                      color: Glas.text,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: selected
                        ? const RadialGradient(
                            colors: [Color(0xFFF8E6B8), Color(0xFFC08E45)],
                          )
                        : null,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFF3DCA6)
                          : const Color(0x59FFECDC),
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? const [
                            BoxShadow(color: Color(0x99E0BF7E), blurRadius: 10),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
