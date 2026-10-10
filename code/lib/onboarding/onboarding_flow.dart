import 'package:flutter/material.dart';

import '../data/profile_store.dart';
import '../data/user_profile.dart';
import 'onboarding_questions.dart';

/// The onboarding questionnaire: welcome, three choice questions, one
/// optional free-text question, done.
///
/// The profile is saved once the free-text step is passed, so a user who
/// quits halfway starts over next time.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.store,
    required this.onFinished,
  });

  final ProfileStore store;
  final ValueChanged<UserProfile> onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  // 0 = welcome, 1..n = choice questions, n+1 = free text, n+2 = done.
  int _step = 0;
  UserProfile _profile = const UserProfile();
  final _noteController = TextEditingController();

  int get _freeTextStep => choiceQuestions.length + 1;
  int get _doneStep => choiceQuestions.length + 2;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _choose(ChoiceQuestion question, String value) {
    setState(() {
      _profile = question.apply(_profile, value);
      _step++;
    });
  }

  Future<void> _finishFreeText({required bool skip}) async {
    final note = skip ? '' : _noteController.text.trim();
    final profile = _profile.copyWith(onboardingNotiz: note);
    await widget.store.save(profile);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _step = _doneStep;
    });
  }

  void _back() => setState(() => _step--);

  @override
  Widget build(BuildContext context) {
    final showBack = _step > 0 && _step < _doneStep;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Zurück',
                onPressed: _back,
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStep(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    if (_step == 0) {
      return _InfoStep(
        title: 'Schön, dass du da bist!',
        text:
            'Bevor es losgeht, vier kurze Fragen. So kann dein Coach dir von '
            'Anfang an Tipps geben, die wirklich zu dir passen. '
            'Dauert keine Minute.',
        buttonLabel: "Los geht's",
        onPressed: () => setState(() => _step = 1),
      );
    }
    if (_step <= choiceQuestions.length) {
      final question = choiceQuestions[_step - 1];
      return _QuestionStep(
        number: _step,
        question: question.question,
        subtitle: question.subtitle,
        children: [
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onPressed: () => _choose(question, option.value),
                child: Text(option.label),
              ),
            ),
        ],
      );
    }
    if (_step == _freeTextStep) {
      return _QuestionStep(
        number: _step,
        question: 'Was möchtest du in drei Monaten anders machen?',
        subtitle: 'Erzähl es in eigenen Worten. Ein Satz reicht.',
        children: [
          TextField(
            controller: _noteController,
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText:
                  'z. B. „Morgens fit aufwachen und dreimal die Woche '
                  'trainieren“',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => _finishFreeText(skip: false),
            child: const Text('Weiter'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _finishFreeText(skip: true),
            child: const Text('Überspringen'),
          ),
        ],
      );
    }
    return _InfoStep(
      title: "Alles klar, los geht's!",
      text:
          'Ab jetzt fragt dich die App einmal am Tag, wie es dir geht. '
          'Antworte einfach in eigenen Worten, dein Coach kümmert sich um '
          'den Rest.',
      buttonLabel: 'Zum ersten Check-in',
      onPressed: () => widget.onFinished(_profile),
    );
  }
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({
    required this.title,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text(text, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 40),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: onPressed,
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    required this.number,
    required this.question,
    required this.subtitle,
    required this.children,
  });

  final int number;
  final String question;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Frage $number von $questionCount',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: number / questionCount),
        const SizedBox(height: 24),
        Text(question, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}
