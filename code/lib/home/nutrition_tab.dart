import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../feed/kcal.dart';
import '../supplements/supplement_data.dart';
import '../supplements/supplement_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../weight/weight.dart';
import '../weight/weight_chart.dart';
import 'feed_widgets.dart';

/// Ernährung page: progress, kcal target, the supplement routine, the field
/// for today's food and the weight trend.
class NutritionTab extends StatelessWidget {
  const NutritionTab({
    super.key,
    required this.kcal,
    required this.weights,
    required this.fragen,
    required this.onSaveKcal,
    required this.onAddWeight,
    required this.onAsk,
    required this.supplements,
    required this.genommen,
    required this.onSaveSupplements,
    required this.onToggleSupplement,
  });

  final KcalProfil? kcal;
  final List<WeightEntry> weights;
  final List<CoachFrage> fragen;

  /// Saves the kcal data and, when given, the first weight.
  final Future<void> Function(KcalProfil profil, double? kg) onSaveKcal;
  final VoidCallback onAddWeight;
  final Future<void> Function(String text) onAsk;
  final List<Supplement> supplements;
  final Set<String> genommen;
  final Future<void> Function(List<Supplement> list) onSaveSupplements;
  final Future<void> Function(Supplement s, bool genommen) onToggleSupplement;

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.of(context).push<(KcalProfil, double?)>(
      MaterialPageRoute(
        builder: (_) => KcalEditor(profil: kcal, needsWeight: weights.isEmpty),
      ),
    );
    if (result != null) await onSaveKcal(result.$1, result.$2);
  }

  @override
  Widget build(BuildContext context) {
    final p = kcal;
    final kg = weights.isEmpty ? null : weights.last.kg;
    return ListView(
      children: [
        const PageHeader(label: 'Bereich', title: 'Ernährung', icon: Icons.eco),
        const GroupLabel('Dein Verlauf'),
        const AreaChart(),
        const GroupLabel('Deine Basis'),
        if (p == null || kg == null)
          FeedCard(
            title: 'Dein kcal-Ziel',
            icon: Icons.restaurant_outlined,
            children: [
              const HintText(
                'Gib einmal Größe, Alter, Geschlecht und deine Aktivität im '
                'Alltag an. Daraus berechnen wir dein kcal-Ziel, und es passt '
                'sich mit jedem neuen Gewicht an. Gezählt wird nichts.',
              ),
              const SizedBox(height: 12),
              GhostButton(
                label: 'kcal-Ziel einrichten',
                onPressed: () => _edit(context),
              ),
            ],
          )
        else
          FeedCard(
            title: 'Dein kcal-Ziel heute',
            icon: Icons.restaurant_outlined,
            trailing: const Tag('passt sich an'),
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatKcal(kcalZiel(p, kg)),
                      style: CoachStyle.question.copyWith(fontSize: 28),
                    ),
                    const TextSpan(
                      text: '  kcal',
                      style: TextStyle(color: CoachStyle.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              HintText(
                'Berechnet aus Größe, Alter, Geschlecht, Aktivität und deinem '
                'aktuellen Gewicht (${formatKg(kg)} kg). Sobald die KI '
                'angeschlossen ist, passt sie es an dein Ziel an. Kein Zählen.',
              ),
              const SizedBox(height: 12),
              GhostButton(
                label: 'Angaben ändern',
                onPressed: () => _edit(context),
              ),
            ],
          ),
        SupplementCard(
          supplements: supplements,
          genommen: genommen,
          onSave: onSaveSupplements,
          onToggle: onToggleSupplement,
        ),
        const GroupLabel('Frag deinen Coach'),
        AskCoachCard(
          title: 'Wie sieht deine Ernährung heute aus?',
          hint:
              'Schreib grob, was du heute gegessen hast. Der Coach schätzt '
              'ein, ob es zu deinem Ziel passt.',
          today: fragen,
          onSend: onAsk,
        ),
        const GroupLabel('Deine Werte'),
        WeightCard(weights: weights, onAdd: onAddWeight),
      ],
    );
  }
}

class WeightCard extends StatelessWidget {
  const WeightCard({super.key, required this.weights, required this.onAdd});

  final List<WeightEntry> weights;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final weeks = weeklyAverages(weights);
    if (weeks.isEmpty) {
      return FeedCard(
        title: 'Gewicht',
        icon: Icons.monitor_weight_outlined,
        children: [
          const HintText(
            'Trag regelmäßig dein Gewicht ein. Dann siehst du hier deinen '
            'Wochenschnitt, und dein kcal-Ziel bleibt aktuell.',
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
    return FeedCard(
      title: 'Gewicht · Wochenschnitt',
      icon: Icons.monitor_weight_outlined,
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
        const HintText(
          'Gezeigt wird der Schnitt pro Woche, damit normale Schwankungen '
          'nicht stören.',
        ),
        const SizedBox(height: 16),
        MainButton(label: 'Gewicht eintragen', onPressed: onAdd),
      ],
    );
  }
}

class WeightDialog extends StatefulWidget {
  const WeightDialog({super.key});

  @override
  State<WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<WeightDialog> {
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

/// Height, age, sex, activity and, if none is stored yet, the weight.
class KcalEditor extends StatefulWidget {
  const KcalEditor({
    super.key,
    required this.profil,
    required this.needsWeight,
  });

  final KcalProfil? profil;
  final bool needsWeight;

  @override
  State<KcalEditor> createState() => _KcalEditorState();
}

class _KcalEditorState extends State<KcalEditor> {
  late final _groesse = TextEditingController(
    text: widget.profil?.groesseCm.toString() ?? '',
  );
  late final _alter = TextEditingController(
    text: widget.profil?.alter.toString() ?? '',
  );
  final _gewicht = TextEditingController();
  late Geschlecht? _geschlecht = widget.profil?.geschlecht;
  late Aktivitaet? _aktivitaet = widget.profil?.aktivitaet;
  bool _tried = false;

  @override
  void dispose() {
    _groesse.dispose();
    _alter.dispose();
    _gewicht.dispose();
    super.dispose();
  }

  int? get _cm => parseInt(_groesse.text, 120, 230);
  int? get _jahre => parseInt(_alter.text, 14, 100);
  double? get _kg => parseKg(_gewicht.text);

  void _save() {
    final cm = _cm, jahre = _jahre, kg = _kg;
    final g = _geschlecht, a = _aktivitaet;
    if (cm == null ||
        jahre == null ||
        g == null ||
        a == null ||
        (widget.needsWeight && kg == null)) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop((
      KcalProfil(groesseCm: cm, alter: jahre, geschlecht: g, aktivitaet: a),
      widget.needsWeight ? kg : null,
    ));
  }

  Widget _choice<T>(
    T value,
    T? group,
    String label,
    String? sub,
    ValueChanged<T> onTap,
  ) {
    final on = value == group;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => onTap(value)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFF1E6D2) : CoachStyle.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? CoachStyle.gold : CoachStyle.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: CoachStyle.body),
              if (sub != null) HintText(sub),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const missing = 'Bitte auswählen.';
    return EditorPage(
      title: 'Dein kcal-Ziel',
      intro:
          'Einmal angeben, danach passt sich dein Ziel mit jedem neuen '
          'Gewicht von selbst an.',
      onSave: _save,
      children: [
        EditorField(
          controller: _groesse,
          label: 'Größe',
          suffix: 'cm',
          number: true,
          error: _tried && _cm == null
              ? 'Bitte zwischen 120 und 230 cm.'
              : null,
        ),
        const SizedBox(height: 12),
        EditorField(
          controller: _alter,
          label: 'Alter',
          suffix: 'Jahre',
          number: true,
          error: _tried && _jahre == null ? 'Bitte zwischen 14 und 100.' : null,
        ),
        if (widget.needsWeight) ...[
          const SizedBox(height: 12),
          EditorField(
            controller: _gewicht,
            label: 'Gewicht heute',
            suffix: 'kg',
            number: true,
            error: _tried && _kg == null
                ? 'Bitte ein Gewicht zwischen 30 und 300 kg.'
                : null,
          ),
        ],
        const SizedBox(height: 20),
        const Text('GESCHLECHT', style: CoachStyle.label),
        const SizedBox(height: 8),
        _choice(
          Geschlecht.mann,
          _geschlecht,
          'Mann',
          null,
          (v) => _geschlecht = v,
        ),
        _choice(
          Geschlecht.frau,
          _geschlecht,
          'Frau',
          null,
          (v) => _geschlecht = v,
        ),
        if (_tried && _geschlecht == null) const _Error(missing),
        const SizedBox(height: 12),
        const Text('AKTIVITÄT IM ALLTAG', style: CoachStyle.label),
        const SizedBox(height: 8),
        for (final a in Aktivitaet.values)
          _choice(
            a,
            _aktivitaet,
            a.label,
            a.beschreibung,
            (v) => _aktivitaet = v,
          ),
        if (_tried && _aktivitaet == null) const _Error(missing),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
  );
}
