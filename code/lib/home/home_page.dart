import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../checkin/checkin_flow.dart';
import '../data/diary_store.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../weight/weight.dart';
import '../weight/weight_chart.dart';

/// The Main Feed: opens after the daily check-in and is tailored to that
/// day. Shows the coach's reply and the optional weight analysis; later also
/// help that reacts to the check-in answers (see Umsetzung/Main Feed.md).
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.store,
    required this.clock,
    required this.onRestartOnboarding,
  });

  final DiaryStore store;
  final DateTime Function() clock;
  final VoidCallback onRestartOnboarding;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CheckIn>? _checkIns;
  List<WeightEntry> _weights = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final checkIns = await widget.store.loadCheckIns();
    final weights = await widget.store.loadWeights();
    if (!mounted) return;
    setState(() {
      _checkIns = checkIns;
      _weights = weights;
    });
  }

  CheckIn? get _today {
    final key = dayKey(widget.clock());
    for (final c in _checkIns ?? const <CheckIn>[]) {
      if (dayKey(c.datum) == key) return c;
    }
    return null;
  }

  Future<void> _addWeight() async {
    final kg = await showDialog<double>(
      context: context,
      builder: (context) => const _WeightDialog(),
    );
    if (kg == null) return;
    await widget.store.addWeight(WeightEntry(widget.clock(), kg));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkIns == null) {
      return const CoachPage(
        child: Center(child: CircularProgressIndicator(color: CoachStyle.gold)),
      );
    }
    final today = _today;
    return CoachPage(
      child: ListView(
        children: [
          const SizedBox(height: 12),
          const Text('DEIN FEED', style: CoachStyle.label),
          const SizedBox(height: 8),
          Text(germanDate(widget.clock()), style: CoachStyle.question),
          const SizedBox(height: 24),
          if (today != null)
            _Card(
              title: 'Dein Coach · heute',
              children: [
                CoachNote(
                  text: today.kiAntwort.isNotEmpty
                      ? today.kiAntwort
                      : noReplyYet,
                ),
              ],
            ),
          const SizedBox(height: 16),
          _WeightCard(weights: _weights, onAdd: _addWeight),
          const SizedBox(height: 24),
          TextButton(
            onPressed: widget.onRestartOnboarding,
            child: const Text(
              'Fragebogen neu starten',
              style: TextStyle(color: CoachStyle.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: CoachStyle.label),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.weights, required this.onAdd});

  final List<WeightEntry> weights;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final weeks = weeklyAverages(weights);
    if (weeks.isEmpty) {
      return _Card(
        title: 'Gewicht · freiwillig',
        children: [
          const Text(
            'Wenn du magst, trag ab und zu dein Gewicht ein. Dann siehst du '
            'hier, ob deine Ernährung in die richtige Richtung geht.',
            style: CoachStyle.body,
          ),
          const SizedBox(height: 16),
          MainButton(label: 'Gewicht eintragen', onPressed: onAdd),
        ],
      );
    }
    final current = weeks.last;
    final shown = weeks.length > 12 ? weeks.sublist(weeks.length - 12) : weeks;
    final diff = weeks.length > 1
        ? current.kg - weeks[weeks.length - 2].kg
        : null;
    return _Card(
      title: 'Gewicht · Wochenschnitt',
      children: [
        Text('${formatKg(current.kg)} kg', style: CoachStyle.question),
        if (diff != null)
          Text(
            '${diff > 0
                ? '+'
                : diff < 0
                ? '−'
                : '±'}'
            '${formatKg(diff.abs())} kg zur Vorwoche',
            style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
          ),
        const SizedBox(height: 12),
        WeightChart(weeks: shown),
        const SizedBox(height: 8),
        Text(
          'Gezeigt wird der Schnitt pro Woche, damit normale Schwankungen '
          'nicht stören.',
          style: CoachStyle.body.copyWith(
            color: CoachStyle.inkSoft,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        MainButton(label: 'Gewicht eintragen', onPressed: onAdd),
      ],
    );
  }
}

class _WeightDialog extends StatefulWidget {
  const _WeightDialog();

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final kg = parseKg(_controller.text);
    if (kg == null) {
      setState(() => _error = 'Bitte ein Gewicht zwischen 30 und 300 kg.');
      return;
    }
    Navigator.of(context).pop(kg);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gewicht heute'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: 'kg',
          hintText: 'z. B. 82,4',
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _save, child: const Text('Speichern')),
      ],
    );
  }
}

/// E.g. "Montag, 12. Oktober".
String germanDate(DateTime d) {
  const days = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];
  const months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  return '${days[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]}';
}
