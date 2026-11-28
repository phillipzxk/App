import 'package:flutter/material.dart';

import '../ui/umbau.dart';

import '../bereiche/glas.dart';
import '../data/profile_store.dart';
import '../data/user_profile.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../mindset/mindset_ui.dart' show CoachZeile;
import '../konto/konto_ui.dart' show bewegungAn, KontoWortmarke, WachsendesLogo;
import 'onboarding_evaluator.dart';
import 'onboarding_questions.dart';
import 'start_saetze.dart';

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
    this.onSchonKonto,
  });

  final ProfileStore store;
  final OnboardingEvaluator evaluator;
  final ValueChanged<UserProfile> onFinished;

  /// "Ich habe schon ein Konto" on the first screen (new phone).
  final VoidCallback? onSchonKonto;

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
          start: startSaetze(_profile),
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
        // The first screen greets with the logo growing itself, like the
        // account screen, and the one sentence of what Groundset is
        // (Rundgang 2026-11-28). It shrinks while the keyboard is open.
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: [
                  const WachsendesLogo(size: 130),
                  const KontoWortmarke(),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 300,
                    child: Text(
                      'Ein Coach, der dein Training, Essen, Schlaf und deinen '
                      'Kopf zusammen sieht.',
                      textAlign: TextAlign.center,
                      style: CoachStyle.body.copyWith(color: Glas.soft),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
        const SizedBox(height: 20),
        MainButton(
          gold: true,
          label: 'Weiter',
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () => setState(() => _phase = _Phase.questions),
        ),
        if (widget.onSchonKonto case final schon?) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              key: const ValueKey('schon-konto'),
              onPressed: schon,
              child: Text(
                'Ich habe schon ein Konto',
                style: Glas.tLabel.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
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
            ZurueckPille(
              onTap: () => setState(() {
                if (_index > 0) {
                  _index--;
                } else {
                  _phase = _Phase.name;
                }
              }),
            ),
            const SizedBox(width: 12),
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
  const _Summary({
    required this.summary,
    required this.start,
    required this.onContinue,
  });

  final String summary;
  final List<StartSatz> start;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final text = summary.isNotEmpty
        ? summary
        : 'Deine Antworten sind gespeichert. Deine persönliche '
              'Auswertung kommt bald, sobald dein Coach freigeschaltet ist.';
    // The text types itself in, then the areas spring in one by one.
    final tippZeit = (text.length * 22).clamp(800, 3200);
    final ab = (tippZeit / 80).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 12),
              const Text('DEIN START', style: CoachStyle.goldLabel),
              const SizedBox(height: 12),
              GoldSchrift(
                'So sehe ich dich gerade',
                style: CoachStyle.question,
              ),
              const SizedBox(height: 18),
              GlasBox(
                art: GlasArt.gold,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CoachAvatar(size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Getippt(
                        key: const ValueKey('start-text'),
                        text: text,
                        dauer: Duration(milliseconds: tippZeit),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Einflug(
                platz: ab,
                child: const Text('DAMIT STARTEN WIR', style: Umbau.label),
              ),
              const SizedBox(height: 10),
              GlasBox(
                key: const ValueKey('start-bereiche'),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Column(
                  children: [
                    for (var i = 0; i < start.length; i++)
                      Einflug(
                        platz: ab + 1 + i * 2,
                        child: _StartZeile(start[i], linie: i > 0),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Einflug(
          platz: ab + 2 + start.length * 2,
          child: MainButton(
            label: "Los geht's",
            gold: true,
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}

/// One area with its start sentence: gold ring with the icon, the area
/// name small above, the sentence below; a hairline between rows.
class _StartZeile extends StatelessWidget {
  const _StartZeile(this.s, {required this.linie});

  final StartSatz s;
  final bool linie;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: linie ? const Border(top: BorderSide(color: Umbau.linie)) : null,
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CoachStyle.goldBright, width: 1.4),
          ),
          child: Icon(s.icon, size: 17, color: Umbau.gold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.name.toUpperCase(), style: Umbau.label),
              const SizedBox(height: 3),
              Text(
                s.satz,
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 14,
                  height: 1.4,
                  color: Umbau.text,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Text that types itself in once; the full text keeps the size.
class _Getippt extends StatelessWidget {
  const _Getippt({super.key, required this.text, required this.dauer});

  final String text;
  final Duration dauer;

  static const _stil = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 15,
    height: 1.5,
    color: Umbau.text,
  );

  @override
  Widget build(BuildContext context) {
    if (!bewegungAn) return Text(text, style: _stil);
    return Stack(
      children: [
        Opacity(opacity: 0, child: Text(text, style: _stil)),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: dauer,
          builder: (context, v, _) =>
              Text(text.substring(0, (v * text.length).round()), style: _stil),
        ),
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
